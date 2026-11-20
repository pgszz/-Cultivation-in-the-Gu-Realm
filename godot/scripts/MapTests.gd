class_name MapTests
extends RefCounted

func run(test: CanonTests) -> void:
	var game:Node=test.game
	var before:=test.checked
	game.village_ui.close()
	game.journal.close()
	game.exit_house(false)
	game.world.destruction.load_data({})
	game.player.body.reset_full()
	game.player.position=Vector2(512,1040)
	game.clear_waypoint(false)
	_check_expansion(test)
	game.fog.load_data([150*240+220,179*240+238],240)
	test.expect(game.fog.discovered(Vector2(220,150)*32+Vector2(16,16)) and game.fog.discovered(Vector2(238,179)*32+Vector2(16,16)),"240-wide fog preserves old explored coordinates")
	test.expect(not game.fog.discovered(Vector2(300,112)*32+Vector2(16,16)),"old fog does not reveal shifted columns")
	game.fog.reveal(Vector2(GameData.MAP_W,GameData.MAP_H)*16,20000)
	await test.key(KEY_M)
	game.minimap_ui.set_mode("local")
	var atlas:AtlasMap=game.minimap_ui.atlas
	atlas.fit_world()
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	test.expect(game.get_viewport_rect().encloses(game.journal.panel.get_global_rect()),"expanded map panel fits viewport")
	test.expect(game.journal.panel.get_global_rect().encloses(atlas.get_global_rect()) and atlas.size.y>=260,"map retains a usable clipped viewport")
	var pos:=Vector2(180,130)*32+Vector2(16,16)
	await test.pointer(atlas.global_position+atlas.world_to_map(pos),MOUSE_BUTTON_LEFT)
	test.expect(game.waypoint.distance_to(pos)<1,"real map click places a point in world coordinates")
	var anchor:=atlas.size*0.5+Vector2(38,20)
	var under_mouse:=atlas.map_to_world(anchor)
	var world_zoom:float=game.zoom_level
	await test.pointer(atlas.global_position+anchor,MOUSE_BUTTON_WHEEL_UP)
	test.expect(atlas.zoom>1 and game.zoom_level==world_zoom,"map wheel zoom is independent of the world camera")
	test.expect(atlas.map_to_world(anchor).distance_to(under_mouse)<1,"zoom keeps the position beneath the cursor fixed")
	await test.click(game.minimap_ui.zoom_in)
	test.expect(atlas.zoom>1.25,"visible plus control zooms the map")
	var previous_center:=atlas.center
	var mark:Vector2=game.waypoint
	var drag_start:=atlas.global_position+atlas.size*0.5
	await _drag(game,drag_start,drag_start+Vector2(65,42),MOUSE_BUTTON_LEFT)
	test.expect(atlas.center.distance_to(previous_center)>100 and game.waypoint==mark,"left drag pans without replacing the marker")
	previous_center=atlas.center
	await _drag(game,drag_start,drag_start-Vector2(30,25),MOUSE_BUTTON_MIDDLE)
	test.expect(atlas.center.distance_to(previous_center)>100 and game.waypoint==mark,"middle drag pans without creating a marker")
	atlas.zoom_at(100,atlas.size*0.5)
	test.expect(atlas.zoom==8 and game.minimap_ui.zoom_in.disabled,"map zoom has an eightfold upper limit")
	atlas.focus_position(Vector2(-1000,-1000))
	test.expect(atlas.map_to_world(Vector2.ZERO).x>=-0.1 and atlas.map_to_world(Vector2.ZERO).y>=-0.1,"panning clamps at the northwest border")
	atlas.focus_position(atlas.extent()+Vector2(1000,1000))
	test.expect(atlas.map_to_world(atlas.size).x<=atlas.extent().x+0.1 and atlas.map_to_world(atlas.size).y<=atlas.extent().y+0.1,"panning clamps at the southeast border")
	atlas.fit_world()
	test.expect(atlas.zoom==1 and game.minimap_ui.zoom_out.disabled,"fit-world restores the overview and minimum zoom")
	await test.pointer(atlas.global_position+atlas.world_to_map(mark),MOUSE_BUTTON_RIGHT)
	test.expect(game.waypoint==Vector2.ZERO and game.minimap_ui.clear_button.disabled,"right click clears the marker and disables clear control")
	game._load_save()
	test.expect(game.waypoint==Vector2.ZERO,"right-click removal survives save/load")
	game.fog.reveal(atlas.extent()*0.5,20000)
	await test.pointer(atlas.global_position+atlas.world_to_map(pos),MOUSE_BUTTON_LEFT)
	await test.pointer(atlas.global_position+atlas.world_to_map(pos),MOUSE_BUTTON_LEFT)
	test.expect(game.waypoint==Vector2.ZERO,"clicking the same flag again cancels it")
	await test.pointer(atlas.global_position+atlas.world_to_map(pos),MOUSE_BUTTON_LEFT)
	await test.click(game.minimap_ui.clear_button)
	test.expect(game.waypoint==Vector2.ZERO,"visible cancel button clears the point")
	game.minimap_ui._mark(pos,"地图回归标记")
	await test.click(game.minimap_ui.target_button)
	test.expect(atlas.zoom>=3 and atlas.world_to_map(pos).distance_to(atlas.size*0.5)<1,"locate-marker control centers the selected destination")
	var retained_center:=atlas.center
	var retained_zoom:=atlas.zoom
	await test.key(KEY_ESCAPE)
	await test.key(KEY_M)
	test.expect(atlas.zoom==retained_zoom and atlas.center==retained_center,"reopening map retains its zoom and viewed region")
	await test.key(KEY_ESCAPE)
	game.player.position=Vector2(512,1040)
	game.set_waypoint(Vector2(9600,6700),"远岭目标")
	var guide:Dictionary=game.waypoint_guidance()
	test.expect(guide.direction=="东南" and guide.steps>200 and not guide.arrived,"outdoor guide gives a correct compass direction and distance")
	game._update_camera(0)
	game.camera.reset_smoothing()
	await game.get_tree().process_frame
	guide=game.hud.waypoint_indicator()
	test.expect(guide.offscreen and game.get_viewport_rect().has_point(guide.screen),"distant target is projected to a visible screen-edge arrow")
	game.hud.minimal=true
	test.expect(not game.hud.waypoint_indicator().is_empty(),"minimal HUD retains destination guidance")
	game.hud.minimal=false
	game.set_waypoint(game.player.position+Vector2(100,0),"近处目标")
	guide=game.hud.waypoint_indicator()
	test.expect(not guide.offscreen,"nearby target uses an on-screen flag")
	game.player.position=game.waypoint
	var log_count:int=game.logs.size()
	game._update_waypoint()
	var arrival_entry:Dictionary=game.logs.back()
	game._update_waypoint()
	test.expect(game.waypoint_guidance().arrived and game.waypoint_notified and game.logs.back()==arrival_entry and game.logs.size()==mini(8,log_count+1),"arrival is reported once while retaining the flag")
	game.enter_house(World.HOUSE_DATA[2])
	guide=game.waypoint_guidance()
	test.expect(guide.indoors and guide.target==HouseInterior.ORIGIN+Vector2(0,184) and not guide.arrived,"indoor navigation points to the actual exit before the outdoor target")
	game.player.position=HouseInterior.ORIGIN+Vector2(10,50)
	game.save_game()
	var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.SAVE_PATH))
	saved["map_width"]=240
	saved["map_version"]=3
	saved["position"]=[240*32+2048+10,1024+50]
	var file:=FileAccess.open(game.SAVE_PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify(saved))
	file.close()
	game._load_save()
	test.expect(game.world.in_interior and game.player.position==HouseInterior.ORIGIN+Vector2(10,50),"version-three map save preserves room-local position after expansion")
	test.expect(game.waypoint_name=="近处目标" and game.waypoint!=Vector2.ZERO,"saved destination survives map and indoor coordinate migration")
	game.exit_house(false)
	test.expect(not game.waypoint_guidance().indoors,"exit restores guidance toward the outdoor marker")
	mark=game.waypoint
	test.expect(not game.set_waypoint(Vector2(INF,0),"invalid") and not game.set_waypoint(Vector2(-32,32),"invalid") and game.waypoint==mark,"invalid destinations cannot replace the current point")
	await _check_settlement_saves(test)
	# Exercise new resources and both camps through actual interaction and GUI.
	var inv:Inventory=game.get_node("/root/Inv")
	for site in World.EXPLORATION_SITES.slice(15):
		game.player.position=Vector2(site.pos)*32+Vector2(16,16)
		var item:="timber" if site.kind=="timber" else "rubble"
		var count:=inv.get_item_count(item)
		var bandages:=inv.get_item_count("bandage")
		game._try_poi_interact()
		test.expect(game.visited_sites.has(site.id),"new site records its visit "+site.id)
		if site.kind in ["timber","rubble"]:
			test.expect(inv.get_item_count(item)==count+3,"new resource yields three supplies "+site.id)
			game._try_poi_interact()
			test.expect(inv.get_item_count(item)==count+3,"new resource respects cooldown "+site.id)
		elif site.kind=="camp":
			await test.click(game.village_ui.camp_claim)
			test.expect(inv.get_item_count("bandage")==bandages+2 and not game.claim_camp_supplies(site.id),"new camp grants its pack once "+site.id)
			game.village_ui.close()
	game.clear_waypoint()
	game._load_save()
	test.expect(game.waypoint==Vector2.ZERO and game.waypoint_guidance().is_empty(),"cleared guide stays absent after a real reload")
	test.expect(game.visited_sites.has("south_grove") and game.claimed_camps.has("far_camp") and game.claimed_camps.has("trail_camp"),"new visits and camp claims persist")
	print("MAPCONTROLS checked=%d"%(test.checked-before))
	await SouthernBorderTests.new().run(test)

