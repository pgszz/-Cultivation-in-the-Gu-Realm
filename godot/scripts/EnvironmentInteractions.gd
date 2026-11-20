class_name EnvironmentInteractions
extends RefCounted

## 有限沙盒反应：具体蛊声明 water/fire/frost，不按道途自动推断。
var cells: Dictionary = {}
var save_delay := 0.0
var dirty := false

func key(cell: Vector2i, layer: int) -> String:
	return "%d:%d:%d" % [layer,cell.x,cell.y]

func state(cell: Vector2i, layer: int) -> Dictionary:
	return cells.get(key(cell,layer),{})

func frozen(cell: Vector2i, layer: int) -> bool:
	return float(state(cell,layer).get("frost",0))>0

func label(cell: Vector2i, layer: int) -> String:
	var s:=state(cell,layer)
	if float(s.get("frost",0))>0: return "结霜 %.1fs" % s.frost
	if float(s.get("burn",0))>0: return "燃烧 %.1fs" % s.burn
	if float(s.get("wet",0))>0: return "潮湿 %.1fs" % s.wet
	return ""

func reaction_kind(projectile: Dictionary) -> String:
	var id:=String(projectile.get("gu_id",""))
	var legacy:Dictionary={"stream_gu":"water","ember_moth":"fire","frost_midge":"frost"}
	return String(legacy.get(id,projectile.get("reaction","")))

func react_cell(game: Node, cell: Vector2i, projectile: Dictionary, obstacle: Dictionary = {}) -> float:
	var kind:=reaction_kind(projectile)
	if game.world.in_interior or kind not in ["water","fire","frost"]: return 0
	if not game.world.blocks.valid(cell,game.world.layer): return 0
	var k:=key(cell,game.world.layer)
	var s:Dictionary=cells.get(k,{"layer":game.world.layer,"x":cell.x,"y":cell.y,"wet":0.0,"frost":0.0,"burn":0.0,"tick":0.0,"object":""})
	var water:bool=game.world.water_at(TerrainLayers.center(cell))
	var pos:=TerrainLayers.center(cell)
	var bonus:=0.0
	match kind:
		"water":
			if s.burn>0: reaction(game,pos,"浇熄",Color("9cdae2"))
			s.burn=0.0
			s.wet=6.0
		"frost":
			if s.burn>0:
				s.burn=0.0
				reaction(game,pos,"冷却灭火",Color("a8dfed"))
			s.frost=6.0
			if water or s.wet>0:
				s.wet=0.0
				reaction(game,pos,"水面结冰" if water else "湿地凝霜",Color("c1e9f3"))
		"fire":
			if s.frost>0:
				s.frost=0.0
				s.wet=4.0
				if not water:
					bonus=24.0
					reaction(game,pos,"冷热崩裂",Color("edc3a1"))
				else: reaction(game,pos,"融冰",Color("b8dce4"))
			elif water or s.wet>0:
				s.wet=3.0 if water else 0.0
				s.burn=0.0
				reaction(game,pos,"蒸汽 · 火焰熄灭",Color("c9dedd"))
			else:
				var object_id:=String(obstacle.get("id",""))
				if game.world.destruction.objects.has(object_id):
					var obj:Dictionary=game.world.destruction.objects[object_id]
					if obj.kind in ["tree","bamboo","house","furniture","bonfire"]:
						s.object=object_id
						s.burn=4.0
						reaction(game,pos,"木质引燃",Color("efaa64"))
	if cells.size()>=192 and not cells.has(k): cells.erase(cells.keys()[0])
	cells[k]=s
	game.world.queue_redraw()
	return bonus

func react_actor(game: Node, actor: Node2D, projectile: Dictionary) -> void:
	if actor.dead: return
	var s:Dictionary=actor.status if actor is Enemy else game.player.utility_gu.person_status.get(actor.resident_id,{})
	for effect in ["wet","frozen","burn","slow","bind","poison"]:
		if not s.has(effect): s[effect]=0.0
	var kind:=reaction_kind(projectile)
	if kind=="water":
		if s.burn>0: reaction(game,actor.position,"浇熄",Color("9cdae2"))
		s.burn=0.0
		s.wet=6.0
	elif kind=="fire":
		if s.wet>0 or s.frozen>0:
			s.wet=0.0
			s.frozen=0.0
			s.burn=0.0
			reaction(game,actor.position,"蒸汽 · 燃烧抵消",Color("c9dedd"))
		else:
			s.burn=maxf(s.burn,float(projectile.get("burn",0)))
			if s.bind>0:
				s.bind=0.0
				reaction(game,actor.position,"藤蔓燃断",Color("efaa64"))
	elif kind=="frost":
		s.burn=0.0
		if s.wet>0:
			s.wet=0.0
			s.frozen=2.0
			reaction(game,actor.position,"湿身冻结",Color("b8e5f5"))
	else: s.burn=maxf(s.burn,float(projectile.get("burn",0)))
	for effect in ["slow","bind","poison"]: s[effect]=maxf(s[effect],float(projectile.get(effect,0)))
	if actor is Npc: game.player.utility_gu.person_status[actor.resident_id]=s

