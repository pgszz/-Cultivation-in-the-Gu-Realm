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
var list_scroll: ScrollContainer
var search: LineEdit
var category: OptionButton
var rank_filter: OptionButton


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

	var filters:=HBoxContainer.new()
	vb.add_child(filters)
	search=LineEdit.new()
	search.placeholder_text="搜索已发现蛊虫"
	search.clear_button_enabled=true
	search.size_flags_horizontal=SIZE_EXPAND_FILL
	search.text_changed.connect(func(_text:String): _apply_filter())
	filters.add_child(search)
	category=OptionButton.new()
	for label in ["全部","攻击","防御","力量","移动","辅助","治疗","侦察","控制","生计","资质","修炼","肉身"]: category.add_item(label)
	category.item_selected.connect(func(_index:int): _apply_filter())
	filters.add_child(category)
	rank_filter=OptionButton.new()
	for text in ["全部转数","一转","二转","三转","四转","五转"]: rank_filter.add_item(text)
	rank_filter.item_selected.connect(func(_index:int): _apply_filter())
	filters.add_child(rank_filter)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	vb.add_child(body)

	var scroll := ScrollContainer.new()
	list_scroll=scroll
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
	portrait=GuArt.portrait(112)
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
		b.custom_minimum_size = Vector2(220, 52)
		b.add_theme_font_size_override("font_size", 12)
		b.text = String(g["name"])
		GuArt.decorate(b,id,38)
		b.pressed.connect(_show_detail.bind(id))
		grid.add_child(b)
		_buttons[id] = b

	var hope:=UIStyle.button("希望蛊 · 开窍消耗\n转数与稀有度未定",_show_detail.bind("hope_gu"))
	GuArt.decorate(hope,"hope_gu",38)
	hope.custom_minimum_size=Vector2(220,52)
	hope.add_theme_font_size_override("font_size",12)
	grid.add_child(hope)
	grid.move_child(hope,0)
	_buttons["hope_gu"]=hope
	vb.add_child(UIStyle.label("原创生成插画 · 原著外形参考与美术推导详见素材说明",11,UIStyle.DIM))

func refresh() -> void:
	var discovered: Array = player.discovered if player != null else []
	count_label.text = "    已发现 %d / %d · 希望蛊开窍指引" % [discovered.filter(func(id): return GameData.GU.has(id)).size(), GameData.GU_ORDER.size()]
	for id in GameData.GU_ORDER:
		var b: Button = _buttons.get(id)
		if b == null:
			continue
		var g: Dictionary = GameData.GU[id]
		if discovered.has(id):
			b.text = "%s · %d转\n%s" % [g.name,g.rank,GuProgression.rarity(id)]
			b.icon=GuArt.texture(id)
			b.modulate = Color.WHITE
		else:
			b.text = "？？？"
			b.icon=null
			b.modulate = Color(0.55, 0.55, 0.55)
	if selected_id == "":
		selected_id="hope_gu"
		if player!=null and player.aperture.is_open():
			for id in GameData.GU_ORDER:
				if discovered.has(id):
					selected_id=id
					break
	_show_detail(selected_id)
	_apply_filter()

func _apply_filter() -> void:
	if search==null or category==null: return
	var query:=search.text.strip_edges()
	var group:=category.get_item_text(category.selected)
	var show_hope:bool=(query=="" or "希望蛊".contains(query)) and group in ["全部","辅助"] and rank_filter.selected==0
	_buttons.hope_gu.visible=show_hope
	var first:="hope_gu" if show_hope else ""
	for id in GameData.GU_ORDER:
		var known:bool=player!=null and player.discovered.has(id)
		var shown:bool=(query=="" or (known and String(GameData.GU[id].name).contains(query))) and (group=="全部" or GameData.gu_category(id)==group)
		shown=shown and (rank_filter.selected==0 or int(GameData.GU[id].rank)==rank_filter.selected)
		_buttons[id].visible=shown
		if shown and first=="": first=id
	if first=="":
		portrait.texture=null
		detail.text="没有匹配的蛊虫。可清空搜索或切换分类。"
	elif selected_id=="" or not _buttons[selected_id].visible:
		_show_detail(first)
	else:
		_show_detail(selected_id)


