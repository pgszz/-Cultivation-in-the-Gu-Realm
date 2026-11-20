class_name UtilityGuEffects
extends RefCounted

## 用途蛊的具体效用。原创与改编身份、参数、配方由 GameData 明示。
var active: Dictionary = {}
var cooldowns: Dictionary = {}
var person_status: Dictionary = {}
var clock := 0.0

func has(kind: String) -> bool:
	return active.has(kind) and float(active[kind].left)>0

func cancel(id: String) -> void:
	for kind in active.keys():
		if active[kind].id==id: active.erase(kind)

func clear_active() -> void:
	active.clear()

func break_veil() -> void:
	active.erase("veil")
	active.erase("aptitude_training")

func cultivation_multiplier() -> float:
	return float(active.cultivation.multiplier) if has("cultivation") else 1.0

func speed_multiplier() -> float:
	return float(active.haste.get("multiplier",1.35)) if has("haste") else 1.0

func vision_bonus() -> float:
	return float(active.vision.get("bonus",180.0)) if has("vision") else 0.0

func detection_multiplier() -> float:
	return float(active.veil.get("detection",0.45)) if has("veil") else 1.0

func harvest_bonus(resource: String) -> int:
	if not has("harvest"): return 0
	return int(active.harvest.get(resource+"_bonus",2 if resource=="timber" else 0))

func prospect_site(game: Node, reach: float) -> Dictionary:
	if not game.world.on_surface(): return {}
	var nearest:Dictionary={}
	for site in World.EXPLORATION_SITES:
		if site.kind not in ["timber","rubble"] or float(game.poi_cd.get(site.id,0))>0: continue
		var distance:float=game.player.position.distance_to(Vector2(site.pos)*GameData.TILE)
		if distance<reach:
			reach=distance
			nearest=site
	return nearest

static func status_speed(state: Dictionary) -> float:
	if float(state.get("frozen",0))>0: return 0.0
	if float(state.get("bind",0))>0: return 0.2
	return 0.55 if float(state.get("slow",0))>0 else 1.0

func person_speed(person: Npc) -> float:
	return status_speed(person_status.get(person.resident_id,{}))

func apply_hit(person: Npc, projectile: Dictionary) -> void:
	if person.dead: return
	var state:Dictionary=person_status.get(person.resident_id,{})
	for key in ["burn","slow","bind","wet","frozen","poison"]:
		state[key]=maxf(float(state.get(key,0)),float(projectile.get(key,0)))
	person_status[person.resident_id]=state

func tick(delta: float, game: Node) -> void:
	var p:Player=game.player
	for kind in active.keys():
		if p.dead or p.gu_effects.usable(game.get_node("/root/Gus"),active[kind].id)==null: active.erase(kind)
	if game.paused or game.refining or p.dead: return
	clock+=delta
	for id in cooldowns.keys():
		cooldowns[id]=maxf(0,float(cooldowns[id])-delta)
		if cooldowns[id]<=0: cooldowns.erase(id)
	for kind in active.keys():
		if kind=="aptitude_training":
			var state:Dictionary=active[kind]
			if game.meditating or not game.can_meditate() or p.position.distance_to(state.start)>0.5:
				active.erase(kind)
				game._action_message("资质修炼中断，已练成的增长保留；预付费用不返还。")
				continue
			var gained:=p.aperture.improve_aptitude(float(state.rate)*minf(delta,float(state.left)),float(state.ceiling))
			if gained<=0:
				active.erase(kind)
				continue
		if kind=="regrowth":
			var part:Dictionary=p.body.parts.get(String(active[kind].part),{})
			if part.is_empty() or bool(part.destroyed):
				active.erase(kind)
				continue
			var elapsed:=minf(delta,float(active[kind].left))
			part.hp=minf(float(part.max_hp),float(part.hp)+float(active[kind].part_rate)*elapsed)
			p.hp=minf(p.max_hp,p.hp+float(active[kind].hp_rate)*elapsed)
			p.body.state_changed.emit()
		active[kind].left-=delta
		if active[kind].left<=0: active.erase(kind)
	for person in game.active_npcs():
		if not person_status.has(person.resident_id): continue
		if person.dead:
			person_status.erase(person.resident_id)
			continue
		var state:Dictionary=person_status[person.resident_id]
		var burned:=minf(delta,float(state.get("burn",0)))
		state["burn_tick"]=float(state.get("burn_tick",0))+burned
		state["poison_tick"]=float(state.get("poison_tick",0))+minf(delta,float(state.get("poison",0)))
		for key in ["burn","slow","bind","wet","frozen","poison"]: state[key]=maxf(0,float(state.get(key,0))-delta)
		# Apply discrete real damage; do not rewrite a save on every render frame.
		if state.burn_tick>=1 or (state.burn<=0 and state.burn_tick>0):
			var damage:float=state.burn_tick*6.0
			state.burn_tick=0
			person.take_damage(damage,game,"fire")
		if not person.dead and (state.poison_tick>=1 or (state.poison<=0 and state.poison_tick>0)):
			var damage:float=state.poison_tick*4.0
			state.poison_tick=0
			person.take_damage(damage,game,"wood")
		if state.burn<=0 and state.slow<=0 and state.bind<=0 and state.wet<=0 and state.frozen<=0 and state.poison<=0: person_status.erase(person.resident_id)

