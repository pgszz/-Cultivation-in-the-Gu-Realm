class_name ActorAnimation
extends RefCounted

## Presentation only: never deals damage, moves a collider or grants loot.
var action := "idle"
var elapsed := 0.0
var duration := 0.0
var clock := 0.0
var direction := 0.0
var moving := false
var walk_distance := 0.0
const DEATH_SECONDS := 0.72

func play(next: String, facing: float, seconds: float = 0.32) -> void:
	if action=="death": return
	action=next
	direction=facing
	elapsed=0.0
	duration=DEATH_SECONDS if next=="death" else maxf(seconds,0.01)

func restore_dead(is_dead: bool) -> void:
	action="death" if is_dead else "idle"
	duration=DEATH_SECONDS if is_dead else 0.0
	elapsed=duration
	moving=false
	walk_distance=0.0

func advance(delta: float, walking: bool, facing: float, distance: float = -1.0) -> void:
	clock+=delta
	moving=walking and action!="death"
	if moving:
		walk_distance+=maxf(0.0,distance) if distance>=0.0 else delta*140.0
	else:
		walk_distance=0.0
	if action!="idle":
		elapsed=minf(duration,elapsed+delta)
		if elapsed>=duration and action!="death": action="idle"
	if action=="idle": direction=facing

func facing_row() -> int:
	var v:=Vector2.from_angle(direction)
	return (2 if v.y<0 else 0) if absf(v.y)>=absf(v.x) else (3 if v.x>0 else 1)

func progress() -> float:
	return clampf(elapsed/maxf(duration,0.01),0,1)

func frame(resident: bool = false) -> int:
	match action:
		"death": return 5 if progress()>=0.5 else (4 if resident else 0)
		"strike": return 3 if progress()>0.18 and progress()<0.8 else 0
		"cast": return 4
		"hurt": return 4 if resident else 0
	return [1,0,2,0][int((walk_distance+0.0001)/16.0)%4] if moving else 0

func draw(canvas: CanvasItem, resident: bool = false, role: int = 0, dash: bool = false, appearance: String = "", player_look: CharacterAppearance = null) -> void:
	var row:=role
	if not resident:
		row=facing_row()
	var texture: Texture2D=PaintedArt.RESIDENTS if resident else PaintedArt.HERO
	var region:=PaintedArt.actor_region(row,frame(resident))
	if not resident and player_look!=null:
		texture=player_look.texture
		region=player_look.region(row,frame(false))
	if resident and appearance!="":
		texture=NpcAppearance.texture(appearance)
		region=NpcAppearance.region(appearance,frame(true))
	var rect:=Rect2(-32,-52,64,64)
	if resident and appearance!="": rect=NpcAppearance.actor_rect(appearance)
	var p:=progress()
	var offset:=Vector2.ZERO
	var rotation:=0.0
	var scale_vector:=Vector2(-1 if resident and cos(direction)<0 else 1,1)
	var tint:=Color.WHITE
	if moving and action=="idle": offset.y=-absf(sin(walk_distance/32.0*PI))*1.0
	if action=="idle" and not moving: scale_vector.y=1.0+sin(clock*2.5)*0.008
	if action=="strike":
		offset=Vector2.from_angle(direction)*sin(p*PI)*6
		rotation=sin(p*TAU)*0.08
	if action=="cast": offset.y=-sin(p*PI)*2
	if action=="hurt":
		offset=-Vector2.from_angle(direction)*sin(p*PI)*5
		rotation=sin(p*PI)*-0.15
		tint=Color.WHITE.lerp(Color("f19c85"),sin(p*PI)*0.7)
	if action=="death" and p<0.5:
		rotation=p*1.0
		scale_vector.y=1.0-p*0.6
		offset=Vector2(p*9,p*5)
	canvas.draw_set_transform(Vector2(0,9),0,Vector2(1,0.28))
	canvas.draw_circle(Vector2.ZERO,13 if action!="death" else 20,Color(0.03,0.09,0.07,0.32))
	canvas.draw_set_transform(offset,rotation,scale_vector)
	if dash and action!="death":
		for i in range(3,0,-1):
			canvas.draw_texture_rect_region(texture,Rect2(rect.position-Vector2.from_angle(direction)*i*7,rect.size),region,Color(0.7,0.9,0.83,0.1))
	canvas.draw_texture_rect_region(texture,rect,region,tint)
	canvas.draw_set_transform(Vector2.ZERO)
	if action=="strike" and p>0.18 and p<0.7:
		canvas.draw_arc(Vector2.from_angle(direction)*15,25,direction-0.8,direction+0.8,18,Color(0.91,0.88,0.73,sin(p*PI)*0.7),2,true)
