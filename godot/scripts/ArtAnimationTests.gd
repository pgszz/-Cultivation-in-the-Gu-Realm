class_name ArtAnimationTests
extends RefCounted

var game: Node
var checked := 0
var failures: Array[String] = []

func expect(condition: bool, message: String) -> void:
	checked+=1
	if not condition:
		failures.append(message)
		print("ARTTEST FAIL "+message)

func wait(seconds: float) -> void:
	await game.get_tree().create_timer(seconds).timeout

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image:=game.get_viewport().get_texture().get_image()
	var error:=image.save_png("res://shot_art_"+name+".png")
	expect(error==OK,"saved animation evidence "+name)

func run(main: Node) -> void:
	game=main
	game.start_game()
	CanonTests.prepare_cultivator(game)
	game.set_process(false)
	game.paused=false
	var p: Player=game.player
	var d: DestructionSystem=game.world.destruction
	var inv: Inventory=game.get_node("/root/Inv")
	var home: Vector2=World.HOUSE_DATA[2].pos
	p.position=home+Vector2(74,52)
	p.dir=-PI*0.5
	game.npc.position=p.position+Vector2(90,0)
	game.npc.player_pos=p.position
	game.set_camera_zoom(1.4)
	game._update_camera(0)
	game.camera.reset_smoothing()
	game.fog.reveal(p.position,600)
	await wait(0.1)
	game.basic_attack()
	expect(p.animation.action=="strike","real basic attack starts strike pose")
	await wait(0.11)
	expect(p.animation.frame()==3,"strike reaches contact pose")
	game.paused=true
	var held:=p.animation.elapsed
	await wait(0.16)
	expect(is_equal_approx(held,p.animation.elapsed),"menu pause freezes actor pose")
	await shot("strike")
	game.paused=false
	await wait(0.5)
	expect(p.animation.action=="idle","strike recovers to idle")
	p.body.apply_hit("hand_l",30)
	expect(p.injury_severe and p.injury_region=="hand_l" and p.injury_time>0,"body destruction triggers localized injury feedback")
	p.body.reset_full()
	var gu: GuVirtual=game.get_node("/root/Gus").add_gu("moon_blade")
	gu.location="aperture"
	p.skill_slots[0]=gu.id
	p.yuan=44
	game.cast_skill(0)
	expect(p.animation.action=="cast" and not game.projectiles.is_empty(),"real moon blade casts with original pose")
	await shot("cast")
	game.damage_player(1)
	expect(p.animation.action=="hurt","real player damage starts recoil")
	await wait(0.09)
	game.paused=true
	await shot("hurt")
	game.paused=false
	var house: WorldProp=d.objects["house:home"].visual
	game.strike_world(home+Vector2(0,-20),1,45,"none",Vector2.ZERO,-1,false)
	expect(house.hit_time>0 and not house.broken,"nonlethal impact shakes intact facade")
	game.strike_world(home+Vector2(0,-20),1,9999,"none",Vector2.ZERO,-1,false)
	var wood:=inv.get_item_count("timber")
	expect(house.broken and house.collapse_elapsed==0,"lethal hit starts collapse once")
	expect(not game.world.collides(home.x,home.y-20,4),"collision clears immediately while visual collapses")
	await wait(0.28)
	expect(house.collapse_elapsed>0 and house.collapse_elapsed<CollapseAnimation.DURATION,"collapse advances over rendered frames")
	game.paused=true
	var collapse_held:=house.collapse_elapsed
	await wait(0.15)
	expect(is_equal_approx(collapse_held,house.collapse_elapsed),"pause freezes collapse")
	await shot("collapse")
	game.strike_world(home+Vector2(0,-20),1,9999,"none",Vector2.ZERO,-1,false)
	expect(inv.get_item_count("timber")==wood and house.collapse_elapsed==collapse_held,"repeat hit neither restarts collapse nor duplicates loot")
	# Replay the presentation at fixed simulation intervals for a reviewable clip.
	for i in 25:
		house.collapse_elapsed=float(i)*CollapseAnimation.DURATION/24.0
		house.queue_redraw()
		await shot("collapse_%03d"%i)
	game.paused=false
	await wait(0.05)
	expect(house.collapse_elapsed==CollapseAnimation.DURATION,"collapse reaches final ruin")
	await shot("ruin")
	var saved:=d.save_data()
	d.load_data(saved,d.salvaged.keys())
	expect(house.broken and house.collapse_elapsed==CollapseAnimation.DURATION,"load restores settled ruin without replay")
	inv.add_item("timber",30)
	inv.add_item("rubble",30)
	expect(game.repair_world_object("house:home"),"rebuild succeeds with original resource rules")
	expect(not house.broken and house.hit_time==0 and game.world.collides(home.x,home.y-20,4),"rebuild resets visual and restores collider")
	game.strike_world(home+Vector2(0,-20),1,9999,"none",Vector2.ZERO,-1,false)
	expect(house.collapse_elapsed==0,"rebuilt building can animate another collapse")
	expect(d.salvage_yield("house:home").is_empty(),"animation replay cannot renew salvage")
	game.npc.take_damage(1,game)
	expect(game.npc.animation.action=="hurt","resident damage starts original recoil pose")
	game.npc.take_damage(9999,game)
	expect(game.npc.dead and game.npc.animation.action=="death","resident lethal hit starts falling")
	await wait(0.2)
	await shot("resident_fall")
	game.npc.load_data(game.npc.save_data())
	expect(game.npc.animation.frame(true)==5 and game.npc.animation.progress()==1,"saved dead resident is already fallen")
	game.enter_house(World.HOUSE_DATA[0])
	p.position=HouseInterior.ORIGIN+Vector2(40,100)
	game._update_camera(0)
	game.camera.reset_smoothing()
	game.strike_world(HouseInterior.ORIGIN+Vector2(190,100),1,9999,"none",Vector2.ZERO,-1,false)
	expect(game.world.interior.fixture_effects.has("interior:clinic:storage"),"interior damage starts furniture collapse")
	await wait(0.3)
	game.paused=true
	await shot("furniture")
	d.load_data(d.save_data(),d.salvaged.keys())
	expect(game.world.interior.fixture_effects.is_empty(),"loading clears all transient furniture effects")
	game.exit_house()
	p.position=home+Vector2(74,52)
	game._update_camera(0)
	game.camera.reset_smoothing()
	game.paused=false
	game.player_death()
	expect(p.dead and game.paused and not game.death_layer.visible,"death freezes gameplay before modal")
	await wait(0.22)
	await shot("player_fall")
	await wait(0.6)
	expect(p.animation.frame()==5 and game.death_layer.visible,"player fall completes before death dialog")
	print("ARTTEST checked=%d failures=%s"%[checked,str(failures)])
	game.get_tree().quit(0 if failures.is_empty() else 1)