func absorb(amount: float, game: Node, element: String = "none") -> float:
	break_veil()
	active.erase("regrowth")
	if has("resist") and String(active.resist.resist_element)==element:
		amount*=1.0-float(active.resist.reduction)
	if not has("shell"): return amount
	var blocked:=minf(amount,float(active.shell.points))
	active.shell.points-=blocked
	game.fx.ring(game.player.position.x,game.player.position.y-18,Color("c8b393"),12,30,0.25)
	game.fx.text(game.player.position.x,game.player.position.y-48,"%s -%.0f"%[GameData.GU[active.shell.template].name,blocked],Color("dec599"),12)
	if active.shell.points<=0: active.erase("shell")
	return amount-blocked

func survey_available(game: Node, reach: float = 850.0) -> bool:
	if not game.world.on_surface(): return false
	var pos:Vector2=game.player.position
	for y in range(maxi(0,int((pos.y-reach)/32)),mini(GameData.MAP_H,int((pos.y+reach)/32)+1)):
		for x in range(maxi(0,int((pos.x-reach)/32)),mini(GameData.MAP_W,int((pos.x+reach)/32)+1)):
			if pos.distance_to(Vector2(x*32+16,y*32+16))<reach and not game.fog.explored.has(y*GameData.MAP_W+x): return true
	return false

