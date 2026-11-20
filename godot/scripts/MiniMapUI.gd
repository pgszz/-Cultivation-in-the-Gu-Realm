class_name MiniMapUI
extends Control

var game: Node
var atlas: AtlasMap
var world_atlas: WorldAtlas
var dimensions: RichTextLabel
var notes: RichTextLabel
var info: RichTextLabel
var mode := "local"
var destination_buttons: VBoxContainer
var wildlife_view: ScrollContainer
var wildlife_rows: VBoxContainer
var map_tools: HBoxContainer
var map_help: Label
var zoom_label: Label
var clear_button: Button
var target_button: Button
var zoom_in: Button
var zoom_out: Button
var search: LineEdit
var layer_picker: OptionButton
var main_columns: HBoxContainer
var southern: SouthernBorderUI
var south_button: Button
var people_button: Button
var people_mark_buttons: Dictionary = {}

func _ready() -> void:
	var cols:=HBoxContainer.new()
	main_columns=cols
	UIStyle.fill(cols)
	cols.add_theme_constant_override("separation",16)
	add_child(cols)
	var left:=UIStyle.card(cols,430)
	left.get_parent().size_flags_stretch_ratio=2.5
	var nav:=HBoxContainer.new()
	left.add_child(nav)
	for row in [["青茅山","local"],["南疆地图","south"],["五域示意","world"],["世界结构","dimensions"],["游历记录","notes"]]:
		var button:=UIStyle.button(row[0],set_mode.bind(row[1]))
		nav.add_child(button)
		if row[1]=="south": south_button=button
	layer_picker=OptionButton.new()
	for title in TerrainLayers.NAMES: layer_picker.add_item(title)
	layer_picker.item_selected.connect(view_layer)
	left.add_child(layer_picker)
	map_tools=HBoxContainer.new()
	left.add_child(map_tools)
	atlas=AtlasMap.new()
	atlas.game=game
	atlas.custom_minimum_size=Vector2(430,280)
	atlas.size_flags_vertical=SIZE_EXPAND_FILL
	atlas.destination_selected.connect(_mark)
	atlas.destination_cleared.connect(_clear)
	atlas.view_changed.connect(_refresh_map_tools)
	left.add_child(atlas)
	zoom_out=UIStyle.button("－",func(): atlas.zoom_at(atlas.zoom/1.25,atlas.size*0.5))
	map_tools.add_child(zoom_out)
	zoom_label=UIStyle.label("100%",14,UIStyle.GOLD)
	zoom_label.custom_minimum_size.x=48
	zoom_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	map_tools.add_child(zoom_label)
	zoom_in=UIStyle.button("＋",func(): atlas.zoom_at(atlas.zoom*1.25,atlas.size*0.5))
	map_tools.add_child(zoom_in)
	map_tools.add_child(UIStyle.button("全图",func(): atlas.fit_world()))
	map_tools.add_child(UIStyle.button("我的位置",func(): view_layer(game.world.layer); atlas.focus_position(game.outdoor_return if game.world.in_interior else game.player.position)))
	target_button=UIStyle.button("定位标点",func(): view_layer(game.waypoint_layer); atlas.focus_position(game.waypoint))
	map_tools.add_child(target_button)
	var names:=CheckButton.new()
	names.text="地名"
	names.button_pressed=true
	names.add_theme_font_size_override("font_size",13)
	names.toggled.connect(func(value:bool): atlas.show_names=value; atlas.queue_redraw())
	map_tools.add_child(names)
	map_help=UIStyle.label("滚轮缩放 · 左/中键拖动 · 单击标点 · 再点或右键取消\n■ 建筑   ● 探索点   ▲ 营地   ○ 栖息地   虚线为方向指引",12,UIStyle.DIM)
	left.add_child(map_help)
	world_atlas=WorldAtlas.new()
	world_atlas.size_flags_vertical=SIZE_EXPAND_FILL
	world_atlas.region_selected.connect(func(_id:String): refresh())
	world_atlas.south_requested.connect(func(): set_mode("south"))
	left.add_child(world_atlas)
	dimensions=UIStyle.rich(16)
	left.add_child(dimensions)
	for d in WorldLore.DIMENSIONS:
		dimensions.text+="[color=#d8bc7c]"+d[0]+"[/color]\n"+d[1]+"\n\n"
	notes=UIStyle.rich(15)
	notes.meta_clicked.connect(_note_mark)
	left.add_child(notes)
	wildlife_view=ScrollContainer.new()
	wildlife_view.size_flags_vertical=SIZE_EXPAND_FILL
	wildlife_view.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(wildlife_view)
	wildlife_rows=VBoxContainer.new()
	wildlife_rows.size_flags_horizontal=SIZE_EXPAND_FILL
	wildlife_rows.add_theme_constant_override("separation",10)
	wildlife_view.add_child(wildlife_rows)
	var right:=UIStyle.card(cols,270)
	right.add_child(UIStyle.label("地理志 · 青茅山前期",21,UIStyle.GOLD))
	info=UIStyle.rich(15)
	right.add_child(info)
	search=LineEdit.new()
	search.placeholder_text="搜索已知地点…"
	search.text_changed.connect(func(_value:String): _filter_sites())
	right.add_child(search)
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=SIZE_EXPAND_FILL
	right.add_child(scroll)
	destination_buttons=VBoxContainer.new()
	destination_buttons.size_flags_horizontal=SIZE_EXPAND_FILL
	scroll.add_child(destination_buttons)
	right.add_child(UIStyle.button("山寨委托 · 查看进度",func():
		game.journal.close()
		game.village_ui.show_commissions()
	))
	people_button=UIStyle.button("青茅人物 · 原著形象",set_mode.bind("people"))
	right.add_child(people_button)
	var creature_nav:=HBoxContainer.new()
	right.add_child(creature_nav)
	for item in [["动物图鉴 · 7 种","wildlife"],["妖兽图鉴 · 2 种","beasts"]]:
		var button:=UIStyle.button(item[0],set_mode.bind(item[1]))
		button.size_flags_horizontal=SIZE_EXPAND_FILL
		creature_nav.add_child(button)
	clear_button=UIStyle.button("取消标点",_clear)
	right.add_child(clear_button)
	southern=SouthernBorderUI.new()
	southern.game=game
	southern.mode_requested.connect(set_mode)
	add_child(southern)
	UIStyle.fill(southern)
	southern.visible=false
	visibility_changed.connect(refresh)
	refresh()

