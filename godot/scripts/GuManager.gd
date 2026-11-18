class_name GuManager
extends Node

## 玩家蛊虫管理 - 管理玩家拥有的所有蛊虫

signal gu_added(gu: GuVirtual)
signal gu_removed(gu_id: String)
signal active_gu_changed(gu: GuVirtual)

var owned_gus: Array[GuVirtual] = []
var active_gu: GuVirtual = null
var max_gu_slots: int = 1000000 # 管理容器，不是空窍槽位上限

func _ready():
	var hunger_system = get_node_or_null("/root/Hunger")
	if hunger_system:
		hunger_system.gu_dormant.connect(_on_gu_dormant)

func add_gu(template_id: String, quality: String = "normal") -> GuVirtual:
	if not GameData.GU.has(template_id):
		push_warning("未校对的蛊虫未开放")
		return null

	var gu = GuVirtual.new(template_id, quality)
	owned_gus.append(gu)

	# 注册到饥饿度系统
	var hunger_system = get_node_or_null("/root/Hunger")
	if hunger_system:
		var rank = GameData.GU[template_id].rank
		hunger_system.register_gu(gu.id, rank, quality, gu.preferred_food)

	gu_added.emit(gu)

	# 如果没有激活蛊虫，自动激活
	if active_gu == null:
		set_active_gu(gu)

	return gu

func remove_gu(gu_id: String) -> bool:
	for i in owned_gus.size():
		if owned_gus[i].id == gu_id:
			var gu = owned_gus[i]
			owned_gus.remove_at(i)

			# 从饥饿度系统注销
			var hunger_system = get_node_or_null("/root/Hunger")
			if hunger_system:
				hunger_system.unregister_gu(gu_id)

			if active_gu and active_gu.id == gu_id:
				active_gu = null
				if owned_gus.size() > 0:
					set_active_gu(owned_gus[0])

			gu_removed.emit(gu_id)
			return true

	return false

func set_active_gu(gu: GuVirtual):
	active_gu = gu
	active_gu_changed.emit(gu)

func get_gu_by_id(gu_id: String) -> GuVirtual:
	for gu in owned_gus:
		if gu.id == gu_id:
			return gu
	return null

func get_gu_list() -> Array[GuVirtual]:
	return owned_gus

func feed_gu(gu_id: String, food_id: String) -> bool:
	var gu = get_gu_by_id(gu_id)
	if not gu:
		return false

	return gu.feed(food_id)

func get_all_hunger_status() -> Array:
	var statuses = []
	var hunger_system = get_node_or_null("/root/Hunger")
	if not hunger_system:
		return statuses

	for gu in owned_gus:
		var hunger = hunger_system.get_hunger(gu.id)
		var status = hunger_system.get_hunger_status(gu.id)
		statuses.append({
			"gu": gu,
			"hunger": hunger,
			"status": status
		})

	return statuses

func _on_gu_dormant(gu_id: String, withered: bool):
	var gu = get_gu_by_id(gu_id)
	var name = gu.name if gu else gu_id
	if withered:
		push_warning("蛊虫【%s】已经饿死" % name)
	else:
		push_warning("蛊虫【%s】濒临饿死，需要及时喂食" % name)

func save_data() -> Array:
	var save_array = []
	for gu in owned_gus:
		save_array.append(gu.to_dict())
	return save_array

func load_data(save_array: Array):
	owned_gus.clear()
	active_gu = null

	for gu_data in save_array:
		if not GameData.GU.has(String(gu_data.get("template_id",""))): continue
		var gu = GuVirtual.from_dict(gu_data)
		owned_gus.append(gu)

		# 重新注册到饥饿度系统
		var hunger_system = get_node_or_null("/root/Hunger")
		if hunger_system:
			hunger_system.register_gu(gu.id, gu.rank, gu.quality, gu.preferred_food)

	if owned_gus.size() > 0:
		set_active_gu(owned_gus[0])