func cast(game: Node, gu: GuVirtual, slot: int) -> bool:
	if not GameData.is_utility_gu(gu.template_id): return false
	var p:Player=game.player
	var sk:Dictionary=GameData.GU[gu.template_id].skill
	var kind:String=sk.kind
	var target_part:String=game.body_ui.selected_part
	var found_site:Dictionary={}
	if game.paused or p.dead: return true
	if kind=="relic":
		CultivationGu.use_relic(game,gu)
		return true
	if float(cooldowns.get(gu.template_id,0))>0:
		game._action_message("%s尚需 %.1f 秒恢复，同类蛊共用冷却。" % [gu.name,cooldowns[gu.template_id]])
		return true
	if has(kind):
		game._action_message("效果仍在持续，不能叠加或提前续时。")
		return true
	match kind:
		"aptitude_training":
			if not game.can_meditate() or p.aperture.rank<gu.rank:
				game._action_message("资质修炼需要对应转数，并在远离威胁、止血后的静处进行。")
				return true
			if p.aperture.capacity>=float(sk.ceiling) or p.aperture.aptitude_gain>=20:
				game._action_message("已达到此蛊的资质容量上限，或终身后天增长已达 20 个百分点。")
				return true
			if p.crystals<int(sk.stones):
				game._action_message("资质修炼需预付 %d 元石。"%int(sk.stones))
				return true
		"conscious_restore":
			if p.body.consciousness>=100:
				game._action_message("意识已满，无需催动。")
				return true
		"purify":
			if p.status.poison<=0 and p.status.burn<=0 and p.status.slow<=0 and p.status.shock<=0:
				game._action_message("没有可清除的中毒、灼烧、迟缓或麻痹。")
				return true
		"mend", "regrowth":
			if not p.body.parts.has(target_part) or p.body.parts[target_part].destroyed or float(p.body.parts[target_part].hp)>=float(p.body.parts[target_part].max_hp):
				game._action_message("请先在 B 人体页选择尚未毁损的受伤部位；缝伤不能再生。")
				return true
		"hemostasis":
			target_part=""
			var worst:=0.0
			for id in p.body.parts:
				var rate:float=p.body.part_bleed_rate(id)
				if rate>worst:
					worst=rate
					target_part=id
			if target_part=="":
				game._action_message("没有需要松脂封住的出血伤口。")
				return true
		"cleanse":
			if float(p.status.poison)<=0:
				game._action_message("当前没有中毒；净露不治疗其他伤势。")
				return true
		"survey":
			if not survey_available(game,float(sk.get("range",850))):
				game._action_message("回声只能在地表探明附近未知地形；此处没有可探明的地形。")
				return true
		"prospect":
			found_site=prospect_site(game,float(sk.range))
			if found_site.is_empty():
				game._action_message("附近没有可采集的木石地点；寻材只能在地表使用。")
				return true
		"blood_restore", "clear_slow", "extinguish", "stamina_restore", "soothe":
			var needed:=false
			match kind:
				"blood_restore": needed=p.body.blood<100
				"clear_slow": needed=float(p.status.get("slow",0))>0 or float(p.status.get("shock",0))>0
				"extinguish": needed=p.status.burn>0
				"stamina_restore": needed=p.gu_effects.stamina<GuEffects.MAX_STAMINA
				"soothe": needed=p.gu_effects.strain>0 or p.body.pain>0
			if not needed:
				game._action_message("当前没有需要此蛊处理的状态。")
				return true
	if not p.aperture.spend(float(sk.cost)):
		game._action_message("真元不足。")
		return true
	cooldowns[gu.template_id]=float(sk.cd)
	p.cast_cds[slot]=float(sk.cd)
	var aim:float=(game.get_global_mouse_position()-p.position).angle()
	p.dir=aim
	p.cast_flash=0.3
	p.animation.play("cast",aim,0.4)
	if sk.has("duration"):
		active[kind]=sk.duplicate(true)
		active[kind].merge({"id":gu.id,"template":gu.template_id,"left":float(sk.duration)},true)
	match kind:
		"aptitude_training":
			p.crystals-=int(sk.stones)
			active.aptitude_training["start"]=p.position
		"conscious_restore":
			p.body.consciousness=minf(100,p.body.consciousness+float(sk.amount))
			p.body.state_changed.emit()
		"purify":
			for state in ["poison","burn","slow","shock"]: p.status[state]=0
		"utility_projectile":
			break_veil()
			var projectile:=sk.duplicate(true)
			projectile["gu_id"]=gu.template_id
			projectile["target"]=game.get_global_mouse_position()
			var count:=int(sk.get("count",1))
			for index in count:
				var angle:=aim+(index-(count-1)*0.5)*float(sk.get("spread",0))
				game.spawn_projectile(p.position,Vector2.from_angle(angle)*float(sk.speed),float(sk.dmg),String(sk.element),"player",projectile)
		"mend":
			var part:Dictionary=p.body.parts[target_part]
			part.hp=minf(float(part.max_hp),float(part.hp)+float(sk.get("part_amount",14)))
			p.hp=minf(p.max_hp,p.hp+float(sk.get("hp_amount",6)))
			p.body.state_changed.emit()
		"hemostasis": p.body.stop_bleed(target_part)
		"cleanse": p.status.poison=0
		"blood_restore":
			p.body.blood=minf(100,p.body.blood+float(sk.amount))
			p.body.state_changed.emit()
		"clear_slow":
			p.status.slow=0
			p.status.shock=0
		"extinguish": p.status.burn=0
		"stamina_restore": p.gu_effects.stamina=minf(GuEffects.MAX_STAMINA,p.gu_effects.stamina+float(sk.amount))
		"soothe":
			p.gu_effects.strain=maxf(0,p.gu_effects.strain-float(sk.strain))
			p.body.pain=maxf(0,p.body.pain-float(sk.pain))
			p.body.state_changed.emit()
		"regrowth": active.regrowth["part"]=target_part
		"survey": game.fog.reveal(p.position,float(sk.get("range",850)))
		"prospect":
			var site_pos:Vector2=Vector2(found_site.pos)*GameData.TILE
			game.fog.reveal(site_pos,80)
			var offset:=site_pos-p.position
			var direction:String=["东","东南","南","西南","西","西北","北","东北"][posmod(roundi(offset.angle()/(PI/4)),8)]
			game.add_log("寻材：%s在%s方向，距离 %.0f 格（地图已标出周围地形）。"%[found_site.name,direction,offset.length()/GameData.TILE],Color("c9b28b"))
		"shell":
			active.shell["points"]=float(sk.get("points",32))
			p.jade_guard=false
			p.gu_effects.guard_id=""
			p.gu_effects.cancel(p.gu_effects.ward_id)
	game.fx.ring(p.position.x,p.position.y-18,sk.color,8,48,0.55)
	game.fx.burst(p.position.x,p.position.y-20,sk.color,10,55,0.5)
	game._action_message(gu.name+" · "+String(GameData.GU[gu.template_id].hint))
	return true

