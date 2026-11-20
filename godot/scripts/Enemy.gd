class_name Enemy
extends Node2D

## 野生蛊虫：数据 + 绘制，AI 与伤害由 Main 驱动。

var kind := ""
var data: Dictionary
var radius := 12.0
var hp := 50.0
var max_hp := 50.0
var atk := 8.0
var spd := 100.0
var color := Color("#ffffff")
var element := "none"
var rank := 1
var display_name := ""
var is_animal := false
var carried_gu: Array = []
var player_pos := Vector2.ZERO
static var low_detail := false
var gu_cast_cd := 2.5

var state := "wander"
var ai := "chase"
var dir := 0.0
var wander_t := 0.0
var atk_cd := 1.0
var stun := 0.0
var flash := 0.0
var shield := 0.0
var dead := false
var moving := false

var wildlife_slot := ""
var habitat_id := ""
var age_seconds := 0.0
var cultivation_seconds := 0.0
var cultivation_stage := 0
var is_monster := false
var cultivating := false
var calm_seconds := 0.0
var threat_time := 0.0
var wildlife_animation: WildlifeAnimation

var status := {
	"burn": 0.0, "poison": 0.0, "wet": 0.0,
	"shock": 0.0, "slow": 0.0, "bleed": 0.0, "bind": 0.0, "frozen": 0.0,
	"poison_tick": 0.0,
}

var _t := 0.0


func setup(id: String) -> void:
	kind = id
	data = GameData.GU[id]
	radius = data["radius"]
	# 蛊虫本体脆弱：野生个体只有图鉴基准的 38% 气血、70% 攻击
	max_hp = data["hp"] * (1.0 + (data["rank"] - 1) * 0.15) * 0.38
	hp = max_hp
	atk = data["atk"] * 0.7
	spd = data["spd"]
	color = data["color"]
	element = data["element"]
	rank = data["rank"]
	display_name = String(data["name"])
	ai = data["ai"]
	state = "wander"
	dir = randf() * TAU
	wander_t = 0.0
	atk_cd = randf_range(0.6, 2.2)
	gu_cast_cd = randf_range(1.5, 3.0)
	carried_gu.clear()
	_t = randf() * TAU




func setup_custom(d: Dictionary) -> void:
	kind = String(d.get("id", "beast"))
	data = d
	display_name = String(d.get("name", "野兽"))
	match kind:
		"rabbit": radius = 10.0
		"deer": radius = 13.0
		"wolf": radius = 15.0
		"bear": radius = 20.0
		"green_wolf": radius = 22.0
		_: radius = 14.0
	max_hp = float(d.get("hp", 60))
	hp = max_hp
	atk = float(d.get("atk", 20))
	spd = 95.0
	match kind:
		"rabbit": color = Color("#b8b0a0")
		"deer": color = Color("#9a7048")
		"wolf": color = Color("#5a5a62")
		"bear": color = Color("#4a3020")
		"green_wolf": color = Color("#3f6a4c")
		_: color = Color("#8a6a4a")
	element = "none"
	rank = int(d.get("rank", 1))
	ai = "chase"
	state = "wander"
	is_animal = true
	carried_gu.clear()
	dir = randf() * TAU
	wander_t = 0.0
	atk_cd = randf_range(0.6, 2.2)
	_t = randf() * TAU
	is_monster=bool(d.get("is_monster",false))
	is_animal=not is_monster
	if d.has("radius"): radius=float(d.radius)
	spd=float(d.get("speed",95.0))
	ai="flee" if d.get("temper","")=="timid" else "chase"
	if WildlifeAnimation.PROFILES.has(kind):
		wildlife_animation=WildlifeAnimation.new()
		wildlife_animation.setup(self,kind)
		wildlife_animation.facing=-1.0 if cos(dir)<0 else 1.0
		wildlife_animation.sync_pose(radius)


func is_creature() -> bool:
	return is_animal or is_monster


func growth_ratio() -> float:
	return clampf(age_seconds/float(data.get("mature",600.0)),0,1)


