class_name TopLayer
extends Node2D

## 画在最上层：弹道、捕获进度环。

var game: Node
var _had_content := false


func _process(_delta: float) -> void:
	if game == null:
		return
	var has_content:bool=not game.projectiles.is_empty() or game.player.capture_target!=null
	if has_content or _had_content: queue_redraw()
	_had_content=has_content


func _draw() -> void:
	if game == null:
		return
	for pr in game.projectiles:
		if GameData.is_utility_gu(pr.get("gu_id","")):
			UtilityGuEffects.draw_projectile(self,pr)
			continue
		if pr.get("gu_id","") in ["moon_blade","moon_glow"]:
			GuVfx.draw_moon(self,pr,game.low_quality)
			continue
		var col: Color = pr["color"]
		var a: float = clampf(pr["life"] / pr["max_life"] + 0.3, 0.0, 1.0)
		draw_circle(pr["pos"], pr["r"], Color(col, a))
		draw_circle(pr["pos"] - pr["vel"] * 0.012, pr["r"] * 0.7, Color(col, a * 0.4))

	var p: Player = game.player
	if p != null and p.capture_target != null and is_instance_valid(p.capture_target):
		var t: Enemy = p.capture_target
		if not t.dead:
			var pct: float = clampf(p.capture_progress / 1.2, 0.0, 1.0)
			draw_arc(t.position, t.radius + 10.0, -PI / 2.0, -PI / 2.0 + TAU * pct, 32, Color("#d9c46a"), 3.0)
			draw_string(ThemeDB.fallback_font, t.position + Vector2(-40, -t.radius - 26),
				"收蛊中…", HORIZONTAL_ALIGNMENT_CENTER, 80, 11, Color("#d9c46a"))
