class_name Fx
extends Node2D

## 粒子、飘字、圆环、地面危险区。

var game: Node
var particles: Array = []
var texts: Array = []
var rings: Array = []
var hazards: Array = []
var chunks: Array = []
var impacts: Array = []
var low_quality := false
var _had_fx := false
var gu := GuVfx.new()


func clear_transients() -> void:
	particles.clear()
	texts.clear()
	rings.clear()
	hazards.clear()
	chunks.clear()
	impacts.clear()
	gu.clear(game.player.position if game!=null and game.player!=null else Vector2.ZERO)
	queue_redraw()


func burst(x: float, y: float, color: Color, n: int = 8, speed: float = 120.0, life: float = 0.45) -> void:
	if low_quality:
		n = int(n * 0.5)
	for i in n:
		var a := randf() * TAU
		var s := randf_range(speed * 0.3, speed)
		particles.append({
			"pos": Vector2(x, y),
			"vel": Vector2(cos(a), sin(a)) * s,
			"life": life, "max": life, "color": color,
			"size": randf_range(1.5, 3.5), "grav": 40.0,
		})


func ring(x: float, y: float, color: Color, r0: float, r1: float, life: float = 0.4) -> void:
	rings.append({"pos": Vector2(x, y), "color": color, "r0": r0, "r1": r1, "life": life, "max": life})

func eject_blocks(pos: Vector2, direction: Vector2, force: float, color: Color) -> void:
	var strong:=force>=32
	for i in (3 if strong else 2):
		var angle:=direction.angle()+randf_range(-0.45,0.45)
		chunks.append({"pos":pos,"vel":Vector2.from_angle(angle)*(clampf(force*4,40,260)+i*12),"z":8.0,"vz":150.0 if strong else 70.0,"life":1.4,"size":15.0 if strong else 6.0,"angle":0.0,"spin":randf_range(-6,6),"color":color})
	while chunks.size()>48: chunks.pop_front()


func text(x: float, y: float, s: String, color: Color = Color("#d8e6d2"), size: int = 12) -> void:
	texts.append({
		"pos": Vector2(x, y), "text": s, "color": color, "size": size,
		"life": 0.9, "max": 0.9, "vy": -28.0,
	})

func impact_mark(pos: Vector2, direction: Vector2, broken: bool) -> void:
	impacts.append({"pos":pos,"angle":direction.angle(),"life":0.45,"broken":broken})
	while impacts.size()>24: impacts.pop_front()
	if broken:
		burst(pos.x,pos.y,Color("c9b797"),20,80,0.8)
	queue_redraw()


func hazard(x: float, y: float, radius: float, color: Color, dps: float, element: String) -> void:
	hazards.append({
		"pos": Vector2(x, y), "r": radius, "color": color,
		"life": 4.0, "max": 4.0, "dps": dps, "element": element,
	})


