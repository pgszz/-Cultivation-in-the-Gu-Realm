class_name WildlifeAnimation
extends RefCounted

## Species-weighted cutout motion. It never moves a collider or grants loot.
const SHADER := preload("res://assets/wildlife/wildlife_motion.gdshader")
const DEATH_SECONDS := 0.65
const HURT_SECONDS := 0.24
const PROFILES := {
	"rabbit":{"style":"hop","stride":2.5,"lift":0.65,"windup":0.18,"strike":0.13,"recover":0.22,"width":0.075,"head":Vector2(0.68,0.5),"legs":[Vector4(0.3,0.7,0.24,0.93),Vector4(0.4,0.68,0.43,0.86),Vector4(0.57,0.65,0.6,0.97),Vector4(0.65,0.65,0.68,0.9)]},
	"deer":{"style":"bound","stride":4.0,"lift":0.32,"windup":0.24,"strike":0.15,"recover":0.28,"width":0.06,"head":Vector2(0.7,0.42),"legs":[Vector4(0.28,0.5,0.17,0.87),Vector4(0.35,0.56,0.37,0.81),Vector4(0.58,0.55,0.55,0.95),Vector4(0.64,0.56,0.66,0.88)]},
	"wolf":{"style":"bite","stride":3.4,"lift":0.22,"windup":0.22,"strike":0.13,"recover":0.28,"width":0.075,"head":Vector2(0.72,0.4),"legs":[Vector4(0.33,0.5,0.2,0.86),Vector4(0.42,0.51,0.37,0.81),Vector4(0.62,0.51,0.61,0.92),Vector4(0.72,0.49,0.75,0.87)]},
	"bear":{"style":"claw","stride":3.0,"lift":0.12,"windup":0.34,"strike":0.18,"recover":0.4,"width":0.1,"head":Vector2(0.72,0.43),"legs":[Vector4(0.22,0.53,0.12,0.83),Vector4(0.33,0.56,0.33,0.78),Vector4(0.47,0.55,0.48,0.87),Vector4(0.73,0.52,0.75,0.84)]},
	"boar":{"style":"charge","stride":2.9,"lift":0.16,"windup":0.3,"strike":0.16,"recover":0.32,"width":0.085,"head":Vector2(0.72,0.5),"legs":[Vector4(0.26,0.53,0.13,0.8),Vector4(0.34,0.56,0.35,0.76),Vector4(0.51,0.55,0.52,0.88),Vector4(0.69,0.56,0.72,0.83)]},
	"fox":{"style":"bite","stride":3.5,"lift":0.26,"windup":0.18,"strike":0.12,"recover":0.24,"width":0.065,"head":Vector2(0.73,0.4),"legs":[Vector4(0.4,0.48,0.31,0.81),Vector4(0.46,0.5,0.48,0.77),Vector4(0.64,0.52,0.63,0.88),Vector4(0.72,0.5,0.75,0.84)]},
	"pheasant":{"style":"bird","stride":2.1,"lift":0.2,"windup":0.16,"strike":0.1,"recover":0.22,"width":0.07,"head":Vector2(0.76,0.4),"legs":[Vector4(0.58,0.65,0.57,0.87),Vector4(0.69,0.65,0.77,0.82),Vector4.ZERO,Vector4.ZERO]},
	"green_wolf":{"style":"bite","stride":3.7,"lift":0.28,"windup":0.26,"strike":0.15,"recover":0.32,"width":0.07,"head":Vector2(0.74,0.4),"legs":[Vector4(0.38,0.5,0.26,0.84),Vector4(0.48,0.53,0.46,0.8),Vector4(0.65,0.53,0.65,0.9),Vector4(0.75,0.51,0.78,0.85)]},
	"iron_bear":{"style":"claw","stride":3.3,"lift":0.14,"windup":0.4,"strike":0.2,"recover":0.44,"width":0.1,"head":Vector2(0.73,0.46),"legs":[Vector4(0.22,0.55,0.12,0.83),Vector4(0.34,0.56,0.34,0.78),Vector4(0.49,0.55,0.49,0.87),Vector4(0.73,0.54,0.75,0.84)]},
}
static var shared_mesh: ArrayMesh
var rig: MeshInstance2D
var shadow: Polygon2D
var profile: Dictionary
var action := "idle"
var elapsed := 0.0
var duration := 0.0
var clock := 0.0
var phase := 0.0
var motion := 0.0
var speed_ratio := 0.0
var facing := 1.0
var attack_direction := Vector2.RIGHT
var hit_sent := false
var hurt_direction := Vector2.LEFT