func growth_name() -> String:
	if growth_ratio()<0.4: return "幼年"
	if growth_ratio()<1.0: return "亚成体"
	return "成年"


func refresh_growth() -> void:
	if not data.has("mature"): return
	var health_ratio:=clampf(hp/maxf(1,max_hp),0,1)
	var ratio:=growth_ratio()
	cultivation_stage=0
	if is_monster:
		for threshold in WildlifeSystem.CULTIVATION_THRESHOLDS:
			if cultivation_seconds>=float(threshold): cultivation_stage+=1
	var strength:=1.0+float(cultivation_stage)*0.18
	max_hp=float(data.hp)*lerpf(0.35,1.0,ratio)*strength
	hp=max_hp*health_ratio
	atk=float(data.atk)*lerpf(0.25,1.0,ratio)*strength
	radius=float(data.radius)*lerpf(0.6,1.0,ratio)
	spd=float(data.speed)*lerpf(0.75,1.0,ratio)
	if wildlife_animation!=null: wildlife_animation.sync_pose(radius)


func life_description() -> String:
	var text:=growth_name()
	if growth_ratio()<1.0: text+=" · 成长 %d%%"%int(growth_ratio()*100)
	if is_monster:
		text+=" · "+WildlifeSystem.CULTIVATION_NAMES[cultivation_stage]
		if cultivating: text+=" · 修炼中"
		if cultivation_stage<3:
			var previous:=0.0 if cultivation_stage==0 else float(WildlifeSystem.CULTIVATION_THRESHOLDS[cultivation_stage-1])
			var next:float=WildlifeSystem.CULTIVATION_THRESHOLDS[cultivation_stage]
			text+=" %d%%"%int((cultivation_seconds-previous)/(next-previous)*100)
	return text


func _process(delta: float) -> void:
	if wildlife_animation==null: _t += delta
	queue_redraw()


