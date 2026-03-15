extends Control
## リッチミニマップ — 建物・壁・道・スキャンライン・パルス・視野角・足跡・ノイズ

const MAP_SIZE : float = 200.0
const PADDING : float = 8.0
const DRAW_SIZE : float = MAP_SIZE - PADDING * 2.0
const GHOST_REVEAL_DIST : float = 30.0
const FOOTPRINT_INTERVAL : float = 1.5
const FOOTPRINT_MAX : int = 40
const SCANLINE_COUNT : int = 50

# ── 色定義 ──
const BG_COLOR       := Color(0.02, 0.04, 0.02, 0.7)
const GRID_COLOR     := Color(0.08, 0.18, 0.08, 0.3)
const SCANLINE_COLOR := Color(0.0, 0.0, 0.0, 0.08)
const PLAYER_COLOR   := Color(0.3, 1.0, 0.4)
const PLAYER_GLOW    := Color(0.2, 0.8, 0.3, 0.15)
const FOV_COLOR      := Color(0.3, 1.0, 0.4, 0.06)
const EXIT_COLOR     := Color(1.0, 0.85, 0.1)
const EXIT_GLOW      := Color(1.0, 0.85, 0.1, 0.12)
const ITEM_COLOR     := Color(0.7, 0.85, 1.0)
const ITEM_GLOW      := Color(0.5, 0.7, 1.0, 0.15)
const GHOST_COLOR    := Color(1.0, 0.15, 0.15, 0.85)
const GHOST_GLOW     := Color(1.0, 0.0, 0.0, 0.2)
const GHOST_RING     := Color(1.0, 0.2, 0.2, 0.12)
const FOOTPRINT_COLOR := Color(0.2, 0.5, 0.2, 0.25)
const CORNER_COLOR   := Color(0.15, 0.5, 0.15, 0.9)
const NOISE_COLOR    := Color(0.1, 0.3, 0.1, 0.04)
const BORDER_COLOR   := Color(0.1, 0.4, 0.1, 0.8)
# 構造物の色
const WALL_COLOR     := Color(0.15, 0.3, 0.15, 0.5)
const ROAD_COLOR     := Color(0.12, 0.2, 0.1, 0.35)
const BUILDING_COLOR := Color(0.2, 0.35, 0.2, 0.45)

var _player: Node3D
var _exit_pos: Vector3
var _item_positions: Array
var _ghost_nodes: Array
var _map_min: Vector2
var _map_max: Vector2

var _time : float = 0.0
var _footprints : Array = []
var _footprint_timer : float = 0.0
var _last_footprint_pos : Vector2 = Vector2.ZERO
var _noise_seed : int = 0

# 構造物データ（ミニマップ座標に変換済み）
var _wall_rects : Array = []     # Array[Rect2] — 壁（線で描画）
var _building_rects : Array = [] # Array[Rect2] — 建物（塗りつぶし）
var _road_rects : Array = []     # Array[Rect2] — 道路（塗りつぶし）


func setup(p_player: Node3D, p_exit: Vector3, p_items: Array,
		p_ghosts: Array, p_min: Vector2, p_max: Vector2) -> void:
	_player = p_player
	_exit_pos = p_exit
	_item_positions = p_items
	_ghost_nodes = p_ghosts
	_map_min = p_min
	_map_max = p_max
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(MAP_SIZE, MAP_SIZE)
	size = Vector2(MAP_SIZE, MAP_SIZE)
	_noise_seed = randi()


