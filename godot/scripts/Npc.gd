class_name Npc
extends Node2D

## 山寨人物；查看页读取这里的实时状态和实际战斗参数。

const ATTACK_DAMAGE := 7.0
const ATTACK_INTERVAL := 1.4
const PURSUIT_SPEED := 95.0
const ATTACK_RANGE := 44.0
const NOTICE_RANGE := 340.0
const PROFILES := {
	"aqing":{"role":"寨中蛊师","place":"古月山寨","duty":"修行指点","text":"常在寨中停留，可向他请教温养空窍与供养蛊虫的常识。"},
	"clinic":{"role":"药堂医者","place":"古月药堂","duty":"包扎与药品","text":"在药堂为来访者包扎伤口，并出售绷带。"},
	"shop":{"role":"商铺伙计","place":"古月商铺","duty":"买卖与委托","text":"照看商铺的蛊虫、蛊食与补给，也受理山寨委托。"},
	"archive":{"role":"学堂执事","place":"古月学堂","duty":"地理与委托","text":"在学堂讲解青茅山地理与修行常识，并受理山寨委托。"}
}

var hp := 100.0
var max_hp := 100.0
var hostile := false
var dead := false
var attack_timer := 0.0
var hurt_timer := 0.0
var resident_id := "aqing"
var outdoors := false
var settlement_id := ""
var radius := 14.0
var npc_name := "寨中蛊师"
var player_pos := Vector2.ZERO
var quest_state := 0  # 0 未接，1 进行中，2 已完成
var _t := 0.0
var game: Node
var animation := ActorAnimation.new()
var facing := 0.0
var _last_position := Vector2.ZERO
var carried_items: Dictionary = {}
var carried_crystals := 0
var possessions_initialized := false
var appearance_id := ""
var conversation: Dictionary = {}
var social := NpcSocial.new()
var speech := ""
var speech_left := 0.0
var greeting_cooldown := 0.0

func social_tick(delta: float) -> void:
	speech_left=maxf(0,speech_left-delta)
	greeting_cooldown=maxf(0,greeting_cooldown-delta)
	if dead or hostile:
		speech_left=0
		return
	if greeting_cooldown>0 or player_pos.distance_to(position)>86: return
	if game.person_talk_blocker(self)!="": return
	greeting_cooldown=24.0
	speech_left=3.5
	speech="又见面了，路上可好？" if not conversation.is_empty() else ("伤还没好，容我歇歇。" if hp<max_hp*0.5 else "要问路吗？过来聊聊。")
	if CanonPeople.has(resident_id): speech=CanonPeople.PEOPLE[resident_id].bubble
	if not self is WorldPerson: facing=(player_pos-position).angle()

func draw_speech() -> void:
	if speech_left<=0 or dead or hostile: return
	var rect:=Rect2(-112,-113,224,28)
	draw_style_box(UIStyle.box(Color("172d2c"),Color("718675"),5),rect)
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(5,19),speech,HORIZONTAL_ALIGNMENT_CENTER,214,12,Color("e0e5ce"))

func load_conversation(data: Dictionary) -> void:
	conversation.clear()
	var raw:Variant=data.get("conversation",{})
	if raw is Dictionary:
		for topic in raw:
			if NpcConversation.TOPICS.has(topic) or topic=="care": conversation[topic]=true
	speech_left=0
	greeting_cooldown=0

func appearance_role() -> String:
	return ""

func get_appearance() -> String:
	appearance_id=NpcAppearance.restore(appearance_id,resident_id,appearance_role(),settlement_id)
	return appearance_id


func _process(delta: float) -> void:
	var walking:=position.distance_to(_last_position)>0.1
	_last_position=position
	if not visible or (game!=null and game.paused): return
	_t += delta
	animation.advance(delta,walking,facing)
	queue_redraw()


func _draw() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	animation.draw(self,true,0,false,get_appearance())
	draw_speech()
	if dead:
		draw_string(ThemeDB.fallback_font,Vector2(-70,-8),npc_name+" · 已死亡",HORIZONTAL_ALIGNMENT_CENTER,140,11,UIStyle.DIM)
		return
	if hostile or hp<max_hp:
		draw_rect(Rect2(-25,-78,50,5),Color("27332b"))
		draw_rect(Rect2(-25,-78,50*hp/max_hp,5),UIStyle.RED)

	draw_string(ThemeDB.fallback_font, Vector2(-46, -56), npc_name,
		HORIZONTAL_ALIGNMENT_CENTER, 92, 11, Color("#d9c46a"))

	if player_pos.distance_to(position) < 80.0 and not hostile:
		draw_string(ThemeDB.fallback_font, Vector2(-90, -70), "Alt + 左键查看 · E 交谈",
			HORIZONTAL_ALIGNMENT_CENTER, 180, 11, Color("#f0e8d0"))

func take_damage(amount: float, game: Node, element: String = "none") -> void:
	if dead or amount<=0: return
	NpcSocial.hit(self,game.player)
	ensure_possessions()
	hp=maxf(0.0,hp-amount)
	hurt_timer=0.25
	animation.play("hurt",facing,0.28)
	if not hostile:
		hostile=true
		game.add_log(npc_name+"遭到攻击，与你敌对。",UIStyle.RED)
	game.fx.text(position.x,position.y-18,"-%d"%ceili(amount),GameData.el_color(element))
	if hp<=0:
		dead=true
		NpcSocial.died(self,game.player)
		animation.play("death",facing)
		game.add_log(npc_name+"已死亡，无法继续交谈或提供服务。",UIStyle.RED)
		game.save_game()
	queue_redraw()

