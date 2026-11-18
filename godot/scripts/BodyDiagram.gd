class_name BodyDiagram
extends Control

signal part_selected(id: String)
var body: BodyComponent
var selected := "torso"
var hit_regions: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = Vector2(235, 340)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _color(id: String) -> Color:
	if body == null or not body.parts.has(id):
		return UIStyle.JADE
	var p: Dictionary = body.parts[id]
	if p.destroyed: return Color("954f4b")
	var ratio := float(p.hp) / float(p.max_hp)
	if ratio <= 0.3: return UIStyle.RED
	if ratio < 0.75: return UIStyle.GOLD
	return Color("82b8a5")

func _shape(id: String, points: PackedVector2Array) -> void:
	draw_colored_polygon(points, _color(id))
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, UIStyle.GOLD if id == selected else Color("c4d3be"), 2.0, true)
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points: bounds = bounds.expand(point)
	hit_regions[id] = bounds.grow(3)

func _draw() -> void:
	hit_regions.clear()
	var x := size.x * 0.5
	_shape("head", PackedVector2Array([Vector2(x-19,24),Vector2(x-13,12),Vector2(x+13,12),Vector2(x+19,24),Vector2(x+17,53),Vector2(x+9,64),Vector2(x-9,64),Vector2(x-17,53)]))
	_shape("neck", PackedVector2Array([Vector2(x-9,64),Vector2(x+9,64),Vector2(x+12,79),Vector2(x-12,79)]))
	_shape("torso", PackedVector2Array([Vector2(x-12,77),Vector2(x-38,86),Vector2(x-31,128),Vector2(x-26,163),Vector2(x+26,163),Vector2(x+31,128),Vector2(x+38,86),Vector2(x+12,77)]))
	_shape("pelvis", PackedVector2Array([Vector2(x-26,164),Vector2(x+26,164),Vector2(x+30,194),Vector2(x+17,211),Vector2(x-17,211),Vector2(x-30,194)]))
	_shape("hand_l", PackedVector2Array([Vector2(x+39,87),Vector2(x+52,98),Vector2(x+61,145),Vector2(x+65,186),Vector2(x+60,201),Vector2(x+48,196),Vector2(x+48,153),Vector2(x+34,119)]))
	_shape("hand_r", PackedVector2Array([Vector2(x-39,87),Vector2(x-52,98),Vector2(x-61,145),Vector2(x-65,186),Vector2(x-60,201),Vector2(x-48,196),Vector2(x-48,153),Vector2(x-34,119)]))
	_shape("leg_l", PackedVector2Array([Vector2(x+3,210),Vector2(x+28,200),Vector2(x+31,248),Vector2(x+26,299),Vector2(x+38,310),Vector2(x+38,319),Vector2(x+10,319),Vector2(x+5,265)]))
	_shape("leg_r", PackedVector2Array([Vector2(x-3,210),Vector2(x-28,200),Vector2(x-31,248),Vector2(x-26,299),Vector2(x-38,310),Vector2(x-38,319),Vector2(x-10,319),Vector2(x-5,265)]))
	_shape("groin", PackedVector2Array([Vector2(x-10,194),Vector2(x+10,194),Vector2(x,212)]))
	draw_line(Vector2(x,84),Vector2(x,158),Color("4c7c71"),1.0)
	draw_line(Vector2(x-24,116),Vector2(x+24,116),Color("4c7c71"),1.0)
	for item in [["eye_l", Vector2(x+8,36)], ["eye_r", Vector2(x-8,36)], ["ear_l", Vector2(x+21,39)], ["ear_r", Vector2(x-21,39)], ["nose", Vector2(x,44)], ["mouth", Vector2(x,53)]]:
		var id: String = item[0]
		var p: Vector2 = item[1]
		draw_circle(p, 3.0, _color(id).darkened(0.55))
		if id == selected: draw_arc(p,6,0,TAU,20,UIStyle.GOLD,2,true)
		hit_regions[id] = Rect2(p-Vector2(5,5),Vector2(10,10))
	draw_string(ThemeDB.fallback_font,Vector2(8,338),"正面视图 · 左右以角色自身为准",HORIZONTAL_ALIGNMENT_CENTER,int(size.x-16),12,UIStyle.DIM)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var ids: Array = hit_regions.keys()
		ids.reverse()
		for id in ids:
			if hit_regions[id].has_point(event.position):
				part_selected.emit(id)
				accept_event()
				return
