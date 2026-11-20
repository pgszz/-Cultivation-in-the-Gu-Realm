class_name BodyComponent
extends Node

## 人体部位伤害：15 部位双层生命。
## 对应文档：《人体结构系统设计.md》。

signal part_destroyed(part_id: String)
signal body_died(reason: String)
signal state_changed

const PARTS := {
	"head": {"name": "头部", "hp": 35.0, "armor": 1.0, "coverage": 8.0, "pain": 8.0, "bleed": 4.0, "vital": true, "mult": 1.2, "parent": ""},
	"neck": {"name": "颈部", "hp": 20.0, "armor": 0.6, "coverage": 3.0, "pain": 6.0, "bleed": 10.0, "vital": true, "mult": 1.1, "parent": "torso"},
	"torso": {"name": "胸腹", "hp": 60.0, "armor": 1.2, "coverage": 22.0, "pain": 5.0, "bleed": 6.0, "vital": true, "mult": 1.0, "parent": ""},
	"pelvis": {"name": "骨盆", "hp": 50.0, "armor": 1.1, "coverage": 18.0, "pain": 5.0, "bleed": 5.0, "vital": false, "mult": 1.0, "parent": ""},
	"ear_l": {"name": "左耳", "hp": 8.0, "armor": 0.3, "coverage": 1.0, "pain": 4.0, "bleed": 1.0, "vital": false, "mult": 1.0, "parent": "head"},
	"ear_r": {"name": "右耳", "hp": 8.0, "armor": 0.3, "coverage": 1.0, "pain": 4.0, "bleed": 1.0, "vital": false, "mult": 1.0, "parent": "head"},
	"eye_l": {"name": "左眼", "hp": 6.0, "armor": 0.2, "coverage": 1.0, "pain": 10.0, "bleed": 2.0, "vital": false, "mult": 1.5, "parent": "head"},
	"eye_r": {"name": "右眼", "hp": 6.0, "armor": 0.2, "coverage": 1.0, "pain": 10.0, "bleed": 2.0, "vital": false, "mult": 1.5, "parent": "head"},
	"nose": {"name": "鼻部", "hp": 8.0, "armor": 0.4, "coverage": 2.0, "pain": 6.0, "bleed": 3.0, "vital": false, "mult": 1.0, "parent": "head"},
	"mouth": {"name": "口部", "hp": 10.0, "armor": 0.3, "coverage": 2.0, "pain": 4.0, "bleed": 2.0, "vital": false, "mult": 1.0, "parent": "head"},
	"hand_l": {"name": "左臂与手", "hp": 18.0, "armor": 0.8, "coverage": 9.0, "pain": 4.0, "bleed": 3.0, "vital": false, "mult": 1.0, "parent": "torso"},
	"hand_r": {"name": "右臂与手", "hp": 18.0, "armor": 0.8, "coverage": 9.0, "pain": 4.0, "bleed": 3.0, "vital": false, "mult": 1.0, "parent": "torso"},
	"leg_l": {"name": "左腿", "hp": 30.0, "armor": 0.9, "coverage": 10.0, "pain": 4.0, "bleed": 4.0, "vital": false, "mult": 1.0, "parent": "pelvis"},
	"leg_r": {"name": "右腿", "hp": 30.0, "armor": 0.9, "coverage": 10.0, "pain": 4.0, "bleed": 4.0, "vital": false, "mult": 1.0, "parent": "pelvis"},
	"groin": {"name": "会阴", "hp": 12.0, "armor": 0.4, "coverage": 3.0, "pain": 12.0, "bleed": 3.0, "vital": false, "mult": 1.0, "parent": "pelvis"},
}

var parts: Dictionary = {}
var blood := 100.0
var pain := 0.0
var consciousness := 100.0
var unconscious := false
var dead := false
var neck_timer := -1.0
var unconscious_timer := 0.0
var rank := 1
var physique := 0
var recovery_delay := 0.0
var gu_changes: BodyGuEffects

var _rng := RandomNumberGenerator.new()


func setup(r: int, phys: int = 0) -> void:
	rank = clampi(r, 1, 5)
	physique = phys
	reset_full()


func reset_full() -> void:
	parts.clear()
	recovery_delay = 0.0
	for id in PARTS:
		var base: Dictionary = PARTS[id]
		var mx := float(base["hp"]) * (1.0 + 0.02 * float(physique))
		parts[id] = {
			"id": id,
			"name": base["name"],
			"max_hp": mx,
			"hp": mx,
			"armor": float(base["armor"]),
			"coverage": float(base["coverage"]),
			"pain": float(base["pain"]),
			"bleed": float(base["bleed"]),
			"vital": bool(base["vital"]),
			"mult": float(base["mult"]),
			"parent": String(base["parent"]),
			"destroyed": false,
			"bandaged": false,
		}
	blood = 100.0
	pain = 0.0
	consciousness = 100.0
	unconscious = false
	dead = false
	neck_timer = -1.0
	unconscious_timer = 0.0
	state_changed.emit()


