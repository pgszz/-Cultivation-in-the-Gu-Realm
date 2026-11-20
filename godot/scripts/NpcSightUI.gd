class_name NpcSightUI
extends PanelContainer

var game: Node
var row: HBoxContainer
var page := 0
var page_size := 6
var page_count := 1
var heading: Label
var cards: Dictionary = {}
var previous: Button
var next: Button

func _ready() -> void:
	mouse_filter=MOUSE_FILTER_STOP
	mouse_force_pass_scroll_events=false
	add_theme_stylebox_override("panel",UIStyle.box(Color(0.04,0.10,0.09,0.92),Color("465b50"),7))
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",3)
	add_child(content)
	var bar:=HBoxContainer.new()
	content.add_child(bar)
	heading=UIStyle.label("视野人物",12,UIStyle.GOLD)
	heading.size_flags_horizontal=SIZE_EXPAND_FILL
	bar.add_child(heading)
	for direction in [-1,1]:
		var button:=UIStyle.button("‹" if direction<0 else "›",turn_page.bind(direction))
		button.custom_minimum_size=Vector2(26,18)
		button.add_theme_font_size_override("font_size",12)
		for state in ["normal","hover","pressed","focus","disabled"]:
			var style:=UIStyle.box(Color("203b35"),Color("465b50"),3)
			style.set_content_margin_all(0)
			button.add_theme_stylebox_override(state,style)
		bar.add_child(button)
		if direction<0: previous=button
		else: next=button
	row=HBoxContainer.new()
	row.add_theme_constant_override("separation",5)
	content.add_child(row)
	hide()

func turn_page(direction: int) -> void:
	page=clampi(page+direction,0,page_count-1)
	refresh()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		turn_page(-1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1)
		accept_event()

func visible_people() -> Array:
	var result:Array=[]
	for person: Npc in game.active_npcs():
		if is_instance_valid(person) and person.is_visible_in_tree() and game.fog.can_see(person.position): result.append(person)
	# Stable identity order avoids moving targets under the mouse when people walk past.
	result.sort_custom(func(a: Npc,b: Npc): return a.resident_id.naturalnocasecmp_to(b.resident_id)<0)
	return result

func refresh() -> void:
	var allowed:bool=game._can_act() and not game.hud.minimal and game.hud.is_visible_in_tree() and not game.meditating
	if not allowed:
		hide()
		clear_cards()
		return
	var people:=visible_people()
	var left:float=game.hud.player_panel.get_global_rect().end.x+12
	var available:=get_viewport_rect().size.x-left-172.0
	page_size=maxi(1,int((minf(720,available)-11)/113))
	page_count=maxi(1,ceili(float(people.size())/page_size))
	page=clampi(page,0,page_count-1)
	var shown:Array=people.slice(page*page_size,(page+1)*page_size)
	var ids:Array=[]
	for person: Npc in shown: ids.append(person.resident_id)
	for id in cards.keys():
		if not ids.has(id) or not is_instance_valid(cards[id].person) or not people.has(cards[id].person):
			row.remove_child(cards[id])
			cards[id].queue_free()
			cards.erase(id)
	for i in shown.size():
		var person: Npc=shown[i]
		if not cards.has(person.resident_id):
			var card:=NpcSightCard.new()
			card.person=person
			card.game=game
			row.add_child(card)
			cards[person.resident_id]=card
		if cards[person.resident_id].get_index()!=i: row.move_child(cards[person.resident_id],i)
		cards[person.resident_id].refresh()
	visible=not people.is_empty()
	if not visible: return
	var width:=maxf(216,mini(page_size,people.size())*113+11)
	if not is_equal_approx(size.x,width): size.x=width
	position=Vector2(left+maxf(0,(available-size.x)*0.5),42)
	heading.text="视野人物 · %d%s" % [people.size(),"    %d / %d" % [page+1,page_count] if page_count>1 else ""]
	heading.tooltip_text="点击头像查看人物；左右箭头或滚轮翻页。"
	previous.disabled=page<=0
	next.disabled=page>=page_count-1

func clear_cards() -> void:
	if cards.is_empty(): return
	for card in cards.values():
		row.remove_child(card)
		card.queue_free()
	cards.clear()
	page=0

func _process(_delta: float) -> void:
	refresh()
