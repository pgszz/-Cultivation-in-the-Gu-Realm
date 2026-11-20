class_name BodyGuEffects
extends RefCounted

## 改造与冷却持久化；临时状态读档关闭。数值均为玩法映射。
const BONE_REGIONS := ["head","neck","torso","pelvis","hand_l","hand_r","leg_l","leg_r"]
const LIMBS := ["hand_l","hand_r","leg_l","leg_r"]
const GROUP_NAMES := {"training":"锻体","recovery":"修复","circulation":"血脉","nerves":"神经","mobility":"运动","surface":"表皮","breath":"呼吸","metabolism":"代谢","temperature":"温肌"}
var bone := ""
var tendon_progress := 0.0
var active: Dictionary = {}
var cooldowns: Dictionary = {}
var clock := 0.0

func cancel(id: String) -> void:
	for group in active.keys():
		if active[group].id==id: active.erase(group)

func clear_active() -> void:
	active.clear()

func interrupt(hit: bool = false) -> void:
	active.erase("training")
	if hit:
		for group in active.keys():
			if active[group].get("interrupt_hit",false): active.erase(group)

func applies(state: Dictionary, part: String) -> bool:
	if state.has("part"): return state.part==part
	return not state.has("regions") or state.regions.has(part)

func modifier(field: String, part: String = "") -> float:
	var result:=1.0
	if field=="part_damage":
		if bone!="" and BONE_REGIONS.has(part): result*=float(GameData.GU[bone].skill.bone_factor)
		if LIMBS.has(part): result*=1.0-0.15*tendon_progress
	if field=="strain_gain": result*=1.0-0.35*tendon_progress
	for state in active.values():
		if field=="part_damage" and not applies(state,part): continue
		result*=float(state.get(field,1.0))
	return result

func healing_factor() -> float:
	return 1.0/(1.0+(0.35 if bone!="" else 0.0)+0.25*tendon_progress)

func self_heal_rate(p: Player) -> float:
	return minf(6.0,(p.atk+p.boar_cultivation.attack_bonus())*0.12)*healing_factor()

func targets(sk: Dictionary, selected: String = "") -> Array:
	if sk.get("selected",false): return [selected]
	return sk.get("regions",BONE_REGIONS)

func injured(b: BodyComponent, ids: Array) -> bool:
	for id in ids:
		if b.parts.has(id) and not b.parts[id].destroyed and float(b.parts[id].hp)<float(b.parts[id].max_hp): return true
	return false

func required_ok(b: BodyComponent, sk: Dictionary) -> bool:
	for id in sk.get("required",[]):
		if b.parts[id].destroyed or float(b.parts[id].hp)<=float(b.parts[id].max_hp)*0.3: return false
	if sk.effect=="spring":
		if b.parts.hand_l.destroyed or b.parts.hand_r.destroyed: return false
		if float(b.parts.hand_l.hp)<=float(b.parts.hand_l.max_hp)*0.3 and float(b.parts.hand_r.hp)<=float(b.parts.hand_r.max_hp)*0.3: return false
	return true

func consume(game: Node, gu: GuVirtual) -> void:
	var p:Player=game.player
	var sk:Dictionary=GameData.GU[gu.template_id].skill
	var gus:GuManager=game.get_node("/root/Gus")
	var hunger:HungerSystem=game.get_node("/root/Hunger")
	var aperture_before:=p.aperture.save_data()
	if not p.aperture.spend(float(sk.cost)):
		game._action_message("真元不足。")
		return
	var body_before:=p.body.save_data()
	var hp_before:=p.hp
	var old_bone:=bone
	var slots:=p.skill_slots.duplicate()
	var owned:=p.owned.duplicate()
	var old_instances:=gus.owned_gus.duplicate()
	var old_active:=gus.active_gu
	var food_state:=hunger.save_data()
	if sk.effect=="bone":
		bone=gu.template_id
		p.body.pain=minf(100,p.body.pain+float(sk.pain))
	else:
		for part in p.body.parts.values():
			if not part.destroyed: part.hp=minf(float(part.max_hp),float(part.hp)+float(sk.part_rate))
		p.hp=minf(p.max_hp,p.hp+float(sk.hp_rate))
	p.owned.erase(gu.template_id)
	for i in p.skill_slots.size():
		if p.skill_slots[i]==gu.id: p.skill_slots[i]=""
	gus.remove_gu(gu.id)
	if not game.save_game():
		bone=old_bone
		p.hp=hp_before
		p.body.load_data(body_before)
		p.aperture.load_data(aperture_before)
		p.skill_slots.assign(slots)
		p.owned.assign(owned)
		gus.owned_gus.assign(old_instances)
		gus.active_gu=old_active
		hunger.register_gu(gu.id,gu.rank,gu.quality,gu.preferred_food)
		hunger.load_data(food_state)
		game._action_message("保存失败，身体变化、真元与蛊虫消耗已全部撤回。")
		return
	p.body.state_changed.emit()
	game.fx.burst(p.position.x,p.position.y-20,GameData.GU[gu.template_id].color,18,55,0.8)
	game._action_message(gu.name+"已消耗；"+GameData.GU[gu.template_id].hint)

