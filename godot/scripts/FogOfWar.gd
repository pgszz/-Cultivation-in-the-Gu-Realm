class_name FogOfWar
extends ColorRect

const BASE_RADIUS := 430.0
var game: Node
var explored: Dictionary = {}
var overlay: ImageTexture
var mask_image: Image
var elapsed := 0.0
var fog_material: ShaderMaterial
var layer := 0
var layer_explored: Dictionary = {}
var layer_images: Dictionary = {}
var layer_textures: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIStyle.fill(self)
	mask_image = Image.create(GameData.MAP_W,GameData.MAP_H,false,Image.FORMAT_RGBA8)
	mask_image.fill(Color(0.025,0.045,0.045,0.97))
	overlay = ImageTexture.create_from_image(mask_image)
	layer_explored[0]=explored
	layer_images[0]=mask_image
	layer_textures[0]=overlay
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec2 player_screen;
uniform vec2 screen_size;
uniform float radius = 430.0;
uniform vec2 world_origin;
uniform vec2 world_span;
uniform vec2 map_extent;
uniform sampler2D explored_mask : filter_nearest;
uniform bool indoors = false;
void fragment() {
    vec2 world_pos = world_origin + UV * world_span;
    vec2 map_uv = world_pos / map_extent;
    float unknown = texture(explored_mask,clamp(map_uv,vec2(0.0),vec2(1.0))).a;
    float d = distance(UV * screen_size,player_screen);
    float fog = smoothstep(radius*0.72,radius,d);
    float alpha = indoors ? 0.96 : mix(0.76,0.99,unknown);
    COLOR = vec4(0.018,0.035,0.04,fog*alpha);
}
"""
	fog_material = ShaderMaterial.new()
	fog_material.shader = shader
	fog_material.set_shader_parameter("explored_mask",overlay)
	fog_material.set_shader_parameter("map_extent",Vector2(GameData.MAP_W,GameData.MAP_H)*GameData.TILE)
	material = fog_material

func radius_world() -> float:
	return ((BASE_RADIUS if layer==0 else 320.0)+game.player.utility_gu.vision_bonus()) * game.player.body.get_vision_multiplier()

func can_see(pos: Vector2) -> bool:
	return game.player.position.distance_to(pos)<radius_world()

func _process(delta: float) -> void:
	if game!=null and game.shang_city!=null and game.shang_city.active:
		visible=false
		return
	visible = game!=null and game.running
	if not visible: return
	for enemy in game.enemies:
		if is_instance_valid(enemy): enemy.visible=game.world.on_surface() and can_see(enemy.position)
	for person in game.active_npcs(): person.visible=can_see(person.position)
	var vp := get_viewport_rect().size
	var transform: Transform2D = game.get_viewport().get_canvas_transform()
	var inverse := transform.affine_inverse()
	fog_material.set_shader_parameter("player_screen",transform*game.player.position)
	fog_material.set_shader_parameter("screen_size",vp)
	fog_material.set_shader_parameter("radius",radius_world()*game.camera.zoom.x)
	fog_material.set_shader_parameter("world_origin",inverse*Vector2.ZERO)
	fog_material.set_shader_parameter("world_span",inverse*vp-inverse*Vector2.ZERO)
	fog_material.set_shader_parameter("indoors",game.world.in_interior)
	elapsed += delta
	if elapsed>=0.15 and not game.paused and not game.world.in_interior:
		elapsed=0.0
		reveal(game.player.position,radius_world())

func reveal(pos: Vector2, radius: float) -> void:
	var changed := false
	var size:=TerrainLayers.size_for(layer)
	for y in range(maxi(0,int((pos.y-radius)/32)),mini(size.y,int((pos.y+radius)/32)+1)):
		for x in range(maxi(0,int((pos.x-radius)/32)),mini(size.x,int((pos.x+radius)/32)+1)):
			var id := y*size.x+x
			if not explored.has(id) and pos.distance_to(Vector2(x*32+16,y*32+16))<radius:
				explored[id]=true
				mask_image.set_pixel(x,y,Color(0,0,0,0))
				changed=true
	if changed: overlay.update(mask_image)

func discovered(pos: Vector2) -> bool:
	return discovered_on(pos,layer)

func _ensure_layer(value: int) -> void:
	if layer_explored.has(value): return
	var size:=TerrainLayers.size_for(value)
	var img:=Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
	img.fill(Color(0.025,0.045,0.045,0.97))
	layer_explored[value]={}
	layer_images[value]=img
	layer_textures[value]=ImageTexture.create_from_image(img)

func set_layer(value: int) -> void:
	layer=clampi(value,0,2)
	_ensure_layer(layer)
	explored=layer_explored[layer]
	mask_image=layer_images[layer]
	overlay=layer_textures[layer]
	elapsed=0
	if fog_material!=null:
		fog_material.set_shader_parameter("explored_mask",overlay)
		fog_material.set_shader_parameter("map_extent",TerrainLayers.extent(layer))

func explored_on(value: int) -> Dictionary:
	_ensure_layer(value)
	return layer_explored[value]

func overlay_on(value: int) -> ImageTexture:
	_ensure_layer(value)
	return layer_textures[value]

func discovered_on(pos: Vector2, value: int) -> bool:
	if not Rect2(Vector2.ZERO,TerrainLayers.extent(value)).has_point(pos): return false
	return explored_on(value).has(int(pos.y/32)*TerrainLayers.size_for(value).x+int(pos.x/32))

func save_layers() -> Dictionary:
	return {"1":explored_on(1).keys(),"2":explored_on(2).keys()}

func load_layers(data: Dictionary) -> void:
	for value in [1,2]:
		_ensure_layer(value)
		layer_explored[value].clear()
		var img:Image=layer_images[value]
		img.fill(Color(0.025,0.045,0.045,0.97))
		var size:=TerrainLayers.size_for(value)
		for raw in data.get(str(value),[]):
			var id:=int(raw)
			if id<0 or id>=size.x*size.y: continue
			layer_explored[value][id]=true
			img.set_pixel(id%size.x,id/size.x,Color(0,0,0,0))
		layer_textures[value].update(img)

func load_data(data: Array, source_width: int = GameData.MAP_W, source_version: int = GameData.MAP_VERSION) -> void:
	set_layer(0)
	explored.clear()
	mask_image.fill(Color(0.025,0.045,0.045,0.97))
	for raw in data:
		var old_id := int(raw)
		if old_id<0 or source_width<=0: continue
		var x:=old_id%source_width
		var y:=old_id/source_width
		if x>=GameData.MAP_W or y>=GameData.MAP_H: continue
		var id := y*GameData.MAP_W+x
		if id>=0 and id<GameData.MAP_W*GameData.MAP_H:
			explored[id]=true
			mask_image.set_pixel(id%GameData.MAP_W,id/GameData.MAP_W,Color(0,0,0,0))
			if source_version<5:
				var old_pos:=Vector2(x,y)*GameData.TILE+Vector2(16,16)
				var migrated:=World.migrate_outdoor_position(old_pos,source_version)
				if migrated!=old_pos:
					var cell:=Vector2i(migrated/GameData.TILE)
					explored[cell.y*GameData.MAP_W+cell.x]=true
					mask_image.set_pixel(cell.x,cell.y,Color(0,0,0,0))
	overlay.update(mask_image)