func summary() -> String:
	var result:Array[String]=[]
	for kind in active:
		var state:Dictionary=active[kind]
		result.append("%s %.0fs" % [GameData.GU[state.template].skill.name,state.left]+(" / %.0f盾"%state.points if kind=="shell" else ""))
	return " · ".join(result)

func save_data() -> Dictionary:
	return {"cooldowns":cooldowns.duplicate(),"person_status":person_status.duplicate(true)}

func load_data(raw: Variant) -> void:
	active.clear()
	cooldowns.clear()
	person_status.clear()
	if not raw is Dictionary: return
	var saved:Variant=raw.get("cooldowns",{})
	if saved is Dictionary:
		for id in saved:
			if GameData.is_utility_gu(id): cooldowns[id]=clampf(float(saved[id]),0,float(GameData.GU[id].skill.cd))
	var states:Variant=raw.get("person_status",{})
	if states is Dictionary:
		for id in states:
			if not states[id] is Dictionary: continue
			var state:Dictionary={}
			for key in ["burn","slow","bind","burn_tick","wet","frozen","poison","poison_tick"]: state[key]=clampf(float(states[id].get(key,0)),0,6)
			person_status[str(id)]=state

func draw_player(canvas: CanvasItem) -> void:
	for kind in active:
		var col:Color=GameData.GU[active[kind].template].color
		match kind:
			"aptitude_training", "cultivation":
				for i in 3:
					canvas.draw_arc(Vector2(0,-20),16+i*6,clock*(1+i*0.2)+i,clock*(1+i*0.2)+i+PI*1.5,28,Color(col,0.65-i*0.12),1.8,true)
			"haste":
				for i in 3: canvas.draw_arc(Vector2(0,-8+i*8),18+i*3,clock*3+i,clock*3+i+PI,20,Color(col,0.65),1.7,true)
			"vision":
				for side in [-1,1]: canvas.draw_circle(Vector2(side*5,-37),2.2+sin(clock*5)*0.5,Color(col,0.9))
			"shell":
				for i in 7: GuVfx._plate(canvas,Vector2(0,-21)+Vector2.from_angle(i*TAU/7+clock*0.4)*25,Vector2(4,6),col,1)
			"harvest":
				for i in 4: canvas.draw_line(Vector2(16+i*2,-20+i*3),Vector2(20+i*2,-22+i*3),Color(col,0.8),2,true)
			"veil":
				for i in 6:
					var at:=Vector2(sin(clock*0.8+i)*24,-25+cos(clock+i*2)*21)
					canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(-4,0),at+Vector2(0,-2),at+Vector2(5,1),at+Vector2(0,2)]),Color(col,0.55))
			"swim":
				for i in 3: canvas.draw_arc(Vector2(0,2),12+i*5,clock+i,clock+i+PI*1.4,20,Color(col,0.65-i*0.15),1.5,true)
			"regrowth":
				for i in 5: canvas.draw_arc(Vector2(0,-22),12+i*2,clock+i,clock+i+PI,20,Color(col,0.65),1.3,true)
			"resist":
				canvas.draw_arc(Vector2(0,-21),28,0,TAU,32,Color(col,0.4+sin(clock*3)*0.1),3,true)

