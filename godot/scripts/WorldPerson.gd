class_name WorldPerson
extends Npc

## A persistent person; PopulationSystem owns decisions and the outdoor clock.
var role := "villager"
var faction := ""
var home := Vector2.ZERO
var route: Array[Vector2] = []
var route_names: Array[String] = []
var route_index := 0
var wait_left := 0.0
var speed := 58.0
var damage := 5.0
var activity := "行走"
var path := PackedVector2Array()
var path_index := 0
var path_goal := Vector2.INF
var replan_left := 0.0
var blocked_time := 0.0
var scan_left := 0.0
var target: Node2D
var attack_target: Node2D
var attack_direction := Vector2.RIGHT
var strike_left := 0.0
var flee_left := 0.0
var attacker_position := Vector2.ZERO
var caravan := false
var trail := PackedVector2Array()

func configure(config: Dictionary, main: Node) -> void:
	game=main
	resident_id=config.id
	npc_name=config.name
	role=config.role
	faction=config.get("faction","山野行人")
	settlement_id=config.get("clan","")
	outdoors=true
	caravan=bool(config.get("caravan",false))
	for point in config.route: route.append(point)
	for label in config.get("stops",[]): route_names.append(label)
	route_index=int(config.get("index",0))%route.size()
	position=route[route_index]
	home=route[0]
	max_hp=160.0 if role in ["guard","escort"] else (85.0 if role=="bandit" else 65.0)
	hp=max_hp
	speed=76.0 if role in ["guard","escort","bandit"] else 58.0
	damage=12.0 if role in ["guard","escort"] else (7.0 if role=="bandit" else 3.0)
	if CanonPeople.has(resident_id):
		# Shared prototype self-defence parameters, not an invented canon power ranking.
		max_hp=100.0
		hp=max_hp
		speed=68.0
		damage=Npc.ATTACK_DAMAGE
	appearance_id=NpcAppearance.restore(config.get("appearance"),resident_id,role,settlement_id)
	hostile=role=="bandit"
	radius=12.0
	scan_left=float(abs(resident_id.hash())%50)/100.0
	wait_left=float(config.get("wait",2.0))
	trail.append(position)
	name="Person_"+resident_id

func _process(_delta: float) -> void:
	if visible: queue_redraw()

func appearance_role() -> String:
	return role

func tick(_delta: float, _main: Node) -> void:
	pass # Main's ordinary NPC loop must not advance these people twice.

func color_for_role() -> Color:
	if hostile: return Color("df8c79")
	if caravan: return Color("e5c18b")
	return Color("99cbd0") if role=="guard" else Color("c8d1a5")

func _draw() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	animation.draw(self,true,0,false,get_appearance())
	if player_pos.distance_to(position)>420: return
	draw_speech()
	var tint:=color_for_role()
	var label:=npc_name+(" · 已死亡" if dead else "")
	draw_string_outline(ThemeDB.fallback_font,Vector2(-90,-57),label,HORIZONTAL_ALIGNMENT_CENTER,180,11,3,Color("13231b"))
	draw_string(ThemeDB.fallback_font,Vector2(-90,-57),label,HORIZONTAL_ALIGNMENT_CENTER,180,11,tint)
	if dead: return
	if hp<max_hp or hostile:
		draw_rect(Rect2(-23,-49,46,3),Color("27332b"))
		draw_rect(Rect2(-23,-49,46*hp/max_hp,3),tint)
	if player_pos.distance_to(position)<180:
		draw_string_outline(ThemeDB.fallback_font,Vector2(-85,25),activity,HORIZONTAL_ALIGNMENT_CENTER,170,10,3,Color("13231b"))
		draw_string(ThemeDB.fallback_font,Vector2(-85,25),activity,HORIZONTAL_ALIGNMENT_CENTER,170,10,Color("c4cbbb"))
	if player_pos.distance_to(position)<80 and not hostile and game.population.nearest_speaker()==self:
		draw_string(ThemeDB.fallback_font,Vector2(-100,-74),"Alt + 左键查看 · E 交谈",HORIZONTAL_ALIGNMENT_CENTER,200,10,Color("eee3c5"))

