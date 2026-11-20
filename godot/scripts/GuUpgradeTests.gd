class_name GuUpgradeTests
extends RefCounted

var game:Node
var checked:=0
var failures:Array[String]=[]

func enter(id: String) -> void:
	game.exit_house(false)
	for house in World.HOUSE_DATA:
		if house.id==id:
			game.enter_house(house)
			return
	expect(false,"missing house "+id)

func expect(ok: bool, message: String) -> void:
	checked+=1
	if not ok:
		failures.append(message)
		print("GUUPGRADETEST FAIL "+message)

func give(id: String) -> GuVirtual:
	var gu:GuVirtual=game.get_node("/root/Gus").add_gu(id)
	game.player.owned.append(id)
	if not game.player.discovered.has(id): game.player.discovered.append(id)
	return gu

func choose_roll(success: bool) -> void:
	var rng:=RandomNumberGenerator.new()
	for value in 100:
		rng.seed=value
		if (rng.randf()<0.8)==success:
			game._rng.seed=value
			return

func click(button: Control) -> void:
	var suite:=CanonTests.new()
	suite.game=game
	await suite.click(button)

func shot(name: String) -> void:
	game.fx.queue_redraw()
	game.player.queue_redraw()
	game.top.queue_redraw()
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	RenderingServer.force_draw()
	var image:=game.get_viewport().get_texture().get_image()
	expect(image!=null and image.save_png("res://shot_guupgrade_"+name+".png")==OK,"save UI evidence "+name)