func _draw() -> void:
	var bob := sin(_t * 4.0) * 1.5
	var near := player_pos.distance_to(position) < 520.0 and not low_detail and not low_detail
	# 影子
	if wildlife_animation==null:
		draw_circle(Vector2(0, radius * 0.9), radius * 0.9, Color(0, 0, 0, 0.35))
	if not near and ((is_creature() and WildlifeArt.texture(kind)==null) or (not is_creature() and GuArt.texture(kind)==null)):
		# 远处只画简化轮廓，减少 draw call
		draw_circle(Vector2(0, bob), radius, color)
		if hp < max_hp:
			var fw := radius * 2.4
			var fr := clampf(hp / max_hp, 0.0, 1.0)
			draw_rect(Rect2(-fw / 2.0, -radius - 10.0, fw, 3.0), Color(0, 0, 0, 0.5))
			draw_rect(Rect2(-fw / 2.0, -radius - 10.0, fw * fr, 3.0), Color("#5fbf6a") if fr > 0.35 else Color("#d9534f"))
		return

	# 元素状态环
	var ring_col := Color(0, 0, 0, 0)
	if status["burn"] > 0.0:
		ring_col = GameData.el_color("fire")
	elif status["poison"] > 0.0:
		ring_col = GameData.el_color("wood")
	elif status["wet"] > 0.0:
		ring_col = GameData.el_color("water")
	elif status["shock"] > 0.0:
		ring_col = GameData.el_color("thunder")
	if ring_col.a > 0.0:
		draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 24, Color(ring_col, 0.5 + sin(_t * 10.0) * 0.2), 2.0)

	# 身体
	if is_creature():
		_draw_beast(bob)
	elif GuArt.texture(kind)!=null:
		texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		draw_texture_rect(GuArt.texture(kind),GuArt.fitted_rect(kind,Rect2(-radius*1.8,-radius*1.8+bob,radius*3.6,radius*3.6)),false,Color(1,1,1,0.6 if dead else 1.0))
	else:
		match kind:
			"green_snake":
				for i in range(2, -1, -1):
					var a := dir + PI
					var p := Vector2(cos(a), sin(a)) * i * 6.0
					draw_circle(p + Vector2(0, bob), radius * (1.0 - i * 0.18), Color(color, 0.55 + (2 - i) * 0.2))
				draw_circle(Vector2(cos(dir) * 5.0, sin(dir) * 5.0 - 2.0 + bob), 2.0, Color("#0c140d"))
			"red_centipede":
				for i in 5:
					var a := dir + PI + (i - 2) * 0.28
					draw_circle(Vector2(cos(a), sin(a)) * 8.0 + Vector2(0, bob), 4.0, color)
				draw_circle(Vector2(0, bob), radius * 0.75, color)
			"moon_blade":
				var tri := PackedVector2Array([
					Vector2(cos(dir) * (radius + 8.0), sin(dir) * (radius + 8.0)) + Vector2(0, bob),
					Vector2(cos(dir + 2.2) * radius, sin(dir + 2.2) * radius) + Vector2(0, bob),
					Vector2(cos(dir - 2.2) * radius, sin(dir - 2.2) * radius) + Vector2(0, bob),
				])
				draw_colored_polygon(tri, color)
			"stone_armor":
				var hex := PackedVector2Array()
				for i in 6:
					var a := i / 6.0 * TAU
					hex.append(Vector2(cos(a), sin(a)) * radius + Vector2(0, bob))
				draw_colored_polygon(hex, color)
				draw_circle(Vector2(0, bob), radius * 0.5, Color("#6a5430"))
			"wind_wing":
				var dia := PackedVector2Array([
					Vector2(0, -radius) + Vector2(0, bob),
					Vector2(radius * 1.4, 0) + Vector2(0, bob),
					Vector2(0, radius) + Vector2(0, bob),
					Vector2(-radius * 1.4, 0) + Vector2(0, bob),
				])
				draw_colored_polygon(dia, color)
				draw_circle(Vector2(0, bob), 2.5, Color("#0c140d"))
			"leiwen":
				draw_circle(Vector2(0, bob), radius, color)
				draw_line(Vector2(-6, -4 + bob), Vector2(0, 0 + bob), Color("#f0e0ff"), 2.0)
				draw_line(Vector2(0, 0 + bob), Vector2(-3, 4 + bob), Color("#f0e0ff"), 2.0)
				draw_line(Vector2(-3, 4 + bob), Vector2(5, 8 + bob), Color("#f0e0ff"), 2.0)
			_:
				# 其余蛊虫用统一圆体，避免新数据刷出来看不见
				draw_circle(Vector2(0, bob), radius, color)
				draw_circle(Vector2(0, bob), radius * 0.55, Color(0.05, 0.08, 0.05, 0.65))

	if dead: return
	# 宿主身上的蛊：彩色小点绕身
	for i in carried_gu.size():
		var gid := String(carried_gu[i])
		var gcol: Color = GameData.GU[gid]["color"] if GameData.GU.has(gid) else Color("#d9c46a")
		var ang := _t * 2.0 + float(i) * TAU / float(maxi(1, carried_gu.size()))
		var gp := Vector2(cos(ang), sin(ang)) * (radius + 7.0)
		draw_circle(gp + Vector2(0, bob), 2.6, gcol)
		draw_circle(gp + Vector2(0, bob), 1.1, Color("#0c140d"))

	# 受击闪白
	if flash > 0.0 and wildlife_animation==null:
		draw_circle(Vector2(0, bob), radius + 2.0, Color(1, 1, 1, min(0.7, flash / 0.12 * 0.7)))

	# 血条
	var w := radius * 2.4
	var bar_y := -radius*3.8-6.0 if wildlife_animation!=null else -radius-12.0
	draw_rect(Rect2(-w / 2.0, bar_y, w, 4.0), Color(0, 0, 0, 0.6))
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	var bar_col := Color("#5fbf6a")
	if ratio < 0.3:
		bar_col = Color("#d9534f")
	elif ratio < 0.6:
		bar_col = Color("#d9a04a")
	draw_rect(Rect2(-w / 2.0, bar_y, w * ratio, 4.0), bar_col)

	if ratio <= 0.35 and not dead:
		var hint := "可捕获 E"
		if is_creature():
			hint = "可收蛊 E" if not carried_gu.is_empty() else ""
		if hint != "":
			draw_string(ThemeDB.fallback_font, Vector2(-radius - 20.0, bar_y-6.0), hint,
				HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0 + 40.0, 10, Color("#d9c46a"))

