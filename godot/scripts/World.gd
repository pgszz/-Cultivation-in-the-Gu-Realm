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
const MAX_TERRAIN_CHUNKS := 24
var terrain_chunks: Dictionary = {}
var dirty_chunks: Dictionary = {}
var minimap_dirty := false
var terrain_use := 0
var terrain_prefetch: Dictionary = {}
var _terrain_visible: Array[Vector2i] = []
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
var shang: ShangCity
var layer := 0
var environment := EnvironmentInteractions.new()
var blocks: TerrainLayers
var floor_image: Image
var ground_tiles: Dictionary = {}
var terrain_edges: Dictionary = {}
var prop_regions: Dictionary = {}
var active_props: Dictionary = {}
var _prop_view := Rect2()
const PROP_REGION_TILES := 16

static var HOUSE_DATA: Array = [
	{"id":"clinic","name":"古月药堂","pos":Vector2(320,896),"hint":"包扎 / 检查伤势"},
	{"id":"shop","name":"古月商铺","pos":Vector2(704,896),"hint":"月兰花瓣 / 青竹酒"},
	{"id":"home","name":"竹楼居所","pos":Vector2(320,1216),"hint":"休息 / 随身行囊"},
	{"id":"archive","name":"古月学堂","pos":Vector2(704,1216),"hint":"修行常识 / 山志"},
	{"id":"ancestral","name":"宗族祠堂","pos":Vector2(512,672),"hint":"古月一族"},
	SettlementData.HALLS[0],
	SettlementData.HALLS[1],
	{"id":"flower_cave","name":"巨石缝隙","pos":Vector2(1184,288),"hint":"后山密洞","kind":"cave"},
	{"id":"spring_cave","name":"地下溶洞","pos":Vector2(736,608),"hint":"灵泉 / 月兰花海","kind":"cave"},
] + SettlementData.HOUSES

const RELOCATED_SETTLEMENTS := [
	{"old":Vector2(2048,672),"current":GameData.BAI_VILLAGE},
	{"old":Vector2(1664,1664),"current":GameData.XIONG_VILLAGE},
]

# 只迁移旧寨内/门前站位；其他已探索山林仍保持原坐标。
static func migrate_outdoor_position(pos: Vector2, source_version: int) -> Vector2:
	if source_version>=5: return pos
	for settlement in RELOCATED_SETTLEMENTS:
		if Rect2(settlement.old+Vector2(-160,-128),Vector2(320,288)).has_point(pos):
			return settlement.current+(pos-settlement.old)
	return pos

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
	{"pos":Vector2(5600,640),"size":Vector2(460,490)},
	{"pos":Vector2(6800,480),"size":Vector2(540,570)},
	{"pos":Vector2(6200,1800),"size":Vector2(500,530)},
	{"pos":Vector2(7200,3300),"size":Vector2(480,500)},
	{"pos":Vector2(5600,4800),"size":Vector2(520,550)},
	{"pos":Vector2(3100,4400),"size":Vector2(500,540)},
	{"pos":Vector2(1100,4700),"size":Vector2(470,510)},
	{"pos":Vector2(6800,5400),"size":Vector2(540,570)},
	{"pos":Vector2(8200,2200),"size":Vector2(540,570)},
	{"pos":Vector2(9600,3100),"size":Vector2(480,520)},
	{"pos":Vector2(9200,5900),"size":Vector2(560,590)},
	{"pos":Vector2(7000,6900),"size":Vector2(500,550)},
	{"pos":Vector2(4500,6200),"size":Vector2(480,510)},
	{"pos":Vector2(2000,7100),"size":Vector2(510,540)},
	{"pos":Vector2(10400,880),"size":Vector2(620,650)},
	{"pos":Vector2(11900,1420),"size":Vector2(620,640)},
	{"pos":Vector2(13000,2760),"size":Vector2(560,600)},
	{"pos":Vector2(14600,3700),"size":Vector2(610,650)},
	{"pos":Vector2(13200,5260),"size":Vector2(640,680)},
	{"pos":Vector2(11200,6100),"size":Vector2(560,610)},
	{"pos":Vector2(14500,7800),"size":Vector2(600,640)},
	{"pos":Vector2(11500,9300),"size":Vector2(610,650)},
	{"pos":Vector2(9200,10100),"size":Vector2(540,580)},
	{"pos":Vector2(6600,8800),"size":Vector2(620,650)},
	{"pos":Vector2(4100,10100),"size":Vector2(560,600)},
	{"pos":Vector2(1600,8800),"size":Vector2(580,620)},
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
var _last_view_size := Vector2.ZERO


func _ready() -> void:
	font = ThemeDB.fallback_font
	z_index = -20
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	destruction=DestructionSystem.new()
	destruction.world=self
	add_child(destruction)
	generate()
	blocks=TerrainLayers.new()
	blocks.setup(self)
	_bake_textures()
	_build_props()
	_register_fixtures()
	queue_redraw()


