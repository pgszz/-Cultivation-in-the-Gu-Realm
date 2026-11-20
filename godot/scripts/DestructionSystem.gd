class_name DestructionSystem
extends Node

var world: Node
var objects: Dictionary = {}
var changed := false
var salvaged: Dictionary = {}

const REACH := 88.0
const REPAIR_COSTS := {
	"house":{"timber":12,"rubble":8}, "wall":{"timber":2,"rubble":6},
	"furniture":{"timber":4}, "bonfire":{"timber":3}, "furnace":{"timber":2,"rubble":6},
}
const SALVAGE := {
	"tree":{"timber":2}, "bamboo":{"timber":2}, "rock":{"rubble":3},
	"house":{"timber":4,"rubble":2}, "wall":{"rubble":2}, "furniture":{"timber":2},
	"bonfire":{"timber":1}, "furnace":{"rubble":3}, "landmark":{"rubble":1},
	"cave":{"rubble":4}, "mountain":{"rubble":8},
}

func register(id: String, kind: String, rect: Rect2, hp: float, hardness: float, visual: Node = null, tile: Vector2i = Vector2i(-1,-1), house: String = "") -> void:
	objects[id]={"id":id,"kind":kind,"rect":rect,"hp":hp,"max_hp":hp,"hardness":hardness,"visual":visual,"tile":tile,"house":house}
	if visual != null:
		visual.object_id=id
		visual.hp=hp
		visual.max_hp=hp

func broken(id: String) -> bool:
	return objects.has(id) and float(objects[id].hp)<=0.0

func health(id: String) -> float:
	return float(objects[id].hp) if objects.has(id) else 0.0

func object_name(id: String) -> String:
	if id.begins_with("shang:"):
		return String(ShangCityData.building(id.trim_prefix("shang:")).get("name","商家城建筑"))
	if not objects.has(id): return "未知物件"
	if id.begins_with("house:"):
		for h in World.HOUSE_DATA:
			if id=="house:"+h.id: return h.name
	if id.begins_with("interior:"):
		return {"bed":"床榻 / 置物架","desk":"桌案","storage":"储物箱","wall_n":"北墙","wall_w":"西墙","wall_e":"东墙","wall_s_left":"南墙左段","wall_s_right":"南墙右段"}.get(id.get_slice(":",2),"室内陈设")
	if id.begins_with("landmark:"):
		for lm in World.LANDMARKS:
			if id=="landmark:"+lm.type: return lm.name
	return {"tree":"树木","bamboo":"青矛竹","rock":"岩石","mountain":"山体","bonfire":"篝火架","furnace":"旧炉"}.get(objects[id].kind,"地物")

func state_text(id: String) -> String:
	var obj: Dictionary=objects[id]
	if float(obj.hp)<=0: return "已毁损"
	if float(obj.hp)<=float(obj.max_hp)*0.3: return "濒临倒塌"
	if float(obj.hp)<float(obj.max_hp): return "已受损"
	return "完好"

func damage_amount(id: String, damage: float, power: float = 1.0) -> float:
	if not objects.has(id) or damage<=0 or power<=0: return 0.0
	var hardness: float=objects[id].hardness
	var amount:=damage*power/maxf(1.0,hardness)
	return amount if amount>=hardness else 0.0

func within_reach(id: String, pos: Vector2, house: String) -> bool:
	if world.layer>0: return false
	if not objects.has(id) or objects[id].house!=house: return false
	var rect: Rect2=objects[id].rect
	return pos.distance_to(pos.clamp(rect.position,rect.end))<=REACH

func nearby(pos: Vector2, house: String) -> Array:
	var found: Array=[]
	for id in objects:
		if not within_reach(id,pos,house): continue
		var rect: Rect2=objects[id].rect
		found.append({"id":id,"distance":pos.distance_to(pos.clamp(rect.position,rect.end))})
	found.sort_custom(func(a: Dictionary,b: Dictionary):
		if is_equal_approx(a.distance,b.distance): return String(a.id)<String(b.id)
		return a.distance<b.distance
	)
	return found

func repairable(id: String) -> bool:
	if not objects.has(id): return false
	var obj: Dictionary=objects[id]
	return REPAIR_COSTS.has(obj.kind) and not SettlementData.is_cave(obj.house)