func set_mode(value: String) -> void:
	mode=value
	refresh()

func show_world() -> void:
	set_mode("world")

func _mark(pos: Vector2,title: String) -> void:
	game.set_waypoint(pos,title,true,atlas.display_layer if mode=="local" else 0)
	refresh()

func view_layer(value: int) -> void:
	if atlas==null: return
	if atlas.display_layer!=value:
		atlas.display_layer=value
		atlas.fit_world()
	layer_picker.select(value)
	refresh()

func _clear() -> void:
	game.clear_waypoint()
	refresh()

func _refresh_map_tools() -> void:
	if zoom_label==null: return
	zoom_label.text="%.0f%%"%(atlas.zoom*100)
	zoom_in.disabled=atlas.zoom>=AtlasMap.MAX_ZOOM
	zoom_out.disabled=atlas.zoom<=AtlasMap.MIN_ZOOM
	target_button.disabled=game.waypoint==Vector2.ZERO

func _filter_sites() -> void:
	for button in destination_buttons.get_children():
		button.visible=search.text.strip_edges().is_empty() or button.text.contains(search.text.strip_edges())

func _note_mark(meta: Variant) -> void:
	for site in World.EXPLORATION_SITES:
		if site.id==String(meta):
			view_layer(0)
			_mark(Vector2(site.pos)*World.TILE+Vector2(16,16),site.name)
			return

func _refresh_sites() -> void:
	for child in destination_buttons.get_children():
		destination_buttons.remove_child(child)
		child.queue_free()
	for portal in game.world.blocks.portals(atlas.display_layer):
		destination_buttons.add_child(UIStyle.button("⇅ "+portal.name,_mark.bind(portal.pos,portal.name)))
	if atlas.display_layer>0:
		notes.text="地下行记 · 靠近石台按 E 留下见闻。\n\n"
		for site in TerrainLayers.SITES:
			if site.layer!=atlas.display_layer or not game.fog.discovered_on(site.pos,site.layer): continue
			var known:bool=game.world.blocks.visited.has(site.id)
			destination_buttons.add_child(UIStyle.button(("✓ " if known else "◇ ")+site.name,_mark.bind(site.pos,site.name)))
			notes.text+=site.name+"\n"+(site.text if known else "尚未踏查")+"\n\n"
		_filter_sites()
		return
	for h in World.HOUSE_DATA:
		if h.id in ["flower_cave","spring_cave"]: continue
		destination_buttons.add_child(UIStyle.button(h.name,_mark.bind(h.pos+Vector2(0,40),h.name)))
	notes.text="[font_size=21][color=#d8bc7c]青茅山行记[/color][/font_size]\n靠近地点按 E 留下见闻；点击已知地点可标记。\n\n"
	for site in World.EXPLORATION_SITES:
		var pos:=Vector2(site.pos)*World.TILE+Vector2(16,16)
		var visited:bool=game.visited_sites.has(site.id)
		var known:bool=visited or game.fog.discovered_on(pos,0)
		if not known:
			notes.text+="[color=#74887e]未发现的山路见闻[/color]\n\n"
			continue
		notes.text+="[url=%s][color=#d8bc7c]%s[/color][/url] · %s\n"%[site.id,site.name,"已踏查" if visited else "待踏查"]
		if visited: notes.text+=site.text+"\n"
		if site.kind=="camp":
			notes.text+="补给已领取 · 仍可包扎与打坐" if game.claimed_camps.has(site.id) else "营地补给尚未领取 · 可包扎与打坐"
		elif site.kind in ["timber","rubble"]:
			var seconds:float=game.poi_cd.get(site.id,0)
			notes.text+="散落材料可采集" if seconds<=0 else "材料恢复还需 %d 秒游玩时间"%ceili(seconds)
		else: notes.text+="山路观景点 · 自由踏查"
		notes.text+="\n\n"
		destination_buttons.add_child(UIStyle.button(("✓ " if visited else "◇ ")+site.name,_mark.bind(pos,site.name)))
	_filter_sites()

