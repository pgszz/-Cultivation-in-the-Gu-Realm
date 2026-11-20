class_name RenderTests
extends RefCounted

var game: Node
var test := CanonTests.new()

func run(main: Node) -> void:
	game=main
	test.game=game
	game.set_process(false)
	game.start_game()
	game.paused=true
	await _settle()
	var world:World=game.world
	test.expect(world.prop_regions.size()>100 and world.active_props.size()<300,"full map keeps prop records while only nearby visuals exist")
	test.expect(world.destruction.objects.size()>9000,"streaming retains remote durability records")
	var id:String=world.active_props.keys()[0]
	var obj:Dictionary=world.destruction.objects[id]
	var position:Vector2=obj.visual.position
	var tile:Vector2i=obj.tile
	world.destruction.hit_area(position,40,15,1,"",Vector2.ZERO,-1,id)
	var hp:float=obj.hp
	game.player.position=Vector2(11000,8000)
	await _settle()
	test.expect(not world.active_props.has(id) and obj.visual==null and obj.hp==hp,"leaving releases visuals without losing damage")
	world.destruction.hit_area(position,40,9999,1,"",Vector2.ZERO,-1,id)
	test.expect(obj.hp==0 and world.tile_at(tile.x,tile.y)==GameData.T_GRASS,"offscreen destruction still clears collision")
	var saved:Dictionary=world.destruction.save_data()
	world.destruction.load_data(saved,world.destruction.salvaged.keys())
	game.player.position=position
	await _settle()
	test.expect(world.active_props.has(id) and obj.visual.broken and obj.visual.collapse_elapsed==CollapseAnimation.DURATION,"return after save/load creates the ruined final appearance")
	test.expect(world.destruction.salvage_yield(id).is_empty(),"streamed ruin cannot grant salvage twice")
	# Damage during a partial prefetch must not publish stale terrain later.
	var remote_key:=Vector2i(10,8)
	var remote_cell:=remote_key*World.CHUNK_TILES+Vector2i(4,4)
	var tile_index:=world._idx(remote_cell.x,remote_cell.y)
	world.terrain_chunks.erase(remote_key)
	var job:Dictionary=world._terrain_job(remote_key)
	while job.next<5*World.CHUNK_TILES: world._paint_chunk_step(job)
	world.terrain_prefetch[remote_key]=job
	world.map[tile_index]=GameData.T_DIRT
	world.refresh_terrain_tile(remote_cell)
	world.flush_terrain_changes()
	world._ensure_terrain(Rect2(Vector2(remote_cell)*32,Vector2(32,32)))
	var expected:=Image.create(32,32,false,Image.FORMAT_RGBA8)
	world._paint_tile(expected,remote_cell.x,remote_cell.y,remote_cell*32)
	var actual:Image=world.terrain_chunks[remote_key].texture.get_image().get_region(Rect2i(Vector2i(4,4)*32,Vector2i(32,32)))
	test.expect(actual.get_data()==expected.get_data(),"terrain changed during prefetch is repainted before publishing")
	test.expect(not world.terrain_prefetch.has(remote_key),"demand loading consumes or invalidates a partial prefetch")
	game.enter_house(World.HOUSE_DATA[2])
	await _settle()
	test.expect(world.active_props.is_empty(),"indoors releases outdoor prop visuals")
	game.exit_house(false)
	await _settle()
	test.expect(not world.active_props.is_empty(),"leaving a room restores nearby visuals")
	# A boundary column changes its own raster and invalidates adjacent faces.
	var cell:=Vector2i.ZERO
	for candidate:Vector2i in world.blocks.mountain_cells["0"]:
		if candidate.x%TerrainRenderCache.CHUNK_TILES==0 and world.blocks.height_at(candidate)>0:
			cell=candidate
			break
	test.expect(cell!=Vector2i.ZERO,"mountain fixture straddles the render cache boundary")
	game.change_layer(0,TerrainLayers.center(cell),false)
	await _settle()
	var cache:TerrainRenderCache=world.blocks.render_cache
	var key:=Vector3i(cell.x/TerrainRenderCache.CHUNK_TILES,cell.y/TerrainRenderCache.CHUNK_TILES,0)
	var before:Image=cache.chunks[key].viewport.get_texture().get_image()
	var rebuilds:=cache.rebuilds
	for i in 4:
		world.queue_redraw()
		await _settle()
	test.expect(cache.rebuilds==rebuilds,"animated world redraws reuse unchanged mountain rasters")
	world.blocks.hit(cell,0,9999)
	await _settle()
	var after:Image=cache.chunks[key].viewport.get_texture().get_image()
	test.expect(before.get_data()!=after.get_data(),"breaking a cached mountain visibly updates its actual texture")
	test.expect(cache.rebuilds>rebuilds and cache.rebuilds<=rebuilds+3,"boundary damage rebuilds only affected cached chunks")
	world.blocks.load_data({})
	test.expect(cache.chunks.is_empty(),"load invalidates all old block rasters")
	await _settle()
	for layer in [1,2]:
		game.change_layer(layer,Vector2(1424,528),false)
		await _settle()
		var floor:=TerrainLayers.cell_at(game.player.position)
		key=Vector3i(floor.x/TerrainRenderCache.CHUNK_TILES,floor.y/TerrainRenderCache.CHUNK_TILES,layer)
		before=cache.chunks[key].viewport.get_texture().get_image()
		world.blocks.hit(floor,layer,12)
		await _settle()
		after=cache.chunks[key].viewport.get_texture().get_image()
		test.expect(before.get_data()!=after.get_data(),"underground damage updates the current layer raster "+str(layer))
		game.set_camera_zoom(0.65)
		await _settle()
		test.expect(cache.chunks.size()<=TerrainRenderCache.MAX_CHUNKS,"zoomed underground view respects the render cache budget")
	game.set_camera_zoom(1.0)
	game.change_layer(0,Vector2(512,1040),false)
	for i in 12:
		game.player.position=Vector2(800+i*1024,1600+(i%3)*1024)
		await _settle()
	test.expect(cache.chunks.size()<=TerrainRenderCache.MAX_CHUNKS and world.terrain_chunks.size()<=World.MAX_TERRAIN_CHUNKS,"travel evicts both raster caches within their budgets")
	test.expect(world.active_props.size()<400,"travel does not accumulate prop nodes")
	game.player.position=Vector2(512,1040)
	await _settle()
	game.get_viewport().get_texture().get_image().save_png("res://shot_render_opening.png")
	print("RENDERTEST checked=%d failures=%s"%[test.checked,str(test.failures)])
	game.get_tree().quit(0 if test.failures.is_empty() else 1)

func _settle() -> void:
	game._update_camera(0)
	game.camera.reset_smoothing()
	for i in 3: await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
