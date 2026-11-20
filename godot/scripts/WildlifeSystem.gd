class_name WildlifeSystem
extends RefCounted

# All population/growth/cultivation values below are sandbox design parameters.
const SPECIES := {
	"rabbit":{"radius":10.0,"speed":105.0,"mature":360.0,"temper":"timid"},
	"deer":{"radius":15.0,"speed":112.0,"mature":900.0,"temper":"timid"},
	"wolf":{"radius":16.0,"speed":92.0,"mature":900.0,"temper":"aggressive"},
	"bear":{"radius":23.0,"speed":63.0,"mature":1200.0,"temper":"territorial"},
	"boar":{"radius":18.0,"speed":80.0,"mature":1000.0,"temper":"territorial"},
	"fox":{"radius":12.0,"speed":115.0,"mature":600.0,"temper":"timid"},
	"pheasant":{"radius":10.0,"speed":100.0,"mature":420.0,"temper":"timid"},
	"green_wolf":{"radius":23.0,"speed":88.0,"mature":1200.0,"temper":"aggressive"},
	"iron_bear":{"radius":28.0,"speed":60.0,"mature":1500.0,"temper":"territorial"},
}
const HABITATS := [
	{"id":"bamboo_hare","name":"山林兔窝","species":"rabbit","tile":Vector2i(41,24),"radius":180.0,"capacity":4,"cooldown":180.0},
	{"id":"east_deer","name":"东麓鹿坪","species":"deer","tile":Vector2i(90,31),"radius":210.0,"capacity":3,"cooldown":300.0},
	{"id":"ridge_wolf","name":"高岭狼穴","species":"wolf","tile":Vector2i(123,24),"radius":180.0,"capacity":3,"cooldown":360.0},
	{"id":"south_bear","name":"南林熊洞","species":"bear","tile":Vector2i(61,77),"radius":170.0,"capacity":2,"cooldown":480.0},
	{"id":"south_boar","name":"竹坡野猪林","species":"boar","tile":Vector2i(37,71),"radius":190.0,"capacity":3,"cooldown":300.0},
	{"id":"valley_fox","name":"溪谷狐穴","species":"fox","tile":Vector2i(92,57),"radius":170.0,"capacity":3,"cooldown":300.0},
	{"id":"south_pheasant","name":"南麓雉草甸","species":"pheasant","tile":Vector2i(43,98),"radius":180.0,"capacity":3,"cooldown":240.0},
	{"id":"spirit_wolf","name":"远岭青狼巢","species":"green_wolf","tile":Vector2i(146,30),"radius":170.0,"capacity":2,"cooldown":720.0},
	{"id":"iron_den","name":"石滩铁背巢","species":"iron_bear","tile":Vector2i(138,91),"radius":180.0,"capacity":2,"cooldown":900.0},
	{"id":"pine_deer","name":"赤松鹿林","species":"deer","tile":Vector2i(206,41),"radius":220.0,"capacity":3,"cooldown":300.0},
	{"id":"reed_boar","name":"芦岸野猪林","species":"boar","tile":Vector2i(74,141),"radius":210.0,"capacity":3,"cooldown":300.0},
	{"id":"east_fox","name":"东岭狐穴","species":"fox","tile":Vector2i(172,73),"radius":180.0,"capacity":2,"cooldown":300.0},
	{"id":"deep_iron","name":"荒山铁背巢","species":"iron_bear","tile":Vector2i(205,155),"radius":210.0,"capacity":2,"cooldown":900.0},
]
const CULTIVATION_THRESHOLDS := [180.0,480.0,900.0]
const CULTIVATION_NAMES := ["初醒","凝息","强健","精壮"]
const SAFE_DISTANCE := 640.0

var game: Node
var slots := {}
var actors := {}
var fading_actors: Array[Enemy] = []
var initialized := false
var scan_time := 0.0
var rng := RandomNumberGenerator.new()

static func species_data(id: String) -> Dictionary:
	if not SPECIES.has(id): return {}
	var result:Dictionary=(MonsterSystem.WILDLIFE[id] if MonsterSystem.WILDLIFE.has(id) else AnimalSystem.ANIMALS[id]).duplicate(true)
	result.merge(SPECIES[id])
	result["id"]=id
	result["is_monster"]=MonsterSystem.WILDLIFE.has(id)
	return result

static func center(habitat: Dictionary) -> Vector2:
	return Vector2(habitat.tile)*GameData.TILE+Vector2(16,16)

static func habitat_for(id: String) -> Dictionary:
	for habitat in HABITATS:
		if habitat.id==id: return habitat
	return {}

