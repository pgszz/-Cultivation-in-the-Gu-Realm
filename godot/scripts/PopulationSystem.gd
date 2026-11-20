class_name PopulationSystem
extends RefCounted

## Routes, schedules and trade values are sandbox parameters. CanonPeople holds sourced identities.
const ROLE_NAMES := {"villager":"寨民","guard":"巡寨守卫","gatherer":"采集山民","traveler":"行脚人","merchant":"行商","porter":"挑夫","escort":"护商镖师","bandit":"山路强盗","cultivator":"寨中修行人"}
const GOODS := {"bandage":{"name":"绷带","price":2,"cap":8},"bamboo_wine":{"name":"青竹酒","price":3,"cap":6},"timber":{"name":"木料","price":2,"cap":10},"rubble":{"name":"碎石","price":2,"cap":8}}
var game: Node
var actors: Dictionary = {}
var navigation := AStarGrid2D.new()
var initialized := false
var day_clock := 480.0
var stock: Dictionary:
	get:
		var merchant:WorldPerson=actors.get("caravan_merchant")
		if merchant==null: return {}
		merchant.ensure_possessions()
		return merchant.carried_items
var restock_left := 600.0
var path_budget := 0
var caravan_ids: Array[String] = ["caravan_merchant","caravan_porter","caravan_guard_a","caravan_guard_b"]

func setup(main: Node) -> void:
	game=main

static func site(id: String) -> Vector2:
	for data in World.EXPLORATION_SITES:
		if data.id==id: return Vector2(data.pos)*32+Vector2(16,16)
	return Vector2(720,1008)

func definitions() -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var settlements:=[{"id":"guyue","name":"古月","base":Vector2(512,1040),"route":[Vector2(336,1264),Vector2(720,1264),Vector2(816,1008),Vector2(336,944)]},
		{"id":"bai","name":"白家","base":GameData.BAI_VILLAGE,"route":[GameData.BAI_VILLAGE+Vector2(-160,672),GameData.BAI_VILLAGE+Vector2(160,384),GameData.BAI_VILLAGE+Vector2(160,64),GameData.BAI_VILLAGE+Vector2(-160,-256)]},
		{"id":"xiong","name":"熊家","base":GameData.XIONG_VILLAGE,"route":[GameData.XIONG_VILLAGE+Vector2(160,672),GameData.XIONG_VILLAGE+Vector2(-160,384),GameData.XIONG_VILLAGE+Vector2(-160,64),GameData.XIONG_VILLAGE+Vector2(160,-256)]}]
	for settlement in settlements:
		for i in 4:
			var route:Array=settlement.route.duplicate()
			route.append(route.pop_front())
			for unused in i: route.append(route.pop_front())
			result.append({"id":settlement.id+"_civil_"+str(i),"name":settlement.name+["寨民","挑水人","赶集人","织户"][i],"role":"villager","faction":settlement.name+"山寨","clan":settlement.id,"route":route,"wait":2.0+i*2.0})
		for i in 2:
			result.append({"id":settlement.id+"_patrol_"+str(i),"name":settlement.name+"巡卫"+("甲" if i==0 else "乙"),"role":"guard","faction":settlement.name+"山寨","clan":settlement.id,"route":settlement.route,"index":i*2,"wait":i*4.0})
	result.append({"id":"bamboo_gatherer","name":"采竹山民","role":"gatherer","route":[Vector2(752,1328),site("south_bamboo"),site("old_camp")],"stops":["寨外住处","南麓竹坡","山民歇脚棚"]})
	result.append({"id":"stone_gatherer","name":"采石山民","role":"gatherer","route":[site("old_camp"),site("south_pass"),site("central_camp")],"stops":["山民歇脚棚","南山石径","溪边营地"]})
	result.append({"id":"east_traveler","name":"东路行脚人","role":"traveler","route":[site("bamboo_hollow"),site("river_ford"),site("central_camp")],"stops":["东麓竹坳","溪谷渡口","溪边营地"]})
	result.append({"id":"south_traveler","name":"南路行脚人","role":"traveler","route":[site("reed_camp"),site("trail_camp"),site("old_camp")],"stops":["芦岸歇脚地","古道行脚营","山民歇脚棚"]})
	var caravan_route:=[Vector2(816,1008),site("bamboo_hollow"),site("switchback_camp"),GameData.BAI_VILLAGE+Vector2(160,64),site("cedar_station"),GameData.XIONG_VILLAGE+Vector2(-160,64),site("trail_camp"),site("old_camp")]
	var stops:=["古月寨外集市","东麓竹坳","盘山歇脚棚","白家商街","杉林驿棚","熊家商街","古道行脚营","山民歇脚棚"]
	for i in caravan_ids.size():
		result.append({"id":caravan_ids[i],"name":["山路行商","商队挑夫","护商镖师甲","护商镖师乙"][i],"role":["merchant","porter","escort","escort"][i],"faction":"青茅行商队","caravan":true,"route":caravan_route,"stops":stops,"wait":18.0})
	for camp in [{"id":"east","pos":site("bamboo_hollow")+Vector2(256,96)},{"id":"south","pos":site("south_pass")+Vector2(192,96)}]:
		for i in 2:
			result.append({"id":camp.id+"_bandit_"+str(i),"name":("东路" if camp.id=="east" else "南路")+"强盗"+("甲" if i==0 else "乙"),"role":"bandit","faction":"山路劫匪","route":[camp.pos+Vector2(i*64,0),camp.pos+Vector2(-96,64),camp.pos+Vector2(96,128)],"wait":3.0+i})
	result.append_array(CanonPeople.definitions())
	return result

