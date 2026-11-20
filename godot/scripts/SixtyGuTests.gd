class_name SixtyGuTests
extends UtilityGuTests

## Real shop input, resource accounting, effect boundaries, save round trips.
func prepare() -> void:
	reset()
	game.player.aperture.rank=2
	game.player.yuan=44
	for key in game.player.status: game.player.status[key]=0.0

func needs() -> void:
	var p:Player=game.player
	p.body.parts.leg_l.hp=10
	p.hp=60
	p.body.blood=60
	p.body.pain=40
	p.gu_effects.strain=60
	p.gu_effects.stamina=40
	p.status.burn=3
	p.status.slow=3
	p.status.shock=3
	game.body_ui.select_part("leg_l")
	game.fog.explored.clear()

func clear_position(near: Vector2) -> Vector2:
	for y in range(-18,19):
		for x in range(-18,19):
			var pos:=near+Vector2(x*32,y*32)
			if game.world.collides(pos.x,pos.y,24): continue
			if not game.world.attack_trace(pos-Vector2(32,0),pos+Vector2(32,0),10).is_empty(): continue
			var occupied:=false
			for actor in game.active_npcs()+game.active_enemies():
				if actor.position.distance_to(pos)<96: occupied=true
			if not occupied: return pos
	expect(false,"unoccupied collision-free combat fixture")
	return near

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
	prepare()
	expect(GameData.GU.size()-GameData.HUNDRED_GU.size()-GameData.BODY_GU.size()==60 and GameData.GU_ORDER.size()-GameData.HUNDRED_GU.size()-GameData.BODY_GU.size()==60,"historical sixty templates retained; hundred batch checked separately")
	var seen:Dictionary={}
	for id in GameData.GU_ORDER:
		expect(not seen.has(id) and GameData.GU.has(id),"unique real entry "+id)
		seen[id]=true
		expect(GuArt.texture(id)!=null and FoodSystem.GRAINS.has(GameData.GU[id].preferred_food),"portrait and valid food "+id)
	for shop in ["shop","bai_shop","xiong_shop"]:
		game.exit_house(false)
		game.enter_house(World.HOUSE_DATA[1] if shop=="shop" else SettlementData.building(shop))
		for id in GameData.SIXTY_GU:
			if GameData.GU[id].shop!=shop: continue
			var count:int=p.captured.size()
			p.crystals=0
			expect(not game.buy_gu(id) and p.captured.size()==count,"purchase rejects insufficient money "+id)
			p.crystals=int(GameData.GU_SHOP[id])+1
			ui.show_service(shop)
			ui.shop_filter.select(1)
			ui._filter_shop()
			await game.get_tree().process_frame
			await game.get_tree().process_frame
			ui.action_scroll.ensure_control_visible(ui.gu_buttons[id])
			await click(ui.gu_buttons[id])
			expect(p.captured.size()==count+1 and p.crystals==1,"real shop button buys "+id)
			expect(not game.buy_gu(id),"stock is finite "+id)
			ui.close()
			p.captured[-1].progress=100
			game.refine_target=p.captured.size()-1
			game._finish_refine()
			var gu:GuVirtual=gus.owned_gus[-1]
			instances[id]=gu
			expect(gu.template_id==id and gu.rank==int(GameData.GU[id].rank) and hunger.gu_data.has(gu.id),"refinement creates correct instance "+id)
			ui.show_service(shop)
			ui.shop_filter.select(2)
			ui._filter_shop()
			await game.get_tree().process_frame
			ui.action_scroll.ensure_control_visible(ui.supply_buttons[gu.preferred_food])
			await click(ui.supply_buttons[gu.preferred_food])
			expect(inv.get_item_count(gu.preferred_food)>0 and p.crystals==0,"supply button buys dedicated food "+id)
			ui.close()
			hunger.gu_data[gu.id].current_hunger=10
			inv.add_item("jade",1)
			var jade:int=inv.get_item_count("jade")
			expect(not inv.use_item("jade",gu.id) and inv.get_item_count("jade")==jade,"wrong food preserves inventory "+id)
			expect(inv.use_item(gu.preferred_food,gu.id) and hunger.get_hunger(gu.id)==100,"dedicated food feeds instance "+id)
			prepare()
		ui.show_service(shop)
		ui.shop_filter.select(1)
		ui._filter_shop()
		await render("shot_sixty_"+shop+".png")
		ui.close()
	game.exit_house(false)
	var site:Dictionary=World.EXPLORATION_SITES.filter(func(s:Dictionary): return s.kind=="timber")[0]
	p.position=game.world.safe_position(Vector2(site.pos)*32+Vector2(160,0))
	for id in GameData.SIXTY_GU:
		prepare()
		needs()
		p.yuan=0
		cast(id)
		expect(u.cooldowns.is_empty() and u.active.is_empty() and game.projectiles.is_empty(),"no essence causes no partial effect "+id)
		prepare()
		needs()
		if int(GameData.GU[id].rank)==2:
			p.aperture.rank=1
			cast(id)
			expect(u.cooldowns.is_empty() and p.yuan==44,"lower rank cannot activate "+id)
			p.aperture.rank=2
		cast(id)
		expect(u.cooldowns.has(id) and p.yuan<44,"real activation spends essence and starts cooldown "+id)
		var sk:Dictionary=GameData.GU[id].skill
		if sk.kind=="utility_projectile":
			expect(game.projectiles.size()==int(sk.get("count",1)),"correct projectile count "+id)
			for pr in game.projectiles: expect(pr.gu_id==id and pr.dmg==float(sk.dmg),"projectile carries actual damage "+id)
		if sk.has("duration"):
			expect(u.has(sk.kind),"buff activates "+id)
			var snap:Dictionary=PlayerStatus.snapshot(game)
			expect(snap.effects.any(func(e:Dictionary): return e.id==sk.kind),"status panel shows buff "+id)
			var left:float=u.active[sk.kind].left
			game.paused=true
			u.tick(2,game)
			expect(u.active[sk.kind].left==left,"menu pauses buff "+id)
			game.paused=false
			game.move_gu(instances[id].id,"bag")
			expect(not u.has(sk.kind),"bag placement cancels buff "+id)
			game.move_gu(instances[id].id,"aperture")
	prepare()
	needs()
	cast("blood_suture")
	expect(p.body.blood==70 and p.body.parts.leg_l.hp==10 and p.hp==60,"blood restoration is not healing or bandaging")
	prepare()
	cast("blood_suture")
	expect(p.yuan==44 and u.cooldowns.is_empty(),"full blood rejects without charge")
	needs()
	cast("warm_pupa")
	expect(p.status.slow==0 and p.status.shock==0 and p.status.burn==3,"warm pupa only clears control")
	cast("rain_pearl",1)
	expect(p.status.burn==0 and p.hp==60,"rain extinguishes without healing")
	cast("vigor_grub",2)
	expect(p.gu_effects.stamina==70 and p.gu_effects.strain==60,"vigor restores stamina without clearing burden")
	prepare()
	needs()
	cast("soothing_moth")
	expect(p.gu_effects.strain==30 and p.body.pain==25 and p.body.parts.leg_l.hp==10,"soothe lowers burden and pain only")
	prepare()
	needs()
	cast("spring_cocoon")
	u.tick(2,game)
	expect(p.body.parts.leg_l.hp==15 and p.hp==64,"cocoon applies bounded real regeneration")
	game.damage_player(1)
	expect(not u.has("regrowth"),"actual damage interrupts cocoon")
	prepare()
	p.body.parts.leg_l.destroyed=true
	p.body.parts.leg_l.hp=0
	cast("spring_cocoon")
	expect(u.active.is_empty() and p.yuan==44,"cocoon cannot regenerate destroyed limb")
	prepare()
	cast("reed_armor")
	var paid:float=p.yuan
	cast("mirror_scale",1)
	expect(u.active.shell.template=="reed_armor" and p.yuan==paid,"shell family cannot stack")
	game.damage_player(12)
	expect(p.hp==100 and u.active.shell.points==8,"reed shell absorbs finite damage in real combat")
	prepare()
	cast("mirror_scale")
	game.damage_player(55)
	expect(p.hp==100 and u.active.shell.points==5,"rank two shell has actual sixty-point budget")
	for id in ["cinder_coat","frost_ward"]:
		prepare()
		cast(id)
		var element:String=GameData.GU[id].skill.resist_element
		expect(u.absorb(20,game,element)==10 and u.absorb(20,game,"metal")==20,"resistance filters only stated damage "+id)
	prepare()
	cast("quick_cricket")
	expect(u.speed_multiplier()==1.75,"quick sprint multiplier")
	paid=p.yuan
	cast("cloud_locust",1)
	expect(p.yuan==paid and u.speed_multiplier()==1.75,"speed family cannot stack")
	var other:GuVirtual=gus.add_gu("quick_cricket")
	u.clear_active()
	p.skill_slots[1]=other.id
	p.cast_cds[1]=0
	game.cast_skill(1)
	expect(not u.has("haste") and p.yuan==paid,"second instance cannot bypass template cooldown")
	prepare()
	cast("mist_butterfly")
	expect(u.detection_multiplier()==0.25,"mist stealth range")
	u.break_veil()
	expect(u.detection_multiplier()==1,"attack breaks stealth")
	prepare()
	cast("far_sight")
	expect(game.fog.radius_world()==FogOfWar.BASE_RADIUS+300,"long sight alters real fog radius")
	p.body.parts.eye_l.destroyed=true
	expect(game.fog.radius_world()<FogOfWar.BASE_RADIUS+300,"long sight still respects eye injury")
	await water_and_resource_tests()
	await projectile_tests()
	await creature_and_terrain_tests()
	prepare()
	cast("cloud_locust")
	var cooldown:float=u.cooldowns.cloud_locust
	p.skill_slots[0]=instances.cloud_locust.id
	game.move_gu(instances.ore_mandible.id,"bag")
	game.save_game()
	expect(game._load_save(),"sixty Gu save loads")
	expect(p.utility_gu.active.is_empty() and p.utility_gu.cooldowns.cloud_locust==cooldown,"save retains cooldown but never restores active effects")
	for id in GameData.SIXTY_GU:
		var gu:GuVirtual=gus.get_gu_by_id(instances[id].id)
		expect(gu!=null and gu.template_id==id and hunger.gu_data.has(gu.id),"instance and appetite survive load "+id)
	expect(gus.get_gu_by_id(instances.ore_mandible.id).location=="bag" and p.skill_slots[0]==instances.cloud_locust.id,"bag and shortcut identity survive load")
	p.discovered.assign(GameData.GU_ORDER)
	game._toggle_ui(game.compendium_ui)
	game.compendium_ui.search.text=""
	game.compendium_ui.refresh()
	await render("shot_sixty_compendium.png")
	game.compendium_ui.search.text="红莲"
	game.compendium_ui._apply_filter()
	expect(game.compendium_ui._buttons.red_lotus_moth.visible and not game.compendium_ui._buttons.moon_blade.visible,"sixty-entry encyclopedia search filters actual rows")
	game.compendium_ui._show_detail("red_lotus_moth")
	await render("shot_sixty_search.png")
	game.compendium_ui.search.text=""
	game.compendium_ui.rank_filter.select(2)
	game.compendium_ui.category.select(8)
	game.compendium_ui._apply_filter()
	expect(game.compendium_ui._buttons.ice_lance.visible and not game.compendium_ui._buttons.thunder_pupa.visible and not game.compendium_ui._buttons.red_lotus_moth.visible,"rank and use filters combine across sixty entries")
	print("SIXTYGUTEST checked=",checked," failures=",failures)
	game.get_tree().quit(0 if failures.is_empty() else 1)

