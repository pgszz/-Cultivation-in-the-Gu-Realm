class_name GameFeatureTests
extends RefCounted

var failures: Array[String]=[]
var checked := 0
var game: Node

func expect(condition: bool, message: String) -> void:
	checked+=1
	if not condition:
		failures.append(message)
		print("FEATURETEST FAIL "+message)

func click_at(pos: Vector2, button: int = MOUSE_BUTTON_LEFT) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position=pos
	motion.global_position=pos
	game.get_viewport().push_input(motion,true)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position=pos
		event.global_position=pos
		event.button_index=button
		event.pressed=pressed
		game.get_viewport().push_input(event,true)
	await game.get_tree().process_frame

func key(code: int) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode=code
		event.pressed=pressed
		game.get_viewport().push_input(event,true)
	await game.get_tree().process_frame

func settle() -> void:
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	await game.get_tree().process_frame

func run(main: Node) -> void:
	game=main
	game.set_process(false)
	await settle()
	await click_at(game.start_btn.get_global_rect().get_center())
	expect(game.running,"start button receives real GUI mouse events")
	await click_at(game.hud.quickbar.get_child(1).get_global_rect().get_center())
	expect(game.journal.visible and game.journal.active_page=="body","HUD body button routes to journal")
	await settle()
	var diagram: BodyDiagram=game.body_ui.diagram
	await click_at(diagram.global_position+diagram.hit_regions.leg_l.get_center())
	expect(game.body_ui.selected_part=="leg_l","anatomy leg click selects correct character side")
	await settle()
	expect(game.body_ui.part_scroll.scroll_vertical>0,"selected lower limb is scrolled into view")
	await click_at(game.journal.tabs.inventory.get_global_rect().get_center())
	expect(game.journal.active_page=="inventory","journal tab click changes page")
	var zoom: float=game.zoom_level
	await click_at(game.inventory_ui.slots[10].get_global_rect().get_center(),MOUSE_BUTTON_WHEEL_DOWN)
	expect(is_equal_approx(game.zoom_level,zoom),"scrolling inventory does not zoom world")
	await key(KEY_TAB)
	expect(not game.journal.visible and not game.paused,"Tab closes journal even with a focused GUI button")
	await click_at(Vector2(640,360),MOUSE_BUTTON_WHEEL_UP)
	expect(game.zoom_level>zoom,"world mouse wheel zooms in")
	game.set_camera_zoom(20)
	expect(is_equal_approx(game.zoom_level,1.75),"zoom upper bound")
	game.set_camera_zoom(-20)
	expect(is_equal_approx(game.zoom_level,0.65),"zoom lower bound")
	game.set_camera_zoom(1.0)
	await key(KEY_V)
	expect(game.journal.active_page=="elements" and game.journal.visible,"V opens element reaction reference")
	await key(KEY_ESCAPE)
	expect(not game.journal.visible,"Escape closes reference")
	game.player.position=World.HOUSE_DATA[0].pos+Vector2(0,40)
	await key(KEY_E)
	expect(game.world.in_interior and game.current_house_id=="clinic","E enters correct house")
	game.player.position=HouseInterior.ORIGIN+Vector2(0,184)
	await key(KEY_E)
	expect(not game.world.in_interior,"E exits house")
	game.paused=true
	var body: BodyComponent=game.player.body
	body.reset_full()
	var full_radius: float=game.fog.radius_world()
	body.apply_hit("eye_l",2)
	expect(game.fog.radius_world()<full_radius and game.fog.radius_world()>full_radius*0.5,"partial eye injury continuously shrinks vision")
	body.apply_hit("eye_l",100)
	expect(is_equal_approx(game.fog.radius_world(),full_radius*0.5),"one destroyed eye halves vision")
	body.apply_hit("eye_r",100)
	expect(is_equal_approx(game.fog.radius_world(),full_radius*0.12),"two destroyed eyes retain only nearby awareness")
	body.stop_bleed()
	body.apply_hit("hand_l",10)
	body.stop_bleed("hand_l")
	var hand_hp: float=body.parts.hand_l.hp
	body.tick(4)
	expect(is_equal_approx(float(body.parts.hand_l.hp),hand_hp),"natural healing waits after hit")
	for i in 20: body.tick(1)
	expect(float(body.parts.hand_l.hp)>hand_hp,"ordinary limb heals over game time")
	expect(body.parts.eye_l.destroyed and body.parts.eye_l.hp==0,"destroyed eye never regrows over time")
	body.reset_full()
	game.fog.reveal(game.player.position,full_radius)
	var explored: Array=game.fog.explored.keys()
	game.fog.load_data(explored)
	expect(game.fog.discovered(game.player.position),"exploration restores")
	game.set_camera_zoom(0.65)
	expect(is_equal_approx(game.fog.radius_world(),full_radius),"zoom cannot expand world vision")
	game.set_camera_zoom(1)
	# Projectile path must reach a real NPC, provoke hostility and stop on impact.
	game.player.position=Vector2(800,1100)
	game.npc.position=Vector2(860,1100)
	var npc_hp: float=game.npc.hp
	game.spawn_projectile(game.player.position,Vector2(300,0),12,"fire","player",{})
	game._update_projectiles(0.2)
	expect(game.npc.hp<npc_hp and game.npc.hostile,"projectile damages NPC and provokes hostility")
	game.npc.take_damage(9999,game)
	expect(game.npc.dead and game.npc.hp==0,"NPC can die")
	game.paused=false
	game._open_npc_dialogue()
	expect(not game.dialogue_layer.visible,"dead NPC cannot open quest dialogue")
	game.paused=true
	var destruct: DestructionSystem=game.world.destruction
	var tree_id := ""
	for id in destruct.objects:
		if destruct.objects[id].kind=="tree":
			tree_id=id
			break
	var tree: Dictionary=destruct.objects[tree_id]
	game.strike_world(tree.rect.get_center(),1,9999,"fire",Vector2.ZERO,-1,false)
	expect(destruct.broken(tree_id),"tree receives attack damage")
	expect(game.world.tile_at(tree.tile.x,tree.tile.y)==GameData.T_GRASS,"destroyed tree clears terrain collision")
	var materials: int=game.player.materials
	game.strike_world(tree.rect.get_center(),1,9999,"fire",Vector2.ZERO,-1,false)
	expect(game.player.materials==materials,"rubble cannot be farmed repeatedly")
	var house: Dictionary=World.HOUSE_DATA[1]
	game.strike_world(house.pos+Vector2(0,-20),2,9999,"earth",Vector2.ZERO,-1,false)
	expect(destruct.broken("house:shop"),"house can be destroyed")
	expect(game.world.house_at(house.pos+Vector2(0,40)).is_empty(),"ruined house cannot be entered")
	expect(not game.world.collides(house.pos.x,house.pos.y-20,12),"ruined house no longer blocks movement")
	game.enter_house(World.HOUSE_DATA[2])
	var wall: Rect2=destruct.objects["interior:home:wall_w"].rect
	expect(game.world.collides(wall.get_center().x,wall.get_center().y,12),"intact room wall blocks movement")
	game.strike_world(wall.get_center(),1,9999,"earth",Vector2.ZERO,-1,false)
	expect(not game.world.collides(wall.get_center().x,wall.get_center().y,12),"destroyed room wall becomes passable")
	var bed: Rect2=destruct.objects["interior:home:bed"].rect
	game.strike_world(bed.get_center(),1,9999,"fire",Vector2.ZERO,-1,false)
	expect(game.world.interior.interaction_at(HouseInterior.ORIGIN+Vector2(-214,-40))!="rest","destroyed bed cannot provide rest")
	body.reset_full()
	game.player.position=HouseInterior.ORIGIN+Vector2(0,0)
	game.paused=false
	await key(KEY_J)
	expect(game.meditating,"J starts meditation inside home")
	var xp: float=game.player.xiuwei
	game._update_meditation(10)
	expect(game.player.xiuwei>xp,"meditation grants cultivation without kills")
	game.paused=true
	xp=game.player.xiuwei
	game._update_meditation(10)
	expect(is_equal_approx(game.player.xiuwei,xp),"paused menus do not advance meditation")
	game.paused=false
	game._update_meditation(60)
	expect(game.player.rank>=2,"meditation reaches breakthrough threshold")
	game.player.iframes=0
	game.damage_player(2,"none")
	expect(not game.meditating,"being hit interrupts meditation")
	expect(not game.can_meditate(),"recent injury prevents immediate meditation")
	body.reset_full()
	game.player.iframes=0
	game.enter_house(World.HOUSE_DATA[0])
	game.exit_house()
	game.enter_house(World.HOUSE_DATA[0])
	var healer: Npc=game.residents.clinic
	healer.take_damage(9999,game)
	expect(not game.service_available("clinic"),"dead indoor resident stops providing service")
	expect(not game.clinic_heal(),"dead healer cannot remotely repair body")
	game.exit_house()
	# Check actual reactions and the same events consumed by the UI.
	var enemy := Enemy.new()
	enemy.setup("stone_armor")
	enemy.max_hp=999
	enemy.hp=999
	enemy.position=game.player.position+Vector2(120,0)
	game.enemies_root.add_child(enemy)
	game.enemies.append(enemy)
	enemy.status.wet=3
	var enemy_hp := enemy.hp
	game.apply_status(enemy,"fire")
	expect(enemy.hp<enemy_hp and enemy.status.wet==0,"steam consumes wet and deals damage")
	expect(game.reaction_events[0].title=="蒸汽","reaction HUD receives actual steam event")
	enemy.status.poison=3
	game.apply_status(enemy,"fire")
	expect(enemy.status.burn>=5 and enemy.status.poison==0,"blight consumes poison and ignites")
	enemy.status.wet=3
	game.apply_status(enemy,"thunder")
	expect(enemy.stun>=0.6,"shock applies actual stun")
	enemy.status.wet=0
	enemy.status.burn=0
	enemy.status.poison=0
	game.apply_status(enemy,"fire")
	expect(not game.fx.hazards.is_empty(),"fire on earth generates lava")
	enemy_hp=enemy.hp
	game._update_hazards(0.5)
	expect(enemy.hp<enemy_hp,"lava hazard deals advertised periodic damage")
	game._update_reaction_events(7)
	expect(game.reaction_events.is_empty(),"reaction notices expire")
	game.save_game()
	game.npc.load_data({})
	healer.load_data({})
	game._load_save()
	expect(game.npc.dead and healer.dead,"NPC death persists through save")
	expect(destruct.broken("house:shop") and destruct.broken("interior:home:wall_w"),"house and room destruction persist")
	expect(game.player.rank>=2 and game.player.xiuwei>100,"meditation progress persists")
	expect(game.fog.discovered(game.player.position) or not game.fog.explored.is_empty(),"explored map persists")
	print("FEATURETEST checked=%d failures=%s" % [checked,str(failures)])
	game.get_tree().quit(0 if failures.is_empty() else 1)
