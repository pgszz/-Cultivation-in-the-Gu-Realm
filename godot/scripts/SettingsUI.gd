class_name SettingsUI
extends Control

## 设置界面 - 音量、分辨率、全屏、键位

@onready var master_slider: HSlider = $Panel/VBox/MasterVolume/Slider
@onready var music_slider: HSlider = $Panel/VBox/MusicVolume/Slider
@onready var sfx_slider: HSlider = $Panel/VBox/SfxVolume/Slider
@onready var resolution_option: OptionButton = $Panel/VBox/Resolution/Option
@onready var fullscreen_check: CheckButton = $Panel/VBox/Fullscreen/Check
@onready var keybind_button: Button = $Panel/VBox/Keybindings/Button
@onready var close_button: Button = $Panel/CloseButton

const SETTINGS_PATH := "user://settings.cfg"
const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

func _ready():
	_setup_ui()
	_connect_signals()
	load_settings()

func _setup_ui():
	# 分辨率选项
	resolution_option.clear()
	for res in RESOLUTIONS:
		resolution_option.add_item("%d × %d" % [res.x, res.y])

	# 音量滑块范围
	master_slider.min_value = 0.0
	master_slider.max_value = 100.0
	master_slider.step = 1.0
	music_slider.min_value = 0.0
	music_slider.max_value = 100.0
	music_slider.step = 1.0
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 100.0
	sfx_slider.step = 1.0

func _connect_signals():
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	resolution_option.item_selected.connect(_on_resolution_selected)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	keybind_button.pressed.connect(_on_keybindings_pressed)
	close_button.pressed.connect(_on_close_pressed)

func _on_master_volume_changed(value: float):
	var db := linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	save_settings()

func _on_music_volume_changed(value: float):
	var bus_idx := AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		var db := linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(bus_idx, db)
	save_settings()

func _on_sfx_volume_changed(value: float):
	var bus_idx := AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		var db := linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(bus_idx, db)
	save_settings()

func _on_resolution_selected(index: int):
	if index >= 0 and index < RESOLUTIONS.size():
		var res: Vector2i = RESOLUTIONS[index]
		DisplayServer.window_set_size(res)
		save_settings()

func _on_fullscreen_toggled(toggled_on: bool):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()

func _on_keybindings_pressed():
	# TODO: 打开键位绑定子界面
	print("键位绑定功能待实现")

func _on_close_pressed():
	hide()

func save_settings():
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_slider.value)
	config.set_value("audio", "music_volume", music_slider.value)
	config.set_value("audio", "sfx_volume", sfx_slider.value)
	config.set_value("video", "resolution_index", resolution_option.selected)
	config.set_value("video", "fullscreen", fullscreen_check.button_pressed)
	config.save(SETTINGS_PATH)

func load_settings():
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		# 使用默认值
		master_slider.value = 80.0
		music_slider.value = 70.0
		sfx_slider.value = 80.0
		resolution_option.selected = 1  # 1920×1080
		fullscreen_check.button_pressed = false
		return

	master_slider.value = config.get_value("audio", "master_volume", 80.0)
	music_slider.value = config.get_value("audio", "music_volume", 70.0)
	sfx_slider.value = config.get_value("audio", "sfx_volume", 80.0)
	resolution_option.selected = config.get_value("video", "resolution_index", 1)
	fullscreen_check.button_pressed = config.get_value("video", "fullscreen", false)

	# 应用设置
	_on_master_volume_changed(master_slider.value)
	_on_music_volume_changed(music_slider.value)
	_on_sfx_volume_changed(sfx_slider.value)
