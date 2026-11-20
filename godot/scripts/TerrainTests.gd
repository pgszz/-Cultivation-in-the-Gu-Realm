class_name TerrainTests
extends RefCounted

var game:Node
var test:=CanonTests.new()

func run(main:Node) -> void:
	game=main
	test.game=game
	game.set_process(false)
	game.start_game()
	CanonTests.prepare_cultivator(game)
	game.player.body.reset_full()
	var blocks:TerrainLayers=game.world.blocks
	# Every stacked cell retains its own identity, durability and one-time yield.
	var peak:=Vector2i.ZERO
	for cell:Vector2i in blocks.mountain_cells["0"]:
		if blocks.height_at(cell)>blocks.height_at(peak): peak=cell
	var old_height:=blocks.height_at(peak)
	var top:=blocks.info(peak,0)
	var adjacent:=blocks.info(peak+Vector2i.RIGHT,0)
	var first:=blocks.hit(peak,0,20)
	test.expect(old_height>=3 and first.hp==top.hp-10,"mountain consists of individually damageable stacked blocks")
	test.expect(blocks.info(peak+Vector2i.RIGHT,0)==adjacent,"striking one column leaves its neighbour untouched")
	test.expect(blocks.hit(peak,0,-100).is_empty(),"negative damage cannot restore a block")
	game.hit_terrain(peak,9999,Vector2.RIGHT)
	test.expect(blocks.height_at(peak)==old_height-1 and blocks.info(peak,0).hp==72,"breaking a summit exposes the intact block beneath it")
	test.expect(not game.fx.chunks.is_empty() and float(game.fx.chunks.back().size)==15,"strong impact ejects visible large block fragments")
	var life:float=game.fx.chunks.back().life
	game.paused=true
	game.fx._process(0.2)
	test.expect(game.fx.chunks.back().life==life,"flying blocks freeze with menus")
	game.paused=false
	game.fx._process(0.1)
	test.expect(game.fx.chunks.back().life<life and game.fx.chunks.back().z>0,"fragments travel with vertical momentum")
	game.change_layer(0,TerrainLayers.center(peak),false)
	test.expect(not game.world.collides(game.player.position.x,game.player.position.y,12),"mountain blocks can be walked on")
	test.expect(blocks.speed_multiplier(game.player.position,Vector2.ZERO)<1,"walking on mountain tiers is slower")
	var slope_found:=false
	for cell:Vector2i in blocks.mountain_cells["0"]:
		for dir in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			if blocks.height_at(cell+dir)>blocks.height_at(cell):
				slope_found=blocks.speed_multiplier(TerrainLayers.center(cell),Vector2(dir))==0.48
				break
		if slope_found: break
	test.expect(slope_found,"climbing an uphill step applies the stronger movement reduction")
	for layer in [1,2]:
		game.change_layer(layer,blocks.portals(layer)[0].pos,false)
		_check_routes(layer)
		await _check_input(layer)
	await _check_layers()
	await _check_occlusion()
	await _check_save()
	print("TERRAINTEST checked=%d failures=%s"%[test.checked,str(test.failures)])
	game.get_tree().quit(0 if test.failures.is_empty() else 1)

func _check_routes(layer:int) -> void:
	var blocks:TerrainLayers=game.world.blocks
	var start:=TerrainLayers.cell_at(blocks.portals(layer)[0].pos)
	var seen:Dictionary={start:true}
	var queue:Array[Vector2i]=[start]
	var index:=0
	while index<queue.size():
		var current:=queue[index]
		index+=1
		for dir in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next:Vector2i=current+dir
			if seen.has(next) or blocks.solid(next,layer): continue
			seen[next]=true
			queue.append(next)
	for portal in blocks.portals(layer):
		test.expect(seen.has(TerrainLayers.cell_at(portal.pos)),"layer %d reachable stair %s"%[layer,portal.id])
	for site in TerrainLayers.SITES:
		if site.layer==layer: test.expect(seen.has(TerrainLayers.cell_at(site.pos)),"layer %d reachable site %s"%[layer,site.id])

