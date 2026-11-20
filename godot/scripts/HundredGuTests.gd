class_name HundredGuTests
extends SixtyGuTests

func setup_rank(rank: int = 5) -> void:
	prepare()
	game.stop_meditation("")
	game.player.aperture.rank=rank
	game.player.aperture.capacity=44
	game.player.aperture.potential=44
	game.player.aperture.aptitude_gain=0
	game.player.aperture.wall_progress=0
	game.player.aperture.refined_essence=0
	game.player.yuan=44
	game.player.crystals=10000

func grant(id: String) -> GuVirtual:
	var gu:GuVirtual=game.get_node("/root/Gus").add_gu(id)
	game.player.owned.append(id)
	instances[id]=gu
	return gu

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
	var u:UtilityGuEffects=p.utility_gu
	var ui:VillageUI=game.village_ui
	setup_rank()
	expect(GameData.GU.size()-GameData.BODY_GU.size()==100 and GameData.GU_ORDER.size()-GameData.BODY_GU.size()==100 and GameData.HUNDRED_GU.size()==40,"historical hundred templates retained; body batch checked separately")
	expect(not GameData.GU.has("hope_gu"),"hope remains separate ritual")
	var seen:Dictionary={}
	for id in GameData.GU_ORDER:
		expect(not seen.has(id) and GameData.GU.has(id),"unique registered template "+id)
		seen[id]=true
	for shop in ["shop","bai_shop","xiong_shop"]:
		game.exit_house(false)
		game.enter_house(World.HOUSE_DATA[1] if shop=="shop" else SettlementData.building(shop))
		for id in GameData.HUNDRED_GU:
			if GameData.GU[id].shop!=shop: continue
			var art:=GuArt.texture(id)
			expect(art!=null and art.get_width()>=512 and art.get_image().detect_alpha()!=Image.ALPHA_NONE,"independent transparent portrait "+id)
			var count:=p.captured.size()
			p.crystals=0
			expect(not game.buy_gu(id) and p.captured.size()==count,"no-money purchase rejected "+id)
			p.crystals=int(GameData.GU_SHOP[id])+1
			ui.show_service(shop)
			ui.shop_filter.select(1)
			ui._filter_shop()
			await game.get_tree().process_frame
			await game.get_tree().process_frame
			ui.action_scroll.ensure_control_visible(ui.gu_buttons[id])
			await click(ui.gu_buttons[id])
			expect(p.captured.size()==count+1 and p.crystals==1,"real shop button purchases "+id)
			if p.captured.size()!=count+1: continue
			ui.close()
			p.captured[-1].progress=100
			game.refine_target=p.captured.size()-1
			game._finish_refine()
			var gu:GuVirtual=gus.owned_gus[-1]
			instances[id]=gu
			expect(gu.template_id==id and gu.rank==int(GameData.GU[id].rank) and hunger.gu_data.has(gu.id),"refinement and hunger register "+id)
			ui.show_service(shop)
			ui.shop_filter.select(2)
			ui._filter_shop()
			await game.get_tree().process_frame
			ui.action_scroll.ensure_control_visible(ui.supply_buttons[gu.preferred_food])
			await click(ui.supply_buttons[gu.preferred_food])
			ui.close()
			hunger.gu_data[gu.id].current_hunger=10
			expect(p.crystals==0 and inv.use_item(gu.preferred_food,gu.id) and hunger.get_hunger(gu.id)==100,"dedicated food purchased and feeds "+id)
			setup_rank()
	game.exit_house(false)
	game.enter_house(World.HOUSE_DATA[0])
	for id in GameData.HUNDRED_GU:
		setup_rank(int(GameData.GU[id].rank))
		var sk:Dictionary=GameData.GU[id].skill
		if sk.kind=="relic": continue
		if sk.kind=="prospect" or sk.kind=="survey":
			game.exit_house(false)
			var site:Dictionary=World.EXPLORATION_SITES.filter(func(s:Dictionary): return s.kind=="timber")[0]
			p.position=game.world.safe_position(Vector2(site.pos)*32+Vector2(160,0))
			game.fog.explored.clear()
		p.body.parts.leg_l.hp=10
		p.hp=60
		p.body.blood=60
		p.body.consciousness=60
		game.body_ui.select_part("leg_l")
		if sk.kind=="purify": p.status.poison=3
		p.aperture.rank=maxi(0,int(GameData.GU[id].rank)-1)
		cast(id)
		expect(u.active.is_empty() and u.cooldowns.is_empty() and game.projectiles.is_empty(),"lower rank cannot activate "+id)
		p.aperture.rank=int(GameData.GU[id].rank)
		p.yuan=0
		cast(id)
		expect(u.active.is_empty() and u.cooldowns.is_empty() and p.crystals==10000,"no essence causes no partial charge "+id)
		p.yuan=44
		cast(id)
		expect(p.yuan<44 and u.cooldowns.has(id),"actual cast spends and starts cooldown "+id)
		if sk.kind=="utility_projectile":
			expect(game.projectiles.size()==int(sk.get("count",1)),"correct projectile count "+id)
			for pr in game.projectiles: expect(pr.dmg==float(sk.dmg) and pr.gu_id==id,"real damage payload "+id)
		if sk.has("duration"):
			expect(u.has(sk.kind),"active effect exists "+id)
			expect(PlayerStatus.snapshot(game).effects.any(func(e:Dictionary): return e.id==sk.kind),"status panel exposes actual effect "+id)
			var left:float=u.active[sk.kind].left
			game.paused=true
			u.tick(2,game)
			expect(u.active[sk.kind].left==left,"menu pauses duration "+id)
			game.paused=false
			game.move_gu(instances[id].id,"bag")
			expect(not u.has(sk.kind),"external location cancels effect "+id)
			game.move_gu(instances[id].id,"aperture")
		game.exit_house(false)
		game.enter_house(World.HOUSE_DATA[0])
	relic_tests()
	aptitude_tests()
	other_effect_tests()
	progression_tests()
	setup_rank()
	p.discovered.assign(GameData.GU_ORDER)
	game.compendium_ui.refresh()
	game.compendium_ui.show()
	game.compendium_ui.category.select(10)
	game.compendium_ui.rank_filter.select(4)
	game.compendium_ui._apply_filter()
	expect(game.compendium_ui._buttons.clear_origin_silkworm.visible and not game.compendium_ui._buttons.nine_aurora_cocoon.visible,"rank four aptitude filter")
	await click(game.compendium_ui._buttons.clear_origin_silkworm)
	expect(game.compendium_ui.selected_id=="clear_origin_silkworm","real compendium selection")
	await render("shot_hundred_aptitude.png")
	game.compendium_ui.category.select(11)
	game.compendium_ui.rank_filter.select(0)
	game.compendium_ui._apply_filter()
	game.compendium_ui._show_detail("purple_relic")
	await render("shot_hundred_relic.png")
	game.compendium_ui.hide()
	setup_rank(4)
	cast("clear_origin_silkworm")
	u.tick(8,game)
	game.journal.open_page("aperture")
	await render("shot_hundred_aperture.png")
	game.journal.close()
	print("HUNDREDGUTEST checked=%d failures=%s"%[checked,str(failures)])
	game.get_tree().quit(0 if failures.is_empty() else 1)

