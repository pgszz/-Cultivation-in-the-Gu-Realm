class_name DestructibleTerrain
extends TileMap

## 环境破坏系统
## 对应文档：环境破坏系统设计.md

signal terrain_destroyed(pos: Vector2i, tile_type: int)
signal terrain_restored(pos: Vector2i, tile_type: int)

# TileMap 层级
const LAYER_BASE := 0        # 不可破坏地基
const LAYER_DESTRUCTIBLE := 1  # 可破坏层
const LAYER_DECORATION := 2    # 装饰层
const LAYER_EFFECTS := 3       # 特效层

var destroyed_tiles := {}  # pos -> {type, time}
var respawn_enabled := true
var default_respawn_time := 600  # 10分钟

func _ready():
	# 补齐四层，避免空 TileMap 调 layer 1 越界
	while get_layers_count() < 4:
		add_layer(get_layers_count())

	# 每秒检查重生
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_check_respawns)
	add_child(timer)
	timer.start()

func destroy_tile(pos: Vector2i, store: bool = true) -> bool:
	if LAYER_DESTRUCTIBLE >= get_layers_count():
		return false
	var tile = get_cell_source_id(LAYER_DESTRUCTIBLE, pos)
	if tile == -1:
		return false

	var tile_type = get_tile_type(pos)

	# 清除可破坏层和装饰层
	set_cell(LAYER_DESTRUCTIBLE, pos, -1)
	set_cell(LAYER_DECORATION, pos, -1)

	if store:
		destroyed_tiles[pos] = {
			"type": tile_type,
			"time": Time.get_unix_time_from_system()
		}

	terrain_destroyed.emit(pos, tile_type)
	return true

func restore_tile(pos: Vector2i):
	if not destroyed_tiles.has(pos):
		return

	var data = destroyed_tiles[pos]
	var tile_type = data.type

	# 恢复地块
	match tile_type:
		GameData.T_TREE:
			set_cell(LAYER_DESTRUCTIBLE, pos, 0, Vector2i(4, 0))
		GameData.T_ROCK:
			set_cell(LAYER_DESTRUCTIBLE, pos, 0, Vector2i(3, 0))
		GameData.T_GRASS:
			set_cell(LAYER_DESTRUCTIBLE, pos, 0, Vector2i(0, 0))

	destroyed_tiles.erase(pos)
	terrain_restored.emit(pos, tile_type)

func get_tile_type(pos: Vector2i) -> int:
	if LAYER_DESTRUCTIBLE >= get_layers_count():
		return -1
	var atlas_coords = get_cell_atlas_coords(LAYER_DESTRUCTIBLE, pos)

	if atlas_coords == Vector2i(0, 0):
		return GameData.T_GRASS
	elif atlas_coords == Vector2i(1, 0):
		return GameData.T_DIRT
	elif atlas_coords == Vector2i(3, 0):
		return GameData.T_ROCK
	elif atlas_coords == Vector2i(4, 0):
		return GameData.T_TREE

	return -1

func _check_respawns():
	if not respawn_enabled:
		return

	var current_time = Time.get_unix_time_from_system()
	var to_restore = []

	for pos in destroyed_tiles:
		var data = destroyed_tiles[pos]
		if current_time - data.time >= default_respawn_time:
			to_restore.append(pos)

	for pos in to_restore:
		restore_tile(pos)

func can_destroy(pos: Vector2i) -> bool:
	if LAYER_DESTRUCTIBLE >= get_layers_count():
		return false
	return get_cell_source_id(LAYER_DESTRUCTIBLE, pos) != -1

func area_damage(center: Vector2, radius: float) -> Array:
	var destroyed = []
	var center_tile = local_to_map(center)

	var check_radius = int(radius / 32) + 1
	for x in range(-check_radius, check_radius + 1):
		for y in range(-check_radius, check_radius + 1):
			var pos = center_tile + Vector2i(x, y)
			var world_pos = map_to_local(pos)

			if world_pos.distance_to(center) <= radius:
				if destroy_tile(pos):
					destroyed.append(pos)

	return destroyed

func save_data() -> Dictionary:
	var save_dict = {}
	for pos in destroyed_tiles:
		var key = "%d,%d" % [pos.x, pos.y]
		save_dict[key] = destroyed_tiles[pos]
	return save_dict

func load_data(save_dict: Dictionary):
	destroyed_tiles.clear()

	for key in save_dict:
		var parts = key.split(",")
		var pos = Vector2i(int(parts[0]), int(parts[1]))
		destroyed_tiles[pos] = save_dict[key]

		# 应用破坏
		destroy_tile(pos, false)
