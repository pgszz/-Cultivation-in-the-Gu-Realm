class_name GuVfxTests
extends RefCounted

var game:Node
var checked:=0
var failures:Array[String]=[]
var instances:Dictionary={}
var label:Label

func expect(ok:bool,message:String) -> void:
	checked+=1
	if not ok:
		failures.append(message)
		print("GUVFXTEST FAIL "+message)

func count(kind:String) -> int:
	var result:=0
	for e in game.fx.gu.events:
		if e.kind==kind: result+=1
	return result

func reset() -> void:
	game.paused=false
	var p:Player=game.player
	p.body.reset_full()
	p.hp=100
	p.dead=false
	p.iframes=0
	p.shield=0
	p.jade_guard=false
	p.light_support_id=""
	p.gu_effects.load_data({})
	p.boar_cultivation.load_data({})
	p.aperture.stage=0
	p.yuan=44
	p.position=HouseInterior.ORIGIN
	p.animation.restore_dead(false)
	p.animation.action="idle"
	p.dir=0
	game.meditating=false
	game.projectiles.clear()
	game.fx.clear_transients()
	for gu in instances.values():
		gu.dead=false
		gu.location="aperture"

func cast(id:String,slot:int=0) -> void:
	game.player.skill_slots[slot]=instances[id].id
	game.player.cast_cds[slot]=0
	game.cast_skill(slot)
	game.fx.gu.advance(0,game)

func aim(at:Vector2) -> void:
	game.shake=0
	game._update_camera(0)
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	await game.get_tree().process_frame
	game.get_viewport().warp_mouse(game.get_viewport().get_canvas_transform()*at)
	await RenderingServer.frame_post_draw

func render(path:String,title:String) -> void:
	label.text=title
	game.player.queue_redraw()
	game.fx.queue_redraw()
	game.top.queue_redraw()
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	# Render deterministically even if another desktop window covers the test window.
	RenderingServer.force_draw()
	var err:=game.get_viewport().get_texture().get_image().save_png(path)
	expect(err==OK,"rendered "+path.get_file())

