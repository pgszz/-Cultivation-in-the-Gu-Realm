class_name SouthernBorderUI
extends Control

signal mode_requested(mode: String)
var game: Node
var map: SouthernBorderMap
var detail: RichTextLabel
var search: LineEdit
var filter: OptionButton
var rows: VBoxContainer
var zoom_label: Label
var zoom_in: Button
var zoom_out: Button
var local_button: Button
var shang_button: Button
var source_back: Button
var route_toggle: CheckButton
var clan_toggle: CheckButton
var selected_key := "qingmao"

func _ready() -> void:
	var layout:=VBoxContainer.new()
	UIStyle.fill(layout)
	add_child(layout)
	var nav:=HBoxContainer.new()
	layout.add_child(nav)
	nav.add_child(UIStyle.button("← 青茅山",func(): mode_requested.emit("local")))
	nav.add_child(UIStyle.button("五域示意",func(): mode_requested.emit("world")))
	var title:=UIStyle.label("南疆山川与家族",20,UIStyle.GOLD)
	title.size_flags_horizontal=SIZE_EXPAND_FILL
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	nav.add_child(title)
	var cols:=HBoxContainer.new()
	cols.add_theme_constant_override("separation",12)
	cols.size_flags_vertical=SIZE_EXPAND_FILL
	layout.add_child(cols)
	var left:=UIStyle.card(cols,420)
	left.get_parent().size_flags_stretch_ratio=2.2
	var controls:=HBoxContainer.new()
	left.add_child(controls)
	map=SouthernBorderMap.new()
	map.size_flags_vertical=SIZE_EXPAND_FILL
	map.selected.connect(func(key:String): select_entry(key,false))
	map.view_changed.connect(_refresh_zoom)
	zoom_out=UIStyle.button("－",func(): map.zoom_at(map.zoom/1.25,map.size*0.5))
	controls.add_child(zoom_out)
	zoom_label=UIStyle.label("100%",14,UIStyle.GOLD)
	zoom_label.custom_minimum_size.x=48
	controls.add_child(zoom_label)
	zoom_in=UIStyle.button("＋",func(): map.zoom_at(map.zoom*1.25,map.size*0.5))
	controls.add_child(zoom_in)
	controls.add_child(UIStyle.button("全图",func(): map.fit_map()))
	route_toggle=CheckButton.new()
	route_toggle.text="推演商路"
	route_toggle.button_pressed=true
	route_toggle.add_theme_font_size_override("font_size",13)
	route_toggle.toggled.connect(func(value:bool): map.show_routes=value; map.queue_redraw())
	controls.add_child(route_toggle)
	var names:=CheckButton.new()
	names.text="地名"
	names.button_pressed=true
	names.add_theme_font_size_override("font_size",13)
	names.toggled.connect(func(value:bool): map.show_names=value; map.queue_redraw())
	controls.add_child(names)
	clan_toggle=CheckButton.new()
	clan_toggle.text="家族"
	clan_toggle.button_pressed=true
	clan_toggle.add_theme_font_size_override("font_size",13)
	clan_toggle.toggled.connect(func(value:bool): map.show_clans=value; map.queue_redraw())
	controls.add_child(clan_toggle)
	left.add_child(map)
	var legend:=UIStyle.label("● 相对关系有据   ◇ 落点推演   ┄ 商路推演\n滚轮缩放 · 左/中键拖动 · 点选地名查看",12,UIStyle.DIM)
	left.add_child(legend)
	var right:=UIStyle.card(cols,300)
	var summary:=UIStyle.label("%d 处山川 · %d 家族"%[SouthernBorderData.SITES.size(),SouthernBorderData.CLANS.size()],16,UIStyle.GOLD)
	right.add_child(summary)
	var search_row:=HBoxContainer.new()
	right.add_child(search_row)
	filter=OptionButton.new()
	for title_text in ["全部","山川地点","超级家族","其他家族","位置待考"]: filter.add_item(title_text)
	filter.item_selected.connect(func(_index:int): refresh_rows())
	search_row.add_child(filter)
	search=LineEdit.new()
	search.placeholder_text="地名 / 家族…"
	search.size_flags_horizontal=SIZE_EXPAND_FILL
	search.text_changed.connect(func(_text:String): refresh_rows())
	search_row.add_child(search)
	var scroll:=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y=82
	scroll.size_flags_vertical=SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio=0.65
	right.add_child(scroll)
	rows=VBoxContainer.new()
	rows.size_flags_horizontal=SIZE_EXPAND_FILL
	scroll.add_child(rows)
	detail=UIStyle.rich(14)
	detail.size_flags_stretch_ratio=1.8
	detail.meta_clicked.connect(_meta)
	right.add_child(detail)
	source_back=UIStyle.button("返回条目",func(): select_entry(selected_key,false))
	source_back.visible=false
	right.add_child(source_back)
	local_button=UIStyle.button("查看青茅山本地地图",show_local)
	right.add_child(local_button)
	shang_button=UIStyle.button("游历商家城 · 演武 / 赌石",func(): game.shang_city.ui.open("travel"))
	shang_button.name="TravelShang"
	right.add_child(shang_button)
	var footer:=UIStyle.label("青茅山前期 · 商家城开放沙盒商区；其余远方地点为地理志",12,UIStyle.DIM)
	footer.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(footer)
	refresh_rows()
	select_entry(selected_key,false)
	_refresh_zoom()

