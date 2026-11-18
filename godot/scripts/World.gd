class_name World
extends Node2D

## 青茅山地图：程序生成 + 手绘瓦片 + 圆形碰撞。

const TILE := GameData.TILE
const MW := GameData.MAP_W
const MH := GameData.MAP_H

var map := PackedByteArray()
var road_tiles := {}
var bridge_tiles := {}
const CHUNK_TILES := 32
var terrain_chunks: Dictionary = {}
var dirty_chunks: Dictionary = {}
var minimap_image: Image
var destruction: DestructionSystem
var minimap_texture: ImageTexture
var tile_var := PackedFloat32Array()
var camera_pos := Vector2.ZERO
var view_size := Vector2(1280, 720)
var player_pos := Vector2.ZERO
var font: Font
var props: Node2D
var houses: Array = []
var interior: HouseInterior
var in_interior := false
var floor_image: Image
var ground_tiles: Dictionary = {}

const HOUSE_DATA := [
	{"id":"clinic","name":"古月药堂","pos":Vector2(320,896),"hint":"包扎 / 检查伤势"},
	{"id":"shop","name":"古月商铺","pos":Vector2(704,896),"hint":"月兰花瓣 / 青竹酒"},
	{"id":"home","name":"竹楼居所","pos":Vector2(320,1216),"hint":"休息 / 随身行囊"},
	{"id":"archive","name":"古月学堂","pos":Vector2(704,1216),"hint":"修行常识 / 山志"},
	{"id":"ancestral","name":"宗族祠堂","pos":Vector2(512,672),"hint":"古月一族"},
	{"id":"bai","name":"白家寨会客楼","pos":Vector2(2048,672),"hint":"白家 / 溪流蛊"},
	{"id":"xiong","name":"熊家寨会客楼","pos":Vector2(1664,1664),"hint":"熊家 / 熊力蛊"},
	{"id":"flower_cave","name":"巨石缝隙","pos":Vector2(1184,288),"hint":"后山密洞","kind":"cave"},
	{"id":"spring_cave","name":"地下溶洞","pos":Vector2(736,608),"hint":"灵泉 / 月兰花海","kind":"cave"},
]

const MOUNTAINS := [
	{"pos":Vector2(1150,1030),"size":Vector2(330,350)},
	{"pos":Vector2(1800,620),"size":Vector2(390,410)},
	{"pos":Vector2(2300,1370),"size":Vector2(360,380)},
	{"pos":Vector2(700,420),"size":Vector2(330,350)},
	{"pos":Vector2(2770,560),"size":Vector2(440,460)},
	{"pos":Vector2(3230,370),"size":Vector2(400,430)},
	{"pos":Vector2(3920,470),"size":Vector2(480,510)},
	{"pos":Vector2(4730,660),"size":Vector2(520,540)},
	{"pos":Vector2(2900,1280),"size":Vector2(450,480)},
	{"pos":Vector2(4000,1330),"size":Vector2(440,460)},
	{"pos":Vector2(4750,2150),"size":Vector2(510,530)},
	{"pos":Vector2(3800,2530),"size":Vector2(500,520)},
	{"pos":Vector2(2860,2250),"size":Vector2(480,500)},
	{"pos":Vector2(1600,2400),"size":Vector2(460,490)},
	{"pos":Vector2(470,2550),"size":Vector2(440,480)},
	{"pos":Vector2(780,3340),"size":Vector2(480,510)},
	{"pos":Vector2(2370,3420),"size":Vector2(490,510)},
	{"pos":Vector2(4240,3600),"size":Vector2(500,520)},
]

static func mountain_footprint(config: Dictionary) -> Rect2:
	return Rect2(config.pos+Vector2(-config.size.x*0.36,-config.size.y*0.12),Vector2(config.size.x*0.72,config.size.y*0.12))

const LANDMARKS := [
	{"pos":Vector2i(43,39),"name":"三寨山道","type":"gate"},
	{"pos":Vector2i(37,9),"name":"后山巨石","type":"ruin"},
	{"pos":Vector2i(31,10),"name":"后山瀑布","type":"pond"},
	{"pos":Vector2i(24,45),"name":"山腰梯田","type":"marsh"},
	{"pos":Vector2i(23,19),"name":"灵泉溶洞","type":"garden"},
]

const ZONE_GRASS := {
	"forest": Color("#203623"), "marsh": Color("#20332d"),
	"ruin": Color("#29252f"), "rock": Color("#2c2c25"),
}
const ZONE_DIRT := {
	"forest": Color("#b19364"), "marsh": Color("#333129"),
	"ruin": Color("#302b28"), "rock": Color("#3a3428"),
}

var _rng := RandomNumberGenerator.new()
var _last_camera := Vector2(-99999, -99999)


func _ready() -> void:
	font = ThemeDB.fallback_font
	z_index = -20
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	destruction=DestructionSystem.new()
	destruction.world=self
	add_child(destruction)
	generate()
	_build_props()
	_register_fixtures()
	queue_redraw()


func _process(_delta: float) -> void:
	# Camera smoothing can settle while gameplay is paused (menus / screenshot).
	var inverse:=get_viewport().get_canvas_transform().affine_inverse()
	camera_pos=inverse*Vector2.ZERO
	view_size=inverse*get_viewport_rect().size-camera_pos
	if camera_pos.distance_squared_to(_last_camera) > 0.25:
		_last_camera = camera_pos
		queue_redraw()
	elif player_pos.distance_to(GameData.BONFIRE) < 700.0 or player_pos.distance_to(GameData.FURNACE) < 700.0 or player_pos.distance_to(Vector2(992,320))<700:
		queue_redraw()