func initialize() -> void:
	if initialized: return
	rebuild_navigation()
	for config in definitions():
		var person:=WorldPerson.new()
		person.configure(config,game)
		for i in person.route.size(): person.route[i]=walkable_position(person.route[i])
		person.home=person.route[0]
		person.position=person.route[person.route_index]
		person.route_index=(person.route_index+1)%person.route.size()
		person.activity="停驻交易" if person.caravan else "驻足歇息"
		# Establish initial separation without moving existing people later.
		for attempt in 16:
			var occupied:=false
			for other in actors.values():
				if person.position.distance_to(other.position)<28: occupied=true
			if not occupied: break
			person.position=walkable_position(person.position+Vector2.from_angle(attempt*2.4)*48)
		person.trail=PackedVector2Array([person.position])
		game.add_child(person)
		actors[person.resident_id]=person
		person.visible=game.world.on_surface()
	initialized=true

func clear() -> void:
	for person in actors.values():
		if is_instance_valid(person): person.queue_free()
	actors.clear()
	initialized=false

func rebuild_navigation() -> void:
	navigation.region=Rect2i(0,0,GameData.MAP_W,GameData.MAP_H)
	navigation.cell_size=Vector2(32,32)
	navigation.offset=Vector2(16,16)
	navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation.update()
	for y in GameData.MAP_H:
		for x in GameData.MAP_W:
			var point:=Vector2i(x,y)
			var index:=y*GameData.MAP_W+x
			navigation.set_point_solid(point,game.world.is_solid_tile(game.world.map[index]))
			navigation.set_point_weight_scale(point,1.0 if game.world.road_tiles.has(index) else 2.8)
	for h in World.HOUSE_DATA: refresh_navigation(Rect2(h.pos-Vector2(70,56),Vector2(140,88)))
	for mountain in World.MOUNTAINS: refresh_navigation(World.mountain_footprint(mountain).grow(16))
	refresh_navigation(Rect2(GameData.BONFIRE-Vector2(32,32),Vector2(64,64)))
	refresh_navigation(Rect2(GameData.FURNACE-Vector2(32,32),Vector2(64,64)))

