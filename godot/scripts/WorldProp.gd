class_name WorldProp
extends Node2D

const MOUNTAIN := preload("res://assets/generated/qingmao_mountain.png")
const ATLAS := preload("res://assets/ninja_adventure/tileset_village_abandoned.png")
var world: Node
var object_id := ""
var hp := 100.0
var max_hp := 100.0
var broken := false
var kind := "tree"
var title := ""
var source := Rect2(0,96,64,48)
var draw_size := Vector2(128,96)
var opacity := 1.0
var tint := Color.WHITE

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func occludes_player() -> bool:
	if world == null or broken: return false
	var local: Vector2 = world.player_pos-position
	return Rect2(Vector2(-draw_size.x*0.5,-draw_size.y+8),draw_size).has_point(local) and local.y < -12

func _process(delta: float) -> void:
	if world == null or not is_visible_in_tree(): return
	if not Rect2(world.camera_pos,world.view_size).grow(draw_size.y).has_point(position): return
	var target := 0.22 if occludes_player() else 1.0
	var next := move_toward(opacity,target,delta*3.8)
	if absf(next-opacity)>0.001:
		opacity = next
		queue_redraw()

func _draw() -> void:
	if broken:
		for i in 5:
			var x := -28+i*13
			draw_rect(Rect2(x,-8+(i%2)*6,23,8),Color("777862") if kind in ["rock","mountain"] else Color("806545"))
		if kind=="house":
			draw_string(ThemeDB.fallback_font,Vector2(-64,22),title+" · 废墟",HORIZONTAL_ALIGNMENT_CENTER,128,13,UIStyle.DIM)
		return
	if hp<max_hp:
		draw_rect(Rect2(-28,10,56,4),Color("263330"))
		draw_rect(Rect2(-28,10,56*hp/max_hp,4),UIStyle.RED)
	if kind=="bamboo":
		for i in 5:
			var x:float=-28+i*14
			var height:float=78+(i%3)*17
			draw_line(Vector2(x,0),Vector2(x,-height),Color(0.32,0.52,0.33,opacity),5)
			for n in range(1,5):
				var y:float=-n*height/5
				draw_line(Vector2(x-3,y),Vector2(x+3,y),Color(0.66,0.74,0.43,opacity),2)
				draw_line(Vector2(x,y),Vector2(x+16,y-13),Color(0.18,0.40,0.24,opacity),3)
		return
	if kind=="cave":
		draw_texture_rect(MOUNTAIN,Rect2(-110,-155,220,166),false,Color(0.85,0.90,0.81,opacity))
		draw_colored_polygon(PackedVector2Array([Vector2(-29,8),Vector2(-25,-38),Vector2(-14,-54),Vector2(11,-59),Vector2(23,-38),Vector2(26,8)]),Color(0.18,0.23,0.18,opacity))
		draw_colored_polygon(PackedVector2Array([Vector2(-19,8),Vector2(-16,-32),Vector2(-4,-46),Vector2(12,-36),Vector2(17,8)]),Color(0.03,0.07,0.06,opacity))
		draw_line(Vector2(-23,7),Vector2(23,7),Color(0.51,0.57,0.40,opacity),5)
		draw_string(ThemeDB.fallback_font,Vector2(-80,28),title,HORIZONTAL_ALIGNMENT_CENTER,160,14,UIStyle.GOLD)
		return
	if kind == "mountain":
		_draw_mountain()
		return
	draw_set_transform(Vector2.ZERO,0,Vector2(1,0.3))
	draw_circle(Vector2(0,9),draw_size.x*0.36,Color(0.05,0.12,0.09,0.28))
	draw_set_transform(Vector2.ZERO)
	var color := tint
	color.a = opacity
	draw_texture_rect_region(ATLAS,Rect2(Vector2(-draw_size.x*0.5,-draw_size.y+8),draw_size),source,color)
	if kind == "house":
		draw_rect(Rect2(-14,0,28,10),Color("b5a271"))
		draw_rect(Rect2(-58,17,116,23),Color(0.05,0.12,0.11,0.86))
		draw_string(ThemeDB.fallback_font,Vector2(-58,34),title,HORIZONTAL_ALIGNMENT_CENTER,116,13,Color("f1dfab"))

func _draw_mountain() -> void:
	var color := Color.WHITE
	color.a = opacity
	draw_texture_rect(MOUNTAIN,Rect2(Vector2(-draw_size.x*0.5,-draw_size.y+8),draw_size),false,color)
