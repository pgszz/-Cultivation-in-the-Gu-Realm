class_name BodyGuTests
extends HundredGuTests

func fixture(rank: int = 3) -> void:
	setup_rank(rank)
	var p:Player=game.player
	p.body.parts.leg_l.hp=20
	p.body.parts.eye_l.hp=3
	p.body.parts.ear_l.hp=4
	p.hp=70
	p.body.blood=80
	p.body.pain=10
	p.body.consciousness=60
	p.gu_effects.stamina=40
	p.gu_effects.strain=40
	game.body_ui.select_part("leg_l")

func run(main: Node) -> void:
	game=main
	game.set_process(false)
	game.start_game()
	CanonTests.prepare_cultivator(game)
	game.player.set_process(false)
	var p:Player=game.player
	var gus:GuManager=game.get_node("/root/Gus")
	var hunger:HungerSystem=game.get_node("/root/Hunger")
	var inv:Inventory=game.get_node("/root/Inv")
	var u:=p.body_gu
	var ui:VillageUI=game.village_ui
	setup_rank()
	p.vital_gu_id=grant("moon_blade").id
	expect(GameData.BODY_GU.size()==20 and GameData.GU.size()==120 and GameData.GU_ORDER.size()==120,"120 unique playable Gu; 20 new body Gu")
	var seen:Dictionary={}
	for id in GameData.GU_ORDER:
		expect(not seen.has(id) and GameData.GU.has(id),"registered unique template "+id)
		seen[id]=true
	for shop in ["shop","bai_shop","xiong_shop"]:
		game.exit_house(false)
		game.enter_house(World.HOUSE_DATA[1] if shop=="shop" else SettlementData.building(shop))
		for id in GameData.BODY_GU:
			if GameData.GU[id].shop!=shop: continue
			var art:=GuArt.texture(id)
			expect(art!=null and art.get_width()>=512 and art.get_image().detect_alpha()!=Image.ALPHA_NONE,"transparent portrait "+id)
			var count:=p.captured.size()
			p.crystals=0
			expect(not game.buy_gu(id) and p.captured.size()==count,"no funds no purchase "+id)
			p.crystals=int(GameData.GU_SHOP[id])+1
			ui.show_service(shop)
			ui.shop_filter.select(1)
			ui._filter_shop()
			await game.get_tree().process_frame
			await game.get_tree().process_frame
			ui.action_scroll.ensure_control_visible(ui.gu_buttons[id])
			await click(ui.gu_buttons[id])
			expect(p.captured.size()==count+1 and p.crystals==1,"shop button buys "+id)
			if p.captured.size()!=count+1: continue
			ui.close()
			p.captured[-1].progress=100
			game.refine_target=p.captured.size()-1
			game._finish_refine()
			var gu:GuVirtual=gus.owned_gus[-1]
			instances[id]=gu
			expect(gu.template_id==id and gu.rank==int(GameData.GU[id].rank) and hunger.gu_data.has(gu.id),"refined independent instance "+id)
			ui.show_service(shop)
			ui.shop_filter.select(2)
			ui._filter_shop()
			await game.get_tree().process_frame
			ui.action_scroll.ensure_control_visible(ui.supply_buttons[gu.preferred_food])
			await click(ui.supply_buttons[gu.preferred_food])
			ui.close()
			hunger.gu_data[gu.id].current_hunger=10
			expect(p.crystals==0 and inv.use_item(gu.preferred_food,gu.id) and hunger.get_hunger(gu.id)==100,"bought food feeds correct instance "+id)
			setup_rank()
	game.exit_house(false)
	game.enter_house(World.HOUSE_DATA[0])
	for id in GameData.BODY_GU:
		fixture(int(GameData.GU[id].rank))
		var sk:Dictionary=GameData.GU[id].skill
		p.aperture.rank=int(GameData.GU[id].rank)-1
		cast(id)
		expect(u.active.is_empty() and u.bone=="" and p.hp==70,"lower rank rejected "+id)
		p.aperture.rank=int(GameData.GU[id].rank)
		if float(sk.cost)>0:
			p.yuan=0
			cast(id)
			expect(u.active.is_empty() and u.bone=="" and p.hp==70,"no essence no partial effect "+id)
		p.yuan=44
		cast(id)
		if sk.get("consumed",false):
			expect(gus.get_gu_by_id(instances[id].id)==null and not hunger.gu_data.has(instances[id].id) and not p.skill_slots.has(instances[id].id),"consumed instance removed everywhere "+id)
			if sk.effect=="bone":
				expect(u.bone==id and p.body.pain==75 and p.hp==70,"permanent bone + pain, no healing "+id)
				var saved:Dictionary=game.character_saves.load_character(game.character_id)
				expect(saved.get("body_gu",{}).get("bone","")==id,"bone and consumption saved together "+id)
				var reference:=BodyComponent.new()
				reference.setup(3)
				var unmodified:float=reference.apply_hit("torso",5).part_damage
				var hit:=p.take_body_hit(5,"none","torso")
				expect(is_equal_approx(hit.part_damage,unmodified*float(sk.bone_factor)) and p.hp==70,"bone reduces real part injury, not hp damage "+id)
				reference.free()
			else:
				expect(p.hp==82 and p.body.parts.leg_l.hp==26 and p.body.blood==80,"leaf heals surviving parts and hp only")
			grant(id)
		else:
			expect(u.active.has(sk.group) and u.cooldowns.has(id) and p.yuan<44,"real activation "+id)
			expect(PlayerStatus.snapshot(game).effects.any(func(e:Dictionary): return e.id=="body_"+sk.group),"status panel exposes effect "+id)
			var before:=u.active.duplicate(true)
			game.paused=true
			u.tick(2,game)
			expect(u.active==before,"ordinary menu pauses "+id)
			game.paused=false
			game.move_gu(instances[id].id,"bag")
			expect(u.active.is_empty(),"bag cancels effect "+id)
			game.move_gu(instances[id].id,"aperture")
			cast(id)
			expect(u.active.is_empty(),"moving back cannot bypass cooldown "+id)
	effect_tests()
	boundary_tests()
	persistence_tests()
	fixture()
	p.discovered.assign(GameData.GU_ORDER)
	game.compendium_ui.refresh()
	game.compendium_ui.show()
	game.compendium_ui.category.select(12)
	game.compendium_ui._apply_filter()
	expect(game.compendium_ui._buttons.iron_bone.visible and not game.compendium_ui._buttons.moon_blade.visible,"body category filter")
	await click(game.compendium_ui._buttons.iron_bone)
	await render("shot_bodygu_compendium.png")
	game.compendium_ui.hide()
	fixture()
	u.bone="jade_bone"
	u.tendon_progress=0.5
	cast("scar_crust")
	game.journal.open_page("body")
	await click(game.body_ui.rows.leg_l)
	expect(game.body_ui.detail.text.contains("护痂") and game.body_ui.detail.text.contains("玉骨"),"body panel selected part shows timed and permanent effects")
	await render("shot_bodygu_body.png")
	game.journal.close()
	cast("lucid_larva",1)
	game.journal.open_page("character")
	game.character_ui.show_status()
	await render("shot_bodygu_status.png")
	game.journal.close()
	print("BODYGUTEST checked=%d failures=%s"%[checked,str(failures)])
	game.get_tree().quit(0 if failures.is_empty() else 1)

