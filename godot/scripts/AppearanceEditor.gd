class_name AppearanceEditor
extends Control

signal confirmed(data: Dictionary, images: Dictionary)
signal dismissed
var data := {}
var images := {}
var folder := ""
var preview: CharacterPreview
var controls := {}
var message: Label
var confirm_button: Button
var cancel_button: Button
var import_actor: Button
var import_outfit: Button
var file_dialog: FileDialog
var file_job := ""
var loading := false
var actor_info: Label
var outfit_info: Label

func _ready() -> void:
	UIStyle.fill(self)
	var shade:=ColorRect.new()
	shade.color=Color("0b1919")
	UIStyle.fill(shade)
	add_child(shade)
	var margin:=MarginContainer.new()
	UIStyle.fill(margin)
	for edge in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+edge,24)
	add_child(margin)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",12)
	margin.add_child(root)
	root.add_child(UIStyle.label("衣冠工坊  /  自定义角色",26,UIStyle.GOLD))
	root.add_child(UIStyle.label("设计衣装 · 导入人物与衣服 · 四方向动作预览",15,UIStyle.DIM))
	var columns:=HBoxContainer.new()
	columns.size_flags_vertical=SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",18)
	root.add_child(columns)
	var left:=UIStyle.card(columns)
	left.add_child(UIStyle.label("人物预览",19,UIStyle.GOLD))
	preview=CharacterPreview.new()
	preview.size_flags_vertical=SIZE_EXPAND_FILL
	preview.custom_minimum_size=Vector2(230,150)
	left.add_child(preview)
	var directions:=HBoxContainer.new()
	left.add_child(directions)
	for i in 4:
		var b:=UIStyle.button(["正面","左侧","背面","右侧"][i],func(): preview.facing=i)
		b.size_flags_horizontal=SIZE_EXPAND_FILL
		directions.add_child(b)
	var poses:=OptionButton.new()
	for title in ["站立","行走","攻击","施法","受伤","倒地"]: poses.add_item(title)
	poses.item_selected.connect(func(index: int): preview.pose=["idle","walk","strike","cast","hurt","death"][index]; preview.elapsed=2)
	poses.custom_minimum_size.y=34
	left.add_child(poses)
	controls["pose"]=poses
	left.add_child(UIStyle.label("仅改变外观，不增加属性或改变碰撞。",13,UIStyle.DIM))
	var scroll:=ScrollContainer.new()
	scroll.size_flags_horizontal=SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio=1.5
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(scroll)
	var right:=VBoxContainer.new()
	right.size_flags_horizontal=SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",9)
	scroll.add_child(right)
	_option(right,"base","外观来源",["原画主角","自定义衣装","导入人物"],["painted","tailored","imported"])
	_option(right,"style","衣服款式",["短打","交领长衫","对襟外袍"])
	_option(right,"hair_style","发型",["束发","长辫","披发"])
	for spec in [["height","身高"],["width","体型"],["hem","衣长"],["sleeve","袖宽"]]: _slider(right,spec[0],spec[1])
	var colors:=GridContainer.new()
	colors.columns=3
	colors.add_theme_constant_override("h_separation",8)
	colors.add_theme_constant_override("v_separation",8)
	right.add_child(colors)
	var titles:=["衣服","镶边","腰带","裤装","肤色","头发"]
	for i in CharacterAppearance.COLORS.size():
		var key:String=CharacterAppearance.COLORS[i]
		var column:=VBoxContainer.new()
		column.size_flags_horizontal=SIZE_EXPAND_FILL
		colors.add_child(column)
		column.add_child(UIStyle.label(titles[i],14,UIStyle.DIM))
		var picker:=ColorPickerButton.new()
		picker.edit_alpha=false
		picker.custom_minimum_size=Vector2(90,30)
		picker.color_changed.connect(func(value: Color): _change(key,value.to_html(false)))
		column.add_child(picker)
		controls[key]=picker
	var hint:=UIStyle.label("配色与衣形调整用于内置衣装。导入图集保留你画的颜色与形状。",13,UIStyle.DIM)
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	right.add_child(hint)
	right.add_child(HSeparator.new())
	right.add_child(UIStyle.label("导入 PNG 动作图集",19,UIStyle.GOLD))
	var spec:=UIStyle.label("6 列 × 4 行，透明背景，每格 32–256 像素。\n行：正面 / 左侧 / 背面 / 右侧\n列：站立 / 左步 / 右步 / 攻击 / 施法 / 倒地",14,UIStyle.DIM)
	right.add_child(spec)
	var imports:=HBoxContainer.new()
	right.add_child(imports)
	import_actor=UIStyle.button("导入整个人物…",func(): _choose("actor_asset"))
	import_outfit=UIStyle.button("导入衣服图层…",func(): _choose("outfit_asset"))
	for button in [import_actor,import_outfit]:
		button.size_flags_horizontal=SIZE_EXPAND_FILL
		imports.add_child(button)
	actor_info=UIStyle.label("",13,UIStyle.JADE)
	outfit_info=UIStyle.label("",13,UIStyle.JADE)
	right.add_child(actor_info)
	right.add_child(outfit_info)
	var removals:=HBoxContainer.new()
	right.add_child(removals)
	removals.add_child(UIStyle.button("移除导入人物",func(): _remove("actor_asset")))
	removals.add_child(UIStyle.button("移除导入衣服",func(): _remove("outfit_asset")))
	var templates:=HBoxContainer.new()
	right.add_child(templates)
	templates.add_child(UIStyle.button("导出人物模板…",func(): _choose("export_full")))
	templates.add_child(UIStyle.button("导出衣服模板…",func(): _choose("export_outfit")))
	right.add_child(UIStyle.button("恢复原画外观",func(): data=CharacterAppearance.DEFAULTS.duplicate(true); images.clear(); _sync()))
	message=UIStyle.label("",14,UIStyle.JADE)
	message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.y=38
	root.add_child(message)
	var actions:=HBoxContainer.new()
	root.add_child(actions)
	cancel_button=UIStyle.button("取消 · 保留原外观",cancel)
	confirm_button=UIStyle.button("确认外观",func(): confirmed.emit(data.duplicate(true),images.duplicate()))
	for button in [cancel_button,confirm_button]:
		button.custom_minimum_size.y=40
		button.size_flags_horizontal=SIZE_EXPAND_FILL
		actions.add_child(button)
	file_dialog=FileDialog.new()
	file_dialog.access=FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters=PackedStringArray(["*.png ; PNG 动作图集"])
	file_dialog.file_selected.connect(_file_selected)
	add_child(file_dialog)
	hide()

