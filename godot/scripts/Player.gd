class_name Player
extends Node2D

## 玩家：只负责数据与绘制，移动/战斗由 Main 驱动。

var game: Node
var radius := 12.0

var aperture := ApertureState.new()
var rank: int:
	get: return aperture.rank
	set(value): aperture.rank=value
var skill_slots: Array[String] = ["","",""]
var vital_gu_id := ""
var jade_guard := false
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

const SPRITE := preload("res://assets/ninja_adventure/samurai_green.png")
var _t := 0.0
var _last_position := Vector2.ZERO
var walking := false


func _process(delta: float) -> void:
	walking = position.distance_to(_last_position)>0.1
	_last_position=position
	_t += delta
	queue_redraw()


func _ready() -> void:
	body = BodyComponent.new()
	body.name = "BodyComponent"
	add_child(body)
	body.setup(rank)
	body.body_died.connect(_on_body_died)


func _on_body_died(reason: String) -> void:
	if game != null and game.has_method("player_death"):
		game.player_death()
		if game.has_method("add_log"):
			game.add_log("你因%s倒下了。" % reason, Color("#d9534f"))


func take_body_hit(damage: float, element: String = "none", region: String = "") -> Dictionary:
	if body == null:
		return {}
	var part := region if region != "" else body.pick_region()
	return body.apply_hit(part, damage * body.get_damage_taken_multiplier(), element)


func reset_stats_for_rank(r: int) -> void:
	aperture = ApertureState.new()
	aperture.rank = clampi(r,1,5)
	max_hp = 100.0
	hp = max_hp
	atk = 11.0
	xp_next = 100.0
	if body != null: body.setup(r)


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
	var bob := sin(_t * 6.0) * 1.2
	# 影子
	draw_circle(Vector2(0, 13), 11.0, Color(0, 0, 0, 0.4))
	if game!=null and game.meditating:
		draw_arc(Vector2(0,8),26+sin(_t*2)*3,0,TAU,40,UIStyle.JADE,2,true)
		draw_arc(Vector2(0,8),34,0,TAU,40,Color(0.7,0.8,0.5,0.4),1,true)
	# 护盾
	if shield > 0.0 or jade_guard:
		draw_arc(Vector2.ZERO, 19.0 + sin(_t * 5.0) * 1.5, 0.0, TAU, 28, Color("9bd59d") if jade_guard else Color(0.69, 0.54, 0.31, 0.85), 2.0)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frame := int(_t*8.0)%4 if walking else 0
	var row := 0
	if sin(dir)<-0.5: row=1
	elif cos(dir)>0.5: row=2
	elif cos(dir)<-0.5: row=3
	draw_texture_rect_region(SPRITE,Rect2(-20,-28,40,40),Rect2(frame*16,row*16,16,16))
	# 武器
	var tip := Vector2(cos(dir), sin(dir))
	draw_line(tip * 8.0, tip * 26.0, Color("#d9c46a"), 2.5)
	# 施法闪光
	if cast_flash > 0.0:
		var a := cast_flash / 0.25
		draw_arc(Vector2.ZERO, 18.0 + (0.25 - cast_flash) * 60.0, 0.0, TAU, 28, Color(0.85, 0.77, 0.42, a), 2.0)
	# 无敌闪烁
	if iframes > 0.0 and int(_t * 20.0) % 2 == 0:
		draw_circle(Vector2.ZERO, 11.0, Color(1, 1, 1, 0.5))