func generate() -> void:
	var legacy_w := 80
	var legacy_h := 60
	road_tiles.clear()
	bridge_tiles.clear()
	_rng.seed = 20261116
	map.resize(MW * MH)
	tile_var.resize(MW * MH)
	map.fill(GameData.T_GRASS)
	for y in legacy_h:
		for x in legacy_w:
			tile_var[_idx(x,y)] = _rng.randf()

	# 边界岩石
	for x in legacy_w:
		map[_idx(x, 0)] = GameData.T_ROCK
		map[_idx(x, legacy_h - 1)] = GameData.T_ROCK
	for y in legacy_h:
		map[_idx(0, y)] = GameData.T_ROCK
		map[_idx(legacy_w - 1, y)] = GameData.T_ROCK

	# 土斑
	for i in 90:
		var cx := 3 + _rng.randi_range(0, legacy_w - 7)
		var cy := 3 + _rng.randi_range(0, legacy_h - 7)
		var r := 1 + _rng.randi_range(0, 3)
		for y in range(-r, r + 1):
			for x in range(-r, r + 1):
				if x * x + y * y <= r * r and _in_legacy(cx + x, cy + y) and _rng.randf() < 0.65:
					map[_idx(cx + x, cy + y)] = GameData.T_DIRT

	# 水塘
	var ponds := [
		Vector3i(30, 13, 4), Vector3i(56, 40, 4),
		Vector3i(22, 50, 4), Vector3i(67, 22, 3),
	]
	for p in ponds:
		for y in range(-p.z, p.z + 1):
			for x in range(-p.z, p.z + 1):
				var d := sqrt(float(x * x + y * y))
				if d <= p.z - 0.3:
					map[_idx(p.x + x, p.y + y)] = GameData.T_WATER
				elif d <= p.z + 0.8 and _rng.randf() < 0.5:
					map[_idx(p.x + x, p.y + y)] = GameData.T_DIRT

	# 树林
	for i in 26:
		var cx := 5 + _rng.randi_range(0, legacy_w - 11)
		var cy := 5 + _rng.randi_range(0, legacy_h - 11)
		if abs(cx - GameData.VILLAGE.x) < 7 and abs(cy - GameData.VILLAGE.y) < 7:
			continue
		var n := 4 + _rng.randi_range(0, 9)
		for j in n:
			var x := cx + _rng.randi_range(-2, 2)
			var y := cy + _rng.randi_range(-2, 2)
			if _in_legacy(x, y) and map[_idx(x, y)] == GameData.T_GRASS:
				map[_idx(x, y)] = GameData.T_TREE

	# 岩石堆
	for i in 20:
		var cx := 5 + _rng.randi_range(0, legacy_w - 11)
		var cy := 5 + _rng.randi_range(0, legacy_h - 11)
		if abs(cx - GameData.VILLAGE.x) < 6 and abs(cy - GameData.VILLAGE.y) < 6:
			continue
		for j in 4 + _rng.randi_range(0, 5):
			var x := cx + _rng.randi_range(-1, 2)
			var y := cy + _rng.randi_range(-1, 2)
			if _in_legacy(x, y) and map[_idx(x, y)] != GameData.T_WATER:
				map[_idx(x, y)] = GameData.T_ROCK

	# 花
	for i in 260:
		var x := 2 + _rng.randi_range(0, legacy_w - 5)
		var y := 2 + _rng.randi_range(0, legacy_h - 5)
		if map[_idx(x, y)] == GameData.T_GRASS and _rng.randf() < 0.7:
			map[_idx(x, y)] = GameData.T_FLOWER

	# 村落空地
	for y in range(GameData.VILLAGE.y - 4, GameData.VILLAGE.y + 5):
		for x in range(GameData.VILLAGE.x - 5, GameData.VILLAGE.x + 6):
			if _in_legacy(x, y):
				map[_idx(x, y)] = GameData.T_DIRT

	for p in [GameData.BONFIRE, GameData.FURNACE]:
		var tx := int(p.x / TILE)
		var ty := int(p.y / TILE)
		for y in range(ty - 1, ty + 2):
			for x in range(tx - 1, tx + 2):
				if _in_legacy(x, y):
					map[_idx(x, y)] = GameData.T_DIRT

	# 村寨巷道与山路按地点关系连通，避免向每个地点铺一条穿潭直线。
	for h in HOUSE_DATA:
		var q:=Vector2i(h.pos/TILE)
		for y in range(q.y-2,q.y+3):
			for x in range(q.x-3,q.x+4):
				if _in_legacy(x,y): map[_idx(x,y)]=GameData.T_DIRT
	for y in range(7,14):
		for x in range(28,34):
			if tile_at(x,y) in [GameData.T_TREE,GameData.T_ROCK]: map[_idx(x,y)]=GameData.T_GRASS
	var routes := [
		[Vector2i(16,23),Vector2i(16,40)],
		[Vector2i(10,29),Vector2i(22,29)],
		[Vector2i(10,39),Vector2i(22,39)],
		[Vector2i(16,23),Vector2i(23,21)],
		[Vector2i(23,21),Vector2i(28,20),Vector2i(35,16),Vector2i(35,11),Vector2i(37,10)],
		[Vector2i(35,11),Vector2i(34,11)],
		[Vector2i(16,32),Vector2i(28,34),Vector2i(43,40),Vector2i(55,34),Vector2i(64,24),Vector2i(64,22)],
		[Vector2i(43,40),Vector2i(47,47),Vector2i(52,54),Vector2i(52,53)],
		[Vector2i(16,39),Vector2i(17,44),Vector2i(19,47),Vector2i(24,49)],
	]
	for route in routes:
		for i in range(route.size()-1): _carve_road(route[i],route[i+1])
	# 梯田保留明确的水平台阶，与随机毒沼区分。
	for y in range(43,49):
		for x in range(20,29):
			if not road_tiles.has(_idx(x,y)): map[_idx(x,y)]=GameData.T_FLOWER if y%2==0 else GameData.T_DIRT
	# Remove stray obstacles from the four landmark approaches.
	for lm in LANDMARKS:
		var q: Vector2i = lm.pos
		for dy in range(-1,2):
			for dx in range(-1,2):
				if _in_legacy(q.x+dx,q.y+dy):
					if tile_at(q.x+dx,q.y+dy)==GameData.T_WATER:
						bridge_tiles[_idx(q.x+dx,q.y+dy)] = true
					map[_idx(q.x+dx,q.y+dy)] = GameData.T_DIRT
	_extend_wilderness()
	_bake_textures()




