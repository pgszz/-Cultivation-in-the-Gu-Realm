class_name WorldAtlas
extends Control

signal region_selected(id: String)
signal south_requested
var selected := "south"
var regions := {}

func _ready() -> void:
	custom_minimum_size=Vector2(340,280)
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_default_cursor_shape=CURSOR_POINTING_HAND

func _draw() -> void:
	regions.clear()
	if PaintedArt.ATLAS!=null: draw_texture_rect(PaintedArt.ATLAS,Rect2(Vector2.ZERO,size),false)
	else: draw_rect(Rect2(Vector2.ZERO,size),Color("24372e"))
	for id in WorldLore.REGIONS:
		var d:Dictionary=WorldLore.REGIONS[id]
		var center:Vector2=d.pos*size
		var r:=Rect2(center-Vector2(size.x*0.12,25),Vector2(size.x*0.24,50))
		regions[id]=r
		draw_style_box(UIStyle.box(Color(0.09,0.18,0.16,0.86) if selected==id else Color(0.12,0.18,0.14,0.68),UIStyle.GOLD if selected==id else Color(0.7,0.7,0.5,0.3)),r)
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
				if id=="south": south_requested.emit()
				accept_event()
