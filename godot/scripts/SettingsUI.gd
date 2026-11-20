class_name SettingsUI
extends Control

var game: Node
var preferences := GameSettings.new()
var panel: PanelContainer
var mode_option: OptionButton
var resolution_option: OptionButton
var resolution_hint: Label
var status: Label
var close_button: Button
var master_slider: HSlider
var music_slider: HSlider
var sfx_slider: HSlider
var resolutions: Array[Vector2i] = []
var _was_paused := false
var _resize_timer: Timer
var _volume_labels := {}

func _ready() -> void:
	UIStyle.fill(self)
	_build_ui()
	_resize_timer=Timer.new()
	_resize_timer.one_shot=true
	_resize_timer.wait_time=0.35
	_resize_timer.timeout.connect(_remember_window_size)
	add_child(_resize_timer)
	get_viewport().size_changed.connect(_layout)
	get_window().size_changed.connect(_on_window_resized)
	get_window().min_size=GameSettings.MIN_SIZE
	preferences.window_size=get_window().size
	var has_settings:=preferences.load_settings()
	preferences.apply_audio()
	_sync_audio()
	_layout()
	_sync_video()
	if has_settings: await _apply_video(false)

func _build_ui() -> void:
	var shade:=ColorRect.new()
	shade.color=Color(0.02,0.05,0.04,0.85)
	UIStyle.fill(shade)
	add_child(shade)
	panel=PanelContainer.new()
	panel.add_theme_stylebox_override("panel",UIStyle.box(UIStyle.BG,UIStyle.GOLD,12))
	add_child(panel)
	var margin:=MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,20)
	panel.add_child(margin)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	margin.add_child(column)
	column.add_child(UIStyle.label("设置",28,UIStyle.GOLD))
	var scroll:=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical=SIZE_EXPAND_FILL
	column.add_child(scroll)
	var body:=VBoxContainer.new()
	body.size_flags_horizontal=SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12)
	scroll.add_child(body)
	body.add_child(UIStyle.label("画面与窗口",18,UIStyle.JADE))
	mode_option=_option_row(body,"显示模式")
	for title in GameSettings.MODE_NAMES: mode_option.add_item(title)
	mode_option.item_selected.connect(_on_mode_selected)
	resolution_option=_option_row(body,"窗口分辨率")
	resolution_option.item_selected.connect(_on_resolution_selected)
	resolution_hint=UIStyle.label("",13,UIStyle.DIM)
	resolution_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_child(resolution_hint)
	body.add_child(UIStyle.label("音量",18,UIStyle.JADE))
	master_slider=_volume_row(body,"总音量","Master")
	music_slider=_volume_row(body,"音乐","Music")
	sfx_slider=_volume_row(body,"音效","SFX")
	var help:=UIStyle.label("WASD / 方向键  行走　　鼠标  瞄准　　空格  疾步\nF11  全屏 / 返回原窗口　　F2  画质　　F3  垂直同步　　F4  帧率限制",13,UIStyle.DIM)
	help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_child(help)
	status=UIStyle.label("设置立即应用并自动保存。",13,UIStyle.DIM)
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	close_button=UIStyle.button("返回  ·  Esc / O",close)
	close_button.custom_minimum_size.y=42
	column.add_child(close_button)

func _option_row(parent: VBoxContainer, title: String) -> OptionButton:
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	parent.add_child(row)
	var label:=UIStyle.label(title,16)
	label.custom_minimum_size.x=120
	row.add_child(label)
	var option:=OptionButton.new()
	option.size_flags_horizontal=SIZE_EXPAND_FILL
	option.custom_minimum_size.y=38
	option.add_theme_font_size_override("font_size",16)
	row.add_child(option)
	return option

