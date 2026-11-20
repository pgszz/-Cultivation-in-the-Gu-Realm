class_name PlayerStatus
extends RefCounted

## 只读人物信息；移动结算也使用同一组倍率，避免面板漏算环境。
static func movement(game: Node, direction: Vector2) -> Dictionary:
	var p:Player=game.player
	var factors:Array=[]
	factors.append(["身体伤势",p.body.get_move_multiplier()])
	factors.append(["蛊术加速",p.utility_gu.speed_multiplier()])
	factors.append(["肉身蛊效",p.body_gu.modifier("move")])
	if float(p.status.get("slow",0))>0: factors.append(["迟缓",0.55])
	if float(p.status.get("shock",0))>0: factors.append(["震颤",0.8])
	var water:float=game.world.water_speed(p.position)
	if game.world.swimming_at(p.position) and p.utility_gu.has("swim"): water=1.0
	factors.append(["游泳" if game.world.swimming_at(p.position) else "冰面",water])
	if not game.world.in_interior:
		if float(game.world.environment.state(TerrainLayers.cell_at(p.position),game.world.layer).get("wet",0))>0 and not game.world.water_at(p.position):
			factors.append(["湿地",0.85])
		factors.append(["地形坡度",game.world.blocks.speed_multiplier(p.position,direction)])
	if p.dash_t>0: factors.append(["疾步",3.2])
	if p.body.unconscious or p.dead: factors.append(["无法行动",0.0])
	var value:float=p.speed+p.spd_bonus
	var sources:Array[String]=[]
	if not is_zero_approx(p.spd_bonus): sources.append("临时效果 %+.1f"%p.spd_bonus)
	for factor in factors:
		if is_equal_approx(float(factor[1]),1.0): continue
		var before:=value
		value*=float(factor[1])
		sources.append("%s %+.0f%%（%+.1f）"%[factor[0],(float(factor[1])-1)*100,value-before])
	return {"value":value,"sources":sources,"factors":factors}

static func row(name: String, base: float, value: float, unit: String, sources: Array) -> Dictionary:
	return {"name":name,"base":base,"value":value,"unit":unit,"sources":sources}

static func effect(id: String, title: String, short_text: String, detail: String, good: bool, left: float = -1.0) -> Dictionary:
	return {"id":id,"title":title,"short":short_text,"detail":detail,"good":good,"left":left}