## CP2 廃倉庫の壁データをハードコードで追加
func add_warehouse_walls() -> void:
	# 外壁
	_add_wall_rect(-25, -18, 50, 0.3)   # 北壁
	_add_wall_rect(-25, 17.7, 50, 0.3)  # 南壁
	_add_wall_rect(-25, -18, 0.3, 36)   # 西壁
	_add_wall_rect(24.7, -18, 0.3, 36)  # 東壁
	# 北仕切り (z=-10)
	_add_wall_rect(-25, -10.15, 8, 0.3)    # NDivider_W
	_add_wall_rect(-14, -10.15, 9, 0.3)    # NDivider_CW
	_add_wall_rect(-2, -10.15, 5, 0.3)     # NDivider_C
	_add_wall_rect(6, -10.15, 10, 0.3)     # NDivider_CE
	_add_wall_rect(19, -10.15, 6, 0.3)     # NDivider_E
	# 南仕切り (z=6)
	_add_wall_rect(-25, 5.85, 7, 0.3)      # SDivider_W
	_add_wall_rect(-15, 5.85, 8, 0.3)      # SDivider_CW
	_add_wall_rect(-4, 5.85, 8, 0.3)       # SDivider_C
	_add_wall_rect(7, 5.85, 11, 0.3)       # SDivider_CE
	_add_wall_rect(21, 5.85, 4, 0.3)       # SDivider_E
	# 縦仕切り（ゾーン境界）
	_add_wall_rect(-12.15, -10, 0.3, 3)    # MZone_WDiv_N
	_add_wall_rect(-12.15, -1, 0.3, 7)     # MZone_WDiv_S
	_add_wall_rect(11.85, -10, 0.3, 4)     # MZone_EDiv_N
	_add_wall_rect(11.85, 1, 0.3, 5)       # MZone_EDiv_S
	_add_wall_rect(-12.15, 6, 0.3, 2)      # SZone_WDiv_N
	_add_wall_rect(-12.15, 11, 0.3, 7)     # SZone_WDiv_S
	_add_wall_rect(11.85, 6, 0.3, 4)       # SZone_EDiv_N
	_add_wall_rect(11.85, 13, 0.3, 5)      # SZone_EDiv_S
	# 支柱
	for p in [Vector2(-6,-2), Vector2(-6,3), Vector2(6,-2), Vector2(6,3),
			Vector2(-18,-14), Vector2(-20,12), Vector2(18,-14), Vector2(20,12)]:
		_add_building_rect(p.x - 0.45, p.y - 0.45, 0.9, 0.9)


## CP3 村マップのグリッドデータから道路・建物を追加
func add_village_from_grid(grid: Dictionary, grid_size: Vector2i, cell_size_val: float) -> void:
	var half_x : float = float(grid_size.x) / 2.0
	var half_y : float = float(grid_size.y) / 2.0
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var wx : float = (float(x) - half_x) * cell_size_val
			var wz : float = (float(y) - half_y) * cell_size_val
			var cell_val : int = grid.get(Vector2i(x, y), 0)
			if cell_val == 1:
				# 道路セル
				_add_road_rect(wx - cell_size_val * 0.5, wz - 1.5, cell_size_val, 3.0)
			else:
				# 非道路 = 建物/草地（薄く表示）
				_add_building_rect(wx - cell_size_val * 0.4, wz - cell_size_val * 0.4,
					cell_size_val * 0.8, cell_size_val * 0.8)


## CP3 手動配置の建物を追加
func add_manual_buildings(buildings: Array) -> void:
	for b in buildings:
		if not is_instance_valid(b):
			continue
		var pos : Vector3 = b.global_position
		# 建物の大きさはスケールから推定（大きいほど大きく表示）
		var s : float = maxf(b.scale.x, b.scale.z) * 0.15
		s = clampf(s, 2.0, 12.0)
		_add_building_rect(pos.x - s, pos.z - s, s * 2.0, s * 2.0)


func _add_wall_rect(wx: float, wz: float, w: float, h: float) -> void:
	var p1 : Vector2 = _world_to_map(Vector3(wx, 0, wz))
	var p2 : Vector2 = _world_to_map(Vector3(wx + w, 0, wz + h))
	var r := Rect2(p1, p2 - p1)
	# 最小幅を保証（壁が見えるように）
	if r.size.x < 1.5:
		r.size.x = 1.5
	if r.size.y < 1.5:
		r.size.y = 1.5
	_wall_rects.append(r)


func _add_building_rect(wx: float, wz: float, w: float, h: float) -> void:
	var p1 : Vector2 = _world_to_map(Vector3(wx, 0, wz))
	var p2 : Vector2 = _world_to_map(Vector3(wx + w, 0, wz + h))
	_building_rects.append(Rect2(p1, p2 - p1))