func repair_cost(id: String) -> Dictionary:
	if not repairable(id): return {}
	var obj: Dictionary=objects[id]
	var missing:=1.0-float(obj.hp)/float(obj.max_hp)
	if missing<=0: return {}
	var cost: Dictionary={}
	for item in REPAIR_COSTS[obj.kind]:
		cost[item]=maxi(1,ceili(float(REPAIR_COSTS[obj.kind][item])*missing))
	return cost

func salvage_yield(id: String) -> Dictionary:
	if not objects.has(id) or salvaged.has(id): return {}
	return SALVAGE.get(objects[id].kind,{}).duplicate()

func repair(id: String, inv: Inventory) -> bool:
	var cost:=repair_cost(id)
	if cost.is_empty(): return false
	for item in cost:
		if not inv.has_item(item,int(cost[item])): return false
	for item in cost: inv.remove_item(item,int(cost[item]))
	objects[id].hp=objects[id].max_hp
	_sync_visual(objects[id])
	changed=true
	return true

func hit_area(center: Vector2, radius: float, damage: float, power: float, house: String = "", direction: Vector2 = Vector2.ZERO, cone: float = -1.0, only_id: String = "") -> Array:
	var hits: Array=[]
	if damage<=0 or power<=0 or radius<0: return hits
	if world.layer>0 and not world.in_interior: return hits
	var obstructed:Dictionary={}
	if direction!=Vector2.ZERO:
		# Snapshot occlusion before any object breaks in this swing.
		for id in objects:
			var obj:Dictionary=objects[id]
			if obj.house!=house or float(obj.hp)<=0: continue
			var nearest:=center.clamp(obj.rect.position,obj.rect.end)
			if center.distance_to(nearest)<=radius and not world.attack_clear(center,nearest,id): obstructed[id]=true
	for id in objects:
		var obj: Dictionary=objects[id]
		if obj.house!=house or float(obj.hp)<=0.0 or obstructed.has(id) or (only_id!="" and id!=only_id): continue
		var r: Rect2=obj.rect
		var nearest := center.clamp(r.position,r.end)
		var offset := nearest-center
		if offset.length()>radius: continue
		if direction!=Vector2.ZERO and offset.length()>2 and offset.normalized().dot(direction)<cone: continue
		var amount := minf(float(obj.hp),damage_amount(id,damage,power))
		if amount<=0:
			hits.append({"id":id,"pos":nearest,"damage":0.0,"hp":obj.hp,"destroyed":false,"kind":obj.kind,"blocked":true,"loot":{}})
			continue
		obj.hp=maxf(0.0,float(obj.hp)-amount)
		_sync_visual(obj,true)
		var loot: Dictionary={}
		if obj.hp<=0:
			loot=salvage_yield(id)
			salvaged[id]=true
		hits.append({"id":id,"pos":nearest,"damage":amount,"hp":obj.hp,"destroyed":obj.hp<=0.0,"kind":obj.kind,"blocked":false,"loot":loot})
		changed=true
		if obj.hp<=0.0: _remove_collision(obj)
	world.flush_terrain_changes()
	return hits

func _sync_visual(obj: Dictionary, animate: bool = false) -> void:
	if is_instance_valid(obj.visual):
		obj.visual.sync_damage(float(obj.hp),animate)
	world.queue_redraw()
	if world.interior!=null:
		world.interior.sync_fixture(obj.id,float(obj.hp),animate)
		world.interior.queue_redraw()

func _remove_collision(obj: Dictionary) -> void:
	var tile: Vector2i=obj.tile
	if tile.x>=0:
		world.map[tile.y*GameData.MAP_W+tile.x]=GameData.T_GRASS
		world.refresh_terrain_tile(tile)

func save_data() -> Dictionary:
	var data := {}
	for id in objects:
		if float(objects[id].hp)<float(objects[id].max_hp): data[id]=objects[id].hp
	return data

func load_data(data: Dictionary, salvage_ids: Array = []) -> void:
	salvaged.clear()
	for id in salvage_ids:
		if id is String and objects.has(id): salvaged[id]=true
	for id in objects:
		var obj: Dictionary=objects[id]
		obj.hp=clampf(float(data.get(id,obj.max_hp)),0,float(obj.max_hp))
		var tile: Vector2i=obj.tile
		if tile.x>=0:
			world.map[tile.y*GameData.MAP_W+tile.x]=GameData.T_TREE if obj.kind in ["tree","bamboo"] else GameData.T_ROCK
		_sync_visual(obj)
		if obj.hp<=0:
			# Older saves already awarded materials when these objects collapsed.
			salvaged[id]=true
			_remove_collision(obj)
	world._bake_textures()
	changed=false