func _process(delta: float) -> void:
	if game!=null:
		gu.advance(delta,game)
		if game.paused:
			queue_redraw()
			return
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p["life"] -= delta
		if float(p["life"]) <= 0.0:
			particles.remove_at(i)
			continue
		var v: Vector2 = p["vel"]
		v.y += float(p["grav"]) * delta
		v *= 0.98
		p["vel"] = v
		p["pos"] = p["pos"] + v * delta
	for i in range(impacts.size()-1,-1,-1):
		impacts[i].life-=delta
		if impacts[i].life<=0: impacts.remove_at(i)
	for i in range(chunks.size()-1,-1,-1):
		var block:Dictionary=chunks[i]
		block.life-=delta
		if block.life<=0: chunks.remove_at(i); continue
		var next:Vector2=block.pos+block.vel*delta
		if game!=null and game.world.collides(next.x,next.y,2): block.vel*=-0.3
		else: block.pos=next
		block.vz-=420*delta
		block.z=maxf(0,block.z+block.vz*delta)
		if block.z<=0:
			block.vel*=pow(0.03,delta)
			block.vz=-block.vz*0.25 if block.vz<-30 else 0.0
		block.angle+=block.spin*delta

	for i in range(texts.size() - 1, -1, -1):
		var t2: Dictionary = texts[i]
		t2["life"] -= delta
		if float(t2["life"]) <= 0.0:
			texts.remove_at(i)
			continue
		var pos: Vector2 = t2["pos"]
		pos.y += float(t2["vy"]) * delta
		t2["pos"] = pos

	for i in range(rings.size() - 1, -1, -1):
		var r: Dictionary = rings[i]
		r["life"] -= delta
		if float(r["life"]) <= 0.0:
			rings.remove_at(i)

	for i in range(hazards.size() - 1, -1, -1):
		var h: Dictionary = hazards[i]
		h["life"] -= delta
		if float(h["life"]) <= 0.0:
			hazards.remove_at(i)

	while particles.size()>(192 if low_quality else 512): particles.pop_front()
	while texts.size()>48: texts.pop_front()
	while rings.size()>48: rings.pop_front()
	var status_fx:=false
	if game!=null:
		status_fx=game.player.gu_effects.ward_valid(game) or not game.player.utility_gu.person_status.is_empty()
		if not status_fx:
			for actor in game.active_enemies():
				if actor.dead: continue
				if float(actor.status.get("burn",0))+float(actor.status.get("slow",0))+float(actor.status.get("bind",0))>0:
					status_fx=true
					break
	if particles.is_empty() and texts.is_empty() and rings.is_empty() and hazards.is_empty() and chunks.is_empty() and impacts.is_empty() and gu.events.is_empty() and not status_fx:
		if _had_fx:
			_had_fx = false
			queue_redraw()
		return
	_had_fx = true
	queue_redraw()


func _draw() -> void:
	for mark in impacts:
		var progress:=1.0-float(mark.life)/0.45
		var color:=Color(0.95,0.91,0.71,(1-progress)*0.85)
		for i in 6:
			var direction:=Vector2.from_angle(mark.angle+i*TAU/6)
			draw_line(mark.pos+direction*(5+progress*8),mark.pos+direction*(12+progress*(24 if mark.broken else 9)),color,2,true)
	if game!=null: gu.draw_world(self,game)
	if game!=null: game.player.utility_gu.draw_world(self,game)
	for block in chunks:
		var alpha:=minf(1,block.life*3)
		draw_circle(block.pos,block.size*0.4,Color(0.02,0.04,0.04,alpha*0.4))
		draw_set_transform(block.pos-Vector2(0,block.z),block.angle)
		draw_rect(Rect2(Vector2.ONE*-block.size*0.5,Vector2.ONE*block.size),Color(block.color,alpha))
		draw_rect(Rect2(Vector2.ONE*-block.size*0.5,Vector2(block.size,3)),Color(Color(block.color).lightened(0.3),alpha))
		draw_set_transform(Vector2.ZERO)
	for h in hazards:
		var a := 0.25 + sin(Time.get_ticks_msec() * 0.006) * 0.08
		draw_circle(h["pos"], h["r"], Color(h["color"], a))

	for p in particles:
		var a: float = clampf(p["life"] / p["max"], 0.0, 1.0)
		var s: float = p["size"]
		draw_rect(Rect2(p["pos"].x - s / 2.0, p["pos"].y - s / 2.0, s, s), Color(p["color"], a))

	for r in rings:
		var t: float = 1.0 - r["life"] / r["max"]
		var rad: float = lerpf(r["r0"], r["r1"], t)
		draw_arc(r["pos"], rad, 0.0, TAU, 32, Color(r["color"], 1.0 - t), 2.0)

	var font := ThemeDB.fallback_font
	for t in texts:
		var a: float = clampf(t["life"] / t["max"], 0.0, 1.0)
		draw_string(font, t["pos"], t["text"], HORIZONTAL_ALIGNMENT_CENTER, 120, t["size"], Color(t["color"], a))
