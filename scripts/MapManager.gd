extends Node2D
class_name MapManager

## 灵墟旅商 · 地图管理器
## 混合模式：TileMapLayer主导 + 手工锚点 + 程序化填充
## 参考：pixel-game-map-generation skill 第九节

const TILE_SIZE: int = 64
const MAP_WIDTH: int = 48   # tiles
const MAP_HEIGHT: int = 32  # tiles
const MAP_PX_W: int = MAP_WIDTH * TILE_SIZE   # 3072
const MAP_PX_H: int = MAP_HEIGHT * TILE_SIZE  # 2048

# ── 地形枚举 ──
enum Terrain {
	GRASS = 0,
	DIRT = 1,
	WATER = 2,
	STONE = 3,
	CLIFF = 4,
}

# ── 地形 → TileSet source_id 映射（运行时填充）──
var _terrain_source: Dictionary = {}

# ── 关键锚点（tile 坐标）──
const ANCHORS: Dictionary = {
	"spawn":       Vector2i(24, 18),  # 玩家出生点
	"spirit_tower": Vector2i(24, 4),   # 灵石巨塔
	"player_stall": Vector2i(20, 18),  # 玩家摊位
	"furnace":     Vector2i(32, 20),   # 熔炉区
	"market_gate": Vector2i(8, 20),    # 集市西入口
	"spirit_bank": Vector2i(36, 24),   # 灵石庄
	"inn":         Vector2i(16, 24),   # 客栈
	"mine_entrance": Vector2i(40, 8),  # 矿洞入口
	"sect_gate":   Vector2i(8, 8),     # 宗门入口（北）
	"bridge":      Vector2i(24, 15),   # 河流石桥
}

# ── 河流路径点（水平曲线）──
const RIVER_Y_CENTER: int = 15  # 河流中心 Y
const RIVER_WIDTH: int = 3      # 河流半宽（上下各 3 tile）

# ── 路径定义：(起点, 终点) ──
const PATHS: Array = [
	["market_gate", "bridge"],
	["bridge", "furnace"],
	["player_stall", "bridge"],
	["player_stall", "spirit_bank"],
	["player_stall", "inn"],
	["spirit_tower", "bridge"],
	["sect_gate", "spirit_tower"],
	["mine_entrance", "furnace"],
]

# ── 节点引用 ──
var _ground_layer: TileMapLayer      # 基础地形
var _water_layer: TileMapLayer       # 水面/河流
var _path_layer: TileMapLayer        # 石板路
var _decoration_layer: TileMapLayer  # 花草/石头装饰
var _cliff_layer: TileMapLayer       # 悬崖（有碰撞）
var _foreground_layer: TileMapLayer  # 树冠/屋顶（遮角色）

var _tileset: TileSet
var _noise: FastNoiseLite


func _ready() -> void:
	_create_noise()
	_create_tileset()
	_create_layers()
	_generate_terrain()
	_place_river()
	_place_paths()
	_place_anchors()
	_place_decorations()
	print("MapManager: 灵墟地图生成完毕 %d×%d tiles (%d×%d px)" % [MAP_WIDTH, MAP_HEIGHT, MAP_PX_W, MAP_PX_H])


# ══════════════════════════════════════════
# 噪声生成器
# ══════════════════════════════════════════

func _create_noise() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.frequency = 0.02
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_octaves = 3
	_noise.fractal_lacunarity = 2.0
	_noise.fractal_gain = 0.5


# ══════════════════════════════════════════
# TileSet 构建
# ══════════════════════════════════════════