func setup(main: Node) -> void:
	game=main
	rng.randomize()

func clear() -> void:
	for actor in fading_actors:
		if is_instance_valid(actor): actor.queue_free()
	fading_actors.clear()
	for actor in actors.values():
		if is_instance_valid(actor):
			game.enemies.erase(actor)
			actor.queue_free()
	actors.clear()
	slots.clear()
	initialized=false
	scan_time=0.0
	game.target_hint=null
	game.player.capture_target=null

func initialize() -> void:
	if initialized: return
	initialized=true
	for habitat in HABITATS:
		for index in int(habitat.capacity):
			var key:String=habitat.id+":"+str(index)
			slots[key]={"cooldown":0.0,"generation":0,"initial":true}
	try_spawns()

func is_safe_area(pos: Vector2) -> bool:
	if game.world.zone_at(pos) in ["village","bai","xiong"]: return true
	if pos.distance_to(GameData.BONFIRE)<320: return true
	for house in World.HOUSE_DATA:
		if pos.distance_to(house.pos)<180: return true
	for site in World.EXPLORATION_SITES:
		if site.kind=="camp" and pos.distance_to(Vector2(site.pos)*32+Vector2(16,16))<200: return true
	return false

func spawn_allowed(pos: Vector2, habitat: Dictionary) -> bool:
	if not game.world.on_surface(): return false
	if pos.distance_to(center(habitat))>float(habitat.radius): return false
	var radius:float=SPECIES[habitat.species].radius
	# Check every covered tile: corner-only sampling can skip a narrow obstacle.
	if game.world.collides(pos.x,pos.y,radius+3): return false
	for y in range(floori((pos.y-radius-3)/32),floori((pos.y+radius+3)/32)+1):
		for x in range(floori((pos.x-radius-3)/32),floori((pos.x+radius+3)/32)+1):
			if game.world.is_solid_tile(game.world.tile_at(x,y)): return false
	if is_safe_area(pos): return false
	if pos.distance_to(game.player.position)<maxf(SAFE_DISTANCE,game.fog.radius_world()+128): return false
	# Check the whole window as well as fog; zooming out must never expose a spawn.
	var viewport:Vector2=game.get_viewport_rect().size/game.zoom_level
	var camera_center:Vector2=game.camera.get_screen_center_position()
	if Rect2(camera_center-viewport*0.5,viewport).grow(radius*3+64).has_point(pos): return false
	for other in game.enemies:
		if is_instance_valid(other) and not other.dead and pos.distance_to(other.position)<radius+other.radius+22: return false
	return true

func try_spawns() -> void:
	if not initialized or not game.world.on_surface(): return
	for habitat in HABITATS:
		for index in int(habitat.capacity):
			var key:String=habitat.id+":"+str(index)
			if actors.has(key) or float(slots[key].cooldown)>0: continue
			for attempt in 64:
				var pos:=center(habitat)+Vector2.from_angle(rng.randf()*TAU)*sqrt(rng.randf())*float(habitat.radius)
				if not spawn_allowed(pos,habitat): continue
				var age:=0.0
				if bool(slots[key].initial):
					var phases:Array=[0.35,1.0] if MonsterSystem.WILDLIFE.has(habitat.species) else [0.2,0.65,1.0]
					age=float(SPECIES[habitat.species].mature)*float(phases[index%phases.size()])
				create_actor(key,habitat,pos,age)
				slots[key].initial=false
				break

func create_actor(key: String, habitat: Dictionary, pos: Vector2, age: float) -> Enemy:
	var actor:Enemy=game._make_host(habitat.species,pos)
	actor.wildlife_slot=key
	actor.habitat_id=habitat.id
	actor.age_seconds=age
	actor.player_pos=game.player.position
	actor.refresh_growth()
	game.enemies_root.add_child(actor)
	game.enemies.append(actor)
	actors[key]=actor
	return actor

func tick(delta: float) -> void:
	if not initialized or not game.running or game.paused or game.player.dead or not game.world.on_surface(): return
	for i in range(fading_actors.size()-1,-1,-1):
		var corpse:=fading_actors[i]
		if not is_instance_valid(corpse):
			fading_actors.remove_at(i)
			continue
		corpse.wildlife_animation.advance(delta)
		corpse.wildlife_animation.sync_pose(corpse.radius)
		if corpse.wildlife_animation.elapsed>=WildlifeAnimation.DEATH_SECONDS:
			corpse.queue_free()
			fading_actors.remove_at(i)
	for key in slots:
		if not actors.has(key): slots[key].cooldown=maxf(0,float(slots[key].cooldown)-delta)
	scan_time+=delta
	if scan_time>=2.0:
		scan_time=0.0
		try_spawns()

