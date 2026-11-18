extends Control

## 喂养界面 - 选择食物喂养蛊虫

@onready var food_list: ItemList = $FoodList
@onready var gu_list: ItemList = $GuList
@onready var feed_button: Button = $FeedButton
@onready var description_label: RichTextLabel = $DescriptionLabel

var inventory: Inventory
var food_system: FoodSystem
var selected_food_id: String = ""
var selected_gu_id: String = ""

func _ready():
	inventory = get_node_or_null("/root/Inv")
	food_system = get_node_or_null("/root/Food")

	feed_button.pressed.connect(_on_feed_pressed)
	food_list.item_selected.connect(_on_food_selected)
	gu_list.item_selected.connect(_on_gu_selected)

	refresh_food_list()
	refresh_gu_list()

func refresh_food_list():
	food_list.clear()

	if not inventory:
		return

	var foods = inventory.get_all_food_items()
	for item in foods:
		var name = food_system.get_food_name(item.id) if food_system else item.id
		var text = "%s ×%d" % [name, item.amount]
		food_list.add_item(text)
		food_list.set_item_metadata(food_list.item_count - 1, item.id)

func refresh_gu_list():
	gu_list.clear()

	var gu_manager = get_node_or_null("/root/Gus")
	if not gu_manager:
		return

	var hunger_system = get_node_or_null("/root/Hunger")
	for gu in gu_manager.owned_gus:
		var hunger = hunger_system.get_hunger(gu.id) if hunger_system else 100.0
		var text = "%s [饥饿度: %.0f]" % [gu.name, hunger]
		gu_list.add_item(text)
		gu_list.set_item_metadata(gu_list.item_count - 1, gu.id)

func _on_food_selected(index: int):
	selected_food_id = food_list.get_item_metadata(index)
	update_description()

func _on_gu_selected(index: int):
	selected_gu_id = gu_list.get_item_metadata(index)
	update_description()

func update_description():
	if selected_food_id == "" or selected_gu_id == "":
		description_label.text = "请选择食物和蛊虫"
		feed_button.disabled = true
		return

	if not food_system:
		return

	var desc = food_system.get_food_description(selected_food_id, "")
	description_label.text = desc
	feed_button.disabled = false

func _on_feed_pressed():
	if selected_food_id == "" or selected_gu_id == "":
		return

	if not inventory or not inventory.has_item(selected_food_id):
		description_label.text = "[color=red]食物不足[/color]"
		return

	# 使用食物
	if inventory.use_item(selected_food_id, selected_gu_id):
		description_label.text = "[color=green]喂食成功！[/color]"
		refresh_food_list()
		refresh_gu_list()
	else:
		description_label.text = "[color=red]喂食失败[/color]"
