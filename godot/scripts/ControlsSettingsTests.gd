class_name ControlsSettingsTests
extends RefCounted

var game: Node
var test := CanonTests.new()

func key_state(code: int, pressed: bool) -> void:
	var event:=InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func settle() -> void:
	await game.get_tree().create_timer(0.15).timeout
	while game.settings_ui.preferences.applying:
		await game.get_tree().process_frame

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	test.expect(game.get_viewport().get_texture().get_image().save_png("res://shot_controls_"+name+".png")==OK,"saved "+name)

func choose(option: OptionButton, index: int) -> void:
	var previous:=option.selected
	await test.click(option)
	var popup:=option.get_popup()
	test.expect(popup.visible,"native option popup opens")
	var received:={"selected":false}
	option.item_selected.connect(func(_index: int): received.selected=true,CONNECT_ONE_SHOT)
	popup.set_focused_item(index)
	for pressed in [true,false]:
		var event:=InputEventKey.new()
		event.keycode=KEY_ENTER
		event.pressed=pressed
		# PopupMenu handles native Window input before Viewport.push_input.
		event.window_id=popup.get_window_id() if pressed else game.get_window().get_window_id()
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	for i in 120:
		await game.get_tree().process_frame
		if received.selected or (previous==index and not popup.visible): break
	test.expect((received.selected or previous==index) and option.selected==index and not popup.visible,"popup keyboard confirms requested choice")
	await settle()

