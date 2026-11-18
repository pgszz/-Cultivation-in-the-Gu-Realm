class_name ElementSystem
extends Node

## 元素反应系统 - 七元素版本
## 七元素：金 metal、木 wood、水 water、火 fire、土 earth、雷 thunder、风 wind
## 21条反应规则

signal element_reaction(reaction_name: String, position: Vector2, power: float)

# 元素力量等级
enum EPLevel { WEAK, EQUAL, STRONG }

# 元素反应表（七元素 21 条，对应《元素碰撞反应.md》4.1）
const REACTIONS := {
	"metal_wood": {"name": "断生", "result": "strip_heal", "power": 1.5},
	"metal_water": {"name": "锈蚀", "result": "rust", "power": 1.5},
	"metal_fire": {"name": "熔金", "result": "melt", "power": 1.5},
	"metal_earth": {"name": "藏锋", "result": "shield", "power": 1.4},
	"metal_thunder": {"name": "导电", "result": "conduct", "power": 1.6},
	"metal_wind": {"name": "风刃", "result": "slash", "power": 1.5},
	"wood_water": {"name": "腐水", "result": "rot", "power": 1.4},
	"wood_fire": {"name": "燃瘴", "result": "blight", "power": 1.5},
	"wood_earth": {"name": "腐土", "result": "corrode", "power": 1.4},
	"wood_thunder": {"name": "雷殛", "result": "scorch", "power": 1.5},
	"wood_wind": {"name": "瘴气", "result": "miasma", "power": 1.4},
	"water_fire": {"name": "蒸汽", "result": "steam", "power": 1.5},
	"water_earth": {"name": "泥泞", "result": "mire", "power": 1.4},
	"water_thunder": {"name": "感电", "result": "shock", "power": 1.8},
	"water_wind": {"name": "冰霜", "result": "freeze", "power": 1.5},
	"fire_earth": {"name": "熔岩", "result": "magma", "power": 1.5},
	"fire_thunder": {"name": "爆燃", "result": "blast", "power": 1.7},
	"fire_wind": {"name": "蔓延", "result": "spread", "power": 1.5},
	"earth_thunder": {"name": "崩裂", "result": "fracture", "power": 1.6},
	"earth_wind": {"name": "沙暴", "result": "sandstorm", "power": 1.5},
	"thunder_wind": {"name": "风暴", "result": "storm", "power": 1.7},
}

func calculate_ep_result(ep1: float, ep2: float) -> EPLevel:
	var ratio = ep1 / ep2 if ep2 > 0 else 999.0

	if ratio >= 2.0:
		return EPLevel.STRONG
	elif ratio <= 0.5:
		return EPLevel.WEAK
	else:
		return EPLevel.EQUAL

func get_reaction(elem1: String, elem2: String) -> Dictionary:
	var key1 = "%s_%s" % [elem1, elem2]
	var key2 = "%s_%s" % [elem2, elem1]

	if REACTIONS.has(key1):
		return REACTIONS[key1]
	elif REACTIONS.has(key2):
		return REACTIONS[key2]

	return {}

func apply_reaction(elem1: String, ep1: float, elem2: String, ep2: float, pos: Vector2) -> Dictionary:
	var reaction = get_reaction(elem1, elem2)
	if reaction.is_empty():
		return {"result": "none", "power": 0.0}

	var ep_level = calculate_ep_result(ep1, ep2)
	var final_power = reaction.power

	match ep_level:
		EPLevel.STRONG:
			final_power *= 1.5
		EPLevel.WEAK:
			final_power *= 0.5
		EPLevel.EQUAL:
			final_power *= 1.0

	element_reaction.emit(reaction.name, pos, final_power)

	return {
		"name": reaction.name,
		"result": reaction.result,
		"power": final_power,
		"ep_level": ep_level
	}

# 元素对地形的影响
func apply_terrain_reaction(element: String, terrain_type: int, pos: Vector2i) -> String:
	match element:
		"fire":
			if terrain_type == GameData.T_GRASS:
				return "burn_grass"
			elif terrain_type == GameData.T_TREE:
				return "burn_tree"
		"water":
			if terrain_type == GameData.T_DIRT:
				return "mud"
		"thunder":
			if terrain_type == GameData.T_WATER:
				return "electrify_water"

	return "none"