func tick(delta: float, game: Node) -> void:
	var p:Player=game.player
	for group in active.keys():
		if p.dead or p.body.dead or p.gu_effects.usable(game.get_node("/root/Gus"),active[group].id)==null: active.erase(group)
	if game.paused or game.refining or p.dead or p.body.dead: return
	clock+=delta
	for id in cooldowns.keys():
		cooldowns[id]=maxf(0,float(cooldowns[id])-delta)
		if cooldowns[id]<=0: cooldowns.erase(id)
	for group in active.keys():
		var s:Dictionary=active[group]
		var elapsed:=minf(delta,float(s.left))
		if not required_ok(p.body,s) or (s.has("part") and p.body.parts[s.part].destroyed):
			active.erase(group)
			continue
		if s.effect=="training":
			if game.meditating or not game.can_meditate() or p.position.distance_to(s.start)>0.5:
				active.erase(group)
				continue
			tendon_progress=minf(1,tendon_progress+float(s.training_rate)*elapsed)
			if tendon_progress>=1: active.erase(group)
		if s.effect=="pulse":
			if p.hp<=15 or p.body.blood>=100:
				active.erase(group)
				continue
			elapsed=minf(elapsed,maxf(0,(p.hp-15)/float(s.hp_drain)))
			elapsed=minf(elapsed,maxf(0,(100-p.body.blood)/float(s.blood_rate)))
			p.hp=maxf(15,p.hp-float(s.hp_drain)*elapsed)
			p.body.blood=minf(100,p.body.blood+float(s.blood_rate)*elapsed)
			if p.hp<=15 or p.body.blood>=100: active.erase(group)
		var drain:=float(s.get("stamina_drain",0))
		if drain>0:
			elapsed=minf(elapsed,p.gu_effects.stamina/drain)
			p.gu_effects.stamina=maxf(0,p.gu_effects.stamina-drain*elapsed)
			if p.gu_effects.stamina<=0: active.erase(group)
		if s.effect=="self_heal":
			var weakest:=""
			var ratio:=1.0
			for id in p.body.parts:
				var part:Dictionary=p.body.parts[id]
				if not part.destroyed and float(part.hp)/float(part.max_hp)<ratio:
					ratio=float(part.hp)/float(part.max_hp)
					weakest=id
			var amount:=self_heal_rate(p)*elapsed
			if weakest!="": p.body.heal_part(weakest,amount)
			p.hp=minf(p.max_hp,p.hp+amount)
		if s.has("part_rate"):
			for id in targets(s,String(s.get("part",""))): p.body.heal_part(id,float(s.part_rate)*elapsed)
		p.body.pain=clampf(p.body.pain+float(s.get("pain_rate",0))*elapsed,0,100)
		p.body.consciousness=clampf(p.body.consciousness+float(s.get("conscious_rate",0))*elapsed,0,100)
		p.gu_effects.strain=clampf(p.gu_effects.strain+float(s.get("strain_rate",0))*elapsed,0,100)
		p.gu_effects.stamina=clampf(p.gu_effects.stamina+float(s.get("stamina_rate",0))*elapsed,0,GuEffects.MAX_STAMINA)
		if s.has("clear_state"): p.status[s.clear_state]=maxf(0,float(p.status[s.clear_state])-float(s.clear_rate)*elapsed)
		s.left-=delta
		if s.left<=0: active.erase(group)

func save_data() -> Dictionary:
	return {"bone":bone,"tendon_progress":tendon_progress,"cooldowns":cooldowns.duplicate()}

func load_data(raw: Variant) -> void:
	bone=""
	tendon_progress=0
	active.clear()
	cooldowns.clear()
	if not raw is Dictionary: return
	if raw.get("bone","") in ["iron_bone","jade_bone"]: bone=String(raw.bone)
	var progress:Variant=raw.get("tendon_progress",0)
	if (progress is float or progress is int) and is_finite(float(progress)): tendon_progress=clampf(float(progress),0,1)
	var saved:Variant=raw.get("cooldowns",{})
	if saved is Dictionary:
		for id in saved:
			if not GameData.BODY_GU.has(id) or not (saved[id] is float or saved[id] is int): continue
			if is_finite(float(saved[id])): cooldowns[id]=clampf(float(saved[id]),0,float(GameData.GU[id].skill.cd))