func _check_expansion(test: CanonTests) -> void:
	var world:World=test.game.world
	test.expect(GameData.MAP_W==480 and GameData.MAP_H==360,"expanded world covers 480 by 360 tiles")
	var settlements:=WorldLore.SETTLEMENTS
	for i in settlements.size():
		for j in range(i+1,settlements.size()):
			var steps:float=settlements[i].pos.distance_to(settlements[j].pos)/GameData.TILE
			test.expect(steps>=260,"villages are separated by at least 260 tiles: "+settlements[i].name+" / "+settlements[j].name)
			print("SETTLEMENT distance %s / %s = %.1f tiles"%[settlements[i].name,settlements[j].name,steps])
	# Travel through more chunks than the cache can hold, then return to the first.
	var first:=Vector2i(0,0)
	for i in 28:
		world._ensure_terrain(Rect2(Vector2(i%14,i/14)*1024+Vector2(32,32),Vector2(64,64)))
	test.expect(world.terrain_chunks.size()<=World.MAX_TERRAIN_CHUNKS and not world.terrain_chunks.has(first),"long-distance travel evicts old terrain chunks within the cache budget")
	world._ensure_terrain(Rect2(32,32,64,64))
	test.expect(world.terrain_chunks.has(first) and world.terrain_chunks[first].texture.get_width()==1024,"returning to an evicted region rebuilds its terrain")
	var distant_id:=""
	for id in world.destruction.objects:
		var tile:Vector2i=world.destruction.objects[id].tile
		if tile.x>400 and tile.y>300:
			distant_id=id
			break
	test.expect(distant_id!="","new remote ranges contain destructible terrain")
	if distant_id!="":
		var tile:Vector2i=world.destruction.objects[distant_id].tile
		var point:=Vector2(tile)*32+Vector2(16,16)
		var key:=Vector2i(tile.x/32,tile.y/32)
		test.expect(not world.terrain_chunks.has(key),"remote destruction fixture starts outside terrain cache")
		world.destruction.hit_area(point,2,10000,10000)
		test.expect(world.tile_at(tile.x,tile.y)==GameData.T_GRASS and world.minimap_texture.get_image().get_pixel(tile.x,tile.y).is_equal_approx(world._minimap_color(tile.x,tile.y)),"off-screen destruction updates collision and minimap without a cached texture")
		world._ensure_terrain(Rect2(point-Vector2(16,16),Vector2(32,32)))
		var local:=tile*32-key*1024+Vector2i(16,16)
		# A cleared tile now exposes its local meadow/forest/moss/gravel substrate.
		var expected:Color=world.ground_tiles[world._natural_ground_material(tile.x,tile.y)].get_pixel((tile.x%8)*32+16,(tile.y%8)*32+16)
		test.expect(world.terrain_chunks[key].texture.get_image().get_pixel(local.x,local.y).is_equal_approx(expected),"visiting damaged remote terrain paints the updated ground")
	world.destruction.load_data({})