func tick(delta: float, game: Node) -> void:
	hurt_timer=maxf(0.0,hurt_timer-delta)
	if dead or not hostile: return
	if float(game.player.utility_gu.person_status.get(resident_id,{}).get("frozen",0))>0: return
	attack_timer=maxf(0.0,attack_timer-delta)
	var offset: Vector2=game.player.position-position
	facing=offset.angle()
	if offset.length()>NOTICE_RANGE: return
	if offset.length()>ATTACK_RANGE:
		var step:Vector2=offset.normalized()*PURSUIT_SPEED*delta*game.player.utility_gu.person_speed(self)
		game.world.move_body(self,step.x,step.y,radius)
	elif attack_timer<=0 and game.world.attack_clear(position,game.player.position):
		attack_timer=ATTACK_INTERVAL
		animation.play("strike",facing,0.4)
		game.damage_player(ATTACK_DAMAGE,"none")

func inspection_data() -> Dictionary:
	var profile:=inspection_profile()
	var health:="已死亡" if dead else ("濒危" if hp<=max_hp*0.25 else ("受伤" if hp<max_hp else "健康"))
	var activity:="停留" if resident_id=="aqing" or outdoors else "当值"
	if hostile:
		var distance:float=position.distance_to(game.player.position) if game!=null else INF
		activity="警戒" if distance>NOTICE_RANGE else ("近身交战" if distance<=ATTACK_RANGE else "追击你")
	if hurt_timer>0: activity="刚刚受击"
	if dead: activity="已死亡"
	return {"name":npc_name,"role":profile.role,"place":profile.place,"duty":profile.duty,"description":profile.text,
		"faction":profile.faction,"relationship":"敌对" if hostile else "中立",
		"relationship_reason":("因你盗窃随身物品而反击，已与你敌对。" if social.theft_retaliation else "曾遭到你的攻击，已与你敌对。") if hostile else "目前没有与你发生敌对冲突。",
		"health":health,"activity":activity,"hp":hp,"max_hp":max_hp,"dead":dead,"hostile":hostile,"appearance":get_appearance()}

func inspection_rect() -> Rect2:
	return Rect2(-34,-28,68,48) if dead else Rect2(-30,-54,60,68)

func inspection_profile() -> Dictionary:
	if PROFILES.has(resident_id):
		var profile:Dictionary=PROFILES[resident_id].duplicate()
		profile["faction"]="古月山寨"
		return profile
	var building:=SettlementData.building(resident_id)
	var clan:String=String(building.clan) if not building.is_empty() else settlement_id
	var faction:String={"bai":"白家寨","xiong":"熊家寨"}.get(clan,"未知")
	if not building.is_empty():
		return {"role":npc_name,"place":building.name,"duty":building.hint,"faction":faction,"text":"常驻%s，可向其询问此处事务。" % building.name}
	if outdoors and clan!="":
		return {"role":npc_name,"place":faction,"duty":"寨内指路","faction":faction,"text":"在寨中停留，可询问药堂、商铺等地点的方向。"}
	return {"role":npc_name,"place":"未知","duty":"未知","faction":"未知","text":"尚无更多身份资料。"}

func save_data() -> Dictionary:
	return {"hp":hp,"hostile":hostile,"dead":dead,"possessions":save_possessions(),"appearance":get_appearance(),"conversation":conversation.duplicate(),"social":social.save_data(self)}

func ensure_possessions() -> void:
	if possessions_initialized: return
	possessions_initialized=true
	var initial:=PersonExchange.initial_possessions(self)
	carried_items=initial.items.duplicate()
	carried_crystals=int(initial.crystals)

func save_possessions() -> Dictionary:
	ensure_possessions()
	return {"items":carried_items.duplicate(),"crystals":carried_crystals}

func load_possessions(data: Dictionary) -> void:
	possessions_initialized=false
	ensure_possessions()
	if not data.has("possessions"):
		# Old corpses have no recorded belongings; do not invent repeatable rewards.
		if dead:
			carried_items.clear()
			carried_crystals=0
		return
	carried_items.clear()
	carried_crystals=0
	var saved:Variant=data.possessions
	if not saved is Dictionary: return
	carried_crystals=clampi(int(saved.get("crystals",0)),0,1000000000)
	var items:Variant=saved.get("items",{})
	if not items is Dictionary: return
	for id in items:
		if not PersonExchange.ordinary_item(str(id)): continue
		var count:=clampi(int(items[id]),0,Inventory.MAX_STACK*10)
		if count>0: carried_items[str(id)]=count

func load_data(data: Dictionary) -> void:
	load_conversation(data)
	appearance_id=NpcAppearance.restore(data.get("appearance"),resident_id,appearance_role(),settlement_id)
	hurt_timer=0.0
	attack_timer=0.0
	hp=clampf(float(data.get("hp",max_hp)),0,max_hp)
	dead=bool(data.get("dead",false)) or hp<=0
	hostile=bool(data.get("hostile",false))
	if dead: hp=0
	social.load_data(self,data.get("social"))
	load_possessions(data)
	animation.restore_dead(dead)
	queue_redraw()
