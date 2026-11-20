class_name ShangCityData
extends RefCounted

## Locations and all economy/combat parameters below are sandbox adaptations.
const ORIGIN := Vector2(24000,4000)
const SIZE := Vector2(2000,1400)
const GATE := Vector2(1000,1210)
const ARENA := Rect2(1080,530,740,460)
const BUILDINGS := [
	{"id":"stones","name":"赌石坊","pos":Vector2(430,560),"size":Vector2(290,240),"art":"shang_hall"},
	{"id":"market","name":"百货商楼","pos":Vector2(800,480),"size":Vector2(290,260),"art":"shang_hall"},
	{"id":"arena","name":"第五内城演武场","pos":Vector2(1440,420),"size":Vector2(340,260),"art":"ancestral"},
	{"id":"inn","name":"行客栈","pos":Vector2(430,960),"size":Vector2(260,220),"art":"home"},
	{"id":"guild","name":"商队货栈","pos":Vector2(800,900),"size":Vector2(270,230),"art":"archive"},
]
const STONES := [
	{"name":"粗石","price":12,"empty":75,"dead":18,"live":7},
	{"name":"花斑石","price":35,"empty":60,"dead":25,"live":15},
	{"name":"紫金石","price":85,"empty":45,"dead":30,"live":25},
]
const GU_POOL := ["stone_skin","copper_skin","little_light","black_boar","white_boar"]
const STOCK := {"moon_petals":1,"bamboo_wine":2,"bandage":8,"timber":5,"rubble":3}
const CONTRACTS := [
	{"id":"timber","name":"修缮木料","item":"timber","count":12,"reward":80},
	{"id":"rubble","name":"铺路石料","item":"rubble","count":18,"reward":65},
	{"id":"bandage","name":"演武药包","item":"bandage","count":6,"reward":58},
]
const OPPONENTS := [
	{"name":"石拳客","hp":85.0,"speed":82.0,"damage":10.0,"style":0},
	{"name":"逐风客","hp":100.0,"speed":112.0,"damage":13.0,"style":1},
	{"name":"月刃客","hp":120.0,"speed":88.0,"damage":16.0,"style":2},
]

static func building(id: String) -> Dictionary:
	for b in BUILDINGS:
		if b.id==id: return b
	return {}

static func body_rect(id: String) -> Rect2:
	var b:=building(id)
	return Rect2(ORIGIN+Vector2(b.pos)+Vector2(-90,-66),Vector2(180,66))

static func arena_rect() -> Rect2:
	return Rect2(ORIGIN+ARENA.position,ARENA.size)

static func valid_save(data: Variant) -> bool:
	if not data is Dictionary: return false
	for key in ["visited","active","bout"]:
		if data.has(key) and not data[key] is bool: return false
	for key in ["seed","serial","wins","losses","bout_level"]:
		var value:Variant=data.get(key,0)
		if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0 or float(value)!=floorf(float(value)) or float(value)>2147483647: return false
	if int(data.get("bout_level",0))>2: return false
	var pos:Variant=data.get("return_pos",[512,1040])
	if not pos is Array or pos.size()!=2: return false
	for value in pos:
		if not (value is int or value is float) or not is_finite(float(value)): return false
	var ids:Dictionary={}
	for key in ["offers","stones"]:
		var rows:Variant=data.get(key,[])
		if not rows is Array or rows.size()>(6 if key=="offers" else 12): return false
		for row in rows:
			if not row is Dictionary: return false
			for field in ["id","tier"]:
				var value:Variant=row.get(field)
				if not (value is int or value is float) or not is_finite(float(value)) or float(value)!=floorf(float(value)): return false
			if int(row.tier)<0 or int(row.tier)>2 or int(row.id)<1 or int(row.id)>int(data.get("serial",0)) or ids.has(int(row.id)): return false
			ids[int(row.id)]=true
	var orders:Variant=data.get("delivered",{})
	if not orders is Dictionary: return false
	for key in orders:
		if key not in ["timber","rubble","bandage"] or not orders[key] is bool: return false
	var history:Variant=data.get("ledger",[])
	if not history is Array or history.size()>12: return false
	for row in history:
		if not row is String: return false
	return true