static func mesh() -> ArrayMesh:
	if shared_mesh!=null: return shared_mesh
	var vertices:=PackedVector3Array()
	var uvs:=PackedVector2Array()
	var indices:=PackedInt32Array()
	const GRID:=24
	for y in range(GRID+1):
		for x in range(GRID+1):
			var uv:=Vector2(x,y)/GRID
			vertices.append(Vector3(uv.x-0.5,uv.y-0.72,0))
			uvs.append(uv)
	for y in GRID:
		for x in GRID:
			var a:=y*(GRID+1)+x
			indices.append_array(PackedInt32Array([a,a+1,a+GRID+1,a+1,a+GRID+2,a+GRID+1]))
	var arrays:=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=indices
	shared_mesh=ArrayMesh.new()
	shared_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return shared_mesh

func setup(actor: Node2D, species: String) -> void:
	profile=PROFILES.get(species,PROFILES.wolf)
	shadow=Polygon2D.new()
	shadow.name="WildlifeShadow"
	var outline:=PackedVector2Array()
	for i in 24: outline.append(Vector2(cos(i*TAU/24),sin(i*TAU/24)*0.26))
	shadow.polygon=outline
	shadow.color=Color(0,0,0,0.23)
	shadow.show_behind_parent=true
	actor.add_child(shadow)
	rig=MeshInstance2D.new()
	rig.name="WildlifeMotion"
	rig.mesh=mesh()
	rig.texture=WildlifeArt.texture(species)
	rig.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	var material:=ShaderMaterial.new()
	material.shader=SHADER
	rig.material=material
	for i in 4: material.set_shader_parameter(["leg_a","leg_b","leg_c","leg_d"][i],profile.legs[i])
	material.set_shader_parameter("head_pivot",profile.head)
	material.set_shader_parameter("leg_width",profile.width)
	# Shadow precedes the rig; the parent's labels and effects remain above both.
	rig.show_behind_parent=true
	actor.add_child(rig)

func play_attack(direction: Vector2) -> bool:
	if action in ["attack","hurt","death"]: return false
	action="attack"
	elapsed=0.0
	duration=float(profile.windup)+float(profile.strike)+float(profile.recover)
	attack_direction=direction.normalized() if direction.length_squared()>0.001 else Vector2(facing,0)
	if absf(attack_direction.x)>0.05: facing=signf(attack_direction.x)
	hit_sent=false
	return true

func play_hurt(direction: Vector2) -> void:
	if action=="death": return
	action="hurt"
	elapsed=0.0
	duration=HURT_SECONDS
	hit_sent=true
	hurt_direction=direction.normalized() if direction.length_squared()>0.001 else Vector2(-facing,0)

func play_death() -> void:
	action="death"
	elapsed=0.0
	duration=DEATH_SECONDS
	hit_sent=true
	motion=0.0

func advance(delta: float) -> bool:
	clock+=delta
	if action not in ["attack","hurt","death"]: return false
	elapsed=minf(duration,elapsed+delta)
	var hit:=action=="attack" and not hit_sent and elapsed>=float(profile.windup)+float(profile.strike)*0.5
	if hit: hit_sent=true
	if elapsed>=duration and action!="death": action="idle"
	return hit

func locomotion(delta: float, displacement: Vector2, radius: float, speed: float, direction: float, cultivating: bool) -> void:
	var distance:=displacement.length()
	speed_ratio=clampf(distance/maxf(delta,0.001)/maxf(speed,1),0,1.5)
	var walking:=distance>0.02 and action not in ["attack","hurt","death"]
	if action not in ["attack","hurt","death"]:
		action="run" if walking and speed_ratio>=0.7 else ("walk" if walking else ("cultivate" if cultivating else "idle"))
		if absf(cos(direction))>0.08: facing=signf(cos(direction))
	motion=move_toward(motion,1.0 if walking else 0.0,delta*10)
	if walking: phase=fmod(phase+distance/maxf(8,radius*float(profile.stride))*TAU,TAU)

func locked() -> bool:
	return action in ["attack","hurt","death"]