func draw_world(canvas: CanvasItem, game: Node) -> void:
	for actor in game.active_npcs()+game.active_enemies():
		if actor.dead or not game.fog.can_see(actor.position): continue
		var state:Dictionary=actor.status if actor is Enemy else person_status.get(actor.resident_id,{})
		if float(state.get("frozen",0))>0:
			canvas.draw_rect(Rect2(actor.position+Vector2(-17,-42),Vector2(34,43)),Color(0.6,0.85,0.98,0.3))
		if float(state.get("bind",0))>0:
			for i in 3: canvas.draw_arc(actor.position+Vector2(0,-8-i*7),actor.radius+3,clock+i,clock+i+TAU*0.8,20,Color("8fc46f"),1.8,true)
		elif float(state.get("slow",0))>0:
			canvas.draw_arc(actor.position,actor.radius+5,0,TAU,24,Color("9bd8ee"),1.5,true)
		if float(state.get("burn",0))>0:
			for i in 3: canvas.draw_line(actor.position+Vector2(-8+i*8,-8),actor.position+Vector2(-7+i*8,-22-sin(clock*8+i)*4),Color("ef9755"),2.8,true)
		if float(state.get("poison",0))>0:
			for i in 3: canvas.draw_circle(actor.position+Vector2(sin(clock*2+i)*12,-16-i*8),2.5,Color("a9ce68"))

static func draw_projectile(canvas: CanvasItem, pr: Dictionary) -> void:
	var col:Color=pr.color
	var pos:Vector2=pr.pos
	var along:Vector2=Vector2(pr.vel).normalized()
	var across:=along.orthogonal()
	var trail:Array=pr.get("trail",[])
	for i in range(1,trail.size()):
		canvas.draw_line(trail[i-1],trail[i],Color(col,0.15+float(i)/trail.size()*0.5),2,true)
	match String(pr.gu_id):
		"stream_gu":
			canvas.draw_colored_polygon(PackedVector2Array([pos+along*10,pos+across*6,pos-along*12,pos-across*6]),Color(col,0.85))
			canvas.draw_circle(pos+along*2,3,Color("e2f9ff"))
		"ember_moth":
			GuVfx._star(canvas,pos,9,Color(col,0.9),float(pr.life)*5)
			canvas.draw_circle(pos,3,Color("fff0bb"))
		"frost_midge":
			canvas.draw_line(pos-along*16,pos+along*12,col,3,true)
			canvas.draw_line(pos-along*7+across*5,pos+along*7,col,1.3,true)
			canvas.draw_line(pos-along*7-across*5,pos+along*7,col,1.3,true)
		"vine_spider":
			canvas.draw_circle(pos,5,col)
			canvas.draw_arc(pos,9,float(pr.life)*8,float(pr.life)*8+PI*1.5,16,Color("cfdda2"),1.5,true)
		_:
			var kind:String=String(pr.gu_id)
			if kind in ["stone_pellet","burrow_grub"]:
				GuVfx._plate(canvas,pos,Vector2(9,7),col,1)
			elif kind in ["red_lotus_moth","thunder_pupa","thorn_seed"]:
				GuVfx._star(canvas,pos,9,Color(col,0.9),float(pr.life)*8)
			elif kind=="venom_gnat":
				canvas.draw_circle(pos,5,col)
				canvas.draw_circle(pos-along*6,3,Color(col,0.5))
			else:
				canvas.draw_colored_polygon(PackedVector2Array([pos+along*13,pos+across*4,pos-along*10,pos-across*4]),col)
			canvas.draw_circle(pos,2,Color(col.lightened(0.5)))