func _process(_delta: float) -> void:
	# Camera smoothing can settle while gameplay is paused (menus / screenshot).
	var inverse:=get_viewport().get_canvas_transform().affine_inverse()
	camera_pos=inverse*Vector2.ZERO
	view_size=inverse*get_viewport_rect().size-camera_pos
	_sync_prop_views(Rect2(camera_pos,view_size))
	if on_surface() and visible and not terrain_chunks.is_empty():
		_prefetch_terrain(Rect2(camera_pos,view_size))
	if not environment.cells.is_empty(): queue_redraw()
	if camera_pos.distance_squared_to(_last_camera) > 0.25 or view_size!=_last_view_size:
		_last_camera = camera_pos
		_last_view_size = view_size
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
		var legacy_pos:Vector2=h.pos
		if h.id=="bai": legacy_pos=RELOCATED_SETTLEMENTS[0].old
		elif h.id=="xiong": legacy_pos=RELOCATED_SETTLEMENTS[1].old
		var q:=Vector2i(legacy_pos/TILE)
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
	_extend_frontier()
	_extend_outer_ranges()
	_extend_settlement_routes()
	_build_settlement_grounds()
	_prepare_habitats()
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
	{"id":"east_watch","name":"东岭望山台","pos":Vector2i(178,36),"kind":"lookout","text":"从东岭眺望青茅山腹地，沿山路可继续进入赤松林。"},
	{"id":"red_pine","name":"赤松林口","pos":Vector2i(208,26),"kind":"timber","text":"风折的松枝可以收集为木料，林地南侧有野鹿活动。"},
	{"id":"upper_ford","name":"上游石桥","pos":Vector2i(218,86),"kind":"lookout","text":"石桥连接东岭与南侧山径，溪岸有普通动物留下的足迹。"},
	{"id":"east_camp","name":"东山猎人棚","pos":Vector2i(228,116),"kind":"camp","text":"猎人留下可领取一次的补给；可在棚下包扎与歇脚。"},
	{"id":"south_stone","name":"南荒碎石坡","pos":Vector2i(152,146),"kind":"rubble","text":"南侧荒坡的散石可收集；继续向东是铁背妖熊栖息的深山。"},
	{"id":"reed_camp","name":"芦岸歇脚地","pos":Vector2i(46,150),"kind":"camp","text":"芦苇岸边有一份行路补给，北路可返回南麓竹坡。"},
	{"id":"cloud_pass","name":"云脊垭口","pos":Vector2i(258,30),"kind":"lookout","text":"云脊的低处连接赤松林与东境松台，沿石路可绕开两侧山体。"},
	{"id":"far_pine","name":"东境松台","pos":Vector2i(294,46),"kind":"timber","text":"高地上堆积着风折松枝，可拾取木料，南路通向云溪长桥。"},
	{"id":"cloud_bridge","name":"云溪长桥","pos":Vector2i(274,104),"kind":"lookout","text":"长桥横过云溪，两岸山路通往东山猎人棚和远岭驿棚。"},
	{"id":"far_camp","name":"远岭驿棚","pos":Vector2i(302,142),"kind":"camp","text":"远行者搭起的遮雨棚，留有一份补给，可以停步包扎与打坐。"},
	{"id":"gravel_valley","name":"东南砾谷","pos":Vector2i(266,204),"kind":"rubble","text":"溪水搬运的松散石料聚在谷底，沿岸可向西进入南泽。"},
	{"id":"south_islet","name":"南泽芦洲","pos":Vector2i(188,212),"kind":"lookout","text":"芦洲旁的木桥连通两岸，向西沿古道返回竹林，向北可回南荒。"},
	{"id":"trail_camp","name":"古道行脚营","pos":Vector2i(108,216),"kind":"camp","text":"古道旁设有行脚营，补给仅可领取一次，之后仍可包扎与歇脚。"},
	{"id":"south_grove","name":"南境竹海","pos":Vector2i(36,206),"kind":"timber","text":"竹林间留有宽敞山径，枯竹可以收集；北行可回芦岸歇脚地。"},
	{"id":"switchback_camp","name":"盘山歇脚棚","pos":Vector2i(332,52),"kind":"camp","text":"翻过云脊后的落脚处。东行沿盘山道抵达白家寨，棚下有一份行路补给。"},
	{"id":"white_stream","name":"白溪渡口","pos":Vector2i(354,92),"kind":"lookout","text":"北路通往白家寨，南路绕过山脊下往南泽与熊家寨；两寨之间仍隔着长途山路。"},
	{"id":"east_scree","name":"东崖石坪","pos":Vector2i(412,54),"kind":"rubble","text":"崖下散石可供拾取。西返白家寨，东南可沿鹰回岭继续游历。"},
	{"id":"eagle_pass","name":"鹰回岭","pos":Vector2i(444,142),"kind":"lookout","text":"高岭山路在此折向南方，沿路可经杉林驿棚前往谷底。"},
	{"id":"cedar_station","name":"杉林驿棚","pos":Vector2i(390,206),"kind":"camp","text":"白家至熊家的长路中段，可领取一次补给并包扎歇脚。"},
	{"id":"long_bridge","name":"叠溪长桥","pos":Vector2i(344,256),"kind":"lookout","text":"桥下溪水汇入山脚。向西南经歇脚营下到熊家寨，北路回白溪。"},
	{"id":"foothill_camp","name":"山脚行旅营","pos":Vector2i(278,284),"kind":"camp","text":"靠近熊家寨的行旅营，可领取一份补给；西南继续下行即到寨口。"},
	{"id":"lowland_bamboo","name":"低地竹湾","pos":Vector2i(160,292),"kind":"timber","text":"古月至熊家的南行古道穿过竹湾，可收集枯竹补充木料。"},
	{"id":"south_watch","name":"山脚望溪台","pos":Vector2i(218,336),"kind":"lookout","text":"溪谷地势渐低，东北可返回熊家寨；向西接回低地竹湾的环路。"},
]

func _extend_frontier() -> void:
	# Separate seed and coordinates preserve every tile of the previous interior.
	_rng.seed=20261119
	for y in 180:
		for x in 240:
			if x>=160 or y>=120: tile_var[_idx(x,y)]=_rng.randf()
	for y in range(1,120): map[_idx(159,y)]=GameData.T_GRASS
	for x in range(1,160): map[_idx(x,119)]=GameData.T_GRASS
	for i in 500:
		var q:=Vector2i(_rng.randi_range(4,240-5),_rng.randi_range(4,180-5))
		if q.x<163 and q.y<123: continue
		for j in _rng.randi_range(3,8):
			var p:=q+Vector2i(_rng.randi_range(-2,2),_rng.randi_range(-2,2))
			map[_idx(p.x,p.y)]=GameData.T_TREE if i%4!=0 else GameData.T_ROCK
	for y in range(8,180-8):
		var x:=191+int(sin(y*0.06)*8)
		for offset in range(-2,2): map[_idx(x+offset,y)]=GameData.T_WATER
	for pond in [Vector3i(219,57,6),Vector3i(84,156,7),Vector3i(172,164,6)]:
		for dy in range(-pond.z,pond.z+1):
			for dx in range(-pond.z,pond.z+1):
				if dx*dx+dy*dy<=pond.z*pond.z: map[_idx(pond.x+dx,pond.y+dy)]=GameData.T_WATER
	var routes:Array=[
		[Vector2i(138,18),Vector2i(166,20),Vector2i(178,36),Vector2i(208,26),Vector2i(224,50),Vector2i(218,86),Vector2i(228,116),Vector2i(210,148),Vector2i(192,164),Vector2i(152,146)],
		[Vector2i(145,82),Vector2i(174,82),Vector2i(218,86)],
		[Vector2i(117,104),Vector2i(128,126),Vector2i(152,146)],
		[Vector2i(152,146),Vector2i(118,154),Vector2i(82,142),Vector2i(46,150),Vector2i(24,134),Vector2i(31,108)],
		[Vector2i(46,108),Vector2i(46,150)],
	]
	for route in routes:
		for i in range(route.size()-1): _carve_road(route[i],route[i+1])
	for site in EXPLORATION_SITES:
		if site.pos.x<160 and site.pos.y<120: continue
		if site.pos.x>=240 or site.pos.y>=180: continue
		for dy in range(-2,3):
			for dx in range(-2,3):
				var p:Vector2i=site.pos+Vector2i(dx,dy)
				if tile_at(p.x,p.y)!=GameData.T_WATER: map[_idx(p.x,p.y)]=GameData.T_DIRT
	for x in 240:
		map[_idx(x,0)]=GameData.T_ROCK
		map[_idx(x,179)]=GameData.T_ROCK
	for y in 180:
		map[_idx(0,y)]=GameData.T_ROCK
		map[_idx(239,y)]=GameData.T_ROCK