func outdoor_blocked(pos: Vector2, radius: float = 12.0) -> bool:
	for offset in [Vector2(-radius,-radius),Vector2(radius,-radius),Vector2(-radius,radius),Vector2(radius,radius),Vector2.ZERO]:
		var p:Vector2=pos+offset
		if game.world.is_solid_tile(game.world.tile_at(floori(p.x/32),floori(p.y/32))): return true
	for house in World.HOUSE_DATA:
		if not game.world.destruction.broken("house:"+house.id) and Rect2(house.pos+Vector2(-54,-40),Vector2(108,40)).grow(radius).has_point(pos): return true
	for i in World.MOUNTAINS.size():
		if not game.world.destruction.broken("mountain:"+str(i)) and World.mountain_footprint(World.MOUNTAINS[i]).grow(radius).has_point(pos): return true
	if not game.world.destruction.broken("bonfire") and pos.distance_to(GameData.BONFIRE)<14+radius: return true
	if not game.world.destruction.broken("furnace") and pos.distance_to(GameData.FURNACE)<16+radius: return true
	return false

func refresh_navigation(rect: Rect2) -> void:
	if navigation.is_dirty(): return
	for y in range(maxi(0,floori(rect.position.y/32)),mini(GameData.MAP_H,ceili(rect.end.y/32)+1)):
		for x in range(maxi(0,floori(rect.position.x/32)),mini(GameData.MAP_W,ceili(rect.end.x/32)+1)):
			navigation.set_point_solid(Vector2i(x,y),outdoor_blocked(Vector2(x*32+16,y*32+16)))

func walkable_position(pos: Vector2) -> Vector2:
	var base:=Vector2i(floori(pos.x/32),floori(pos.y/32))
	for ring in range(0,13):
		for y in range(-ring,ring+1):
			for x in range(-ring,ring+1):
				if ring>0 and absi(x)!=ring and absi(y)!=ring: continue
				var point:=base+Vector2i(x,y)
				if navigation.is_in_boundsv(point) and not navigation.is_point_solid(point): return Vector2(point)*32+Vector2(16,16)
	return pos

func set_visible(value: bool) -> void:
	for person in actors.values(): person.visible=value and game.fog.can_see(person.position)

func tick(delta: float) -> void:
	if not initialized or not game.running or game.paused or game.player.dead or not game.world.on_surface(): return
	day_clock=fmod(day_clock+delta,1440.0)
	restock_left=maxf(0,restock_left-delta)
	path_budget=3
	for person:WorldPerson in actors.values():
		person.player_pos=game.player.position
		var previous:=person.position
		person.replan_left=maxf(0,person.replan_left-delta)
		person.attack_timer=maxf(0,person.attack_timer-delta)
		person.flee_left=maxf(0,person.flee_left-delta)
		person.scan_left-=delta
		if not person.dead:
			if person.scan_left<=0:
				person.scan_left=0.5
				find_target(person)
			update_person(person,delta)
		person.animation.advance(delta,person.position.distance_squared_to(previous)>0.01,person.facing)
		person.hurt_timer=maxf(0,person.hurt_timer-delta)
		if person.caravan:
			# Fixed distance samples keep queue spacing independent of frame duration.
			while person.position.distance_to(person.trail[-1])>=16:
				person.trail.append(person.trail[-1].move_toward(person.position,16))
				if person.trail.size()>120: person.trail.remove_at(0)

func peaceful_area(pos: Vector2) -> bool:
	return game.wildlife.is_safe_area(pos)

func clear_line(from: Vector2, to: Vector2) -> bool:
	var steps:=maxi(1,ceili(from.distance_to(to)/12))
	for i in range(1,steps):
		if outdoor_blocked(from.lerp(to,float(i)/steps),2): return false
	return true

func valid_target(person: WorldPerson, candidate: Node2D) -> bool:
	if not is_instance_valid(candidate) or candidate.dead: return false
	if person.role=="bandit" and (peaceful_area(candidate.position) or person.home.distance_to(candidate.position)>540): return false
	return person.position.distance_to(candidate.position)<360

