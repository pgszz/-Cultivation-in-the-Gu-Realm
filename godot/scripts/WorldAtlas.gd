class_name WorldAtlas
extends Control

signal region_selected(id: String)
var selected := "south"
var regions := {}

func _ready() -> void:
	custom_minimum_size=Vector2(340,280)
	mouse_default_cursor_shape=CURSOR_POINTING_HAND

func _draw() -> void:
	regions.clear()
	for id in WorldLore.REGIONS:
		var d:Dictionary=WorldLore.REGIONS[id]
		var center:Vector2=d.pos*size
		var r:=Rect2(center-Vector2(size.x*0.13,48),Vector2(size.x*0.26,96))
		regions[id]=r
		draw_style_box(UIStyle.box(d.color.darkened(0.55),UIStyle.GOLD if selected==id else d.color),r)
		draw_string(ThemeDB.fallback_font,center+Vector2(-50,0),d.name,HORIZONTAL_ALIGNMENT_CENTER,100,23,d.color.lightened(0.3))
		if id=="south":
			draw_circle(center+Vector2(0,20),4,UIStyle.GOLD)
			draw_string(ThemeDB.fallback_font,center+Vector2(8,24),"青茅山",HORIZONTAL_ALIGNMENT_LEFT,90,13,UIStyle.INK)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		for id in regions:
			if regions[id].has_point(event.position):
				selected=id
				queue_redraw()
				region_selected.emit(id)
				accept_event()