func _extend_outer_ranges() -> void:
	# Freeze earlier generators at their original dimensions before adding new land.
	_rng.seed=20261120
	for y in 240:
		for x in 320:
			if x>=240 or y>=180: tile_var[_idx(x,y)]=_rng.randf()
	for y in range(1,180): map[_idx(239,y)]=GameData.T_GRASS
	for x in range(1,240): map[_idx(x,179)]=GameData.T_GRASS
	for i in 760:
		var q:=Vector2i(_rng.randi_range(4,320-5),_rng.randi_range(4,240-5))
		if q.x<243 and q.y<183: continue
		for j in _rng.randi_range(3,9):
			var p:=q+Vector2i(_rng.randi_range(-2,2),_rng.randi_range(-2,2))
			map[_idx(p.x,p.y)]=GameData.T_TREE if i%4!=0 else GameData.T_ROCK
	for y in range(12,226):
		var x:=274+int(sin(y*0.065)*8)
		for offset in range(-2,3): map[_idx(x+offset,y)]=GameData.T_WATER
	for x in range(62,272):
		var y:=204+int(sin(x*0.045)*9)
		for offset in range(-2,2): map[_idx(x,y+offset)]=GameData.T_WATER
	for pond in [Vector3i(298,82,7),Vector3i(222,222,6),Vector3i(62,193,6)]:
		for dy in range(-pond.z,pond.z+1):
			for dx in range(-pond.z,pond.z+1):
				if dx*dx+dy*dy<=pond.z*pond.z: map[_idx(pond.x+dx,pond.y+dy)]=GameData.T_WATER
	var routes:Array=[
		[Vector2i(208,26),Vector2i(246,20),Vector2i(258,30),Vector2i(294,46),Vector2i(306,68),Vector2i(304,96),Vector2i(274,104),Vector2i(302,142),Vector2i(296,180),Vector2i(266,204)],
		[Vector2i(228,116),Vector2i(246,122),Vector2i(274,104)],
		[Vector2i(266,204),Vector2i(246,222),Vector2i(230,232),Vector2i(188,212),Vector2i(148,226),Vector2i(108,216),Vector2i(68,224),Vector2i(36,206),Vector2i(24,172),Vector2i(46,150)],
		[Vector2i(152,146),Vector2i(142,176),Vector2i(156,194),Vector2i(188,212)],
		[Vector2i(192,164),Vector2i(228,182),Vector2i(266,204)],
	]
	for route in routes:
		for i in range(route.size()-1): _carve_road(route[i],route[i+1])
	for site in EXPLORATION_SITES:
		if site.pos.x<240 and site.pos.y<180: continue
		if site.pos.x>=320 or site.pos.y>=240: continue
		for dy in range(-2,3):
			for dx in range(-2,3):
				var p:Vector2i=site.pos+Vector2i(dx,dy)
				if tile_at(p.x,p.y)!=GameData.T_WATER: map[_idx(p.x,p.y)]=GameData.T_DIRT
	for x in 320:
		map[_idx(x,0)]=GameData.T_ROCK
		map[_idx(x,239)]=GameData.T_ROCK
	for y in 240:
		map[_idx(0,y)]=GameData.T_ROCK
		map[_idx(319,y)]=GameData.T_ROCK

func _extend_settlement_routes() -> void:
	_rng.seed=20261121
	for y in MH:
		for x in MW:
			if x>=320 or y>=240: tile_var[_idx(x,y)]=_rng.randf()
	for y in range(1,240): map[_idx(319,y)]=GameData.T_GRASS
	for x in range(1,320): map[_idx(x,239)]=GameData.T_GRASS
	for i in 2100:
		var q:=Vector2i(_rng.randi_range(4,MW-5),_rng.randi_range(4,MH-5))
		if q.x<323 and q.y<243: continue
		for j in _rng.randi_range(4,10):
			var p:=q+Vector2i(_rng.randi_range(-2,2),_rng.randi_range(-2,2))
			map[_idx(p.x,p.y)]=GameData.T_TREE if i%5!=0 else GameData.T_ROCK
	for y in range(18,330):
		var x:=338+int(sin(y*0.035)*12)
		for offset in range(-2,3): map[_idx(x+offset,y)]=GameData.T_WATER
	for x in range(80,430):
		var y:=270+int(sin(x*0.028)*12)
		for offset in range(-2,3): map[_idx(x,y+offset)]=GameData.T_WATER
	for pond in [Vector3i(394,122,10),Vector3i(444,244,12),Vector3i(110,326,9),Vector3i(292,328,8)]:
		for dy in range(-pond.z,pond.z+1):
			for dx in range(-pond.z,pond.z+1):
				if dx*dx+dy*dy<=pond.z*pond.z: map[_idx(pond.x+dx,pond.y+dy)]=GameData.T_WATER
	# Curving inter-village roads connect the earlier exploration network to both new gates.
	var routes:Array=[
		[Vector2i(294,46),Vector2i(318,40),Vector2i(332,52),Vector2i(344,72),Vector2i(360,66)],
		[Vector2i(360,66),Vector2i(380,46),Vector2i(412,54),Vector2i(446,90),Vector2i(444,142)],
		[Vector2i(360,66),Vector2i(354,92),Vector2i(380,106),Vector2i(414,120),Vector2i(444,142)],
		[Vector2i(302,142),Vector2i(326,132),Vector2i(354,92)],
		[Vector2i(444,142),Vector2i(416,178),Vector2i(390,206),Vector2i(370,230),Vector2i(344,256),Vector2i(308,272),Vector2i(278,284),Vector2i(266,300),Vector2i(248,306)],
		[Vector2i(390,206),Vector2i(422,220),Vector2i(430,264),Vector2i(392,294),Vector2i(344,256)],
		[Vector2i(266,204),Vector2i(290,224),Vector2i(314,242),Vector2i(344,256)],
		[Vector2i(188,212),Vector2i(212,240),Vector2i(228,266),Vector2i(248,306)],
		[Vector2i(108,216),Vector2i(128,242),Vector2i(142,266),Vector2i(160,292),Vector2i(202,306),Vector2i(248,306)],
		[Vector2i(36,206),Vector2i(58,244),Vector2i(88,260),Vector2i(118,286),Vector2i(160,292)],
		[Vector2i(160,292),Vector2i(180,324),Vector2i(218,336),Vector2i(240,326),Vector2i(248,306)],
	]
	for route in routes:
		for i in range(route.size()-1): _carve_road(route[i],route[i+1])
	for site in EXPLORATION_SITES.slice(23):
		for dy in range(-2,3):
			for dx in range(-2,3):
				var p:Vector2i=site.pos+Vector2i(dx,dy)
				if tile_at(p.x,p.y)!=GameData.T_WATER: map[_idx(p.x,p.y)]=GameData.T_DIRT
	for settlement in RELOCATED_SETTLEMENTS:
		var q:=Vector2i(settlement.current/TILE)
		for dy in range(-5,6):
			for dx in range(-7,8):
				map[_idx(q.x+dx,q.y+dy)]=GameData.T_DIRT
		_carve_road(q+Vector2i(-7,2),q+Vector2i(7,2))
	for x in MW:
		map[_idx(x,0)]=GameData.T_ROCK
		map[_idx(x,MH-1)]=GameData.T_ROCK
	for y in MH:
		map[_idx(0,y)]=GameData.T_ROCK
		map[_idx(MW-1,y)]=GameData.T_ROCK