func find_target(person: WorldPerson) -> void:
	if valid_target(person,person.target): return
	person.target=null
	if person.hostile and not game.player.dead and person.position.distance_to(game.player.position)<210*game.player.utility_gu.detection_multiplier() and (person.role!="bandit" or not peaceful_area(game.player.position)) and clear_line(person.position,game.player.position):
		person.target=game.player
		return
	# Named people defend themselves; do not make Fang Yuan or Bai Ning Bing volunteer escorts.
	if person.role=="cultivator": return
	var best:=230.0
	for other:WorldPerson in actors.values():
		if other==person or other.dead: continue
		var opposed:=other.role!="bandit" if person.role=="bandit" else other.role=="bandit"
		if not opposed or not valid_target(person,other): continue
		var distance:=person.position.distance_to(other.position)
		if distance<best and clear_line(person.position,other.position):
			person.target=other
			best=distance

func can_fight(person: WorldPerson) -> bool:
	return person.role in ["guard","escort","bandit","cultivator"] or (person.hostile and person.social.theft_retaliation)

func update_person(person: WorldPerson, delta: float) -> void:
	if float(game.player.utility_gu.person_status.get(person.resident_id,{}).get("frozen",0))>0:
		person.activity="冻结中"
		person.strike_left=0
		return
	if person.hurt_timer>0:
		person.strike_left=0
		person.activity="受伤后退"
		return
	if person.strike_left>0:
		var before:=person.strike_left
		person.strike_left=maxf(0,person.strike_left-delta)
		if before>0.27 and person.strike_left<=0.27: resolve_strike(person)
		return
	if valid_target(person,person.target):
		if not can_fight(person):
			person.activity="避险逃离"
			person.flee_left=4
			person.attacker_position=person.target.position
			flee(person,delta)
		else:
			person.activity="因失窃反击" if person.social.theft_retaliation and person.target==game.player else ("近身自卫" if person.role=="cultivator" else ("劫道追击" if person.role=="bandit" else "迎敌护卫"))
			var offset:Vector2=person.target.position-person.position
			person.facing=offset.angle()
			if offset.length()>42 or not clear_line(person.position,person.target.position): navigate(person,person.target.position,delta,1.25)
			elif person.attack_timer<=0:
				person.strike_left=0.55
				person.attack_timer=1.3
				person.attack_target=person.target
				person.attack_direction=offset.normalized()
				person.animation.play("strike",person.facing,0.55)
		return
	person.target=null
	if person.flee_left>0 and not can_fight(person):
		person.activity="避险逃离"
		flee(person,delta)
		return
	if person.caravan:
		var leader:=caravan_leader()
		if leader!=null and leader!=person:
			person.route_index=leader.route_index
			person.wait_left=leader.wait_left
			person.activity="随队护送" if person.role=="escort" else "挑担随行"
			var order:=caravan_ids.find(person.resident_id)
			if leader.trail.size()<=order*4 and person.position.distance_to(leader.position)<250: return
			var follow:Vector2=leader.trail[maxi(0,leader.trail.size()-1-order*4)]
			if person.position.distance_to(follow)>24: navigate(person,follow,delta,1.25 if person.position.distance_to(leader.position)>160 else 1.0)
			return
		for member:WorldPerson in actors.values():
			if member.caravan and not member.dead and member.position.distance_to(person.position)>280:
				person.activity="等候队伍"
				return
	if person.role in ["villager","gatherer"] and (day_clock<360 or day_clock>=1080):
		person.activity="归家歇息"
		navigate(person,person.home,delta)
		return
	if person.wait_left>0:
		person.wait_left=maxf(0,person.wait_left-delta)
		person.activity="停驻交易" if person.caravan else ("采集歇脚" if person.role=="gatherer" else ("驻足思量" if person.role=="cultivator" else "驻足歇息"))
		return
	person.activity="巡寨" if person.role=="guard" else ("结队赶路" if person.caravan else ("路边游荡" if person.role=="bandit" else "日常行走"))
	if navigate(person,person.route[person.route_index],delta):
		if not person.route_names.is_empty(): person.social.record(person,"journey","抵达%s。" % person.route_names[person.route_index])
		if person.caravan and person.route_index in [0,3,5] and restock_left<=0 and not actors.caravan_merchant.dead:
			for item in GOODS: stock[item]=maxi(int(stock.get(item,0)),int(GOODS[item].cap))
			restock_left=600
		person.route_index=(person.route_index+1)%person.route.size()
		person.wait_left=18.0 if person.caravan else (12.0 if person.role=="cultivator" else (10.0 if person.role=="gatherer" else (2.0 if person.role in ["guard","bandit"] else 6.0)))
		person.path_goal=Vector2.INF