func water_and_resource_tests() -> void:
	var p:Player=game.player
	var u:UtilityGuEffects=p.utility_gu
	prepare()
	var water_pos:=Vector2.ZERO
	for y in range(20,GameData.MAP_H-20):
		for x in range(20,GameData.MAP_W-20):
			var pos:=Vector2(x*32+16,y*32+16)
			if game.world.swimming_at(pos):
				water_pos=pos
				break
		if water_pos!=Vector2.ZERO: break
	expect(water_pos!=Vector2.ZERO,"found actual swimming water")
	p.position=water_pos
	var before:float=PlayerStatus.movement(game,Vector2.RIGHT).value
	cast("water_skater")
	expect(PlayerStatus.movement(game,Vector2.RIGHT).value>before,"water skater removes actual swim slowdown")
	for id in ["ore_mandible","timber_mantis","gather_scarab"]:
		prepare()
		cast(id)
		for kind in ["timber","rubble"]:
			var site:Dictionary=World.EXPLORATION_SITES.filter(func(s:Dictionary): return s.kind==kind)[0]
			p.position=Vector2(site.pos)*32
			game.poi_cd.erase(site.id)
			var inv:Inventory=game.get_node("/root/Inv")
			var count:int=inv.get_item_count(kind)
			game._try_poi_interact()
			expect(inv.get_item_count(kind)==count+3+u.harvest_bonus(kind),"actual harvest bonus "+id+kind)
			count=inv.get_item_count(kind)
			game._try_poi_interact()
			expect(inv.get_item_count(kind)==count,"harvest never bypasses site cooldown "+id+kind)
	prepare()
	var site:Dictionary=World.EXPLORATION_SITES.filter(func(s:Dictionary): return s.kind=="timber")[0]
	p.position=Vector2(site.pos)*32
	game.poi_cd.erase(site.id)
	var visited:Dictionary=game.visited_sites.duplicate()
	var inv:Inventory=game.get_node("/root/Inv")
	var count:int=inv.get_item_count("timber")
	game.fog.explored.clear()
	cast("scent_ant")
	expect(not game.fog.explored.is_empty() and game.visited_sites==visited and inv.get_item_count("timber")==count,"prospecting reveals terrain without claiming visit or materials")
	game.enter_house(World.HOUSE_DATA[1])
	prepare()
	cast("earth_cicada")
	cast("scent_ant",1)
	expect(p.yuan==44 and u.cooldowns.is_empty(),"terrain scouts reject interior without charge")
	game.exit_house(false)

