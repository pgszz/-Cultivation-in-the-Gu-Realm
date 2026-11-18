class_name Npc
extends Node2D

## 青茅山蛊师：给玩家第一个采集委托。

var hp := 100.0
var max_hp := 100.0
var hostile := false
var dead := false
var attack_timer := 0.0
var hurt_timer := 0.0
var resident_id := "aqing"
var radius := 14.0
var npc_name := "寨中蛊师"
var player_pos := Vector2.ZERO
var quest_state := 0  # 0 未接，1 进行中，2 已完成
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if dead:
		draw_rect(Rect2(-18,0,36,12),Color("51635e"))
		draw_string(ThemeDB.fallback_font,Vector2(-70,-8),npc_name+" · 已死亡",HORIZONTAL_ALIGNMENT_CENTER,140,11,UIStyle.DIM)
		return
	if hostile or hp<max_hp:
		draw_rect(Rect2(-25,-56,50,5),Color("27332b"))
		draw_rect(Rect2(-25,-56,50*hp/max_hp,5),UIStyle.RED)

	draw_circle(Vector2(0, 14), 12.0, Color(0, 0, 0, 0.35))
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	draw_texture_rect_region(preload("res://assets/ninja_adventure/samurai_blue.png"),Rect2(-20,-28,40,40),Rect2(0,0,16,16))

	draw_string(ThemeDB.fallback_font, Vector2(-46, -30), npc_name,
		HORIZONTAL_ALIGNMENT_CENTER, 92, 11, Color("#d9c46a"))

	if player_pos.distance_to(position) < 80.0 and not hostile:
		var hint := "按 E 交谈"
		if quest_state == 1:
			hint = "按 E 交任务"
		draw_string(ThemeDB.fallback_font, Vector2(-52, -44), hint,
			HORIZONTAL_ALIGNMENT_CENTER, 104, 11, Color("#f0e8d0"))

func take_damage(amount: float, game: Node, element: String = "none") -> void:
	if dead: return
	hp=maxf(0.0,hp-amount)
	hurt_timer=0.25
	if not hostile:
		hostile=true
		game.add_log(npc_name+"遭到攻击，与你敌对。",UIStyle.RED)
	game.fx.text(position.x,position.y-18,"-%d"%ceili(amount),GameData.el_color(element))
	if hp<=0:
		dead=true
		game.add_log(npc_name+"已死亡，无法继续交谈或提供服务。",UIStyle.RED)
		game.save_game()
	queue_redraw()

func tick(delta: float, game: Node) -> void:
	hurt_timer=maxf(0.0,hurt_timer-delta)
	modulate=Color("ef9b85") if hurt_timer>0 else Color.WHITE
	if dead or not hostile: return
	attack_timer=maxf(0.0,attack_timer-delta)
	var offset: Vector2=game.player.position-position
	if offset.length()>340: return
	if offset.length()>44:
		var step:=offset.normalized()*95*delta
		game.world.move_body(self,step.x,step.y,radius)
	elif attack_timer<=0:
		attack_timer=1.4
		game.damage_player(7.0,"none")

func save_data() -> Dictionary:
	return {"hp":hp,"hostile":hostile,"dead":dead}

func load_data(data: Dictionary) -> void:
	hp=clampf(float(data.get("hp",max_hp)),0,max_hp)
	dead=bool(data.get("dead",false)) or hp<=0
	hostile=bool(data.get("hostile",false))
	if dead: hp=0
	queue_redraw()
