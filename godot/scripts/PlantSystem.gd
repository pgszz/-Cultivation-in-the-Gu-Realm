class_name PlantSystem
extends Node2D

## 植物系统 - 采集与种植
## 对应文档：植物系统设计.md

signal plant_collected(plant_id: String, amount: int)
signal plant_harvested(plant_id: String, amount: int)

# 植物数据库
const PLANTS := {
	# 普通植物
	"grass": {"name": "青草", "type": "common", "restore": 5, "respawn_time": 300},
	"wild_fruit": {"name": "野果", "type": "common", "restore": 10, "respawn_time": 300},
	"mushroom": {"name": "蘑菇", "type": "common", "restore": 10, "respawn_time": 600},

	# 灵草
	"blood_vine": {"name": "血藤", "type": "spirit", "restore": 30, "dao_bonus": {"力": 20}, "respawn_time": 3600},
	"transform_leaf": {"name": "变形叶", "type": "spirit", "restore": 30, "dao_bonus": {"变": 20}, "respawn_time": 3600},
	"soul_grass": {"name": "魂草", "type": "spirit", "restore": 30, "dao_bonus": {"魂": 20}, "respawn_time": 3600},

	# 仙药
	"thousand_ginseng": {"name": "千年人参", "type": "immortal", "restore": 100, "dao_bonus": {}, "respawn_time": 86400},
	"phoenix_flower": {"name": "凤凰花", "type": "immortal", "restore": 100, "dao_bonus": {"变": 80}, "respawn_time": 86400},
}

class PlantNode:
	var plant_id: String
	var position: Vector2
	var next_respawn_time: int = 0
	var is_available: bool = true

var plant_nodes := []  # Array[PlantNode]

func spawn_plant(plant_id: String, pos: Vector2):
	var node = PlantNode.new()
	node.plant_id = plant_id
	node.position = pos
	node.is_available = true
	plant_nodes.append(node)

func collect_plant(node: PlantNode) -> bool:
	if not node.is_available:
		return false

	var plant = PLANTS[node.plant_id]
	var amount = randi() % 3 + 1  # 1-3个

	plant_collected.emit(node.plant_id, amount)

	# 设置重生时间
	node.is_available = false
	node.next_respawn_time = Time.get_unix_time_from_system() + plant.respawn_time

	return true

func _process(_delta):
	var current_time = Time.get_unix_time_from_system()
	for node in plant_nodes:
		if not node.is_available and current_time >= node.next_respawn_time:
			node.is_available = true

func get_plant_restore(plant_id: String, gu_dao: String = "") -> float:
	var plant = PLANTS.get(plant_id)
	if not plant:
		return 0.0

	var restore = float(plant.restore)

	# 道属加成
	if plant.has("dao_bonus") and plant.dao_bonus.has(gu_dao):
		restore += plant.dao_bonus[gu_dao]

	return restore
