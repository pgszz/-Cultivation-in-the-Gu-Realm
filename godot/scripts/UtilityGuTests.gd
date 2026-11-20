class_name UtilityGuTests
extends RefCounted

var game: Node
var checked := 0
var failures: Array[String] = []
var instances: Dictionary = {}

func expect(ok: bool, label: String) -> void:
	checked+=1
	if not ok:
		failures.append(label)
		print("UTILITYGUTEST FAIL "+label)

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

func reset() -> void:
	game.village_ui.close()
	game.journal.close()
	game.close_refine()
	game.paused=false
	game.player.body.reset_full()
	game.player.hp=100
	game.player.iframes=0
	game.player.jade_guard=false
	game.player.shield=0
	game.player.atk_cd=0
	game.player.status.poison=0
	game.player.status.burn=0
	game.player.gu_effects.load_data({})
	game.player.utility_gu.load_data({})
	game.player.body_gu.load_data({})
	game.player.aperture.rank=1
	game.player.aperture.stage=0
	game.player.yuan=44
	game.player.cast_cds=[0.0,0.0,0.0]
	game.projectiles.clear()

func cast(id: String, slot: int = 0) -> void:
	game.equip_gu(instances[id].id,slot)
	game.player.cast_cds[slot]=0
	game.cast_skill(slot)

func render(path: String) -> void:
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	RenderingServer.force_draw()
	expect(game.get_viewport().get_texture().get_image().save_png("res://"+path)==OK,"saved "+path)