func _refresh_zoom() -> void:
	if zoom_label==null: return
	zoom_label.text="%.0f%%"%(map.zoom*100)
	zoom_out.disabled=map.zoom<=1
	zoom_in.disabled=map.zoom>=5

func refresh_rows() -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	if filter.selected in [0,1]:
		for row in SouthernBorderData.SITES:
			if SouthernBorderData.matches(row,search.text): _row(row.id,row.name+" · "+row.kind)
	if filter.selected!=1:
		for row in SouthernBorderData.CLANS:
			if filter.selected==2 and row.tier!="超级家族": continue
			if filter.selected==3 and row.tier=="超级家族": continue
			if filter.selected==4 and row.site!="": continue
			if SouthernBorderData.matches(row,search.text): _row("clan:"+row.id,row.name+" · "+("位置待考" if row.site=="" else row.tier))
	if rows.get_child_count()==0: rows.add_child(UIStyle.label("没有匹配条目",14,UIStyle.DIM))

func _row(key: String, title: String) -> void:
	var button:=UIStyle.button(title,select_entry.bind(key,true))
	button.name="Entry_"+key.replace(":","_")
	button.alignment=HORIZONTAL_ALIGNMENT_LEFT
	button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	button.tooltip_text=title
	button.set_meta("entry",key)
	rows.add_child(button)

func select_entry(key: String, focus: bool = true) -> void:
	if SouthernBorderData.entry(key).is_empty(): return
	selected_key=key
	detail.text=SouthernBorderData.detail(key)
	detail.scroll_to_line(0)
	source_back.visible=false
	var site:=SouthernBorderData.focus_site(key)
	if focus and site!="": map.focus_site(site)
	else:
		map.selected_site=site
		map.queue_redraw()
	local_button.visible=SouthernBorderData.entry(key).has("local")
	shang_button.visible=site=="shangliang"
	for child in rows.get_children():
		if child is Button: child.modulate=UIStyle.GOLD if child.get_meta("entry","")==key else Color.WHITE

func _meta(value: Variant) -> void:
	var key:=String(value)
	if key.begins_with("source:"):
		var id:=key.trim_prefix("source:")
		if not SouthernBorderData.SOURCES.has(id): return
		var source:Dictionary=SouthernBorderData.SOURCES[id]
		detail.text="[color=#d8bc7c]%s[/color]\n%s\n\n%s\n\n来源可作正文核对；镜像站可能有排版和可达性变化。\n\n[url=external:%s]在浏览器查看来源[/url]"%[source.title,source.kind,source.scope,id]
		detail.scroll_to_line(0)
		source_back.visible=true
	elif key.begins_with("external:"):
		var id:=key.trim_prefix("external:")
		if SouthernBorderData.SOURCES.has(id): OS.shell_open(SouthernBorderData.SOURCES[id].url)
	elif key.begins_with("site:"): select_entry(key.trim_prefix("site:"))
	elif key.begins_with("clan:"): select_entry(key)

func show_local() -> void:
	var row:=SouthernBorderData.entry(selected_key)
	if not row.has("local"): return
	game.minimap_ui.view_layer(0)
	mode_requested.emit("local")
	var point:=Vector2(512,1000)
	if row.get("local","")=="bai": point=GameData.BAI_VILLAGE
	elif row.get("local","")=="xiong": point=GameData.XIONG_VILLAGE
	game.minimap_ui.atlas.focus_position(point)
