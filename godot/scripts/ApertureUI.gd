class_name ApertureUI
extends Control

var game: Node
var summary: RichTextLabel
var view: ApertureView
var list: VBoxContainer
var detail: RichTextLabel
var selected_id := ""
var selected_slot := 0
var target: OptionButton

func _ready() -> void:
	var cols:=HBoxContainer.new()
	UIStyle.fill(cols)
	cols.add_theme_constant_override("separation",16)
	add_child(cols)
	var left:=_scroll_card(cols,435)
	left.add_child(UIStyle.label("内视 · 空窍元海",22,UIStyle.GOLD))
	var overview:=HBoxContainer.new()
	overview.add_theme_constant_override("separation",14)
	left.add_child(overview)
	view=ApertureView.new()
	view.player=game.player
	overview.add_child(view)
	summary=UIStyle.rich(14)
	summary.fit_content=true
	summary.scroll_active=false
	summary.custom_minimum_size=Vector2(215,210)
	summary.size_flags_horizontal=SIZE_EXPAND_FILL
	overview.add_child(summary)
	left.add_child(UIStyle.button("J 打坐 · 消耗真元温养窍壁",func():
		game.journal.close()
		game.toggle_meditation()
	))
	left.add_child(UIStyle.button("温养完成后冲关",func(): game.attempt_breakthrough()))
	left.add_child(UIStyle.button("吸收元石 · 从随身钱袋取用",func():
		game.absorb_primeval_stone()
		refresh()
	))
	var right:=_scroll_card(cols,375)
	right.add_child(UIStyle.label("已炼化蛊 · 居处与催动",22,UIStyle.GOLD))
	var scroll:=ScrollContainer.new()
	scroll.custom_minimum_size.y=120
	scroll.size_flags_vertical=SIZE_EXPAND_FILL
	right.add_child(scroll)
	list=VBoxContainer.new()
	list.size_flags_horizontal=SIZE_EXPAND_FILL
	scroll.add_child(list)
	detail=UIStyle.rich(15)
	detail.fit_content=true
	detail.scroll_active=false
	detail.custom_minimum_size.y=95
	right.add_child(detail)
	var binding:=HBoxContainer.new()
	right.add_child(binding)
	target=OptionButton.new()
	for i in 3: target.add_item("催蛊快捷位 %d" % (i+1))
	target.item_selected.connect(func(i:int): selected_slot=i)
	binding.add_child(target)
	binding.add_child(UIStyle.button("绑定快捷位",func():
		game.equip_gu(selected_id,selected_slot)
		refresh()
	))
	var moves:=HBoxContainer.new()
	right.add_child(moves)
	for row in [["收入空窍","aperture"],["取出携带","bag"],["寄居掌心","body"]]:
		moves.add_child(UIStyle.button(row[0],_move.bind(row[1])))
	right.add_child(UIStyle.button("去背包取食物喂养 →",func(): game.open_journal("inventory")))
	visibility_changed.connect(refresh)
	refresh()

func _scroll_card(parent: Control, width: float) -> VBoxContainer:
	var card:=UIStyle.card(parent,width)
	var scroll:=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical=SIZE_EXPAND_FILL
	card.add_child(scroll)
	var content:=VBoxContainer.new()
	content.size_flags_horizontal=SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",10)
	scroll.add_child(content)
	return content

func _move(location: String) -> void:
	game.move_gu(selected_id,location)
	refresh()

func select_gu(id: String) -> void:
	selected_id=id
	var gu: GuVirtual=game.get_node("/root/Gus").get_gu_by_id(id)
	if gu: game.get_node("/root/Gus").set_active_gu(gu)
	refresh()

func refresh() -> void:
	if summary==null: return
	var p:Player=game.player
	var a:=p.aperture
	view.queue_redraw()
	summary.text="[color=#d8bc7c]%s · %s资质[/color]\n元海上限：整个空窍的 %.0f%%\n%s：%.1f%%\n高一小阶真元：%.1f%%\n窍壁温养：%.1f%%\n元石待吸收余量：%.1f\n" % [a.realm(),a.aptitude(),a.capacity,a.essence_name(),a.essence,a.refined_essence,a.wall_progress,a.stone_reserve]
	summary.text+="[color=#93a99f]金虚线是元海上限；空窍不存放元石、药物等普通物品。[/color]"
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	var gus:GuManager=game.get_node("/root/Gus")
	if selected_id=="" and gus.active_gu!=null: selected_id=gus.active_gu.id
	for gu in gus.owned_gus:
		var location: String={"aperture":"空窍中","body":"掌心寄居","bag":"外部携带"}[gu.location]
		var text:=gu.name+" · "+location+(" · 本命" if gu.id==p.vital_gu_id else "")+(" · 已死亡" if gu.dead else "")
		var button:=UIStyle.button(text,select_gu.bind(gu.id))
		GuArt.decorate(button,gu.template_id,28)
		button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		button.modulate=UIStyle.GOLD if gu.id==selected_id else Color.WHITE
		list.add_child(button)
	var selected:=gus.get_gu_by_id(selected_id)
	if selected==null:
		detail.text="选择蛊虫查看居处。\n空窍不是三个技能槽，已炼化蛊虫可超过三只。\n外部携带的蛊在背包中；月光蛊也可寄居掌心。"
	else:
		detail.text="[color=#76c2aa]%s[/color]\n%s\n食物：%s · %s\n" % [selected.name,GameData.activation_hint(selected.template_id,a.stage),FoodSystem.GRAINS[selected.preferred_food].name,game.get_node("/root/Hunger").get_hunger_status(selected.id)]
		for i in 3:
			if p.skill_slots[i]==selected.id: detail.text+="已绑定快捷位 %d\n"%(i+1)