func take_damage(amount: float, main: Node, element: String = "none") -> void:
	if dead or amount<=0: return
	social.ensure(self)
	var was_hostile:=hostile
	hostile=true
	receive_hit(amount,main.player)
	if not was_hostile: main.add_log(npc_name+"遭到攻击，与你敌对。",UIStyle.RED)
	main.population.alert_assault(self)
	main.save_game()

func receive_hit(amount: float, source: Node2D) -> void:
	if dead or amount<=0: return
	amount=game.player.gu_effects.absorb_ally_damage(amount,self,source,game)
	if amount<=0: return
	NpcSocial.hit(self,source)
	ensure_possessions()
	hp=maxf(0,hp-amount)
	hurt_timer=0.28
	strike_left=0
	attack_target=null
	if is_instance_valid(source):
		attacker_position=source.position
		target=source
		facing=(source.position-position).angle()
	flee_left=8.0
	animation.play("hurt",facing,0.28)
	if game.fog.can_see(position): game.fx.text(position.x,position.y-22,"-%d"%ceili(amount),UIStyle.RED)
	if hp<=0:
		dead=true
		NpcSocial.died(self,source)
		target=null
		activity="已死亡"
		animation.play("death",facing)
		game.population.person_died(self)
		if game.fog.can_see(position): game.add_log(npc_name+"倒下了。",UIStyle.DIM)
		game.save_game()

func inspection_data() -> Dictionary:
	var title:String=PopulationSystem.ROLE_NAMES.get(role,"行人")
	if CanonPeople.has(resident_id): title=CanonPeople.PEOPLE[resident_id].title
	return {"name":npc_name,"role":title,"place":faction,"duty":title,"description":game.population.description(self),
		"faction":faction,"relationship":"敌对" if hostile else "中立",
		"relationship_reason":"寨外劫道者，会攻击路过的行人。" if role=="bandit" else (("因你盗窃随身物品而反击，已与你敌对。" if social.theft_retaliation else "你曾袭击此人或其保护的队伍。") if hostile else "目前没有与你发生敌对冲突。"),
		"health":"已死亡" if dead else ("受伤" if hp<max_hp else "健康"),"activity":activity,
		"hp":hp,"max_hp":max_hp,"dead":dead,"hostile":hostile,"attack":damage if game.population.can_fight(self) else 0.0,"interval":1.3,"speed":speed*1.25,"appearance":get_appearance()}

func save_data() -> Dictionary:
	return {"hp":hp,"dead":dead,"hostile":hostile,"position":[position.x,position.y],"route_index":route_index,
		"wait":wait_left,"facing":facing,"flee":flee_left,"attacker":[attacker_position.x,attacker_position.y],"possessions":save_possessions(),"appearance":get_appearance(),"conversation":conversation.duplicate(),"social":social.save_data(self)}

func load_data(data: Dictionary) -> void:
	load_conversation(data)
	appearance_id=NpcAppearance.restore(data.get("appearance"),resident_id,role,settlement_id)
	hp=clampf(float(data.get("hp",max_hp)),0,max_hp)
	dead=bool(data.get("dead",false)) or hp<=0
	hostile=role=="bandit" or bool(data.get("hostile",false))
	if dead: hp=0
	social.load_data(self,data.get("social"))
	load_possessions(data)
	route_index=clampi(int(data.get("route_index",route_index)),0,route.size()-1)
	wait_left=clampf(float(data.get("wait",wait_left)),0,60)
	facing=float(data.get("facing",0))
	flee_left=clampf(float(data.get("flee",0)),0,8)
	var pos:Variant=data.get("position")
	if pos is Array and pos.size()==2:
		var restored:=Vector2(float(pos[0]),float(pos[1]))
		if restored.is_finite() and Rect2(32,32,(GameData.MAP_W-2)*32,(GameData.MAP_H-2)*32).has_point(restored): position=restored
	var threat:Variant=data.get("attacker")
	if threat is Array and threat.size()==2: attacker_position=Vector2(float(threat[0]),float(threat[1]))
	animation.restore_dead(dead)
	activity="已死亡" if dead else ("避险逃离" if flee_left>0 else "继续行程")
	target=null
	attack_target=null
	strike_left=0
	path.clear()
	path_goal=Vector2.INF
	trail=PackedVector2Array([position])