func died(actor: Enemy) -> void:
	var key:=actor.wildlife_slot
	if not slots.has(key): return
	actors.erase(key)
	slots[key].cooldown=float(habitat_for(actor.habitat_id).cooldown)
	slots[key].generation=int(slots[key].generation)+1
	slots[key].initial=false

func retire(actor: Enemy) -> void:
	if actor.wildlife_animation==null:
		actor.queue_free()
		return
	actor.wildlife_animation.play_death()
	actor.wildlife_animation.sync_pose(actor.radius)
	fading_actors.append(actor)

func begin_attack(actor: Enemy) -> void:
	if actor.dead or actor.wildlife_animation==null or game.player.dead: return
	if actor.wildlife_animation.play_attack(game.player.position-actor.position):
		actor.cultivating=false
		actor.calm_seconds=0
		actor.state="attack"
		actor.atk_cd=maxf(actor.atk_cd,actor.wildlife_animation.duration+0.55)

func resolve_attack(actor: Enemy) -> void:
	if not game.world.on_surface() or not game.world.attack_clear(actor.position,game.player.position): return
	if actor.dead or game.player.dead or is_safe_area(game.player.position): return
	var offset:Vector2=game.player.position-actor.position
	if offset.length()>actor.radius+game.player.radius+22: return
	if offset.length()>1 and offset.normalized().dot(actor.wildlife_animation.attack_direction)<0.35: return
	# An attack cannot reach through a tree, wall or rock during the wind-up.
	var steps:=maxi(1,ceili(offset.length()/8))
	for i in range(1,steps):
		var point:Vector2=actor.position+offset*float(i)/steps
		if game.world.collides(point.x,point.y,2): return
	game.damage_player(actor.atk+game._rng.randf_range(0,3),actor.element)

func animate_actor(actor: Enemy, delta: float) -> void:
	var animation:=actor.wildlife_animation
	var old_position:=actor.position
	actor._t+=delta
	if actor.stun>0 and animation.action=="attack": animation.play_hurt(-animation.attack_direction)
	if animation.advance(delta): resolve_attack(actor)
	if not animation.locked() and actor.stun<=0: update_ai(actor,delta)
	animation.locomotion(delta,actor.position-old_position,actor.radius,actor.spd,actor.dir,actor.cultivating)
	# Action clocks, AI and hit resolution keep running outside sight. Only
	# uploading the visual pose is unnecessary while the creature is hidden.
	if actor.is_visible_in_tree(): animation.sync_pose(actor.radius)

func tick_life(actor: Enemy, delta: float) -> void:
	if actor.dead or not SPECIES.has(actor.kind): return
	actor.age_seconds+=delta
	var recently_hurt:=actor.threat_time>0
	actor.threat_time=maxf(0,actor.threat_time-delta)
	var habitat:=habitat_for(actor.habitat_id)
	var quiet:=not habitat.is_empty() and actor.position.distance_to(center(habitat))<float(habitat.radius)*0.85
	quiet=quiet and actor.position.distance_to(game.player.position)>300 and actor.hp>=actor.max_hp*0.7 and not recently_hurt and actor.stun<=0
	if actor.wildlife_animation!=null and actor.wildlife_animation.locked(): quiet=false
	for value in actor.status.values():
		if float(value)>0: quiet=false
	actor.calm_seconds=actor.calm_seconds+delta if quiet else 0.0
	actor.cultivating=actor.is_monster and actor.growth_ratio()>=1.0 and actor.calm_seconds>=8.0 and actor.cultivation_seconds<900.0
	if actor.cultivating:
		var adult_seconds:=clampf(actor.age_seconds-float(actor.data.mature),0,delta)
		var settled_seconds:=clampf(actor.calm_seconds-8.0,0,delta)
		actor.cultivation_seconds=minf(900.0,actor.cultivation_seconds+minf(adult_seconds,settled_seconds))
	actor.refresh_growth()

func move_actor(actor: Enemy, velocity: Vector2, delta: float) -> void:
	var next:=actor.position+velocity*delta
	# Creatures walk and collide normally; no distance-based deletion or teleporting.
	if is_safe_area(next):
		actor.dir+=PI*0.5
		return
	game.world.move_body(actor,velocity.x*delta,velocity.y*delta,actor.radius)

