class_name PopulationTests
extends RefCounted

var game: Node
var checked:=0
var failures:Array[String]=[]

func expect(value: bool, label: String) -> void:
	checked+=1
	if not value:
		failures.append(label)
		print("POPULATIONTEST FAIL "+label)

func key(code: int) -> void:
	for pressed in [true,false]:
		var event:=InputEventKey.new()
		event.keycode=code
		event.pressed=pressed
		game.get_viewport().push_input(event,true)
	await game.get_tree().process_frame

func click(button: Button) -> void:
	await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=pressed
		event.position=button.get_global_rect().get_center()
		game.get_viewport().push_input(event,true)
	await game.get_tree().process_frame

func run(main: Node) -> void:
	game=main
	game.set_process(false)
	game.start_game()
	CanonTests.prepare_cultivator(game)
	var population:PopulationSystem=game.population
	expect(population.actors.size()==30+CanonPeople.ORDER.size(),"ordinary population and named canon people are attached to the main game")
	var roles:Dictionary={}
	var links:Dictionary={}
	var start_positions:Dictionary={}
	for person:WorldPerson in population.actors.values():
		roles[person.role]=true
		start_positions[person.resident_id]=person.position
		expect(person in game.active_npcs() and not game.enemies.any(func(enemy:Enemy): return enemy.get_instance_id()==person.get_instance_id()),"person participates in interaction and combat without becoming wildlife "+person.resident_id)
		expect(not population.outdoor_blocked(person.position),"person starts outside terrain and buildings "+person.resident_id)
		for i in person.route.size():
			var from:=Vector2i(person.route[i]/32)
			var to:=Vector2i(person.route[(i+1)%person.route.size()]/32)
			var id:=str(from)+str(to)
			if links.has(id): continue
			links[id]=true
			expect(not population.navigation.get_id_path(from,to).is_empty(),"route is connected through the actual map "+id)
	expect(roles.size()==9,"ordinary occupations and canon cultivators have separate roles")
	for frame in 320: population.tick(0.1)
	var moved:=0
	for person:WorldPerson in population.actors.values():
		if person.position.distance_to(start_positions[person.resident_id])>24: moved+=1
		expect(not population.outdoor_blocked(person.position),"walking preserves terrain collision "+person.resident_id)
	expect(moved>=22,"daytime routes move people across all districts")
	var merchant:WorldPerson=population.actors.caravan_merchant
	expect(merchant.position.distance_to(start_positions.caravan_merchant)>50,"caravan leaves its stop by walking")
	expect(population.actors.bai_patrol_0.position.distance_to(start_positions.bai_patrol_0)>30,"distant patrol continues without being teleported or despawned")
	var frozen:=merchant.position
	var clock:=population.day_clock
	var motion:=merchant.animation.clock
	game.paused=true
	population.tick(10)
	expect(merchant.position==frozen and population.day_clock==clock and merchant.animation.clock==motion,"menu pauses movement schedule and animation")
	game.paused=false
	game.enter_house(World.HOUSE_DATA[2])
	population.tick(10)
	expect(merchant.position==frozen and merchant not in game.active_npcs() and not merchant.visible,"indoor scene hides and pauses outdoor people")
	game.exit_house(false)
	game.player.dead=true
	population.tick(10)
	expect(population.day_clock==clock,"player death freezes the outdoor schedule")
	game.player.dead=false
	var citizen:WorldPerson=population.actors.guyue_civil_0
	population.day_clock=1100
	citizen.wait_left=0
	population.tick(0.1)
	expect(citizen.activity=="归家歇息","night schedule sends civilians home")
	population.day_clock=480
	# Nearby E and real GUI purchase use the same validation as normal play.
	merchant.position=population.walkable_position(Vector2(816,1008))
	merchant.target=null
	merchant.flee_left=0
	for offset in [Vector2(0,36),Vector2(0,-36),Vector2(36,0),Vector2(-36,0)]:
		var nearby:Vector2=merchant.position+offset
		if not game.world.collides(nearby.x,nearby.y,12) and game.world.conversation_clear(nearby,merchant.position):
			game.player.position=nearby
			break
	game._update_camera(0)
	game.camera.reset_smoothing()
	await key(KEY_E)
	if game.village_ui.mode!="conversation": print("TALK DEBUG mode=%s msg=%s blocker=%s player=%s merchant=%s" % [game.village_ui.mode,game.last_action_message,game.person_talk_blocker(merchant),game.player.position,merchant.position])
	expect(game.village_ui.visible and game.village_ui.mode=="conversation" and game.paused,"E opens conversation with nearby moving merchant")
	await click(game.village_ui.actions.get_node("Talk_service"))
	var inv:Inventory=game.get_node("/root/Inv")
	game.player.crystals=30
	var supplies:=inv.get_item_count("bandage")
	var stock:int=population.stock.bandage
	await click(game.village_ui.caravan_buttons.bandage)
	expect(game.player.crystals==28 and inv.get_item_count("bandage")==supplies+1 and population.stock.bandage==stock-1,"merchant GUI atomically charges money delivers goods and reduces finite stock")
	game.player.crystals=0
	expect(not population.buy(merchant,"bandage") and population.stock.bandage==stock-1,"insufficient money cannot consume merchant stock")
	game.village_ui.close()
	game.player.position+=Vector2(200,0)
	game.player.crystals=30
	expect(not population.buy(merchant,"bandage") and game.player.crystals==30,"distant purchases are rejected")
	# Combat includes a real wind-up and an independently checked strike.
	var bandit:WorldPerson=population.actors.east_bandit_0
	var arena:=bandit.home
	for i in 100:
		var candidate:=population.walkable_position(bandit.home+Vector2((i%10-5)*32,(int(i/10)-5)*32))
		if not population.outdoor_blocked(candidate+Vector2(34,0)) and not population.peaceful_area(candidate):
			arena=candidate
			break
	bandit.position=arena
	game.player.position=arena+Vector2(34,0)
	game.player.iframes=0
	game.player.shield=0
	game.player.jade_guard=false
	game.player.hp=game.player.max_hp
	bandit.target=game.player
	bandit.attack_timer=0
	bandit.hurt_timer=0
	var hp:float=game.player.hp
	population.update_person(bandit,0.1)
	expect(bandit.strike_left>0 and game.player.hp==hp,"bandit begins a readable attack before dealing damage")
	population.update_person(bandit,0.3)
	expect(game.player.hp<hp,"bandit strike damages the actual player")
	var hit_hp:float=game.player.hp
	game.player.iframes=0
	population.update_person(bandit,0.1)
	expect(game.player.hp==hit_hp,"one bandit swing cannot hit twice")
	bandit.strike_left=0
	bandit.attack_timer=0
	population.update_person(bandit,0.1)
	game.player.position=arena+Vector2(120,0)
	population.update_person(bandit,0.3)
	expect(game.player.hp==hit_hp,"moving outside reach during wind-up evades a bandit")
	game.player.position=arena+Vector2(34,0)
	bandit.strike_left=0
	bandit.attack_timer=0
	population.update_person(bandit,0.1)
	bandit.take_damage(1,game)
	population.update_person(bandit,0.3)
	expect(bandit.strike_left==0 and game.player.hp==hit_hp,"hurting a bandit cancels pending damage")
	game.player.position=GameData.BONFIRE
	expect(not population.valid_target(bandit,game.player),"bandits cannot pursue a target into a safe settlement")
	merchant.position=arena+Vector2(34,0)
	merchant.target=null
	bandit.target=merchant
	bandit.strike_left=0
	bandit.attack_timer=0
	bandit.hurt_timer=0
	var merchant_hp:=merchant.hp
	population.update_person(bandit,0.1)
	population.update_person(bandit,0.3)
	expect(merchant.hp<merchant_hp and merchant.target==bandit,"bandits can attack the caravan independently of the player")
	var old_pos:=merchant.position
	merchant.hurt_timer=0
	population.path_budget=3
	population.update_person(merchant,0.2)
	expect(merchant.activity=="避险逃离" and merchant.position!=old_pos and not merchant.hostile,"civilian merchant flees an NPC attack without becoming hostile to the player")
	var escort:WorldPerson=population.actors.caravan_guard_a
	escort.position=arena-Vector2(32,0)
	escort.target=null
	population.find_target(escort)
	expect(escort.target==bandit,"caravan escort acquires a nearby bandit to defend the party")
	var guard:WorldPerson=population.actors.guyue_patrol_0
	guard.position=citizen.position+Vector2(40,0)
	citizen.take_damage(1,game)
	expect(citizen.hostile and guard.hostile and guard.target==game.player,"attacking a civilian provokes a nearby patrol")
	var coins:float=game.player.crystals
	var cultivation:float=game.player.xiuwei
	bandit.take_damage(999,game)
	bandit.take_damage(999,game)
	expect(bandit.dead and game.player.crystals==coins and game.player.xiuwei==cultivation,"person death is permanent and does not grant automatic money or cultivation")
	merchant.position=population.walkable_position(Vector2(1808,1328))
	merchant.route_index=2
	merchant.wait_left=7.0
	population.stock.bandage=2
	population.restock_left=271
	population.day_clock=777
	game.save_game()
	var saved_position:=merchant.position
	game._load_save()
	merchant=population.actors.caravan_merchant
	expect(merchant.position==saved_position and merchant.route_index==2 and is_equal_approx(merchant.wait_left,7),"save restores a caravan in the middle of its route")
	expect(population.actors.east_bandit_0.dead and population.actors.guyue_patrol_0.hostile,"death and hostility persist through actual reload")
	expect(population.stock.bandage==2 and population.restock_left==271 and population.day_clock==777,"stock restock delay and schedule persist without offline advancement")
	game._load_save()
	await game.get_tree().process_frame
	var count:=0
	for child in game.get_children():
		if child is WorldPerson: count+=1
	expect(count==30+CanonPeople.ORDER.size() and population.actors.size()==count,"repeated reload cannot duplicate people")
	game.enter_house(World.HOUSE_DATA[2])
	game.save_game()
	game._load_save()
	expect(game.world.in_interior and not population.actors.caravan_merchant.visible,"loading inside a building keeps outdoor people hidden")
	game.exit_house(false)
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.SAVE_PATH))
	data.erase("population")
	var file:=FileAccess.open(game.SAVE_PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	game._load_save()
	expect(population.actors.size()==30+CanonPeople.ORDER.size() and population.stock.bandage==8,"old saves without population data receive one default population")
	game.exit_house(false)
	game.paused=false
	game.player.position=GameData.BONFIRE
	await long_journey(population)
	print("POPULATIONTEST checked=%d moved=%d routes=%d failures=%s"%[checked,moved,links.size(),str(failures)])
	game.get_tree().quit(0 if failures.is_empty() else 1)

func long_journey(population: PopulationSystem) -> void:
	population.load_data(null)
	var merchant:WorldPerson=population.actors.caravan_merchant
	var destinations:Dictionary={}
	var max_step:=0.0
	for frame in 6000:
		var previous:=merchant.position
		population.tick(0.2)
		max_step=maxf(max_step,previous.distance_to(merchant.position))
		destinations[merchant.route_index]=true
		if frame%600==0:
			print("POPULATION journey seconds=%d next=%d activity=%s position=%s"%[frame/5,merchant.route_index,merchant.activity,str(merchant.position)])
			if frame==600:
				for id in population.caravan_ids:
					var member:WorldPerson=population.actors[id]
					print("POPULATION member=%s position=%s goal=%s path=%d/%d blocked=%.2f activity=%s"%[id,str(member.position),str(member.path_goal),member.path_index,member.path.size(),member.blocked_time,member.activity])
			await game.get_tree().process_frame
	expect(not merchant.dead and destinations.has(4) and destinations.has(6),"twenty simulated minutes carry the caravan through Bai and Xiong stops")
	expect(max_step<=merchant.speed*1.45*0.2+0.1,"long caravan travel never teleports between route points")
	for id in population.caravan_ids:
		var member:WorldPerson=population.actors[id]
		expect(not member.dead and not population.outdoor_blocked(member.position) and member.position.distance_to(merchant.position)<400,"caravan member survives and stays with the long journey "+id)
	var saved:=population.save_data()
	# Supply must require both a settlement arrival and the elapsed cooldown.
	for condition in [[1,0.0,false],[3,200.0,false],[3,0.0,true]]:
		merchant.route_index=condition[0]
		merchant.position=merchant.route[merchant.route_index]
		merchant.wait_left=0
		merchant.target=null
		merchant.flee_left=0
		merchant.hurt_timer=0
		for id in population.caravan_ids:
			population.actors[id].position=merchant.position
		population.stock.bandage=0
		population.restock_left=condition[1]
		population.update_person(merchant,0.1)
		expect((population.stock.bandage==8)==condition[2],"restock is gated by arrival and time "+str(condition))
	population.load_data(saved)
	merchant=population.actors.caravan_merchant
	merchant.route_index=5
	merchant.wait_left=9
	var porter:WorldPerson=population.actors.caravan_porter
	porter.route_index=1
	var previous:=porter.position
	merchant.receive_hit(999,null)
	expect(population.caravan_leader()==porter and porter.position==previous and porter.route_index==5 and porter.wait_left==9,"surviving porter inherits the dead leader's destination without teleporting")
	game.save_game()
	game._load_save()
	expect(population.actors.caravan_merchant.dead and population.actors.caravan_merchant.activity=="已死亡" and population.caravan_leader().resident_id=="caravan_porter" and population.caravan_leader().route_index==5,"dead merchant and successor route survive reload")

static func capture(game: Node, scenario: String) -> void:
	game.start_game()
	CanonTests.prepare_cultivator(game)
	game.set_process(false)
	var population:PopulationSystem=game.population
	var observer:=Vector2(560,1104)
	if scenario=="population":
		for frame in 160: population.tick(0.1)
	elif scenario in ["caravan","populationmotion"]:
		for frame in 540: population.tick(0.1)
		observer=population.actors.caravan_merchant.position+Vector2(0,120)
	elif scenario=="bandits": observer=population.actors.east_bandit_0.position+Vector2(96,96)
	elif scenario=="caravantrade": observer=population.actors.caravan_merchant.position+Vector2(0,36)
	game.player.position=game.world.safe_outdoor_position(observer)
	for person in game.active_npcs(): person.player_pos=game.player.position
	if scenario in ["population","caravan","bandits"]:
		# Art evidence: keep the new ground-inspection card from covering the group.
		game.hud.hide()
		game.set_camera_zoom(1.25)
	game._update_camera(0)
	game.camera.reset_smoothing()
	game.fog.reveal(game.player.position,game.fog.radius_world())
	if scenario=="caravantrade": game.village_ui.show_traveler(population.actors.caravan_merchant)
	else: game.paused=true
	await game.get_tree().create_timer(0.6).timeout
	if scenario=="populationmotion":
		DirAccess.make_dir_recursive_absolute("res://population_frames")
		game.paused=false
		for frame in 90:
			population.tick(1.0/15.0)
			await game.get_tree().process_frame
			await RenderingServer.frame_post_draw
			var frame_error:=game.get_viewport().get_texture().get_image().save_png("res://population_frames/%03d.png"%frame)
			if frame_error!=OK:
				game.get_tree().quit(1)
				return
		game.paused=true
	await RenderingServer.frame_post_draw
	var error:=game.get_viewport().get_texture().get_image().save_png("res://shot_"+scenario+".png")
	print("SHOT population scenario=%s err=%d"%[scenario,error])
	game.get_tree().quit(0 if error==OK else 1)