func run(main: Node) -> void:
	game=main
	game.set_process(false)
	game.start_game()
	CanonTests.prepare_cultivator(game)
	var p:Player=game.player
	var gus:GuManager=game.get_node("/root/Gus")
	var inv:Inventory=game.get_node("/root/Inv")
	var hunger:HungerSystem=game.get_node("/root/Hunger")
	var ui:VillageUI=game.village_ui
	var u:UtilityGuEffects=p.utility_gu
	reset()
	var count:int=p.captured.size()
	expect(not game.buy_gu("wind_moth") and p.captured.size()==count,"wilderness cannot purchase Gu")
	for shop in ["shop","bai_shop","xiong_shop"]:
		game.exit_house(false)
		var house:Dictionary=World.HOUSE_DATA[1] if shop=="shop" else SettlementData.building(shop)
		game.enter_house(house)
		for id in GameData.shop_gu_ids(shop):
			if not GameData.UTILITY_GU.has(id): continue
			p.crystals=0
			count=p.captured.size()
			expect(not game.buy_gu(id) and count==p.captured.size(),"no funds leaves stock intact "+id)
			p.crystals=int(GameData.GU_SHOP[id])+1
			ui.show_service(shop)
			ui.shop_filter.select(1)
			ui._filter_shop()
			await game.get_tree().process_frame
			await game.get_tree().process_frame
			var button:Button=ui.gu_buttons[id]
			ui.action_scroll.ensure_control_visible(button)
			await click(button)
			expect(p.crystals==1 and p.captured.size()==count+1 and p.captured[-1].id==id,"real shop purchase "+id)
			expect(button.disabled and not game.buy_gu(id),"finite stock "+id)
			ui.close()
			p.captured[-1].progress=100
			game.refine_target=p.captured.size()-1
			game._finish_refine()
			var gu:GuVirtual=gus.owned_gus[-1]
			instances[id]=gu
			expect(gu.template_id==id and gu.location=="aperture" and hunger.gu_data.has(gu.id),"refinement registers appetite "+id)
			ui.show_service(shop)
			ui.shop_filter.select(2)
			ui._filter_shop()
			var food_before:int=inv.get_item_count(gu.preferred_food)
			await game.get_tree().process_frame
			ui.action_scroll.ensure_control_visible(ui.supply_buttons[gu.preferred_food])
			await click(ui.supply_buttons[gu.preferred_food])
			expect(inv.get_item_count(gu.preferred_food)==food_before+1 and p.crystals==0,"real food purchase "+id)
			ui.close()
			hunger.gu_data[gu.id].current_hunger=10
			inv.add_item("jade",1)
			var jade:int=inv.get_item_count("jade")
			expect(not inv.use_item("jade",gu.id) and inv.get_item_count("jade")==jade,"wrong food remains "+id)
			expect(inv.use_item(gu.preferred_food,gu.id) and hunger.get_hunger(gu.id)==100,"dedicated feeding "+id)
			expect(GuArt.texture(id)!=null and GuArt.texture(id).get_width()>=512,"portrait loaded "+id)
			reset()
			p.yuan=0
			cast(id)
			expect(p.yuan==0 and u.active.is_empty() and game.projectiles.is_empty() and u.cooldowns.is_empty(),"failed cast is atomic "+id)
			reset()
		p.crystals=100
		expect(not game.buy_gu("stream_gu" if shop!="bai_shop" else "wind_moth"),"shop rejects another clan stock "+shop)
		for food in GameData.utility_food_stock(): expect(game.buy_supply(food,1),"all new food replenishable at "+shop+" "+food)
		expect(not game.buy_supply("wind_moth_care",0),"food price cannot be forged "+shop)
		ui.show_service(shop)
		ui.shop_filter.select(1)
		ui._filter_shop()
		await render("shot_utility_"+shop+".png")
		ui.close()
	game.exit_house(false)
	game.enter_house(World.HOUSE_DATA[2])
	reset()
	# Resource-safe targeted treatment, no regeneration or blood restoration.
	p.body.parts.leg_l.hp=10
	p.hp=70
	p.body.blood=55
	game.body_ui.select_part("leg_l")
	cast("mending_silk")
	expect(p.body.parts.leg_l.hp==24 and p.hp==76 and p.body.blood==55 and p.yuan==30,"mending changes only selected living part and health")
	var duplicate:GuVirtual=gus.add_gu("mending_silk")
	p.skill_slots[1]=duplicate.id
	p.cast_cds[1]=0
	game.cast_skill(1)
	expect(p.yuan==30 and p.body.parts.leg_l.hp==24,"second instance cannot bypass template cooldown")
	reset()
	p.body.parts.leg_l.destroyed=true
	p.body.parts.leg_l.hp=0
	cast("mending_silk")
	expect(p.body.parts.leg_l.destroyed and p.body.parts.leg_l.hp==0 and p.yuan==44,"mending refuses destroyed limb without charging")
	reset()
	p.body.parts.leg_l.hp=2
	p.body.parts.hand_l.hp=8
	var blood:float=p.body.blood
	cast("resin_beetle")
	expect(p.body.parts.leg_l.bandaged and not p.body.parts.hand_l.bandaged and p.body.blood==blood,"resin seals only the worst bleeding wound")
	reset()
	p.status.poison=8
	p.status.burn=5
	cast("dew_moth")
	expect(p.status.poison==0 and p.status.burn==5 and p.yuan==34,"dew removes poison only")
	reset()
	cast("wind_moth")
	expect(u.speed_multiplier()==1.35,"wind increases actual movement multiplier")
	p.body.parts.leg_l.hp=1
	p.body.parts.leg_r.hp=1
	expect(u.speed_multiplier()*p.body.get_move_multiplier()<1,"leg wounds still limit speed")
	var duration:float=u.active.haste.left
	game.paused=true
	u.tick(10,game)
	expect(u.active.haste.left==duration,"menu freezes duration")
	game.paused=false
	game.refining=true
	u.tick(10,game)
	expect(u.active.haste.left==duration,"refinement freezes active duration")
	game.refining=false
	game.move_gu(instances.wind_moth.id,"bag")
	expect(not u.has("haste"),"external placement cancels wind immediately")
	game.move_gu(instances.wind_moth.id,"aperture")
	reset()
	cast("night_firefly")
	expect(game.fog.radius_world()==610,"firefly expands real vision")
	p.body.parts.eye_l.destroyed=true
	p.body.parts.eye_l.hp=0
	expect(game.fog.radius_world()<610,"eye injury still reduces expanded vision")
	reset()
	cast("echo_cicada")
	expect(p.yuan==44 and u.cooldowns.is_empty(),"indoor survey rejected without charge")
	game.exit_house(false)
	reset()
	p.position=game.world.safe_position(Vector2(2200,1400))
	game.fog.explored.clear()
	var visited:Dictionary=game.visited_sites.duplicate()
	var camps:Dictionary=game.claimed_camps.duplicate()
	cast("echo_cicada")
	expect(game.fog.explored.size()>1000 and p.yuan==34,"echo reveals real terrain")
	expect(game.visited_sites==visited and game.claimed_camps==camps and not game.fog.can_see(p.position+Vector2(700,0)),"survey does not see distant people or claim exploration rewards")
	u.cooldowns.clear()
	cast("echo_cicada")
	expect(p.yuan==34,"fully mapped area refuses wasted survey")
	reset()
	p.jade_guard=true
	cast("gravel_shell")
	expect(u.has("shell") and not p.jade_guard,"gravel cancels skin protection")
	var hp:float=p.hp
	game.damage_player(20)
	expect(p.hp==hp and u.active.shell.points==12,"shell absorbs actual hit with finite capacity")
	game.damage_player(20)
	expect(p.hp<hp and not u.has("shell"),"shell breaks after capacity exhausted")
	reset()
	cast("gravel_shell")
	u.tick(11,game)
	expect(not u.has("shell"),"unused shell expires")
	reset()
	cast("veil_leaf")
	expect(u.detection_multiplier()==0.45,"veil reduces new discovery range")
	game.basic_attack(p.position+Vector2(100,0))
	expect(u.detection_multiplier()==1,"melee breaks veil")
	reset()
	cast("veil_leaf")
	game.damage_player(2)
	expect(not u.has("veil"),"damage breaks veil")
	reset()
	cast("veil_leaf")
	p.yuan=44
	cast("stream_gu",1)
	expect(not u.has("veil"),"attack Gu breaks veil")
	reset()
	for site in World.EXPLORATION_SITES:
		if site.kind!="timber": continue
		p.position=Vector2(site.pos)*GameData.TILE
		game.poi_cd.erase(site.id)
		var timber:int=inv.get_item_count("timber")
		cast("bamboo_saw")
		game._try_poi_interact()
		expect(inv.get_item_count("timber")==timber+5,"bamboo boosts actual timber gathering")
		game._try_poi_interact()
		expect(inv.get_item_count("timber")==timber+5,"bamboo respects site cooldown")
		break
	await projectile_tests()
	await wildlife_tests()
	reset()
	cast("wind_moth")
	game.save_game()
	game._load_save()
	expect(not u.has("haste") and float(u.cooldowns.get("wind_moth",0))>0,"load clears active buffs but preserves cooldown")
	for id in GameData.UTILITY_GU:
		expect(gus.owned_gus.any(func(gu:GuVirtual): return gu.template_id==id),"independent Gu survives character save "+id)
	var old:Dictionary=game._snapshot()
	old.erase("utility_gu")
	game._load_save(old)
	expect(u.active.is_empty() and u.cooldowns.is_empty(),"older saves default to empty effects")
	p.discovered.assign(GameData.GU_ORDER)
	game._toggle_ui(game.compendium_ui)
	game.compendium_ui.refresh()
	game.compendium_ui.category.select(6)
	game.compendium_ui._apply_filter()
	game.compendium_ui._show_detail("mending_silk")
	expect(game.compendium_ui._buttons.mending_silk.visible and not game.compendium_ui._buttons.moon_blade.visible,"treatment category filters actual encyclopedia")
	await render("shot_utility_compendium.png")
	print("UTILITYGUTEST checked=%d failures=%s"%[checked,str(failures)])
	game.get_tree().quit(0 if failures.is_empty() else 1)