func refresh() -> void:
	if atlas==null: return
	main_columns.visible=mode!="south"
	if southern!=null: southern.visible=mode=="south"
	if mode=="south": return
	atlas.visible=mode=="local"
	map_tools.visible=mode=="local"
	layer_picker.visible=mode=="local"
	map_help.visible=mode=="local"
	search.visible=mode=="local"
	clear_button.disabled=game.waypoint==Vector2.ZERO
	_refresh_map_tools()
	world_atlas.visible=mode=="world"
	dimensions.visible=mode=="dimensions"
	notes.visible=mode=="notes"
	wildlife_view.visible=mode in ["wildlife","beasts","people"]
	if mode=="people": _refresh_people()
	elif wildlife_view.visible: _refresh_wildlife()
	destination_buttons.get_parent().visible=mode=="local"
	_refresh_sites()
	atlas.queue_redraw()
	world_atlas.queue_redraw()
	if mode=="people":
		info.text="[color=#d8bc7c]青茅山关键人物[/color]\n\n方源、方正、白凝冰、青书。\n\n外貌依照正文；衣纹、部分配色和动作是美术补充。点击人物旁的「原著依据」查看章节。\n\n标记的是常去区域，人物会沿附近道路行走。抵达后靠近按 E 交谈，或 Alt + 左键查看。\n\n日程与对话为自由探索改编，不强制复演小说。"
	elif mode in ["wildlife","beasts"]:
		info.text="[color=#d8bc7c]普通动物 · 七种[/color]\n\n野兔、鹿、狼、黑熊、野猪、赤狐与山雉。\n\n从幼年长成亚成体、成年，体型和力量随之增长。动物没有修炼阶段，也不会自动变成妖兽。\n\n胆小动物遇人逃离；狼会追击；黑熊、野猪守地反击。" if mode=="wildlife" else "[color=#df8775]妖兽 · 两种[/color]\n\n青狼妖、铁背妖熊是独立妖兽物种。\n\n成年后在巢域内安静、健康时自行修炼。靠近、受伤和异常状态会打断。\n\n阶段：初醒 → 凝息 → 强健 → 精壮。累计修炼 3 / 8 / 15 分钟，各次提升基础力量 18%，不会无限增强。\n\n妖兽与修炼阶段为本作沙盒设计。"
		info.text+="\n\n各自栖息地限量补充，空缺冷却后只在视野外出现幼体。\n生长、修炼与冷却仅计算室外游玩时间，菜单、室内与离线暂停。"
		if game.waypoint!=Vector2.ZERO: info.text+="\n\n目的地："+game.waypoint_name
	elif mode=="world":
		var d:Dictionary=WorldLore.REGIONS[world_atlas.selected]
		info.text="[color=#d8bc7c]"+d.name+"[/color]\n\n"+d.text+"\n\n这是一张方位示意图，不能点击传送。其他四域尚未建设。"
	elif mode=="dimensions":
		info.text="时间基准：青茅山前期\n\n界壁尚存，黑白两天轮转。\n\n魂魄、生死门、光阴长河不是三个可随意进出的复活界面。\n\n未开放的领域只提供设定说明。"
	elif mode=="notes":
		var count:=0
		for site in World.EXPLORATION_SITES:
			if game.visited_sites.has(site.id): count+=1
		info.text="已踏查 %d / %d 处\n\n山路见闻可用于可选委托，先前的游历同样有效。\n\n探索与采集无需先接委托。补给进入背包，普通物品不能存入空窍。"%[count,World.EXPLORATION_SITES.size()]
		if game.waypoint!=Vector2.ZERO: info.text+="\n\n目的地："+game.waypoint_name
	else:
		var pos:Vector2=game.outdoor_return if game.world.in_interior else game.player.position
		info.text="[color=#d8bc7c]青茅山 · %d×%d 格[/color]\n当前位置：%s\n探索点 %d / %d · 每格约一步\n"%[GameData.MAP_W,GameData.MAP_H,game.current_house_name if game.world.in_interior else game.world.zone_name(game.world.zone_at(pos)),game.visited_sites.size(),World.EXPLORATION_SITES.size()]
		var size:=TerrainLayers.size_for(atlas.display_layer)
		info.text="[color=#d8bc7c]%s · %d×%d 格[/color]\n当前所在：%s\n\n切换此处只查看地图。地穴和石阶附近按 E 往返。\n"%[TerrainLayers.NAMES[atlas.display_layer],size.x,size.y,TerrainLayers.NAMES[game.world.layer]]
		if game.waypoint!=Vector2.ZERO:
			var guidance:Dictionary=game.waypoint_guidance()
			if guidance.transition!="": info.text+="\n先到"+guidance.transition+"，按 E。\n"
			info.text+="\n[color=#d8bc7c]标点：%s[/color]\n%s · %.0f 步\n%s"%[game.waypoint_name,guidance.direction,guidance.steps,"先前往出口，按 E 离开" if game.world.in_interior else ("已到达附近；探索点仍需按 E 踏查" if guidance.arrived else "沿山路前往；虚线不代表可穿越障碍")]
		else: info.text+="\n点击地图或下方地点添加标点。\n关闭山志后显示方向、距离和到达提示。"


