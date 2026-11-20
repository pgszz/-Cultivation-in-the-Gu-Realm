class_name StartScreen
extends Control

var game: Node
var start_button: Button
var settings_button: Button
var create_button: Button
var delete_button: Button
var note: Label
var selected_id := ""
var cards: VBoxContainer
var card_buttons := {}
var detail: Label
var identity: Label
var portrait: CharacterPreview
var appearance_button: Button
var appearance_editor: AppearanceEditor
var draft_appearance: Dictionary = {}
var draft_images: Dictionary = {}
var editing_new := false
var edit_target := ""
var new_appearance_button: Button
var new_overlay: Control
var delete_overlay: Control
var name_input: LineEdit
var create_confirm: Button
var create_cancel: Button
var name_error: Label
var delete_confirm: Button
var delete_cancel: Button
var delete_text: Label
var delete_target := ""

func _ready() -> void:
	UIStyle.fill(self)
	var shade:=ColorRect.new()
	shade.color=Color(0.02,0.06,0.06,0.88)
	UIStyle.fill(shade)
	add_child(shade)
	var margin:=MarginContainer.new()
	UIStyle.fill(margin)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,28)
	add_child(margin)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",12)
	margin.add_child(root)
	var header:=HBoxContainer.new()
	root.add_child(header)
	var title:=UIStyle.label("蛊道修仙  /  青茅山",28,UIStyle.GOLD)
	title.size_flags_horizontal=SIZE_EXPAND_FILL
	header.add_child(title)
	settings_button=UIStyle.button("设置 · 画面与声音",game.open_settings)
	header.add_child(settings_button)
	root.add_child(UIStyle.label("选择角色   ·   每个角色一段独立的山中岁月",16,UIStyle.DIM))
	var columns:=HBoxContainer.new()
	columns.add_theme_constant_override("separation",24)
	columns.size_flags_vertical=SIZE_EXPAND_FILL
	root.add_child(columns)
	var scroll:=ScrollContainer.new()
	scroll.size_flags_horizontal=SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio=1.25
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(scroll)
	cards=VBoxContainer.new()
	cards.size_flags_horizontal=SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation",8)
	scroll.add_child(cards)
	var right:=UIStyle.card(columns)
	identity=UIStyle.label("尚无角色",23,UIStyle.GOLD)
	identity.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(identity)
	portrait=CharacterPreview.new()
	portrait.size_flags_vertical=SIZE_EXPAND_FILL
	portrait.custom_minimum_size.y=100
	right.add_child(portrait)
	detail=UIStyle.label("",15)
	detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	right.add_child(detail)
	note=UIStyle.label("死亡后该角色永久作废，无法读档复活。请珍惜每一次出行。",14,UIStyle.RED)
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.y=38
	root.add_child(note)
	var actions:=HBoxContainer.new()
	actions.add_theme_constant_override("separation",12)
	root.add_child(actions)
	create_button=UIStyle.button("＋ 新建角色",open_create)
	delete_button=UIStyle.button("删除角色",open_delete)
	appearance_button=UIStyle.button("设计外观",open_appearance)
	start_button=UIStyle.button("进入青茅山 →",func():
		if not selected_id.is_empty(): game.start_game(selected_id)
	)
	for button in [create_button,appearance_button,delete_button,start_button]:
		button.size_flags_horizontal=SIZE_EXPAND_FILL
		button.custom_minimum_size.y=44
		actions.add_child(button)
	_build_dialogs()
	appearance_editor=AppearanceEditor.new()
	add_child(appearance_editor)
	appearance_editor.confirmed.connect(_confirm_appearance)
	appearance_editor.dismissed.connect(func():
		if editing_new: new_appearance_button.grab_focus()
		else: appearance_button.grab_focus()
	)
	selected_id=game.character_saves.last_selection()
	refresh()
	if not game.character_saves.last_error.is_empty(): note.text=game.character_saves.last_error

