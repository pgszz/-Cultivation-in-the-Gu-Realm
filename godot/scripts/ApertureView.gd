class_name ApertureView
extends Control

var player: Player

func _ready() -> void:
	custom_minimum_size=Vector2(160,210)
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter=MOUSE_FILTER_IGNORE

func _draw() -> void:
	if player==null: return
	var a:=player.aperture
	if not a.is_open():
		draw_string(ThemeDB.fallback_font,Vector2(0,94),"空窍尚未开辟",HORIZONTAL_ALIGNMENT_CENTER,int(size.x),16,UIStyle.DIM)
		return
	var center:=Vector2(size.x/2,94)
	var radius:=78.0
	draw_circle(center,radius,Color("091e22"))
	var surface:=center.y+radius-a.total()/100.0*radius*2
	var refined_line:=center.y+radius-a.essence/100.0*radius*2
	var sea:Color=[Color("487c69"),Color("a85140"),Color("b9c7d4"),Color("d6b25a"),Color("9866b7")][clampi(a.rank-1,0,4)]
	for y in range(int(ceil(surface)),int(center.y+radius)):
		var half:=sqrt(maxf(0,radius*radius-pow(float(y)-center.y,2)))
		draw_line(Vector2(center.x-half,y),Vector2(center.x+half,y),sea.lightened(0.3) if y<refined_line else sea,1)
	var ceiling:=center.y+radius-a.capacity/100.0*radius*2
	var edge:=sqrt(maxf(0,radius*radius-pow(ceiling-center.y,2)))
	draw_dashed_line(Vector2(center.x-edge,ceiling),Vector2(center.x+edge,ceiling),UIStyle.GOLD,1,5)
	draw_arc(center,radius+3,0,TAU,96,Color("dce6d6"),3+float(a.stage),true)
	var residing:Array=[]
	for gu in player.get_node("/root/Gus").owned_gus:
		if gu.location=="aperture" and not gu.dead: residing.append(gu)
	for i in mini(5,residing.size()):
		var angle:float=-PI*0.7+float(i)*TAU/maxi(3,mini(5,residing.size()))
		var point:=center+Vector2.from_angle(angle)*43
		draw_texture_rect(GuArt.texture(residing[i].template_id),GuArt.fitted_rect(residing[i].template_id,Rect2(point-Vector2(15,15),Vector2(30,30))),false)
	draw_string(ThemeDB.fallback_font,Vector2(0,200),"单一空窍 · "+ApertureState.WALLS[a.stage],HORIZONTAL_ALIGNMENT_CENTER,int(size.x),14,UIStyle.GOLD)