func _create_tileset() -> void:
	_tileset = TileSet.new()
	_tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# ── 加载 terrain_tileset.png，如果不存在则回退到独立文件 ──
	var tex_paths := {
		Terrain.GRASS: "res://assets/tilesets/grass.png",
		Terrain.DIRT:  "res://assets/tilesets/dirt.png",
		Terrain.WATER: "res://assets/tilesets/water.png",
		Terrain.STONE: "res://assets/tilesets/stone.png",
		Terrain.CLIFF: "res://assets/tilesets/cliff.png",
	}

	# 为每种地形创建 AtlasSource（每个源一个 tile 变体）
	for terrain_id in tex_paths:
		var tex: Texture2D = load(tex_paths[terrain_id])
		if not tex:
			push_warning("MapManager: 找不到地形纹理 %s" % tex_paths[terrain_id])
			continue

		var source := TileSetAtlasSource.new()
		source.texture = tex
		source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

		var source_id := _tileset.add_source(source)
		# 创建 tile (0,0) — 基础填充变体
		var tile_coords := Vector2i(0, 0)
		source.create_tile(tile_coords)

		_terrain_source[terrain_id] = source_id  # 存储 source_id 代替列索引


	# ── 配置物理层（碰撞）──
	# Physics Layer 0: 不可行走（水、悬崖）
	# Physics Layer 1: 半透明遮挡（装饰物）
	_tileset.add_physics_layer(0)  # collision
	_tileset.add_physics_layer(1)  # decoration occlusion

	# 水和悬崖 → 设置碰撞（直接修改 TileData 引用，无需 set 回去）
	for terrain_id in [Terrain.WATER, Terrain.CLIFF]:
		var sid: int = _terrain_source.get(terrain_id, -1)
		if sid < 0:
			continue
		var tile_data: TileData = _tileset.get_source(sid).get_tile_data(Vector2i(0, 0), 0)
		if not tile_data:
			continue
		# 矩形碰撞 → 4个顶点 polygon
		var poly := PackedVector2Array([
			Vector2(0, 0),
			Vector2(TILE_SIZE, 0),
			Vector2(TILE_SIZE, TILE_SIZE),
			Vector2(0, TILE_SIZE),
		])
		tile_data.set_collision_polygons_count(0, 1)
		tile_data.set_collision_polygon_points(0, 0, poly)

	print("MapManager: TileSet 创建完毕，%d 种地形" % tex_paths.size())


# ══════════════════════════════════════════
# 层级创建
# ══════════════════════════════════════════

func _create_layers() -> void:
	# 底层：地面（草/泥/石）
	_ground_layer = _make_layer("Ground", 0, false)

	# 水面层：半透明渲染，有碰撞
	_water_layer = _make_layer("Water", 1, true)
	_water_layer.self_modulate = Color(1, 1, 1, 0.85)

	# 路径层：石板路
	_path_layer = _make_layer("Paths", 2, false)

	# 悬崖层：有碰撞
	_cliff_layer = _make_layer("Cliffs", 3, true)

	# 装饰层：花草石头
	_decoration_layer = _make_layer("Decorations", 4, false)

	# 前景层：树冠/屋顶（z-index 最高，遮住角色）
	_foreground_layer = _make_layer("Foreground", 10, false)
	_foreground_layer.y_sort_enabled = true
	_foreground_layer.z_index = 10


func _make_layer(layer_name: String, y_sort_origin: int, has_collision: bool) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = _tileset
	layer.y_sort_origin = y_sort_origin
	if has_collision:
		layer.collision_enabled = true
	add_child(layer)
	return layer


# ══════════════════════════════════════════
# 地形生成（程序化 + 锚点周边手动）
# ══════════════════════════════════════════

