class_name Player
extends Node2D

## 玩家：只负责数据与绘制，移动/战斗由 Main 驱动。

var game: Node
var appearance := CharacterAppearance.new()
var radius := 12.0

var aperture := ApertureState.new()
var rank: int:
	get: return aperture.rank
	set(value): aperture.rank=value
var skill_slots: Array[String] = ["","",""]
var vital_gu_id := ""
var jade_guard := false
var light_support_id := ""
var boar_cultivation := BoarCultivation.new()
var gu_effects := GuEffects.new()
var utility_gu := UtilityGuEffects.new()
var body_gu := BodyGuEffects.new()
var hp := 100.0
var max_hp := 100.0
var yuan: float:
	get: return aperture.total()
	set(value):
		aperture.essence=clampf(value,0,aperture.capacity)
		aperture.refined_essence=0
var max_yuan: float:
	get: return aperture.capacity
	set(value): aperture.capacity=clampf(value,20,99)
var speed := 168.0
var atk := 11.0
var atk_bonus := 0.0
var def_bonus := 0.0
var spd_bonus := 0.0
var buff_time := 0.0
var xiuwei: float:
	get: return aperture.wall_progress
	set(value): aperture.wall_progress=clampf(value,0,100)
var xp_next := 100.0
var crystals := 60
var materials := 0

var owned: Array[String] = []
var captured: Array = []
var discovered: Array[String] = []

var dir := 0.0
var atk_cd := 0.0
var dash_cd := 0.0
var dash_t := 0.0
var iframes := 0.0
var shield := 0.0
var cast_flash := 0.0
var hurt_flash := 0.0
var cast_cds := [0.0, 0.0, 0.0]
var regen := 0.0
var dead := false
var body: BodyComponent
var capture_target = null
var capture_progress := 0.0

var status := {
	"burn": 0.0, "poison": 0.0, "wet": 0.0,
	"shock": 0.0, "slow": 0.0, "bleed": 0.0,
}

var animation := ActorAnimation.new()
var injury_region := ""
var injury_time := 0.0
var injury_severe := false
var _t := 0.0
var _last_position := Vector2.ZERO
var walking := false
var swimming := false


func _process(delta: float) -> void:
	var distance := position.distance_to(_last_position)
	_last_position=position
	# Repositioning on load / entering a house is not a walking stride.
	walking = distance > 0.01 and distance <= maxf(64.0,(speed+spd_bonus)*delta*5.0)
	if game!=null and (not game.running or game.paused) and not (dead and animation.action=="death" and animation.progress()<1):
		walking=false
		return
	_t += delta
	injury_time=maxf(0,injury_time-delta)
	animation.advance(delta,walking,dir,distance if walking else 0.0)
	if dead and animation.action=="death" and animation.progress()>=1 and game!=null:
		game.death_layer.visible=true
	queue_redraw()


func _ready() -> void:
	_last_position=position
	body = BodyComponent.new()
	body.name = "BodyComponent"
	add_child(body)
	body.setup(rank)
	body.gu_changes=body_gu
	body.body_died.connect(_on_body_died)
	body.part_destroyed.connect(_on_part_destroyed)

func _on_part_destroyed(part: String) -> void:
	injury_region=part
	injury_severe=true
	injury_time=0.8
	animation.play("hurt",dir,0.42)


func _on_body_died(reason: String) -> void:
	if game != null and game.has_method("player_death"):
		game.player_death(reason)
		if game.has_method("add_log"):
			game.add_log("你因%s倒下了。" % reason, Color("#d9534f"))


func take_body_hit(damage: float, element: String = "none", region: String = "") -> Dictionary:
	if body == null:
		return {}
	var part := region if region != "" else body.pick_region()
	var result:=body.apply_hit(part, damage * body.get_damage_taken_multiplier(), element)
	injury_region=String(result.get("part",part))
	injury_severe=bool(result.get("destroyed",false))
	injury_time=0.8 if injury_severe else 0.24
	return result


