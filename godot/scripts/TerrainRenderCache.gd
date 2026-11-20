class_name TerrainRenderCache
extends RefCounted

# Bake the existing block artwork once on the GPU. No readback or per-frame
# tessellation; the 1 px gutter preserves antialiased edges between chunks.
const CHUNK_TILES := 16
const MAX_CHUNKS := 48
var chunks: Dictionary = {}
var stamp := 0
var rebuilds := 0

func draw(canvas: Node2D, view: Rect2, layer: int, blocks: TerrainLayers) -> void:
	var size:=TerrainLayers.size_for(layer)
	var span:=CHUNK_TILES*GameData.TILE
	var current:Dictionary={}
	for y in range(maxi(0,floori(view.position.y/span)),mini(ceili(float(size.y)/CHUNK_TILES),ceili(view.end.y/span))):
		for x in range(maxi(0,floori(view.position.x/span)),mini(ceili(float(size.x)/CHUNK_TILES),ceili(view.end.x/span))):
			var key:=Vector3i(x,y,layer)
			current[key]=true
			if not chunks.has(key): _create(canvas,blocks,key)
			var chunk:Dictionary=chunks[key]
			stamp+=1
			chunk.used=stamp
			if chunk.viewport==null: continue
			if chunk.dirty:
				chunk.painter.queue_redraw()
				chunk.viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
				chunk.dirty=false
				rebuilds+=1
			canvas.draw_texture_rect_region(chunk.viewport.get_texture(),chunk.rect,Rect2(Vector2.ONE,chunk.rect.size))
	while chunks.size()>maxi(MAX_CHUNKS,current.size()):
		var oldest:=Vector3i(-1,-1,-1)
		var age:=stamp+1
		for key:Vector3i in chunks:
			if not current.has(key) and int(chunks[key].used)<age:
				age=chunks[key].used
				oldest=key
		if oldest.z<0: break
		_discard(oldest)

func _create(canvas: Node2D, blocks: TerrainLayers, key: Vector3i) -> void:
	var origin:=Vector2i(key.x,key.y)*CHUNK_TILES
	var dimensions:=(TerrainLayers.size_for(key.z)-origin).min(Vector2i(CHUNK_TILES,CHUNK_TILES))
	var rect:=Rect2(Vector2(origin)*GameData.TILE,Vector2(dimensions)*GameData.TILE)
	var chunk:Dictionary={"viewport":null,"painter":null,"rect":rect,"dirty":true,"used":stamp}
	chunks[key]=chunk
	if key.z==0:
		var empty:=true
		for y in range(origin.y,origin.y+dimensions.y):
			for x in range(origin.x,origin.x+dimensions.x):
				if blocks.height_at(Vector2i(x,y))!=0:
					empty=false
					break
			if not empty: break
		if empty: return
	var viewport:=SubViewport.new()
	viewport.name="TerrainBake_%d_%d_%d"%[key.z,key.x,key.y]
	viewport.size=Vector2i(rect.size)+Vector2i(2,2)
	viewport.disable_3d=true
	viewport.transparent_bg=true
	viewport.gui_disable_input=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	canvas.add_child(viewport)
	var painter:=TerrainChunk.new()
	painter.blocks=blocks
	painter.cells=Rect2i(origin,dimensions)
	painter.layer=key.z
	painter.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	viewport.add_child(painter)
	chunk.viewport=viewport
	chunk.painter=painter

func invalidate(cell: Vector2i, layer: int) -> void:
	# Neighbours use this cell's height for their exposed faces and shadows.
	for offset in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		var adjacent:Vector2i=cell+offset
		if adjacent.x<0 or adjacent.y<0: continue
		var key:=Vector3i(adjacent.x/CHUNK_TILES,adjacent.y/CHUNK_TILES,layer)
		if not chunks.has(key): continue
		if chunks[key].viewport==null: chunks.erase(key)
		else: chunks[key].dirty=true

func clear() -> void:
	for key:Vector3i in chunks.keys(): _discard(key)

func _discard(key: Vector3i) -> void:
	if is_instance_valid(chunks[key].viewport): chunks[key].viewport.queue_free()
	chunks.erase(key)