func projectile_tests() -> void:
	prepare()
	var person:WorldPerson=game.population.actors.values()[0]
	var saved:=person.save_data()
	var saved_pos:=person.position
	# Spawn immediately next to the actor on an existing passable tile.
	var base:=clear_position(GameData.BONFIRE+Vector2(0,500))
	person.position=base
	person.hp=1000
	person.max_hp=1000
	game.player.position=base-Vector2(100,0)
	for id in GameData.SIXTY_GU:
		var sk:Dictionary=GameData.GU[id].skill.duplicate(true)
		if sk.kind!="utility_projectile": continue
		sk["gu_id"]=id
		game.player.utility_gu.person_status.clear()
		game.spawn_projectile(base-Vector2(20,0),Vector2(200,0),float(sk.dmg),String(sk.element),"player",sk)
		var hp:float=person.hp
		game._update_projectiles(0.03)
		expect(person.hp<hp,"real projectile damages moving person "+id)
		if id=="venom_gnat":
			hp=person.hp
			game.player.utility_gu.tick(2,game)
			expect(is_equal_approx(hp-person.hp,8),"poison inflicts deterministic person damage")
		game.projectiles.clear()
	var env:EnvironmentInteractions=game.world.environment
	env.react_actor(game,person,{"gu_id":"stream_gu"})
	env.react_actor(game,person,{"gu_id":"ice_lance","reaction":"frost","slow":5})
	expect(game.player.utility_gu.person_status[person.resident_id].frozen==2,"new frost reacts with wet actors")
	env.react_actor(game,person,{"gu_id":"red_lotus_moth","reaction":"fire","burn":3})
	expect(game.player.utility_gu.person_status[person.resident_id].frozen==0 and game.player.utility_gu.person_status[person.resident_id].burn==0,"new fire consumes freeze through steam")
	var cell:=TerrainLayers.cell_at(base)
	env.react_cell(game,cell,{"gu_id":"ice_lance","reaction":"frost"})
	expect(env.frozen(cell,game.world.layer),"new frost changes real terrain state")
	var bonus:float=env.react_cell(game,cell,{"gu_id":"red_lotus_moth","reaction":"fire"})
	expect(not env.frozen(cell,game.world.layer) and bonus==24,"new fire cracks frosted dry terrain")
	person.position=saved_pos
	person.load_data(saved)
	game.player.utility_gu.person_status.clear()