func _volume_row(parent: VBoxContainer, title: String, bus: String) -> HSlider:
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	parent.add_child(row)
	var label:=UIStyle.label(title,16)
	label.custom_minimum_size.x=120
	row.add_child(label)
	var slider:=HSlider.new()
	slider.min_value=0
	slider.max_value=100
	slider.step=1
	slider.size_flags_horizontal=SIZE_EXPAND_FILL
	slider.custom_minimum_size.y=32
	row.add_child(slider)
	var value:=UIStyle.label("",14,UIStyle.DIM)
	value.custom_minimum_size.x=48
	value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	_volume_labels[bus]=value
	slider.value_changed.connect(func(amount: float):
		preferences.volumes[bus]=amount
		value.text="%d%%"%amount
		preferences.apply_audio()
		_save()
	)
	return slider

func _layout() -> void:
	var extent:=get_viewport_rect().size
	panel.size=Vector2(minf(720,extent.x-32),minf(610,extent.y-32))
	panel.position=(extent-panel.size)*0.5

func open() -> void:
	if visible: return
	_was_paused=game.paused
	game.paused=true
	game._world_attack_held=false
	_sync_video()
	show()
	close_button.grab_focus()

func close() -> void:
	if not visible: return
	hide()
	game.paused=_was_paused
	game._world_attack_held=false
	close_button.release_focus()

func _sync_audio() -> void:
	for pair in [[master_slider,"Master"],[music_slider,"Music"],[sfx_slider,"SFX"]]:
		pair[0].set_value_no_signal(preferences.volumes[pair[1]])
		_volume_labels[pair[1]].text="%d%%"%preferences.volumes[pair[1]]

func _sync_video() -> void:
	mode_option.select(GameSettings.MODES.find(preferences.mode))
	mode_option.disabled=preferences.applying
	resolution_option.clear()
	resolutions.clear()
	var fullscreen:=preferences.mode=="fullscreen"
	if fullscreen:
		resolutions.append(DisplayServer.screen_get_size(DisplayServer.window_get_current_screen()))
	else:
		var limit:=preferences.maximum_window_size()
		for candidate in GameSettings.RESOLUTIONS:
			if candidate.x<=limit.x and candidate.y<=limit.y: resolutions.append(candidate)
		if not preferences.window_size in resolutions: resolutions.append(preferences.window_size)
	for extent in resolutions: resolution_option.add_item("%d × %d"%[extent.x,extent.y])
	resolution_option.select(0 if fullscreen else resolutions.find(preferences.window_size))
	resolution_option.disabled=fullscreen or preferences.applying
	resolution_hint.text="全屏使用显示器原生分辨率；退出后恢复先前的窗口尺寸。" if fullscreen else "立即应用并保存，仅列出当前屏幕可容纳的尺寸。无边框窗口隐藏标题栏。"

func _on_mode_selected(index: int) -> void:
	if preferences.applying or index<0 or index>=GameSettings.MODES.size(): return
	preferences.mode=GameSettings.MODES[index]
	await _apply_video()

func _on_resolution_selected(index: int) -> void:
	if preferences.applying or preferences.mode=="fullscreen" or index<0 or index>=resolutions.size(): return
	preferences.window_size=resolutions[index]
	await _apply_video()

func toggle_fullscreen() -> void:
	if preferences.applying: return
	preferences.mode=preferences.last_window_mode if preferences.mode=="fullscreen" else "fullscreen"
	await _apply_video()

func _apply_video(persist: bool = true) -> void:
	_resize_timer.stop()
	mode_option.disabled=true
	resolution_option.disabled=true
	await preferences.apply_video(get_window())
	_sync_video()
	_layout()
	if persist: _save()

func _on_window_resized() -> void:
	if not preferences.applying and preferences.mode!="fullscreen" and get_window().mode==Window.MODE_WINDOWED:
		_resize_timer.start()

func _remember_window_size() -> void:
	if preferences.applying or preferences.mode=="fullscreen" or get_window().mode!=Window.MODE_WINDOWED: return
	preferences.window_size=get_window().size
	_sync_video()
	_save()

func _save() -> void:
	var error:=preferences.save_settings()
	status.text="设置已保存。" if error==OK else "本次设置已应用，但保存失败（%s）。"%error_string(error)
