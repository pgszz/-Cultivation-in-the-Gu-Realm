class_name JournalUI
extends Control

var game: Node
var pages: Dictionary={}
var tabs: Dictionary={}
var active_page:="character"
var header: Label
var footer: Label
var panel: PanelContainer

func _ready()->void:
	UIStyle.fill(self)
	mouse_filter=MOUSE_FILTER_STOP
	var dim:=ColorRect.new()
	dim.color=Color(0.015,0.04,0.04,0.45)
	UIStyle.fill(dim)
	add_child(dim)
	panel=PanelContainer.new()
	UIStyle.fill(panel)
	resized.connect(_layout_panel)
	_layout_panel()
	panel.add_theme_stylebox_override("panel",UIStyle.box(Color("102321"),Color("72816a"),12))
	add_child(panel)
	var layout:=VBoxContainer.new()
	layout.add_theme_constant_override("separation",8)
	panel.add_child(layout)
	var top:=HBoxContainer.new()
	layout.add_child(top)
	top.add_child(UIStyle.label("修 行 录",21,UIStyle.GOLD))
	header=UIStyle.label("",15,UIStyle.DIM)
	header.size_flags_horizontal=SIZE_EXPAND_FILL
	header.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(header)
	var close_button:=UIStyle.button("返回  Esc",close)
	close_button.custom_minimum_size.x=112
	top.add_child(close_button)
	var nav:=HBoxContainer.new()
	nav.add_theme_constant_override("separation",8)
	layout.add_child(nav)
	for item in [["character","人物 / C"],["aperture","空窍 / Q"],["body","身体 / B"],["inventory","背包 / I"],["map","山志 / M"],["elements","蛊术 / V"]]:
		var button:=UIStyle.button(item[1],open_page.bind(item[0]))
		button.size_flags_horizontal=SIZE_EXPAND_FILL
		nav.add_child(button)
		tabs[item[0]]=button
	var content:=Control.new()
	content.size_flags_vertical=SIZE_EXPAND_FILL
	layout.add_child(content)
	var character:=CharacterUI.new()
	character.player=game.player
	character.game=game
	var aperture:=ApertureUI.new()
	aperture.game=game
	var body:=BodyUI.new()
	body.player=game.player
	body.game=game
	var inventory:=InventoryUI.new()
	inventory.game=game
	var map:=MiniMapUI.new()
	map.game=game
	var elements:=ElementUI.new()
	elements.game=game
	pages={"aperture":aperture,"character":character,"body":body,"inventory":inventory,"map":map,"elements":elements}
	for key in pages:
		var page:Control=pages[key]
		page.visible=false
		content.add_child(page)
		UIStyle.fill(page)
	game.aperture_ui=aperture
	game.character_ui=character
	game.body_ui=body
	game.inventory_ui=inventory
	game.minimap_ui=map
	footer=UIStyle.label("Q 内视空窍 · I 查看外物 · 1/2/3 只是催蛊快捷位",13,UIStyle.DIM)
	layout.add_child(footer)
	visible=false

func _layout_panel() -> void:
	if panel==null: return
	var margin_x:=maxf(18,(size.x-1080)*0.5)
	var margin_y:=maxf(18,(size.y-580)*0.5)
	panel.offset_left=margin_x
	panel.offset_right=-margin_x
	panel.offset_top=margin_y
	panel.offset_bottom=-margin_y

func open_page(key:String)->void:
	if not pages.has(key): return
	active_page=key
	visible=true
	game.paused=true
	for name in pages:
		pages[name].visible=name==key
		tabs[name].modulate=UIStyle.GOLD if name==key else Color.WHITE
	if pages[key].has_method("refresh"): pages[key].refresh()
	if key=="inventory": pages[key].refresh_inventory()

func close()->void:
	visible=false
	for page in pages.values(): page.visible=false
	if game.running and not game.player.dead: game.paused=false

func _process(_delta:float)->void:
	if not visible: return
	var p:Player=game.player
	header.text="%s    元石 %d" % [p.aperture.realm(),p.crystals]