# New named sites are sandbox geography, not asserted novel locations.
const EXPLORATION_SITES := [
	{"id":"bamboo_hollow","name":"东麓竹坳","pos":Vector2i(87,24),"kind":"timber","text":"竹坳内倒伏的青矛竹可收集成木料，带回商铺换取补给。"},
	{"id":"river_ford","name":"溪谷渡口","pos":Vector2i(107,48),"kind":"lookout","text":"木桥连接两岸；北行通往高岭，南路绕过水潭。"},
	{"id":"high_ridge","name":"远山观景台","pos":Vector2i(138,18),"kind":"lookout","text":"山岭连绵。这里适合停步辨认山路，也可以自行打坐温养。"},
	{"id":"stone_gully","name":"东南石滩","pos":Vector2i(145,82),"kind":"rubble","text":"山水冲下的松散石料可以拾取；完整山体仍需要足够破坏力。"},
	{"id":"south_bamboo","name":"南麓竹坡","pos":Vector2i(31,76),"kind":"timber","text":"山脚竹林疏密相间。拾取枯竹不会惊动寨中守卫。"},
	{"id":"old_camp","name":"山民歇脚棚","pos":Vector2i(72,88),"kind":"camp","text":"棚下留有一个行路人补给包；领取后不会再生。"},
	{"id":"cedar_pool","name":"杉林深潭","pos":Vector2i(117,104),"kind":"lookout","text":"深潭旁有一片平坦岸地。打坐和探索均不要求击杀野兽。"},
	{"id":"south_pass","name":"南山石径","pos":Vector2i(46,108),"kind":"rubble","text":"碎石铺成的山路通向林间回环，沿路可以返回三寨。"},
	{"id":"central_camp","name":"溪边营地","pos":Vector2i(96,68),"kind":"camp","text":"一处能歇脚的临时营地。这里的补给由先到的旅人取走。"},
]

func _extend_wilderness() -> void:
	_rng.seed=20261118
	for y in MH:
		for x in MW:
			if x>=80 or y>=60: tile_var[_idx(x,y)]=_rng.randf()
	# Remove former east/south borders; old interior coordinates stay unchanged.
	for y in range(1,60): map[_idx(79,y)]=GameData.T_GRASS
	for x in range(1,80): map[_idx(x,59)]=GameData.T_GRASS
	for i in 380:
		var q:=Vector2i(_rng.randi_range(4,MW-5),_rng.randi_range(4,MH-5))
		if q.x<83 and q.y<63: continue
		var kind:=GameData.T_TREE if i%4!=0 else GameData.T_ROCK
		for j in _rng.randi_range(3,9):
			var t:=q+Vector2i(_rng.randi_range(-2,2),_rng.randi_range(-2,2))
			map[_idx(t.x,t.y)]=kind
	for y in range(5,MH-5):
		var river_x:=104+int(sin(y*0.09)*6)
		for x in range(river_x-2,river_x+2): map[_idx(x,y)]=GameData.T_WATER
	for pond in [Vector3i(121,102,6),Vector3i(32,94,5),Vector3i(136,42,5)]:
		for dy in range(-pond.z,pond.z+1):
			for dx in range(-pond.z,pond.z+1):
				if dx*dx+dy*dy<=pond.z*pond.z: map[_idx(pond.x+dx,pond.y+dy)]=GameData.T_WATER
	var routes: Array = [
		[Vector2i(64,24),Vector2i(77,25),Vector2i(87,24),Vector2i(96,16),Vector2i(112,22),Vector2i(138,18),Vector2i(148,34),Vector2i(137,54)],
		[Vector2i(64,48),Vector2i(82,50),Vector2i(98,48),Vector2i(107,48),Vector2i(118,55),Vector2i(137,54)],
		[Vector2i(52,54),Vector2i(56,70),Vector2i(72,88),Vector2i(95,98),Vector2i(117,104),Vector2i(143,98),Vector2i(145,82),Vector2i(137,54)],
		[Vector2i(24,49),Vector2i(30,64),Vector2i(31,76),Vector2i(22,87),Vector2i(40,104),Vector2i(46,108),Vector2i(72,88)],
		[Vector2i(98,48),Vector2i(96,68),Vector2i(89,76),Vector2i(72,88)],
	]
	for route in routes:
		for i in range(route.size()-1): _carve_road(route[i],route[i+1])
	for site in EXPLORATION_SITES:
		for dy in range(-2,3):
			for dx in range(-2,3):
				var q:Vector2i=site.pos+Vector2i(dx,dy)
				if tile_at(q.x,q.y)!=GameData.T_WATER: map[_idx(q.x,q.y)]=GameData.T_DIRT
	for x in MW:
		map[_idx(x,0)]=GameData.T_ROCK
		map[_idx(x,MH-1)]=GameData.T_ROCK
	for y in MH:
		map[_idx(0,y)]=GameData.T_ROCK
		map[_idx(MW-1,y)]=GameData.T_ROCK

