class_name WildlifeTests
extends RefCounted

var checked:=0
var failures:Array[String]=[]
var game:Node

func expect(value: bool, message: String) -> void:
	checked+=1
	if not value:
		failures.append(message)
		print("WILDLIFETEST FAIL "+message)

func run(main: Node) -> void:
	game=main
	game.set_process(false)
	game.wildlife.rng.seed=20261118
	game.start_game()
	CanonTests.prepare_cultivator(game)
	var ecology:WildlifeSystem=game.wildlife
	var player:Player=game.player
	var species:Dictionary={}
	var initial_count:int=game.enemies.size()
	expect(initial_count==35,"all thirteen habitats contain their initial 35 residents")
	for actor in game.enemies:
		expect(actor.is_animal!=actor.is_monster and actor.is_monster==MonsterSystem.WILDLIFE.has(actor.kind),"animal and monster identities are exclusive "+actor.kind)
		species[actor.kind]=true
		expect(actor.data.id==actor.kind and actor.kind!="beast","species identity preserved "+actor.kind)
		expect(not game.world.collides(actor.position.x,actor.position.y,actor.radius),"resident has physical clearance "+actor.wildlife_slot)
		expect(actor.position.distance_to(player.position)>=640 and not ecology.is_safe_area(actor.position),"initial residents outside player safety zones "+actor.wildlife_slot)
	for id in WildlifeSystem.SPECIES:
		expect(species.has(id),"species lives in the actual main scene "+id)
		expect(WildlifeArt.texture(id)!=null,"portrait available "+id)
	if not failures.is_empty():
		print("WILDLIFETEST checked=%d failures=%s"%[checked,str(failures)])
		game.get_tree().quit(1)
		return
	var far:Enemy=ecology.actors["iron_den:0"]
	game._update_spawn(12)
	expect(is_instance_valid(far) and far in game.enemies,"distant animals persist instead of being despawned")
	for i in 12: game.random_spawn()
	expect(game.enemies.size()==initial_count,"repeated spawn scans respect per-habitat caps")
	var rabbit:Enemy=ecology.actors["bamboo_hare:0"]
	var old_radius:=rabbit.radius
	var old_hp:=rabbit.max_hp
	rabbit.hp=rabbit.max_hp*0.5
	ecology.tick_life(rabbit,400)
	expect(rabbit.growth_name()=="成年" and rabbit.radius>old_radius and rabbit.max_hp>old_hp,"juvenile grows into an adult with larger body and attributes")
	expect(is_equal_approx(rabbit.hp/rabbit.max_hp,0.5),"growth preserves injury proportion")
	expect(rabbit.cultivation_stage==0 and not rabbit.cultivating and not rabbit.is_monster,"ordinary animal never cultivates or transforms into a monster")
	var fox:Enemy=ecology.actors["valley_fox:0"]
	player.position=fox.position+Vector2(50,0)
	game.update_enemy(fox,0.1)
	expect(fox.state=="flee","timid animal flees instead of attacking")
	var beast:Enemy=ecology.actors["spirit_wolf:0"]
	player.position=Vector2(512,1040)
	beast.position=WildlifeSystem.center(WildlifeSystem.habitat_for(beast.habitat_id))
	beast.age_seconds=float(beast.data.mature)
	beast.refresh_growth()
	var attack:=beast.atk
	var juvenile:Enemy=game._make_host("green_wolf",beast.position)
	juvenile.habitat_id=beast.habitat_id
	juvenile.age_seconds=float(juvenile.data.mature)-1
	juvenile.calm_seconds=10
	ecology.tick_life(juvenile,2)
	expect(is_equal_approx(juvenile.cultivation_seconds,1),"juvenile time is excluded when a tick crosses adulthood")
	juvenile.free()
	for i in 200: game.update_enemy(beast,1)
	expect(beast.cultivation_stage==1 and beast.atk>attack and beast.cultivating,"adult beast cultivates independently in its den")
	var progress:=beast.cultivation_seconds
	player.position=beast.position+Vector2(160,0)
	game.update_enemy(beast,0.1)
	expect(beast.cultivation_seconds==progress and not beast.cultivating and beast.state=="chase","approach interrupts cultivation and triggers territorial combat")
	player.position=Vector2(512,1040)
	game.damage_enemy(beast,1,"none")
	game.update_enemy(beast,1)
	expect(beast.cultivation_seconds==progress,"recent injury prevents immediate cultivation")
	beast.threat_time=0
	beast.status.poison=5
	ecology.tick_life(beast,1)
	expect(beast.cultivation_seconds==progress,"negative status prevents cultivation")
	beast.status.poison=0
	beast.hp=beast.max_hp*0.5
	ecology.tick_life(beast,20)
	expect(beast.cultivation_seconds==progress,"severely injured beast cannot cultivate")
	beast.hp=beast.max_hp
	beast.cultivation_seconds=899
	ecology.tick_life(beast,2000)
	expect(beast.cultivation_seconds==900 and beast.cultivation_stage==3,"beast strength has a finite cultivation cap")
	var age:=rabbit.age_seconds
	game.paused=true
	game._process(60)
	expect(rabbit.age_seconds==age,"menu pause prevents growth")
	game.paused=false
	game.enter_house(World.HOUSE_DATA[2])
	game._process(1)
	expect(rabbit.age_seconds==age,"indoor play does not advance outdoor wildlife")
	game.exit_house(false)
	game.paused=false
	var habitat:=WildlifeSystem.habitat_for(rabbit.habitat_id)
	var slot:=rabbit.wildlife_slot
	var wall_progress:=player.aperture.wall_progress
	var money:=player.crystals
	var inv:Inventory=game.get_node("/root/Inv")
	var meat:=inv.get_item_count("rabbit_meat")
	game.kill_enemy(rabbit)
	expect(inv.get_item_count("rabbit_meat")==meat+1 and player.crystals==money and player.aperture.wall_progress==wall_progress,"hunting yields materials without currency or cultivation")
	expect(not ecology.actors.has(slot) and ecology.slots[slot].cooldown==habitat.cooldown,"death starts the habitat's own cooldown")
	game._update_spawn(20)
	expect(not ecology.actors.has(slot),"empty slot does not instantly respawn")
	var remaining:float=ecology.slots[slot].cooldown
	game.paused=true
	game._update_spawn(60)
	expect(ecology.slots[slot].cooldown==remaining,"spawn cooldown pauses with menus")
	game.paused=false
	player.position=WildlifeSystem.center(habitat)
	game._update_camera(0)
	game.camera.reset_smoothing()
	game._update_spawn(1000)
	expect(not ecology.actors.has(slot),"camping a cleared den never spawns an animal on the player")
	game.set_camera_zoom(0.65)
	player.body.apply_hit("eye_l",100)
	expect(not ecology.spawn_allowed(player.position+Vector2(100,0),habitat),"zoom and reduced vision do not weaken safe spawn distance")
	player.body.reset_full()
	player.position=Vector2(512,1040)
	game._update_camera(0)
	game.camera.reset_smoothing()
	game.random_spawn()
	expect(not ecology.actors.has(slot),"wide zoom also blocks a distant habitat still inside the camera")
	game.set_camera_zoom(1.0)
	game._update_camera(0)
	game.camera.reset_smoothing()
	for i in 3: game.random_spawn()
	expect(ecology.actors.has(slot),"cleared habitat replenishes once player leaves the area")
	if ecology.actors.has(slot):
		var young:Enemy=ecology.actors[slot]
		expect(young.age_seconds==0 and young.growth_name()=="幼年","replacement starts life as a juvenile")
		expect(young.position.distance_to(WildlifeSystem.center(habitat))<=habitat.radius,"replacement stays inside its configured habitat")
		game.kill_enemy(young)
	beast.position=WildlifeSystem.center(WildlifeSystem.habitat_for(beast.habitat_id))
	beast.age_seconds=1777
	beast.cultivation_seconds=320
	beast.refresh_growth()
	beast.hp=57
	beast.status.burn=4
	var saved_pos:=beast.position
	game.save_game()
	var before:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.SAVE_PATH))
	game._load_save()
	beast=ecology.actors["spirit_wolf:0"]
	expect(beast.age_seconds==1777 and beast.cultivation_seconds==320 and beast.hp==57 and beast.position==saved_pos and beast.status.burn==4,"save restores age, cultivation, wounds, position and status")
	expect(not ecology.actors.has(slot) and ecology.slots[slot].cooldown==habitat.cooldown,"loading preserves a dead slot and cooldown")
	game._load_save()
	beast=ecology.actors["spirit_wolf:0"]
	expect(game.enemies.size()==ecology.actors.size(),"loading twice does not duplicate residents")
	expect(beast.age_seconds==1777,"loading adds no offline growth")
	var beast_count:int=game.enemies.size()
	var beast_drop:=inv.get_item_count("green_wolf_fur")
	game.kill_enemy(beast)
	expect(game.enemies.size()==beast_count-1 and inv.get_item_count("green_wolf_fur")==beast_drop+1,"monster category retains its own hunting drops")
	await _check_ui()
	before.erase("wildlife")
	before.version=6
	var file:=FileAccess.open(game.SAVE_PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify(before))
	file.close()
	game._load_save()
	game._spawn_initial_enemies()
	expect(ecology.actors.size()==35 and game.enemies.size()==35,"legacy save initializes habitats without duplicate spawning")
	print("WILDLIFETEST checked=%d failures=%s"%[checked,str(failures)])
	game.get_tree().quit(0 if failures.is_empty() else 1)

func _check_ui() -> void:
	var gui:=CanonTests.new()
	gui.game=game
	await gui.key(KEY_M)
	expect(game.journal.visible and game.journal.active_page=="map","M opens actual journal")
	game.minimap_ui.set_mode("wildlife")
	await game.get_tree().process_frame
	expect(game.minimap_ui.wildlife_view.visible and game.minimap_ui.wildlife_rows.get_child_count()==10,"bestiary exposes ten animal habitat cards")
	var first:HBoxContainer=game.minimap_ui.wildlife_rows.get_child(0)
	var details:VBoxContainer=first.get_child(1)
	var button:Button=details.get_child(details.get_child_count()-1)
	await gui.click(button)
	expect(game.waypoint_name=="山林兔窝" and game.waypoint==WildlifeSystem.center(WildlifeSystem.HABITATS[0]),"actual habitat button sets walking destination")
	game.minimap_ui.set_mode("beasts")
	expect(game.minimap_ui.wildlife_rows.get_child_count()==3,"monster habitats have their own separate bestiary page")
	await gui.key(KEY_ESCAPE)
	expect(not game.journal.visible and not game.paused,"bestiary closes back to play")
