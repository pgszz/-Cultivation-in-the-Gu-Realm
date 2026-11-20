class_name GuEffects
extends RefCounted

## 已核对蛊虫的具体效用；数值映射与供养抽象见 CANON。
const MAX_STAMINA := 100.0
var guard_id := ""
var ward_id := ""
var ward_target: Node2D
var brute_id := ""
var brute_left := 0.0
var endurance_id := ""
var endurance_left := 0.0
var leap_cd := 0.0
var stamina := MAX_STAMINA
var strain := 0.0

func usable(gus: GuManager, id: String) -> GuVirtual:
	var gu:=gus.get_gu_by_id(id)
	return gu if gu!=null and not gu.dead and gu.location!="bag" else null

func cancel(id: String) -> void:
	if guard_id==id: guard_id=""
	if ward_id==id:
		ward_id=""
		ward_target=null
	if brute_id==id:
		brute_id=""
		brute_left=0
	if endurance_id==id:
		endurance_id=""
		endurance_left=0

func tick(delta: float, p: Player, gus: GuManager) -> void:
	stamina=minf(MAX_STAMINA,stamina+8.0*delta)
	strain=maxf(0,strain-delta)
	leap_cd=maxf(0,leap_cd-delta)
	brute_left=maxf(0,brute_left-delta)
	endurance_left=maxf(0,endurance_left-delta)
	if brute_left<=0 or usable(gus,brute_id)==null:
		brute_id=""
		brute_left=0
	if endurance_left<=0 or usable(gus,endurance_id)==null:
		endurance_id=""
		endurance_left=0
	if guard_id!="":
		var gu:=usable(gus,guard_id)
		if gu==null or not p.aperture.spend(float(GameData.GU[gu.template_id].skill.upkeep)*delta):
			guard_id=""
	if ward_id!="":
		var gu:=usable(gus,ward_id)
		var game:Node=p.get_parent()
		if gu==null or not ward_valid(game) or not p.aperture.spend(float(GameData.GU[gu.template_id].skill.upkeep)*delta):
			ward_id=""
			ward_target=null

func ward_valid(game: Node) -> bool:
	if ward_id=="" or game.player.dead or usable(game.get_node("/root/Gus"),ward_id)==null: return false
	return is_instance_valid(ward_target) and not ward_target.dead and not ward_target.hostile and game.active_npcs().has(ward_target) and game.player.position.distance_to(ward_target.position)<=180 and not game.world.collides(ward_target.position.x,ward_target.position.y,2)

func absorb_ally_damage(amount: float, target: Node2D, source: Node2D, game: Node) -> float:
	if ward_id=="" or target!=ward_target or source==game.player or not ward_valid(game): return amount
	var gu:=usable(game.get_node("/root/Gus"),ward_id)
	if gu==null: return amount
	var sk:Dictionary=GameData.GU[gu.template_id].skill
	if not game.player.aperture.spend(amount*float(sk.hit_cost)):
		cancel(ward_id)
		return amount
	var reduced:=amount*float(sk.reduction)
	game.fx.gu.guard_hit(target.position,"moon_raiment",reduced,false)
	return amount-reduced

func attack_bonus() -> float:
	return 22.0 if brute_left>0 else 0.0

func stamina_cost(base: float) -> float:
	return base*(0.4 if endurance_left>0 else 1.0)

func spend_stamina(base: float) -> bool:
	var cost:=stamina_cost(base)
	if stamina<cost: return false
	stamina-=cost
	return true

func absorb_damage(amount: float, p: Player, gus: GuManager) -> float:
	if guard_id=="": return amount
	var gu:=usable(gus,guard_id)
	if gu==null:
		guard_id=""
		return amount
	var skill:Dictionary=GameData.GU[gu.template_id].skill
	if not p.aperture.spend(amount*float(skill.hit_cost)):
		guard_id=""
		return amount
	return amount*(1.0-float(skill.reduction))