func exploration_at(pos: Vector2) -> Dictionary:
	for site in EXPLORATION_SITES:
		if pos.distance_to(Vector2(site.pos)*TILE+Vector2(16,16))<76: return site
	return {}

func safe_outdoor_position(pos: Vector2) -> Vector2:
	if not collides(pos.x,pos.y,12): return pos
	var q:=Vector2i(pos/TILE)
	for radius in range(1,12):
		for dy in range(-radius,radius+1):
			for dx in range(-radius,radius+1):
				var p:=Vector2(q+Vector2i(dx,dy))*TILE+Vector2(16,16)
				if not collides(p.x,p.y,12): return p
	return Vector2(512,1040)

func _carve_road(a: Vector2i, b: Vector2i) -> void:
	var steps := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in steps + 1:
		var tt := float(i) / float(maxi(1, steps))
		var x := int(round(lerpf(float(a.x), float(b.x), tt)))
		var y := int(round(lerpf(float(a.y), float(b.y), tt)))
		for oy in range(0, 2):
			if _in_map(x, y + oy):
				var idx := _idx(x, y + oy)
				if map[idx] == GameData.T_WATER:
					bridge_tiles[idx] = true
				map[idx] = GameData.T_DIRT
				road_tiles[idx] = true


func _idx(x: int, y: int) -> int:
	return y * MW + x


func _in_legacy(x: int, y: int) -> bool:
	return x>=0 and y>=0 and x<80 and y<60


func _in_map(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < MW and y < MH


func tile_at(tx: int, ty: int) -> int:
	if not _in_map(tx, ty):
		return GameData.T_ROCK
	return map[_idx(tx, ty)]


func is_solid_tile(t: int) -> bool:
	return t == GameData.T_WATER or t == GameData.T_ROCK or t == GameData.T_TREE


func collides(x: float, y: float, radius: float) -> bool:
	if in_interior and interior != null:
		return interior.collides_at(Vector2(x,y),radius)
	for h in HOUSE_DATA:
		if destruction.broken("house:"+h.id): continue
		var hp: Vector2 = h.pos
		if Rect2(hp+Vector2(-54,-40),Vector2(108,40)).grow(radius).has_point(Vector2(x,y)):
			return true
	for mountain in MOUNTAINS:
		if destruction.broken("mountain:"+str(MOUNTAINS.find(mountain))): continue
		if mountain_footprint(mountain).grow(radius).has_point(Vector2(x,y)): return true
	for i in 5:
		var px := x
		var py := y
		match i:
			0: px -= radius; py -= radius
			1: px += radius; py -= radius
			2: px -= radius; py += radius
			3: px += radius; py += radius
			_: pass
		var tx := int(floor(px / TILE))
		var ty := int(floor(py / TILE))
		if is_solid_tile(tile_at(tx, ty)):
			return true
		if not destruction.broken("furnace") and Vector2(px, py).distance_squared_to(GameData.FURNACE) < 256.0:
			return true
		if not destruction.broken("bonfire") and Vector2(px, py).distance_squared_to(GameData.BONFIRE) < 196.0:
			return true
	return false


func move_body(body: Node2D, dx: float, dy: float, radius: float) -> void:
	if not collides(body.position.x + dx, body.position.y, radius):
		body.position.x += dx
	if not collides(body.position.x, body.position.y + dy, radius):
		body.position.y += dy


func _draw() -> void:
	var tsec := Time.get_ticks_msec() * 0.001

	if not terrain_chunks.is_empty():
		var view:=Rect2(camera_pos,view_size).grow(TILE)
		for chunk in terrain_chunks.values():
			if view.intersects(chunk.rect): draw_texture(chunk.texture,chunk.rect.position)
	else:
		_draw_tiles_fallback()

	_draw_stations(tsec)


func _draw_tiles_fallback() -> void:
	var x0 := max(0, int(camera_pos.x / TILE) - 1)
	var y0 := max(0, int(camera_pos.y / TILE) - 1)
	var x1 := min(MW - 1, int((camera_pos.x + view_size.x) / TILE) + 1)
	var y1 := min(MH - 1, int((camera_pos.y + view_size.y) / TILE) + 1)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), _tile_color(x, y))