func effect_tests() -> void:
	var p:Player=game.player
	var b:=p.body
	var u:=p.body_gu
	for id in GameData.BODY_GU:
		fixture()
		var sk:Dictionary=GameData.GU[id].skill
		if sk.get("consumed",false): continue
		cast(id)
		match id:
			"tempered_sinew":
				u.tick(100,game)
				expect(is_equal_approx(u.tendon_progress,0.5) and u.active.is_empty(),"training bounded by 20 seconds")
				expect(is_equal_approx(u.modifier("strain_gain"),0.825),"training reduces actual brute burden multiplier")
			"clot_thread":
				b.parts.leg_r.hp=1
				expect(is_equal_approx(b.part_bleed_rate("leg_r"),0.54),"clot modifies real wound bleed")
				u.clear_active()
				expect(is_equal_approx(b.part_bleed_rate("leg_r"),1.2),"clot expiry restores bleeding")
			"numb_ant", "nerve_lantern":
				b.apply_hit("leg_r",5)
				expect(is_equal_approx(b.pain,10+2.8*float(sk.pain_taken)),"incoming pain modifier "+id)
				if id=="nerve_lantern":
					p.status.shock=10
					u.tick(2,game)
					expect(p.status.shock==2,"nerve clears shock over time")
			"lucid_larva":
				u.tick(2,game)
				expect(b.consciousness==64,"lucidity recovers consciousness")
			"sinew_spring":
				expect(is_equal_approx(b.get_attack_speed_multiplier(),1.3),"spring modifies melee speed")
				game.basic_attack(p.position+Vector2(500,0))
				expect(is_equal_approx(p.atk_cd,0.38/1.3),"real melee cooldown uses body effect")
				u.tick(2,game)
				expect(p.gu_effects.stamina==38,"spring pays stamina")
			"feather_marrow", "ballast_bone", "scar_crust":
				var raw:=BodyComponent.new()
				raw.setup(3)
				var expected:float=raw.apply_hit("leg_l",5).part_damage*float(sk.part_damage)
				var hit:=b.apply_hit("leg_l",5)
				expect(is_equal_approx(float(hit.part_damage),expected),"real limb damage modifier "+id)
				if id=="scar_crust": expect(u.modifier("part_damage","leg_r")==1,"crust protects selected side only")
				if sk.has("move"): expect(is_equal_approx(PlayerStatus.movement(game,Vector2.RIGHT).value,p.speed*float(sk.move)),"actual movement modifier "+id)
				raw.free()
			"red_pulse":
				u.tick(2,game)
				expect(is_equal_approx(p.hp,68.8) and is_equal_approx(b.blood,82.4),"pulse trades hp for body blood")
			"lung_bell":
				u.tick(2,game)
				expect(p.gu_effects.stamina==50,"breath restores stamina")
			"bitter_liver", "warm_muscle":
				p.status[sk.clear_state]=10
				p.status.burn=10
				u.tick(2,game)
				expect(p.status[sk.clear_state]==4 and p.status.burn==10,"selective state decay "+id)
			"clear_cornea":
				var before:=b.get_vision_multiplier()
				u.tick(2,game)
				expect(is_equal_approx(b.parts.eye_l.hp,4.3) and b.get_vision_multiplier()>before,"eye repair changes actual vision")
			"ear_suture":
				u.tick(2,game)
				expect(is_equal_approx(b.parts.ear_l.hp,5.6) and b.pain==9 and b.parts.eye_l.hp==3,"ear repair is local and reduces pain")
			"joint_mender":
				u.tick(2,game)
				expect(b.parts.leg_l.hp==23 and p.gu_effects.strain==36 and is_equal_approx(u.modifier("move"),0.75),"joint repair + strain relief + slowdown")
			"self_reliance":
				var rate:=u.self_heal_rate(p)
				p.boar_cultivation.progress=1
				expect(u.self_heal_rate(p)>rate,"self reliance scales with permanent strength")
				p.boar_cultivation.progress=0
				u.tick(2,game)
				expect(is_equal_approx(p.hp,70+rate*2) and p.gu_effects.stamina==36,"self reliance heals with stamina cost")
				u.bone="iron_bone"
				expect(u.self_heal_rate(p)<rate,"reinforced body harder to heal")