func flee(person: WorldPerson, delta: float) -> void:
	var away:Vector2=(person.position-person.attacker_position).normalized()
	if away==Vector2.ZERO: away=Vector2.RIGHT
	for turn in [0.0,0.7,-0.7,1.4,-1.4]:
		var destination:=person.position+away.rotated(turn)*96
		if not outdoor_blocked(destination):
			navigate(person,destination,delta,1.45)
			return

func navigate(person: WorldPerson, destination: Vector2, delta: float, multiplier: float = 1.0) -> bool:
	var goal:=walkable_position(destination)
	if person.position.distance_to(goal)<6: return true
	if (person.path.is_empty() or person.path_goal.distance_to(goal)>40) and person.replan_left<=0 and path_budget>0:
		path_budget-=1
		var start:=Vector2i(walkable_position(person.position)/32)
		var end:=Vector2i(goal/32)
		person.path=navigation.get_point_path(start,end)
		person.path_index=0
		person.path_goal=goal
		person.replan_left=0.6
	if person.path.is_empty():
		person.activity="等候通路"
		return false
	var remaining:float=minf(delta,0.25)*person.speed*multiplier*game.player.utility_gu.person_speed(person)
	while remaining>0 and person.path_index<person.path.size():
		var offset:Vector2=person.path[person.path_index]-person.position
		if offset.length()<2:
			person.path_index+=1
			continue
		person.facing=offset.angle()
		var step:=offset.normalized()*minf(remaining,minf(offset.length(),6))
		var before:=person.position
		game.world.move_body(person,step.x,step.y,person.radius)
		remaining-=step.length()
		if before.distance_squared_to(person.position)<0.01:
			person.blocked_time+=delta
			if person.blocked_time>0.8:
				refresh_navigation(Rect2(person.position-Vector2(96,96),Vector2(192,192)))
				person.path.clear()
				person.replan_left=0.5
				person.blocked_time=0
			return false
		person.blocked_time=0
	if person.path_index>=person.path.size(): person.path.clear()
	return person.position.distance_to(goal)<6

func resolve_strike(person: WorldPerson) -> void:
	var victim:=person.attack_target
	if not valid_target(person,victim) or not game.world.on_surface() or not game.world.attack_clear(person.position,victim.position): return
	var offset:Vector2=victim.position-person.position
	if offset.length()>55 or (offset.length()>1 and offset.normalized().dot(person.attack_direction)<0.4) or not clear_line(person.position,victim.position): return
	if victim==game.player: game.damage_player(person.damage,"none")
	elif victim is WorldPerson: victim.receive_hit(person.damage,person)

func alert_assault(victim: WorldPerson) -> void:
	if victim.role=="bandit": return
	for guard:WorldPerson in actors.values():
		if guard.dead or not guard.role in ["guard","escort"]: continue
		if (guard.role=="guard" and guard.position.distance_to(victim.position)<300) or (guard.caravan and victim.caravan):
			guard.social.player_assault(guard,"因你袭击%s而与你敌对。" % victim.npc_name)
			guard.hostile=true
			guard.target=game.player