func _add_road_rect(wx: float, wz: float, w: float, h: float) -> void:
	var p1 : Vector2 = _world_to_map(Vector3(wx, 0, wz))
	var p2 : Vector2 = _world_to_map(Vector3(wx + w, 0, wz + h))
	_road_rects.append(Rect2(p1, p2 - p1))


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	_time += delta
	_footprint_timer += delta
	if _footprint_timer >= FOOTPRINT_INTERVAL:
		_footprint_timer = 0.0
		var pp : Vector2 = _world_to_map(_player.global_position)
		if _last_footprint_pos.distance_to(pp) > 3.0:
			_footprints.append(pp)
			_last_footprint_pos = pp
			if _footprints.size() > FOOTPRINT_MAX:
				_footprints.pop_front()
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(_player):
		return

	# ── 背景 ──
	draw_rect(Rect2(Vector2.ZERO, Vector2(MAP_SIZE, MAP_SIZE)), BG_COLOR)
	var center := Vector2(MAP_SIZE * 0.5, MAP_SIZE * 0.5)
	draw_circle(center, MAP_SIZE * 0.6, Color(0.03, 0.08, 0.03, 0.15))

	# ── 道路 ──
	for r in _road_rects:
		draw_rect(r, ROAD_COLOR)

	# ── 建物（塗りつぶし） ──
	for r in _building_rects:
		draw_rect(r, BUILDING_COLOR)

	# ── 壁（線） ──
	for r in _wall_rects:
		draw_rect(r, WALL_COLOR)

	# ── グリッド線 ──
	var grid_step : float = DRAW_SIZE / 5.0
	for i in range(1, 5):
		var x : float = PADDING + grid_step * i
		draw_line(Vector2(x, PADDING), Vector2(x, MAP_SIZE - PADDING), GRID_COLOR, 1.0)
		var y : float = PADDING + grid_step * i
		draw_line(Vector2(PADDING, y), Vector2(MAP_SIZE - PADDING, y), GRID_COLOR, 1.0)

	# ── スキャンライン ──
	var scan_offset : float = fmod(_time * 12.0, MAP_SIZE)
	for i in range(SCANLINE_COUNT):
		var sy : float = fmod(float(i) * (MAP_SIZE / float(SCANLINE_COUNT)) + scan_offset, MAP_SIZE)
		draw_line(Vector2(0, sy), Vector2(MAP_SIZE, sy), SCANLINE_COLOR, 1.0)

	# ── ノイズドット ──
	var rng := RandomNumberGenerator.new()
	rng.seed = _noise_seed + int(_time * 3.0)
	for i in range(12):
		var nx : float = rng.randf_range(PADDING, MAP_SIZE - PADDING)
		var ny : float = rng.randf_range(PADDING, MAP_SIZE - PADDING)
		draw_rect(Rect2(nx, ny, 2, 1), NOISE_COLOR)

	# ── 足跡 ──
	var fp_count : int = _footprints.size()
	for i in range(fp_count):
		var alpha : float = float(i) / float(maxi(fp_count, 1)) * 0.3
		draw_circle(_footprints[i], 1.5, Color(FOOTPRINT_COLOR.r, FOOTPRINT_COLOR.g, FOOTPRINT_COLOR.b, alpha))

	# ── 出口（パルス□） ──
	var exit_p : Vector2 = _world_to_map(_exit_pos)
	var exit_pulse : float = 0.5 + 0.5 * sin(_time * 3.0)
	draw_circle(exit_p, 12.0 + exit_pulse * 4.0, EXIT_GLOW)
	draw_rect(Rect2(exit_p - Vector2(6, 6), Vector2(12, 12)), EXIT_COLOR, false, 2.0)
	draw_circle(exit_p, 2.0, EXIT_COLOR)
	_draw_label(exit_p + Vector2(0, -14), "EXIT", EXIT_COLOR)

	# ── 未取得アイテム（パルス◇） ──
	var found : int = GameManager.items_found
	for i in range(_item_positions.size()):
		if i < found:
			continue
		var ip : Vector2 = _world_to_map(_item_positions[i])
		var item_pulse : float = 0.5 + 0.5 * sin(_time * 2.5 + float(i) * 1.3)
		draw_circle(ip, 8.0 + item_pulse * 3.0, ITEM_GLOW)
		var d : float = 5.0 + item_pulse * 1.5
		draw_colored_polygon(PackedVector2Array([
			ip + Vector2(0, -d), ip + Vector2(d, 0),
			ip + Vector2(0, d), ip + Vector2(-d, 0)]), ITEM_COLOR)

	# ── ゴースト（距離30m以内、パルスリング） ──
	var player_pos_2d := Vector2(_player.global_position.x, _player.global_position.z)
	for ghost in _ghost_nodes:
		if not is_instance_valid(ghost) or not ghost.visible:
			continue
		var ghost_pos_2d := Vector2(ghost.global_position.x, ghost.global_position.z)
		var dist : float = player_pos_2d.distance_to(ghost_pos_2d)
		if dist > GHOST_REVEAL_DIST:
			continue
		var gp : Vector2 = _world_to_map_2d(ghost_pos_2d)
		var proximity : float = 1.0 - dist / GHOST_REVEAL_DIST
		var ghost_pulse : float = 0.5 + 0.5 * sin(_time * 5.0)
		draw_arc(gp, 10.0 + proximity * 8.0 + ghost_pulse * 3.0, 0, TAU, 32,
			Color(GHOST_RING.r, GHOST_RING.g, GHOST_RING.b, GHOST_RING.a * proximity), 1.0)
		draw_circle(gp, 8.0, Color(GHOST_GLOW.r, GHOST_GLOW.g, GHOST_GLOW.b, GHOST_GLOW.a * proximity))
		draw_circle(gp, 3.0 + proximity * 3.0, GHOST_COLOR)

	# ── プレイヤー視野角 ──
	var pp : Vector2 = _world_to_map(_player.global_position)
	var angle : float = -_player.rotation.y
	var fov_half : float = 0.45
	var fov_len : float = 35.0
	for i in range(8):
		var t : float = float(i) / 7.0
		var a : float = angle + lerpf(-fov_half, fov_half, t)
		var tip := pp + Vector2(sin(a), -cos(a)) * fov_len
		draw_colored_polygon(PackedVector2Array([pp, tip,
			pp + Vector2(sin(a + 0.08), -cos(a + 0.08)) * fov_len]), FOV_COLOR)

	# ── プレイヤー（▲ + グロー） ──
	var player_pulse : float = 0.8 + 0.2 * sin(_time * 4.0)
	draw_circle(pp, 12.0 * player_pulse, PLAYER_GLOW)
	var tri_size : float = 8.0
	var p0 := Vector2(0, -tri_size)
	var p1 := Vector2(-tri_size * 0.6, tri_size * 0.5)
	var p2 := Vector2(tri_size * 0.6, tri_size * 0.5)
	var cos_a : float = cos(angle)
	var sin_a : float = sin(angle)
	p0 = Vector2(p0.x * cos_a - p0.y * sin_a, p0.x * sin_a + p0.y * cos_a) + pp
	p1 = Vector2(p1.x * cos_a - p1.y * sin_a, p1.x * sin_a + p1.y * cos_a) + pp
	p2 = Vector2(p2.x * cos_a - p2.y * sin_a, p2.x * sin_a + p2.y * cos_a) + pp
	draw_colored_polygon(PackedVector2Array([p0, p1, p2]), PLAYER_COLOR)

	# ── 枠線 + コーナーデコ ──
	draw_rect(Rect2(Vector2.ZERO, Vector2(MAP_SIZE, MAP_SIZE)), BORDER_COLOR, false, 1.5)
	_draw_corners()

	# ── 走査線ハイライト ──
	var sweep_y : float = fmod(_time * 25.0, MAP_SIZE + 30.0) - 15.0
	draw_rect(Rect2(0, sweep_y, MAP_SIZE, 3.0), Color(0.1, 0.3, 0.1, 0.06))


