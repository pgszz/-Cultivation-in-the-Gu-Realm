class_name GameManager
extends Node

## 游戏管理器 - 整合所有系统

var hunger_system: HungerSystem
var plant_system: PlantSystem
var animal_system: AnimalSystem
var monster_system: MonsterSystem
var food_system: FoodSystem
var inventory: Inventory

signal game_ready

func _ready():
	initialize_systems()
	game_ready.emit()

func initialize_systems():
	# 系统由 project.godot 里的 Autoload 创建，这里只取引用。
	hunger_system = get_node_or_null("/root/Hunger")
	plant_system = get_node_or_null("/root/Plants")
	animal_system = get_node_or_null("/root/Animals")
	monster_system = get_node_or_null("/root/Monsters")
	food_system = get_node_or_null("/root/Food")
	inventory = get_node_or_null("/root/Inv")

	print("所有系统初始化完成")

func save_game(save_path: String) -> bool:
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"hunger": hunger_system.save_data() if hunger_system else {},
		"inventory": inventory.save_data() if inventory else {},
	}

	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		return false

	file.store_var(save_data)
	file.close()
	return true

func load_game(save_path: String) -> bool:
	if not FileAccess.file_exists(save_path):
		return false

	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return false

	var save_data = file.get_var()
	file.close()

	if hunger_system and save_data.has("hunger"):
		hunger_system.load_data(save_data.hunger)

	if inventory and save_data.has("inventory"):
		inventory.load_data(save_data.inventory)

	return true