static func snapshot(game: Node) -> Dictionary:
	var p:Player=game.player
	var b:=p.body
	var g:=p.gu_effects
	var u:=p.utility_gu
	var rows:Array=[]
	var effects:Array=[]
	var attack_sources:Array[String]=[]
	if p.boar_cultivation.attack_bonus()>0: attack_sources.append("豕蛊永久养力 +%.1f"%p.boar_cultivation.attack_bonus())
	if p.atk_bonus!=0: attack_sources.append("临时效果 %+.1f"%p.atk_bonus)
	if g.attack_bonus()>0: attack_sources.append("蛮力天牛 +%.1f"%g.attack_bonus())
	rows.append(row("徒手攻击",p.atk,p.melee_attack(),"",attack_sources))
	var move:=movement(game,Vector2.from_angle(p.dir))
	rows.append(row("移动速度",p.speed,move.value,"像素/秒",move.sources))
	var attack_speed:=maxf(0.5,b.get_attack_speed_multiplier())*100
	rows.append(row("攻击速度",100,attack_speed,"%",["身体伤势与肉身蛊效；普攻间隔 %.2f 秒"%(0.38/(attack_speed/100))] if not is_equal_approx(attack_speed,100) else []))
	rows.append(row("精准度",100,b.get_accuracy()*100,"%",["眼伤、疼痛和失血合计 %+.0f 个百分点"%((b.get_accuracy()-1)*100)] if b.get_accuracy()<1 else []))
	var vision_base:=FogOfWar.BASE_RADIUS if game.fog.layer==0 else 320.0
	var vision_sources:Array[String]=[]
	if u.vision_bonus()>0: vision_sources.append("视野蛊术 +%.0f"%u.vision_bonus())
	if b.get_vision_multiplier()<1: vision_sources.append("眼伤 %+.0f%%（%+.1f）"%[(b.get_vision_multiplier()-1)*100,(vision_base+u.vision_bonus())*(b.get_vision_multiplier()-1)])
	rows.append(row("视野半径",vision_base,game.fog.radius_world(),"像素",vision_sources))
	rows.append(row("疾步体力消耗",25,g.stamina_cost(25),"",["黄骆耐力 -60%"] if g.endurance_left>0 else []))
	if g.brute_left>0: effects.append(effect("brute","蛮力天牛","攻击 +22","徒手攻击 +22；不叠加、不提前续时。",true,g.brute_left))
	if g.endurance_left>0: effects.append(effect("endurance","黄骆耐力","耗体 -60%","体力消耗 -60%：疾步 25 → 10，腾跃 20 → 8。",true,g.endurance_left))
	if p.atk_bonus!=0 or p.spd_bonus!=0:
		effects.append(effect("temporary","临时强化","攻击 %+.1f"%p.atk_bonus,"攻击 %+.1f；移动速度 %+.1f。"%[p.atk_bonus,p.spd_bonus],p.atk_bonus+p.spd_bonus>=0,p.buff_time))
	for kind in u.active:
		if not u.has(kind): continue
		var state:Dictionary=u.active[kind]
		var short_text:=""
		var detail:=""
		match kind:
			"aptitude_training":
				short_text="资质 +%.2f/秒"%float(state.rate)
				detail="每秒容量 +%.2f 个百分点，本蛊上限 %.0f%%；后天增长 %.2f/20。移动、攻击、受击或打坐中断，不补真元。"%[state.rate,state.ceiling,p.aperture.aptitude_gain]
			"cultivation":
				short_text="温养 ×%.1f"%u.cultivation_multiplier()
				detail="打坐温养速度与耗元同时 ×%.1f；没有额外真元，不加快跨转冲窍。"%u.cultivation_multiplier()
			"haste":
				short_text="移速 +%.0f%%"%((u.speed_multiplier()-1)*100)
				detail="移动速度 ×%.2f，与伤势、水域、地形和疾步依次相乘。"%u.speed_multiplier()
			"vision":
				short_text="视野 +%.0f"%u.vision_bonus()
				detail="视野半径 +%.0f 像素，再乘眼部视野倍率；当前净增 %.1f。"%[u.vision_bonus(),u.vision_bonus()*b.get_vision_multiplier()]
			"veil":
				short_text="侦测距 -%.0f%%"%((1-u.detection_multiplier())*100)
				detail="敌人侦测你的距离 ×%.2f；攻击或受击后解除，不清除已有追击。"%u.detection_multiplier()
			"shell":
				short_text="护盾 %.0f"%float(state.get("points",0))
				detail="剩余吸收 %.1f / %.0f 点伤害；与皮蛊护体互斥。"%[float(state.get("points",0)),float(GameData.GU[state.template].skill.get("points",32))]
			"harvest":
				short_text="采木 +%d / 采石 +%d"%[u.harvest_bonus("timber"),u.harvest_bonus("rubble")]
				detail="木材采集点 3 → %d，石料 3 → %d；保留刷新冷却，不增加徒手攻击。"%[3+u.harvest_bonus("timber"),3+u.harvest_bonus("rubble")]
			"swim":
				short_text="踏波通行"
				detail="游泳减速移除，仍计算身体伤势、坡度和碰撞。"
			"regrowth":
				short_text="缝伤恢复"
				detail="%s耐久 +%.1f/秒、气血 +%.1f/秒；受击中断，不能再生。"%[b.parts[state.part].name,state.part_rate,state.hp_rate]
			"resist":
				short_text="%s减伤 %.0f%%"%[{"fire":"火焰","water":"水霜"}.get(state.resist_element,"对应伤害"),float(state.reduction)*100]
				detail=String(GameData.GU[state.template].hint)
		if not short_text.is_empty(): effects.append(effect(kind,String(GameData.GU[state.template].skill.name),short_text,detail,true,float(state.left)))
	var body_gu:=p.body_gu
	if body_gu.bone!="": effects.append(effect("body_bone",GameData.GU[body_gu.bone].name,"永久骨骼强化",GameData.GU[body_gu.bone].hint,true))
	if body_gu.tendon_progress>0: effects.append(effect("body_tendon","永久锻筋","进度 %.1f%%"%(body_gu.tendon_progress*100),"四肢部位伤害 ×%.3f；蛮力新增负担 ×%.3f。"%[1-0.15*body_gu.tendon_progress,body_gu.modifier("strain_gain")],true))
	for group in body_gu.active:
		var state:Dictionary=body_gu.active[group]
		var detail:String=GameData.GU[state.template].hint
		if state.has("part"): detail="作用部位："+String(b.parts[state.part].name)+"。"+detail
		if state.effect=="self_heal": detail+=" 当前恢复 %.2f/秒。"%body_gu.self_heal_rate(p)
		effects.append(effect("body_"+group,GameData.GU[state.template].name,BodyGuEffects.GROUP_NAMES[group],detail,true,state.left))
	var gus:GuManager=game.get_node("/root/Gus")
	var guard:=g.usable(gus,g.guard_id)
	if guard!=null:
		var sk:Dictionary=GameData.GU[guard.template_id].skill
		effects.append(effect("guard",guard.name,"减伤 %.0f%%"%(float(sk.reduction)*100),"受击伤害 -%.0f%%；持续耗元 %.2f/秒，受击每点基础伤害耗元 %.3f。真元不足失效。"%[float(sk.reduction)*100,p.aperture.cost_at_stage(float(sk.upkeep)),p.aperture.cost_at_stage(float(sk.hit_cost))],true))
	if p.jade_guard: effects.append(effect("jade","玉皮护体","减伤 60%","受击伤害 -60%%；持续耗元 %.2f/秒，受击每点基础伤害耗元 %.3f。真元不足失效。"%[p.aperture.cost_at_stage(1),p.aperture.cost_at_stage(0.35)],true))
	if g.ward_valid(game):
		var sk:Dictionary=GameData.GU.moon_raiment.skill
		effects.append(effect("ward","月霓庇护","庇护同伴","庇护 %s，受到伤害 -%.0f%%；自身减伤 +0。持续耗元 %.2f/秒，受击每点基础伤害耗元 %.3f。距离超过 180 像素或真元不足时解除。"%[g.ward_target.npc_name,float(sk.reduction)*100,p.aperture.cost_at_stage(float(sk.upkeep)),p.aperture.cost_at_stage(float(sk.hit_cost))],true))
	if p.shield>0: effects.append(effect("shield","护盾","吸收 %.0f"%p.shield,"剩余吸收 %.1f 点伤害。"%p.shield,true))
	if game.active_light_gu()!=null:
		effects.append(effect("light","小光辅月","月刃 +100%","月光蛊月刃基础伤害 ×2（+100%%），每次额外耗元 %.2f。"%p.aperture.cost_at_stage(float(GameData.GU.little_light.skill.cost)),true))
	if p.boar_cultivation.active_id!="": effects.append(effect("training","豕蛊养力","养力 +2%/秒","每秒增加永久进度 2 个百分点，耗元 %.2f/秒；每日最多 15 秒，进度上限 100%%。"%p.aperture.cost_at_stage(1),true))
	if p.dash_t>0: effects.append(effect("dash","疾步","移速 +220%","移动速度 ×3.2（+220%），与其他移动倍率相乘。",true,p.dash_t))
	if p.iframes>0: effects.append(effect("iframes","受击保护","免疫受击","短时间免疫再次受击；不阻止伤口继续失血。",true,p.iframes))
	if p.aperture.stone_reserve>0: effects.append(effect("stone","吸收元石","真元 +1/s","额外补充普通真元 +1/秒，剩余储量 %.1f；元海已满时停止消耗储量。"%p.aperture.stone_reserve,true))
	if not p.dead and not b.dead and b.recovery_delay<=0 and b.total_bleed_rate()<=0:
		var recovery:Array[String]=[]
		if p.hp<p.max_hp and b.blood>=50 and float(p.status.get("burn",0))<=0 and float(p.status.get("poison",0))<=0 and float(p.status.get("bleed",0))<=0: recovery.append("气血 +0.15/秒")
		if b.blood<100: recovery.append("身体血量 +0.25/秒")
		if b.consciousness<100: recovery.append("意识 +1/秒")
		for part in b.parts.values():
			if not part.destroyed and float(part.hp)<float(part.max_hp):
				recovery.append("受伤部位耐久 +0.12/秒")
				break
		if not recovery.is_empty(): effects.append(effect("recovery","休息恢复","恢复中","、".join(recovery)+"；受伤或出血会中断恢复，毁损部位不会再生。",true))
	if b.get_move_multiplier()<1 or b.get_attack_speed_multiplier()<1:
		var parts:Array[String]=[]
		for id in ["pelvis","leg_l","leg_r","hand_l","hand_r"]:
			if b.parts[id].destroyed or float(b.parts[id].hp)<=float(b.parts[id].max_hp)*0.3: parts.append(String(b.parts[id].name)+b.part_status(id))
		effects.append(effect("injury","肢体伤势","移速 %+.0f%%"%((b.get_move_multiplier()-1)*100),"%s\n伤势移动倍率 %+.0f%%；实际攻击速度 %+.0f%%。%s"%["、".join(parts),(b.get_move_multiplier()-1)*100,attack_speed-100,"无法疾步。" if not b.can_dash() else ""],false))
	var eye_accuracy:=0.0
	var lost:=0
	for id in ["eye_l","eye_r"]:
		if b.parts[id].destroyed:
			eye_accuracy+=25
			lost+=1
		elif float(b.parts[id].hp)<=float(b.parts[id].max_hp)*0.3: eye_accuracy+=10
	if lost==2: eye_accuracy=60
	if b.get_vision_multiplier()<1:
		effects.append(effect("eyes","眼部伤势","视野 %+.0f%%"%((b.get_vision_multiplier()-1)*100),"视野 %+.0f%%；精准度 -%.0f 个百分点（再结算疼痛、失血与下限）。"%[(b.get_vision_multiplier()-1)*100,eye_accuracy],false))
	if b.pain>=60: effects.append(effect("pain","剧痛","精准 -20%","精准度 -20 个百分点；疼痛每秒自然下降 3。",false))
	if b.blood<100:
		effects.append(effect("blood","失血","血量 %.0f"%b.blood,"血量 %.1f / 100；每缺少 10 点血量，精准度 -3 个百分点；当前 -%.0f 个百分点。"%[b.blood,floorf((100-b.blood)/10)*3],false))
	if b.total_bleed_rate()>0: effects.append(effect("wound","伤口出血","失血 -%.1f/s"%b.total_bleed_rate(),"身体血量 -%.1f/秒；气血与身体血量分别结算。包扎可止血，B 查看出血部位。"%b.total_bleed_rate(),false))
	if b.unconscious: effects.append(effect("unconscious","昏迷","无法行动","无法移动、普攻、疾步或催蛊；部位受伤 +50%，精准度再减 30 个百分点。",false))
	if not b.parts.head.destroyed and float(b.parts.head.hp)<=float(b.parts.head.max_hp)*0.3: effects.append(effect("head","头部重伤","意识 -1/s","意识 -1/秒；若满足休息恢复条件，会同时结算意识 +1/秒。",false))
	if b.neck_timer>=0: effects.append(effect("neck","颈部致命伤","急需止血","死亡倒计时 %.1f 秒；及时包扎颈部可止血。"%b.neck_timer,false,b.neck_timer))
	for key in p.status:
		var left:float=p.status[key]
		if left<=0: continue
		var names:Dictionary={"burn":"灼烧","poison":"中毒","bleed":"流血","wet":"潮湿","shock":"麻痹","slow":"迟缓"}
		var info:Dictionary={"burn":[2.0,2.5],"poison":[1.5,1.8],"bleed":[1.5,2.0]}
		var detail:="当前无额外行动属性变化。"
		var short_text:="附着"
		if key in ["slow","shock"]:
			var multiplier:=0.55 if key=="slow" else 0.8
			short_text="移速 %+.0f%%"%((multiplier-1)*100)
			detail="移动速度 ×%.2f，与伤势、蛊术和地形依次相乘；暖脉蛊可解除。"%multiplier
		if info.has(key):
			short_text="伤害 %.1f/次"%float(info[key][0])
			detail="每次基础气血伤害 %.1f，概率触发频率约 %.1f 次/秒；实际伤害受护体、护盾和受击间隔影响。"%[info[key][0],info[key][1]]
		effects.append(effect(key,String(names.get(key,key)),short_text,detail,false,left))
	for factor in move.factors:
		if factor[0] not in ["游泳","冰面","湿地","地形坡度"] or is_equal_approx(float(factor[1]),1): continue
		effects.append(effect(String(factor[0]),String(factor[0]),"移速 %+.0f%%"%((float(factor[1])-1)*100),"移动速度 %+.0f%%（×%.2f）；离开对应地形后恢复。地形坡度按当前朝向计算。"%[(float(factor[1])-1)*100,factor[1]],false))
	if g.strain>65: effects.append(effect("strain","蛮力负担","负担 %.0f"%g.strain,"当前负担 %.1f；继续使用蛮力可能拉伤。负担每秒减少 1，实际伤势单独列出。"%g.strain,false))
	return {"attributes":rows,"effects":effects}