func relic_tests() -> void:
	var p:Player=game.player
	var gus:GuManager=game.get_node("/root/Gus")
	var hunger:HungerSystem=game.get_node("/root/Hunger")
	var ids:=["bronze_relic","red_iron_relic","silver_relic","gold_relic","purple_relic"]
	for index in ids.size():
		var id:String=ids[index]
		expect(int(GameData.GU[id].rank)==index+1,"canon relic rank "+id)
		for stage in 3:
			setup_rank(index+1)
			p.aperture.stage=stage
			var gu:=grant(id)
			cast(id)
			expect(p.aperture.rank==index+1 and p.aperture.stage==stage+1 and p.aperture.capacity==44 and p.aperture.aptitude_gain==0,"relic raises one small realm only "+id+str(stage))
			expect(gus.get_gu_by_id(gu.id)==null and not hunger.gu_data.has(gu.id) and not p.skill_slots.has(gu.id),"consumed instance fully removed "+id)
			var snapshot:Dictionary=game.character_saves.load_character(game.character_id)
			expect(int(snapshot.aperture.stage)==stage+1 and not snapshot.gus.any(func(g:Dictionary): return g.id==gu.id),"consumption and stage saved together "+id)
		setup_rank(index+1)
		p.aperture.stage=3
		var gu:=grant(id)
		cast(id)
		expect(gus.get_gu_by_id(gu.id)==gu and p.aperture.rank==index+1,"peak cannot cross rank with relic "+id)
		p.aperture.stage=0
		p.aperture.rank=mini(5,index+2) if index<4 else 4
		cast(id)
		expect(gus.get_gu_by_id(gu.id)==gu and p.aperture.stage==0,"wrong rank relic is retained "+id)
	setup_rank(1)
	var gu:=grant("bronze_relic")
	var vital:String=p.vital_gu_id
	p.vital_gu_id=gu.id
	cast("bronze_relic")
	expect(gus.get_gu_by_id(gu.id)==gu and p.aperture.stage==0,"protected vital relic is retained")
	p.vital_gu_id=vital
	var saved_id:String=game.character_id
	game.character_id="invalid"
	cast("bronze_relic")
	expect(gus.get_gu_by_id(gu.id)==gu and hunger.gu_data.has(gu.id) and p.aperture.stage==0 and p.skill_slots.has(gu.id),"failed save rolls back complete relic transaction")
	game.character_id=saved_id

