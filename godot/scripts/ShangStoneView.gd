class_name ShangStoneView
extends Control

var progress := 1.0
var result: Dictionary={}

func _ready() -> void:
	custom_minimum_size=Vector2(0,112)
	mouse_filter=MOUSE_FILTER_IGNORE

func reveal(value: Dictionary) -> void:
	result=value
	progress=0

func _process(delta: float) -> void:
	if visible and progress<1:
		progress=minf(1,progress+delta/1.5)
		queue_redraw()

func _draw() -> void:
	var c:=size*0.5
	var separation:=smoothstep(0.15,0.8,progress)*70 if not result.is_empty() else 0.0
	for side in [-1,1]:
		var p:=c+Vector2(side*separation,0)
		var points:=PackedVector2Array([p+Vector2(0,-44),p+Vector2(side*38,-28),p+Vector2(side*43,20),p+Vector2(side*20,43),p+Vector2(0,32),p+Vector2(side*9,5),p+Vector2(0,-15)])
		draw_colored_polygon(points,Color("77716f") if side==-1 else Color("a4947e"))
		draw_polyline(points,Color("c9b792"),2,true)
	if result.get("kind","")=="live" and progress>0.45:
		draw_texture_rect(GuArt.texture(result.gu),GuArt.fitted_rect(result.gu,Rect2(c-Vector2(40,40),Vector2(80,80))),false,Color(1,1,1,smoothstep(0.45,0.85,progress)))
	elif not result.is_empty() and progress>0.7:
		draw_string(ThemeDB.fallback_font,c+Vector2(-70,6),"蛊虫残躯" if result.kind=="dead" else ("解石损毁" if result.kind=="broken" else "空石"),HORIZONTAL_ALIGNMENT_CENTER,140,16,UIStyle.DIM)