func pick_region() -> String:
	var roll := _rng.randf_range(0.0, 100.0)
	var acc := 0.0
	for id in PARTS:
		acc += float(PARTS[id]["coverage"])
		if roll <= acc:
			return id
	return "torso"


func apply_hit(region: String, damage: float, element: String = "none") -> Dictionary:
	if dead:
		return {"dead": true}
	recovery_delay = 8.0
	var id := _redirect(region)
	var p: Dictionary = parts[id]
	var final := maxf(1.0, damage)
	var part_mult := float(p["mult"])
	var armor_mult := 1.0 - float(p["armor"]) * 0.3
	var part_damage := final * part_mult * armor_mult
	# 元素部位加成
	if element == "fire" and (id == "eye_l" or id == "eye_r" or id == "mouth"):
		part_damage *= 1.2
	elif element == "thunder" and id == "head":
		part_damage *= 1.1
	if gu_changes!=null: part_damage*=gu_changes.modifier("part_damage",id)
	var destroyed_now := false
	var was_destroyed: bool = bool(p["destroyed"])
	if not was_destroyed:
		p["bandaged"] = false
		p["hp"] = maxf(0.0, float(p["hp"]) - part_damage)
		if float(p["hp"]) <= 0.0:
			destroyed_now = true
			_destroy(id)
	pain = minf(100.0, pain + float(p["pain"]) * 0.7 * (gu_changes.modifier("pain_taken") if gu_changes!=null else 1.0))
	consciousness = maxf(0.0, consciousness - part_damage * 0.08)
	if pain >= 100.0 or consciousness <= 0.0:
		unconscious = true
	if float(p["hp"]) <= 0.0 and not destroyed_now:
		pass
	state_changed.emit()
	return {
		"part": id,
		"name": p["name"],
		"part_damage": part_damage,
		"destroyed": destroyed_now,
		"dead": dead,
	}


func _redirect(region: String) -> String:
	var id := region
	var guard := 0
	while parts.has(id) and bool(parts[id]["destroyed"]) and guard < 4:
		var parent := String(parts[id]["parent"])
		if parent == "" or not parts.has(parent):
			break
		id = parent
		guard += 1
	return id if parts.has(id) else "torso"


func _destroy(id: String) -> void:
	var p: Dictionary = parts[id]
	p["destroyed"] = true
	p["hp"] = 0.0
	part_destroyed.emit(id)
	match id:
		"head":
			_die("头部毁坏")
		"torso":
			_die("上半身毁坏")
		"neck":
			neck_timer = 3.0
		"groin":
			pain = minf(100.0, pain + 30.0 * (gu_changes.modifier("pain_taken") if gu_changes!=null else 1.0))


func _die(reason: String) -> void:
	if dead:
		return
	dead = true
	body_died.emit(reason)


func tick(delta: float) -> void:
	if dead:
		return
	recovery_delay = maxf(0.0,recovery_delay-delta)
	var bleed := total_bleed_rate()
	blood = maxf(0.0, blood - bleed * delta)
	pain = maxf(0.0, pain - 3.0 * delta)
	if neck_timer >= 0.0:
		neck_timer -= delta
		if neck_timer <= 0.0:
			_die("颈部大出血")
			return
	# 头部重伤会持续压意识
	if not bool(parts["head"]["destroyed"]) and float(parts["head"]["hp"]) <= float(parts["head"]["max_hp"]) * 0.3:
		consciousness = maxf(0.0, consciousness - 1.0 * delta)
	if pain >= 100.0 or consciousness <= 0.0:
		unconscious = true
	elif pain < 50.0 and consciousness > 40.0:
		unconscious = false
	if unconscious:
		unconscious_timer += delta
		if unconscious_timer >= 60.0:
			_die("昏迷过久")
	else:
		unconscious_timer = 0.0
	if blood <= 0.0:
		_die("失血过多")
	if not dead and recovery_delay<=0.0 and bleed<=0.0:
		for p in parts.values():
			if not bool(p.destroyed):
				p.hp=minf(float(p.max_hp),float(p.hp)+0.12*delta)
		blood=minf(100.0,blood+0.25*delta)
		consciousness=minf(100.0,consciousness+delta)