func _generate_terrain() -> void:
	# 1) 全图铺草地作为基础
	var grass_sid: int = _safe_sid(Terrain.GRASS)
	if grass_sid < 0:
		return
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			_ground_layer.set_cell(Vector2i(x, y), grass_sid, Vector2i(0, 0))

	# 2) 用噪声散布泥土斑块
	var dirt_sid: int = _safe_sid(Terrain.DIRT)
	if dirt_sid >= 0:
		for x in range(MAP_WIDTH):
			for y in range(MAP_HEIGHT):
				var n: float = _noise.get_noise_2d(float(x), float(y))
				if n > 0.35:
					_ground_layer.set_cell(Vector2i(x, y), dirt_sid, Vector2i(0, 0))

	# 3) 锚点周围手动铺石板（干净平整区域）
	_apply_circle(Vector2i(24, 18), 3, Terrain.STONE)   # 玩家摊位周围
	_apply_circle(Vector2i(24, 4), 2, Terrain.STONE)    # 灵石巨塔
	_apply_circle(Vector2i(32, 20), 3, Terrain.STONE)   # 熔炉区
	_apply_circle(Vector2i(16, 24), 2, Terrain.STONE)   # 客栈
	_apply_circle(Vector2i(36, 24), 2, Terrain.STONE)   # 灵石庄
	_apply_circle(Vector2i(8, 20), 2, Terrain.STONE)    # 集市入口


func _safe_sid(terrain: int) -> int:
	return _terrain_source.get(terrain, -1)


func _set_cell_safe(layer: TileMapLayer, pos: Vector2i, terrain: int) -> void:
	var sid := _safe_sid(terrain)
	if sid >= 0:
		layer.set_cell(pos, sid, Vector2i(0, 0))


func _apply_circle(center: Vector2i, radius: int, terrain: int) -> void:
	var sid: int = _safe_sid(terrain)
	if sid < 0:
		return
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if dx * dx + dy * dy <= radius * radius:
				var pos := Vector2i(center.x + dx, center.y + dy)
				if _in_bounds(pos):
					_ground_layer.set_cell(pos, sid, Vector2i(0, 0))


# ══════════════════════════════════════════
# 河流
# ══════════════════════════════════════════

func _place_river() -> void:
	var water_sid: int = _safe_sid(Terrain.WATER)
	if water_sid < 0:
		return
	for x in range(MAP_WIDTH):
		for dy in range(-RIVER_WIDTH, RIVER_WIDTH + 1):
			var y := RIVER_Y_CENTER + dy

			# 用噪声让河流边缘弯曲
			var noise_val: float = _noise.get_noise_2d(float(x) * 0.5, 0.0)
			y += int(noise_val * 2.0)

			# 在桥梁位置留出通道（3 tile 宽）
			var bridge_x := ANCHORS["bridge"].x
			if x >= bridge_x - 1 and x <= bridge_x + 1 and dy >= -1 and dy <= 1:
				continue

			if _in_bounds(Vector2i(x, y)):
				_water_layer.set_cell(Vector2i(x, y), water_sid, Vector2i(0, 0))


# ══════════════════════════════════════════
# 石板路径
# ══════════════════════════════════════════

func _place_paths() -> void:
	var stone_sid: int = _safe_sid(Terrain.STONE)
	if stone_sid < 0:
		return

	for path_pair in PATHS:
		var from_key: String = path_pair[0]
		var to_key: String = path_pair[1]
		if not ANCHORS.has(from_key) or not ANCHORS.has(to_key):
			continue

		var start: Vector2i = ANCHORS[from_key]
		var end: Vector2i = ANCHORS[to_key]

		# 简单 L 形路径（先水平后垂直 or 先垂直后水平）
		# 随机选择转弯顺序
		var horizontal_first: bool = (start.x + start.y) % 3 == 0

		if horizontal_first:
			_draw_path_segment(start, Vector2i(end.x, start.y), stone_sid)
			_draw_path_segment(Vector2i(end.x, start.y), end, stone_sid)
		else:
			_draw_path_segment(start, Vector2i(start.x, end.y), stone_sid)
			_draw_path_segment(Vector2i(start.x, end.y), end, stone_sid)


func _draw_path_segment(from: Vector2i, to: Vector2i, sid: int) -> void:
	# 画 2 tile 宽的石板路
	var dx := signi(to.x - from.x)
	var dy := signi(to.y - from.y)
	var cur := from
	while true:
		for w in [-1, 0, 1]:
			var pos: Vector2i
			if dx != 0:
				pos = Vector2i(cur.x, cur.y + w)
			else:
				pos = Vector2i(cur.x + w, cur.y)
			if _in_bounds(pos):
				_path_layer.set_cell(pos, sid, Vector2i(0, 0))

		if cur == to:
			break
		if dx != 0:
			cur.x += dx
		if dy != 0:
			cur.y += dy
		if cur.distance_squared_to(from) > 500:  # 安全上限
			break