func _extend_wilderness() -> void:
	_rng.seed=20261118
	for y in 120:
		for x in 160:
			if x>=80 or y>=60: tile_var[_idx(x,y)]=_rng.randf()
	# Remove former east/south borders; old interior coordinates stay unchanged.
	for y in range(1,60): map[_idx(79,y)]=GameData.T_GRASS
	for x in range(1,80): map[_idx(x,59)]=GameData.T_GRASS
	for i in 380:
		var q:=Vector2i(_rng.randi_range(4,160-5),_rng.randi_range(4,120-5))
		if q.x<83 and q.y<63: continue
		var kind:=GameData.T_TREE if i%4!=0 else GameData.T_ROCK
		for j in _rng.randi_range(3,9):
			var t:=q+Vector2i(_rng.randi_range(-2,2),_rng.randi_range(-2,2))
			map[_idx(t.x,t.y)]=kind
	for y in range(5,120-5):
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
		if site.pos.x>=160 or site.pos.y>=120: continue
		for dy in range(-2,3):
			for dx in range(-2,3):
				var q:Vector2i=site.pos+Vector2i(dx,dy)
				if tile_at(q.x,q.y)!=GameData.T_WATER: map[_idx(q.x,q.y)]=GameData.T_DIRT
	for x in 160:
		map[_idx(x,0)]=GameData.T_ROCK
		map[_idx(x,120-1)]=GameData.T_ROCK
	for y in 120:
		map[_idx(0,y)]=GameData.T_ROCK
		map[_idx(160-1,y)]=GameData.T_ROCK

func _build_settlement_grounds() -> void:
	# Public underground entrances connect to existing trails before props are built.
	for entrance in TerrainLayers.ENTRANCES:
		var tile:=Vector2i(entrance.pos/TILE)
		var nearest:=tile
		var best:=INF
		for index in road_tiles:
			var cell:=Vector2i(int(index)%MW,int(index)/MW)
			var distance:=Vector2(cell-tile).length_squared()
			if distance<best: best=distance; nearest=cell
		_carve_road(nearest,tile)
		for dy in range(-2,3):
			for dx in range(-2,3): map[_idx(tile.x+dx,tile.y+dy)]=GameData.T_DIRT
	for district in SettlementData.DISTRICTS:
		var base:=Vector2i(district.pos/TILE)
		# Two parallel streets bypass the hall, with cross lanes and a south gate.
		for x in [-5,5]: _carve_road(base+Vector2i(x,-13),base+Vector2i(x,25))
		for y in [-13,-8,2,12,21,25]: _carve_road(base+Vector2i(-15,y),base+Vector2i(15,y))
		_carve_road(base+Vector2i(0,21),base+Vector2i(0,28))
		for house in HOUSE_DATA:
			if house.get("clan","")!=district.id: continue
			var tile:=Vector2i(house.pos/TILE)
			for y in range(tile.y-5,tile.y+3):
				for x in range(tile.x-4,tile.x+5):
					map[_idx(x,y)]=GameData.T_DIRT
					bridge_tiles.erase(_idx(x,y))
			var lane:=base+Vector2i(-5 if tile.x<base.x else 5,tile.y-base.y+2)
			_carve_road(tile+Vector2i(0,2),lane)
		# Small kitchen gardens and a courtyard make inhabited land distinct from wilderness.
		for y in range(17,23):
			for x in range(8,14):
				var p:=base+Vector2i(x,y)
				if not road_tiles.has(_idx(p.x,p.y)): map[_idx(p.x,p.y)]=GameData.T_FLOWER if y%2==0 else GameData.T_DIRT
	for person in SettlementData.PEOPLE:
		var tile:=Vector2i(person.pos/TILE)
		for dy in range(-1,2):
			for dx in range(-1,2): map[_idx(tile.x+dx,tile.y+dy)]=GameData.T_DIRT

func _prepare_habitats() -> void:
	# Small den clearings and approaches make each marked habitat reachable.
	var existing_roads:Array=road_tiles.keys()
	for habitat in WildlifeSystem.HABITATS:
		var home_tile:Vector2i=habitat.tile
		var nearest:=home_tile
		var best:=INF
		for index in existing_roads:
			var point:=Vector2i(int(index)%MW,int(index)/MW)
			var distance:=Vector2(point-home_tile).length_squared()
			if distance<best:
				best=distance
				nearest=point
		_carve_road(nearest,home_tile)
		for y in range(home_tile.y-1,home_tile.y+2):
			for x in range(home_tile.x-1,home_tile.x+2):
				if tile_at(x,y)!=GameData.T_WATER: map[_idx(x,y)]=GameData.T_GRASS


func exploration_at(pos: Vector2) -> Dictionary:
	if not on_surface(): return {}
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
	if layer>0:
		var kind:=blocks.kind_at(Vector2i(tx,ty),layer)
		return GameData.T_WATER if kind==2 else (GameData.T_ROCK if kind in [1,3,4] else GameData.T_DIRT)
	if not _in_map(tx, ty):
		return GameData.T_ROCK
	return map[_idx(tx, ty)]


func is_solid_tile(t: int) -> bool:
	return t == GameData.T_WATER or t == GameData.T_ROCK or t == GameData.T_TREE


func collides(x: float, y: float, radius: float, allow_water: bool = false) -> bool:
	if shang!=null and shang.active: return shang.collides(Vector2(x,y),radius)
	if in_interior and interior != null:
		return interior.collides_at(Vector2(x,y),radius)
	if layer>0:
		for offset in [Vector2.ZERO,Vector2(-radius,-radius),Vector2(radius,-radius),Vector2(-radius,radius),Vector2(radius,radius)]:
			var cell:=TerrainLayers.cell_at(Vector2(x,y)+offset)
			if not blocks.valid(cell,layer): return true
			if blocks.solid(cell,layer) and not (allow_water and blocks.kind_at(cell,layer)==2): return true
		return false
	for h in HOUSE_DATA:
		if destruction.broken("house:"+h.id): continue
		var hp: Vector2 = h.pos
		if Rect2(hp+Vector2(-54,-40),Vector2(108,40)).grow(radius).has_point(Vector2(x,y)):
			return true
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
		if not _in_map(tx,ty): return true
		if is_solid_tile(tile_at(tx, ty)) and not (allow_water and tile_at(tx,ty)==GameData.T_WATER):
			return true
		if not destruction.broken("furnace") and Vector2(px, py).distance_squared_to(GameData.FURNACE) < 256.0:
			return true
		if not destruction.broken("bonfire") and Vector2(px, py).distance_squared_to(GameData.BONFIRE) < 196.0:
			return true
	return false


func move_body(body: Node2D, dx: float, dy: float, radius: float) -> void:
	# Keep collision sampling shorter than the body radius, including low FPS dashes.
	var steps:=maxi(1,ceili(maxf(absf(dx),absf(dy))/maxf(4.0,radius*0.5)))
	var step:=Vector2(dx,dy)/steps
	for i in steps:
		if not collides(body.position.x + step.x, body.position.y, radius, body is Player):
			body.position.x += step.x
		if not collides(body.position.x, body.position.y + step.y, radius, body is Player):
			body.position.y += step.y

