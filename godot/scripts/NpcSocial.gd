class_name NpcSocial
extends RefCounted

## Sandbox social memory. Only actual interactions create dated history.
const HISTORY_LIMIT := 48
const REWARD_INTERVAL := 300.0
var initialized := false
var affinity := 0
var met := false
var history: Array[Dictionary] = []
var rewards: Dictionary = {}
var grudges: Dictionary = {}
var theft_retaliation := false

static func now(person: Npc) -> float:
	return maxf(0,float(person.game.social_time)) if person.game!=null else 0.0

func ensure(person: Npc) -> void:
	if initialized: return
	initialized=true
	affinity=-60 if person.hostile else 0
	met=not person.conversation.is_empty()
	for topic in person.conversation:
		if NpcConversation.TOPICS.has(topic): rewards["talk:"+str(topic)]=now(person)

func label(person: Npc) -> String:
	ensure(person)
	if person.hostile: return "敌对"
	if affinity<=-30: return "厌恶"
	if affinity<0: return "戒备"
	if affinity>=60: return "信赖"
	if affinity>=30: return "友善"
	if affinity>=4: return "熟识"
	return "相识" if met else "陌生"

func tint(person: Npc) -> Color:
	ensure(person)
	if person.dead: return UIStyle.DIM
	if person.hostile or affinity<0: return UIStyle.RED
	return UIStyle.JADE if affinity>=4 else UIStyle.GOLD

func record(person: Npc, kind: String, message: String, actor: String = "", change: int = 0) -> void:
	ensure(person)
	var time:=now(person)
	# Consecutive repeated actions form one entry, preserving the real total change.
	if not history.is_empty():
		var last:Dictionary=history.back()
		if last.kind==kind and last.actor==actor and last.text==message and time-float(last.time)<=60:
			last.time=time
			last.count=int(last.count)+1
			last.change=int(last.change)+change
			return
	history.append({"time":time,"kind":kind,"text":message,"actor":actor,"change":change,"count":1})
	while history.size()>HISTORY_LIMIT: history.pop_front()

func reward(person: Npc, key: String, amount: int, once: bool = false) -> int:
	ensure(person)
	if person.dead or person.hostile: return 0
	if rewards.has(key) and (once or now(person)-float(rewards[key])<REWARD_INTERVAL): return 0
	rewards[key]=now(person)
	var old:=affinity
	affinity=clampi(affinity+amount,-100,100)
	return affinity-old

func meet(person: Npc) -> bool:
	ensure(person)
	if met or person.dead or person.hostile: return false
	met=true
	record(person,"meet","与你初次交谈。","player")
	return true

func conversation_event(person: Npc, topic: String) -> void:
	meet(person)
	var change:=reward(person,"care" if topic=="care" else "talk:"+topic,8 if topic=="care" else 2,topic!="care")
	var message:="接受你的绷带包扎，伤势得到缓解。" if topic=="care" else "与你谈起「%s」。" % NpcConversation.TOPICS[topic]
	record(person,"care" if topic=="care" else "talk",message,"player",change)

func trade_event(person: Npc, item_name: String, amount: int, buying: bool) -> void:
	meet(person)
	var change:=reward(person,"trade",1)
	record(person,"trade","向你出售%s ×%d。" % [item_name,amount] if buying else "从你手中购入%s ×%d。" % [item_name,amount],"player",change)

func cooldown_left(person: Npc, key: String) -> float:
	ensure(person)
	return maxf(0,REWARD_INTERVAL-(now(person)-float(rewards[key]))) if rewards.has(key) else 0.0

func gift_event(person: Npc, item_name: String, amount: int, gain: int) -> int:
	meet(person)
	var change:=reward(person,"gift",gain)
	record(person,"gift","收下你赠送的%s ×%d。" % [item_name,amount],"player",change)
	return change

func theft_event(person: Npc, item_name: String, amount: int, loss: int) -> int:
	ensure(person)
	met=true
	rewards.theft=now(person)
	var before:=affinity
	affinity=maxi(-100,affinity-loss)
	record(person,"theft","发现你盗走%s ×%d，对你提高戒备。" % [item_name,amount],"player",affinity-before)
	return affinity-before

func retaliate(person: Npc) -> void:
	theft_retaliation=true
	person.hostile=true
	person.speech_left=0
	if person is WorldPerson:
		person.target=person.game.player
		person.flee_left=0
		person.activity="因失窃反击"
	record(person,"retaliation","因你盗窃随身物品，愤而反击，与你敌对。","player")
	person.queue_redraw()

func player_assault(person: Npc, reason: String = "遭到你的攻击，与你结怨。") -> void:
	ensure(person)
	if grudges.has("player"): return
	grudges.player=true
	met=true
	var old:=affinity
	affinity=clampi(affinity-60,-100,-60)
	record(person,"hostility",reason,"player",affinity-old)

static func all_people(game: Node) -> Array:
	var people:Array=[game.npc]
	people.append_array(game.residents.values())
	people.append_array(game.population.actors.values())
	return people