func aptitude_tests() -> void:
	var p:Player=game.player
	var u:=p.utility_gu
	for id in ["clear_origin_silkworm","deep_spring_butterfly","marrow_lotus_beetle","nine_aurora_cocoon"]:
		setup_rank(int(GameData.GU[id].rank))
		var sk:Dictionary=GameData.GU[id].skill
		p.crystals=0
		cast(id)
		expect(p.yuan==44 and not u.has("aptitude_training"),"no stones cannot partially charge aptitude "+id)
		p.crystals=10000
		cast(id)
		var yuan:float=p.yuan
		u.tick(50,game)
		expect(is_equal_approx(p.aperture.capacity,44+float(sk.rate)*float(sk.duration)) and p.yuan==yuan and p.aperture.potential==44,"bounded continuous aptitude does not grant essence "+id)
		expect(p.crystals==10000-int(sk.stones) and not u.has("aptitude_training"),"fixed payment and duration "+id)
		setup_rank(int(GameData.GU[id].rank))
		p.aperture.capacity=float(sk.ceiling)-0.1
		cast(id)
		u.tick(2,game)
		expect(is_equal_approx(p.aperture.capacity,float(sk.ceiling)),"per-Gu aptitude ceiling "+id)
	setup_rank()
	p.aperture.aptitude_gain=19.9
	cast("nine_aurora_cocoon")
	u.tick(5,game)
	expect(is_equal_approx(p.aperture.aptitude_gain,20) and is_equal_approx(p.aperture.capacity,44.1),"shared lifetime aptitude cap")
	setup_rank(4)
	cast("clear_origin_silkworm")
	u.tick(2,game)
	p.position+=Vector2(2,0)
	u.tick(2,game)
	expect(not u.has("aptitude_training") and is_equal_approx(p.aperture.capacity,44.3),"movement interrupts without refund or extra growth")
	setup_rank(4)
	cast("clear_origin_silkworm")
	game.damage_player(1)
	expect(not u.has("aptitude_training"),"damage interrupts aptitude")
	setup_rank(4)
	cast("clear_origin_silkworm")
	u.break_veil()
	expect(not u.has("aptitude_training"),"attack interrupts aptitude")
	setup_rank(4)
	cast("clear_origin_silkworm")
	u.tick(4,game)
	var saved_gain:float=p.aperture.aptitude_gain
	expect(game.save_game() and game._load_save(),"save/load aptitude through formal character slot")
	expect(is_equal_approx(p.aperture.aptitude_gain,saved_gain) and is_equal_approx(p.aperture.capacity,44+saved_gain) and not u.has("aptitude_training"),"growth persists but active training does not resume")
	for id in instances.keys():
		var current:GuVirtual=game.get_node("/root/Gus").get_gu_by_id(instances[id].id)
		if current!=null: instances[id]=current
	var old:=ApertureState.new()
	old.load_data({"rank":2,"capacity":44})
	expect(old.aptitude_gain==0 and old.capacity==44,"old save defaults to zero acquired aptitude")

func other_effect_tests() -> void:
	setup_rank()
	var p:Player=game.player
	var u:=p.utility_gu
	p.body.parts.leg_l.hp=10
	p.hp=60
	game.body_ui.select_part("leg_l")
	cast("scar_stitch")
	expect(p.body.parts.leg_l.hp==20 and p.hp==64,"mending uses its own effect magnitude")
	setup_rank()
	p.body.consciousness=60
	cast("calm_bell_moth")
	expect(p.body.consciousness==78,"consciousness restoration applies")
	setup_rank()
	cast("calm_bell_moth")
	expect(p.yuan==44 and u.cooldowns.is_empty(),"full consciousness rejects without payment")
	setup_rank()
	for key in ["poison","burn","slow","shock","bleed"]: p.status[key]=3
	cast("purifying_lacewing")
	expect(p.status.poison==0 and p.status.burn==0 and p.status.slow==0 and p.status.shock==0 and p.status.bleed==3,"purification leaves wounds and bleeding untouched")
	setup_rank()
	p.body.parts.leg_l.hp=0
	p.body.parts.leg_l.destroyed=true
	cast("return_spring_silk")
	expect(p.yuan==44 and not u.has("regrowth"),"rank five healing cannot regrow destroyed parts")
	setup_rank()
	cast("wall_polish_snail")
	var before:float=p.yuan
	game.meditating=true
	game._update_meditation(5)
	expect(is_equal_approx(p.aperture.wall_progress,6) and is_equal_approx(before-p.yuan,6),"accelerated meditation charges matching essence")
	game.stop_meditation("")
	setup_rank()
	cast("prism_aegis")
	expect(u.absorb(100,game)==0 and u.active.shell.points==250,"rank five shield absorbs real finite damage")

func progression_tests() -> void:
	var p:Player=game.player
	for rank in range(1,5):
		setup_rank(rank)
		p.aperture.stage=3
		p.aperture.wall_progress=100
		game.attempt_breakthrough()
		expect(game.meditating and p.aperture.crossing,"real crossing action rank "+str(rank))
		game._update_meditation(30)
		expect(p.aperture.rank==rank+1 and p.aperture.stage==0,"continuous crossing reaches rank "+str(rank+1))
	setup_rank(5)
	p.aperture.stage=3
	p.aperture.wall_progress=100
	game.attempt_breakthrough()
	expect(p.aperture.rank==5 and not p.aperture.crossing,"no accidental immortal rank")
	var low:=ApertureState.new()
	low.load_data({"rank":1,"stage":3,"capacity":20,"essence":20,"wall_progress":100})
	expect(low.begin_crossing() and low.advance_crossing(30) and low.rank==2,"lowest random aptitude has playable sandbox crossing")