func part_bleed_rate(id: String) -> float:
	if not parts.has(id): return 0.0
	var p: Dictionary = parts[id]
	if bool(p.get("bandaged", false)): return 0.0
	var factor:=gu_changes.modifier("bleed") if gu_changes!=null else 1.0
	if bool(p["destroyed"]): return float(p["bleed"])*factor
	if float(p["hp"]) <= float(p["max_hp"]) * 0.3: return float(p["bleed"]) * 0.3 * factor
	return 0.0


func total_bleed_rate() -> float:
	var rate := 0.0
	for id in parts: rate += part_bleed_rate(id)
	return rate


func get_move_multiplier() -> float:
	if dead:
		return 0.0
	var m := 1.0
	if bool(parts["pelvis"]["destroyed"]):
		m *= 0.5
	elif float(parts["pelvis"]["hp"]) <= float(parts["pelvis"]["max_hp"]) * 0.3:
		m *= 0.7
	var legs_destroyed := 0
	for id in ["leg_l", "leg_r"]:
		if bool(parts[id]["destroyed"]):
			legs_destroyed += 1
			m *= 0.6
		elif float(parts[id]["hp"]) <= float(parts[id]["max_hp"]) * 0.3:
			m *= 0.7
	if legs_destroyed >= 2:
		m = minf(m, 0.3)
	if unconscious:
		m *= 0.5
	return clampf(m, 0.1, 1.0)


func can_dash() -> bool:
	if dead or unconscious:
		return false
	if bool(parts["pelvis"]["destroyed"]):
		return false
	for id in ["leg_l", "leg_r"]:
		if bool(parts[id]["destroyed"]):
			return false
		if float(parts[id]["hp"]) <= float(parts[id]["max_hp"]) * 0.3:
			return false
	return true


func can_cast() -> bool:
	return not dead and not unconscious

func get_cast_cost_multiplier() -> float:
	return 1.0


func get_attack_speed_multiplier() -> float:
	var m := 1.0
	for id in ["hand_l", "hand_r"]:
		if bool(parts[id]["destroyed"]):
			m *= 0.7
		elif float(parts[id]["hp"]) <= float(parts[id]["max_hp"]) * 0.3:
			m *= 0.9
	if unconscious:
		m *= 0.6
	return clampf(m, 0.3, 1.0)*(gu_changes.modifier("attack_speed") if gu_changes!=null else 1.0)


func get_accuracy() -> float:
	var acc := 1.0
	var eyes_destroyed := 0
	for id in ["eye_l", "eye_r"]:
		if bool(parts[id]["destroyed"]):
			eyes_destroyed += 1
			acc -= 0.25
		elif float(parts[id]["hp"]) <= float(parts[id]["max_hp"]) * 0.3:
			acc -= 0.10
	if eyes_destroyed >= 2:
		acc = 0.4
	if pain >= 60.0:
		acc -= 0.2
	var blood_lost := 100.0 - blood
	acc -= floorf(blood_lost / 10.0) * 0.03
	if unconscious:
		acc -= 0.3
	return clampf(acc, 0.15, 1.0)


func get_vision_multiplier() -> float:
	var vision := 1.0
	var lost := 0
	for id in ["eye_l","eye_r"]:
		var p: Dictionary = parts[id]
		if p.destroyed:
			vision *= 0.5
			lost += 1
		else:
			vision *= lerpf(0.5,1.0,float(p.hp)/float(p.max_hp))
	return 0.12 if lost==2 else clampf(vision,0.12,1.0)


func get_damage_taken_multiplier() -> float:
	return 1.5 if unconscious else 1.0


func heal_all(amount: float) -> void:
	for id in parts:
		var p: Dictionary = parts[id]
		if not bool(p["destroyed"]):
			p["hp"] = minf(float(p["max_hp"]), float(p["hp"]) + amount)
	pain = maxf(0.0, pain - amount * 2.0)
	consciousness = minf(100.0, consciousness + amount)
	blood = minf(100.0, blood + amount * 0.5)
	state_changed.emit()


func heal_part(id: String, amount: float) -> void:
	if parts.has(id):
		var p: Dictionary = parts[id]
		if not bool(p["destroyed"]):
			p["hp"] = minf(float(p["max_hp"]), float(p["hp"]) + amount)
		state_changed.emit()


func destroyed_count() -> int:
	var n := 0
	for id in parts:
		if bool(parts[id]["destroyed"]):
			n += 1
	return n


func worst_parts() -> Array:
	var out: Array = []
	for id in parts:
		var p: Dictionary = parts[id]
		if bool(p["destroyed"]) or float(p["hp"]) <= float(p["max_hp"]) * 0.3:
			out.append(String(p["name"]))
	return out

