class_name PlayerHUD
extends PanelContainer

var game: Node
var hud: HUD
var portrait_button: Button
var portrait: CharacterPreview
var collapse_button: Button
var quickbar: HBoxContainer
var buttons: Dictionary={}
var meters: Dictionary={}
var meter_labels: Dictionary={}
var vitals: VBoxContainer
var identity: Label
var status_rows: Dictionary={}
var status_buttons: Dictionary={}
var status_signature:="@initial"
var elapsed:=0.0
var last_minimal:=false

func _ready() -> void:
	position=Vector2(12,12)
	custom_minimum_size.x=350
	size.x=350
	mouse_filter=MOUSE_FILTER_STOP
	mouse_force_pass_scroll_events=false
	add_theme_stylebox_override("panel",UIStyle.box(Color(0.035,0.095,0.09,0.94),Color("687662"),8))
	var layout:=VBoxContainer.new()
	layout.add_theme_constant_override("separation",5)
	add_child(layout)
	var top:=HBoxContainer.new()
	top.add_theme_constant_override("separation",8)
	layout.add_child(top)
	portrait_button=small_button("",func(): game.open_journal("character"))
	portrait_button.custom_minimum_size=Vector2(62,78)
	portrait_button.tooltip_text="点击头像 · 查看人物属性与状态（C）"
	top.add_child(portrait_button)
	portrait=CharacterPreview.new()
	portrait.bust=true
	UIStyle.fill(portrait)
	portrait.animate=false
	portrait_button.add_child(portrait)
	var info:=VBoxContainer.new()
	info.size_flags_horizontal=SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation",3)
	top.add_child(info)
	var title:=HBoxContainer.new()
	info.add_child(title)
	identity=UIStyle.label("",13,UIStyle.GOLD)
	identity.size_flags_horizontal=SIZE_EXPAND_FILL
	identity.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_child(identity)
	collapse_button=small_button("−",toggle)
	collapse_button.custom_minimum_size=Vector2(25,24)
	title.add_child(collapse_button)
	vitals=VBoxContainer.new()
	vitals.add_theme_constant_override("separation",3)
	info.add_child(vitals)
	for spec in [["hp","气血",UIStyle.RED],["yuan","真元",Color("79c6ea")],["stamina","体力",UIStyle.GOLD]]:
		var line:=HBoxContainer.new()
		line.add_theme_constant_override("separation",5)
		vitals.add_child(line)
		line.add_child(UIStyle.label(spec[1],11,UIStyle.DIM))
		var meter:=UIStyle.meter(0,100,spec[2])
		meter.custom_minimum_size=Vector2(70,7)
		meter.size_flags_horizontal=SIZE_EXPAND_FILL
		meter.size_flags_vertical=SIZE_SHRINK_CENTER
		meter.mouse_filter=MOUSE_FILTER_IGNORE
		line.add_child(meter)
		meters[spec[0]]=meter
		var amount:=UIStyle.label("",11)
		amount.custom_minimum_size.x=78
		amount.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		line.add_child(amount)
		meter_labels[spec[0]]=amount
	quickbar=HBoxContainer.new()
	quickbar.add_theme_constant_override("separation",3)
	layout.add_child(quickbar)
	for item in [["人物","character","C"],["空窍","aperture","Q"],["身体","body","B"],["背包","inventory","I"],["山志","map","M"],["蛊术","elements","V"],["炼蛊","refinement",""]]:
		var button:=small_button(item[0],func(): game.open_journal(item[1]))
		button.size_flags_horizontal=SIZE_EXPAND_FILL
		button.tooltip_text="%s %s"%[item[0],item[2]]
		quickbar.add_child(button)
		buttons[item[1]]=button
	for good in [true,false]:
		var line:=HBoxContainer.new()
		line.add_theme_constant_override("separation",4)
		layout.add_child(line)
		line.add_child(UIStyle.label("增益" if good else "减益",11,UIStyle.JADE if good else UIStyle.RED))
		var entries:=HBoxContainer.new()
		entries.add_theme_constant_override("separation",4)
		entries.size_flags_horizontal=SIZE_EXPAND_FILL
		line.add_child(entries)
		status_rows[good]=entries
	refresh()