func water_at(pos: Vector2) -> bool:
	if shang!=null and shang.active: return false
	if in_interior: return false
	var cell:=TerrainLayers.cell_at(pos)
	return blocks.valid(cell,layer) and tile_at(cell.x,cell.y)==GameData.T_WATER

func swimming_at(pos: Vector2) -> bool:
	return water_at(pos) and not environment.frozen(TerrainLayers.cell_at(pos),layer)

func water_speed(pos: Vector2) -> float:
	if not water_at(pos): return 1.0
	if not swimming_at(pos): return 0.9
	for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		if not water_at(pos+direction*32): return 0.7
	return 0.5

func on_surface() -> bool:
	return layer==0 and not in_interior and not (shang!=null and shang.active)

func map_texture(map_layer: int) -> Texture2D:
	return minimap_texture if map_layer==0 else blocks.minimaps[map_layer]

func attack_obstacle(pos: Vector2, attack_height: int = 0, radius: float = 0) -> Dictionary:
	if shang!=null and shang.active: return shang.obstacle(pos,radius)
	if in_interior:
		for id in HouseInterior.FIXTURES:
			var full_id:String="interior:"+interior.house_id+":"+id
			if not destruction.objects.has(full_id) or destruction.broken(full_id): continue
			if Rect2(destruction.objects[full_id].rect).grow(radius).has_point(pos): return {"id":full_id,"pos":pos,"block":false}
		return {}
	if layer==0:
		for house in HOUSE_DATA:
			var id:String="house:"+house.id
			if not destruction.broken(id) and Rect2(destruction.objects[id].rect).grow(radius).has_point(pos): return {"id":id,"pos":pos,"block":false}
	for offset in [Vector2.ZERO,Vector2(-radius,-radius),Vector2(radius,-radius),Vector2(-radius,radius),Vector2(radius,radius)]:
		var cell:=TerrainLayers.cell_at(pos+offset)
		if not blocks.valid(cell,layer): return {"id":"boundary","pos":pos,"block":false}
		if layer>0 and blocks.kind_at(cell,layer) in [1,3,4]: return {"id":blocks.key(cell,layer),"cell":cell,"pos":pos,"block":true}
		if layer==0:
			var tile_id:="tile:%d:%d"%[cell.x,cell.y]
			if destruction.objects.has(tile_id) and not destruction.broken(tile_id): return {"id":tile_id,"pos":pos,"block":false}
			if blocks.height_at(cell)>attack_height: return {"id":blocks.key(cell,0,blocks.height_at(cell)),"cell":cell,"pos":pos,"block":true}
	if layer==0:
		for id in ["bonfire","furnace"]:
			if destruction.objects.has(id) and not destruction.broken(id) and Rect2(destruction.objects[id].rect).grow(radius).has_point(pos): return {"id":id,"pos":pos,"block":false}
	return {}

func attack_trace(from: Vector2, to: Vector2, radius: float = 0) -> Dictionary:
	var steps:=maxi(1,ceili(from.distance_to(to)/4.0))
	var height:=blocks.height_at(TerrainLayers.cell_at(from)) if on_surface() else 0
	for i in range(1,steps+1):
		var point:=from.lerp(to,float(i)/steps)
		var obstacle:=attack_obstacle(point,height,radius)
		if not obstacle.is_empty(): return obstacle
	return {}

func conversation_clear(from: Vector2, to: Vector2) -> bool:
	# Climbable hill tiers do not silence nearby people; walls and solid props do.
	var steps:=maxi(1,ceili(from.distance_to(to)/4.0))
	for i in range(1,steps):
		var point:=from.lerp(to,float(i)/steps)
		if collides(point.x,point.y,0,true): return false
	return true

func attack_clear(from: Vector2, to: Vector2, target_id: String = "") -> bool:
	var obstacle:=attack_trace(from,to)
	return obstacle.is_empty() or obstacle.id==target_id

func aimed_block(from: Vector2, target: Vector2, reach: float = 80) -> Dictionary:
	if shang!=null and shang.active: return {}
	if in_interior: return {}
	var delta:=target-from
	var end:=from+delta.limit_length(reach)
	var obstacle:=attack_trace(from,end)
	if not obstacle.is_empty():
		return blocks.info(obstacle.cell,layer) if obstacle.block else {}
	return blocks.info(TerrainLayers.cell_at(end),layer)

func safe_position(pos: Vector2, allow_water: bool = false) -> Vector2:
	if allow_water and pos.is_finite() and not collides(pos.x,pos.y,12,true): return pos
	if layer==0: return safe_outdoor_position(pos)
	if not pos.is_finite(): pos=Vector2(592,592)
	pos=pos.clamp(Vector2(16,16),TerrainLayers.extent(layer)-Vector2(16,16))
	var start:=TerrainLayers.cell_at(pos)
	if not collides(pos.x,pos.y,12): return pos
	for radius in range(1,128):
		for y in range(-radius,radius+1):
			for x in range(-radius,radius+1):
				if absi(x)!=radius and absi(y)!=radius: continue
				var p:=TerrainLayers.center(start+Vector2i(x,y))
				if not collides(p.x,p.y,12): return p
	return Vector2(592,592)


func _draw() -> void:
	if layer>0:
		draw_rect(Rect2(camera_pos,view_size),Color("10171b"))
		blocks.draw(self,Rect2(camera_pos,view_size),layer)
		environment.draw(self,get_parent(),Rect2(camera_pos,view_size))
		return
	var tsec := Time.get_ticks_msec() * 0.001
	if not ground_tiles.is_empty():
		for key in _ensure_terrain(Rect2(camera_pos,view_size).grow(TILE)):
			var chunk:Dictionary=terrain_chunks[key]
			draw_texture(chunk.texture,chunk.rect.position)
	else:
		_draw_tiles_fallback()

	_draw_stations(tsec)
	if blocks!=null: blocks.draw(self,Rect2(camera_pos,view_size),0)
	environment.draw(self,get_parent(),Rect2(camera_pos,view_size))


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
	if ground_tiles.is_empty():
		floor_image=PaintedArt.TERRAIN.get_image()
		floor_image.convert(Image.FORMAT_RGBA8)
		for i in 6:
			var material_tile:=floor_image.get_region(Rect2i((i%3)*512,(i/3)*512,512,512))
			material_tile.resize(128,128,Image.INTERPOLATE_LANCZOS)
			ground_tiles[i]=material_tile
		for i in 7:
			var texture:Texture2D=load("res://assets/shang_city/"+["paving","earth","courtyard","meadow","forest","moss","gravel"][i]+".png")
			var surface:=texture.get_image()
			surface.convert(Image.FORMAT_RGBA8)
			surface.resize(256,256,Image.INTERPOLATE_LANCZOS)
			ground_tiles[6+i]=surface
	terrain_chunks.clear()
	terrain_prefetch.clear()
	_terrain_visible.clear()
	dirty_chunks.clear()
	minimap_dirty=false
	var mini := Image.create(MW, MH, false, Image.FORMAT_RGBA8)
	for y in MH:
		for x in MW:
			mini.set_pixel(x, y, _minimap_color(x, y))
	minimap_image=mini
	minimap_texture = ImageTexture.create_from_image(mini)
	queue_redraw()
	print("WORLD minimap ms=%d; terrain cache limit=%d" % [Time.get_ticks_msec()-t0,MAX_TERRAIN_CHUNKS])