func _bake_textures() -> void:
	var t0 := Time.get_ticks_msec()
	floor_image = load("res://assets/ninja_adventure/tileset_floor.png").get_image()
	for ty in 3:
		for tx in 3:
			var tile := floor_image.get_region(Rect2i(tx*16,112+ty*16,16,16))
			tile.resize(TILE,TILE,Image.INTERPOLATE_NEAREST)
			ground_tiles["%d:%d" % [tx,ty]] = tile
	terrain_chunks.clear()
	for cy in range(0,MH,CHUNK_TILES):
		for cx in range(0,MW,CHUNK_TILES):
			var dimensions:=Vector2i(mini(CHUNK_TILES,MW-cx),mini(CHUNK_TILES,MH-cy))
			var image:=Image.create(dimensions.x*TILE,dimensions.y*TILE,false,Image.FORMAT_RGBA8)
			for y in range(cy,cy+dimensions.y):
				for x in range(cx,cx+dimensions.x): _paint_tile(image,x,y,Vector2i(cx,cy)*TILE)
			var key:=Vector2i(cx/CHUNK_TILES,cy/CHUNK_TILES)
			terrain_chunks[key]={"image":image,"texture":ImageTexture.create_from_image(image),"rect":Rect2(Vector2(cx,cy)*TILE,Vector2(dimensions)*TILE)}
	dirty_chunks.clear()
	var mini := Image.create(MW, MH, false, Image.FORMAT_RGBA8)
	for y in MH:
		for x in MW:
			mini.set_pixel(x, y, _minimap_color(x, y))
	minimap_image=mini
	minimap_texture = ImageTexture.create_from_image(mini)
	print("WORLD bake ms=%d" % (Time.get_ticks_msec() - t0))


func _tile_color(x: int, y: int) -> Color:
	var t := map[_idx(x, y)]
	var v := tile_var[_idx(x, y)]
	var gz := zone_at(Vector2(x * TILE, y * TILE))
	match t:
		GameData.T_GRASS:
			var gc: Color = ZONE_GRASS.get(gz, Color("#203623"))
			return gc.lightened(0.08) if v > 0.5 else gc
		GameData.T_DIRT:
			var dc: Color = ZONE_DIRT.get(gz, Color("#b19364"))
			if road_tiles.has(_idx(x, y)):
				dc = dc.lightened(0.12)
			elif v > 0.5:
				dc = dc.darkened(0.05)
			return dc
		GameData.T_WATER: return Color("#448b8a")
		GameData.T_ROCK: return Color("#2a2f2a")
		GameData.T_TREE: return Color("#1c2c1c")
		GameData.T_FLOWER: return Color("#233a25") if v > 0.5 else Color("#203623")
		GameData.T_RUIN: return Color("#2c2a26")
	return Color("#203623")


func _paint_tile(image: Image, x: int, y: int, origin: Vector2i = Vector2i.ZERO) -> void:
	var p := Vector2i(x*TILE,y*TILE)-origin
	var t := tile_at(x,y)
	var v := tile_var[_idx(x,y)]
	var base := Color("789552")
	var zone := zone_at(Vector2(x*TILE,y*TILE))
	if zone == "marsh": base = Color("647e61")
	if zone == "ruin": base = Color("858b64")
	if zone == "rock": base = Color("8b9063")
	image.fill_rect(Rect2i(p,Vector2i(TILE,TILE)),base.lightened(v*0.035))
	if bridge_tiles.has(_idx(x,y)):
		image.fill_rect(Rect2i(p,Vector2i(TILE,TILE)),Color("554c38"))
		for plank in 4:
			image.fill_rect(Rect2i(p+Vector2i(1,plank*8+1),Vector2i(30,6)),Color("b89a63") if plank%2==0 else Color("a78c5d"))
		if not bridge_tiles.has(_idx(x-1,y)):
			image.fill_rect(Rect2i(p+Vector2i(1,0),Vector2i(3,TILE)),Color("786343"))
		if not bridge_tiles.has(_idx(x+1,y)):
			image.fill_rect(Rect2i(p+Vector2i(28,0),Vector2i(3,TILE)),Color("786343"))
		return
	if t == GameData.T_DIRT or t == GameData.T_RUIN:
		var l := tile_at(x-1,y) == t
		var r := tile_at(x+1,y) == t
		var u := tile_at(x,y-1) == t
		var d := tile_at(x,y+1) == t
		var tx := 1 if l and r else (0 if not l else 2)
		var ty := 1 if u and d else (0 if not u else 2)
		var key := "%d:%d" % [tx,ty]
		image.blend_rect(ground_tiles[key],Rect2i(0,0,TILE,TILE),p)
	elif t == GameData.T_WATER:
		image.fill_rect(Rect2i(p,Vector2i(TILE,TILE)),Color("448b8a"))
		for side in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			if tile_at(x+side.x,y+side.y) != GameData.T_WATER:
				var edge := Rect2i(p,Vector2i(TILE,4))
				if side == Vector2i.DOWN: edge.position.y += TILE-4
				if side == Vector2i.LEFT: edge.size = Vector2i(4,TILE)
				if side == Vector2i.RIGHT:
					edge.size = Vector2i(4,TILE)
					edge.position.x += TILE-4
				image.fill_rect(edge,Color("a1b28a"))
		if v>0.35:
			image.fill_rect(Rect2i(p+Vector2i(6,12+int(v*12)),Vector2i(15,2)),Color("67aba0"))
	else:
		if v>0.42:
			var gx := int(v*29)
			image.fill_rect(Rect2i(p+Vector2i(gx,12),Vector2i(2,5)),base.darkened(0.12))
			image.fill_rect(Rect2i(p+Vector2i(gx+3,10),Vector2i(2,4)),base.lightened(0.12))
		if t == GameData.T_FLOWER:
			image.fill_rect(Rect2i(p+Vector2i(12,14),Vector2i(3,4)),Color("e8d99b"))
			image.fill_rect(Rect2i(p+Vector2i(18,22),Vector2i(3,3)),Color("c6a9c1"))