func run(main:Node) -> void:
	game=main
	game.set_process(false)
	game.start_game()
	CanonTests.prepare_cultivator(game)
	game.fx.set_process(false)
	game.player.set_process(false)
	game.enter_house(World.HOUSE_DATA[2])
	game.set_camera_zoom(1.75)
	game.zone_banner_time=0
	game.logs.clear()
	var layer:=CanvasLayer.new()
	game.add_child(layer)
	label=Label.new()
	label.position=Vector2(270,58)
	label.size=Vector2(740,30)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",19)
	label.add_theme_color_override("font_color",Color("f3e4b7"))
	layer.add_child(label)
	for id in GameData.GU_ORDER: instances[id]=game.get_node("/root/Gus").add_gu(id)
	game.player.owned.assign(GameData.GU_ORDER)
	reset()
	await aim(game.player.position+Vector2(300,0))
	var p:Player=game.player
	var visuals:GuVfx=game.fx.gu

	# Normal and assisted crescents keep their existing gameplay size and cost.
	cast("moon_blade")
	expect(game.projectiles.size()==1 and p.yuan==34,"ordinary crescent costs ten essence")
	var pr:Dictionary=game.projectiles[0]
	expect(pr.gu_id=="moon_blade" and pr.r==6 and pr.dmg==26,"crescent retains physical radius and damage")
	game._update_projectiles(0.25)
	expect(pr.trail.size()>2 and pr.trail.size()<=16,"actual moving projectile builds bounded trail")
	await render("res://shot_guvfx_moon.png","月光蛊 · 月牙弹道与方向拖尾")
	reset()
	cast("little_light",1)
	cast("moon_blade")
	pr=game.projectiles[0]
	expect(pr.r==12 and pr.dmg==52 and p.yuan==31.5,"assisted crescent doubles radius and damage at existing combined cost")
	game._update_projectiles(0.25)
	await render("res://shot_guvfx_light.png","小光辅助 · 更大的月牙、银白刃缘与掌心星光")
	# Actual wall collision creates one impact, with no later phantom projectile.
	game._update_projectiles(0.6)
	expect(game.projectiles.is_empty() and count("moon_hit")==1,"wall consumes projectile and produces exactly one impact")
	await render("res://shot_guvfx_impact.png","月刃命中墙壁 · 碎光只在真实碰撞处出现")
	game.top._process(0)
	expect(not game.top._had_content,"empty top layer clears the last projectile drawing")

	# NPC and enemy hits use the same impact hook, including lethal targets.
	reset()
	game.exit_house(false)
	var npc:Npc=game.npc
	var old_pos:Vector2=npc.position
	p.position=old_pos-Vector2(55,0)
	await aim(npc.position)
	var hp:float=npc.hp
	cast("moon_blade")
	game._update_projectiles(0.12)
	expect(npc.hp<hp and count("moon_hit")==1,"actual NPC damage gets a single crescent impact")
	game.enter_house(World.HOUSE_DATA[2])
	reset()
	await aim(p.position+Vector2(200,0))
	var enemy:Enemy=game.spawn_enemy("moon_blade",p.position+Vector2(65,0))
	cast("moon_blade")
	game._update_projectiles(0.15)
	expect(enemy.dead and count("moon_hit")==1,"lethal enemy hit still emits exactly one impact")

	for id in ["jade_skin","copper_skin","iron_skin","stone_skin","beast_skin"]:
		reset()
		cast(id)
		expect(visuals.snapshot(game).get("guard","")==id,"live guard material follows "+id)
		game.damage_player(10)
		var last:Dictionary=visuals.events[-1]
		expect(last.kind=="guard_hit" and last.reduced>0 and last.id==id,"funded guard reports actual reduction for "+id)
		await render("res://shot_guvfx_"+id+".png",GameData.GU[id].name+" · 护体材质 / 受击反馈")
		p.iframes=0
		p.yuan=0
		game.damage_player(10)
		expect(not visuals.snapshot(game).has("guard") and visuals.events[-1].kind=="guard_break","unfunded guard collapses before drawing for "+id)
		reset()
		cast(id)
		game.paused=true
		game.move_gu(instances[id].id,"bag")
		visuals.advance(0.1,game)
		expect(not visuals.active.has("guard") and count("awaken")==0,"removing guard during paused menu clears its aura and activation for "+id)

	reset()
	cast("copper_skin")
	cast("jade_skin")
	expect(visuals.snapshot(game).guard=="jade_skin" and count("awaken")==1,"guard replacement has one material and removes old activation")
	instances.jade_skin.dead=true
	visuals.advance(0,game)
	expect(not visuals.active.has("guard"),"dead Gu cannot keep a visual guard")
	reset()
	cast("copper_skin")
	p.yuan=0
	game._update_owned_gu(0.1)
	expect(not visuals.snapshot(game).has("guard") and count("guard_break")==1,"upkeep exhaustion emits dispersal without requiring another incoming hit")

	reset()
	cast("brute_longhorn")
	cast("yellow_camel",1)
	expect(visuals.active.has("brute") and visuals.active.has("endurance"),"both independent temporary states can be shown together")
	p.atk_cd=0
	game.basic_attack()
	expect(count("melee")==1 and visuals.events[-1].strong,"real empowered melee gets its own colored strike")
	await render("res://shot_guvfx_brute.png","蛮力天牛 · 双臂增力与强化普攻 / 黄骆 · 足部耐力流光")
	var before_hp:=p.hp
	var before_yuan:=p.yuan
	visuals.advance(1,game)
	expect(p.hp==before_hp and p.yuan==before_yuan and p.gu_effects.brute_left==5,"visual time never applies damage or spends gameplay resources")
	p.gu_effects.tick(5,p,game.get_node("/root/Gus"))
	visuals.advance(0,game)
	expect(not visuals.active.has("brute") and visuals.active.has("endurance"),"brute effect ends at real expiry while endurance remains")
	p.gu_effects.tick(10,p,game.get_node("/root/Gus"))
	visuals.advance(0,game)
	expect(not visuals.active.has("endurance"),"endurance aura ends with actual timer")

	reset()
	cast("yellow_camel",1)
	await aim(p.position+Vector2(250,0))
	var start:Vector2=p.position
	cast("dragon_cricket")
	var leap:Dictionary=visuals.events[-1]
	expect(count("leap")==1 and leap.from==start and leap.pos==p.position and p.position.distance_to(start)<=112.01,"leap trail ends exactly at the collision-tested destination (%s / %.4f)"%[str(leap),p.position.distance_to(start)])
	expect(p.iframes==0 and p.gu_effects.stamina==92,"leap art grants no invulnerability and preserves endurance discount")
	await render("res://shot_guvfx_leap.png","龙丸蛐蛐 · 腾跃残影与落地涟漪，黄骆节省体力")
	reset()
	p.position=HouseInterior.ORIGIN+Vector2(327,0)
	# Keep the target inside the visible viewport; OS mouse warps clamp off-window coordinates.
	game.set_camera_zoom(1.0)
	await aim(p.position+Vector2(16,0))
	expect(game.world.collides(p.position.x+4,p.position.y,p.radius),"blocked leap fixture is touching the intact wall")
	cast("dragon_cricket")
	expect(count("leap")==0 and p.yuan==44 and p.gu_effects.stamina==100,"blocked leap produces neither success art nor resource charge")
	game.set_camera_zoom(1.75)
	game._update_camera(0)
	reset()
	p.yuan=0
	cast("brute_longhorn")
	cast("moon_blade")
	cast("jiu_chong")
	expect(visuals.events.is_empty() and visuals.snapshot(game).is_empty() and game.projectiles.is_empty(),"failed casts do not show successful effects")

	reset()
	cast("jiu_chong")
	expect(count("refine")==1 and p.aperture.refined_essence==5 and p.yuan==29,"wine mist follows successful essence conversion only")
	await render("res://shot_guvfx_wine.png","酒虫 · 酒雾收束，精炼真元汇入空窍")
	for id in ["white_boar","black_boar"]:
		reset()
		cast(id)
		expect(visuals.snapshot(game).get("training","")==id,"bodily training uses the active Gu's visual identity")
		game._update_owned_gu(0.5)
		visuals.advance(0.5,game)
		expect(p.boar_cultivation.progress>0,"training visual accompanies real permanent strength gain")
		await render("res://shot_guvfx_"+id+".png",GameData.GU[id].name+" · 静处养力，向身体汇聚的流光")
		game.stop_gu_training("")
		visuals.advance(0,game)
		expect(not visuals.active.has("training"),"training accents stop on interruption")

	reset()
	cast("jade_skin")
	cast("jiu_chong")
	game.paused=true
	var frozen:float=visuals.clock
	var life:float=visuals.events[-1].life
	visuals.advance(2,game)
	expect(visuals.clock==frozen and visuals.events[-1].life==life,"menu pause freezes transient and persistent animation clocks")
	game.paused=false
	game.save_game()
	game._load_save()
	visuals.advance(0,game)
	expect(visuals.active.is_empty() and visuals.events.is_empty(),"load clears temporary Gu presentation without reviving active powers")
	expect(game.get_node("/root/Gus").owned_gus.size()==GameData.GU_ORDER.size(),"load preserves all formal independent Gu while clearing only temporary presentation")
	for gu in game.get_node("/root/Gus").owned_gus: instances[gu.template_id]=gu
	reset()
	cast("jiu_chong")
	game.exit_house(false)
	expect(visuals.events.is_empty(),"leaving interior clears world-space effects")
	game.enter_house(World.HOUSE_DATA[2])
	reset()
	cast("jade_skin")
	game.player_death()
	visuals.advance(0.1,game)
	expect(visuals.events.is_empty() and visuals.active.is_empty(),"death clears active auras immediately")
	reset()
	game.death_layer.visible=false
	game.low_quality=true
	visuals.advance(0,game)
	await aim(p.position+Vector2(200,0))
	cast("iron_skin")
	cast("moon_blade",1)
	expect(not game.projectiles.is_empty(),"low quality cast creates projectile: "+game.last_action_message)
	game._update_projectiles(0.2)
	expect(not game.projectiles.is_empty() and game.projectiles[0].trail.size()<=8 and visuals.snapshot(game).get("guard","")=="iron_skin","low quality keeps real projectile and guard identity")
	await render("res://shot_guvfx_low.png","低画质 · 保留月牙轮廓、护体材质与受击识别")
	for i in 100: visuals.emit("moon_hit",p.position,"moon_blade",0.3,{"angle":0,"strong":false})
	expect(visuals.events.size()<=32,"low-quality burst backlog has a hard bound")
	visuals.advance(1,game)
	expect(visuals.events.is_empty(),"finished effects are removed")
	game.low_quality=false
	await motion_preview()
	print("GUVFXTEST checked=%d failures=%s"%[checked,str(failures)])
	game.get_tree().quit(0 if failures.is_empty() else 1)