func boundary_tests() -> void:
	var p:Player=game.player
	var b:=p.body
	var u:=p.body_gu
	var gus:GuManager=game.get_node("/root/Gus")
	for id in GameData.BODY_GU:
		fixture()
		var sk:Dictionary=GameData.GU[id].skill
		if sk.get("consumed",false): continue
		cast(id)
		var payment:=p.yuan
		cast(id)
		expect(p.yuan==payment,"same template cannot extend or stack "+id)
		u.tick(200,game)
		expect(u.active.is_empty() and is_equal_approx(u.modifier("move"),1) and is_equal_approx(u.modifier("attack_speed"),1),"bounded expiry removes temporary modifiers "+id)
		fixture()
		cast(id)
		instances[id].dead=true
		u.tick(0,game)
		expect(u.active.is_empty(),"dead Gu stops effect "+id)
		instances[id].dead=false
	for id in ["vitality_leaf","clear_cornea","ear_suture","joint_mender","self_reliance"]:
		setup_rank(3)
		for part in ["eye_l","eye_r","ear_l","ear_r","leg_l"]:
			b.parts[part].hp=0
			b.parts[part].destroyed=true
			b.parts[part].bandaged=true
		game.body_ui.select_part("leg_l")
		cast(id)
		expect(u.active.is_empty() and p.yuan==44,"destroyed-only wounds do not trigger healing "+id)
		p.hp=70
		cast(id)
		u.tick(5,game)
		expect(b.parts.eye_l.hp==0 and b.parts.leg_l.destroyed,"no regeneration "+id)
		if gus.get_gu_by_id(instances[id].id)==null: grant(id)
	fixture()
	cast("numb_ant")
	var essence:=p.yuan
	cast("nerve_lantern",1)
	expect(u.active.nerves.template=="numb_ant" and p.yuan==essence,"nerve group mutually exclusive")
	fixture()
	cast("feather_marrow")
	essence=p.yuan
	cast("ballast_bone",1)
	expect(u.active.mobility.template=="feather_marrow" and p.yuan==essence,"mobility group mutually exclusive")
	fixture()
	cast("red_pulse")
	p.hp=15.3
	u.tick(20,game)
	expect(is_equal_approx(p.hp,15) and is_equal_approx(b.blood,80.6),"pulse stops exactly at hp floor")
	fixture()
	cast("red_pulse")
	p.hp=5
	u.tick(2,game)
	expect(p.hp==5 and b.blood==80 and u.active.is_empty(),"damage below pulse floor never heals for free")
	fixture()
	cast("self_reliance")
	p.gu_effects.stamina=1
	var rate:=u.self_heal_rate(p)
	u.tick(5,game)
	expect(is_equal_approx(p.hp,70+rate*0.5) and u.active.is_empty(),"healing bounded by remaining stamina")
	fixture()
	cast("lung_bell")
	b.parts.torso.hp=10
	u.tick(1,game)
	expect(u.active.is_empty() and p.gu_effects.stamina==40,"lost torso condition cancels breathing")
	fixture()
	cast("clear_cornea")
	game.damage_player(1)
	expect(not u.active.has("recovery"),"actual hit interrupts eye treatment")
	fixture()
	cast("tempered_sinew")
	u.tick(4,game)
	p.position+=Vector2(2,0)
	u.tick(2,game)
	expect(is_equal_approx(u.tendon_progress,0.1) and u.active.is_empty(),"movement interrupts training, earned progress remains")
	fixture()
	cast("tempered_sinew")
	game.basic_attack()
	expect(u.active.is_empty(),"real attack interrupts training")
	fixture()
	u.tendon_progress=0.99
	cast("tempered_sinew")
	u.tick(20,game)
	expect(u.tendon_progress==1 and u.active.is_empty(),"training lifetime cap")
	fixture()
	cast("clot_thread")
	var fatal:=BodyComponent.new()
	fatal.setup(3)
	fatal.gu_changes=u
	fatal.neck_timer=0.01
	fatal.tick(0.02)
	expect(fatal.dead and not p.dead,"clot cannot stop fatal neck timer")
	fatal.free()