func _image_circle(image: Image, cx: int, cy: int, r: int, col: Color) -> void:
	for yy in range(-r, r + 1):
		for xx in range(-r, r + 1):
			if xx * xx + yy * yy <= r * r:
				var ix := cx + xx
				var iy := cy + yy
				if ix >= 0 and iy >= 0 and ix < image.get_width() and iy < image.get_height():
					image.set_pixel(ix, iy, col)


func _minimap_color(x: int, y: int) -> Color:
	match map[_idx(x, y)]:
		GameData.T_WATER: return Color("#448b8a")
		GameData.T_ROCK: return Color("#3a3f3a")
		GameData.T_TREE: return Color("#2f5a33")
		GameData.T_DIRT: return Color("#b19364")
		GameData.T_RUIN: return Color("#4a463c")
	return Color("#789552")


func _draw_stations(tsec: float) -> void:
	if not destruction.broken("furnace"):
		# 蛊炉
		var fx := GameData.FURNACE.x
		var fy := GameData.FURNACE.y
		draw_circle(Vector2(fx, fy), 20.0, Color("#4a4a42"))
		draw_circle(Vector2(fx, fy - 2), 15.0, Color("#5c5a50"))
		var glow := 0.6 + sin(tsec * 3.0) * 0.25
		draw_circle(Vector2(fx, fy - 6), 7.0, Color(0.91, 0.40, 0.23, glow))
		draw_string(font, Vector2(fx - 20, fy + 32), "火盆", HORIZONTAL_ALIGNMENT_CENTER, 40, 11, Color("#d9c46a"))
		if player_pos.distance_to(GameData.FURNACE) < 90.0:
			draw_string(font, Vector2(fx - 60, fy - 30), "火盆 · 取暖照明", HORIZONTAL_ALIGNMENT_CENTER, 120, 12, Color("#f0e8d0"))

	if not destruction.broken("bonfire"):
		# 篝火
		var bx := GameData.BONFIRE.x
		var by := GameData.BONFIRE.y
		draw_rect(Rect2(bx - 10, by + 2, 20, 4), Color("#3a2a18"))
		var f := 0.7 + sin(tsec * 8.0) * 0.3
		var points := PackedVector2Array([
			Vector2(bx - 7, by + 2),
			Vector2(bx, by - 22 - f * 6),
			Vector2(bx + 7, by + 2),
		])
		draw_colored_polygon(points, Color(0.91, 0.55, 0.23, f))
		draw_string(font, Vector2(bx - 20, by + 28), "篝火", HORIZONTAL_ALIGNMENT_CENTER, 40, 11, Color("#d9c46a"))
	_draw_landmarks()
	_draw_exploration_sites()


# ------------------------------------------------------------------ 生态分区

func zone_at(pos: Vector2) -> String:
	if Rect2(224,560,640,752).has_point(pos): return "village"
	if pos.distance_to(Vector2(2048,672))<210: return "bai"
	if pos.distance_to(Vector2(1664,1664))<210: return "xiong"
	var tx := int(pos.x / TILE)
	var ty := int(pos.y / TILE)
	if tx>=80:
		if absi(tx-104)<9: return "valley"
		if ty<40: return "ridge"
		return "forest" if ty>90 else "rock"
	if ty>=60: return "south_forest"
	if tx<40: return "forest" if ty<30 else "marsh"
	return "ruin" if ty<30 else "rock"


func zone_name(zone: String) -> String:
	match zone:
		"valley": return "青茅山 · 东麓溪谷"
		"ridge": return "青茅山 · 远山高岭"
		"south_forest": return "青茅山 · 南麓林地"
		"bai": return "白家寨"
		"xiong": return "熊家寨 · 山脚"
		"village": return "古月山寨"
		"forest": return "青茅山 · 青矛竹林"
		"marsh": return "青茅山 · 山腰梯田"
		"ruin": return "青茅山 · 高处山林"
		"rock": return "青茅山 · 岩坡"
	return "青茅山"


func zone_color(zone: String) -> Color:
	match zone:
		"village": return Color("#d9c46a")
		"forest": return Color("#6fbf73")
		"marsh": return Color("#5aa9c9")
		"ruin": return Color("#c9a0ff")
		"rock": return Color("#d9b06a")
	return Color("#d8e6d2")