func cast(game: Node, gu: GuVirtual, slot: int) -> bool:
	var sk:Dictionary=GameData.GU[gu.template_id].skill
	if sk.kind not in ["skin_guard","brute_force","endurance","cricket_leap"]: return false
	var p:Player=game.player
	if sk.kind=="skin_guard":
		if guard_id==gu.id or ward_id==gu.id:
			guard_id=""
			ward_id=""
			ward_target=null
			game._action_message("已停止%s护体。" % gu.name)
		elif not p.aperture.can_spend(float(sk.upkeep)):
			game._action_message("真元不足以维持%s。" % gu.name)
		else:
			guard_id=gu.id
			ward_id=""
			ward_target=null
			p.jade_guard=false
			p.utility_gu.active.erase("shell")
			if gu.template_id=="moon_raiment":
				var distance:=36.0
				for person in game.active_npcs():
					var cursor_distance:float=person.position.distance_to(game.get_global_mouse_position())
					if person is WorldPerson and not person.dead and not person.hostile and p.position.distance_to(person.position)<=180 and cursor_distance<distance:
						ward_target=person
						distance=cursor_distance
				if ward_target!=null:
					ward_id=gu.id
					guard_id=""
			p.animation.play("cast",p.dir,0.32)
			game._action_message("%s正在庇护%s；持续与受击耗元，超出 180 像素会消散。" % [gu.name,ward_target.npc_name] if ward_target!=null else "%s护体开启；持续与受击耗元，其他护体不叠加。" % gu.name)
		p.cast_cds[slot]=0.3
		return true
	if sk.kind=="brute_force" and brute_left>0:
		game._action_message("蛮力仍在生效，不能叠加或提前续时。")
		return true
	if sk.kind=="endurance" and endurance_left>0:
		game._action_message("黄骆耐力仍在生效，无需重复催动。")
		return true
	var origin:=p.position
	var destination:=origin
	if sk.kind=="cricket_leap":
		if leap_cd>0:
			game._action_message("腾跃尚未恢复。")
			return true
		if not p.body.can_dash():
			game._action_message("腿部伤势使你无法借蛐蛐蛊腾跃；它不能修复伤腿。")
			return true
		if stamina<stamina_cost(20):
			game._action_message("体力不足以腾跃，稍作休息。")
			return true
		var direction:Vector2=(game.get_global_mouse_position()-p.position).normalized()
		for step in 28:
			# Sample from the fixed origin to avoid accumulated rounding at distant map coordinates.
			var next:Vector2=origin+direction*((step+1)*4.0)
			if game.world.collides(next.x,next.y,p.radius,true): break
			destination=next
		if destination.distance_to(p.position)<8:
			game._action_message("前方没有腾跃空间。")
			return true
	if not p.aperture.spend(float(sk.cost)):
		game._action_message("真元不足。")
		return true
	match sk.kind:
		"brute_force":
			brute_id=gu.id
			brute_left=5.0
			strain=minf(100,strain+35.0*(1.0-p.boar_cultivation.progress*0.4)*p.body_gu.modifier("strain_gain"))
			if strain>65:
				for id in ["hand_l","hand_r"]:
					if not p.body.parts[id].destroyed: p.body.apply_hit(id,6.0)
				p.hp=maxf(1,p.hp-4)
				game._action_message("频繁爆发超出身体承受：双臂肌肉拉伤。蛮力只持续 5 秒。")
			else:
				game._action_message("蛮力爆发 5 秒，肉身攻击 +22；连续使用可能拉伤。")
		"endurance":
			endurance_id=gu.id
			endurance_left=15.0
			game._action_message("黄骆耐力 15 秒：疾步与腾跃体力消耗减少 60%。")
		"cricket_leap":
			spend_stamina(20)
			p.position=destination
			leap_cd=2.0
			p.dash_t=0
			p.dir=(destination-origin).angle()
			game.fx.gu.emit("leap",destination,gu.template_id,0.45,{"from":origin})
			game._action_message("借蛐蛐蛊腾跃闪避；碰到障碍会停下。")
	p.cast_cds[slot]=float(sk.cd)
	p.cast_flash=0.25
	p.animation.play("cast",p.dir,0.28)
	return true

func summary(gus: GuManager) -> String:
	var out:Array[String]=[]
	var guard:=usable(gus,guard_id)
	if guard!=null: out.append(guard.name+"护体")
	if ward_id!="" and is_instance_valid(ward_target): out.append("月衣庇护·"+ward_target.npc_name)
	if brute_left>0: out.append("蛮力 %.1fs" % brute_left)
	if endurance_left>0: out.append("耐力 %.1fs" % endurance_left)
	return " · ".join(out)

func save_data() -> Dictionary:
	return {"stamina":stamina,"strain":strain}

func load_data(data: Dictionary) -> void:
	stamina=clampf(float(data.get("stamina",MAX_STAMINA)),0,MAX_STAMINA)
	strain=clampf(float(data.get("strain",0)),0,100)
	guard_id=""
	ward_id=""
	ward_target=null
	brute_id=""
	brute_left=0
	endurance_id=""
	endurance_left=0
	leap_cd=0