func creature_and_terrain_tests() -> void:
	prepare()
	var habitat:Dictionary=WildlifeSystem.HABITATS[2]
	var pos:=clear_position(game.wildlife.center(habitat))
	game.player.position=pos-Vector2(150,0)
	var actor:Enemy=game.wildlife.create_actor("sixty_test_wolf",habitat,pos,10000)
	actor.data=actor.data.duplicate(true)
	actor.data.hp=1000.0
	actor.hp=1000
	actor.max_hp=1000
	for id in GameData.SIXTY_GU:
		var sk:Dictionary=GameData.GU[id].skill.duplicate(true)
		if sk.kind!="utility_projectile": continue
		for key in actor.status: actor.status[key]=0.0
		sk["gu_id"]=id
		var hp:float=actor.hp
		game.spawn_projectile(actor.position,Vector2(200,0),float(sk.dmg),String(sk.element),"player",sk)
		game._update_projectiles(0.01)
		expect(actor.hp<hp,"new projectile hits real wildlife "+id)
		if id=="venom_gnat":
			hp=actor.hp
			actor.stun=3
			game.update_enemy(actor,2)
			expect(is_equal_approx(hp-actor.hp,8),"wildlife poison matches described four damage per second")
		game.projectiles.clear()
	game.enemies.erase(actor)
	game.wildlife.actors.erase("sixty_test_wolf")
	actor.queue_free()
	await game.get_tree().process_frame
	game.change_layer(1,Vector2(1424,528),false)
	var target:Vector2=game.player.position+Vector2(0,64)
	var cell:=TerrainLayers.cell_at(target)
	var before:Dictionary=game.world.blocks.info(cell,1)
	expect(not before.is_empty(),"real cave block available for excavation")
	var sk:Dictionary=GameData.GU.burrow_grub.skill.duplicate(true)
	sk["gu_id"]="burrow_grub"
	sk["target"]=target
	game.spawn_projectile(game.player.position,Vector2.DOWN*float(sk.speed),float(sk.dmg),String(sk.element),"player",sk)
	for i in 10: game._update_projectiles(0.04)
	var after:Dictionary=game.world.blocks.info(cell,1)
	expect(after.is_empty() or float(before.hp)-float(after.hp)>float(sk.dmg),"excavation uses ninety terrain power rather than six creature damage")
	expect(game.projectiles.is_empty(),"excavation projectile terminates at terrain")
	game.change_layer(0,GameData.BONFIRE+Vector2(0,100),false)