func reset_stats_for_rank(r: int) -> void:
	aperture = ApertureState.new()
	if r>0: aperture.awaken()
	aperture.rank = clampi(r,0,5)
	max_hp = 100.0
	hp = max_hp
	atk = 11.0
	xp_next = 100.0
	body_gu.load_data({})
	if body != null: body.setup(r)

func melee_attack() -> float:
	return atk+atk_bonus+boar_cultivation.attack_bonus()+gu_effects.attack_bonus()


func tick_status(delta: float, main: Node) -> void:
	if body != null:
		body.tick(delta)
		if not dead and not body.dead and body.recovery_delay<=0 and body.total_bleed_rate()<=0 and body.blood>=50 and status.burn<=0 and status.poison<=0 and status.bleed<=0:
			hp=minf(max_hp,hp+0.15*delta)
	for k in ["burn", "poison", "wet", "shock", "slow", "bleed"]:
		if status[k] > 0.0:
			status[k] = max(0.0, status[k] - delta)
			if k == "burn" and randf() < delta * 2.5:
				main.damage_player(2.0, "fire")
			if k == "poison" and randf() < delta * 1.8:
				main.damage_player(1.5, "wood")
			if k == "bleed" and randf() < delta * 2.0:
				main.damage_player(1.5, "metal")


func _draw() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	if dead:
		animation.draw(self,false,0,false,"",appearance)
		return
	if game!=null and game.meditating:
		draw_arc(Vector2(0,8),26+sin(_t*2)*3,0,TAU,40,UIStyle.JADE,2,true)
		draw_arc(Vector2(0,8),34,0,TAU,40,Color(0.7,0.8,0.5,0.4),1,true)
	if game!=null: game.fx.gu.draw_player(self,game,false)
	if shield>0:
		draw_arc(Vector2.ZERO,19,0,TAU,28,Color(0.69,0.54,0.31,0.65),2)
	if swimming: draw_set_transform(Vector2(0,(10.0 if game.world.water_speed(position)<=0.5 else 3.0)+sin(_t*4)*1.3))
	animation.draw(self,false,0,dash_t>0,"",appearance)
	draw_set_transform(Vector2.ZERO)
	if swimming:
		# Water covers the feet; the wake follows actual movement and game time.
		draw_set_transform(Vector2(0,1),0,Vector2(1,0.65))
		draw_circle(Vector2.ZERO,18,Color(0.2,0.5,0.57,0.78))
		for i in 2:
			draw_arc(Vector2.ZERO,18+i*7+sin(_t*4+i)*2,0,TAU,28,Color(0.7,0.91,0.93,0.65-i*0.2),1.6,true)
		draw_set_transform(Vector2.ZERO)
	_draw_injury()
	body_gu.draw(self)
	if game!=null: game.fx.gu.draw_player(self,game,true)
	if not dead: utility_gu.draw_player(self)
	# 无敌闪烁
	if iframes > 0.0 and int(_t * 20.0) % 2 == 0:
		draw_circle(Vector2.ZERO, 11.0, Color(1, 1, 1, 0.5))

func _draw_injury() -> void:
	if injury_time<=0: return
	var point:=Vector2(0,-26)
	if injury_region in ["head","neck","eye_l","eye_r","ear_l","ear_r","mouth","nose"]: point.y=-43
	elif injury_region.begins_with("leg") or injury_region in ["pelvis","groin"]: point.y=-5
	if injury_region.ends_with("_l"): point.x=-7
	elif injury_region.ends_with("_r"): point.x=7
	var lifetime:=0.8 if injury_severe else 0.24
	var progress:=1.0-injury_time/lifetime
	var color:=Color(0.95,0.58,0.38,1-progress)
	for i in (7 if injury_severe else 4):
		var direction:=Vector2.from_angle(i*TAU/(7 if injury_severe else 4))
		draw_line(point+direction*(3+progress*6),point+direction*(7+progress*12),color,2,true)