func part_description(part: String) -> String:
	var lines:Array[String]=[]
	if bone!="" and BONE_REGIONS.has(part): lines.append("%s永久改造：部位伤害 ×%.2f"%[GameData.GU[bone].name,GameData.GU[bone].skill.bone_factor])
	if tendon_progress>0 and LIMBS.has(part): lines.append("锻筋 %.1f%%：部位伤害 ×%.3f"%[tendon_progress*100,1-0.15*tendon_progress])
	for s in active.values():
		if not applies(s,part): continue
		lines.append("%s · %.1f 秒\n%s"%[GameData.GU[s.template].name,s.left,GameData.GU[s.template].hint])
	return "\n".join(lines) if not lines.is_empty() else "当前没有作用于此部位的肉身蛊效。"

func draw(canvas: CanvasItem) -> void:
	for group in active:
		var s:Dictionary=active[group]
		var col:Color=GameData.GU[s.template].color
		match group:
			"recovery":
				for i in 4: canvas.draw_arc(Vector2(0,-22),10+i*4,clock+i,clock+i+PI,20,Color(col,0.7),1.3,true)
			"nerves":
				for i in 4: canvas.draw_circle(Vector2.from_angle(clock*2+i*TAU/4)*13+Vector2(0,-36),1.8,col)
			"mobility":
				for side in [-1,1]: canvas.draw_line(Vector2(side*8,-19),Vector2(side*(11+sin(clock*4)*2),1),Color(col,0.65),2,true)
			_:
				canvas.draw_arc(Vector2(0,-19),19,clock,clock+TAU*0.8,30,Color(col,0.6),2,true)

func rejection(game: Node, gu: GuVirtual) -> String:
	var p:Player=game.player
	var b:=p.body
	var sk:Dictionary=GameData.GU[gu.template_id].skill
	if float(cooldowns.get(gu.template_id,0))>0: return "同种蛊共享冷却，还需 %.1f 秒。"%float(cooldowns[gu.template_id])
	if active.has(String(sk.get("group",""))): return "同组身体状态仍在持续，不能叠加或提前续时。"
	if not required_ok(b,sk): return "身体条件不足：所需部位重伤或毁损；B 人体页可查看。"
	if sk.get("consumed",false) and gu.id==p.vital_gu_id: return "本作保护本命蛊，不允许主动消耗本命实例。"
	if sk.get("selected",false):
		var part:String=game.body_ui.selected_part
		if not b.parts.has(part) or b.parts[part].destroyed: return "请在 B 人体页选择未毁损部位；此蛊不能再生。"
		if sk.has("allowed") and not sk.allowed.has(part): return "续节只能作用于手臂或腿。"
	match String(sk.effect):
		"bone":
			if bone!="": return "已完成骨骼改造，铁骨与玉骨不能重复叠加或相互覆盖。"
			if not game.can_meditate() or b.pain>=35 or b.blood<70: return "骨骼改造需要静处、全身止血、疼痛低于 35、血量至少 70。"
		"training":
			if tendon_progress>=1: return "锻筋已达永久上限 100%。"
			if not game.can_meditate() or game.meditating: return "请先收功，并在安全、止血的静处锻筋。"
		"leaf", "self_heal":
			if p.hp>=p.max_hp and not injured(b,b.parts.keys()): return "没有可治疗的伤势；毁损部位不算可修复目标。"
		"eyes", "ears", "joint":
			if not injured(b,targets(sk,game.body_ui.selected_part)): return "对应部位完好或已毁损，无法修复。"
		"pulse":
			if b.blood>=100 or p.hp<=15: return "赤脉需血量未满且气血高于 15；将消耗气血补血量。"
	if float(sk.get("stamina_drain",0))>0 and p.gu_effects.stamina<=0: return "体力不足，无法维持身体状态。"
	return ""

func cast(game: Node, gu: GuVirtual, slot: int) -> bool:
	if not GameData.BODY_GU.has(gu.template_id): return false
	var p:Player=game.player
	if game.paused or p.dead or not p.body.can_cast(): return true
	var reason:=rejection(game,gu)
	if reason!="":
		game._action_message(reason)
		return true
	var sk:Dictionary=GameData.GU[gu.template_id].skill
	if sk.get("consumed",false):
		consume(game,gu)
		return true
	if not p.aperture.spend(float(sk.cost)):
		game._action_message("真元不足。")
		return true
	var state:=sk.duplicate(true)
	state.merge({"id":gu.id,"template":gu.template_id,"left":float(sk.duration),"start":p.position},true)
	if sk.get("selected",false): state["part"]=game.body_ui.selected_part
	active[String(sk.group)]=state
	cooldowns[gu.template_id]=float(sk.cd)
	p.cast_cds[slot]=float(sk.cd)
	p.animation.play("cast",p.dir,0.45)
	game.fx.ring(p.position.x,p.position.y-18,GameData.GU[gu.template_id].color,8,45,0.65)
	game._action_message(gu.name+" · "+GameData.GU[gu.template_id].hint)
	return true