static func attributes_text(data: Dictionary) -> String:
	var lines:Array[String]=[]
	for item in data.attributes:
		var change:float=item.value-item.base
		var col:="#76c2aa" if change>0 else "#df8775"
		if item.name=="疾步体力消耗": col="#76c2aa" if change<0 else "#df8775"
		var delta:="持平" if is_zero_approx(change) else "[color=%s]%+.1f%s[/color]"%[col,change," 个百分点" if item.unit=="%" else ""]
		lines.append("[b]%s[/b]   %.1f%s → %.1f%s   %s"%[item.name,item.base,item.unit,item.value,item.unit,delta])
		if not item.sources.is_empty(): lines.append("[color=#93a99f]"+" · ".join(item.sources)+"[/color]")
	return "\n".join(lines)

static func effects_text(data: Dictionary) -> String:
	var lines:Array[String]=[]
	for good in [true,false]:
		lines.append("[color=%s][b]%s[/b][/color]"%["#76c2aa" if good else "#df8775","增益" if good else "减益 / 环境"])
		var count:=0
		for item in data.effects:
			if item.good!=good: continue
			count+=1
			lines.append("[color=%s]%s · %s[/color]\n%s"%["#76c2aa" if good else "#df8775",item.title,"剩余 %.1f 秒"%item.left if item.left>=0 else "随状态持续",item.detail])
		if count==0: lines.append("当前无")
	return "\n\n".join(lines)