func projectile_tests() -> void:
	game.enter_house(World.HOUSE_DATA[1])
	var person:Npc=game.residents.shop
	# Use the resident belonging to the actual house rather than an outdoor bystander.
	if not game.active_npcs().is_empty(): person=game.active_npcs()[0]
	var old_pos:Vector2=person.position
	var old_health:Dictionary=person.save_data()
	for id in ["stream_gu","ember_moth","frost_midge","vine_spider"]:
		reset()
		person.dead=false
		person.hp=100
		person.position=game.player.position+Vector2(42,0)
		game._update_camera(0)
		game.camera.reset_smoothing()
		game.camera.force_update_scroll()
		await game.get_tree().process_frame
		game.get_viewport().warp_mouse(game.get_viewport().get_canvas_transform()*person.position)
		await RenderingServer.frame_post_draw
		cast(id)
		expect(game.projectiles.size()==1 and game.projectiles[0].gu_id==id,"casts distinct real projectile "+id)
		game._update_projectiles(0.1)
		expect(person.hp<100,"projectile hits real person "+id)
		if id in ["stream_gu","frost_midge","vine_spider"]:
			expect(game.player.utility_gu.person_speed(person)<1,"control changes person movement "+id)
		if id=="ember_moth":
			var health:float=person.hp
			game.player.utility_gu.tick(1,game)
			expect(person.hp<health,"burn deals subsequent real damage")
		game.projectiles.clear()
	person.position=old_pos
	person.load_data(old_health)
	reset()
	cast("gravel_shell")
	game.player.yuan=44
	cast("wind_moth",1)
	game.player.yuan=44
	cast("night_firefly",2)
	game.set_camera_zoom(1.75)
	game._update_camera(0)
	await render("shot_utility_effects.png")
	game.exit_house(false)