func _dialog() -> Control:
	var overlay:=Control.new()
	UIStyle.fill(overlay)
	add_child(overlay)
	var shade:=ColorRect.new()
	shade.color=Color(0,0,0,0.78)
	UIStyle.fill(shade)
	overlay.add_child(shade)
	var center:=CenterContainer.new()
	UIStyle.fill(center)
	overlay.add_child(center)
	var box:=UIStyle.card(center,500)
	box.add_theme_constant_override("separation",16)
	overlay.set_meta("content",box)
	overlay.hide()
	return overlay

func _build_dialogs() -> void:
	new_overlay=_dialog()
	var box:VBoxContainer=new_overlay.get_meta("content")
	box.add_child(UIStyle.label("新的山中岁月",24,UIStyle.GOLD))
	box.add_child(UIStyle.label("角色名（1–16 字）",16))
	name_input=LineEdit.new()
	name_input.max_length=16
	name_input.placeholder_text="为这位尚未开窍的凡人起名"
	name_input.custom_minimum_size.y=42
	name_input.text_submitted.connect(func(_text: String): _create())
	box.add_child(name_input)
	new_appearance_button=UIStyle.button("设计外观 · 衣服与导入图集",func():
		editing_new=true
		appearance_editor.open(draft_appearance,"",draft_images)
	)
	box.add_child(new_appearance_button)
	box.add_child(UIStyle.label("凡人开局，需借希望蛊开窍。资质随机丁至甲等。\n背包与世界进度独立；死亡即永久陨落。",16,UIStyle.RED))
	name_error=UIStyle.label("",14,UIStyle.RED)
	name_error.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	name_error.custom_minimum_size=Vector2(460,40)
	box.add_child(name_error)
	create_confirm=UIStyle.button("创建角色",_create)
	box.add_child(create_confirm)
	create_cancel=UIStyle.button("取消",func(): new_overlay.hide(); create_button.grab_focus())
	box.add_child(create_cancel)
	delete_overlay=_dialog()
	box=delete_overlay.get_meta("content")
	box.add_child(UIStyle.label("删除角色存档",24,UIStyle.RED))
	delete_text=UIStyle.label("",16)
	delete_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	delete_text.custom_minimum_size=Vector2(460,100)
	box.add_child(delete_text)
	delete_cancel=UIStyle.button("取消 · 保留角色",func(): delete_overlay.hide(); delete_button.grab_focus())
	box.add_child(delete_cancel)
	delete_confirm=UIStyle.button("永久删除此角色",_delete)
	box.add_child(delete_confirm)