func _ensure_terrain(view: Rect2) -> Array[Vector2i]:
	var visible_keys:Array[Vector2i]=[]
	var span:=CHUNK_TILES*TILE
	var columns:=ceili(float(MW)/CHUNK_TILES)
	var rows:=ceili(float(MH)/CHUNK_TILES)
	for y in range(clampi(floori(view.position.y/span),0,rows),clampi(ceili(view.end.y/span),0,rows)):
		for x in range(clampi(floori(view.position.x/span),0,columns),clampi(ceili(view.end.x/span),0,columns)):
			var key:=Vector2i(x,y)
			visible_keys.append(key)
			if not terrain_chunks.has(key): _bake_chunk(key)
			terrain_use+=1
			terrain_chunks[key].used=terrain_use
	_terrain_visible=visible_keys
	_trim_terrain(visible_keys)
	return visible_keys

func _trim_terrain(visible_keys: Array[Vector2i]) -> void:
	# Keep the current viewport and a bounded number of recently visited chunks.
	while terrain_chunks.size()>maxi(MAX_TERRAIN_CHUNKS,visible_keys.size()):
		var oldest:=Vector2i(-1,-1)
		var stamp:=terrain_use+1
		for key in terrain_chunks:
			if not visible_keys.has(key) and int(terrain_chunks[key].used)<stamp:
				stamp=int(terrain_chunks[key].used)
				oldest=key
		if oldest.x<0: break
		terrain_chunks.erase(oldest)
		dirty_chunks.erase(oldest)

func _bake_chunk(key: Vector2i) -> void:
	var job:Dictionary=terrain_prefetch.get(key,{})
	if job.is_empty(): job=_terrain_job(key)
	while job.next<job.count: _paint_chunk_step(job)
	_finish_chunk(key,job)

func _terrain_job(key: Vector2i) -> Dictionary:
	var origin:=key*CHUNK_TILES
	var dimensions:=Vector2i(mini(CHUNK_TILES,MW-origin.x),mini(CHUNK_TILES,MH-origin.y))
	var image:=Image.create(dimensions.x*TILE,dimensions.y*TILE,false,Image.FORMAT_RGBA8)
	return {"origin":origin,"dimensions":dimensions,"image":image,"next":0,"count":dimensions.x*dimensions.y}

func _paint_chunk_step(job: Dictionary) -> void:
	var index:int=job.next
	_paint_tile(job.image,job.origin.x+index%job.dimensions.x,job.origin.y+index/job.dimensions.x,job.origin*TILE)
	job.next+=1

func _finish_chunk(key: Vector2i, job: Dictionary) -> void:
	terrain_use+=1
	terrain_chunks[key]={"image":job.image,"texture":ImageTexture.create_from_image(job.image),"rect":Rect2(Vector2(job.origin)*TILE,Vector2(job.dimensions)*TILE),"used":terrain_use}
	terrain_prefetch.erase(key)

func _prefetch_terrain(view: Rect2) -> void:
	# Idle time prepares the next 512 px of travel. Do at most ~2 ms of tile
	# painting per frame; a newly visible chunk can finish its partial job.
	var ahead:=view.grow(512)
	var span:=CHUNK_TILES*TILE
	var wanted:Array[Vector2i]=[]
	for y in range(maxi(0,floori(ahead.position.y/span)),mini(ceili(float(MH)/CHUNK_TILES),ceili(ahead.end.y/span))):
		for x in range(maxi(0,floori(ahead.position.x/span)),mini(ceili(float(MW)/CHUNK_TILES),ceili(ahead.end.x/span))):
			var key:=Vector2i(x,y)
			if not _terrain_visible.has(key): wanted.append(key)
	wanted.sort_custom(func(a:Vector2i,b:Vector2i): return (Vector2(a)*span+Vector2.ONE*span*0.5).distance_squared_to(view.get_center())<(Vector2(b)*span+Vector2.ONE*span*0.5).distance_squared_to(view.get_center()))
	# Wide/high-resolution views must not continually prefetch and evict the
	# same neighbours when all slots are occupied by the visible ground.
	wanted.resize(mini(wanted.size(),maxi(0,MAX_TERRAIN_CHUNKS-_terrain_visible.size())))
	wanted=wanted.filter(func(key:Vector2i): return not terrain_chunks.has(key))
	for key:Vector2i in terrain_prefetch.keys():
		if not wanted.has(key): terrain_prefetch.erase(key)
	if wanted.is_empty(): return
	var key:Vector2i=wanted[0]
	if not terrain_prefetch.has(key): terrain_prefetch[key]=_terrain_job(key)
	var job:Dictionary=terrain_prefetch[key]
	var deadline:=Time.get_ticks_usec()+2000
	while job.next<job.count and Time.get_ticks_usec()<deadline: _paint_chunk_step(job)
	if job.next==job.count:
		_finish_chunk(key,job)
		_trim_terrain(_terrain_visible)


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
	var p:=Vector2i(x*TILE,y*TILE)-origin
	var t:=tile_at(x,y)
	var cell:=Rect2i((x%8)*TILE,(y%8)*TILE,TILE,TILE)
	image.blit_rect(ground_tiles[9],cell,p)
	var base:=_natural_ground_material(x,y)
	if base!=9:
		var base_edges:=0
		for i in 4:
			var side:Vector2i=[Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN][i]
			if _natural_ground_material(x+side.x,y+side.y)!=base: base_edges|=1<<i
		_blend_ground_tile(image,p,x,y,base,base_edges)
	if bridge_tiles.has(_idx(x,y)):
		image.fill_rect(Rect2i(p,Vector2i(TILE,TILE)),Color("554c38"))
		for plank in 4:
			image.fill_rect(Rect2i(p+Vector2i(1,plank*8+1),Vector2i(30,6)),Color("b89a63") if plank%2==0 else Color("a78c5d"))
		if not bridge_tiles.has(_idx(x-1,y)):
			image.fill_rect(Rect2i(p+Vector2i(1,0),Vector2i(3,TILE)),Color("786343"))
		if not bridge_tiles.has(_idx(x+1,y)):
			image.fill_rect(Rect2i(p+Vector2i(28,0),Vector2i(3,TILE)),Color("786343"))
		return
	var material_index:=0
	match t:
		GameData.T_DIRT: material_index=1
		GameData.T_WATER: material_index=2
		GameData.T_ROCK,GameData.T_RUIN: material_index=3
		GameData.T_TREE: material_index=10
	if t==GameData.T_DIRT:
		var zone:=zone_at(Vector2(x*TILE,y*TILE))
		material_index=6 if zone in ["village","bai"] else (8 if zone=="xiong" else 7)
	elif t==GameData.T_RUIN: material_index=8
	if material_index>0:
		var edges:=0
		for i in 4:
			var side: Vector2i=[Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN][i]
			if tile_at(x+side.x,y+side.y)!=t: edges|=1<<i
		var strength:=1.0
		if material_index==7: strength=0.72 if road_tiles.has(_idx(x,y)) else 0.38
		_blend_ground_tile(image,p,x,y,material_index,edges,strength)
	if t==GameData.T_FLOWER:
		_image_circle(image,p.x+12,p.y+15,2,Color("dfce9f"))
		_image_circle(image,p.x+22,p.y+23,2,Color("bda9d0"))


