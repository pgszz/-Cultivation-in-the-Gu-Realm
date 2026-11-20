class_name PlayerStatusTests
extends RefCounted

var game: Node
var test:=CanonTests.new()
var instances: Dictionary={}

func settle() -> void:
	await game.get_tree().create_timer(0.22).timeout

func shot(name: String) -> void:
	game.hud.player_panel.refresh()
	await settle()
	await RenderingServer.frame_post_draw
	test.expect(game.get_viewport().get_texture().get_image().save_png("res://shot_status_"+name+".png")==OK,"rendered "+name)

func cast(id: String) -> void:
	game.player.yuan=44
	game.equip_gu(instances[id].id,0)
	game.player.cast_cds[0]=0
	game.cast_skill(0)

func stat(name: String) -> Dictionary:
	for item in PlayerStatus.snapshot(game).attributes:
		if item.name==name: return item
	return {}

func find_effect(id: String) -> Dictionary:
	for item in PlayerStatus.snapshot(game).effects:
		if item.id==id: return item
	return {}

func run(main: Node) -> void:
	game=main
	test.game=game
	game.set_process(false)
	await test.start_character()
	var p:Player=game.player
	var hud:PlayerHUD=game.hud.player_panel
	await settle()
	test.expect(hud.is_visible_in_tree() and game.get_viewport_rect().encloses(hud.get_global_rect()),"portrait HUD fits viewport")
	test.expect(hud.portrait.appearance.texture==p.appearance.texture,"HUD uses actual customized character texture")
	for compact in [false,true]:
		game.hud.minimal=compact
		hud.refresh()
		await test.click(hud.portrait_button)
		test.expect(game.journal.visible and game.journal.active_page=="character","portrait opens attributes compact="+str(compact))
		test.expect(p.atk_cd==0 and not game._world_attack_held,"portrait click never attacks world")
		await test.key(KEY_ESCAPE)
		for key in hud.buttons:
			await test.click(hud.buttons[key])
			if not game.journal.visible or game.journal.active_page!=key:
				print("STATUS NAV expected=%s actual=%s visible=%s rect=%s hud=%s"%[key,game.journal.active_page,game.journal.visible,hud.buttons[key].get_global_rect(),hud.get_global_rect()])
				await shot("navfailure")
			test.expect(game.journal.visible and game.journal.active_page==key,"compact navigation "+key+" "+str(compact))
			test.expect(not game._world_attack_held,"navigation click consumed "+key)
			await test.key(KEY_ESCAPE)
	await test.click(hud.collapse_button)
	await settle()
	test.expect(not game.hud.minimal and hud.vitals.visible,"plus button expands bars")
	await test.click(hud.collapse_button)
	await settle()
	test.expect(game.hud.minimal and not hud.vitals.visible and hud.quickbar.is_visible_in_tree(),"minus button retains working shortcuts")
	await test.key(KEY_F1)
	await settle()
	test.expect(not game.hud.minimal and hud.vitals.visible,"F1 and collapse button share state")
	var zoom:float=game.zoom_level
	var wheel:=InputEventMouseButton.new()
	wheel.position=hud.portrait_button.get_global_rect().get_center()
	wheel.button_index=MOUSE_BUTTON_WHEEL_UP
	wheel.pressed=true
	game.get_viewport().push_input(wheel,true)
	wheel=wheel.duplicate()
	wheel.pressed=false
	game.get_viewport().push_input(wheel,true)
	test.expect(game.zoom_level==zoom,"wheel over HUD does not zoom world")
	for id in ["brute_longhorn","yellow_camel","wind_moth","night_firefly","gravel_shell","copper_skin","veil_leaf","bamboo_saw"]:
		var gu:GuVirtual=game.get_node("/root/Gus").add_gu(id)
		gu.location="aperture"
		instances[id]=gu
	game.enter_house(World.HOUSE_DATA[0])
	p.position=HouseInterior.ORIGIN+Vector2(0,65)
	p.body.reset_full()
	p.boar_cultivation.progress=0.5
	cast("brute_longhorn")
	cast("yellow_camel")
	cast("wind_moth")
	cast("night_firefly")
	test.expect(is_equal_approx(stat("徒手攻击").value,38.5),"permanent +5.5 and temporary +22 sum once")
	test.expect(stat("徒手攻击").value==p.melee_attack(),"display attack equals combat damage input")
	test.expect(is_equal_approx(stat("移动速度").value,226.8),"actual haste shows +35 percent")
	test.expect(is_equal_approx(stat("疾步体力消耗").value,10),"endurance shows 25 to 10")
	p.body.parts.leg_l.hp=8
	p.body.parts.eye_l.hp=0
	p.body.parts.eye_l.destroyed=true
	test.expect(is_equal_approx(stat("移动速度").value,158.76),"leg injury multiplies haste rather than adding percentages")
	test.expect(is_equal_approx(stat("视野半径").value,305) and stat("视野半径").value==game.fog.radius_world(),"vision bonus is reduced by eye injury exactly as world fog")
	test.expect(is_equal_approx(stat("精准度").value,75),"destroyed eye reduces accuracy 25 percentage points")
	var before:Vector2=p.position
	var controls:=ControlsSettingsTests.new()
	controls.key_state(KEY_D,true)
	game._update_player(0.05)
	controls.key_state(KEY_D,false)
	test.expect(absf(p.position.distance_to(before)-158.76*0.05)<0.04,"world displacement uses displayed injured haste speed")
	cast("gravel_shell")
	var hp:float=p.hp
	p.iframes=0
	game.damage_player(7)
	test.expect(p.hp==hp and float(p.utility_gu.active.shell.points)==25 and find_effect("shell").detail.contains("25.0"),"shield status follows actual absorbed damage")
	cast("copper_skin")
	test.expect(find_effect("shell").is_empty() and not find_effect("guard").is_empty(),"mutually exclusive guard replaces shield in state list")
	p.yuan=0
	game._update_owned_gu(0.1)
	test.expect(find_effect("guard").is_empty(),"insufficient essence removes expired guard from display")
	p.yuan=44
	cast("veil_leaf")
	cast("bamboo_saw")
	p.status.poison=6
	p.body.blood=70
	p.body.pain=65
	test.expect(is_equal_approx(stat("精准度").value,46),"eye pain and blood penalties display final 46 percent")
	test.expect(find_effect("wound").detail.contains("身体血量") and find_effect("poison").detail.contains("每次基础"),"bleeding and probabilistic HP damage use distinct units")
	game.character_ui.refresh()
	test.expect(game.character_ui.attributes.text.contains("永久进度") and game.character_ui.attributes.text.contains("蛮力负担"),"unified sheet preserves cultivation and stamina details")
	game.exit_house(false)
	test.expect(find_effect("haste").is_empty(),"crossing building boundary clears utility effects from display")
	p.utility_gu.cooldowns.clear()
	cast("wind_moth")
	cast("night_firefly")
	cast("veil_leaf")
	cast("bamboo_saw")
	game._update_camera(0)
	game.fog.reveal(p.position,500)
	await shot("hud")
	game.hud.minimal=true
	await shot("compact")
	var motion:=InputEventMouseMotion.new()
	motion.position=hud.status_buttons.brute.get_global_rect().get_center()
	game.get_viewport().push_input(motion,true)
	await test.click(hud.status_buttons.brute)
	test.expect(game.journal.visible and game.journal.active_page=="character","effect chip opens unified character sheet")
	await settle()
	test.expect(game.character_ui.detail_scroll.scroll_vertical>0,"effect chip scrolls directly to full status details")
	var left:float=p.gu_effects.brute_left
	p.utility_gu.tick(1,game)
	await settle()
	test.expect(p.gu_effects.brute_left==left and not find_effect("haste").is_empty(),"opening attributes pauses durations")
	await shot("effects")
	var scroll_event:=InputEventMouseButton.new()
	scroll_event.position=game.character_ui.detail_scroll.get_global_rect().get_center()
	scroll_event.button_index=MOUSE_BUTTON_WHEEL_DOWN
	for i in 45:
		for pressed in [true,false]:
			scroll_event=scroll_event.duplicate()
			scroll_event.pressed=pressed
			game.get_viewport().push_input(scroll_event,true)
	test.expect(game.character_ui.detail_scroll.scroll_vertical>game.character_ui.status_heading.position.y and game.zoom_level==zoom,"mouse wheel reaches lower debuffs without zooming world")
	await shot("debuffs")
	game.character_ui.detail_scroll.scroll_vertical=0
	await shot("attributes")
	test.expect(game.journal.panel.get_global_rect().encloses(game.character_ui.detail_scroll.get_global_rect()),"scrollable attributes stay inside journal")
	game.character_ui.detail_scroll.scroll_vertical=int(game.character_ui.detail_scroll.get_v_scroll_bar().max_value)
	await test.key(KEY_ESCAPE)
	await test.click(hud.portrait_button)
	await settle()
	test.expect(game.character_ui.detail_scroll.scroll_vertical==0,"avatar always returns to attributes after browsing lower status details")
	await test.key(KEY_ESCAPE)
	p.gu_effects.tick(20,p,game.get_node("/root/Gus"))
	p.utility_gu.tick(30,game)
	hud.refresh()
	test.expect(find_effect("brute").is_empty() and find_effect("haste").is_empty() and not hud.status_buttons.has("brute"),"expired effects leave both HUD and full sheet")
	p.body.unconscious=true
	test.expect(stat("移动速度").value==0 and not find_effect("unconscious").is_empty(),"unconscious displays zero movement and cannot act")
	await test.click(hud.portrait_button)
	test.expect(game.journal.visible,"unconscious character can still inspect attributes")
	await test.key(KEY_ESCAPE)
	p.body.unconscious=false
	p.body.reset_full()
	cast("wind_moth")
	test.expect(game.save_game(),"save unified HUD preference through actual character save")
	test.expect(game._load_save(),"reload actual character")
	await settle()
	test.expect(find_effect("haste").is_empty() and game.hud.minimal and hud.quickbar.is_visible_in_tree(),"reload restores compact preference without stale active buffs")
	test.expect(is_equal_approx(p.boar_cultivation.attack_bonus(),5.5),"permanent cultivation survives loading")
	var saved:Dictionary=game._snapshot().duplicate(true)
	for i in 20: PlayerStatus.snapshot(game)
	test.expect(game._snapshot()==saved,"status inspection does not mutate player or environment")
	var adventure:=AdventureTests.new()
	adventure.game=game
	var shore:Dictionary=adventure.shore(0)
	test.expect(not shore.is_empty(),"found actual shoreline for environmental modifiers")
	if not shore.is_empty():
		p.position=shore.water
		p.dir=0
		var expected:float=p.speed*game.world.water_speed(p.position)*game.world.blocks.speed_multiplier(p.position,Vector2.RIGHT)
		test.expect(absf(stat("移动速度").value-expected)<0.01 and find_effect("游泳").short.contains("-30%"),"shore swimming displays actual 70 percent water speed")
		p.position=shore.land
		var cell:=TerrainLayers.cell_at(p.position)
		game.world.environment.cells[game.world.environment.key(cell,0)]={"wet":6.0}
		expected=p.speed*0.85*game.world.blocks.speed_multiplier(p.position,Vector2.RIGHT)
		test.expect(absf(stat("移动速度").value-expected)<0.01 and not find_effect("湿地").is_empty(),"wet terrain displays and calculates fifteen percent penalty")
		game.world.environment.cells.clear()
		p.status.wet=3
		expected=p.speed*game.world.blocks.speed_multiplier(p.position,Vector2.RIGHT)
		test.expect(absf(stat("移动速度").value-expected)<0.01 and find_effect("wet").detail.contains("无额外"),"attached wet status does not invent an inactive speed penalty")
	print("STATUSTEST checked=%d failures=%s"%[test.checked,str(test.failures)])
	game.get_tree().quit(0 if test.failures.is_empty() else 1)