func update_ai(actor: Enemy, delta: float) -> void:
	var habitat:=habitat_for(actor.habitat_id)
	var home:Vector2=center(habitat)
	var distance:=actor.position.distance_to(game.player.position)
	var temper:String=SPECIES[actor.kind].temper
	var notice:float=game.player.utility_gu.detection_multiplier()
	if actor.state in ["chase","flee"] or actor.threat_time>0: notice=1.0
	var threatened:bool=not game.player.dead and (distance<230*notice or actor.threat_time>0)
	var fleeing:=temper=="timid" or actor.growth_ratio()<0.5
	var speed:=actor.spd
	speed*=UtilityGuEffects.status_speed(actor.status)
	if threatened and fleeing:
		actor.state="flee"
		var away:Vector2=(actor.position-game.player.position).normalized()
		if actor.position.distance_to(home)>float(habitat.radius)*1.8:
			away=(away+(home-actor.position).normalized()*1.5).normalized()
		actor.dir=away.angle()
		move_actor(actor,away*speed*1.1,delta)
		return
	var pursuing:bool=not fleeing and not game.player.dead and not is_safe_area(game.player.position)
	pursuing=pursuing and (actor.threat_time>0 or distance<(230 if temper=="aggressive" else 125)*notice)
	pursuing=pursuing and game.player.position.distance_to(home)<float(habitat.radius)+260
	if pursuing:
		actor.state="chase"
		actor.cultivating=false
		actor.calm_seconds=0
		actor.dir=(game.player.position-actor.position).angle()
		if distance>actor.radius+game.player.radius+14:
			move_actor(actor,Vector2.from_angle(actor.dir)*speed,delta)
		elif actor.atk_cd<=0:
			actor.atk_cd=1.7
			game._enemy_attack(actor)
		return
	if actor.cultivating:
		actor.state="cultivate"
		actor.moving=false
		return
	if actor.position.distance_to(home)>float(habitat.radius)*0.7:
		actor.state="return"
		actor.dir=(home-actor.position).angle()
		move_actor(actor,Vector2.from_angle(actor.dir)*speed*0.6,delta)
		return
	actor.state="wander"
	actor.wander_t-=delta
	if actor.wander_t<=0:
		actor.wander_t=rng.randf_range(1.5,4.0)
		actor.dir=rng.randf()*TAU
		actor.moving=rng.randf()<0.55
	if actor.moving: move_actor(actor,Vector2.from_angle(actor.dir)*speed*0.3,delta)

func save_data() -> Dictionary:
	var result:Dictionary={"slots":{}}
	for key in slots:
		var row:Dictionary=slots[key].duplicate(true)
		if actors.has(key) and is_instance_valid(actors[key]) and not actors[key].dead:
			var actor:Enemy=actors[key]
			row["actor"]={"position":[actor.position.x,actor.position.y],"age":actor.age_seconds,"cultivation":actor.cultivation_seconds,"hp":actor.hp,"status":actor.status.duplicate(),"threat":actor.threat_time,"dir":actor.dir}
		result.slots[key]=row
	return result

func load_data(raw: Variant) -> void:
	clear()
	if not raw is Dictionary or not raw.get("slots") is Dictionary:
		initialize()
		return
	initialized=true
	for habitat in HABITATS:
		for index in int(habitat.capacity):
			var key:String=habitat.id+":"+str(index)
			var saved:Variant=raw.slots.get(key,{"initial":true,"cooldown":0.0})
			if not saved is Dictionary: saved={}
			slots[key]={"cooldown":clampf(float(saved.get("cooldown",habitat.cooldown)),0,habitat.cooldown),"generation":maxi(0,int(saved.get("generation",0))),"initial":bool(saved.get("initial",false))}
			var record:Variant=saved.get("actor")
			if not record is Dictionary: continue
			var p:Variant=record.get("position",[])
			if not p is Array or p.size()!=2 or float(record.get("hp",0))<=0: continue
			var pos:=Vector2(float(p[0]),float(p[1]))
			if not pos.is_finite(): pos=center(habitat)
			var actor:=create_actor(key,habitat,pos,clampf(float(record.get("age",0)),0,8640000))
			actor.cultivation_seconds=clampf(float(record.get("cultivation",0)),0,900)
			actor.refresh_growth()
			actor.hp=clampf(float(record.get("hp",actor.max_hp)),0.01,actor.max_hp)
			actor.threat_time=clampf(float(record.get("threat",0)),0,15)
			actor.dir=float(record.get("dir",0))
			if record.get("status") is Dictionary:
				for status in actor.status: actor.status[status]=clampf(float(record.status.get(status,0)),0,60)