func sync_pose(radius: float) -> void:
	if not is_instance_valid(rig): return
	var material:ShaderMaterial=rig.material
	var style:String=profile.style
	var amplitude:=lerpf(0.18,0.48,minf(1,speed_ratio))*motion
	var legs:=Vector4(sin(phase),sin(phase+PI),sin(phase+PI),sin(phase))*amplitude
	if style=="hop": legs=Vector4(sin(phase),sin(phase+0.3),sin(phase+PI),sin(phase+PI+0.3))*amplitude
	if style=="claw": legs*=0.7
	var offset:=Vector2(0,-absf(sin(phase))*radius*float(profile.lift)*motion)
	var rotation:=sin(phase)*0.035*motion*facing
	var body_scale:=Vector2(1,1+sin(clock*2.4)*0.012*(1-motion))
	var head:=sin(clock*1.9)*0.025*(1-motion)+sin(phase)*0.045*motion
	var flash:=0.0
	if action=="attack":
		var windup:float=profile.windup
		var strike:float=profile.strike
		var impact:=windup+strike*0.5
		var coil:=clampf(elapsed/windup,0,1) if elapsed<windup else 1.0-smoothstep(windup,impact,elapsed)
		var thrust:=smoothstep(windup,impact,elapsed) if elapsed<impact else 1.0-smoothstep(impact,duration,elapsed)
		offset=-attack_direction*radius*0.22*coil+attack_direction*radius*0.8*thrust
		body_scale=Vector2(1-0.07*coil+0.1*thrust,1+0.04*coil-0.07*thrust)
		head=0.12*coil-0.2*thrust
		legs=Vector4(0.08,0.04,-0.18,-0.12)*coil
		if style=="claw":
			legs.z=-1.0*coil+0.65*thrust
			legs.w=-0.35*coil+0.25*thrust
			rotation=(-0.1*coil+0.15*thrust)*facing
			offset.y-=radius*0.25*coil
		elif style=="charge":
			head=0.22*coil+0.07*thrust
			offset+=attack_direction*radius*0.25*thrust
		else:
			offset.y-=radius*0.3*thrust
	elif action=="hurt":
		var recoil:=sin(clampf(elapsed/HURT_SECONDS,0,1)*PI)
		offset=hurt_direction*radius*0.4*recoil
		rotation=-facing*recoil*0.14
		body_scale=Vector2(1-0.09*recoil,1-0.04*recoil)
		head=-0.16*recoil
		legs=Vector4(-0.12,0.08,0.16,-0.05)*recoil
		flash=maxf(0,1-elapsed/HURT_SECONDS)
	elif action=="death":
		var fall:=smoothstep(0,0.75,elapsed/DEATH_SECONDS)
		rotation=facing*0.28*fall
		body_scale=Vector2(1+0.1*fall,1-0.55*fall)
		offset=Vector2(facing*radius*0.3*fall,radius*0.35*fall)
		legs=Vector4(0.4,0.2,-0.5,-0.3)*fall
		rig.modulate.a=1.0-smoothstep(0.6,1.0,elapsed/DEATH_SECONDS)
	else: rig.modulate.a=1.0
	rig.position=offset
	rig.rotation=rotation
	rig.scale=body_scale*radius*4.2*Vector2(facing,1)
	shadow.position=Vector2(0,radius*0.77)
	shadow.scale=Vector2.ONE*radius*1.35*(1.0-absf(sin(phase))*0.16*motion)
	shadow.modulate.a=rig.modulate.a
	material.set_shader_parameter("leg_angles",legs)
	material.set_shader_parameter("head_angle",head)
	material.set_shader_parameter("tail_angle",sin(clock*3+phase)*0.12*(0.3+motion))
	material.set_shader_parameter("ear_sway",sin(phase+clock)*0.024*(0.2+motion) if style=="hop" else 0.0)
	material.set_shader_parameter("wing_lift",absf(sin(phase*2))*0.06*motion if style=="bird" else 0.0)
	material.set_shader_parameter("hit_flash",flash)

func draw_effects(canvas: CanvasItem, radius: float, monster: bool) -> void:
	if action=="death": return
	if motion>0.3:
		for i in 3:
			var trail:=fmod(phase/TAU+float(i)/3,1.0)
			canvas.draw_circle(Vector2(-facing*radius*(0.4+trail*1.4),radius*(0.7+sin(i*2.0)*0.1)),radius*(0.05+trail*0.13),Color(0.7,0.62,0.42,(1-trail)*0.22*motion))
	if action=="attack":
		var warning:=elapsed<float(profile.windup)
		var angle:=attack_direction.angle()
		var tint:=Color("df8a72") if monster else Color("e5c795")
		if warning:
			tint.a=0.3+0.3*elapsed/float(profile.windup)
			canvas.draw_arc(Vector2.ZERO,radius+14,angle-0.65,angle+0.65,16,tint,2,true)
		elif elapsed<float(profile.windup)+float(profile.strike):
			tint.a=0.85
			for i in (3 if profile.style=="claw" else 1):
				canvas.draw_arc(attack_direction*radius*0.6,radius+8+i*4,angle-0.75,angle+0.6,16,tint,2,true)
