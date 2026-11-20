class_name HungerSystem
extends Node

const GAME_DAY_SECONDS := 1440.0
const QUALITY_MULTIPLIER := {"normal":1.0}
const FEED_DAYS := {"moon_petals":1.0,"bamboo_wine":4.0,"jade":10.0,"pork_ration":5.0,"light_care":1.0,"copper_skin_care":1.0,"iron_skin_care":1.0,"stone_skin_care":1.0,"beast_skin_care":1.0,"brute_longhorn_care":1.0,"yellow_camel_care":1.0,"dragon_cricket_care":1.0}
signal gu_hunger_changed(gu_id: String, hunger: float)
signal gu_starving(gu_id: String)
signal gu_dormant(gu_id: String, withered: bool) # 兼容接口，表示濒饿/死亡。

class GuHungerData:
	var gu_id := ""
	var rank := 1
	var quality := "normal"
	var preferred_food := ""
	var current_hunger := 100.0
	var hunger_rate := 0.0
	var starving_seconds := 0.0
	var dead := false
	var is_dormant := false
	var is_withered := false

var gu_data := {}

func register_gu(id: String, rank: int, _quality: String, preferred_food: String = "") -> void:
	var d := GuHungerData.new()
	d.gu_id=id
	d.rank=rank
	d.preferred_food=preferred_food
	d.hunger_rate=100.0/(GAME_DAY_SECONDS*float(FEED_DAYS.get(preferred_food,1.0)))
	if preferred_food=="jade" and rank==2: d.hunger_rate=100.0/(GAME_DAY_SECONDS*20.0)
	gu_data[id]=d

func unregister_gu(id: String) -> void:
	gu_data.erase(id)

func update(delta: float) -> void:
	for d in gu_data.values():
		if d.dead: continue
		var until_empty: float=d.current_hunger/maxf(d.hunger_rate,0.00001)
		d.current_hunger=maxf(0,d.current_hunger-d.hunger_rate*delta)
		if d.current_hunger<=0:
			d.starving_seconds+=maxf(0,delta-until_empty)
			# 宽限时长为模拟参数；饿死后普通喂食不能复活。
			if d.starving_seconds>=GAME_DAY_SECONDS:
				d.dead=true
				d.is_withered=true
				gu_dormant.emit(d.gu_id,true)
		gu_hunger_changed.emit(d.gu_id,d.current_hunger)

func get_hunger(id: String) -> float:
	return gu_data[id].current_hunger if gu_data.has(id) else 100.0

func get_hunger_penalty(id: String) -> float:
	return 0.0 if gu_data.has(id) and gu_data[id].dead else 1.0

func feed_gu(id: String, amount: float) -> bool:
	if not gu_data.has(id): return false
	var d = gu_data[id]
	if d.dead or amount<=0 or d.current_hunger>=100: return false
	d.current_hunger=minf(100,d.current_hunger+amount)
	d.starving_seconds=0
	gu_hunger_changed.emit(id,d.current_hunger)
	return true

func get_hunger_status(id: String) -> String:
	if not gu_data.has(id): return "未知"
	var d = gu_data[id]
	if d.dead: return "已饿死"
	if d.current_hunger<=0: return "断粮 · 濒危"
	if d.current_hunger<25: return "需要喂食"
	return "食物充足"

func save_data() -> Dictionary:
	var out := {}
	for id in gu_data:
		var d = gu_data[id]
		out[id]={"current_hunger":d.current_hunger,"starving_seconds":d.starving_seconds,"dead":d.dead}
	return out

func load_data(data: Dictionary) -> void:
	for id in data:
		if not gu_data.has(id): continue
		var d = gu_data[id]
		d.current_hunger=clampf(float(data[id].get("current_hunger",100)),0,100)
		d.starving_seconds=maxf(0,float(data[id].get("starving_seconds",0)))
		d.dead=bool(data[id].get("dead",false))
