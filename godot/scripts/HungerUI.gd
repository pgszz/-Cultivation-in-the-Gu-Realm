extends Control

## 饥饿度UI显示 - 显示蛊虫饥饿状态

@onready var hunger_bar: ProgressBar = $HungerBar
@onready var status_label: Label = $StatusLabel
@onready var timer_label: Label = $TimerLabel

var gu_id: String = ""
var hunger_system: HungerSystem

func _ready():
	hunger_system = get_node_or_null("/root/Hunger")

	if hunger_system:
		hunger_system.gu_hunger_changed.connect(_on_hunger_changed)
		hunger_system.gu_starving.connect(_on_starving)

func set_gu(id: String):
	gu_id = id
	update_display()

func _process(_delta):
	if gu_id != "":
		update_display()

func update_display():
	if not hunger_system or gu_id == "":
		return

	var hunger = hunger_system.get_hunger(gu_id)
	var status = hunger_system.get_hunger_status(gu_id)
	var penalty = hunger_system.get_hunger_penalty(gu_id)

	# 更新进度条
	hunger_bar.value = hunger

	# 根据饥饿度改变颜色
	if hunger >= 80:
		hunger_bar.modulate = Color.GREEN
	elif hunger >= 50:
		hunger_bar.modulate = Color.YELLOW
	elif hunger >= 20:
		hunger_bar.modulate = Color.ORANGE
	else:
		hunger_bar.modulate = Color.RED

	# 更新状态文本
	status_label.text = "%s (%.0f%%)" % [status, hunger]

	if penalty < 1.0:
		status_label.text += " [战力×%.0f%%]" % (penalty * 100)

	# 休眠/枯眠倒计时
	if hunger_system.gu_data.has(gu_id):
		var data = hunger_system.gu_data[gu_id]
		if data.is_withered:
			timer_label.text = "枯眠：需要材料唤醒"
			timer_label.visible = true
		elif data.is_dormant:
			var remaining: float = hunger_system.DORMANT_REVIVE_WINDOW - (Time.get_unix_time_from_system() - data.dormant_time)
			timer_label.text = "休眠倒计时：%d 秒" % max(0, int(remaining))
			timer_label.visible = true
		else:
			timer_label.visible = false

func _on_hunger_changed(id: String, hunger: float):
	if id == gu_id:
		update_display()

func _on_starving(id: String):
	if id == gu_id:
		# 播放警告音效
		push_warning("蛊虫【%s】濒死！" % gu_id)
