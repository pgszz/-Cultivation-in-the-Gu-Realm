extends Node2D

## 饥饿度系统测试场景

@onready var hunger_ui = $UI/HungerUI
@onready var status_label = $UI/StatusLabel

var test_gu_ids = []
var game_manager: GameManager
var gu_manager: GuManager

func _ready():
	# 初始化系统
	game_manager = GameManager.new()
	add_child(game_manager)
	await get_tree().process_frame

	gu_manager = get_node_or_null("/root/Gus")

	# 创建测试蛊虫
	setup_test_gus()

	# 添加测试食物
	add_test_food()

	print("=== 饥饿度系统测试 ===")
	print("按键说明：")
	print("1-3: 选择不同蛊虫")
	print("F: 喂食当前蛊虫")
	print("T: 加速时间（测试饥饿度下降）")
	print("S: 保存游戏")
	print("L: 加载游戏")

	if "--autotest" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		_autotest()


func _autotest() -> void:
	print("AUTOTEST gu_ids=%s" % str(test_gu_ids))
	feed_current_gu()
	accelerate_time()
	var hunger_system := get_node_or_null("/root/Hunger")
	for id in test_gu_ids:
		print("AUTOTEST %s hunger=%.1f status=%s" % [
			id, hunger_system.get_hunger(id), hunger_system.get_hunger_status(id)
		])
	var first_gu = gu_manager.owned_gus[0]
	print("AUTOTEST guvirtual feed=%s atk=%.1f" % [str(first_gu.feed("grain_normal")), first_gu.get_effective_atk()])
	var food := get_node_or_null("/root/Food")
	print("AUTOTEST food grass=%.0f grain=%s" % [
		food.calculate_restore("grass", "力"), food.get_food_name("grain_normal")
	])
	save_game()
	var before: float = hunger_system.get_hunger(test_gu_ids[0])
	hunger_system.gu_data[test_gu_ids[0]].current_hunger = 10.0
	load_game()
	print("AUTOTEST load before=%.1f after=%.1f" % [before, hunger_system.get_hunger(test_gu_ids[0])])
	get_tree().quit()

func setup_test_gus():
	# 创建3只不同转数的蛊虫进行测试
	var gu1 = gu_manager.add_gu("moon_blade", "normal")  # 1转
	var gu2 = gu_manager.add_gu("leiwen", "fine")   # 2转精英
	var gu3 = gu_manager.add_gu("jin_can", "perfect")  # 4转BOSS

	test_gu_ids = [gu1.id, gu2.id, gu3.id]

	# 显示第一只蛊虫
	if hunger_ui:
		hunger_ui.set_gu(test_gu_ids[0])

func add_test_food():
	var inventory = get_node_or_null("/root/Inv")
	if not inventory:
		return

	# 添加各种食物
	inventory.add_item("grain_normal", 10)
	inventory.add_item("grass", 20)
	inventory.add_item("rabbit_meat", 15)
	inventory.add_item("wolf_demon_meat", 5)
	inventory.add_item("blood_vine", 8)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1, KEY_2, KEY_3:
				var index = event.keycode - KEY_1
				if index < test_gu_ids.size():
					select_gu(index)
			KEY_F:
				feed_current_gu()
			KEY_T:
				accelerate_time()
			KEY_S:
				save_game()
			KEY_L:
				load_game()

func select_gu(index: int):
	if hunger_ui:
		hunger_ui.set_gu(test_gu_ids[index])
	update_status("切换到蛊虫 #%d" % (index + 1))

func feed_current_gu():
	var current_gu_id = hunger_ui.gu_id if hunger_ui else ""
	if current_gu_id == "":
		return

	var inventory = get_node_or_null("/root/Inv")
	var food_system = get_node_or_null("/root/Food")

	if not inventory or not food_system:
		return

	# 找到第一个可用食物
	var foods = inventory.get_all_food_items()
	if foods.is_empty():
		update_status("没有食物！")
		return

	var food_id = foods[0].id
	if inventory.use_item(food_id, current_gu_id):
		var food_name = food_system.get_food_name(food_id)
		update_status("喂食 %s 成功" % food_name)
	else:
		update_status("喂食失败")

func accelerate_time():
	var hunger_system = get_node_or_null("/root/Hunger")
	if not hunger_system:
		return

	# 模拟 1 游戏小时（60 秒 / 1 游戏日=1440 秒）
	hunger_system.update(60.0)

	update_status("时间加速：1小时")

func save_game():
	if game_manager.save_game("user://test_save.sav"):
		update_status("游戏已保存")
	else:
		update_status("保存失败")

func load_game():
	if game_manager.load_game("user://test_save.sav"):
		update_status("游戏已加载")
	else:
		update_status("加载失败")

func update_status(text: String):
	if status_label:
		status_label.text = text
	print(text)