func open(value: Dictionary, art_folder: String = "", staged: Dictionary = {}) -> void:
	data=CharacterAppearance.normalize(value)
	folder=art_folder
	images=staged.duplicate()
	preview.pose="idle"
	preview.facing=0
	controls.pose.select(0)
	message.text="调整后点击确认保存；取消会放弃本次修改。"
	_sync()
	show()
	cancel_button.grab_focus()

func _option(parent: Node, key: String, title: String, labels: Array, values: Array = []) -> void:
	var row:=HBoxContainer.new()
	parent.add_child(row)
	var label:=UIStyle.label(title,15)
	label.custom_minimum_size.x=90
	row.add_child(label)
	var option:=OptionButton.new()
	option.size_flags_horizontal=SIZE_EXPAND_FILL
	option.custom_minimum_size.y=32
	for text in labels: option.add_item(text)
	option.item_selected.connect(func(index: int): _change(key,index if values.is_empty() else values[index]))
	row.add_child(option)
	controls[key]=option

func _slider(parent: Node, key: String, title: String) -> void:
	var row:=HBoxContainer.new()
	parent.add_child(row)
	var label:=UIStyle.label(title,15)
	label.custom_minimum_size.x=90
	row.add_child(label)
	var slider:=HSlider.new()
	slider.min_value=CharacterAppearance.LIMITS[key].x
	slider.max_value=CharacterAppearance.LIMITS[key].y
	slider.step=0.01
	slider.size_flags_horizontal=SIZE_EXPAND_FILL
	slider.custom_minimum_size.y=25
	slider.value_changed.connect(func(value: float): _change(key,value))
	row.add_child(slider)
	controls[key]=slider