func reaction(game: Node, pos: Vector2, title: String, color: Color) -> void:
	game.fx.text(pos.x,pos.y-38,title,color,14)
	game.fx.ring(pos.x,pos.y,color,5,36,0.65)
	game.fx.burst(pos.x,pos.y-4,color,12,75,0.7)
	game.record_reaction(title)

func tick(delta: float, game: Node) -> void:
	if game.paused or not game.running or game.player.dead: return
	save_delay+=delta
	for k in cells.keys():
		var s:Dictionary=cells[k]
		# Inactive floors do not silently burn while the player is elsewhere.
		if s.layer!=game.world.layer or game.world.in_interior: continue
		var burned:=minf(delta,float(s.burn))
		for effect in ["wet","frost","burn"]: s[effect]=maxf(0,float(s[effect])-delta)
		s.tick+=burned
		if s.tick>=0.5 or (s.burn<=0 and s.tick>0):
			if s.object!="" and not game.world.destruction.broken(s.object):
				var hits:Array=game.strike_world(TerrainLayers.center(Vector2i(s.x,s.y)),40,s.tick*8.0,"fire",Vector2.ZERO,-1,false,s.object,false)
				dirty=dirty or hits.any(func(hit:Dictionary): return float(hit.damage)>0)
			s.tick=0.0
		if s.wet<=0 and s.frost<=0 and s.burn<=0: cells.erase(k)
	if dirty and save_delay>=0.5:
		dirty=false
		save_delay=0.0
		game.save_game()

func draw(canvas: Node2D, game: Node, view: Rect2) -> void:
	for s in cells.values():
		if s.layer!=game.world.layer: continue
		var pos:=Vector2(s.x,s.y)*32
		if not view.grow(32).has_point(pos): continue
		if s.frost>0:
			canvas.draw_rect(Rect2(pos+Vector2(1,1),Vector2(30,30)),Color(0.65,0.88,0.96,0.65))
			canvas.draw_polyline(PackedVector2Array([pos+Vector2(4,6),pos+Vector2(18,14),pos+Vector2(7,25)]),Color("def5f4"),1.5,true)
		elif s.wet>0:
			canvas.draw_rect(Rect2(pos+Vector2(2,2),Vector2(28,28)),Color(0.18,0.48,0.59,0.3))
			canvas.draw_arc(pos+Vector2(16,16),10,0,PI,12,Color(0.6,0.85,0.92,0.6),1.2,true)
		if s.burn>0:
			for i in 3:
				var base:=pos+Vector2(7+i*8,26)
				canvas.draw_colored_polygon(PackedVector2Array([base-Vector2(5,0),base+Vector2(sin(s.burn*12+i)*4,-14-i*3),base+Vector2(5,0)]),Color("f1ac5e"))

func save_data() -> Dictionary:
	return cells.duplicate(true)

func load_data(raw: Variant) -> void:
	cells.clear()
	dirty=false
	save_delay=0.0
	if not raw is Dictionary: return
	for k in raw:
		if cells.size()>=192: break
		if not raw[k] is Dictionary: continue
		var s:Dictionary=raw[k].duplicate()
		var layer:=int(s.get("layer",-1))
		var cell:=Vector2i(int(s.get("x",-1)),int(s.get("y",-1)))
		if layer not in [0,1,2] or cell.x<0 or cell.y<0 or cell.x>=TerrainLayers.size_for(layer).x or cell.y>=TerrainLayers.size_for(layer).y or str(k)!=key(cell,layer): continue
		for effect in ["wet","frost","burn","tick"]:
			var value:=float(s.get(effect,0))
			s[effect]=clampf(value,0,6) if is_finite(value) else 0.0
		s.object=String(s.get("object",""))
		cells[k]=s