func wildlife_tests() -> void:
	reset()
	var habitat:Dictionary=WildlifeSystem.HABITATS[2]
	var base:Vector2=game.world.safe_position(game.wildlife.center(habitat))
	# Find a clear actual strip without modifying the terrain fixture.
	var found:=false
	for y in range(-10,11):
		for x in range(-10,11):
			var candidate:Vector2=base+Vector2(x*32,y*32)
			var clear:=true
			for step in 6:
				var point:=candidate+Vector2(step*32,0)
				if game.world.collides(point.x,point.y,24): clear=false
			if clear:
				base=candidate
				found=true
				break
		if found: break
	expect(found,"found a real clear strip for wildlife projectile collision")
	game.player.position=base
	var actor:Enemy=game.wildlife.create_actor("utility_test_wolf",habitat,base+Vector2(60,0),2000)
	actor.hp=1000
	actor.max_hp=1000
	for id in ["stream_gu","ember_moth","frost_midge","vine_spider"]:
		reset()
		var sk:Dictionary=GameData.GU[id].skill.duplicate(true)
		sk["gu_id"]=id
		game.spawn_projectile(actor.position-Vector2(24,0),Vector2(200,0),float(sk.dmg),String(sk.element),"player",sk)
		var hp:float=actor.hp
		game._update_projectiles(0.03)
		expect(actor.hp<hp,"projectile damages wildlife "+id)
		if sk.has("slow"): expect(float(actor.status.get("slow",0))>0,"wildlife receives slowing "+id)
		if sk.has("bind"): expect(UtilityGuEffects.status_speed(actor.status)==0.2,"wildlife binding is stronger than slowing")
		if sk.has("burn"): expect(float(actor.status.get("burn",0))==0 and float(actor.status.get("wet",0))==0,"stream wet status consumes ember burning through steam")
	reset()
	actor.position=base+Vector2(160,0)
	game.player.position=base
	for key in actor.status: actor.status[key]=0.0
	actor.state="wander"
	actor.threat_time=0
	cast("veil_leaf")
	game.wildlife.update_ai(actor,0)
	expect(actor.state!="chase","concealed player does not trigger unaware wolf at 160px")
	game.player.utility_gu.break_veil()
	game.wildlife.update_ai(actor,0)
	expect(actor.state=="chase","unconcealed player triggers actual wolf pursuit")
	game.player.utility_gu.cooldowns.clear()
	game.player.yuan=44
	cast("veil_leaf")
	game.wildlife.update_ai(actor,0)
	expect(actor.state=="chase","veil cannot erase existing wildlife pursuit")
	var person:WorldPerson=game.population.actors.values()[0]
	var saved_person:=person.save_data()
	person.position=base
	person.path.clear()
	person.path_goal=Vector2.INF
	person.replan_left=0
	game.population.path_budget=4
	game.population.navigate(person,base+Vector2(128,0),0.1)
	var normal:float=person.position.distance_to(base)
	person.position=base
	person.path.clear()
	person.path_goal=Vector2.INF
	person.replan_left=0
	game.population.path_budget=4
	game.player.utility_gu.apply_hit(person,{"bind":3.0})
	game.population.navigate(person,base+Vector2(128,0),0.1)
	var bound:float=person.position.distance_to(base)
	expect(normal>0 and bound>0 and bound<normal*0.3,"binding reduces actual routed person movement")
	person.load_data(saved_person)
	game.player.utility_gu.person_status.erase(person.resident_id)
	game.enemies.erase(actor)
	game.wildlife.actors.erase("utility_test_wolf")
	actor.queue_free()
	await game.get_tree().process_frame