func _draw_corners() -> void:
	var L : float = 16.0
	var W : float = 2.0
	draw_line(Vector2(0, 0), Vector2(L, 0), CORNER_COLOR, W)
	draw_line(Vector2(0, 0), Vector2(0, L), CORNER_COLOR, W)
	draw_line(Vector2(MAP_SIZE, 0), Vector2(MAP_SIZE - L, 0), CORNER_COLOR, W)
	draw_line(Vector2(MAP_SIZE, 0), Vector2(MAP_SIZE, L), CORNER_COLOR, W)
	draw_line(Vector2(0, MAP_SIZE), Vector2(L, MAP_SIZE), CORNER_COLOR, W)
	draw_line(Vector2(0, MAP_SIZE), Vector2(0, MAP_SIZE - L), CORNER_COLOR, W)
	draw_line(Vector2(MAP_SIZE, MAP_SIZE), Vector2(MAP_SIZE - L, MAP_SIZE), CORNER_COLOR, W)
	draw_line(Vector2(MAP_SIZE, MAP_SIZE), Vector2(MAP_SIZE, MAP_SIZE - L), CORNER_COLOR, W)


func _draw_label(pos: Vector2, text: String, col: Color) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var font_size : int = 9
	var text_size : Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var draw_pos := Vector2(pos.x - text_size.x * 0.5, pos.y)
	draw_rect(Rect2(draw_pos.x - 2, draw_pos.y - text_size.y, text_size.x + 4, text_size.y + 2), Color(0, 0, 0, 0.5))
	draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)


func _world_to_map(world_pos: Vector3) -> Vector2:
	var nx : float = (world_pos.x - _map_min.x) / (_map_max.x - _map_min.x)
	var nz : float = (world_pos.z - _map_min.y) / (_map_max.y - _map_min.y)
	return Vector2(
		clampf(PADDING + nx * DRAW_SIZE, PADDING, MAP_SIZE - PADDING),
		clampf(PADDING + nz * DRAW_SIZE, PADDING, MAP_SIZE - PADDING))


func _world_to_map_2d(pos_2d: Vector2) -> Vector2:
	var nx : float = (pos_2d.x - _map_min.x) / (_map_max.x - _map_min.x)
	var nz : float = (pos_2d.y - _map_min.y) / (_map_max.y - _map_min.y)
	return Vector2(
		clampf(PADDING + nx * DRAW_SIZE, PADDING, MAP_SIZE - PADDING),
		clampf(PADDING + nz * DRAW_SIZE, PADDING, MAP_SIZE - PADDING))