func motion_preview() -> void:
	# Fixed simulation steps render the production effects, rather than illustrative replacements.
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://vfx_frames"))
	reset()
	game.player.aperture.stage=2
	await aim(game.player.position+Vector2(250,0))
	cast("jade_skin")
	cast("little_light",1)
	cast("yellow_camel",2)
	expect(game.fx.gu.active.size()==3,"motion capture begins with actual guard, light and endurance")
	for frame in 60:
		if frame in [0,24]:
			cast("moon_blade")
			expect(not game.projectiles.is_empty(),"motion capture casts real assisted crescent")
		if frame==12:
			game.player.iframes=0
			game.damage_player(8)
		if frame==30: cast("brute_longhorn")
		if frame==36:
			game.player.atk_cd=0
			game.basic_attack()
		if frame==44:
			cast("dragon_cricket")
			expect(count("leap")==1,"motion capture includes real leap event")
		game._update_projectiles(1.0/15)
		game._update_owned_gu(1.0/15)
		game.fx._process(1.0/15)
		game.player.iframes=maxf(0,game.player.iframes-1.0/15)
		game.player._process(1.0/15)
		await render("res://vfx_frames/%03d.png"%frame,"实战特效演示 · 辅光月刃 / 玉皮受击 / 蛮力 / 黄骆 / 腾跃")