func _check_settlement_saves(test: CanonTests) -> void:
	var game:Node=test.game
	game.save_game()
	var baseline:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.SAVE_PATH))
	for index in 2:
		var moved:Dictionary=World.RELOCATED_SETTLEMENTS[index]
		var house:Dictionary=World.HOUSE_DATA[5+index]
		var expected:Vector2=moved.current+Vector2(0,50)
		for width in [80,160,240,320]:
			var saved:=baseline.duplicate(true)
			saved["map_width"]=width
			saved["map_version"]=4
			saved["house_id"]=""
			saved["position"]=[moved.old.x,moved.old.y+50]
			saved["waypoint"]=[moved.old.x,moved.old.y+40]
			saved["waypoint_name"]=house.name
			var q:=Vector2i(moved.old/32)
			saved["explored"]=[q.y*width+q.x,30*width+14]
			saved["world_damage"]={"house:"+house.id:125.0}
			_write_save(game,saved)
			game._load_save()
			test.expect(game.player.position==expected and game.waypoint==moved.current+Vector2(0,40),"old outdoor position and destination follow relocated "+house.id+" from width "+str(width))
			test.expect(game.fog.discovered(moved.current) and game.fog.discovered(moved.old) and game.fog.discovered(Vector2(14,30)*32) and not game.fog.discovered(Vector2(330,170)*32),"old fog retains geography and only copies known village cells: "+house.id+" / "+str(width))
			test.expect(game.world.destruction.objects["house:"+house.id].hp==125,"relocated house retains saved damage "+house.id+" / "+str(width))
		game.save_game()
		game._load_save()
		test.expect(game.player.position==expected and game.waypoint==moved.current+Vector2(0,40),"current map save never applies settlement migration twice "+house.id)
		test.expect(game.world.zone_at(expected)==house.id and game.wildlife.is_safe_area(expected),"relocated village remains a wildlife safe area "+house.id)
		game.paused=false
		await test.key(KEY_E)
		test.expect(game.world.in_interior and game.current_house_id==house.id,"E enters relocated village hall "+house.id)
		game.player.position=HouseInterior.ORIGIN+Vector2(0,184)
		await test.key(KEY_E)
		test.expect(not game.world.in_interior and game.player.position==expected,"E exits at relocated village door "+house.id)
		var indoor:=baseline.duplicate(true)
		indoor["map_width"]=320
		indoor["map_version"]=4
		indoor["house_id"]=house.id
		indoor["position"]=[320*32+2048+10,1024+50]
		_write_save(game,indoor)
		game._load_save()
		test.expect(game.world.in_interior and game.player.position==HouseInterior.ORIGIN+Vector2(10,50) and game.outdoor_return==expected,"320-wide indoor save preserves room position and new exit "+house.id)
		game.exit_house(false)
		indoor["world_damage"]={"house:"+house.id:0.0}
		_write_save(game,indoor)
		game._load_save()
		test.expect(not game.world.in_interior and game.player.position==expected and game.world.destruction.broken("house:"+house.id),"old destroyed interior resumes outside relocated ruin "+house.id)
	_write_save(game,baseline)
	game._load_save()
	test.expect(World.migrate_outdoor_position(Vector2(6000,4000),4)==Vector2(6000,4000),"unmoved wilderness saves retain their geographic position")

func _write_save(game: Node, data: Dictionary) -> void:
	var file:=FileAccess.open(game.SAVE_PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func _drag(game: Node, from: Vector2, to: Vector2, button: int) -> void:
	var motion:=InputEventMouseMotion.new()
	motion.position=from
	game.get_viewport().push_input(motion,true)
	var press:=InputEventMouseButton.new()
	press.position=from
	press.button_index=button
	press.pressed=true
	game.get_viewport().push_input(press,true)
	motion=InputEventMouseMotion.new()
	motion.position=to
	motion.relative=to-from
	motion.button_mask=MOUSE_BUTTON_MASK_LEFT if button==MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_MIDDLE
	game.get_viewport().push_input(motion,true)
	var release:=InputEventMouseButton.new()
	release.position=to
	release.button_index=button
	game.get_viewport().push_input(release,true)
	await game.get_tree().process_frame