func _natural_ground_material(x: int, y: int) -> int:
	# Surface art only; geology, walkability and the saved map remain authoritative.
	for side in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		if tile_at(x+side.x,y+side.y)==GameData.T_WATER: return 12
	var zone:=zone_at(Vector2(x*TILE,y*TILE))
	if zone in ["marsh","southern_marsh","valley"]: return 11
	if zone in ["forest","south_forest","east_frontier"]: return 10
	if zone in ["rock","ridge","outer_ridge","cloud_range"]: return 12
	return 9


func _blend_ground_tile(image: Image, p: Vector2i, x: int, y: int, material_index: int, edges: int, strength: float = 1.0) -> void:
	var repeat_size:=8 if material_index>=6 else 4
	var cell:=Rect2i(posmod(x,repeat_size)*TILE,posmod(y,repeat_size)*TILE,TILE,TILE)
	var key:="%d:%d:%d:%d:%d"%[material_index,posmod(x,repeat_size),posmod(y,repeat_size),edges,roundi(strength*100)]
	if not terrain_edges.has(key):
		var tile:Image=ground_tiles[material_index].get_region(cell)
		if edges>0 or strength<1:
			for yy in TILE:
				for xx in TILE:
					var fade:=1.0
					# Feather both axes at corners and vary the rim to soften the tile grid.
					var rim:=(10.0 if material_index in [7,10,11,12] else 5.0)+sin(float(xx+yy)*0.7)*1.5
					if edges&1: fade*=smoothstep(0.0,rim,float(xx))
					if edges&2: fade*=smoothstep(0.0,rim,float(TILE-1-xx))
					if edges&4: fade*=smoothstep(0.0,rim,float(yy))
					if edges&8: fade*=smoothstep(0.0,rim,float(TILE-1-yy))
					var color:=tile.get_pixel(xx,yy)
					color.a=fade*strength
					tile.set_pixel(xx,yy,color)
		terrain_edges[key]=tile
	image.blend_rect(terrain_edges[key],Rect2i(0,0,TILE,TILE),p)


func _image_circle(image: Image, cx: int, cy: int, r: int, col: Color) -> void:
	for yy in range(-r, r + 1):
		for xx in range(-r, r + 1):
			if xx * xx + yy * yy <= r * r:
				var ix := cx + xx
				var iy := cy + yy
				if ix >= 0 and iy >= 0 and ix < image.get_width() and iy < image.get_height():
					image.set_pixel(ix, iy, col)


func _minimap_color(x: int, y: int) -> Color:
	if blocks!=null and blocks.height_at(Vector2i(x,y))!=0: return blocks.color_at(Vector2i(x,y),0)
	match map[_idx(x, y)]:
		GameData.T_WATER: return Color("#448b8a")
		GameData.T_ROCK: return Color("#3a3f3a")
		GameData.T_TREE: return Color("#2f5a33")
		GameData.T_DIRT: return Color("#b19364")
		GameData.T_RUIN: return Color("#4a463c")
	return Color("#789552")


func _draw_stations(tsec: float) -> void:
	var view:=Rect2(camera_pos,view_size).grow(100)
	if view.has_point(GameData.FURNACE) and not destruction.broken("furnace"):
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

	if view.has_point(GameData.BONFIRE) and not destruction.broken("bonfire"):
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
	_draw_settlements()

func _draw_settlements() -> void:
	for district in SettlementData.DISTRICTS:
		if not Rect2(camera_pos,view_size).grow(160).intersects(district.bounds): continue
		var gate:Vector2=district.pos+Vector2(0,768)
		var color:Color=district.color
		for x in [-76,76]:
			draw_line(gate+Vector2(x,12),gate+Vector2(x,-84),Color("675742"),9)
			draw_rect(Rect2(gate+Vector2(x-12,-72),Vector2(24,46)),color.darkened(0.2))
		draw_line(gate+Vector2(-86,-84),gate+Vector2(86,-84),Color("8f7753"),13)
		draw_string(font,gate+Vector2(-80,-96),district.name+" · 寨口",HORIZONTAL_ALIGNMENT_CENTER,160,18,color)
		for offset in [Vector2(-160,160),Vector2(160,480)]:
			var p:Vector2=district.pos+offset
			draw_line(p,p+Vector2(0,-64),Color("6d5a40"),4)
			draw_rect(Rect2(p+Vector2(-17,-64),Vector2(34,38)),color)
			draw_string(font,p+Vector2(-15,-40),"白" if district.id=="bai" else "熊",HORIZONTAL_ALIGNMENT_CENTER,30,16,Color("263c38"))


# ------------------------------------------------------------------ 生态分区

func zone_at(pos: Vector2) -> String:
	if layer>0: return "underground_"+str(layer)
	if Rect2(224,560,640,752).has_point(pos): return "village"
	for district in SettlementData.DISTRICTS:
		if district.bounds.has_point(pos): return district.id
	var tx := int(pos.x / TILE)
	var ty := int(pos.y / TILE)
	if ty>=240: return "foothills"
	if tx>=320: return "outer_ridge"
	if tx>=240: return "cloud_range"
	if ty>=180: return "southern_marsh"
	if tx>=160: return "east_frontier"
	if ty>=120: return "south_frontier"
	if tx>=80:
		if absi(tx-104)<9: return "valley"
		if ty<40: return "ridge"
		return "forest" if ty>90 else "rock"
	if ty>=60: return "south_forest"
	if tx<40: return "forest" if ty<30 else "marsh"
	return "ruin" if ty<30 else "rock"


