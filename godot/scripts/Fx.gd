class_name Fx
extends Node2D

## 粒子、飘字、圆环、地面危险区。

var game: Node
var particles: Array = []
var texts: Array = []
var rings: Array = []
var hazards: Array = []
var low_quality := false
var _had_fx := false


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


func text(x: float, y: float, s: String, color: Color = Color("#d8e6d2"), size: int = 12) -> void:
	texts.append({
		"pos": Vector2(x, y), "text": s, "color": color, "size": size,
		"life": 0.9, "max": 0.9, "vy": -28.0,
	})


func hazard(x: float, y: float, radius: float, color: Color, dps: float, element: String) -> void:
	hazards.append({
		"pos": Vector2(x, y), "r": radius, "color": color,
		"life": 4.0, "max": 4.0, "dps": dps, "element": element,
	})


func _process(delta: float) -> void:
	if game!=null and game.paused: return
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

	if particles.is_empty() and texts.is_empty() and rings.is_empty() and hazards.is_empty():
		if _had_fx:
			_had_fx = false
			queue_redraw()
		return
	_had_fx = true
	queue_redraw()


func _draw() -> void:
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
