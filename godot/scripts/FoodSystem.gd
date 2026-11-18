class_name FoodSystem
extends Node

signal food_used(food_id: String, gu_id: String, restore_amount: float)
const GRAINS := {
	"moon_petals":{"name":"月兰花瓣","restore":25.0,"type":"food"},
	"bamboo_wine":{"name":"青竹酒（一坛）","restore":100.0,"type":"food"},
	"jade":{"name":"玉石（二两）","restore":100.0,"type":"food"},
}
var hunger_system: HungerSystem

func _ready() -> void:
	hunger_system=get_node_or_null("/root/Hunger")

func feed_gu(gu_id: String, food_id: String, _dao: String = "") -> bool:
	var gus := get_node_or_null("/root/Gus")
	var gu: GuVirtual = gus.get_gu_by_id(gu_id) if gus else null
	if gu==null or gu.dead or gu.preferred_food!=food_id or not GRAINS.has(food_id): return false
	var restore := float(GRAINS[food_id].restore)
	if not hunger_system.feed_gu(gu_id,restore): return false
	food_used.emit(food_id,gu_id,restore)
	return true

func calculate_restore(food_id: String, _dao: String = "") -> float:
	return float(GRAINS.get(food_id,{}).get("restore",0))

func get_food_name(food_id: String) -> String:
	return String(GRAINS.get(food_id,{}).get("name",food_id))

func get_food_dao(_food_id: String) -> String:
	return ""

func get_food_type(_food_id: String) -> String:
	return "food"

func get_food_description(food_id: String, _dao: String = "") -> String:
	return get_food_name(food_id)+"。只可喂给以此为食的蛊虫；不匹配不会消耗物品。"