func _show_detail(id: String) -> void:
	selected_id = id
	if id=="hope_gu":
		portrait.texture=GuArt.texture("hope_gu")
		detail.text="[color=#d8bc7c]希望蛊 · 开窍消耗[/color]\n"+AwakeningUI.HOPE_TEXT+"\n\n[color=#d8bc7c]使用方式[/color]\n凡人到古月地下溶洞，走近月兰花海按 E，引动希望蛊。无需真元，完成开窍后成为一转初阶。\n\n资质丁/丙/乙/甲对应元海20–39%/40–59%/60–79%/80–99%。创建时随机固定；这是本版玩法分布，不是原著概率。\n\n依据：第一卷第5–7章。开窍后无法重复使用来提升资质。"
		return
	var g: Dictionary = GameData.GU[id]
	var discovered: Array = player.discovered if player != null else []
	portrait.texture=GuArt.texture(id) if discovered.has(id) else null
	if not discovered.has(id):
		detail.text = "[color=#8fa38a]尚未发现[/color]\n\n取得这种蛊后，图鉴才会解锁。"
		return
	var sk: Dictionary = g["skill"]
	detail.text=GuProgression.detail(id,player.aperture.stage if player!=null else 0,player.aperture.rank if player!=null else 1)
	detail.text+="\n\n[color=#5fbf6a]【%s】[/color]\n%s\n食物：%s" % [sk.name,g.flavor,FoodSystem.GRAINS[g.preferred_food].name]
	var care:Dictionary={
		"moon_blade":"月兰花瓣 · 每日四片\n取得：完成希望蛊开窍后获入门补给，或在商铺购买；需先炼化。",
		"jiu_chong":"青竹酒 · 一坛供四天\n取得：带酒探索后山巨石缝隙内的密洞。",
		"jade_skin":"玉石 · 二两供十天\n取得：古月商铺，500 元石。",
		"little_light":"专用供养 · 暂按一日份模拟，具体食材未核实\n取得：古月商铺，60 元石。需先炼化，再开启辅光并催月刃。",
		"white_boar":"猪肉 · 一头成年猪的肉供五天\n取得：古月商铺，600 元石。静处绑定快捷位催动养力；C 查看永久力量。",
		"black_boar":"猪肉 · 一头成年猪的肉供五天\n取得：古月商铺，600 元石，仅一只。与白豕共用身体进度与每日安全量，不可换蛊绕过。",
	}
	var care_text:String=care.get(id,"")
	if GameData.is_utility_gu(id):
		care_text="%s · 一游戏日一份，三寨商铺均售 1 元石。\n蛊虫取得：%s · %d 元石；先购买放入行囊，再 R 炼化、Q 绑定。\n%s；食性、外形与数值为本作设计，非原著配方。" % [FoodSystem.GRAINS[g.preferred_food].name,GameData.shop_name(id),GameData.GU_SHOP[id],g.origin]
	if GameData.GU_SHOP.has(id): care_text+="\n本版商铺总库存 %d 只；含升炼备料，不代表原著稀有度。" % int(GuProgression.SHOP_LIMITS.get(id,1))
	if GuProgression.RECIPES.has(id): care_text="修行录 → 炼蛊，按已核对路线合炼取得。白玉食玉每二十日八两；月芒、月霓裳暂用专用供养，古月商铺出售。"
	if GameData.EXPANSION_GU.has(id):
		care_text="专用供养 · 一日份（模拟）\n具体食材尚待原著核实。古月商铺售价 %d 元石，每种一只；先放背包，再 R 炼化、Q 绑定。供养每份 1 元石。" % int(GameData.GU_SHOP[id])
	detail.text+="\n\n[color=#d8bc7c]供养与取得[/color]\n"+care_text
	if id in ["beast_skin","dragon_cricket"]: detail.text+="\n\n[color=#93a99f]外形细节为同系或名称基础上的美术推导，不是完整原文描述。[/color]"

	if id=="jade_skin": detail.text+="\n\n[color=#93a99f]美术推导：参考皮蛊同系的扁宽外形，以及玉皮的翠绿护体效果。[/color]"
	if id=="black_boar": detail.text+="\n\n[color=#93a99f]美术推导：采用同系甲虫轮廓与黑色甲壳。商铺上架与共享养力上限是试玩安排。[/color]"