func _check_input(layer:int) -> void:
	var origin:=TerrainLayers.center(Vector2i(44,16) if layer==1 else Vector2i(48,20))
	game.player.position=origin
	for zoom in [0.65,1.0,1.75]:
		game.set_camera_zoom(zoom)
		game._update_camera(0)
		game.camera.reset_smoothing()
		await game.get_tree().process_frame
		await game.get_tree().process_frame
		for dir in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
			var target:Vector2=origin+dir*32
			var cell:=TerrainLayers.cell_at(target)
			game.world.blocks.damage.erase(game.world.blocks.key(cell,layer))
			var before:Dictionary=game.world.blocks.info(cell,layer)
			game.player.atk_cd=0
			var screen:Vector2=game.get_viewport().get_canvas_transform()*target
			await test.pointer(screen,MOUSE_BUTTON_LEFT)
			var after:Dictionary=game.world.blocks.info(cell,layer)
			test.expect(not before.is_empty() and not after.is_empty() and after.hp<before.hp,"short click attacks %s at zoom %.2f in layer %d"%[dir,zoom,layer])
			test.expect(absf(wrapf(game.player.dir-dir.angle(),-PI,PI))<0.01,"attack direction matches screen position")
	game.set_camera_zoom(1)
	await test.key(KEY_F)
	test.expect(game.village_ui.visible and game.village_ui.mode=="block" and game.village_ui.description.text.contains("血量"),"F opens the current cave block health details")
	await test.key(KEY_F)
	test.expect(not game.village_ui.visible and not game.paused,"F closes block inspection and resumes play")
	# Projectile collision samples all directions independently of camera zoom.
	for dir:Vector2i in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
		var block:=TerrainLayers.cell_at(origin)+dir*3
		game.world.blocks.caves[layer][block.y*128+block.x]=1 if layer==1 else 4
		game.world.blocks.damage.erase(game.world.blocks.key(block,layer))
		var hp:float=game.world.blocks.info(block,layer).hp
		game.spawn_projectile(origin,Vector2(dir)*500,20,"none","player",{})
		game._update_projectiles(0.25)
		test.expect(game.projectiles.is_empty() and game.world.blocks.info(block,layer).hp<hp,"projectile hits the first wall toward "+str(dir))

func _check_layers() -> void:
	var blocks:TerrainLayers=game.world.blocks
	for entrance in TerrainLayers.ENTRANCES:
		game.change_layer(0,entrance.pos,false)
		await test.key(KEY_E)
		test.expect(game.world.layer==1 and game.player.position.distance_to(entrance.landing)<1,"E enters "+entrance.id)
		test.expect(game.active_npcs().is_empty() and game.active_enemies().is_empty() and not game.world.props.visible,"surface actors and props are isolated underground")
		var clock_before:float=game.population.day_clock
		game.population.tick(10)
		test.expect(game.population.day_clock==clock_before,"surface schedules freeze underground")
		await test.key(KEY_E)
		test.expect(game.world.layer==0 and game.player.position.distance_to(entrance.pos)<1,"E returns through "+entrance.id)
	for stair in TerrainLayers.STAIRS:
		game.change_layer(1,stair.upper,false)
		await test.key(KEY_E)
		test.expect(game.world.layer==2 and game.player.position==stair.lower,"E descends "+stair.id)
		await test.key(KEY_E)
		test.expect(game.world.layer==1 and game.player.position==stair.upper,"E ascends "+stair.id)
	game.change_layer(1,TerrainLayers.SITES[0].pos,false)
	var actor:Enemy=game.enemies[0]
	var actor_pos:=actor.position
	var actor_hp:=actor.hp
	actor.position=game.player.position+Vector2(32,0)
	game.player.atk_cd=0
	game.basic_attack(actor.position)
	game.spawn_projectile(game.player.position,Vector2.RIGHT*500,20,"none","player",{})
	game._update_projectiles(0.1)
	test.expect(actor.hp==actor_hp and game.person_talk_blocker(game.npc)!="","surface enemies and residents cannot be hit or traded with from a cave")
	test.expect(game.can_meditate(),"a surface enemy at matching coordinates cannot block underground meditation")
	actor.position=actor_pos
	game.projectiles.clear()
	var inv:Inventory=game.get_node("/root/Inv")
	var count:=inv.get_item_count("bandage")
	await test.key(KEY_E)
	await test.key(KEY_E)
	test.expect(inv.get_item_count("bandage")==count+2 and blocks.visited.has("under_camp"),"underground supplies are claimed exactly once")
	game.set_waypoint(TerrainLayers.SITES[5].pos,"深层玉脉",false,2)
	var guide:Dictionary=game.waypoint_guidance()
	test.expect(guide.transition!="" and not guide.arrived,"cross-layer navigation points to a stair before the destination")
	game.fog.load_layers({})
	game.fog.set_layer(1)
	game.fog.reveal(game.player.position,120)
	test.expect(game.fog.discovered(game.player.position) and not game.fog.discovered_on(game.player.position,2),"cave exploration is independent between floors")
	await test.key(KEY_M)
	var previous:Vector2=game.player.position
	game.minimap_ui.view_layer(2)
	game.minimap_ui.atlas.fit_world()
	await game.get_tree().process_frame
	test.expect(game.world.layer==1 and game.player.position==previous,"viewing another map does not teleport")
	test.expect(game.get_viewport_rect().encloses(game.journal.panel.get_global_rect()),"layer map panel fits viewport")
	var atlas:AtlasMap=game.minimap_ui.atlas
	var point:=Vector2(1900,1800)
	await test.pointer(atlas.global_position+atlas.world_to_map(point),MOUSE_BUTTON_LEFT)
	test.expect(game.waypoint_layer==2 and game.waypoint.distance_to(point)<1,"map click records the viewed destination layer")
	await test.pointer(atlas.global_position+atlas.world_to_map(point),MOUSE_BUTTON_RIGHT)
	test.expect(game.waypoint==Vector2.ZERO,"right click removes a layered waypoint")
	await test.key(KEY_ESCAPE)

