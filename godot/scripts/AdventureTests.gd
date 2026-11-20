class_name AdventureTests
extends RefCounted

var game: Node
var test := CanonTests.new()
var instances: Dictionary = {}

func aim(point: Vector2) -> void:
	game._update_camera(0)
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	await game.get_tree().process_frame
	var screen:Vector2=game.get_viewport().get_canvas_transform()*point
	game.get_viewport().warp_mouse(screen)
	await game.get_tree().process_frame
	var motion:=InputEventMouseMotion.new()
	motion.position=game.get_viewport().get_canvas_transform()*point
	game.get_viewport().warp_mouse(motion.position)
	game.get_viewport().push_input(motion,true)
	# Leave the injected aim as the last event before the caller casts.

func cast(id: String, point: Vector2) -> void:
	game.player.yuan=44
	game.player.aperture.rank=2 if id=="moon_glow" else 1
	game.player.utility_gu.cooldowns.clear()
	game.equip_gu(instances[id].id,0)
	game.player.cast_cds[0]=0
	game.projectiles.clear()
	await aim(point)
	var screen:Vector2=game.get_viewport().get_canvas_transform()*point
	test.expect(game.get_viewport().get_mouse_position().distance_to(screen)<=2,"actual cast aims at requested world point: "+id)
	game.cast_skill(0)
	if not game.projectiles.is_empty() and absf(game.projectiles[0].ground_range-game.player.position.distance_to(point))>3: print("AIM DEBUG expected=%s mouse=%s pr=%s" % [point,game.get_global_mouse_position(),game.projectiles[0]])
	test.expect(game.projectiles.size()==1 and game.player.yuan<44,"actual cast consumes essence and launches "+id)
	for i in 16: game._update_projectiles(0.04)

func render(label: String) -> void:
	game.logs.clear()
	if label in ["mountain","swimming"]: game.reaction_events.clear()
	game.paused=true
	game.fog.reveal(game.player.position,500)
	game._update_camera(0)
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	test.expect(game.get_viewport().get_texture().get_image().save_png("res://shot_adventure_"+label+".png")==OK,"rendered "+label)
	game.paused=false

func shore(layer: int) -> Dictionary:
	game.world.layer=layer
	var size:=TerrainLayers.size_for(layer)
	for y in range(2,size.y-2):
		for x in range(2,size.x-2):
			var water:=TerrainLayers.center(Vector2i(x,y))
			if not game.world.water_at(water): continue
			for dir in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				var land:Vector2=water+dir*32
				if not game.world.water_at(land) and not game.world.collides(land.x,land.y,12) and not game.world.collides(water.x,water.y,12,true): return {"land":land,"water":water}
	return {}

func run(main: Node) -> void:
	game=main
	test.game=game
	game.set_process(false)
	game.start_game()
	CanonTests.prepare_cultivator(game)
	game.player.body.reset_full()
	for id in ["moon_blade","moon_glow","stream_gu","ember_moth","frost_midge","vine_spider"]:
		var gu:GuVirtual=game.get_node("/root/Gus").add_gu(id)
		gu.location="aperture"
		game.player.owned.append(id)
		instances[id]=gu
	game.change_layer(1,Vector2(1424,528),false)
	var target:Vector2=game.player.position+Vector2(0,64)
	var cell:=TerrainLayers.cell_at(target)
	for id in instances:
		game.world.blocks.damage.clear()
		game.world.environment.cells.clear()
		var hp:float=game.world.blocks.info(cell,1).hp
		await cast(id,target)
		test.expect((game.world.blocks.info(cell,1).is_empty() or game.world.blocks.info(cell,1).hp<hp),"Gu damages same-height floor aimed down: "+id)
		test.expect(game.projectiles.is_empty(),"projectile terminates at aim point: "+id)
	# Zero resources must never damage terrain or start reactions.
	game.player.yuan=0
	game.player.cast_cds[0]=0
	game.player.utility_gu.cooldowns.clear()
	var unchanged:Dictionary=game.world.blocks.save_data().duplicate(true)
	game.cast_skill(0)
	test.expect(game.projectiles.is_empty() and game.world.blocks.save_data()==unchanged,"empty essence cannot excavate")
	# A projectile stops at the first intact cave wall, even when aimed beyond it.
	game.world.blocks.damage.clear()
	game.change_layer(1,Vector2(528,592),false)
	var wall:=Vector2i.ZERO
	for y in range(10,26):
		for x in range(10,26):
			var c:=Vector2i(x,y)
			if game.world.blocks.kind_at(c,1) in [1,3,4] and game.world.blocks.kind_at(c+Vector2i.DOWN,1)==0 and game.world.blocks.kind_at(c+Vector2i.DOWN*2,1)==0:
				wall=c
				break
		if wall!=Vector2i.ZERO: break
	test.expect(wall!=Vector2i.ZERO,"found actual cave wall edge")
	game.player.position=TerrainLayers.center(wall+Vector2i.DOWN*2)
	var wall_hp:float=game.world.blocks.info(wall,1).hp
	var behind:Dictionary=game.world.blocks.info(wall+Vector2i.UP,1)
	await cast("moon_blade",TerrainLayers.center(wall+Vector2i.UP))
	test.expect(game.world.blocks.info(wall,1).hp<wall_hp and game.world.blocks.info(wall+Vector2i.UP,1)==behind,"Gu hits first blocker and cannot strike beyond it")
	await reactions()
	await swimming()
	await conversation()
	game.village_ui.close()
	# Use explicit awakened capacities; creation randomness must not affect UI fixtures.
	for capacity in [20,84,99,44]:
		var aperture:=ApertureState.new()
		aperture.potential=capacity
		test.expect(aperture.awaken() and aperture.capacity==capacity,"display fixture awakens at capacity %d" % capacity)
		game.player.aperture=aperture
		test.expect(aperture.fill_ratio()==1,"full essence fills capacity %d" % capacity)
		game.player.yuan=capacity*0.5
		test.expect(aperture.fill_ratio()==0.5,"half essence fills half of capacity %d" % capacity)
	game.player.yuan=44
	test.expect(game.player.aperture.fill_ratio()==1 and game.player.aperture.amount_text()=="44.0 / 44.0","full essence is 44/44 at 100 percent of capacity")
	game.player.yuan=22
	test.expect(game.player.aperture.fill_ratio()==0.5,"half essence is half of the blue bar")
	game.player.yuan=44
	game.open_journal("aperture")
	await render("essence")
	game.journal.close()
	# Actual procedural mountain rendering retains collision and HP cell alignment.
	var peak:Vector2i=game.world.blocks.mountain_cells["0"][0]
	for c:Vector2i in game.world.blocks.mountain_cells["0"]:
		if game.world.blocks.height_at(c)>game.world.blocks.height_at(peak): peak=c
	game.change_layer(0,TerrainLayers.center(peak)+Vector2(0,96),false)
	game.hit_terrain(peak,45,Vector2.UP)
	game.set_camera_zoom(1.4)
	game.clear_waypoint(false)
	game.fx.clear_transients()
	await aim(TerrainLayers.center(peak))
	await render("mountain")
	print("ADVENTURETEST checked=%d failures=%s" % [test.checked,str(test.failures)])
	game.get_tree().quit(0 if test.failures.is_empty() else 1)

