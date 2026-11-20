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
var cols: HBoxContainer
var mortal_panel: VBoxContainer
var awaken_button: Button

func _ready() -> void:
	cols=HBoxContainer.new()
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
	right.add_child(UIStyle.button("查看升炼蛊方与威力变化 →",func(): game.open_journal("refinement")))
	mortal_panel=VBoxContainer.new()
	UIStyle.fill(mortal_panel)
	mortal_panel.add_theme_constant_override("separation",18)
	add_child(mortal_panel)
	mortal_panel.add_child(UIStyle.label("凡人 · 空窍尚未开辟",24,UIStyle.GOLD))
	var hope:=GuArt.portrait(125)
	hope.texture=GuArt.texture("hope_gu")
	mortal_panel.add_child(hope)
	var explanation:=UIStyle.label("希望蛊是花海中的微弱白色光点。\n借希望蛊开辟空窍，形成光膜与青铜元海，才可成为蛊师。\n\n当前资质：未觉醒 · 无真元 · 无窍壁\n你仍可行走、探索、采集、交易与使用普通物品。",16)
	explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	mortal_panel.add_child(explanation)
	awaken_button=UIStyle.button("标记地下溶洞 · 寻找希望蛊",func(): game.guide_awakening())
	mortal_panel.add_child(awaken_button)
	mortal_panel.add_child(UIStyle.label("进入洞口后走近月兰花海，按 E 开始。资质揭晓前不显示等第。",13,UIStyle.DIM))
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
	cols.visible=a.is_open()
	mortal_panel.visible=not a.is_open()
	if not a.is_open():
		awaken_button.text="引动花海中的希望蛊" if game.world.in_interior and game.current_house_id=="spring_cave" and game.world.interior.interaction_at(p.position)=="spring_cave" else "标记地下溶洞 · 寻找希望蛊"
		return
	view.queue_redraw()
	summary.text="[color=#d8bc7c]%s · %s资质[/color]\n当前真元：%s（剩余 %.0f%%）\n资质容量：占整个空窍 %.1f%%\n%s：%.1f 点\n高一小阶真元：%.1f 点\n窍壁温养：%.1f%%\n元石待吸收余量：%.1f\n" % [a.realm(),a.aptitude(),a.amount_text(),a.fill_ratio()*100,a.capacity,a.essence_name(),a.essence,a.refined_essence,a.wall_progress,a.stone_reserve]
	summary.text+="先天潜力：%.0f%% · 后天增长：%.2f / 20 点\n"%[a.potential,a.aptitude_gain]
	summary.text+="[color=#93a99f]1 点真元等于空窍容积的 1%；金虚线是元海上限。资质蛊只扩大容量，舍利蛊只提升对应转数的小阶。普通物品放背包。[/color]"
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	var gus:GuManager=game.get_node("/root/Gus")
	if selected_id=="" and gus.active_gu!=null: selected_id=gus.active_gu.id
	for gu in gus.owned_gus:
		var location: String={"aperture":"空窍中","body":"掌心寄居","bag":"外部携带"}[gu.location]
		var text:="%s · %d转 · %s\n%s%s%s" % [gu.name,gu.rank,GuProgression.rarity(gu.template_id),location," · 本命" if gu.id==p.vital_gu_id else ""," · 已死亡" if gu.dead else ""]
		var button:=UIStyle.button(text,select_gu.bind(gu.id))
		GuArt.decorate(button,gu.template_id,28)
		button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		button.modulate=UIStyle.GOLD if gu.id==selected_id else Color.WHITE
		list.add_child(button)
	var selected:=gus.get_gu_by_id(selected_id)
	if selected==null:
		detail.text="选择蛊虫查看居处。\n空窍不是三个技能槽，已炼化蛊虫可超过三只。\n外部携带的蛊在背包中；月光蛊、小光蛊也可寄居掌心。"
	else:
		var effect_text:=GameData.activation_hint(selected.template_id,a.stage,a.rank)
		if not GameData.GU[selected.template_id].has("hint"): effect_text=GuProgression.power(selected.template_id)+"\n"+effect_text
		detail.text="[color=#d8bc7c]%s[/color]\n%s\n食物：%s · %s\n" % [GuProgression.title(selected.template_id),effect_text,FoodSystem.GRAINS[selected.preferred_food].name,game.get_node("/root/Hunger").get_hunger_status(selected.id)]
		for i in 3:
			if p.skill_slots[i]==selected.id: detail.text+="已绑定快捷位 %d\n"%(i+1)
