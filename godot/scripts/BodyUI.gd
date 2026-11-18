class_name BodyUI
extends Control

var player: Player
var game: Node
var selected_part := "torso"
var diagram: BodyDiagram
var detail: RichTextLabel
var advice: Label
var part_scroll: ScrollContainer
var summary: Label
var treat_button: Button
var rows: Dictionary = {}
var _elapsed := 0.0

func _ready() -> void:
	var stack := VBoxContainer.new()
	UIStyle.fill(stack)
	stack.add_theme_constant_override("separation",14)
	add_child(stack)
	summary = UIStyle.label("",16)
	stack.add_child(summary)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation",14)
	columns.size_flags_vertical = SIZE_EXPAND_FILL
	stack.add_child(columns)
	var anatomy := UIStyle.card(columns,238)
	anatomy.get_parent().size_flags_horizontal = SIZE_FILL
	anatomy.add_child(UIStyle.label("经脉 · 肢体",20,UIStyle.GOLD))
	diagram = BodyDiagram.new()
	diagram.size_flags_vertical = SIZE_EXPAND_FILL
	diagram.part_selected.connect(select_part)
	anatomy.add_child(diagram)
	anatomy.add_child(UIStyle.label("青绿 完好   金色 受伤   红色 危重",12,UIStyle.DIM))
	var list_card := UIStyle.card(columns,220)
	list_card.get_parent().size_flags_horizontal = SIZE_FILL
	list_card.add_child(UIStyle.label("部位检查 / 15",20,UIStyle.GOLD))
	var scroll := ScrollContainer.new()
	part_scroll = scroll
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_card.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(list)
	for id in BodyComponent.PARTS:
		var button := UIStyle.button("",select_part.bind(id))
		button.custom_minimum_size.y = 40
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		list.add_child(button)
		rows[id] = button
	var right := UIStyle.card(columns,290)
	right.add_child(UIStyle.label("伤势与处理",20,UIStyle.GOLD))
	detail = UIStyle.rich(15)
	right.add_child(detail)
	advice = UIStyle.label("",15,UIStyle.JADE)
	advice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(advice)
	treat_button = UIStyle.button("处理此处伤口 · H",_treat)
	right.add_child(treat_button)
	var links := HBoxContainer.new()
	right.add_child(links)
	var bag_link := UIStyle.button("背包药物 →",func():
		if game != null: game.open_journal("inventory")
	)
	bag_link.size_flags_horizontal=SIZE_EXPAND_FILL
	links.add_child(bag_link)
	var attr_link := UIStyle.button("人物属性 →",func():
		if game != null: game.open_journal("character")
	)
	attr_link.size_flags_horizontal=SIZE_EXPAND_FILL
	links.add_child(attr_link)
	refresh()

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	_elapsed += delta
	if _elapsed >= 0.15:
		_elapsed = 0.0
		refresh()

func select_part(id: String) -> void:
	selected_part = id
	refresh()
	if part_scroll and rows.has(id):
		await get_tree().process_frame
		part_scroll.ensure_control_visible(rows[id])

func refresh() -> void:
	if player == null or player.body == null or detail == null: return
	var b := player.body
	diagram.body = b
	diagram.selected = selected_part
	diagram.queue_redraw()
	summary.text = "血量 %.0f%%    疼痛 %.0f / 100    意识 %.0f%%    失血 %.1f / 秒    视野 %.0f%%" % [b.blood,b.pain,b.consciousness,b.total_bleed_rate(),b.get_vision_multiplier()*100]
	for id in rows:
		var p: Dictionary = b.parts[id]
		rows[id].text = "%s  %s  %d/%d" % [p.name,b.part_status(id),ceili(p.hp),int(p.max_hp)]
		rows[id].modulate = UIStyle.GOLD if id == selected_part else Color.WHITE
	if not b.parts.has(selected_part): return
	var part: Dictionary = b.parts[selected_part]
	var bleed := b.part_bleed_rate(selected_part)
	detail.text = "[font_size=25][color=#d8bc7c]%s[/color][/font_size]  %s\n" % [part.name,b.part_status(selected_part)]
	detail.text += "耐久  %d / %d    当前出血  %.1f / 秒\n护甲  %.1f（部位伤害减免 %.0f%%）\n\n" % [ceili(part.hp),int(part.max_hp),bleed,part.armor,part.armor*30.0]
	detail.text += "[color=#76c2aa]部位作用与受伤后果[/color]\n%s" % b.part_description(selected_part)
	advice.text = "处理建议：" + b.treatment_hint(selected_part)
	if b.neck_timer >= 0.0:
		detail.text += "\n[color=#df8775]颈部急救倒计时：%.1f 秒。立即止血！[/color]" % b.neck_timer
	var inv := get_node_or_null("/root/Inv")
	var bandages: int = inv.get_item_count("bandage") if inv else 0
	treat_button.text = "包扎此部位 · 绷带 %d" % bandages
	treat_button.disabled = (bandages == 0 and player.materials <= 0) or (float(part.hp) >= float(part.max_hp) and bleed <= 0.0 and b.neck_timer < 0.0)

func _treat() -> void:
	if game != null: game.treat_part(selected_part)
	refresh()