func reactions() -> void:
	game.change_layer(1,Vector2(1424,528),false)
	game.world.blocks.damage.clear()
	var point:Vector2=game.player.position+Vector2(64,0)
	var cell:=TerrainLayers.cell_at(point)
	await cast("frost_midge",point)
	var hp:float=game.world.blocks.info(cell,1).hp
	await cast("ember_moth",point)
	test.expect(game.world.blocks.info(cell,1).is_empty() or game.world.blocks.info(cell,1).hp<hp-float(GameData.GU.ember_moth.skill.dmg),"frozen ground gets extra thermal fracture damage")
	test.expect(game.reaction_events.any(func(e:Dictionary): return e.title=="冷热崩裂"),"reaction records actual thermal fracture")
	# Use a real person with the same shared status path as actual projectile hits.
	game.change_layer(0,Vector2(512,1040),false)
	var person:Npc=game.npc
	game.world.environment.react_actor(game,person,{"gu_id":"ember_moth","burn":3.0})
	game.world.environment.react_actor(game,person,{"gu_id":"stream_gu"})
	var state:Dictionary=game.player.utility_gu.person_status[person.resident_id]
	test.expect(state.burn==0 and state.wet>0,"water extinguishes real actor burning")
	game.world.environment.react_actor(game,person,{"gu_id":"frost_midge","slow":3.0})
	test.expect(state.frozen==2 and game.player.utility_gu.person_speed(person)==0,"wet then frost freezes movement")
	game.paused=true
	game.player.utility_gu.tick(1,game)
	test.expect(state.frozen==2,"freeze pauses with menu")
	game.paused=false
	game.player.utility_gu.tick(2.1,game)
	test.expect(state.frozen==0 and game.player.utility_gu.person_speed(person)>0,"freeze wears off")
	game.player.utility_gu.person_status.clear()
	var wood_id:=""
	for id in game.world.destruction.objects:
		if game.world.destruction.objects[id].kind=="tree":
			wood_id=id
			break
	var obj:Dictionary=game.world.destruction.objects[wood_id]
	cell=TerrainLayers.cell_at(Rect2(obj.rect).get_center())
	game.world.environment.react_cell(game,cell,{"gu_id":"ember_moth"},{"id":wood_id})
	var wood_hp:float=obj.hp
	game.world.environment.tick(1,game)
	test.expect(obj.hp<wood_hp,"wood ignition deals persistent real object damage")
	game.world.environment.react_cell(game,cell,{"gu_id":"stream_gu"})
	wood_hp=obj.hp
	game.world.environment.tick(1,game)
	test.expect(obj.hp==wood_hp,"water stops wood burning damage")
	game.world.environment.cells.clear()
	var slot:=""
	for actor:Enemy in game.active_enemies():
		if not actor.wildlife_slot.is_empty():
			slot=actor.wildlife_slot
			actor.status.frozen=2.0
			actor.status.bind=3.0
			break
	test.expect(slot!="","found persistent wildlife for status save")
	game._load_save(game._snapshot().duplicate(true))
	var restored:=false
	for actor:Enemy in game.active_enemies():
		if actor.wildlife_slot==slot: restored=actor.status.frozen==2.0 and actor.status.bind==3.0
	test.expect(restored,"wildlife freeze and bind survive character save load")