func _check_occlusion() -> void:
	game.change_layer(1,Vector2(528,592),false)
	var blocks:TerrainLayers=game.world.blocks
	var wall:=Vector2i(10,10)
	var wall_pos:=TerrainLayers.center(wall)
	var start:=wall_pos+Vector2(0,48)
	# Isolated corridor fixture: a wall between attacker and target, another wall behind.
	blocks.carve(1,wall,4)
	blocks.caves[1][wall.y*128+wall.x]=1
	blocks.caves[1][(wall.y-1)*128+wall.x]=1
	blocks.damage.erase(blocks.key(wall,1))
	blocks.damage.erase(blocks.key(wall+Vector2i.UP,1))
	game.player.position=start
	test.expect(not game.world.attack_clear(start,wall_pos-Vector2(0,32)),"rock wall blocks an attack line")
	test.expect(game.world.collides(wall_pos.x,wall_pos.y,12),"intact cave walls block movement")
	var before:=blocks.info(wall+Vector2i.UP,1)
	game.spawn_projectile(start,Vector2.UP*600,9999,"none","player",{})
	game._update_projectiles(0.2)
	test.expect(game.projectiles.is_empty() and blocks.kind_at(wall,1)==0,"projectile breaks the first wall and stops")
	test.expect(blocks.info(wall+Vector2i.UP,1).hp==before.hp,"same projectile cannot damage the next wall")
	test.expect(not game.world.collides(wall_pos.x,wall_pos.y,12),"destroyed cave wall becomes a walkable passage")
	test.expect(blocks.info(wall,1).hp==48 and blocks.info(wall,1).height==-1,"destroyed wall exposes a separate floor with its own health")
	var inv:Inventory=game.get_node("/root/Inv")
	var count:=inv.get_item_count("rubble")
	game.hit_terrain(wall,9999,Vector2.UP)
	test.expect(inv.get_item_count("rubble")==count,"destroyed wall does not repeat its salvage")
	# Normal NPC combat must also respect a wall before any destruction happens.
	game.change_layer(0,Vector2(512,1040),false)
	game.enter_house(World.HOUSE_DATA[0])
	var npc:Npc=game.residents.clinic
	var id:="interior:clinic:table"
	if not game.world.destruction.objects.has(id): id="interior:clinic:storage"
	var rect:Rect2=game.world.destruction.objects[id].rect
	var saved_pos:=npc.position
	npc.position=rect.get_center()-Vector2(0,rect.size.y*0.5+10)
	npc.load_data({"hp":100})
	game.player.position=rect.get_center()+Vector2(0,rect.size.y*0.5+10)
	var hp:=npc.hp
	game.strike_world(game.player.position,200,9999,"none",Vector2.UP,0.5)
	test.expect(npc.hp==hp and game.world.destruction.broken(id),"one swing breaks cover without hitting the NPC behind it")
	game.strike_world(game.player.position,200,1,"none",Vector2.UP,0.5)
	test.expect(npc.hp<hp,"a later swing reaches the NPC after cover is removed")
	npc.position=saved_pos
	npc.load_data({"hp":100})
	game.exit_house(false)
	game.change_layer(0,Vector2(512,1040),false)
	var villager:Npc=game.npc
	var saved_villager:=villager.save_data().duplicate(true)
	var villager_pos:=villager.position
	villager.load_data({"hp":100,"hostile":false})
	villager.position=game.player.position+Vector2(0,32)
	var floor_cell:=TerrainLayers.cell_at(villager.position)
	var floor_hp:float=blocks.info(floor_cell,0).hp
	game.player.atk_cd=0
	game.basic_attack(villager.position)
	test.expect(villager.hp<100 and blocks.info(floor_cell,0).hp==floor_hp,"hitting a person does not also excavate the ground beneath them")
	villager.position=villager_pos
	villager.load_data(saved_villager)