func refresh() -> void:
	for child in cards.get_children():
		cards.remove_child(child)
		child.queue_free()
	card_buttons.clear()
	var entries:Array[Dictionary]=game.character_saves.entries()
	var selected:Dictionary={}
	for entry in entries:
		if entry.id==selected_id: selected=entry
	if selected.is_empty() and not entries.is_empty():
		selected=entries[0]
		selected_id=selected.id
	if entries.is_empty():
		selected_id=""
		cards.add_child(UIStyle.label("山路尚无人踏足\n\n点击「新建角色」开启游历。",18,UIStyle.DIM))
	for entry in entries:
		var state: String={"alive":"可继续","dead":"已陨落 · 永久作废","corrupt":"存档损坏 · 无法读取","deleting":"删除未完成 · 可重试"}[entry.status]
		var button:=UIStyle.button("%s  %s\n%s · 游历 %d 分钟"%["◆" if entry.id==selected_id else "◇",entry.name,state,int(entry.play_time/60)],select_character.bind(entry.id))
		button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y=74
		button.add_theme_font_size_override("font_size",16)
		button.add_theme_color_override("font_color",UIStyle.RED if entry.status!="alive" else UIStyle.INK)
		if entry.id==selected_id: button.add_theme_stylebox_override("normal",UIStyle.box(Color("29483f"),UIStyle.GOLD))
		cards.add_child(button)
		card_buttons[entry.id]=button
	delete_button.disabled=selected.is_empty()
	start_button.disabled=selected.is_empty() or selected.get("status","")!="alive"
	appearance_button.disabled=start_button.disabled
	identity.text=str(selected.get("name","尚无角色"))
	portrait.modulate=Color("777b79") if selected.get("status","")=="dead" else Color.WHITE
	portrait.show_appearance(game.character_saves.appearance_for(selected_id),game.character_saves.art_directory(selected_id))
	if selected.is_empty(): detail.text="新建凡人角色，从古月山寨出发。\n借希望蛊开窍后，方可温养空窍、炼化用蛊。"
	elif selected.status=="dead": detail.text="此人已陨落。\n"+selected.death_reason+"\n可保留这段记录，也可删除此角色。"
	elif selected.status!="alive": detail.text="此存档无法继续读取。\n可删除后重新创建角色。"
	else:
		var stages:=["初阶","中阶","高阶","巅峰"]
		var realm:="凡人 · 资质未觉醒" if selected.rank==0 or selected.fresh else "%d 转 · %s"%[selected.rank,stages[clampi(selected.stage,0,3)]]
		detail.text="%s\n%s\nWASD 移动 · E 交互 · Esc 暂停 / 返回"%[realm,"前往地下溶洞花海，借希望蛊开窍" if selected.fresh else "最近保存："+selected.updated_at.replace("T"," ")]

func select_character(id: String) -> void:
	selected_id=id
	game.character_saves.remember_selection(id)
	refresh()

func open_create() -> void:
	draft_appearance=CharacterAppearance.DEFAULTS.duplicate(true)
	draft_images.clear()
	name_input.text=""
	name_error.text=""
	new_overlay.show()
	name_input.grab_focus()

func _create() -> void:
	var id: String=game.character_saves.create_character(name_input.text,draft_appearance,draft_images)
	if id.is_empty():
		name_error.text=game.character_saves.last_error
		return
	new_overlay.hide()
	draft_images.clear()
	select_character(id)
	note.text="角色已创建。选择「进入青茅山」开始游历；死亡后永久作废。"
	start_button.grab_focus()

func open_appearance() -> void:
	if appearance_button.disabled: return
	editing_new=false
	edit_target=selected_id
	appearance_editor.open(game.character_saves.appearance_for(edit_target),game.character_saves.art_directory(edit_target))

func _confirm_appearance(value: Dictionary, images: Dictionary) -> void:
	if editing_new:
		draft_appearance=value.duplicate(true)
		draft_images=images.duplicate()
		appearance_editor.hide()
		name_error.text="外观已选定，将随新角色一起保存。"
		create_confirm.grab_focus()
		return
	if not game.character_saves.update_appearance(edit_target,value,images):
		appearance_editor.message.text=game.character_saves.last_error
		return
	appearance_editor.hide()
	appearance_editor.images.clear()
	refresh()
	note.text="外观已保存。人物、衣服及动作将在本角色中使用。"
	appearance_button.grab_focus()

func open_delete() -> void:
	if selected_id.is_empty(): return
	delete_target=selected_id
	delete_text.text="确定删除「%s」？\n\n该角色的背包、蛊虫和世界进度将永久删除。\n其他角色不受影响。"%identity.text
	delete_overlay.show()
	delete_cancel.grab_focus()

func _delete() -> void:
	if not game.character_saves.delete_character(delete_target):
		delete_text.text=game.character_saves.last_error
		return
	delete_overlay.hide()
	selected_id=""
	refresh()
	game.character_saves.remember_selection(selected_id)
	note.text="角色存档已删除。可新建角色，或选择其他角色继续游历。"

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not game.start_layer.visible: return
	if appearance_editor!=null and appearance_editor.visible: return
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		new_overlay.hide()
		delete_overlay.hide()
		get_viewport().set_input_as_handled()
