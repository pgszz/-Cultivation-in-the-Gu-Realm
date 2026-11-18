class_name GuVirtual
extends RefCounted

## 蛊虫实例 - 扩展原GameData，整合饥饿度系统

static var next_id := 0
var location := "aperture" # aperture / body / bag
var dead := false
var id: String
var template_id: String
var name: String
var rank: int
var dao: String
var element: String

# 战斗属性
var hp: float
var max_hp: float
var atk: float
var spd: float
var level: int = 1
var exp: float = 0.0

# 饥饿度相关
var hunger: float = 100.0
var last_fed_time: int = 0
var preferred_food: String = ""

# 品质
var quality: String = "normal"  # normal, elite, boss

func _init(tid: String, quality_: String = "normal"):
	template_id = tid
	quality = quality_
	next_id += 1
	id = "%s_%d_%d" % [tid, Time.get_unix_time_from_system(), next_id]

	var data = GameData.GU[tid]
	name = data.name
	rank = data.rank
	dao = data.dao
	element = data.element

	# 基础属性
	max_hp = data.hp
	hp = max_hp
	atk = data.atk
	spd = data.spd

	# 道属直接用中文九道，和食物表/图鉴保持一致
	preferred_food = String(data.get("preferred_food",""))

func _root_node(name: String) -> Node:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null(name)
	return null


func get_effective_atk() -> float:
	var hunger_system = _root_node("Hunger")
	if not hunger_system:
		return atk

	var penalty = hunger_system.get_hunger_penalty(id)
	return atk * penalty


func get_effective_spd() -> float:
	var hunger_system = _root_node("Hunger")
	if not hunger_system:
		return spd

	var penalty = hunger_system.get_hunger_penalty(id)
	return spd * penalty


func feed(food_id: String) -> bool:
	var food_system = _root_node("Food")
	if not food_system:
		return false

	return food_system.feed_gu(id, food_id, preferred_food)

func gain_exp(_amount: float):
	pass # 蛊虫不通过战斗经验升转；需要对应蛊方合炼。

func to_dict() -> Dictionary:
	return {
		"id": id,
		"location": location,
		"dead": dead,
		"template_id": template_id,
		"quality": quality,
		"level": level,
		"exp": exp,
		"hunger": hunger,
		"last_fed_time": last_fed_time,
		"preferred_food": preferred_food,
	}

static func from_dict(data: Dictionary) -> GuVirtual:
	var gu = GuVirtual.new(data.template_id, data.get("quality", "normal"))
	gu.id = data.id
	gu.location = String(data.get("location","aperture"))
	if gu.location not in ["aperture","body","bag"]: gu.location="aperture"
	gu.dead = bool(data.get("dead",false))
	gu.level = data.get("level", 1)
	gu.exp = data.get("exp", 0.0)
	gu.hunger = data.get("hunger", 100.0)
	gu.last_fed_time = data.get("last_fed_time", 0)
	gu.preferred_food = data.get("preferred_food", "")
	return gu
