class_name WildlifeAnimationTests
extends RefCounted

var checked:=0
var failures:Array[String]=[]
var game:Node

func expect(value: bool, label: String) -> void:
	checked+=1
	if not value:
		failures.append(label)
		print("WILDLIFEANIMTEST FAIL "+label)

func pursuit_lane(actor: Enemy) -> Dictionary:
	var home:=WildlifeSystem.center(WildlifeSystem.habitat_for(actor.habitat_id))
	for y in range(-4,5):
		for x in range(-4,5):
			var origin:=home+Vector2(x,y)*GameData.TILE
			for direction in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
				var clear:=true
				for step in 23:
					var point:Vector2=origin+direction*step*8
					if game.world.collides(point.x,point.y,actor.radius) or game.wildlife.is_safe_area(point):
						clear=false
						break
				if clear: return {"origin":origin,"direction":direction}
	return {}

func run(main: Node) -> void:
	game=main
	game.set_process(false)
	game.start_game()
	CanonTests.prepare_cultivator(game)
	for actor in game.enemies:
		expect(actor.wildlife_animation!=null and is_instance_valid(actor.wildlife_animation.rig),"main-scene creature has an animated rig "+actor.kind)
		if actor.wildlife_animation==null: continue
		expect(actor.wildlife_animation.rig.texture==WildlifeArt.texture(actor.kind),"rig preserves species illustration "+actor.kind)
	var wolf:Enemy=game.wildlife.actors["ridge_wolf:1"]
	var habitat:=WildlifeSystem.habitat_for(wolf.habitat_id)
	wolf.position=WildlifeSystem.center(habitat)
	wolf.age_seconds=float(wolf.data.mature)
	wolf.refresh_growth()
	game.player.position=wolf.position+Vector2(42,0)
	game.player.iframes=0
	game.player.jade_guard=false
	game.player.shield=0
	game.player.hp=game.player.max_hp
	wolf.atk_cd=10
	var hp:float=game.player.hp
	game._enemy_attack(wolf)
	expect(wolf.wildlife_animation.action=="attack" and game.player.hp==hp,"attack starts with visible wind-up and no immediate damage")
	game.update_enemy(wolf,0.1)
	expect(game.player.hp==hp,"wind-up leaves time to evade")
	game.update_enemy(wolf,0.2)
	expect(game.player.hp<hp,"strike crossing applies the actual melee hit")
	var after_hit:float=game.player.hp
	game.player.iframes=0
	game.update_enemy(wolf,0.1)
	expect(game.player.hp==after_hit,"one swing cannot hit twice")
	game.update_enemy(wolf,1)
	game._enemy_attack(wolf)
	game.player.position+=Vector2(160,0)
	game.update_enemy(wolf,0.3)
	expect(game.player.hp==after_hit,"leaving reach during wind-up avoids the attack")
	game.update_enemy(wolf,1)
	game.player.position=wolf.position+Vector2(42,0)
	wolf.atk_cd=10
	game._enemy_attack(wolf)
	game.player.position=wolf.position-Vector2(42,0)
	game.update_enemy(wolf,0.3)
	expect(game.player.hp==after_hit,"moving behind the locked attack direction avoids a hit")
	game.update_enemy(wolf,1)
	game.player.position=wolf.position+Vector2(42,0)
	game.player.iframes=0
	game._enemy_attack(wolf)
	var obstruction:Vector2i=Vector2i((wolf.position+Vector2(21,0))/32)
	var tile_index:int=game.world._idx(obstruction.x,obstruction.y)
	var previous_tile:int=game.world.map[tile_index]
	game.world.map[tile_index]=GameData.T_ROCK
	game.update_enemy(wolf,0.3)
	expect(game.player.hp==after_hit,"obstruction across the strike path prevents damage")
	game.world.map[tile_index]=previous_tile
	game.update_enemy(wolf,1)
	game.player.position=wolf.position+Vector2(42,0)
	game._enemy_attack(wolf)
	game.damage_enemy(wolf,1,"none")
	expect(wolf.wildlife_animation.action=="hurt","actual damage plays recoil and cancels the pending strike")
	game.update_enemy(wolf,0.23)
	expect(game.player.hp==after_hit,"interrupted attack cannot deal delayed damage")
	game.update_enemy(wolf,0.1)
	game._enemy_attack(wolf)
	wolf.stun=1.0
	game.update_enemy(wolf,0.3)
	expect(game.player.hp==after_hit,"stun interrupts wind-up before damage")
	wolf.stun=0
	game.update_enemy(wolf,1)
	game._enemy_attack(wolf)
	wolf.stun=0.01
	game.update_enemy(wolf,0.3)
	expect(game.player.hp==after_hit,"stun ending within this tick still cancels the pending strike")
	var animation:=wolf.wildlife_animation
	animation.action="idle"
	game._enemy_attack(wolf)
	var elapsed:=animation.elapsed
	game.paused=true
	game._process(1)
	expect(animation.elapsed==elapsed and game.player.hp==after_hit,"menu pause freezes wind-up and prevents hidden damage")
	game.paused=false
	game.enter_house(World.HOUSE_DATA[2])
	game._process(0.1)
	expect(animation.elapsed==elapsed,"interior freezes outdoor attack animation")
	game.exit_house(false)
	game.paused=false
	animation.action="idle"
	# Earlier attack checks may leave the wolf against a rock; find a real clear lane.
	var lane:=pursuit_lane(wolf)
	expect(not lane.is_empty(),"found unobstructed pursuit lane within wolf habitat")
	if not lane.is_empty():
		wolf.position=lane.origin
		game.player.position=wolf.position+lane.direction*170
		var pursuit_start:=wolf.position
		var phase:=animation.phase
		game.update_enemy(wolf,0.1)
		expect(wolf.state=="chase" and wolf.position.distance_to(pursuit_start)>0 and animation.action=="run" and animation.motion>0 and not is_equal_approx(animation.phase,phase),"actual pursuit advances the running gait")
		# Keep the zero-displacement rule under the real AI/collision/animation path.
		var block_cell:=Vector2i((lane.origin+lane.direction*GameData.TILE)/GameData.TILE)
		var block_index:int=game.world._idx(block_cell.x,block_cell.y)
		var block_tile:int=game.world.map[block_index]
		game.world.map[block_index]=GameData.T_ROCK
		wolf.position=lane.origin+lane.direction*(GameData.TILE*0.5-wolf.radius-1)
		game.player.position=wolf.position+lane.direction*170
		var blocked_start:=wolf.position
		phase=animation.phase
		game.update_enemy(wolf,0.1)
		expect(wolf.position==blocked_start and animation.phase==phase and animation.motion==0 and animation.action=="idle","no displacement stops footsteps instead of running in place")
		game.world.map[block_index]=block_tile
	for key in ["spirit_wolf:0","iron_den:0"]:
		var monster:Enemy=game.wildlife.actors[key]
		monster.age_seconds=float(monster.data.mature)
		monster.refresh_growth()
		var monster_lane:=pursuit_lane(monster)
		expect(not monster_lane.is_empty(),"found unobstructed monster pursuit lane "+monster.kind)
		if monster_lane.is_empty(): continue
		monster.position=monster_lane.origin
		monster.threat_time=2.0
		monster.atk_cd=10
		monster.wildlife_animation.action="idle"
		game.player.position=monster.position+monster_lane.direction*170
		var before:=monster.position
		var phase:=monster.wildlife_animation.phase
		game.update_enemy(monster,0.1)
		expect(monster.is_monster and monster.state=="chase" and monster.position.distance_to(before)>0 and monster.wildlife_animation.action=="run" and monster.wildlife_animation.motion>0 and not is_equal_approx(monster.wildlife_animation.phase,phase),"actual monster pursuit advances the running gait "+monster.kind)
	for id in WildlifeAnimation.PROFILES:
		var actor:Enemy=game._make_host(id,Vector2.ZERO)
		actor.age_seconds=float(actor.data.mature)
		actor.refresh_growth()
		var motion:=actor.wildlife_animation
		motion.locomotion(0.1,Vector2(actor.spd*0.1,0),actor.radius,actor.spd,0,false)
		motion.sync_pose(actor.radius)
		var first:Vector4=motion.rig.material.get_shader_parameter("leg_angles")
		motion.locomotion(0.1,Vector2(actor.spd*0.1,0),actor.radius,actor.spd,0,false)
		motion.sync_pose(actor.radius)
		var next:Vector4=motion.rig.material.get_shader_parameter("leg_angles")
		expect(first!=next,"limbs change pose during movement "+id)
		motion.locomotion(0.1,Vector2(-actor.spd*0.1,0),actor.radius,actor.spd,PI,false)
		motion.sync_pose(actor.radius)
		expect(motion.rig.scale.x<0 and motion.rig.scale.y>0,"left-facing motion mirrors without turning upside down "+id)
		var body_pos:=actor.position
		motion.play_hurt(Vector2.LEFT)
		motion.advance(0.1)
		motion.sync_pose(actor.radius)
		expect(motion.rig.position.x<0 and actor.position==body_pos,"hurt recoil moves the illustration without teleporting collision "+id)
		actor.free()
	var timid:Enemy=game.wildlife.actors["bamboo_hare:0"]
	game.player.position=timid.position+Vector2(50,0)
	game.update_enemy(timid,0.1)
	expect(timid.state=="flee" and timid.wildlife_animation.action!="attack","timid animals still flee instead of gaining aggression from animation")
	var inv:Inventory=game.get_node("/root/Inv")
	var drops:=inv.get_item_count("wolf_meat")
	var key:=wolf.wildlife_slot
	game.kill_enemy(wolf)
	expect(wolf.dead and wolf not in game.enemies and wolf.wildlife_animation.action=="death","death immediately removes targeting but retains a falling illustration")
	game.kill_enemy(wolf)
	expect(inv.get_item_count("wolf_meat")==drops+1,"death animation cannot duplicate loot")
	game.save_game()
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.SAVE_PATH))
	expect(not data.wildlife.slots[key].has("actor"),"save during falling animation records death rather than resurrecting the corpse")
	game.paused=true
	game.wildlife.tick(1)
	expect(wolf.wildlife_animation.elapsed==0,"death animation pauses with menus")
	game.paused=false
	game.wildlife.tick(0.3)
	expect(wolf.wildlife_animation.elapsed>0 and wolf in game.wildlife.fading_actors,"death visibly advances before cleanup")
	game.wildlife.tick(1)
	await game.get_tree().process_frame
	expect(not is_instance_valid(wolf),"death presentation is cleaned up after its finite duration")
	print("WILDLIFEANIMTEST checked=%d failures=%s"%[checked,str(failures)])
	game.get_tree().quit(0 if failures.is_empty() else 1)