func _change(key: String, value: Variant) -> void:
	if loading: return
	if key=="base" and value=="imported" and data.actor_asset=="" and not images.has("actor_asset"):
		message.text="请先点击「导入整个人物」选择 PNG 图集。"
		_sync()
		return
	data[key]=value
	if key!="base" and data.base=="painted": data.base="tailored"
	_sync()

func _sync() -> void:
	loading=true
	controls.base.select(["painted","tailored","imported"].find(data.base))
	for key in ["style","hair_style"]: controls[key].select(int(data[key]))
	for key in CharacterAppearance.LIMITS: controls[key].set_value_no_signal(data[key])
	for key in CharacterAppearance.COLORS: controls[key].color=Color(data[key])
	var imported_actor:bool=data.base=="imported"
	var imported_outfit:bool=data.base!="painted" and (data.outfit_asset!="" or images.has("outfit_asset"))
	controls.style.disabled=imported_actor or imported_outfit
	controls.hair_style.disabled=imported_actor
	for key in CharacterAppearance.LIMITS: controls[key].editable=not imported_actor and not imported_outfit
	for key in CharacterAppearance.COLORS:
		controls[key].disabled=imported_actor or (imported_outfit and key in ["cloth","trim","sash"])
	loading=false
	preview.show_appearance(data,folder,images)
	actor_info.text="人物："+("已导入 · 确认后保存在本角色" if images.has("actor_asset") else ("使用本角色已保存图集" if data.actor_asset!="" else "未导入"))
	outfit_info.text="衣服："+("已导入 · 叠加在人物上" if images.has("outfit_asset") else ("使用本角色已保存图集" if data.outfit_asset!="" else "使用内置衣装"))
	if preview.appearance.warning!="": message.text=preview.appearance.warning

func _choose(job: String) -> void:
	file_job=job
	file_dialog.file_mode=FileDialog.FILE_MODE_SAVE_FILE if job.begins_with("export_") else FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.title="导出可绘制模板" if job.begins_with("export_") else "选择人物 / 衣服动作图集"
	file_dialog.current_file=("character_template.png" if job=="export_full" else "outfit_template.png") if job.begins_with("export_") else ""
	file_dialog.popup_centered_ratio(0.78)

func _file_selected(path: String) -> void:
	if file_job.begins_with("export_"):
		var result:=export_template(path,file_job=="export_outfit")
		message.text="模板已导出："+path.get_file() if result==OK else "模板导出失败："+error_string(result)
	else: import_png(path,file_job)

func import_png(path: String, slot: String) -> bool:
	if slot not in ["actor_asset","outfit_asset"]: return false
	var result:=CharacterAppearance.read_png(path)
	if not result.has("image"):
		message.text=result.error
		return false
	images[slot]=result.image
	data[slot]=""
	if slot=="actor_asset": data.base="imported"
	elif data.base=="painted": data.base="tailored"
	message.text="已载入「%s」。可切换方向和动作检查，确认后保存。"%path.get_file()
	_sync()
	return true

func export_template(path: String, clothes_only: bool) -> Error:
	# Always export the editable rig, so separately exported layers share the same anchors.
	return CharacterAppearance.sheet(data,"outfit" if clothes_only else "full").save_png(path)

func _remove(slot: String) -> void:
	images.erase(slot)
	data[slot]=""
	if slot=="actor_asset" and data.base=="imported": data.base="tailored"
	message.text="已移除导入图层，确认后生效。"
	_sync()

func cancel() -> void:
	file_dialog.hide()
	images.clear()
	hide()
	dismissed.emit()

func _input(event: InputEvent) -> void:
	if visible and not file_dialog.visible and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		cancel()
		get_viewport().set_input_as_handled()