func swimming() -> void:
	for layer in [0,1,2]:
		var pair:=shore(layer)
		test.expect(not pair.is_empty(),"found water and accessible shore on layer %d" % layer)
		if pair.is_empty(): continue
		game.change_layer(layer,pair.land,false)
		var displacement:Vector2=pair.water-pair.land
		game.world.move_body(game.player,displacement.x,displacement.y,12)
		game.player.status.burn=3
		game.update_water_state()
		test.expect(game.player.position.distance_to(pair.water)<1 and game.player.swimming,"player can enter water on layer %d" % layer)
		test.expect(game.player.status.burn==0 and game.player.status.wet>0 and not game.can_meditate(),"water extinguishes player, applies wet and prevents meditation")
		test.expect(game.world.water_speed(pair.water)<1 and game.world.collides(pair.water.x,pair.water.y,12),"water slows player while preserving land NPC collision")
		game.save_game()
		var snapshot:Dictionary=game._snapshot().duplicate(true)
		game._load_save(snapshot)
		test.expect(game.player.position.distance_to(pair.water)<1 and game.player.swimming,"swimming position survives save on layer %d" % layer)
		game.world.environment.react_cell(game,TerrainLayers.cell_at(pair.water),{"gu_id":"frost_midge"})
		game.update_water_state(false)
		test.expect(not game.player.swimming and game.world.water_speed(pair.water)==0.9,"ice supports walking without swimming")
		var state:Dictionary=game.world.environment.save_data()
		game.world.environment.load_data(state)
		test.expect(game.world.environment.save_data()==state,"environment save restores remaining ice duration")
		game.paused=true
		game.world.environment.tick(2,game)
		test.expect(game.world.environment.save_data()==state,"ice timer pauses")
		game.paused=false
		game.world.environment.tick(6.1,game)
		game.update_water_state(false)
		test.expect(game.player.swimming,"melting ice returns safely to swimming")
		if layer==0:
			await aim(pair.water+Vector2(32,0))
			await render("swimming")
		if layer==2:
			await cast("frost_midge",pair.water+Vector2(32,0))
			await render("elements")
		game.world.move_body(game.player,-displacement.x,-displacement.y,12)
		game.update_water_state(false)
		test.expect(not game.player.swimming and game.player.position.distance_to(pair.land)<1,"player can return to shore on layer %d" % layer)
	# Environment fields are optional in old characters and reject malformed input.
	var invalid:Dictionary={"9:1:1":{"layer":9,"x":1,"y":1},"0:-1:2":{"layer":0,"x":-1,"y":2}}
	game.world.environment.load_data(invalid)
	test.expect(game.world.environment.cells.is_empty(),"invalid reaction layer and coordinates rejected")

func conversation() -> void:
	game.change_layer(0,Vector2(512,1040),false)
	var person:Npc=game.npc
	person.position=Vector2(544,1040)
	person.hp=70
	person.hostile=false
	person.conversation.clear()
	game.talk_to_person(person)
	test.expect(game.village_ui.visible and game.village_ui.mode=="conversation" and game.paused,"talk opens actual conversational choices")
	await test.click(game.village_ui.actions.get_node("Talk_life"))
	test.expect(person.conversation.has("life") and game.village_ui.description.text.contains("带着伤"),"real topic button responds to current injury and remembers meeting")
	await test.click(game.village_ui.actions.get_node("Talk_cultivation"))
	test.expect(game.village_ui.title.text.contains("熟识") and game.village_ui.description.text.contains("44 / 44"),"familiarity and explanation update through conversation")
	await test.click(game.village_ui.actions.get_node("Talk_road"))
	test.expect(game.waypoint!=Vector2.ZERO and game.waypoint_layer==0,"conversation directions create a usable map waypoint")
	var inv:Inventory=game.get_node("/root/Inv")
	inv.add_item("bandage",1)
	var amount:=inv.get_item_count("bandage")
	var before:float=person.hp
	NpcConversation.reply(game,person,"care")
	test.expect(inv.get_item_count("bandage")==amount-1 and person.hp==before+18,"helping an injured person consumes real bandage and restores health")
	game.village_ui.show_conversation(person,NpcConversation.reply(game,person,"life"))
	await render("conversation")
	game.village_ui.close()
	var saved:=person.save_data()
	person.conversation.clear()
	person.load_data(saved)
	test.expect(person.conversation.has("life") and person.conversation.has("care"),"social memory and care survive loading")
	person.hostile=true
	before=person.hp
	NpcConversation.reply(game,person,"care")
	test.expect(person.hp==before and game.person_talk_blocker(person)!="","hostile people reject conversation and treatment")
	person.load_data(saved)
