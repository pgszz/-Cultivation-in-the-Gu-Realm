class_name DestructionSystem
extends Node

var world: Node
var objects: Dictionary = {}
var changed := false

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

func hit_area(center: Vector2, radius: float, damage: float, power: float, house: String = "", direction: Vector2 = Vector2.ZERO, cone: float = -1.0) -> Array:
	var hits: Array=[]
	for id in objects:
		var obj: Dictionary=objects[id]
		if obj.house!=house or float(obj.hp)<=0.0: continue
		var r: Rect2=obj.rect
		var nearest := center.clamp(r.position,r.end)
		var offset := nearest-center
		if offset.length()>radius: continue
		if direction!=Vector2.ZERO and offset.length()>2 and offset.normalized().dot(direction)<cone: continue
		var amount := damage*power/maxf(1.0,float(obj.hardness))
		if amount<float(obj.hardness): continue
		obj.hp=maxf(0.0,float(obj.hp)-amount)
		_sync_visual(obj)
		hits.append({"id":id,"pos":r.get_center(),"damage":amount,"hp":obj.hp,"destroyed":obj.hp<=0.0,"kind":obj.kind})
		changed=true
		if obj.hp<=0.0: _remove_collision(obj)
	world.flush_terrain_changes()
	return hits

func _sync_visual(obj: Dictionary) -> void:
	if is_instance_valid(obj.visual):
		obj.visual.hp=obj.hp
		obj.visual.broken=obj.hp<=0.0
		obj.visual.queue_redraw()
	world.queue_redraw()
	if world.interior!=null: world.interior.queue_redraw()

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

func load_data(data: Dictionary) -> void:
	for id in objects:
		var obj: Dictionary=objects[id]
		obj.hp=clampf(float(data.get(id,obj.max_hp)),0,float(obj.max_hp))
		var tile: Vector2i=obj.tile
		if tile.x>=0:
			world.map[tile.y*GameData.MAP_W+tile.x]=GameData.T_TREE if obj.kind in ["tree","bamboo"] else GameData.T_ROCK
		_sync_visual(obj)
		if obj.hp<=0: _remove_collision(obj)
	world._bake_textures()
	changed=false
