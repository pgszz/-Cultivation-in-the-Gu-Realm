class_name AwakeningTests
extends RefCounted

var game: Node
var test:=CanonTests.new()
var checked:=0
var failures:Array[String]=[]

func expect(ok: bool, message: String) -> void:
	checked+=1
	if not ok:
		failures.append(message)
		print("AWAKENINGTEST FAIL "+message)

func shot(name: String) -> void:
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	RenderingServer.force_draw()
	var picture:=game.get_viewport().get_texture().get_image()
	expect(picture.save_png("res://shot_awakening_"+name+".png")==OK,"save window evidence "+name)

func enter_flower_sea() -> void:
	if game.world.in_interior: game.exit_house(false)
	for house in World.HOUSE_DATA:
		if house.id=="spring_cave":
			game.player.position=house.pos+Vector2(0,40)
			await test.key(KEY_E)
			break
	expect(game.current_house_id=="spring_cave" and game.world.in_interior,"actual E enters existing grotto")
	game.player.position=HouseInterior.ORIGIN+Vector2(0,-10)
	await test.key(KEY_E)
	expect(game.awakening_ui.visible,"actual flower-sea E opens awakening")

func run(main: Node) -> void:
	game=main
	test.game=game
	game.set_process(false)
	await test.start_character(false)
	game.player.set_process(false)
	game.awakening_ui.set_process(false)
	var p:Player=game.player
	var ui:AwakeningUI=game.awakening_ui
	var gus:GuManager=game.get_node("/root/Gus")
	var initial:Dictionary=game.character_saves.load_character(game.character_id)
	var potential:float=initial.aperture.potential
	expect(p.rank==0 and p.aperture.capacity==0 and p.yuan==0,"real new character starts mortal without aperture or essence")
	expect(potential>=20 and potential<=99 and initial.rank==0,"latent aptitude is persisted at creation")
	expect(p.captured.is_empty() and gus.owned_gus.is_empty() and p.vital_gu_id=="","no starter or vital Gu before awakening")
	expect(p.discovered.has("hope_gu"),"mortal knows hope guide without owning ceremony Gu")
	var art:=GuArt.texture("hope_gu")
	expect(art!=null and art.get_width()>=512 and art.get_image().detect_alpha()!=Image.ALPHA_NONE,"Hope illustration has actual transparent alpha")
	p.aperture.recover(6000)
	expect(p.yuan==0 and p.aperture.recovery_rate()==0,"mortal cannot naturally regenerate essence")
	expect(not p.aperture.spend(0) and not p.aperture.spend(1) and not p.aperture.refine_essence(),"mortal cannot spend or refine even zero-cost essence")
	expect(p.aperture.cultivate(600)==0 and p.aperture.wall_progress==0 and not p.aperture.begin_crossing(),"cultivation cannot bypass opening")
	var stones:=p.crystals
	game.absorb_primeval_stone()
	expect(p.crystals==stones and p.aperture.stone_reserve==0,"mortal stone absorption rejects without charging")
	await test.key(KEY_J)
	await test.key(KEY_R)
	expect(not game.meditating and not game.refine_layer.visible,"actual J and R cannot bypass mortal restrictions")
	game.attempt_breakthrough()
	expect(p.rank==0,"breakthrough button cannot open aperture")
	var fake:GuVirtual=gus.add_gu("moon_blade")
	fake.location="bag"
	game.equip_gu(fake.id,0)
	expect(p.skill_slots[0]=="" and not game.move_gu(fake.id,"aperture") and not game.move_gu(fake.id,"body"),"mortal cannot equip or move Gu inside")
	game.cast_skill(0)
	expect(game.projectiles.is_empty(),"mortal cannot cast")
	gus.remove_gu(fake.id)
	p.captured.append({"id":"moon_blade","rank":1,"progress":0.0})
	game._refine_at(0)
	game._update_refine(200)
	expect(not game.refining and p.captured[0].progress==0,"direct refinement cannot bypass mortal gate")
	p.captured.clear()
	expect(game._can_act() and p.body.can_dash(),"mortal keeps ordinary world actions")
	await test.key(KEY_Q)
	expect(game.aperture_ui.mortal_panel.visible and not game.aperture_ui.cols.visible,"Q shows unopened guidance instead of an aperture")
	await shot("mortal")
	await test.click(game.aperture_ui.awaken_button)
	expect(not game.journal.visible and game.waypoint_name.contains("希望蛊"),"guide button marks the real grotto entrance")
	game.open_awakening()
	ui.begin()
	ui.advance(20)
	expect(not ui.playing and p.rank==0,"opening cannot happen outside flower sea")
	ui.close()
	await enter_flower_sea()
	p.status.poison=1
	ui.begin()
	expect(not ui.playing,"poison blocks starting ceremony")
	p.status.poison=0
	ui.refresh()
	await test.click(ui.begin_button)
	expect(ui.playing and game.paused,"actual begin button starts paused cinematic")
	ui.advance(4)
	expect(p.rank==0 and p.aperture.capacity==0,"light gathering does not grant rank early")
	expect(not ui._commit() and p.rank==0 and p.captured.is_empty(),"commit rejects an unfinished ceremony without rewards")
	await test.key(KEY_TAB)
	await test.key(KEY_R)
	expect(ui.visible and not game.journal.visible and not game.refine_layer.visible,"cinematic blocks competing menus")
	await test.key(KEY_ESCAPE)
	ui.advance(30)
	expect(not ui.visible and not ui.playing and not game.paused and p.rank==0 and p.captured.is_empty(),"Escape cancels without grants or stuck pause")
	expect(game.save_game() and game._load_save(),"interrupted mortal saves and reloads")
	expect(p.rank==0 and p.aperture.potential==potential and p.yuan==0,"reload cannot reroll latent aptitude or invent essence")
	await enter_flower_sea()
	ui.begin()
	game.current_house_id="home"
	ui.advance(1)
	expect(not ui.playing and p.rank==0,"leaving ritual location interrupts safely")
	game.current_house_id="spring_cave"
	ui.refresh()
	ui.begin()
	p.dead=true
	ui.advance(1)
	expect(not ui.playing and p.rank==0,"dead character cannot finish awakening")
	p.dead=false
	ui.refresh()
	ui.begin()
	var temporary:String=game.SAVE_PATH+".tmp"
	DirAccess.make_dir_recursive_absolute(temporary)
	ui.advance(12)
	expect(p.rank==0 and p.captured.is_empty() and not ui.completed,"save failure rolls back rank and starter grant")
	DirAccess.remove_absolute(temporary)
	expect(game.character_saves.load_character(game.character_id).aperture.potential==potential,"save failure preserves original latent aptitude")
	p.hp=79
	p.body.parts.hand_l.hp-=3
	var hand_hp:float=p.body.parts.hand_l.hp
	ui.refresh()
	await test.click(ui.begin_button)
	expect(ui.playing,"retry after failed save uses normal button")
	DirAccess.make_dir_recursive_absolute("res://awakening_frames")
	for frame in 36:
		ui.advance(1.0/3.0)
		await game.get_tree().process_frame
		await RenderingServer.frame_post_draw
		if DisplayServer.get_name()!="headless":
			game.get_viewport().get_texture().get_image().save_png("res://awakening_frames/%03d.png"%frame)
		if frame==5: await shot("gathering")
		if frame==19: await shot("membrane")
		if frame==30: await shot("sea")
	ui.advance(0.001)
	expect(ui.completed and p.rank==1 and p.aperture.stage==0,"full animation completes first rank")
	expect(p.aperture.capacity==potential and p.yuan==potential and p.aperture.wall_progress==0,"primordial sea matches committed aptitude")
	expect(p.hp==79 and p.body.parts.hand_l.hp==hand_hp,"awakening does not heal injuries or reset ordinary body")
	expect(p.captured.size()==1 and p.captured[0].id=="moon_blade" and p.vital_gu_id=="" and gus.owned_gus.is_empty(),"one unrefined starter is external; hope is consumed and not vital")
	await shot("result")
	var saved:Dictionary=game.character_saves.load_character(game.character_id)
	expect(saved.rank==1 and saved.aperture.capacity==potential and saved.captured.size()==1,"successful result persisted before success UI")
	ui.begin()
	ui.advance(99)
	expect(not ui._commit() and p.captured.size()==1 and p.aperture.capacity==potential,"repeated action cannot duplicate starter or reroll aptitude")
	await test.click(ui.close_button)
	expect(not ui.visible and not game.paused,"result button returns to world")
	expect(game._load_save() and p.rank==1 and p.aperture.capacity==potential and p.captured.size()==1,"completed character survives reload")
	await test.key(KEY_Q)
	expect(game.aperture_ui.cols.visible and not game.aperture_ui.mortal_panel.visible,"Q changes to real aperture after awakening")
	await shot("aperture")
	game.journal.close()
	game.compendium_ui.show()
	game.compendium_ui.refresh()
	game.compendium_ui._show_detail("hope_gu")
	expect(game.compendium_ui.portrait.texture==art and game.compendium_ui.detail.text.contains("开窍消耗"),"compendium shows ritual usage and illustration")
	await shot("hope")
	game.compendium_ui.hide()
	await test.key(KEY_R)
	expect(game.refine_layer.visible,"normal refinement is unlocked after awakening")
	game._refine_at(0)
	p.captured[0].progress=100
	game._finish_refine()
	expect(gus.owned_gus.size()==1 and p.vital_gu_id==gus.owned_gus[0].id,"first actually refined Gu becomes vital")
	game.close_refine()
	for pair in [[20,"丁等"],[39,"丁等"],[40,"丙等"],[59,"丙等"],[60,"乙等"],[79,"乙等"],[80,"甲等"],[99,"甲等"]]:
		var state:=ApertureState.new()
		state.potential=pair[0]
		expect(state.awaken() and state.aptitude()==pair[1] and state.capacity==pair[0],"aptitude boundary "+str(pair[0]))
		expect(not state.awaken(),"opened aperture cannot awaken twice")
	var legacy:=ApertureState.new()
	legacy.load_data({"rank":2,"stage":2,"capacity":73,"essence":17,"wall_progress":42})
	expect(legacy.rank==2 and legacy.stage==2 and legacy.capacity==73 and legacy.essence==17 and legacy.wall_progress==42,"legacy cultivator retains rank aptitude and progress")
	legacy.load_data({})
	expect(legacy.rank==1 and legacy.capacity==44,"legacy missing aperture fields retain historical fallback")
	print("AWAKENINGTEST checked=%d failures=%s"%[checked,str(failures)])
	game.get_tree().quit(0 if failures.is_empty() else 1)
