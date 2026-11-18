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

func _ready() -> void:
	var cols:=HBoxContainer.new()
	UIStyle.fill(cols)
	cols.add_theme_constant_override("separation",16)
	add_child(cols)
	var left:=UIStyle.card(cols,430)
	var nav:=HBoxContainer.new()
	left.add_child(nav)
	for row in [["青茅山","local"],["五域示意","world"],["世界结构","dimensions"],["游历记录","notes"]]:
		nav.add_child(UIStyle.button(row[0],set_mode.bind(row[1])))
	atlas=AtlasMap.new()
	atlas.game=game
	atlas.custom_minimum_size=Vector2(430,280)
	atlas.size_flags_vertical=SIZE_EXPAND_FILL
	atlas.destination_selected.connect(_mark)
	left.add_child(atlas)
	world_atlas=WorldAtlas.new()
	world_atlas.size_flags_vertical=SIZE_EXPAND_FILL
	world_atlas.region_selected.connect(func(_id:String): refresh())
	left.add_child(world_atlas)
	dimensions=UIStyle.rich(16)
	left.add_child(dimensions)
	for d in WorldLore.DIMENSIONS:
		dimensions.text+="[color=#d8bc7c]"+d[0]+"[/color]\n"+d[1]+"\n\n"
	notes=UIStyle.rich(15)
	notes.meta_clicked.connect(_note_mark)
	left.add_child(notes)
	var right:=UIStyle.card(cols,270)
	right.add_child(UIStyle.label("地理志 · 青茅山前期",21,UIStyle.GOLD))
	info=UIStyle.rich(15)
	right.add_child(info)
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
	right.add_child(UIStyle.button("清除目的地",func():
		game.waypoint=Vector2.ZERO
		game.waypoint_name=""
		game.save_game()
		refresh()
	))
	visibility_changed.connect(refresh)
	refresh()

func set_mode(value: String) -> void:
	mode=value
	refresh()

func show_world() -> void:
	set_mode("world")

func _mark(pos: Vector2,title: String) -> void:
	game.waypoint=pos
	game.waypoint_name=title
	game.save_game()
	refresh()

func _note_mark(meta: Variant) -> void:
	for site in World.EXPLORATION_SITES:
		if site.id==String(meta):
			_mark(Vector2(site.pos)*World.TILE+Vector2(16,16),site.name)
			return

func _refresh_sites() -> void:
	for child in destination_buttons.get_children():
		destination_buttons.remove_child(child)
		child.queue_free()
	for h in World.HOUSE_DATA:
		if h.id in ["flower_cave","spring_cave"]: continue
		destination_buttons.add_child(UIStyle.button(h.name,_mark.bind(h.pos,h.name)))
	notes.text="[font_size=21][color=#d8bc7c]青茅山行记[/color][/font_size]\n靠近地点按 E 留下见闻；点击已知地点可标记。\n\n"
	for site in World.EXPLORATION_SITES:
		var pos:=Vector2(site.pos)*World.TILE+Vector2(16,16)
		var visited:bool=game.visited_sites.has(site.id)
		var known:bool=visited or game.fog.discovered(pos)
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

func refresh() -> void:
	if atlas==null: return
	atlas.visible=mode=="local"
	world_atlas.visible=mode=="world"
	dimensions.visible=mode=="dimensions"
	notes.visible=mode=="notes"
	destination_buttons.get_parent().visible=mode=="local"
	_refresh_sites()
	atlas.queue_redraw()
	world_atlas.queue_redraw()
	if mode=="world":
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
		info.text="南疆 › 青茅山 › "+(game.current_house_name if game.world.in_interior else game.world.zone_name(game.world.zone_at(pos)))+"\n\n160×120 格 · 自由探索\n三寨之外有溪谷、高岭与南麓林地；发现新地点后可标记前往，无剧情前置。\n\n点击地图设置步行指引；金色为建筑，青绿为探索点。"
		if game.waypoint!=Vector2.ZERO: info.text+="\n\n目的地："+game.waypoint_name
