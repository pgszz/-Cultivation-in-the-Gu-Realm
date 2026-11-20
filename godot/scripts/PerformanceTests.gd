class_name PerformanceTests
extends RefCounted

# Windowed, full-quality sampling. Wall time includes CPU, GPU and vsync.
# 60 FPS target with tolerance for desktop scheduling; never infer success
# from the existence of a PERF line or the process exit code alone.
const MIN_FPS := 55.0
const MAX_P95_MS := 22.0
const WARMUP_SECONDS := 3.0
const SAMPLE_SECONDS := 5.0
var game: Node

func run(main: Node, scenes: bool = false) -> void:
	game=main
	game.performance_testing=true
	game.start_game()
	print("PERF_CONFIG "+JSON.stringify({"engine":Engine.get_version_info().string,"renderer":ProjectSettings.get_setting("rendering/renderer/rendering_method"),"device":RenderingServer.get_video_adapter_name(),"window":str(game.get_window().size),"viewport":str(game.get_viewport_rect().size),"vsync":DisplayServer.window_get_vsync_mode(),"max_fps":Engine.max_fps,"warmup_seconds":WARMUP_SECONDS,"sample_seconds":SAMPLE_SECONDS,"minimum_fps":MIN_FPS,"maximum_p95_ms":MAX_P95_MS}))
	await _sample("opening")
	if scenes:
		await _sample("walk",true)
		game.player.position=Vector2(2800,4400)
		game._update_camera(0)
		game.camera.reset_smoothing()
		await _sample("frontier_travel",false,false,true)
		game.player.position=Vector2(512,1040)
		game.set_camera_zoom(0.65)
		await _sample("wide_view")
		game.set_camera_zoom(1.0)
		game.change_layer(1,Vector2(1424,528),false)
		await _sample("underground")
		game.change_layer(2,Vector2(1552,656),false)
		await _sample("deep_cave")
		game.change_layer(0,Vector2(512,1040),false)
		game.enter_house(World.HOUSE_DATA[2])
		await _sample("interior")
		game.exit_house(false)
		var wolf:Enemy=game.wildlife.actors["ridge_wolf:1"]
		game.player.position=wolf.position+Vector2(42,0)
		game._update_camera(0)
		game.camera.reset_smoothing()
		await _sample("wildlife_combat",false,true)
	game.get_tree().quit()

func _sample(label: String, walking: bool = false, combat: bool = false, traveling: bool = false) -> void:
	var start:=Time.get_ticks_usec()
	var previous:=start
	var warmup_us:=int(WARMUP_SECONDS*1000000)
	var duration_us:=int(SAMPLE_SECONDS*1000000)
	var samples:Array[float]=[]
	var draws:Array[int]=[]
	var report_at:=1.0
	var measurement_start:=0
	var tick:=0.0
	var origin:Vector2=game.player.position
	var cold_max_ms:=0.0
	while measurement_start==0 or Time.get_ticks_usec()-measurement_start<duration_us:
		await game.get_tree().process_frame
		var now:=Time.get_ticks_usec()
		var elapsed:=(now-start)/1000000.0
		var frame_ms:=(now-previous)/1000.0
		previous=now
		if traveling:
			# Scripted camera traversal through uncached country at 180 px/s;
			# keep the simulation live and place the actor on valid ground.
			game.player.position=game.world.safe_position(origin+Vector2(elapsed*180,0),true)
		if walking:
			# Normal movement and collision along the village street, with a
			# continuously moving camera and streamed prop borders.
			var direction:=Vector2.DOWN if elapsed<4.0 else Vector2.UP
			game.world.move_body(game.player,direction.x*100*frame_ms/1000,direction.y*100*frame_ms/1000,game.player.radius)
		if combat:
			# Keep this short fixture alive while real wildlife AI, attacks,
			# damage feedback and particles run. No paused simulation shortcut.
			game.player.hp=game.player.max_hp
			game.player.body.reset_full()
			tick+=frame_ms/1000
			if tick>0.4:
				tick=0
				game.fx.burst(game.player.position.x,game.player.position.y,Color("d9c46a"),8,120,0.4)
		if now-start<warmup_us:
			cold_max_ms=maxf(cold_max_ms,frame_ms)
			continue
		if measurement_start==0:
			cold_max_ms=maxf(cold_max_ms,frame_ms)
			measurement_start=now
			continue
		samples.append(frame_ms)
		draws.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		if (now-measurement_start)/1000000.0>=report_at:
			print("PERF fps=%d draws=%d objects=%d nodes=%d scene=%s"%[Engine.get_frames_per_second(),draws.back(),Performance.get_monitor(Performance.OBJECT_COUNT),Performance.get_monitor(Performance.OBJECT_NODE_COUNT),label])
			report_at+=1
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png("res://shot_perf_"+label+".png")
	var ordered:=samples.duplicate()
	ordered.sort()
	draws.sort()
	var total:=0.0
	for ms:float in samples: total+=ms
	var fps:=samples.size()*1000.0/maxf(1,total)
	var p95:float=ordered[clampi(ceili(ordered.size()*0.95)-1,0,ordered.size()-1)] if not ordered.is_empty() else INF
	var passed:bool=fps>=MIN_FPS and p95<=MAX_P95_MS and not game.low_quality and not game.paused and not game.player.dead and samples.size()>0
	var result:Dictionary={"scene":label,"passed":passed,"fps_mean":snappedf(fps,0.01),"p95_ms":snappedf(p95,0.01),"max_ms":ordered.back() if not ordered.is_empty() else 0,"cold_max_ms":cold_max_ms,"frames":samples.size(),"sample_seconds":snappedf(total/1000,0.01),"draws_median":draws[draws.size()/2] if not draws.is_empty() else 0,"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),"ground_chunks":game.world.terrain_chunks.size(),"block_chunks":game.world.blocks.render_cache.chunks.size(),"block_rebuilds":game.world.blocks.render_cache.rebuilds,"prop_visuals":game.world.active_props.size(),"distance":game.player.position.distance_to(origin),"full_quality":not game.low_quality}
	print("PERF_SUMMARY "+JSON.stringify(result))
