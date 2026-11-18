class_name Inventory
extends Node

## 背包系统 - 管理食物、材料、道具
## 整合所有食物类型

signal item_added(item_id: String, amount: int)
signal item_removed(item_id: String, amount: int)
signal item_used(item_id: String)

const MAX_STACK := 99
const SELL_PRICES := {"timber":1,"rubble":1,"rabbit_meat":1,"rabbit_skin":1,"deer_meat":2,"deer_horn":2,"wolf_meat":2,"wolf_fang":2,"bear_meat":3,"bear_gall":4}

const ITEM_INFO := {
	"bandage": {"name":"绷带","desc":"包扎身体页选中的伤口，止血并恢复少量耐久。不能修复毁损部位。"},
	"timber": {"name":"木料","desc":"从树木、青矛竹或木制物体取得的材料，存放在行囊中。"},
	"rubble": {"name":"碎石","desc":"破坏岩石与墙体后留下的石料，存放在行囊中。"},
	"rabbit_meat": {"name":"兔肉","desc":"狩猎所得。不是当前三种蛊虫的食物；烹饪尚未开放。"},
	"deer_meat": {"name":"鹿肉","desc":"狩猎所得。不是当前三种蛊虫的食物；烹饪尚未开放。"},
	"wolf_meat": {"name":"狼肉","desc":"狩猎所得。不是当前三种蛊虫的食物；烹饪尚未开放。"},
	"bear_meat": {"name":"熊肉","desc":"狩猎所得。不是当前三种蛊虫的食物；烹饪尚未开放。"},
	"rabbit_skin": {"name":"兔皮","desc":"狩猎所得的兽皮。"},
	"deer_horn": {"name":"鹿角","desc":"狩猎所得的鹿角。"},
	"wolf_fang": {"name":"狼牙","desc":"狩猎所得的兽牙。"},
	"bear_gall": {"name":"熊胆","desc":"狩猎所得；目前不能直接用于治疗。"},
}


var items := {}  # item_id -> amount

func add_item(item_id: String, amount: int = 1) -> bool:
	if items.has(item_id):
		items[item_id] = min(items[item_id] + amount, MAX_STACK * 10)
	else:
		items[item_id] = amount

	item_added.emit(item_id, amount)
	return true

func remove_item(item_id: String, amount: int = 1) -> bool:
	if not has_item(item_id, amount):
		return false

	items[item_id] -= amount
	if items[item_id] <= 0:
		items.erase(item_id)

	item_removed.emit(item_id, amount)
	return true

func has_item(item_id: String, amount: int = 1) -> bool:
	return items.get(item_id, 0) >= amount

func get_item_count(item_id: String) -> int:
	return items.get(item_id, 0)

func get_all_food_items() -> Array:
	var food_items = []

	for item_id in items:
		if is_food(item_id):
			food_items.append({
				"id": item_id,
				"amount": items[item_id]
			})

	return food_items

func is_food(item_id: String) -> bool:
	return FoodSystem.GRAINS.has(item_id)

func use_item(item_id: String, target: String = "") -> bool:
	if not has_item(item_id):
		return false

	if is_food(item_id) and target != "":
		# 喂食蛊虫
		var food_system = get_node_or_null("/root/Food")
		if food_system and food_system.feed_gu(target, item_id):
			remove_item(item_id, 1)
			item_used.emit(item_id)
			return true

	return false

func save_data() -> Dictionary:
	return {"items": items}

func load_data(save_dict: Dictionary):
	items = save_dict.get("items", {})


func is_material(item_id: String) -> bool:
	return ITEM_INFO.has(item_id)


func get_item_name(item_id: String) -> String:
	if ITEM_INFO.has(item_id):
		return String(ITEM_INFO[item_id]["name"])
	var food := get_node_or_null("/root/Food")
	if food != null and is_food(item_id):
		return String(food.get_food_name(item_id))
	if GameData.GU.has(item_id):
		return String(GameData.GU[item_id]["name"])
	return item_id


func get_item_desc(item_id: String) -> String:
	if ITEM_INFO.has(item_id):
		return String(ITEM_INFO[item_id]["desc"])
	if is_food(item_id):
		return "蛊虫食物"
	if GameData.GU.has(item_id):
		return "蛊虫"
	return ""