func _refresh_people() -> void:
	for child in wildlife_rows.get_children():
		wildlife_rows.remove_child(child)
		child.queue_free()
	people_mark_buttons.clear()
	for id in CanonPeople.ORDER:
		var data:Dictionary=CanonPeople.PEOPLE[id]
		var row:=HBoxContainer.new()
		row.add_theme_constant_override("separation",12)
		wildlife_rows.add_child(row)
		var portrait:=GuArt.portrait(112)
		portrait.texture=NpcAppearance.portrait(id)
		row.add_child(portrait)
		var details:=VBoxContainer.new()
		details.size_flags_horizontal=SIZE_EXPAND_FILL
		row.add_child(details)
		details.add_child(UIStyle.label(data.name,21,UIStyle.GOLD))
		var text:=UIStyle.label(data.period+"\n"+data.look,14,UIStyle.INK)
		text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		details.add_child(text)
		var actions:=HBoxContainer.new()
		details.add_child(actions)
		var mark:=UIStyle.button("标记常去区域",_mark_person.bind(id))
		mark.name="Mark_"+id
		actions.add_child(mark)
		people_mark_buttons[id]=mark
		actions.add_child(UIStyle.button("原著依据",_show_person_lore.bind(id)))

func _show_person_lore(id: String) -> void:
	info.text=CanonPeople.lore(id)
	info.scroll_to_line(0)

func _mark_person(id: String) -> void:
	var data:Dictionary=CanonPeople.PEOPLE[id]
	mode="local"
	view_layer(0)
	_mark(data.home,data.stops[0]+" · "+data.name)
	atlas.focus_position(data.home)

func _refresh_wildlife() -> void:
	for child in wildlife_rows.get_children():
		wildlife_rows.remove_child(child)
		child.queue_free()
	for habitat in WildlifeSystem.HABITATS:
		if MonsterSystem.WILDLIFE.has(habitat.species)!=(mode=="beasts"): continue
		var data:=WildlifeSystem.species_data(habitat.species)
		var row:=HBoxContainer.new()
		row.add_theme_constant_override("separation",12)
		wildlife_rows.add_child(row)
		var portrait:=GuArt.portrait(104)
		portrait.texture=WildlifeArt.texture(habitat.species)
		row.add_child(portrait)
		var details:=VBoxContainer.new()
		details.size_flags_horizontal=SIZE_EXPAND_FILL
		row.add_child(details)
		details.add_child(UIStyle.label(data.name+(" · 妖兽" if data.is_monster else " · 动物"),18,UIStyle.GOLD))
		var summary:=UIStyle.label("%s · 上限 %d 只\n幼年至成年约 %d 分钟\n空缺冷却 %d 分钟"%[habitat.name,habitat.capacity,int(data.mature/60),int(habitat.cooldown/60)],13,UIStyle.DIM)
		summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		details.add_child(summary)
		var temper:Dictionary={"timid":"胆小，遇人逃离","territorial":"守护领地，近身或受击反击","aggressive":"领地内主动追击"}
		var behavior:=UIStyle.label(temper[data.temper],12,UIStyle.INK)
		behavior.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		details.add_child(behavior)
		details.add_child(UIStyle.button("标记栖息地 (%d, %d)"%[habitat.tile.x,habitat.tile.y],_mark.bind(WildlifeSystem.center(habitat),habitat.name)))
