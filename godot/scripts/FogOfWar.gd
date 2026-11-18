class_name FogOfWar
extends ColorRect

const BASE_RADIUS := 430.0
var game: Node
var explored: Dictionary = {}
var overlay: ImageTexture
var mask_image: Image
var elapsed := 0.0
var fog_material: ShaderMaterial

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIStyle.fill(self)
	mask_image = Image.create(GameData.MAP_W,GameData.MAP_H,false,Image.FORMAT_RGBA8)
	mask_image.fill(Color(0.025,0.045,0.045,0.97))
	overlay = ImageTexture.create_from_image(mask_image)
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
	return BASE_RADIUS * game.player.body.get_vision_multiplier()

func can_see(pos: Vector2) -> bool:
	return game.player.position.distance_to(pos)<radius_world()

func _process(delta: float) -> void:
	visible = game!=null and game.running
	if not visible: return
	for enemy in game.enemies:
		if is_instance_valid(enemy): enemy.visible=not game.world.in_interior and can_see(enemy.position)
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
	for y in range(maxi(0,int((pos.y-radius)/32)),mini(GameData.MAP_H,int((pos.y+radius)/32)+1)):
		for x in range(maxi(0,int((pos.x-radius)/32)),mini(GameData.MAP_W,int((pos.x+radius)/32)+1)):
			var id := y*GameData.MAP_W+x
			if not explored.has(id) and pos.distance_to(Vector2(x*32+16,y*32+16))<radius:
				explored[id]=true
				mask_image.set_pixel(x,y,Color(0,0,0,0))
				changed=true
	if changed: overlay.update(mask_image)

func discovered(pos: Vector2) -> bool:
	if pos.x<0 or pos.y<0 or pos.x>=GameData.MAP_W*32 or pos.y>=GameData.MAP_H*32: return false
	return explored.has(int(pos.y/32)*GameData.MAP_W+int(pos.x/32))

func load_data(data: Array, source_width: int = GameData.MAP_W) -> void:
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
	overlay.update(mask_image)