func run(main: Node) -> void:
	game=main
	game.set_process(false)
	game.start_game()
	CanonTests.prepare_cultivator(game)
	game.player.set_process(false)
	game.fx.set_process(false)
	var p:Player=game.player
	var gus:GuManager=game.get_node("/root/Gus")
	var hunger:HungerSystem=game.get_node("/root/Hunger")
	var inv:Inventory=game.get_node("/root/Inv")
	for id in GuProgression.RECIPES:
		var art:=GuArt.texture(id)
		expect(art!=null and art.get_width()>=512 and art.get_image().detect_alpha()!=Image.ALPHA_NONE,"rank two portrait has true alpha: "+id)
	enter("home")
	p.body.reset_full()
	p.hp=100
	p.status.clear()
	p.aperture.rank=1
	p.aperture.stage=3
	p.aperture.wall_progress=100
	p.aperture.essence=29
	expect(not p.aperture.begin_crossing(),"crossing needs thirty percent ordinary essence")
	p.aperture.essence=44
	game.attempt_breakthrough()
	expect(game.meditating and p.aperture.crossing and not game.paused,"aperture action starts continuous crossing")
	game._update_meditation(10)
	expect(p.aperture.rank==1 and is_equal_approx(p.aperture.essence,34),"ten seconds spends ten essence without granting rank early")
	game.stop_meditation("")
	expect(not p.aperture.crossing and p.aperture.crossing_seconds==0 and p.aperture.essence==34,"interruption resets progress without refund")
	p.aperture.essence=44
	game.attempt_breakthrough()
	game.paused=true
	game._update_meditation(10)
	expect(p.aperture.crossing_seconds==0,"menu pauses crossing")
	game.paused=false
	game._update_meditation(30)
	expect(p.aperture.rank==2 and p.aperture.stage==0 and not game.meditating,"crossing reaches rank two first stage")
	expect(is_equal_approx(p.aperture.essence,1.4) and not p.aperture.refine_essence(),"remaining essence converts and rank one liquor cannot refine rank two")
	p.aperture.essence=44
	for gu in gus.owned_gus.duplicate(): gus.remove_gu(gu.id)
	p.owned.clear()
	p.captured.clear()
	p.skill_slots=["","",""]
	p.vital_gu_id=""
	p.crystals=5000
	game.gu_shop_purchased.clear()
	game.jade_gu_purchased=false
	enter("shop")
	for id in ["moon_blade","little_light","little_light"]:
		var count:=p.captured.size()
		game.village_ui.show_service("shop")
		await game.get_tree().process_frame
		await game.get_tree().process_frame
		game.village_ui.action_scroll.ensure_control_visible(game.village_ui.gu_buttons[id])
		await click(game.village_ui.gu_buttons[id])
		expect(p.captured.size()==count+1,"shop UI supplies unrefined "+id)
		if p.captured.size()!=count+1:
			await shot("shop_failure")
			print("SHOP DEBUG house=%s running=%s message=%s button=%s scroll=%s" % [game.current_house_id,game.running,game.last_action_message,game.village_ui.gu_buttons[id].get_global_rect(),game.village_ui.action_scroll.get_global_rect()])
			game.get_tree().quit(1)
			return
		game.village_ui.close()
		p.captured[-1].progress=100
		game.refine_target=p.captured.size()-1
		game._finish_refine()
	var ids:Array[String]=[]
	for gu in GuRefinement.materials(game,"moon_glow"): ids.append(gu.id)
	expect(ids.size()==3 and ids[1]!=ids[2],"two light materials are independent instances")
	var money:=p.crystals
	var essence:=p.aperture.essence
	var light:GuVirtual=gus.get_gu_by_id(ids[1])
	game.move_gu(light.id,"bag")
	expect(not GuRefinement.fuse(game,"moon_glow") and p.crystals==money and p.aperture.essence==essence,"bag material blocks without charging")
	game.move_gu(light.id,"aperture")
	light.dead=true
	expect(not GuRefinement.fuse(game,"moon_glow") and p.crystals==money,"dead material blocks without charging")
	light.dead=false
	hunger.gu_data[light.id].dead=true
	expect(not GuRefinement.fuse(game,"moon_glow"),"hunger death cannot bypass recipe validation")
	hunger.gu_data[light.id].dead=false
	hunger.gu_data[light.id].current_hunger=37
	p.crystals=79
	expect(not GuRefinement.fuse(game,"moon_glow") and p.crystals==79,"insufficient stones do not partially charge")
	p.crystals=money
	p.aperture.essence=9
	expect(not GuRefinement.fuse(game,"moon_glow") and p.crystals==money and p.aperture.essence==9,"insufficient essence leaves both resources untouched")
	p.aperture.essence=essence
	choose_roll(false)
	expect(not GuRefinement.fuse(game,"moon_glow") and p.crystals==money-80,"failed fusion spends displayed stone cost")
	expect(is_equal_approx(p.aperture.essence,essence-10) and GuRefinement.materials(game,"moon_glow").size()==3,"failed fusion spends essence once and preserves materials")
	game.open_journal("refinement")
	var ui:RefinementUI=game.journal.pages.refinement
	ui.select_recipe("moon_glow")
	await shot("recipe")
	choose_roll(true)
	await click(ui.action)
	var moon:GuVirtual=gus.active_gu
	expect(moon.template_id=="moon_glow" and moon.rank==2,"recipe button creates rank two moon glow")
	expect(p.vital_gu_id==moon.id and p.skill_slots[0]==moon.id and p.skill_slots[1]=="" and p.skill_slots[2]=="","vital and shortcut transfer without duplicate bindings")
	expect(is_equal_approx(hunger.get_hunger(moon.id),37),"fusion inherits minimum fullness")
	for old in ids: expect(gus.get_gu_by_id(old)==null and not hunger.gu_data.has(old),"consumed instance and hunger registration removed")
	money=p.crystals
	expect(not GuRefinement.fuse(game,"moon_glow") and p.crystals==money,"repeat action cannot duplicate product")
	game.journal.close()
	game.projectiles.clear()
	p.aperture.essence=44
	p.cast_cds[0]=0
	game.cast_skill(0)
	expect(game.projectiles.size()==1 and game.projectiles[0].dmg==78 and game.projectiles[0].r==12,"actual moon glow projectile has threefold damage")
	expect(is_equal_approx(p.aperture.essence,38),"rank two projectile costs six percent essence")
	var extra:=give("little_light")
	p.light_support_id=extra.id
	p.cast_cds[0]=0
	game.projectiles.clear()
	game.cast_skill(0)
	expect(game.projectiles[0].dmg==78,"light does not apply unsupported extra multiplier")
	p.aperture.rank=1
	p.cast_cds[0]=0
	game.projectiles.clear()
	essence=p.aperture.essence
	game.cast_skill(0)
	expect(game.projectiles.is_empty() and p.aperture.essence==essence,"rank gate blocks without spending")
	p.aperture.rank=2
	for recipe in ["white_jade","moon_raiment"]:
		for tid in GuProgression.RECIPES[recipe].inputs: give(tid)
		p.aperture.essence=44
		p.boar_cultivation.progress=0.7
		choose_roll(true)
		expect(GuRefinement.fuse(game,recipe),"defensive fusion "+recipe)
		var gu:GuVirtual=gus.active_gu
		expect(is_equal_approx(p.boar_cultivation.progress,0.7),"permanent muscle survives "+recipe)
		p.skill_slots[1]=gu.id
		p.cast_cds[1]=0
		p.aperture.essence=44
		game.cast_skill(1)
		expect(is_equal_approx(p.gu_effects.absorb_damage(100,p,gus),20 if recipe=="white_jade" else 30),"stronger real reduction "+recipe)
		expect(not p.jade_guard and p.gu_effects.guard_id==gu.id,"defensive effects remain exclusive")
		p.hp=100
		p.shield=0
		p.iframes=0
		p.aperture.essence=44
		game.damage_player(10,"none")
		expect(is_equal_approx(p.hp,98 if recipe=="white_jade" else 97),"player damage entry applies upgraded protection "+recipe)
		p.body.reset_full()
		p.status.clear()
		if recipe=="white_jade":
			hunger.gu_data[gu.id].current_hunger=0
			inv.add_item("jade",4)
			for n in 4: expect(inv.use_item("jade",gu.id),"white jade accepts two-liang portion %d"%n)
			expect(hunger.get_hunger(gu.id)==100,"eight liang completes white jade feeding")
			expect(is_equal_approx(hunger.gu_data[gu.id].hunger_rate,100.0/(20*1440)),"white jade has twenty-day feeding cycle")
	var raiment:GuVirtual=gus.active_gu
	game.journal.close()
	game.exit_house(false)
	var target:WorldPerson=game.population.actors["guyue_civil_0"]
	p.position=target.position+Vector2(20,0)
	p.gu_effects.guard_id=""
	p.aperture.essence=44
	target.hostile=false
	target.hp=target.max_hp
	game.shake=0
	game.set_camera_zoom(1.0)
	game._update_camera(0)
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	await game.get_tree().process_frame
	game.get_viewport().warp_mouse(game.get_viewport().get_canvas_transform()*target.position)
	await game.get_tree().process_frame
	var motion:=InputEventMouseMotion.new()
	motion.position=game.get_viewport().get_canvas_transform()*target.position
	game.get_viewport().push_input(motion,true)
	await RenderingServer.frame_post_draw
	p.cast_cds[1]=0
	game.cast_skill(1)
	if p.gu_effects.ward_target!=target:
		print("WARD AIM DEBUG cursor=",game.get_global_mouse_position()," target=",target.position," player=",p.position," guard=",p.gu_effects.guard_id," ward=",p.gu_effects.ward_id," picked=",p.gu_effects.ward_target," slot=",p.skill_slots[1]," expected=",raiment.id," rank=",p.aperture.rank," cd=",p.cast_cds[1]," dead=",target.dead," viewport=",game.get_viewport_rect()," screen=",motion.position)
	expect(p.gu_effects.ward_target==target and p.gu_effects.ward_id==raiment.id and p.gu_effects.guard_id=="","actual mouse aim selects nearby neutral NPC for ward")
	game.fx.clear_transients()
	game.fx._process(1.0)
	game.fx._process(1.0)
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	var draw_count:Array[int]=[0]
	var count_draw:Callable=func(): draw_count[0]+=1
	game.fx.draw.connect(count_draw)
	game.fx._process(0.1)
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	expect(draw_count[0]>0,"allied ward keeps redrawing after transient particles expire")
	game.fx.draw.disconnect(count_draw)
	game.get_viewport().warp_mouse(Vector2(100,150))
	await shot("ward")
	p.dead=true
	expect(not p.gu_effects.ward_valid(game),"dead caster cannot leave a visible or effective ward")
	p.dead=false
	raiment.dead=true
	expect(not p.gu_effects.ward_valid(game),"dead Gu cannot leave a ward between ticks")
	raiment.dead=false
	var source:=Node2D.new()
	game.add_child(source)
	var hp:float=target.hp
	target.receive_hit(10,source)
	expect(is_equal_approx(target.hp,hp-3),"real NPC damage entry receives allied protection")
	target.hostile=true
	hp=target.hp
	target.receive_hit(10,source)
	expect(is_equal_approx(target.hp,hp-10),"hostile recipient immediately loses mitigation")
	target.hostile=false
	expect(p.gu_effects.absorb_ally_damage(10,target,p,game)==10,"player assault cannot be made invulnerable by own ward")
	p.position+=Vector2(400,0)
	p.gu_effects.tick(0,p,gus)
	expect(p.gu_effects.ward_id=="","out of range cancels allied ward")
	source.queue_free()
	enter("home")
	game.open_journal("aperture")
	game.aperture_ui.select_gu(raiment.id)
	await shot("aperture")
	game.journal.close()
	game.compendium_ui.show()
	game.compendium_ui.refresh()
	game.compendium_ui._show_detail("moon_glow")
	await shot("compendium")
	game.compendium_ui.hide()
	game.move_gu(moon.id,"bag")
	game.open_journal("inventory")
	game.inventory_ui.selected_id="owned:"+moon.id
	game.inventory_ui.refresh_inventory()
	await shot("bag")
	game.journal.close()
	var saved:Array[String]=[]
	for gu in gus.owned_gus: saved.append(gu.id)
	expect(game.save_game(),"save upgraded state")
	game._load_save()
	expect(p.aperture.rank==2 and gus.owned_gus.size()==saved.size(),"reload preserves rank and instance count")
	for id in saved: expect(gus.get_gu_by_id(id)!=null,"reload preserves instance identity")
	expect(gus.get_gu_by_id(moon.id).location=="bag" and p.vital_gu_id==moon.id,"reload preserves bag location and upgraded vital identity")
	expect(game.gu_shop_remaining("little_light")==4,"material stock counts persist")
	expect(p.gu_effects.guard_id=="" and p.gu_effects.ward_id=="","load clears active defense")
	print("GUUPGRADETEST checked=%d failures=%s" % [checked,str(failures)])
	game.get_tree().quit(0 if failures.is_empty() else 1)
