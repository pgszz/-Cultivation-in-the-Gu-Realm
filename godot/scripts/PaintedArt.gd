class_name PaintedArt
extends RefCounted

## Original atlases stay unmodified; regions and animation are resolved at runtime.
const HERO := preload("res://assets/painted_world/character.png")
static var RESIDENTS: Texture2D = load("res://assets/painted_world/residents_clean.png") if ResourceLoader.exists("res://assets/painted_world/residents_clean.png") else preload("res://assets/painted_world/residents.png")
const BUILDINGS := preload("res://assets/painted_world/buildings.png")
const SCENERY := preload("res://assets/painted_world/scenery.png")
const TERRAIN := preload("res://assets/painted_world/terrain.png")
# Optional illustration: the playable map is drawn from the generated terrain.
static var ATLAS: Texture2D = load("res://assets/painted_world/atlas.png") if ResourceLoader.exists("res://assets/painted_world/atlas.png") else null
const HOUSE_FRAMES := {"home":0,"clinic":1,"shop":2,"archive":3,"ancestral":4,"bai":5,"xiong":6,"flower_cave":7,"spring_cave":8}
static var _bounds: Dictionary = {}
static var _cache: Dictionary = {}

static func sprite(sheet: String, index: int) -> AtlasTexture:
	var key := "%s:%d" % [sheet,index]
	if _cache.has(key): return _cache[key]
	if _bounds.is_empty():
		_bounds=JSON.parse_string(FileAccess.get_file_as_string("res://assets/painted_world/ATLAS.json"))
	var texture: Texture2D=BUILDINGS if sheet=="buildings" else SCENERY
	var b: Array=_bounds[sheet].bounds[index]
	var result:=AtlasTexture.new()
	result.atlas=texture
	result.region=Rect2(b[0],b[1],b[2],b[3])
	result.filter_clip=true
	_cache[key]=result
	return result

static func prop(kind: String, id: String) -> AtlasTexture:
	if id=="house:shang_hall":
		if not _cache.has(id):
			var painted:=AtlasTexture.new()
			painted.atlas=load("res://assets/shang_city/merchant_hall.png")
			painted.region=Rect2(Vector2.ZERO,painted.atlas.get_size())
			_cache[id]=painted
		return _cache[id]
	if kind in ["house","cave"]:
		var house_id:=id.trim_prefix("house:")
		var data:=SettlementData.building(house_id)
		return sprite("buildings",int(data.art) if not data.is_empty() else HOUSE_FRAMES.get(house_id,0))
	return sprite("scenery",{"bamboo":0,"tree":1,"mountain":2,"rock":3}.get(kind,3))

static func ruin(kind: String) -> AtlasTexture:
	return sprite("buildings",9 if kind in ["house","furniture","wall"] else (10 if kind in ["rock","mountain","cave"] else 11))

static func fit(texture: Texture2D, bounds: Rect2) -> Rect2:
	var scale_factor:=minf(bounds.size.x/texture.get_width(),bounds.size.y/texture.get_height())
	var extent:=texture.get_size()*scale_factor
	return Rect2(Vector2(bounds.get_center().x-extent.x*0.5,bounds.end.y-extent.y),extent)

static func actor_region(row: int, frame: int) -> Rect2:
	return Rect2(frame*256,row*256,256,256)

static func resident_row(id: String) -> int:
	return {"clinic":1,"shop":2,"workshop":2,"archive":3}.get(SettlementData.service(id),0)