func persistence_tests() -> void:
	var p:Player=game.player
	var b:=p.body
	var u:=p.body_gu
	var gus:GuManager=game.get_node("/root/Gus")
	var hunger:HungerSystem=game.get_node("/root/Hunger")
	fixture()
	for id in ["iron_bone","jade_bone","vitality_leaf"]:
		var gu:GuVirtual=instances[id]
		var original:String=game.character_id
		game.character_id="invalid"
		cast(id)
		expect(gus.get_gu_by_id(gu.id)==gu and hunger.gu_data.has(gu.id) and p.skill_slots.has(gu.id) and u.bone=="" and p.hp==70 and b.pain==10 and p.yuan==44,"failed save rolls back full body consumption "+id)
		game.character_id=original
	fixture()
	var vital:String=p.vital_gu_id
	p.vital_gu_id=instances.iron_bone.id
	cast("iron_bone")
	expect(u.bone=="" and p.yuan==44,"vital bone cannot be consumed")
	p.vital_gu_id=vital
	cast("iron_bone")
	expect(u.bone=="iron_bone","bone consumed successfully")
	var essence:=p.yuan
	cast("jade_bone")
	expect(u.bone=="iron_bone" and p.yuan==essence and gus.get_gu_by_id(instances.jade_bone.id)!=null,"bone types cannot overwrite or stack")
	u.tendon_progress=0.4
	b.pain=10
	p.yuan=44
	cast("numb_ant")
	var cooldown:float=u.cooldowns.numb_ant
	expect(game.save_game() and game._load_save(),"formal save and load")
	expect(u.bone=="iron_bone" and is_equal_approx(u.tendon_progress,0.4) and u.active.is_empty() and is_equal_approx(u.cooldowns.numb_ant,cooldown),"permanent changes and cooldown persist, active effects close")
	for id in instances.keys():
		var current:GuVirtual=gus.get_gu_by_id(instances[id].id)
		if current!=null: instances[id]=current
	grant("iron_bone")
	var old:=BodyGuEffects.new()
	old.load_data({})
	expect(old.bone=="" and old.tendon_progress==0 and old.active.is_empty(),"old saves default to unmodified body")
	old.load_data({"bone":"unknown","tendon_progress":INF,"cooldowns":{"numb_ant":"bad"}})
	expect(old.bone=="" and old.tendon_progress==0 and old.cooldowns.is_empty(),"invalid optional data sanitized")
