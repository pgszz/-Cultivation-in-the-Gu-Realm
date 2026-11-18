class_name HealthUI
extends Control

## 健康显示 - 玩家血条、真元、激活蛊虫状态、饥饿度

var player: Player
var gu_manager: GuManager
var hunger_system: HungerSystem

const C_INK := Color("#d8e6d2")
const C_DIM := Color("#8fa38a")
const C_BLOOD := Color("#d9534f")
const C_YUAN := Color("#4aa3df")
const C_HUNGER := Color("#f9a825")
const C_PANEL := Color(0.04, 0.07, 0.05, 0.62)

var font: Font


func _ready() -> void:
	font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	gu_manager = get_node_or_null("/root/Gus")
	hunger_system = get_node_or_null("/root/Hunger")


func set_player(p: Player) -> void:
	player = p


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not player:
		return

	var pos := Vector2(12, 10)
	var bar_width := 200.0

	# 背景面板
	draw_rect(Rect2(pos, Vector2(bar_width + 80, 110)), C_PANEL)

	# 玩家血条
	_draw_bar(pos + Vector2(8, 8), bar_width, player.hp / player.max_hp, C_BLOOD,
		"气血", "%d/%d" % [ceili(max(player.hp, 0.0)), int(player.max_hp)])

	# 真元条
	_draw_bar(pos + Vector2(8, 28), bar_width, player.yuan / player.max_yuan, C_YUAN,
		"真元", "%d/%d" % [ceili(player.yuan), int(player.max_yuan)])

	# 状态图标
	var status_x := pos.x + 8
	var status_y := pos.y + 50
	for k in ["burn", "poison", "bleed", "wet", "shock", "slow"]:
		if player.status[k] > 0.0:
			var col := _get_status_color(k)
			draw_circle(Vector2(status_x, status_y), 4.0, col)
			status_x += 14.0

	# 激活蛊虫
	if gu_manager and gu_manager.active_gu:
		var gu := gu_manager.active_gu
		var gu_pos := pos + Vector2(8, 62)

		# 蛊虫头像背景
		draw_rect(Rect2(gu_pos, Vector2(32, 32)), Color(0, 0, 0, 0.7))

		# 蛊虫元素颜色边框
		var gu_data = GameData.GU.get(gu.template_id, {})
		if gu_data.has("color"):
			draw_rect(Rect2(gu_pos, Vector2(32, 32)), gu_data.color, false, 2.0)

		# 蛊虫名称
		draw_string(font, gu_pos + Vector2(38, 12), gu.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, C_INK)

		# 蛊虫等级/转数
		draw_string(font, gu_pos + Vector2(38, 26), "%d转" % gu.rank, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, C_DIM)

		# 饥饿度进度条
		if hunger_system:
			var hunger := hunger_system.get_hunger(gu.id)
			var hunger_color := _get_hunger_color(hunger)
			_draw_bar(gu_pos + Vector2(38, 30), bar_width - 46, hunger / 100.0, hunger_color,
				"饥饿", "%.0f%%" % hunger)


func _draw_bar(pos: Vector2, width: float, ratio: float, col: Color, label: String, value: String) -> void:
	# 标签
	draw_string(font, pos + Vector2(0, 8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, C_DIM)

	# 进度条背景
	draw_rect(Rect2(pos + Vector2(32, 0), Vector2(width, 10)), Color(0, 0, 0, 0.6))

	# 进度条填充
	var filled_width := width * clampf(ratio, 0.0, 1.0)
	if filled_width > 0:
		draw_rect(Rect2(pos + Vector2(32, 0), Vector2(filled_width, 10)), col)

	# 边框
	draw_rect(Rect2(pos + Vector2(32, 0), Vector2(width, 10)), Color(1, 1, 1, 0.1), false, 1.0)

	# 数值
	draw_string(font, pos + Vector2(32 + width + 6, 8), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, C_DIM)


func _get_status_color(status_key: String) -> Color:
	match status_key:
		"burn": return GameData.el_color("fire")
		"poison": return GameData.el_color("wood")
		"bleed": return GameData.el_color("metal")
		"wet": return GameData.el_color("water")
		"shock": return GameData.el_color("thunder")
		"slow": return GameData.el_color("earth")
	return Color.WHITE


func _get_hunger_color(hunger: float) -> Color:
	if hunger >= 80.0:
		return Color.GREEN
	elif hunger >= 50.0:
		return Color.YELLOW
	elif hunger >= 20.0:
		return Color.ORANGE
	else:
		return Color.RED