func _build_props() -> void:
	props = Node2D.new()
	props.name = "VillageAndForest"
	props.y_sort_enabled = true
	get_parent().add_child(props)
	for y in range(1,MH-1):
		for x in range(1,MW-1):
			var t := tile_at(x,y)
			var v := tile_var[_idx(x,y)]
			if t != GameData.T_TREE and t != GameData.T_ROCK: continue
			var prop := WorldProp.new()
			prop.world = self
			prop.position = Vector2(x*TILE+16,y*TILE+26)
			if t == GameData.T_TREE:
				prop.source = Rect2(0,96 if v>0.45 else 144,64,48)
				prop.draw_size = Vector2(112,96) if v>0.45 else Vector2(96,88)
				prop.tint = Color("d3e1bc")
				if v>0.35:
					prop.kind="bamboo"
					prop.draw_size=Vector2(90,128)
			else:
				prop.kind = "rock"
				prop.source = Rect2(144,80,32,32)
				prop.draw_size = Vector2(42,42)
			props.add_child(prop)
			destruction.register("tile:%d:%d"%[x,y],prop.kind,Rect2(x*TILE,y*TILE,TILE,TILE),45.0 if t==GameData.T_TREE else 100.0,1.0 if t==GameData.T_TREE else 2.5,prop,Vector2i(x,y))
	for h in HOUSE_DATA:
		var house := WorldProp.new()
		house.world = self
		house.kind = String(h.get("kind","house"))
		house.title = h.name
		house.position = h.pos
		house.source = Rect2(192 if h.id in ["clinic","home"] else 256,96,64,80 if h.id in ["clinic","home"] else 64)
		house.draw_size = house.source.size*2.5
		props.add_child(house)
		houses.append(house)
		destruction.register("house:"+h.id,"house",Rect2(h.pos+Vector2(-64,-42),Vector2(128,48)),320,1.8,house)
	for config in MOUNTAINS:
		var mountain := WorldProp.new()
		mountain.kind = "mountain"
		mountain.world = self
		mountain.position = config.pos
		mountain.draw_size = config.size
		props.add_child(mountain)
		destruction.register("mountain:"+str(MOUNTAINS.find(config)),"mountain",mountain_footprint(config),900,6.0,mountain)


func house_at(pos: Vector2) -> Dictionary:
	for h in HOUSE_DATA:
		if destruction.broken("house:"+h.id): continue
		if pos.distance_to(h.pos+Vector2(0,20)) < 58:
			return h
	return {}


func interaction_prompt(pos: Vector2) -> String:
	if in_interior and interior != null: return interior.interaction_prompt(pos)
	var h := house_at(pos)
	if not h.is_empty(): return "E  进入%s · %s" % [h.name,h.hint]
	var site:=exploration_at(pos)
	if not site.is_empty(): return "E  探索"+site.name
	return ""


func _draw_landmarks() -> void:
	for lm in LANDMARKS:
		if destruction.broken("landmark:"+lm.type): continue
		var tile: Vector2i = lm["pos"]
		var p := Vector2(tile.x, tile.y) * TILE
		if p.distance_to(camera_pos + view_size * 0.5) > 900.0:
			continue
		var kind: String = lm["type"]
		if player_pos.distance_to(p) < 110.0:
			var act := "探查"
			match kind:
				"garden": act = "查看花田"
				"pond": act = "查看溪瀑"
				"marsh": act = "查看梯田"
				"ruin": act = "查看石缝"
				"gate": act = "查看山门"
			draw_string(font, Vector2(p.x - 60, p.y + 62), "按 E " + act,
				HORIZONTAL_ALIGNMENT_CENTER, 120, 11, Color("#f0e8d0"))
		match kind:
			"gate":
				draw_rect(Rect2(p.x - 34, p.y - 26, 6, 52), Color("#6a5a3a"))
				draw_rect(Rect2(p.x + 28, p.y - 26, 6, 52), Color("#6a5a3a"))
				draw_rect(Rect2(p.x - 34, p.y - 30, 68, 8), Color("#8a7042"))
				draw_string(font, Vector2(p.x - 38, p.y + 44), lm["name"],
					HORIZONTAL_ALIGNMENT_CENTER, 76, 12, Color("#d9c46a"))
			"pond":
				_draw_waterfall(p)
				draw_string(font, p+Vector2(-65,-110), lm.name,HORIZONTAL_ALIGNMENT_CENTER,130,14,Color("bbdcda"))
			"marsh":
				for step in 4:
					var y:=p.y-55+step*28
					var width:=180+step*20
					draw_rect(Rect2(p.x-width/2,y,width,26),Color("6e7450"))
					draw_rect(Rect2(p.x-width/2+5,y+3,width-10,17),Color("6d9678"))
					draw_line(Vector2(p.x-width/2,y+26),Vector2(p.x+width/2,y+26),Color("414a31"),5)
					for stalk in range(10,width-10,12):
						draw_line(Vector2(p.x-width/2+stalk,y+15),Vector2(p.x-width/2+stalk-3,y+7),Color("c2c58c"),2)
				draw_string(font, p+Vector2(-60,-65), lm.name,HORIZONTAL_ALIGNMENT_CENTER,120,14,Color("c1d8a1"))
			"garden":
				draw_rect(Rect2(p.x - 22, p.y - 10, 44, 22), Color(0.35, 0.55, 0.25, 0.55))
				draw_string(font, Vector2(p.x - 34, p.y - 18), lm["name"],
					HORIZONTAL_ALIGNMENT_CENTER, 68, 11, Color("#a8d06a"))
			"ruin":
				draw_rect(Rect2(p.x - 8, p.y - 28, 16, 48), Color("#5c584a"))
				draw_rect(Rect2(p.x - 20, p.y + 12, 40, 10), Color("#4a463c"))
				draw_string(font, Vector2(p.x - 44, p.y - 36), lm["name"],
					HORIZONTAL_ALIGNMENT_CENTER, 88, 11, Color("#c9a0ff"))

