class_name CompendiumUI
extends Control

## 已接入蛊虫的图片与用养说明。

var player: Player
var grid: GridContainer
var count_label: Label
var detail: RichTextLabel
var portrait: TextureRect
var _buttons := {}
var selected_id := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	refresh()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.04, 0.025, 0.48)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel",UIStyle.box(Color("102321"),Color("72816a")))
	var arrange:=func():
		var mx:=maxf(18,(size.x-850)/2)
		var my:=maxf(18,(size.y-460)/2)
		panel.offset_left=mx
		panel.offset_right=-mx
		panel.offset_top=my
		panel.offset_bottom=-my
	resized.connect(arrange)
	arrange.call()
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 16
	vb.offset_top = 12
	vb.offset_right = -16
	vb.offset_bottom = -12
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	var header := HBoxContainer.new()
	vb.add_child(header)
	var title := Label.new()
	title.text = "蛊 虫 图 鉴"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#d9c46a"))
	header.add_child(title)
	count_label = Label.new()
	count_label.add_theme_font_size_override("font_size", 13)
	count_label.add_theme_color_override("font_color", Color("#8fa38a"))
	header.add_child(count_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close := Button.new()
	close.text = "关闭（K）"
	close.pressed.connect(hide)
	header.add_child(close)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	vb.add_child(body)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(240, 0)
	body.add_child(scroll)
	grid = GridContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.columns = 1
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	portrait=GuArt.portrait(160)
	right.add_child(portrait)
	detail = RichTextLabel.new()
	detail.bbcode_enabled = true
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.fit_content = false
	detail.scroll_active = true
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.custom_minimum_size = Vector2(300, 0)
	detail.add_theme_font_size_override("normal_font_size", 15)
	right.add_child(detail)

	for id in GameData.GU_ORDER:
		var g: Dictionary = GameData.GU[id]
		var b := UIStyle.button("")
		b.custom_minimum_size = Vector2(220, 74)
		b.add_theme_font_size_override("font_size", 12)
		b.text = String(g["name"])
		GuArt.decorate(b,id,50)
		b.pressed.connect(_show_detail.bind(id))
		grid.add_child(b)
		_buttons[id] = b

	vb.add_child(UIStyle.label("原创生成插画 · 原著外形参考与美术推导详见素材说明",11,UIStyle.DIM))

func refresh() -> void:
	var discovered: Array = player.discovered if player != null else []
	count_label.text = "    已发现 %d / %d" % [discovered.size(), GameData.GU_ORDER.size()]
	for id in GameData.GU_ORDER:
		var b: Button = _buttons.get(id)
		if b == null:
			continue
		var g: Dictionary = GameData.GU[id]
		if discovered.has(id):
			b.text = String(g["name"])
			b.icon=GuArt.texture(id)
			b.modulate = Color.WHITE
		else:
			b.text = "？？？"
			b.icon=null
			b.modulate = Color(0.55, 0.55, 0.55)
	if selected_id == "":
		selected_id = GameData.GU_ORDER[0]
	_show_detail(selected_id)


func _show_detail(id: String) -> void:
	selected_id = id
	var g: Dictionary = GameData.GU[id]
	var discovered: Array = player.discovered if player != null else []
	portrait.texture=GuArt.texture(id) if discovered.has(id) else null
	if not discovered.has(id):
		detail.text = "[color=#8fa38a]尚未发现[/color]\n\n取得这种蛊后，图鉴才会解锁。"
		return
	var sk: Dictionary = g["skill"]
	detail.text = "[font_size=20][color=#d9c46a]%s[/color][/font_size]\n" % g["name"]
	detail.text += "[color=#8fa38a]%d 转 · 食物：%s[/color]\n\n" % [g.rank,FoodSystem.GRAINS[g.preferred_food].name]
	detail.text += "[color=#5fbf6a]【%s】[/color]\n" % sk["name"]
	detail.text += "%s\n\n" % g["flavor"]
	detail.text += "[color=#8fa38a]"+GameData.activation_hint(id,player.aperture.stage if player!=null else 0)+"[/color]"
	var care:Dictionary={
		"moon_blade":"月兰花瓣 · 每日四片\n取得：开局行囊携带，需先炼化。",
		"jiu_chong":"青竹酒 · 一坛供四天\n取得：带酒探索后山巨石缝隙内的密洞。",
		"jade_skin":"玉石 · 二两供十天\n取得：古月商铺单只库存，500 元石。",
	}
	detail.text+="\n\n[color=#d8bc7c]供养与取得[/color]\n"+care.get(id,"")

	if id=="jade_skin": detail.text+="\n\n[color=#93a99f]美术推导：参考皮蛊同系的扁宽外形，以及玉皮的翠绿护体效果。[/color]"