func zone_name(zone: String) -> String:
	if zone.begins_with("underground_"): return TerrainLayers.NAMES[layer]
	match zone:
		"outer_ridge": return "青茅山 · 白溪远山"
		"foothills": return "青茅山 · 叠溪山脚"
		"cloud_range": return "青茅山 · 云脊远岭"
		"southern_marsh": return "青茅山 · 南泽古道"
		"east_frontier": return "青茅山 · 东岭深山"
		"south_frontier": return "青茅山 · 南部荒野"
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
			var kind:="rock" if t==GameData.T_ROCK else ("bamboo" if v>0.35 else "tree")
			var id:="tile:%d:%d"%[x,y]
			# Collision and durability stay resident; only the visual is streamed.
			destruction.register(id,kind,Rect2(x*TILE,y*TILE,TILE,TILE),45.0 if t==GameData.T_TREE else 100.0,1.0 if t==GameData.T_TREE else 2.5,null,Vector2i(x,y))
			var region:=Vector2i(x/PROP_REGION_TILES,y/PROP_REGION_TILES)
			if not prop_regions.has(region): prop_regions[region]=[]
			prop_regions[region].append(id)
	for h in HOUSE_DATA:
		var house := WorldProp.new()
		house.world = self
		house.kind = String(h.get("kind","house"))
		house.title = h.name
		house.position = h.pos
		house.source = Rect2(192 if h.id in ["clinic","home"] else 256,96,64,80 if h.id in ["clinic","home"] else 64)
		house.draw_size = Vector2(186,170) if house.kind=="house" else Vector2(210,185)
		props.add_child(house)
		houses.append(house)
		destruction.register("house:"+h.id,house.kind,Rect2(h.pos+Vector2(-64,-42),Vector2(128,48)),320,1.8,house)


func _sync_prop_views(view: Rect2) -> void:
	# The outer margin covers tall bamboo, shadows and falling debris. Refresh
	# before the camera reaches it; stationary frames do no registry traversal.
	var wanted:=view.grow(192) if on_surface() else Rect2()
	if _prop_view==wanted: return
	if wanted.has_area() and _prop_view.encloses(view.grow(144)) and _prop_view.size.is_equal_approx(wanted.size): return
	_prop_view=wanted
	var keep:Dictionary={}
	if wanted.has_area():
		var span:=PROP_REGION_TILES*TILE
		for y in range(maxi(0,floori(wanted.position.y/span)),mini(ceili(float(MH)/PROP_REGION_TILES),ceili(wanted.end.y/span))):
			for x in range(maxi(0,floori(wanted.position.x/span)),mini(ceili(float(MW)/PROP_REGION_TILES),ceili(wanted.end.x/span))):
				for id:String in prop_regions.get(Vector2i(x,y),[]):
					var obj:Dictionary=destruction.objects[id]
					var pos:=Vector2(obj.tile)*TILE+Vector2(16,26)
					if not wanted.has_point(pos): continue
					keep[id]=true
					if not active_props.has(id): _create_prop_visual(obj,pos)
	for id:String in active_props.keys():
		if keep.has(id): continue
		destruction.objects[id].visual=null
		active_props[id].queue_free()
		active_props.erase(id)

func _create_prop_visual(obj: Dictionary, pos: Vector2) -> void:
	var prop:=WorldProp.new()
	prop.world=self
	prop.object_id=obj.id
	prop.kind=obj.kind
	prop.position=pos
	var v:float=tile_var[_idx(obj.tile.x,obj.tile.y)]
	prop.draw_size=Vector2(42,42) if obj.kind=="rock" else (Vector2(90,128) if obj.kind=="bamboo" else (Vector2(112,96) if v>0.45 else Vector2(96,88)))
	prop.max_hp=obj.max_hp
	prop.sync_damage(obj.hp)
	props.add_child(prop)
	obj.visual=prop
	active_props[obj.id]=prop


func house_at(pos: Vector2) -> Dictionary:
	if layer>0: return {}
	for h in HOUSE_DATA:
		if destruction.broken("house:"+h.id): continue
		if pos.distance_to(h.pos+Vector2(0,20)) < 58:
			return h
	return {}


func interaction_prompt(pos: Vector2) -> String:
	if shang!=null and shang.active: return shang.prompt()
	if in_interior and interior != null: return interior.interaction_prompt(pos)
	var portal:=blocks.portal_at(pos,layer)
	if not portal.is_empty(): return "E  "+portal.name
	if layer>0:
		var site:=blocks.site_at(pos,layer)
		return "E  "+site.name if not site.is_empty() else "左键开凿 · F 查看方块 · M 分层地图"
	var h := house_at(pos)
	if not h.is_empty(): return "E  进入%s · %s" % [h.name,h.hint]
	for house in HOUSE_DATA:
		if destruction.broken("house:"+house.id) and destruction.within_reach("house:"+house.id,pos,""):
			return "F  检查%s · %s"%[house.name,"废墟可重建" if destruction.repairable("house:"+house.id) else "地物已毁损"]
	var site:=exploration_at(pos)
	if not site.is_empty(): return "E  探索"+site.name
	return ""


func _draw_landmarks() -> void:
	for lm in LANDMARKS:
		if destruction.broken("landmark:"+lm.type): continue
		var tile: Vector2i = lm["pos"]
		var p := Vector2(tile.x, tile.y) * TILE
		if not Rect2(camera_pos,view_size).grow(190).has_point(p):
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
	draw_texture_rect(PaintedArt.prop("mountain",""),Rect2(p+Vector2(-115,-170),Vector2(230,210)),false)
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
	if not on_surface(): return {}
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
	minimap_image.set_pixel(tile.x,tile.y,_minimap_color(tile.x,tile.y))
	minimap_dirty=true
	for offset in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		var p:Vector2i=tile+offset
		if not _in_map(p.x,p.y): continue
		var key:=Vector2i(p.x/CHUNK_TILES,p.y/CHUNK_TILES)
		# A partially painted neighbour must never publish pre-damage pixels.
		terrain_prefetch.erase(key)
		if not terrain_chunks.has(key): continue
		_paint_tile(terrain_chunks[key].image,p.x,p.y,key*CHUNK_TILES*TILE)
		dirty_chunks[key]=true

func flush_terrain_changes() -> void:
	for key in dirty_chunks: terrain_chunks[key].texture.update(terrain_chunks[key].image)
	if minimap_dirty: minimap_texture.update(minimap_image)
	minimap_dirty=false
	dirty_chunks.clear()
	queue_redraw()

func _register_fixtures() -> void:
	destruction.register("furnace","furnace",Rect2(GameData.FURNACE-Vector2(18,18),Vector2(36,36)),240,3.0)
	destruction.register("bonfire","bonfire",Rect2(GameData.BONFIRE-Vector2(14,14),Vector2(28,28)),70,1.0)
	for lm in LANDMARKS:
		var pos: Vector2=Vector2(lm.pos)*TILE
		destruction.register("landmark:"+lm.type,"landmark",Rect2(pos-Vector2(20,20),Vector2(40,40)),180,2.0)
	for house in HOUSE_DATA:
		for id in HouseInterior.FIXTURES:
			if SettlementData.is_cave(house.id) and not id.begins_with("wall"): continue
			var rect: Rect2=HouseInterior.FIXTURES[id]
			destruction.register("interior:"+house.id+":"+id,"wall" if id.begins_with("wall") else "furniture",Rect2(rect.position+HouseInterior.ORIGIN,rect.size),200.0 if id.begins_with("wall") else 60.0,2.0 if id.begins_with("wall") else 1.0,null,Vector2i(-1,-1),house.id)