# ══════════════════════════════════════════
# 手工锚点装饰
# ══════════════════════════════════════════

func _place_anchors() -> void:
	# 灵石巨塔 → 装饰圈 + 悬崖围边
	var cliff_sid: int = _safe_sid(Terrain.CLIFF)
	if cliff_sid < 0:
		return
	var tower := ANCHORS["spirit_tower"]
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			if abs(dx) == 2 or abs(dy) == 2:
				var pos := Vector2i(tower.x + dx, tower.y + dy)
				if _in_bounds(pos):
					_cliff_layer.set_cell(pos, cliff_sid, Vector2i(0, 0))

	# 矿洞入口 → 悬崖围边（暗示洞穴）
	var mine := ANCHORS["mine_entrance"]
	for dx in range(-2, 3):
		for dy in range(-1, 2):
			if abs(dx) == 2 or abs(dy) == 1:
				var pos := Vector2i(mine.x + dx, mine.y + dy)
				if _in_bounds(pos):
					_cliff_layer.set_cell(pos, cliff_sid, Vector2i(0, 0))
	# 入口处挖空
	_set_cell_safe(_ground_layer, ANCHORS["mine_entrance"], Terrain.DIRT)

	# 宗门入口 → 装饰悬崖
	var sect := ANCHORS["sect_gate"]
	for dx in range(-2, 3):
		for dy in range(-2, 0):
			var pos := Vector2i(sect.x + dx, sect.y + dy)
			if _in_bounds(pos):
				_cliff_layer.set_cell(pos, cliff_sid, Vector2i(0, 0))


# ══════════════════════════════════════════
# 装饰散布
# ══════════════════════════════════════════

func _place_decorations() -> void:
	# 用噪声散布装饰物（预留 tile 槽位，后续接入 sprite）
	var deco_sid: int = _safe_sid(Terrain.GRASS)
	if deco_sid < 0:
		return

	# 后续可替换为实际装饰 tile（花草/石头/灌木）
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var n: float = _noise.get_noise_2d(float(x) * 0.1, float(y) * 0.1 + 100.0)
			# 只在草地且远离路径的地方放置装饰
			if abs(n) < 0.15 and _ground_layer.get_cell_source_id(Vector2i(x, y)) == _safe_sid(Terrain.GRASS):
				# 跳过锚点周围
				var near_anchor := false
				for anchor_key in ANCHORS:
					var apos: Vector2i = ANCHORS[anchor_key]
					if Vector2i(x, y).distance_squared_to(apos) < 16:  # radius 4
						near_anchor = true
						break
				if not near_anchor:
					_decoration_layer.set_cell(Vector2i(x, y), deco_sid, Vector2i(0, 0))


# ══════════════════════════════════════════
# 公共 API
# ══════════════════════════════════════════

## 获取锚点的世界坐标（像素）
func get_world_pos(anchor_key: String) -> Vector2:
	if ANCHORS.has(anchor_key):
		var tile_pos: Vector2i = ANCHORS[anchor_key]
		return Vector2(tile_pos.x * TILE_SIZE + TILE_SIZE / 2, tile_pos.y * TILE_SIZE + TILE_SIZE / 2)
	return Vector2.ZERO

## 获取玩家出生点（世界坐标）
func get_spawn_pos() -> Vector2:
	return get_world_pos("spawn")

## 检查 tile 坐标是否在边界内
func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < MAP_WIDTH and pos.y >= 0 and pos.y < MAP_HEIGHT

## 获取所有锚点信息（供其他系统使用）
func get_all_anchors() -> Dictionary:
	return ANCHORS.duplicate()
