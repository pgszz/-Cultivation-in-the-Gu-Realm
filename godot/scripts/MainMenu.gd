class_name MainMenu
extends Control

## 主菜单 - 游戏启动界面

@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var load_game_button: Button = $VBoxContainer/LoadGameButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

const SAVE_PATH = "user://save.json"
const GAME_SCENE_PATH = "res://main.tscn"

func _ready():
	# 检查是否有存档
	var has_save = FileAccess.file_exists(SAVE_PATH)
	continue_button.disabled = not has_save

	# 连接按钮信号
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_continue_pressed():
	# 加载最近的存档并开始游戏
	_load_game_and_start()

func _on_new_game_pressed():
	# 开始新游戏
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_load_game_pressed():
	# 显示存档列表（当前简化为直接加载）
	_load_game_and_start()

func _on_settings_pressed():
	# TODO: 打开设置面板
	print("设置功能待实现")

func _on_quit_pressed():
	# 退出游戏
	get_tree().quit()

func _load_game_and_start():
	# 切换到游戏场景
	get_tree().change_scene_to_file(GAME_SCENE_PATH)
	# 加载存档由 GameManager 在场景加载后处理
	await get_tree().process_frame
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("load_game"):
		game_manager.load_game(SAVE_PATH)
