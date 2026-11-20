class_name NewGuTests
extends RefCounted

func run(suite: RefCounted) -> void:
	var before:int=suite.checked
	var failures_before:int=suite.failures.size()
	var game:Node=suite.game
	var p:Player=game.player
	var gus:GuManager=game.get_node("/root/Gus")
	var inv:Inventory=game.get_node("/root/Inv")
	var hunger:HungerSystem=game.get_node("/root/Hunger")
	game.village_ui.close()
	game.journal.close()
	game.exit_house(false)
	game.world.destruction.load_data({})
	game.residents.shop.dead=false
	game.residents.shop.hostile=false
	p.body.reset_full()
	p.hp=p.max_hp
	p.dead=false
	p.jade_guard=false
	game.meditating=false
	game.gu_shop_purchased.clear()
	var money:int=p.crystals
	suite.expect(not game.buy_gu("little_light") and p.crystals==money,"new Gu cannot be bought from wilderness")
	game.enter_house(World.HOUSE_DATA[1])
	var new_ids:Array[String]=[]
	for id in ["little_light","white_boar","black_boar"]:
		p.crystals=0
		var count:int=p.captured.size()
		suite.expect(not game.buy_gu(id) and p.captured.size()==count,"new Gu requires actual payment: "+id)
		p.crystals=int(GameData.GU_SHOP[id])
		game.village_ui.show_service("shop")
		await game.get_tree().process_frame
		await game.get_tree().process_frame
		var button:Button=game.village_ui.gu_buttons[id]
		game.village_ui.action_scroll.ensure_control_visible(button)
		await suite.click(button)
		suite.expect(p.crystals==0 and p.captured.size()==count+1 and p.captured[-1].id==id,"actual shop button puts unrefined Gu into bag: "+id)
		suite.expect(game.gu_shop_remaining(id)==int(GuProgression.SHOP_LIMITS.get(id,1))-1 and button.disabled==(game.gu_shop_remaining(id)==0),"finite material stock decremented: "+id)
		game.village_ui.close()
		p.captured[-1].progress=100.0
		game.refine_target=p.captured.size()-1
		game._finish_refine()
		var gu:GuVirtual=gus.owned_gus[-1]
		new_ids.append(gu.id)
		suite.expect(gu.template_id==id and gu.location=="aperture" and hunger.gu_data.has(gu.id),"new Gu refinement registers independent appetite: "+id)
		hunger.gu_data[gu.id].current_hunger=10
		inv.add_item("jade",1)
		var jade:int=inv.get_item_count("jade")
		suite.expect(not inv.use_item("jade",gu.id) and inv.get_item_count("jade")==jade,"wrong food not consumed for "+id)
		inv.add_item(gu.preferred_food,1)
		var food_count:int=inv.get_item_count(gu.preferred_food)
		suite.expect(inv.use_item(gu.preferred_food,gu.id) and hunger.get_hunger(gu.id)==100 and inv.get_item_count(gu.preferred_food)==food_count-1,"new Gu eats exactly one matched ration: "+id)
	var light:GuVirtual=gus.get_gu_by_id(new_ids[0])
	var white:GuVirtual=gus.get_gu_by_id(new_ids[1])
	var black:GuVirtual=gus.get_gu_by_id(new_ids[2])
	var moon:GuVirtual=gus.add_gu("moon_blade")
	suite.expect(game.move_gu(light.id,"body"),"little light can reside in palm")
	game.equip_gu(moon.id,0)
	game.equip_gu(light.id,1)
	p.aperture.stage=0
	p.aperture.essence=44
	p.aperture.refined_essence=0
	p.cast_cds=[0.0,0.0,0.0]
	game.cast_skill(1)
	game.projectiles.clear()
	game.cast_skill(0)
	suite.expect(game.projectiles.size()==1 and game.projectiles[0].dmg==52 and game.projectiles[0].r==12,"light synergy doubles actual projectile damage and size")
	suite.expect(is_equal_approx(p.aperture.essence,31.5),"synergy charges combined essence once")
	p.aperture.essence=11
	p.cast_cds[0]=0
	game.projectiles.clear()
	game.cast_skill(0)
	suite.expect(game.projectiles.is_empty() and p.aperture.essence==11,"insufficient combined essence does not partially spend or fire")
	game.move_gu(light.id,"bag")
	suite.expect(game.active_light_gu()==null and p.light_support_id=="","removing the supporting instance cancels synergy")
	p.aperture.essence=44
	p.cast_cds[0]=0
	game.cast_skill(0)
	suite.expect(game.projectiles.size()==1 and game.projectiles[0].dmg==26 and GameData.GU.moon_blade.skill.dmg==26,"plain moon blade restored without mutating template")
	game.move_gu(light.id,"aperture")
	game.equip_gu(white.id,1)
	game.equip_gu(black.id,2)
	p.boar_cultivation.load_data({})
	p.aperture.essence=44
	p.cast_cds=[0.0,0.0,0.0]
	var wall:float=p.aperture.wall_progress
	var realm:String=p.aperture.realm()
	game.cast_skill(1)
	game._update_owned_gu(5)
	suite.expect(is_equal_approx(p.boar_cultivation.progress,0.1) and is_equal_approx(p.aperture.essence,39),"white boar trains permanently over time and pays essence")
	var power:float=p.melee_attack()
	suite.expect(power>p.atk and p.aperture.wall_progress==wall and p.aperture.realm()==realm,"boar strength affects melee, not cultivation experience")
	game.move_gu(white.id,"bag")
	suite.expect(p.boar_cultivation.active_id=="" and p.melee_attack()==power,"taking out boar stops training without losing muscle strength")
	p.cast_cds[2]=0
	game.cast_skill(2)
	game._update_owned_gu(20)
	suite.expect(is_equal_approx(p.boar_cultivation.progress,0.3) and is_equal_approx(p.boar_cultivation.daily_used,15) and p.boar_cultivation.active_id=="","black and white share daily safe dose; large delta cannot bypass it")
	p.cast_cds[2]=0
	game.cast_skill(2)
	suite.expect(p.boar_cultivation.active_id=="","switching boars cannot bypass daily limit")
	var elapsed:float=p.boar_cultivation.day_elapsed
	game.open_journal("character")
	game._process(30)
	suite.expect(p.boar_cultivation.day_elapsed==elapsed,"ordinary menu pauses boar recovery clock")
	suite.expect(game.character_ui.attributes.text.contains("永久进度"),"character page displays permanent strength")
	game.journal.close()
	p.boar_cultivation.tick(1440,p.aperture,false)
	suite.expect(p.boar_cultivation.daily_used==0 and is_equal_approx(p.boar_cultivation.progress,0.3),"new day restores safe dose without automatic training")
	p.aperture.essence=0
	p.aperture.refined_essence=0
	p.cast_cds[2]=0
	game.cast_skill(2)
	suite.expect(p.boar_cultivation.active_id=="","empty aperture cannot start free strength training")
	p.aperture.essence=44
	p.boar_cultivation.progress=0.99
	p.cast_cds[2]=0
	game.cast_skill(2)
	game._update_owned_gu(5)
	suite.expect(p.boar_cultivation.progress==1 and p.boar_cultivation.active_id=="" and p.melee_attack()==p.atk+p.atk_bonus+11,"boar power stops at a finite body cap")
	p.boar_cultivation.load_data({})
	p.cast_cds[2]=0
	game.cast_skill(2)
	p.iframes=0
	game.damage_player(1)
	suite.expect(p.boar_cultivation.active_id=="","real incoming damage interrupts training")
	p.body.reset_full()
	p.boar_cultivation.progress=0.25
	p.boar_cultivation.daily_used=7
	p.boar_cultivation.day_elapsed=91
	hunger.gu_data[black.id].current_hunger=0
	hunger.gu_data[black.id].starving_seconds=1439
	game._update_owned_gu(2)
	suite.expect(black.dead and is_equal_approx(p.boar_cultivation.progress,0.25),"starving boar dies but already gained strength remains")
	inv.add_item("pork_ration",1)
	var pork:int=inv.get_item_count("pork_ration")
	suite.expect(not inv.use_item("pork_ration",black.id) and inv.get_item_count("pork_ration")==pork,"pork cannot revive dead boar or consume on failure")
	game.save_game()
	game.gu_shop_purchased.clear()
	p.boar_cultivation.load_data({})
	game._load_save()
	suite.expect(is_equal_approx(p.boar_cultivation.progress,0.25) and p.boar_cultivation.daily_used==7 and p.boar_cultivation.day_elapsed==93,"permanent strength and daily budget survive real save reload")
	suite.expect(game.gu_shop_purchased.has("little_light") and game.gu_shop_purchased.has("white_boar") and not game.buy_gu("white_boar"),"new Gu stock persists across reload")
	suite.expect(gus.get_gu_by_id(new_ids[2]).dead and gus.get_gu_by_id(new_ids[1]).location=="bag","new instances keep death and external residence after reload")
	var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.SAVE_PATH))
	saved.erase("gu_shop_purchased")
	saved.erase("boar_cultivation")
	saved.version=6
	saved.jade_gu_purchased=true
	var file:=FileAccess.open(game.SAVE_PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify(saved))
	file.close()
	game._load_save()
	suite.expect(p.boar_cultivation.progress==0 and p.boar_cultivation.daily_used==0 and game.gu_shop_purchased.has("jade_skin"),"version 6 initializes new fields while preserving sold jade stock")
	p.captured.clear()
	for id in GameData.GU_ORDER:
		p.captured.append({"id":id,"rank":1,"quality":"normal","progress":0.0})
	game.village_ui.close()
	await suite.key(KEY_R)
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	var panel:Control=game.refine_layer.get_meta("vbox").get_parent().get_parent()
	suite.expect(game.refine_layer.visible and game.get_viewport_rect().encloses(panel.get_global_rect()),"full Gu refinement list stays within viewport")
	var last_index:=GameData.GU_ORDER.size()-1
	var last_row:Control=game.refine_list.get_child(last_index)
	game.refine_scroll.ensure_control_visible(last_row)
	await suite.click(last_row.get_child(2))
	suite.expect(game.refining and game.refine_target==last_index,"last new Gu remains reachable through real refinement button")
	game.close_refine()
	var isolated:=HungerSystem.new()
	isolated.register_gu("boar",1,"normal","pork_ration")
	isolated.update(1440*5)
	suite.expect(is_zero_approx(isolated.get_hunger("boar")) and not isolated.gu_data.boar.dead,"whole-pig ration supports five game days before starvation")
	isolated.free()
	print("NEWGUTEST checked=%d failures=%d" % [suite.checked-before,suite.failures.size()-failures_before])