func _draw_beast(bob: float) -> void:
	var art:=WildlifeArt.texture(kind)
	if art!=null:
		if wildlife_animation!=null:
			wildlife_animation.draw_effects(self,radius,is_monster)
		else:
			texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
			var side:=radius*4.2
			var rect:=Rect2(-side*0.5,-side*0.72+bob,side,side)
			draw_set_transform(Vector2.ZERO,0,Vector2(-1 if cos(dir)<0 else 1,1))
			draw_texture_rect(art,rect,false)
			draw_set_transform(Vector2.ZERO)
		if dead: return
		if cultivating:
			draw_arc(Vector2(0,radius*0.55),radius*1.35,0,TAU,32,Color(0.4,0.85,0.7,0.4+sin(_t*2)*0.15),2,true)
		if player_pos.distance_to(position)<430:
			var category:="妖兽" if is_monster else "动物"
			var label:=category+" · "+display_name+" · "+growth_name()
			var label_y:=-radius*3.8-13.0 if wildlife_animation!=null else -radius*2.95
			draw_string_outline(ThemeDB.fallback_font,Vector2(-95,label_y),label,HORIZONTAL_ALIGNMENT_CENTER,190,12,3,Color(0.06,0.09,0.07,0.9))
			draw_string(ThemeDB.fallback_font,Vector2(-95,label_y),label,HORIZONTAL_ALIGNMENT_CENTER,190,12,Color("e8a994") if is_monster else Color("e2d6b7"))
		return
	var body_col := color
	var head := Vector2(cos(dir) * radius * 0.95, sin(dir) * radius * 0.95)
	# 四肢
	for sx in [-0.55, 0.55]:
		for sy in [-0.35, 0.35]:
			var leg := Vector2(sx * radius * 0.8, sy * radius * 1.05)
			draw_line(Vector2(sx * radius * 0.4, bob), leg + Vector2(0, bob + 4), body_col.darkened(0.25), 2.0)
	# 躯干
	draw_circle(Vector2(0, bob), radius * 0.85, body_col)
	# 头
	draw_circle(head + Vector2(0, bob), radius * 0.5, body_col.lightened(0.08))
	# 耳朵
	var perp := Vector2(-sin(dir), cos(dir))
	for s in [-1.0, 1.0]:
		var ear_base: Vector2 = head + perp * radius * 0.25 * s + Vector2(0, bob)
		var pt: Vector2 = ear_base + perp * radius * 0.18 * s - Vector2(cos(dir), sin(dir)) * radius * 0.25
		draw_colored_polygon(PackedVector2Array([
			ear_base + perp * radius * 0.12 * s,
			pt,
			ear_base - perp * radius * 0.12 * s,
		]), body_col.darkened(0.1))
	# 眼睛
	draw_circle(head + perp * radius * 0.16 + Vector2(0, bob), 1.8, Color("#e8c84a"))
	draw_circle(head - perp * radius * 0.16 + Vector2(0, bob), 1.8, Color("#e8c84a"))
	# 尾巴
	var tail := -Vector2(cos(dir), sin(dir)) * radius * 1.05 + Vector2(0, bob)
	draw_line(Vector2(0, bob), tail, body_col.darkened(0.2), 2.0)
	if String(kind) == "green_wolf":
		draw_arc(Vector2(0, bob), radius + 5.0, 0.0, TAU, 28, Color(0.25, 0.75, 0.45, 0.45), 2.0)