func small_button(text: String, callback: Callable) -> Button:
	var button:=UIStyle.button(text,callback)
	button.custom_minimum_size=Vector2(0,27)
	button.add_theme_font_size_override("font_size",11)
	button.focus_mode=FOCUS_NONE
	button.mouse_force_pass_scroll_events=false
	for state in ["normal","hover","pressed","focus"]:
		var style:=UIStyle.box(Color("203b35") if state=="normal" else Color("305548"),Color("465b50") if state=="normal" else UIStyle.GOLD,4)
		style.set_content_margin_all(4)
		button.add_theme_stylebox_override(state,style)
	return button

func toggle() -> void:
	hud.minimal=not hud.minimal
	refresh()
	game.save_game()

func open_status() -> void:
	game.open_journal("character")
	game.character_ui.show_status()

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	elapsed+=delta
	if elapsed>=0.1 or last_minimal!=hud.minimal:
		elapsed=0
		refresh()

func refresh() -> void:
	if game.player==null or game.fog==null or identity==null: return
	var p:Player=game.player
	var resized_panel:=last_minimal!=hud.minimal
	last_minimal=hud.minimal
	vitals.visible=not hud.minimal
	portrait_button.custom_minimum_size.y=42 if hud.minimal else 78
	collapse_button.text="+" if hud.minimal else "−"
	collapse_button.tooltip_text="展开信息 · F1" if hud.minimal else "收起信息 · F1；头像与快捷按钮仍可使用"
	identity.text=game.character_name+" · "+p.aperture.realm()
	identity.tooltip_text=identity.text
	portrait.appearance.texture=p.appearance.texture
	portrait.appearance.data=p.appearance.data
	meters.hp.value=p.hp/p.max_hp*100
	meters.yuan.value=p.aperture.fill_ratio()*100
	meters.stamina.value=p.gu_effects.stamina
	meter_labels.hp.text="%.0f / %.0f"%[p.hp,p.max_hp]
	meter_labels.yuan.text=p.aperture.amount_text()
	meter_labels.stamina.text="%.0f / 100"%p.gu_effects.stamina
	portrait_button.tooltip_text="%s\n气血 %.1f / %.0f · 真元 %s · 体力 %.1f / 100\n点击查看完整属性（C）"%[identity.text,p.hp,p.max_hp,p.aperture.amount_text(),p.gu_effects.stamina]
	var data:=PlayerStatus.snapshot(game)
	var signature:=""
	for item in data.effects: signature+=item.id+":"+str(item.good)+";"
	if signature!=status_signature:
		resized_panel=true
		status_signature=signature
		status_buttons.clear()
		for good in [true,false]:
			var container:HBoxContainer=status_rows[good]
			for child in container.get_children():
				container.remove_child(child)
				child.queue_free()
			var matching:Array=data.effects.filter(func(item:Dictionary): return item.good==good)
			if matching.is_empty(): container.add_child(UIStyle.label("暂无",11,UIStyle.DIM))
			for i in mini(2,matching.size()):
				var button:=small_button("",open_status)
				button.custom_minimum_size.x=112
				button.size_flags_horizontal=SIZE_EXPAND_FILL
				button.clip_text=true
				button.add_theme_color_override("font_color",UIStyle.JADE if good else UIStyle.RED)
				container.add_child(button)
				status_buttons[matching[i].id]=button
			if matching.size()>2:
				var more:=small_button("+%d"%(matching.size()-2),open_status)
				more.tooltip_text="查看全部 %d 项%s"%[matching.size(),"增益" if good else "减益"]
				container.add_child(more)
	for item in data.effects:
		if not status_buttons.has(item.id): continue
		var button:Button=status_buttons[item.id]
		button.text=item.short+(" %.0fs"%ceilf(item.left) if item.left>=0 else "")
		button.tooltip_text=item.title+"\n"+item.detail+("\n剩余 %.1f 秒"%item.left if item.left>=0 else "\n随状态持续")+"\n点击查看全部状态与属性"
	# Container minimum size can shrink after collapsing or after effects expire.
	if resized_panel: size.y=0