func caravan_leader() -> WorldPerson:
	for id in caravan_ids:
		if actors.has(id) and not actors[id].dead: return actors[id]
	return null

func person_died(person: WorldPerson) -> void:
	if not person.caravan: return
	# The next surviving member keeps the journey's destination, not its old start.
	for id in caravan_ids:
		var member:WorldPerson=actors.get(id)
		if member==person: break
		if member!=null and not member.dead: return
	var successor:=caravan_leader()
	if successor==null: return
	successor.route_index=person.route_index
	successor.wait_left=person.wait_left
	successor.path.clear()
	successor.path_goal=Vector2.INF

func nearest_speaker() -> WorldPerson:
	var nearest:WorldPerson=null
	var distance:=80.0
	for person:WorldPerson in actors.values():
		if person.dead or person.hostile: continue
		var d:float=game.player.position.distance_to(person.position)
		if d<distance:
			distance=d
			nearest=person
	return nearest

func description(person: WorldPerson) -> String:
	if CanonPeople.has(person.resident_id):
		return CanonPeople.PEOPLE[person.resident_id].summary+"\n当前："+person.activity+"\n下一站："+person.route_names[person.route_index]
	var text:String={"villager":"白日在住处与寨中街巷之间走动，夜间回到住处附近歇息。","guard":"沿寨中道路巡逻，遇到强盗会迎敌，附近有人遭你袭击也会出手。","gatherer":"在住处、采集地与歇脚棚之间往返，夜间回程。采集是日常活动表现，不会替玩家领取材料。","traveler":"沿山道在几个落脚点之间步行游历。","merchant":"带着挑夫和镖师往返三寨，途中停驻可交易。货物有限，到达寨中且距上次补货至少十分钟才补满。","porter":"沿队伍走过的路线挑担随行，遇袭时避险。","escort":"跟随商队护送，遇到强盗会迎击。","bandit":"在寨外固定路段游荡，袭击附近行人；不会进入山寨或营地追杀。"}.get(person.role,"")
	text+="\n当前："+person.activity
	if not person.route_names.is_empty(): text+="\n下一站："+person.route_names[person.route_index]
	return text

func can_trade(person: WorldPerson) -> bool:
	return is_instance_valid(person) and person.role=="merchant" and PersonExchange.blocker(game,person)==""

func buy(person: WorldPerson, item: String) -> bool:
	if not can_trade(person) or not GOODS.has(item):
		game.last_action_message="行商不在近处，或正处于危险中，无法交易。"
		return false
	return PersonExchange.trade(game,person,item,1,true)

func save_data() -> Dictionary:
	var people:Dictionary={}
	for id in actors: people[id]=actors[id].save_data()
	return {"clock":day_clock,"restock":restock_left,"people":people}

func load_data(raw: Variant) -> void:
	clear()
	day_clock=480
	restock_left=600
	initialize()
	if not raw is Dictionary: return
	day_clock=fposmod(float(raw.get("clock",480)),1440)
	restock_left=clampf(float(raw.get("restock",600)),0,600)
	var people:Variant=raw.get("people",{})
	if people is Dictionary:
		for id in actors:
			if people.get(id) is Dictionary:
				actors[id].load_data(people[id])
				if outdoor_blocked(actors[id].position): actors[id].position=walkable_position(actors[id].position)
	# Migrate the former shared caravan stock only when personal inventory is absent.
	var merchant_data:Dictionary=people.get("caravan_merchant",{}) if people is Dictionary else {}
	var goods:Variant=raw.get("stock")
	if not merchant_data.has("possessions") and goods is Dictionary:
		for item in GOODS:
			var count:=clampi(int(goods.get(item,GOODS[item].cap)),0,int(GOODS[item].cap))
			if count>0: stock[item]=count
			else: stock.erase(item)
	set_visible(game.world.on_surface())
