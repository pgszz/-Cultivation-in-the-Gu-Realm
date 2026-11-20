class_name WorldProp
extends Node2D

var world: Node
var object_id := ""
var art_id := ""
var hp := 100.0
var max_hp := 100.0
var broken := false
var kind := "tree"
var title := ""
# Legacy construction metadata; original art is selected by object identity.
var source := Rect2(0,96,64,48)
var draw_size := Vector2(128,96)
var opacity := 1.0
var tint := Color.WHITE
var hit_time := 0.0
var collapse_elapsed := CollapseAnimation.DURATION

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR

func sync_damage(health: float, animate: bool = false) -> void:
	var was_broken:=broken
	var was_hp:=hp
	hp=health
	broken=hp<=0
	if animate and hp<was_hp:
		hit_time=0.28
		if broken and not was_broken: collapse_elapsed=0.0
	else:
		hit_time=0.0
		collapse_elapsed=CollapseAnimation.DURATION
	queue_redraw()

func occludes_player() -> bool:
	if world==null or broken: return false
	var local: Vector2=world.player_pos-position
	return Rect2(Vector2(-draw_size.x*0.5,-draw_size.y+8),draw_size).has_point(local) and local.y<-12

func advance_visual(delta: float) -> void:
	hit_time=maxf(0,hit_time-delta)
	if broken: collapse_elapsed=minf(CollapseAnimation.DURATION,collapse_elapsed+delta)

func _process(delta: float) -> void:
	if world==null or not is_visible_in_tree(): return
	var game: Node=world.get_parent()
	var animating:=hit_time>0 or (broken and collapse_elapsed<CollapseAnimation.DURATION)
	if not game.paused: advance_visual(delta)
	if not Rect2(world.camera_pos,world.view_size).grow(draw_size.y).has_point(position): return
	var target:=0.22 if occludes_player() else 1.0
	var next:=move_toward(opacity,target,delta*3.8)
	if absf(next-opacity)>0.001 or animating:
		opacity=next
		queue_redraw()

func _draw() -> void:
	var texture:=PaintedArt.prop(kind,art_id if art_id!="" else object_id)
	var rect:=PaintedArt.fit(texture,Rect2(Vector2(-draw_size.x*0.5,-draw_size.y+8),draw_size))
	if broken:
		var p:=collapse_elapsed/CollapseAnimation.DURATION
		var debris:=PaintedArt.ruin(kind)
		var ruin_size:=Vector2(draw_size.x,maxf(30,draw_size.y*0.35))
		draw_texture_rect(debris,PaintedArt.fit(debris,Rect2(Vector2(-ruin_size.x*0.5,12-ruin_size.y),ruin_size)),false,Color(1,1,1,smoothstep(0.12,0.72,p)))
		if p<1: CollapseAnimation.draw(self,texture,rect,p)
		if kind in ["house","cave"]: _draw_label(title+(" · 坍塌中" if p<1 else " · 废墟"),"F 检查 / 重建" if kind=="house" else "洞口已毁损")
		return
	draw_set_transform(Vector2(0,8),0,Vector2(1,0.22))
	draw_circle(Vector2.ZERO,draw_size.x*0.35,Color(0.05,0.12,0.09,0.23*opacity))
	draw_set_transform(Vector2(sin(hit_time*95)*hit_time*10,0),sin(hit_time*70)*hit_time*0.04)
	var color:=Color.WHITE.darkened((1.0-hp/max_hp)*0.22)
	color.a=opacity
	draw_texture_rect(texture,rect,false,color)
	_draw_wear()
	draw_set_transform(Vector2.ZERO)
	if kind in ["house","cave"]: _draw_label(title,"")

func _draw_label(text: String, hint: String) -> void:
	draw_rect(Rect2(-70,17,140,23),Color(0.05,0.12,0.11,0.86))
	draw_string(ThemeDB.fallback_font,Vector2(-70,34),text,HORIZONTAL_ALIGNMENT_CENTER,140,13,UIStyle.GOLD)
	if hint!="": draw_string(ThemeDB.fallback_font,Vector2(-70,53),hint,HORIZONTAL_ALIGNMENT_CENTER,140,12,UIStyle.DIM)

func _draw_wear() -> void:
	if hp>=max_hp: return
	var severe:=hp/max_hp<=0.3
	var width:=minf(draw_size.x*0.55,90)
	var height:=minf(draw_size.y*0.45,60)
	var crack:=PackedVector2Array([Vector2(-width*0.25,-height),Vector2(2,-height*0.65),Vector2(-8,-height*0.4),Vector2(width*0.24,-8)])
	draw_polyline(crack,Color(0.12,0.12,0.09,opacity),3 if severe else 2,true)
	if severe: draw_line(Vector2(-8,-height*0.4),Vector2(-width*0.45,-height*0.25),Color(0.12,0.12,0.09,opacity),3,true)
	draw_rect(Rect2(-28,10,56,4),Color("263330"))
	draw_rect(Rect2(-28,10,56*hp/max_hp,4),UIStyle.RED if severe else UIStyle.GOLD)