func _draw_waterfall(p: Vector2) -> void:
	# 岩壁、水帘、潭面与泡沫分别绘制，溪瀑不再只是地图标记。
	draw_texture_rect(WorldProp.MOUNTAIN,Rect2(p+Vector2(-115,-170),Vector2(230,210)),false)
	for i in 7:
		var x:=p.x-73+i*24
		draw_line(Vector2(x,p.y-55+abs(i-3)*6),Vector2(x-8,p.y+18),Color("3c514b"),10)
	draw_set_transform(p+Vector2(0,42),0,Vector2(1,0.42))
	draw_circle(Vector2.ZERO,76,Color("3c7f88"))
	draw_arc(Vector2.ZERO,64,0,TAU,40,Color("80bcc0"),3)
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(p+Vector2(-30,-85),Vector2(60,126)),Color("79b1bb"))
	draw_rect(Rect2(p+Vector2(-22,-85),Vector2(39,127)),Color("b8dfdd"))
	var phase:=fmod(Time.get_ticks_msec()/35.0,25.0)
	for i in 5:
		var y:=p.y-83+phase+i*25
		draw_line(Vector2(p.x-17,y),Vector2(p.x+15,y+12),Color("e0eecc"),3)
	for i in 9:
		draw_circle(p+Vector2(-37+i*9,35+sin(float(i)*1.8)*6),5,Color("d0e5cf"))

func poi_at(pos: Vector2, radius: float = 100.0) -> Dictionary:
	var best: Dictionary = {}
	var best_d := radius
	for lm in LANDMARKS:
		if destruction.broken("landmark:"+lm.type): continue
		var tile: Vector2i = lm["pos"]
		var p := Vector2(tile.x, tile.y) * TILE
		var d := pos.distance_to(p)
		if d < best_d:
			best_d = d
			best = lm
	return best

func _draw_exploration_sites() -> void:
	for site in EXPLORATION_SITES:
		var p:=Vector2(site.pos)*TILE+Vector2(16,16)
		if not Rect2(camera_pos,view_size).grow(160).has_point(p): continue
		if site.kind=="camp":
			draw_colored_polygon(PackedVector2Array([p+Vector2(-52,4),p+Vector2(0,-66),p+Vector2(52,4)]),Color("b69b67"))
			draw_colored_polygon(PackedVector2Array([p+Vector2(-18,4),p+Vector2(0,-44),p+Vector2(22,4)]),Color("344539"))
		elif site.kind=="timber":
			for i in 4: draw_line(p+Vector2(-28,-i*7),p+Vector2(28,-i*7+5),Color("9f9765"),5)
		elif site.kind=="rubble":
			for i in 4: draw_circle(p+Vector2(-21+i*14,-(i%2)*8),9,Color("a5ac96"))
		else:
			draw_line(p+Vector2(0,8),p+Vector2(0,-35),Color("6d5a40"),5)
			draw_rect(Rect2(p+Vector2(-28,-40),Vector2(56,19)),Color("b99f69"))
		draw_string(font,p+Vector2(-84,30),site.name,HORIZONTAL_ALIGNMENT_CENTER,168,13,UIStyle.GOLD)

func refresh_terrain_tile(tile: Vector2i) -> void:
	var key:=Vector2i(tile.x/CHUNK_TILES,tile.y/CHUNK_TILES)
	if not terrain_chunks.has(key): return
	_paint_tile(terrain_chunks[key].image,tile.x,tile.y,key*CHUNK_TILES*TILE)
	dirty_chunks[key]=true
	minimap_image.set_pixel(tile.x,tile.y,_minimap_color(tile.x,tile.y))

func flush_terrain_changes() -> void:
	if dirty_chunks.is_empty(): return
	for key in dirty_chunks: terrain_chunks[key].texture.update(terrain_chunks[key].image)
	minimap_texture.update(minimap_image)
	dirty_chunks.clear()

func _register_fixtures() -> void:
	destruction.register("furnace","furnace",Rect2(GameData.FURNACE-Vector2(18,18),Vector2(36,36)),240,3.0)
	destruction.register("bonfire","bonfire",Rect2(GameData.BONFIRE-Vector2(14,14),Vector2(28,28)),70,1.0)
	for lm in LANDMARKS:
		var pos: Vector2=Vector2(lm.pos)*TILE
		destruction.register("landmark:"+lm.type,"landmark",Rect2(pos-Vector2(20,20),Vector2(40,40)),180,2.0)
	for house in HOUSE_DATA:
		for id in HouseInterior.FIXTURES:
			if house.id in ["flower_cave","spring_cave"] and not id.begins_with("wall"): continue
			var rect: Rect2=HouseInterior.FIXTURES[id]
			destruction.register("interior:"+house.id+":"+id,"wall" if id.begins_with("wall") else "furniture",Rect2(rect.position+HouseInterior.ORIGIN,rect.size),200.0 if id.begins_with("wall") else 60.0,2.0 if id.begins_with("wall") else 1.0,null,Vector2i(-1,-1),house.id)