func _check_save() -> void:
	game.change_layer(2,TerrainLayers.STAIRS[0].lower,false)
	var blocks:TerrainLayers=game.world.blocks
	var cell:=Vector2i(8,8)
	game.hit_terrain(cell,30,Vector2.RIGHT)
	var hp:float=blocks.info(cell,2).hp
	var pos:Vector2=game.player.position
	game.set_waypoint(TerrainLayers.ENTRANCES[0].pos,"回到竹林",false,0)
	game.save_game()
	var save:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.SAVE_PATH))
	game.change_layer(0,Vector2(512,1040),false)
	blocks.damage.clear()
	game._load_save(save)
	test.expect(game.world.layer==2 and game.player.position==pos,"save restores underground floor and position")
	test.expect(blocks.info(cell,2).hp==hp and blocks.claimed.has("under_camp"),"save restores independent block damage and one-time supplies")
	test.expect(game.waypoint_layer==0 and game.waypoint_guidance().transition!="","save restores cross-layer waypoint")
	test.expect(game.fog.discovered_on(TerrainLayers.SITES[0].pos,1),"save restores exploration on an inactive floor")
	for key in ["world_layer","terrain_layers","layer_explored","waypoint_layer"]: save.erase(key)
	save.position=[512,1040]
	game._load_save(save)
	test.expect(game.world.layer==0 and blocks.damage.is_empty() and blocks.claimed.is_empty(),"legacy saves default to surface and intact blocks")
	game.change_layer(2,TerrainLayers.center(Vector2i(1,1)),false)
	test.expect(not game.world.collides(game.player.position.x,game.player.position.y,12),"invalid cave spawn relocates to a safe floor")
	var first:Vector2i=blocks.mountain_cells["0"][0]
	blocks.load_data({},{"mountain:0":450})
	test.expect(blocks.info(first,0).hp==36,"legacy whole-mountain damage migrates proportionally to individual blocks")
	blocks.load_data({"damage":{"2:8:8:0":99999,"2:8:8:9":2,"8:1:1:0":0}})
	test.expect(blocks.damage.size()==1 and blocks.info(Vector2i(8,8),2).hp<=120,"loaded block damage rejects invalid floors and clamps material health")

func shot(main:Node, scenario:String) -> void:
	game=main
	game.set_process(false)
	game.start_game()
	CanonTests.prepare_cultivator(game)
	game.player.body.reset_full()
	var aim_point:=Vector2.INF
	if scenario=="blockmountain" or scenario=="blockimpact":
		var cells:Array=game.world.blocks.mountain_cells["0"]
		var cell:Vector2i=cells[cells.size()/2]
		for current:Vector2i in cells:
			if game.world.blocks.height_at(current)>game.world.blocks.height_at(cell): cell=current
		aim_point=TerrainLayers.center(cell)
		game.change_layer(0,aim_point+Vector2(0,64),false)
		var target:Dictionary=game.world.aimed_block(game.player.position,aim_point,64)
		if not target.is_empty(): cell=target.cell
		game.hit_terrain(cell,36,Vector2.UP)
		if scenario=="blockimpact":
			game.hit_terrain(cell,999,Vector2.RIGHT)
			game.fx._process(0.16)
	else:
		var layer:=2 if scenario=="deepcave" else 1
		game.change_layer(layer,TerrainLayers.SITES[0 if layer==1 else 4].pos+Vector2(0,75),false)
		game.set_waypoint(TerrainLayers.STAIRS[1].upper if layer==1 else TerrainLayers.STAIRS[1].lower,"返回石阶",false,layer)
	game._update_camera(0)
	game.camera.reset_smoothing()
	game.fog.reveal(game.player.position,420)
	if scenario=="layermap":
		game.get_viewport().warp_mouse(Vector2(8,8))
		game.fog.reveal(TerrainLayers.extent(1)*0.5,5000)
		game.open_journal("map")
		game.minimap_ui.view_layer(1)
		game.minimap_ui.atlas.fit_world()
	game.paused=true
	game.logs.clear()
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	game._update_camera(0)
	if aim_point.is_finite(): game.get_viewport().warp_mouse(game.get_viewport().get_canvas_transform()*aim_point)
	await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result:=game.get_viewport().get_texture().get_image().save_png("res://shot_"+scenario+".png")
	print("SHOT "+scenario+" "+str(result))
	game.get_tree().quit(0 if result==OK else 1)
