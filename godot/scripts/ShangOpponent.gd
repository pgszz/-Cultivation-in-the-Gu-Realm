class_name ShangOpponent
extends Npc

var city: Node
var profile: Dictionary
var windup := 0.0
var aim := Vector2.ZERO
var defeated := false

func inspection_profile() -> Dictionary:
	return {"role":"演武蛊师","place":"商家城 · 第五内城","duty":"擂台对战","faction":"演武场","text":"本场对手，真实伤害 %.0f；蓄势 0.55 秒，可移动躲避。"%float(profile.get("damage",0))}

func inspection_data() -> Dictionary:
	var data:=super.inspection_data()
	data.relationship="演武对手"
	data.relationship_reason="已登记的演武对局；本场结束后离场。"
	return data

func take_damage(amount: float, main: Node, element: String = "none") -> void:
	if defeated or not city.bout or amount<=0: return
	hp=maxf(0,hp-amount)
	animation.play("hurt",facing,0.22)
	main.fx.text(position.x,position.y-25,"-%.0f"%amount,GameData.el_color(element))
	if hp<=0:
		defeated=true
		animation.play("death",facing)
		# Deferred: projectile iteration must finish before clearing transients.
		city.finish_bout.call_deferred(true)

func social_tick(_delta: float) -> void:
	pass

func tick(delta: float, main: Node) -> void:
	if defeated or not city.bout or main.player.dead: return
	if float(main.player.utility_gu.person_status.get(resident_id,{}).get("frozen",0))>0: return
	attack_timer=maxf(0,attack_timer-delta)
	var offset:Vector2=main.player.position-position
	facing=offset.angle()
	if windup>0:
		windup=maxf(0,windup-delta)
		if windup<=0:
			animation.play("strike",facing,0.3)
			if int(profile.style)==2:
				main.spawn_projectile(position,(aim-position).normalized()*270,float(profile.damage),"moon","enemy",{"color":Color("92dcf4")})
			elif main.player.position.distance_to(aim)<48 and position.distance_to(main.player.position)<90:
				main.damage_player(float(profile.damage))
		return
	var reach:=210.0 if int(profile.style)==2 else 48.0
	if offset.length()>reach:
		var step:Vector2=offset.normalized()*float(profile.speed)*delta*main.player.utility_gu.person_speed(self)
		main.world.move_body(self,step.x,step.y,radius)
	elif attack_timer<=0:
		attack_timer=1.7
		windup=0.55
		aim=main.player.position
		main.fx.ring(aim.x,aim.y,UIStyle.RED,12,46,0.55)
		main.fx.text(position.x,position.y-90,"蓄势 · 闪避",UIStyle.RED,12)

func _draw() -> void:
	animation.draw(self,true,0,false,get_appearance())
	draw_string(ThemeDB.fallback_font,Vector2(-80,-85),npc_name,HORIZONTAL_ALIGNMENT_CENTER,160,13,UIStyle.GOLD)
	draw_rect(Rect2(-40,-74,80,6),Color("293332"))
	draw_rect(Rect2(-40,-74,80*hp/max_hp,6),UIStyle.RED)
