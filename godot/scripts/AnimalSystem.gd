class_name AnimalSystem
extends Node2D

## 动物系统 - 狩猎与驯养
## 对应文档：动物系统设计.md

signal animal_killed(animal_id: String, drops: Array)
signal animal_tamed(animal_id: String)

const ANIMALS := {
	# 普通动物
	"rabbit": {"name": "野兔", "type": "herbivore", "hp": 20, "atk": 5, "meat_restore": 15, "drops": ["rabbit_meat", "rabbit_skin"]},
	"deer": {"name": "野鹿", "type": "herbivore", "hp": 40, "atk": 10, "meat_restore": 25, "drops": ["deer_meat", "deer_horn"]},
	"wolf": {"name": "野狼", "type": "carnivore", "hp": 60, "atk": 30, "meat_restore": 35, "drops": ["wolf_meat", "wolf_fang"], "tameable": true},
	"bear": {"name": "黑熊", "type": "carnivore", "hp": 150, "atk": 50, "meat_restore": 60, "drops": ["bear_meat", "bear_gall"]},

	# 野兽
	"iron_bear": {"name": "铁背熊", "type": "beast", "rank": 1, "hp": 300, "atk": 100, "meat_restore": 50, "dao_bonus": {"力": 20}, "drops": ["bear_meat", "iron_back"]},
	"golden_rhino": {"name": "金角犀", "type": "beast", "rank": 2, "hp": 500, "atk": 200, "meat_restore": 70, "dao_bonus": {"力": 30}, "drops": ["rhino_meat", "golden_horn"]},

	# 凶兽
	"flame_lion": {"name": "赤炎狮", "type": "fierce", "rank": 4, "hp": 2000, "atk": 500, "meat_restore": 150, "dao_bonus": {"变": 80}, "drops": ["lion_meat", "flame_heart"]},
}

const MEAT_TYPES := {
	"rabbit_meat": {"name": "兔肉", "restore": 15, "type": "herbivore"},
	"deer_meat": {"name": "鹿肉", "restore": 25, "type": "herbivore"},
	"wolf_meat": {"name": "狼肉", "restore": 35, "type": "carnivore"},
	"bear_meat": {"name": "熊肉", "restore": 60, "type": "carnivore"},
	"lion_meat": {"name": "狮肉", "restore": 150, "type": "fierce"},
}

class AnimalInstance:
	var animal_id: String
	var position: Vector2
	var hp: float
	var max_hp: float
	var is_alive: bool = true

func spawn_animal(animal_id: String, pos: Vector2) -> AnimalInstance:
	var data = ANIMALS[animal_id]
	var instance = AnimalInstance.new()
	instance.animal_id = animal_id
	instance.position = pos
	instance.max_hp = data.hp
	instance.hp = data.hp
	return instance

func damage_animal(instance: AnimalInstance, damage: float):
	instance.hp -= damage
	if instance.hp <= 0:
		kill_animal(instance)

func kill_animal(instance: AnimalInstance):
	instance.is_alive = false
	var data = ANIMALS[instance.animal_id]
	var drops = []

	for drop_id in data.drops:
		drops.append(drop_id)

	animal_killed.emit(instance.animal_id, drops)

func tame_animal(instance: AnimalInstance) -> bool:
	var data = ANIMALS[instance.animal_id]
	if not data.get("tameable", false):
		return false

	if instance.hp > instance.max_hp * 0.2:
		return false  # 血量必须<20%

	var success_rate = 0.8  # 80%成功率
	if randf() < success_rate:
		animal_tamed.emit(instance.animal_id)
		return true

	return false

func get_meat_restore(meat_id: String, gu_type: String = "") -> float:
	var meat = MEAT_TYPES.get(meat_id)
	if not meat:
		return 0.0

	var restore = float(meat.restore)

	# 类型加成
	if meat.type == "carnivore" and gu_type == "力":
		restore += 20.0

	return restore