static func clan(person: Npc) -> String:
	if person.settlement_id!="": return person.settlement_id
	if Npc.PROFILES.has(person.resident_id): return "guyue"
	return ""

static func bond(person: Npc, other: Npc) -> String:
	if person==other: return ""
	var canon_bond:=CanonPeople.bond(person.resident_id,other.resident_id)
	if canon_bond!="": return canon_bond
	if person is WorldPerson and other is WorldPerson:
		if person.caravan and other.caravan:
			if person.role=="escort" and other.role!="escort": return "护送对象"
			if person.role!="escort" and other.role=="escort": return "随行护卫"
			return "同行伙伴"
		if person.role=="bandit" and other.role=="bandit" and person.resident_id.get_slice("_",0)==other.resident_id.get_slice("_",0): return "同伙"
	if clan(person)!="" and clan(person)==clan(other):
		if person is WorldPerson and other is WorldPerson and person.role=="guard" and other.role=="guard": return "巡逻搭档"
		return "同寨"
	return ""

func relations(person: Npc) -> Array[Dictionary]:
	ensure(person)
	var result:Array[Dictionary]=[]
	for other: Npc in all_people(person.game):
		if not is_instance_valid(other) or other==person: continue
		var kind:=bond(person,other)
		if grudges.has(other.resident_id): kind="仇敌"+(" · 原"+kind if kind!="" else "")
		if kind=="": continue
		result.append({"id":other.resident_id,"name":other.npc_name,"kind":kind,"dead":other.dead,"appearance":other.get_appearance()})
	return result

static func hit(person: Npc, source: Node2D) -> void:
	if source==person.game.player:
		person.social.player_assault(person)
	elif source is Npc:
		for pair in [[person,source],[source,person]]:
			var owner: Npc=pair[0]
			var other: Npc=pair[1]
			owner.social.ensure(owner)
			if owner.social.grudges.has(other.resident_id): continue
			owner.social.grudges[other.resident_id]=true
			owner.social.record(owner,"conflict","与%s发生交战，结下仇怨。" % other.npc_name,other.resident_id)

static func died(person: Npc, source: Node2D) -> void:
	var killer:String="你" if source==person.game.player else (source.npc_name if source is Npc else "不明袭击者")
	person.social.record(person,"death","遭%s重创，伤重身亡。" % killer,"player" if source==person.game.player else (source.resident_id if source is Npc else ""))
	if source is Npc: source.social.record(source,"kill","在交战中杀死%s。" % person.npc_name,person.resident_id)
	for other: Npc in all_people(person.game):
		if not is_instance_valid(other) or other==person or other==source or other.dead: continue
		var kind:=bond(other,person)
		# Only nearby witnesses learn about the death; do not give remote NPCs omniscience.
		if kind=="" or not person.game.active_npcs().has(other) or other.position.distance_to(person.position)>300: continue
		other.social.ensure(other)
		var change:=0
		if source==person.game.player:
			var before:=other.social.affinity
			other.social.affinity=maxi(-100,before-15)
			change=other.social.affinity-before
		other.social.record(other,"loss","目睹%s%s被%s杀死。" % [kind,person.npc_name,killer],person.resident_id,change)

static func stamp(time: float) -> String:
	var seconds:=maxi(0,int(time))
	return "游历 %02d:%02d:%02d" % [seconds/3600,(seconds/60)%60,seconds%60]

func save_data(person: Npc) -> Dictionary:
	ensure(person)
	return {"affinity":affinity,"met":met,"history":history.duplicate(true),"rewards":rewards.duplicate(),"grudges":grudges.duplicate(),"theft_retaliation":theft_retaliation}

func load_data(person: Npc, raw: Variant) -> void:
	initialized=false
	history.clear()
	rewards.clear()
	grudges.clear()
	theft_retaliation=false
	ensure(person)
	if not raw is Dictionary: return
	affinity=clampi(int(raw.get("affinity",affinity)),-100,100)
	met=bool(raw.get("met",met))
	theft_retaliation=bool(raw.get("theft_retaliation",false))
	if raw.get("rewards") is Dictionary:
		for key in raw.rewards:
			if key in ["trade","care","gift","theft"] or (str(key).begins_with("talk:") and NpcConversation.TOPICS.has(str(key).trim_prefix("talk:"))): rewards[str(key)]=clampf(float(raw.rewards[key]),0,now(person))
	if raw.get("grudges") is Dictionary:
		for key in raw.grudges:
			if str(key).length()<=80: grudges[str(key)]=true
	if raw.get("history") is Array:
		for entry in raw.history.slice(-HISTORY_LIMIT):
			if not entry is Dictionary or not entry.get("text") is String: continue
			history.append({"time":clampf(float(entry.get("time",0)),0,now(person)),"kind":str(entry.get("kind","")).left(32),"text":entry.text.left(240),"actor":str(entry.get("actor","")).left(80),"change":clampi(int(entry.get("change",0)),-200,200),"count":clampi(int(entry.get("count",1)),1,99999)})