func stop_bleed(part_id: String = "") -> void:
	if part_id == "" or part_id == "neck":
		neck_timer = -1.0
	for id in parts:
		if part_id == "" or id == part_id:
			parts[id]["bandaged"] = true
	state_changed.emit()


func part_status(id: String) -> String:
	var p: Dictionary = parts[id]
	if bool(p.destroyed): return "毁损"
	var ratio := float(p.hp) / float(p.max_hp)
	if ratio <= 0.3: return "重伤"
	if ratio < 0.75: return "受伤"
	if ratio < 1.0: return "轻伤"
	return "完好"


func part_description(id: String) -> String:
	match id:
		"head": return "维持意识。耐久低于 30% 时意识每秒下降 1 点；毁损会立即死亡。"
		"neck": return "重要血管所在。毁损后触发 3 秒急救倒计时；及时包扎可阻止致命出血。"
		"torso": return "胸腔与腹部，保护核心脏器。毁损会立即死亡。"
		"pelvis": return "支撑躯干和双腿。重伤时移动速度降至 70%；毁损时降至 50% 且不能疾步。"
		"hand_l", "hand_r": return "包括手臂与手掌，用于攻击和持物。单侧重伤使攻击速度乘 90%，毁损乘 70%；是否需要完整肢体取决于具体蛊虫，不能一概禁蛊。"
		"leg_l", "leg_r": return "支撑行走与疾步。单腿重伤使移速乘 70%，毁损乘 60%；任一腿重伤即无法疾步，双腿毁损移速最多 30%。"
		"eye_l", "eye_r": return "眼伤会连续缩小视野。单眼毁损视野减半，双眼毁损仅余 12% 近身感知；单眼重伤精准度 -10%，毁损 -25%，双眼毁损基础精准度 40%。"
		"ear_l", "ear_r": return "外耳损伤会产生疼痛与出血。当前版本没有额外听觉或视野减益。"
		"nose": return "面部软组织，受伤产生疼痛，重伤或毁损会出血。当前没有额外嗅觉减益。"
		"mouth": return "影响进食与发声，不自动禁止全部蛊虫；火焰对此部位额外造成 20% 部位伤害。"
		"groin": return "脆弱的会阴部位。毁损额外增加 30 点疼痛；疼痛达到 100 会导致昏迷。"
	return ""


func treatment_hint(id: String) -> String:
	var p: Dictionary = parts[id]
	if bool(p.destroyed):
		return "已包扎，当前不再出血。普通包扎不能恢复毁损部位；需要有明确再生效用的蛊术，普通医者不能修复。" if bool(p.get("bandaged",false)) else "先包扎止血；普通医者不能使缺失部位再生。普通绷带不能恢复毁损部位。"
	if float(p.hp) >= float(p.max_hp): return "此部位完好，无需消耗治疗物品。"
	if bool(p.get("bandaged",false)): return "已包扎。脱离受击 8 秒且全身止血后，每秒恢复 0.12 耐久；再次受击会重新出血。"
	return "使用 1 份绷带：止住此部位出血，恢复 12 点耐久。脱离受击 8 秒且全身止血后也会自然恢复。毁损部位不会随时间再生。"


func save_data() -> Dictionary:
	var saved := {}
	for id in parts:
		saved[id] = {"hp": parts[id].hp, "destroyed": parts[id].destroyed, "bandaged": parts[id].get("bandaged",false)}
	return {"parts":saved,"blood":blood,"pain":pain,"consciousness":consciousness,"neck_timer":neck_timer,"unconscious":unconscious,"unconscious_timer":unconscious_timer,"dead":dead}


func load_data(data: Dictionary) -> void:
	if data.is_empty(): return
	if bool(data.get("dead",false)):
		reset_full()
		return
	var saved: Dictionary = data.get("parts",{})
	for id in parts:
		if saved.has(id) and saved[id] is Dictionary:
			parts[id].hp = clampf(float(saved[id].get("hp",parts[id].max_hp)),0,parts[id].max_hp)
			parts[id].destroyed = bool(saved[id].get("destroyed",false))
			parts[id].bandaged = bool(saved[id].get("bandaged",false))
			if parts[id].destroyed: parts[id].hp = 0.0
	blood = clampf(float(data.get("blood",100)),0,100)
	pain = clampf(float(data.get("pain",0)),0,100)
	consciousness = clampf(float(data.get("consciousness",100)),0,100)
	neck_timer = clampf(float(data.get("neck_timer",-1)),-1,3)
	unconscious = bool(data.get("unconscious",false))
	unconscious_timer = clampf(float(data.get("unconscious_timer",0)),0,60)
	state_changed.emit()