func run(main: Node) -> void:
	game=main
	test.game=game
	game.set_process(false)
	var ui:SettingsUI=game.settings_ui
	var prefs:GameSettings=ui.preferences
	var original_size:Vector2i=game.get_window().size
	await settle()
	if FileAccess.file_exists("user://controls_restart.json"):
		var previous:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://controls_restart.json"))
		test.checked=int(previous.checked)
		test.expect(game.get_window().mode==Window.MODE_WINDOWED and game.get_window().borderless and game.get_window().size==Vector2i(960,540),"new Main restores saved mode and resolution during ready")
		test.expect(ui.sfx_slider.value==63 and prefs.volumes.SFX==63,"new settings UI restores volume without overwriting it")
		print("CONTROLTEST checked=%d failures=%s"%[test.checked,str(test.failures)])
		game.get_tree().quit(0 if test.failures.is_empty() else 1)
		return
	var screen:StartScreen=game.start_screen
	await test.click(screen.settings_button)
	test.expect(ui.visible and not game.running,"start menu opens usable settings before playing")
	await shot("start_settings")
	await test.click(ui.close_button)
	test.expect(not ui.visible and not game.running,"settings returns to start screen")
	await test.start_character()
	test.expect(game.running,"start button still starts game")
	await test.key(KEY_O)
	test.expect(ui.visible and game.paused,"O opens settings and pauses simulation")
	await test.key(KEY_TAB)
	test.expect(ui.visible and not game.journal.visible,"settings owns Tab focus without opening journal")
	test.expect(game.get_viewport_rect().encloses(ui.panel.get_global_rect()),"settings panel fits viewport")
	test.expect(ui.panel.get_global_rect().encloses(ui.close_button.get_global_rect()),"return button stays visible")
	await shot("settings")
	await test.click(ui.close_button)
	test.expect(not ui.visible and not game.paused and not game._world_attack_held,"GUI return resumes without accidental attack")
	await test.key(KEY_ESCAPE)
	await test.click(game.pause_layer.get_meta("vbox").get_node("SettingsButton"))
	test.expect(ui.visible and game.paused,"pause menu settings entry works")
	await test.key(KEY_ESCAPE)
	test.expect(not ui.visible and game.pause_layer.visible and game.paused,"Esc returns to previous paused state")
	await test.key(KEY_ESCAPE)
	await test.key(KEY_O)
	await choose(ui.mode_option,1)
	test.expect(game.get_window().mode==Window.MODE_WINDOWED and game.get_window().borderless,"borderless choice changes actual native window flags")
	test.expect(prefs.mode=="borderless","UI stores borderless mode")
	await choose(ui.resolution_option,ui.resolutions.find(Vector2i(960,540)))
	test.expect(game.get_window().size==Vector2i(960,540),"selected resolution changes native client size")
	await shot("borderless")
	await test.key(KEY_F11)
	await settle()
	test.expect(game.get_window().mode==Window.MODE_FULLSCREEN and prefs.mode=="fullscreen","F11 enters actual fullscreen while settings is open")
	test.expect(ui.resolution_option.disabled,"fullscreen clearly uses native display resolution")
	await shot("fullscreen")
	await test.key(KEY_F11)
	await settle()
	test.expect(game.get_window().mode==Window.MODE_WINDOWED and game.get_window().borderless and game.get_window().size==Vector2i(960,540),"F11 restores borderless type and exact previous client size")
	ui.mode_option.item_selected.emit(0)
	await settle()
	test.expect(not game.get_window().borderless and game.get_window().mode==Window.MODE_WINDOWED,"window option restores title bar")
	ui.resolution_option.item_selected.emit(ui.resolutions.find(original_size))
	await settle()
	test.expect(game.get_window().size==original_size,"window resolution restores initial size")
	game._toggle_quality()
	test.expect(game.get_window().size==original_size,"F2 quality never overwrites chosen resolution")
	game._toggle_quality()
	game.get_window().size=Vector2i(1000,600)
	await game.get_tree().create_timer(0.6).timeout
	test.expect(prefs.window_size==Vector2i(1000,600) and ui.resolutions[ui.resolution_option.selected]==Vector2i(1000,600),"manual resize updates preference and visible custom size")
	ui.sfx_slider.value=0
	test.expect(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")),"SFX zero mutes the real sound bus")
	game._play_tone(220,0.08)
	test.expect(game._sfx_pool[-1].bus=="SFX","combat sound uses SFX slider")
	ui.sfx_slider.value=63
	var loaded:=GameSettings.new()
	test.expect(loaded.load_settings() and loaded.mode==prefs.mode and loaded.window_size==prefs.window_size and loaded.volumes.SFX==63,"actual settings.cfg round trip preserves display and audio")
	# The same loader/apply path used on startup must restore the native window.
	game.get_window().size=Vector2i(800,450)
	await loaded.apply_video(game.get_window())
	test.expect(game.get_window().size==Vector2i(1000,600),"saved settings restore actual window on apply")
	ui.preferences.window_size=original_size
	await ui._apply_video()
	await test.key(KEY_O)
	_check_legacy_settings()
	await _check_movement()
	if test.failures.is_empty():
		prefs.mode="borderless"
		prefs.window_size=Vector2i(960,540)
		prefs.save_settings()
		var marker:=FileAccess.open("user://controls_restart.json",FileAccess.WRITE)
		marker.store_string(JSON.stringify({"checked":test.checked}))
		marker.close()
		game.get_window().mode=Window.MODE_WINDOWED
		game.get_window().borderless=false
		game.get_window().size=Vector2i(800,450)
		game.get_tree().reload_current_scene()
		return
	print("CONTROLTEST checked=%d failures=%s"%[test.checked,str(test.failures)])
	game.get_tree().quit(0 if test.failures.is_empty() else 1)

func _check_legacy_settings() -> void:
	var config:=ConfigFile.new()
	config.set_value("video","resolution_index",0)
	config.set_value("video","fullscreen",true)
	config.set_value("audio","master_volume",27.0)
	config.save("user://legacy_settings.cfg")
	var before:=FileAccess.get_file_as_string("user://legacy_settings.cfg")
	var loaded:=GameSettings.new()
	test.expect(loaded.load_settings("user://legacy_settings.cfg") and loaded.mode=="fullscreen" and loaded.window_size==Vector2i(1280,720) and loaded.volumes.Master==27,"legacy fullscreen/index/audio config migrates")
	test.expect(FileAccess.get_file_as_string("user://legacy_settings.cfg")==before,"loading does not partially overwrite configuration")
	config.set_value("video","mode","invalid")
	config.set_value("video","window_width",-1)
	config.set_value("video","window_height",99999)
	config.set_value("audio","sfx_volume","broken")
	config.save("user://invalid_settings.cfg")
	loaded=GameSettings.new()
	test.expect(loaded.load_settings("user://invalid_settings.cfg") and loaded.mode=="windowed" and loaded.window_size==Vector2i(1280,720) and loaded.volumes.SFX==80,"invalid saved values fall back safely")
	var fitted:=loaded.fit_window_size(Vector2i(7680,4320))
	var limit:=loaded.maximum_window_size()
	test.expect(fitted.x<=limit.x and fitted.y<=limit.y,"oversized saved resolution fits current monitor")

func _check_movement() -> void:
	var p:Player=game.player
	p.set_process(false)
	game.enter_house(World.HOUSE_DATA[0])
	var origin:=HouseInterior.ORIGIN+Vector2(0,65)
	p.position=origin
	p._last_position=origin
	p.animation.restore_dead(false)
	game._update_camera(0)
	game.camera.reset_smoothing()
	await settle()
	# Keep the cursor to the right for every direction, reproducing the original bug.
	game.get_viewport().warp_mouse(p.get_global_transform_with_canvas()*Vector2(160,0))
	await settle()
	var directions := [[KEY_W,Vector2.UP,2],[KEY_S,Vector2.DOWN,0],[KEY_A,Vector2.LEFT,1],[KEY_D,Vector2.RIGHT,3],[KEY_UP,Vector2.UP,2],[KEY_DOWN,Vector2.DOWN,0],[KEY_LEFT,Vector2.LEFT,1],[KEY_RIGHT,Vector2.RIGHT,3]]
	for item in directions:
		p.position=origin
		p._last_position=origin
		key_state(item[0],true)
		game._update_player(0.1)
		p._process(0.1)
		key_state(item[0],false)
		var delta:Vector2=p.position-origin
		test.expect(delta.normalized().dot(item[1])>0.99 and absf(delta.length()-p.speed*0.1)<0.05,"directional key moves correctly "+str(item[0]))
		test.expect(p.animation.facing_row()==item[2] and p.walking,"walking sprite faces movement independently of mouse "+str(item[0]))
		p.queue_redraw()
		if item[0] in [KEY_W,KEY_S,KEY_A,KEY_D]: await shot("walk_"+str(item[2]))
		var facing:=p.dir
		game._update_player(0.1)
		p._process(0.1)
		test.expect(not p.walking and p.animation.frame()==0 and p.dir==facing,"release stops gait and retains facing "+str(item[0]))
	p.position=origin
	p._last_position=origin
	key_state(KEY_W,true)
	key_state(KEY_D,true)
	game._update_player(0.1)
	p._process(0.1)
	key_state(KEY_W,false)
	key_state(KEY_D,false)
	test.expect(absf(p.position.distance_to(origin)-p.speed*0.1)<0.05,"diagonal speed equals cardinal speed")
	p.position=origin
	p._last_position=origin
	key_state(KEY_A,true)
	key_state(KEY_D,true)
	game._update_player(0.1)
	p._process(0.1)
	key_state(KEY_A,false)
	key_state(KEY_D,false)
	test.expect(p.position==origin and not p.walking,"opposing keys cancel without walking in place")
	p.atk_cd=0
	p.dir=PI
	# Reassert the cursor in this viewport; another test window may have moved the OS cursor.
	var aim:=InputEventMouseMotion.new()
	aim.position=p.get_global_transform_with_canvas()*Vector2(160,0)
	game.get_viewport().push_input(aim,true)
	game.basic_attack()
	test.expect(p.animation.action=="strike" and Vector2.from_angle(p.animation.direction).x>0.9,"attack still aims at cursor while previously facing left")
	p.animation.restore_dead(false)
	# A large frame step must not skip the complete room wall into outdoor space.
	game.world.move_body(p,1200,0,p.radius)
	test.expect(p.position.x<HouseInterior.ORIGIN.x+400 and not game.world.collides(p.position.x,p.position.y,p.radius),"large movement step cannot tunnel through room wall")
	key_state(KEY_D,true)
	game._update_player(0.2)
	p._last_position=p.position
	game._update_player(0.2)
	p._process(0.2)
	key_state(KEY_D,false)
	test.expect(not p.walking and p.animation.frame()==0,"blocked movement stops stride")
	var slow:=ActorAnimation.new()
	var fast:=ActorAnimation.new()
	for i in 10: slow.advance(0.1,true,0,3.2)
	for i in 40: fast.advance(0.025,true,0,0.8)
	test.expect(is_equal_approx(slow.walk_distance,fast.walk_distance) and slow.frame()==fast.frame(),"stride phase depends on distance instead of frame rate")
	var before:Vector2=p.position
	game.paused=true
	key_state(KEY_A,true)
	game._process(0.1)
	key_state(KEY_A,false)
	test.expect(p.position==before,"paused main loop blocks directional movement")
