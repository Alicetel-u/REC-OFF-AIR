class_name WFCGenerator
extends RefCounted

## マップ生成器
## MapType.INDUSTRIAL : 単層インダストリアル 5列×4行  CELL_SIZE=13m
## MapType.HAISON     : 廃村 6列×5行                  CELL_SIZE=15m

# ──────────────────────────────────────────────
# 定数
# ──────────────────────────────────────────────

const CELL_SIZE_INDUSTRIAL := 13.0
const CELL_SIZE_HAISON     := 15.0
const CEIL_H               := 5.5   # インダストリアル天井高
const CEIL_H_HAISON        := 3.8   # 廃村民家天井高

# 後方互換用エイリアス（StageGeneratorが参照している）
const CELL_SIZE := 13.0
const CEIL_H_DEFAULT := 5.5

enum Socket { CLOSED, OPEN }
enum Face   { N, E, S, W }

enum MapType { INDUSTRIAL, HAISON }

enum RoomTheme {
	# ── インダストリアル ──
	ENTRANCE, LOADING, CORRIDOR, WORKSHOP,
	MACHINE_RM, GENERATOR, CONTROL_RM, STORAGE,
	STORAGE2, CORRIDOR2, BREAK_ROOM, LOCKER,
	# ── 廃村 ──
	OUTDOOR,       # 野外通路・広場（天井なし・壁なし）
	SHRINE,        # 神社本殿
	FARMHOUSE,     # 民家
	BARN,          # 納屋・倉庫
	WELL,          # 井戸広場
	VILLAGE_SQ,    # 村の広場
	RUIN,          # 廃墟
}

const OPPOSITE := { Face.N: Face.S, Face.S: Face.N, Face.E: Face.W, Face.W: Face.E }
const NEIGHBOR_OFFSET := {
	Face.N: Vector2i(0, -1), Face.S: Vector2i(0, 1),
	Face.E: Vector2i(1, 0),  Face.W: Vector2i(-1, 0),
}

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


# ──────────────────────────────────────────────
# メイン生成
# ──────────────────────────────────────────────

func generate(_w: int = 4, _h: int = 3, _max_retries: int = 1,
		map_type: int = MapType.HAISON) -> Dictionary:
	match map_type:
		MapType.HAISON:
			return generate_haison()
		_:
			return generate_industrial()


# ──────────────────────────────────────────────
# インダストリアル マップ (5×4)
# ──────────────────────────────────────────────

func generate_industrial() -> Dictionary:
	var gw: int = 5
	var gh: int = 4
	var cell_sz := CELL_SIZE_INDUSTRIAL
	var O := Socket.OPEN
	var C := Socket.CLOSED

	# Socket順: [N, E, S, W]
	#     Col0           Col1           Col2           Col3           Col4
	# R0  MACHINE_RM     GENERATOR      CONTROL_RM     STORAGE        VAULT
	#     [C,O,O,C]      [C,O,O,O]      [C,O,O,O]      [C,O,O,O]      [C,C,O,O]
	# R1  CORRIDOR       WORKSHOP       CORRIDOR2      STORAGE2       MACHINE_B
	#     [O,O,O,C]      [O,O,O,O]      [O,O,O,O]      [O,O,O,O]      [O,C,O,O]
	# R2  LOADING        ENTRANCE       BREAK_ROOM     LOCKER         UTILITY
	#     [O,O,O,C]      [O,O,O,O]      [O,O,O,O]      [O,O,O,O]      [O,C,O,O]
	# R3  PUMP_RM        BOILER         ARCHIVE        FURNACE        EXIT_HALL
	#     [O,O,C,C]      [O,O,C,O]      [O,O,C,O]      [O,O,C,O]      [O,C,C,O]
	var f0_defs := [
		# Row 0
		["MACHINE_RM",  RoomTheme.MACHINE_RM,  C, O, O, C, false, false],
		["GENERATOR",   RoomTheme.GENERATOR,   C, O, O, O, false, false],
		["CONTROL_RM",  RoomTheme.CONTROL_RM,  C, O, O, O, false, false],
		["STORAGE",     RoomTheme.STORAGE,     C, O, O, O, false, false],
		["VAULT",       RoomTheme.STORAGE2,    C, C, O, O, false, false],
		# Row 1
		["CORRIDOR",    RoomTheme.CORRIDOR,    O, O, O, C, false, false],
		["WORKSHOP",    RoomTheme.WORKSHOP,    O, O, O, O, false, false],
		["CORRIDOR2",   RoomTheme.CORRIDOR2,   O, O, O, O, false, false],
		["STORAGE2",    RoomTheme.STORAGE2,    O, O, O, O, false, false],
		["MACHINE_B",   RoomTheme.MACHINE_RM,  O, C, O, O, false, false],
		# Row 2
		["LOADING",     RoomTheme.LOADING,     O, O, O, C, false, false],
		["ENTRANCE",    RoomTheme.ENTRANCE,    O, O, O, O, false, false],
		["BREAK_ROOM",  RoomTheme.BREAK_ROOM,  O, O, O, O, false, false],
		["LOCKER",      RoomTheme.LOCKER,      O, O, O, O, false, false],
		["UTILITY",     RoomTheme.WORKSHOP,    O, C, O, O, false, false],
		# Row 3
		["PUMP_RM",     RoomTheme.MACHINE_RM,  O, O, C, C, false, false],
		["BOILER",      RoomTheme.GENERATOR,   O, O, C, O, false, false],
		["ARCHIVE",     RoomTheme.BREAK_ROOM,  O, O, C, O, false, false],
		["FURNACE",     RoomTheme.CONTROL_RM,  O, O, C, O, false, false],
		["EXIT_HALL",   RoomTheme.CORRIDOR,    O, C, C, O, false, false],
	]

	var floor0 := _create_floor(gw, gh, 0.0, f0_defs, cell_sz)
	var spawns := _compute_spawns_industrial(floor0, gw, gh)

	var result := {
		"map_type": MapType.INDUSTRIAL,
		"cell_size": cell_sz,
		"ceil_h": CEIL_H,
		"floors": [floor0],
		"spawns": spawns,
		"grid_w": gw,
		"grid_h": gh,
	}
	_print_debug(result)
	return result


# ──────────────────────────────────────────────
# 廃村 マップ (6×5)
# ──────────────────────────────────────────────

func generate_haison() -> Dictionary:
	var gw: int = 6
	var gh: int = 5
	var cell_sz := CELL_SIZE_HAISON
	var O := Socket.OPEN
	var C := Socket.CLOSED

	# Socket順: [N, E, S, W]   outdoor=true で天井・壁なし
	#      Col0           Col1           Col2           Col3           Col4           Col5
	# R0   SHRINE         OUTDOOR        OUTDOOR        FARMHOUSE_A    OUTDOOR        BARN
	#      [C,O,O,C]      [C,O,O,O]      [C,O,O,O]      [C,O,O,O]      [C,O,O,O]      [C,C,O,O]
	# R1   OUTDOOR        OUTDOOR        OUTDOOR        OUTDOOR        OUTDOOR        OUTDOOR
	#      [O,O,O,C]      [O,O,O,O]      [O,O,O,O]      [O,O,O,O]      [O,O,O,O]      [O,C,O,O]
	# R2   FARMHOUSE_B    OUTDOOR        WELL           OUTDOOR        FARMHOUSE_C    OUTDOOR
	#      [O,O,O,C]      [O,O,O,O]      [O,O,O,O]      [O,O,O,O]      [O,O,O,O]      [O,C,O,O]
	# R3   OUTDOOR        FARMHOUSE_D    OUTDOOR        RUIN           OUTDOOR        OUTDOOR
	#      [O,O,O,C]      [O,O,O,O]      [O,O,O,O]      [O,O,O,O]      [O,O,O,O]      [O,C,O,O]
	# R4   FARMHOUSE_E    OUTDOOR        VILLAGE_SQ     FARMHOUSE_F    OUTDOOR        EXIT_HALL
	#      [O,O,C,C]      [O,O,C,O]      [O,O,C,O]      [O,O,C,O]      [O,O,C,O]      [O,C,C,O]
	var f0_defs := [
		# Row 0 (北端)
		# name                theme                  N  E  S  W     stair  outdoor
		["SHRINE",      RoomTheme.SHRINE,       C, O, O, C, false, false],
		["OUTDOOR_N1",  RoomTheme.OUTDOOR,      C, O, O, O, false, true ],
		["OUTDOOR_N2",  RoomTheme.OUTDOOR,      C, O, O, O, false, true ],
		["FARMHOUSE_A", RoomTheme.FARMHOUSE,    C, O, O, O, false, false],
		["OUTDOOR_N3",  RoomTheme.OUTDOOR,      C, O, O, O, false, true ],
		["BARN",        RoomTheme.BARN,         C, C, O, O, false, false],
		# Row 1
		["OUTDOOR_W1",  RoomTheme.OUTDOOR,      O, O, O, C, false, true ],
		["OUTDOOR_C1",  RoomTheme.OUTDOOR,      O, O, O, O, false, true ],
		["OUTDOOR_C2",  RoomTheme.OUTDOOR,      O, O, O, O, false, true ],
		["OUTDOOR_C3",  RoomTheme.OUTDOOR,      O, O, O, O, false, true ],
		["OUTDOOR_C4",  RoomTheme.OUTDOOR,      O, O, O, O, false, true ],
		["OUTDOOR_E1",  RoomTheme.OUTDOOR,      O, C, O, O, false, true ],
		# Row 2
		["FARMHOUSE_B", RoomTheme.FARMHOUSE,    O, O, O, C, false, false],
		["OUTDOOR_M1",  RoomTheme.OUTDOOR,      O, O, O, O, false, true ],
		["WELL",        RoomTheme.WELL,         O, O, O, O, false, true ],
		["OUTDOOR_M2",  RoomTheme.OUTDOOR,      O, O, O, O, false, true ],
		["FARMHOUSE_C", RoomTheme.FARMHOUSE,    O, O, O, O, false, false],
		["OUTDOOR_E2",  RoomTheme.OUTDOOR,      O, C, O, O, false, true ],
		# Row 3
		["OUTDOOR_W2",  RoomTheme.OUTDOOR,      O, O, O, C, false, true ],
		["FARMHOUSE_D", RoomTheme.FARMHOUSE,    O, O, O, O, false, false],
		["OUTDOOR_S1",  RoomTheme.OUTDOOR,      O, O, O, O, false, true ],
		["RUIN",        RoomTheme.RUIN,         O, O, O, O, false, false],
		["OUTDOOR_S2",  RoomTheme.OUTDOOR,      O, O, O, O, false, true ],
		["OUTDOOR_E3",  RoomTheme.OUTDOOR,      O, C, O, O, false, true ],
		# Row 4 (南端)
		["FARMHOUSE_E", RoomTheme.FARMHOUSE,    O, O, C, C, false, false],
		["OUTDOOR_S3",  RoomTheme.OUTDOOR,      O, O, C, O, false, true ],
		["VILLAGE_SQ",  RoomTheme.VILLAGE_SQ,   O, O, C, O, false, true ],
		["FARMHOUSE_F", RoomTheme.FARMHOUSE,    O, O, C, O, false, false],
		["OUTDOOR_S4",  RoomTheme.OUTDOOR,      O, O, C, O, false, true ],
		["EXIT_HALL",   RoomTheme.ENTRANCE,     O, C, C, O, false, false],
	]

	var floor0 := _create_floor(gw, gh, 0.0, f0_defs, cell_sz)
	var spawns := _compute_spawns_haison(floor0, gw, gh)

	var result := {
		"map_type": MapType.HAISON,
		"cell_size": cell_sz,
		"ceil_h": CEIL_H_HAISON,
		"floors": [floor0],
		"spawns": spawns,
		"grid_w": gw,
		"grid_h": gh,
	}
	_print_debug(result)
	return result


# ──────────────────────────────────────────────
# フロアグリッド構築
# ──────────────────────────────────────────────

func _create_floor(gw: int, gh: int, floor_y: float, defs: Array,
		cell_sz: float) -> Dictionary:
	var grid: Array = []
	var idx := 0
	for z in gh:
		var row: Array = []
		for x in gw:
			var d: Array = defs[idx]
			var world_x: float = x * cell_sz - (gw * cell_sz * 0.5) + cell_sz * 0.5
			var world_z: float = z * cell_sz - (gh * cell_sz * 0.5) + cell_sz * 0.5
			row.append({
				"name":         d[0],
				"theme":        d[1],
				"sockets":      [d[2], d[3], d[4], d[5]],
				"is_staircase": d[6],
				"outdoor":      d[7],
				"world_pos":    Vector3(world_x, floor_y, world_z),
				"grid_pos":     Vector2i(x, z),
				"floor_y":      floor_y,
			})
			idx += 1
		grid.append(row)
	return { "grid": grid, "grid_w": gw, "grid_h": gh, "floor_y": floor_y }


# ──────────────────────────────────────────────
# スポーン計算 (インダストリアル)
# ──────────────────────────────────────────────

func _compute_spawns_industrial(f0: Dictionary, _gw: int, _gh: int) -> Dictionary:
	var spawns := {
		"player":      Vector3.ZERO,
		"exit":        Vector3.ZERO,
		"items":       [] as Array[Vector3],
		"ghosts":      [] as Array[Dictionary],
		"doors":       [] as Array[Dictionary],
		"key":         Vector3.ZERO,
		"power_cells": [] as Array[Vector3],
	}

	var all_cells: Array[Dictionary] = []
	for z in f0.grid_h:
		for x in f0.grid_w:
			all_cells.append(f0.grid[z][x])

	# プレイヤー: ENTRANCE
	for cell in all_cells:
		if cell.theme == RoomTheme.ENTRANCE:
			spawns.player = cell.world_pos + Vector3(0, 1.0, 0)
			break

	# 出口: ENTRANCE南壁際
	for cell in all_cells:
		if cell.theme == RoomTheme.ENTRANCE:
			spawns.exit = cell.world_pos + Vector3(0, 1.5, 3.5)
			break

	# アイテム: ENTRANCE・LOADING 以外
	var item_candidates: Array[Dictionary] = []
	for cell in all_cells:
		if cell.theme not in [RoomTheme.ENTRANCE, RoomTheme.LOADING]:
			item_candidates.append(cell)
	item_candidates.shuffle()
	for i in mini(5, item_candidates.size()):
		var c: Dictionary = item_candidates[i]
		spawns.items.append(c.world_pos + Vector3(
			_rng.randf_range(-2.5, 2.5), 1.0, _rng.randf_range(-2.5, 2.5)))

	# ゴースト
	var ghost_rooms := [
		RoomTheme.MACHINE_RM, RoomTheme.CONTROL_RM,
		RoomTheme.STORAGE,    RoomTheme.GENERATOR,
		RoomTheme.STORAGE2,
	]
	var ghost_candidates: Array[Dictionary] = []
	for cell in all_cells:
		if cell.theme in ghost_rooms:
			ghost_candidates.append(cell)
	ghost_candidates.shuffle()
	for i in mini(2, ghost_candidates.size()):
		var cell: Dictionary = ghost_candidates[i]
		var pos: Vector3 = cell.world_pos + Vector3(0, 0.5, 0)
		var hs := CELL_SIZE_INDUSTRIAL * 0.3
		spawns.ghosts.append({
			"pos": pos,
			"patrol_pts": [
				pos + Vector3(hs,  0,  hs), pos + Vector3(-hs, 0,  hs),
				pos + Vector3(-hs, 0, -hs), pos + Vector3(hs,  0, -hs),
			],
		})

	# ドア: CONTROL_RM と LOCKER
	var door_rooms := [RoomTheme.CONTROL_RM, RoomTheme.LOCKER]
	var grid: Array = f0.grid
	for z in f0.grid_h:
		for x in f0.grid_w:
			var cell: Dictionary = grid[z][x]
			if cell.theme not in door_rooms:
				continue
			var placed := false
			for face in [Face.N, Face.E, Face.S, Face.W]:
				if placed:
					break
				if cell.sockets[face] != Socket.OPEN:
					continue
				var off: Vector2i = NEIGHBOR_OFFSET[face]
				var nx: int = x + off.x
				var nz: int = z + off.y
				if nx < 0 or nx >= f0.grid_w or nz < 0 or nz >= f0.grid_h:
					continue
				var neighbor: Dictionary = grid[nz][nx]
				var door_pos: Vector3 = (cell.world_pos + neighbor.world_pos) * 0.5
				door_pos.y = 0.0
				var rot_y := 90.0 if face in [Face.N, Face.S] else 0.0
				var is_locked: bool = (cell.theme == RoomTheme.LOCKER)
				spawns.doors.append({
					"pos": door_pos, "rotation_y": rot_y, "locked": is_locked,
				})
				placed = true

	# 鍵: STORAGE または GENERATOR
	for cell in all_cells:
		if cell.theme in [RoomTheme.STORAGE, RoomTheme.GENERATOR]:
			spawns.key = cell.world_pos + Vector3(1.5, 1.0, 1.5)
			break

	# PowerCell
	var pc_candidates: Array[Dictionary] = []
	for cell in all_cells:
		if cell.theme not in [RoomTheme.ENTRANCE, RoomTheme.LOADING]:
			pc_candidates.append(cell)
	pc_candidates.shuffle()
	for i in mini(3, pc_candidates.size()):
		spawns.power_cells.append(
			pc_candidates[i].world_pos + Vector3(
				_rng.randf_range(-2.5, 2.5), 0.5, _rng.randf_range(-2.5, 2.5)))

	return spawns


# ──────────────────────────────────────────────
# スポーン計算 (廃村)
# ──────────────────────────────────────────────

func _compute_spawns_haison(f0: Dictionary, _gw: int, _gh: int) -> Dictionary:
	var spawns := {
		"player":      Vector3.ZERO,
		"exit":        Vector3.ZERO,
		"items":       [] as Array[Vector3],
		"ghosts":      [] as Array[Dictionary],
		"doors":       [] as Array[Dictionary],
		"key":         Vector3.ZERO,
		"power_cells": [] as Array[Vector3],
	}

	var all_cells: Array[Dictionary] = []
	for z in f0.grid_h:
		for x in f0.grid_w:
			all_cells.append(f0.grid[z][x])

	# プレイヤー: EXIT_HALL (ENTRANCE テーマ) = 南東の出口前
	for cell in all_cells:
		if cell.name == "EXIT_HALL":
			spawns.player = cell.world_pos + Vector3(-2.0, 1.0, -1.0)
			spawns.exit   = cell.world_pos + Vector3(0, 1.5, 2.0)
			break

	# アイテム: FARMHOUSE・SHRINE・BARN・RUIN に分散
	var item_rooms := [
		RoomTheme.FARMHOUSE, RoomTheme.SHRINE,
		RoomTheme.BARN,      RoomTheme.RUIN,
	]
	var item_candidates: Array[Dictionary] = []
	for cell in all_cells:
		if cell.theme in item_rooms:
			item_candidates.append(cell)
	item_candidates.shuffle()
	for i in mini(5, item_candidates.size()):
		var c: Dictionary = item_candidates[i]
		spawns.items.append(c.world_pos + Vector3(
			_rng.randf_range(-2.0, 2.0), 1.0, _rng.randf_range(-2.0, 2.0)))

	# ゴースト: 廃屋・神社周辺
	var ghost_rooms := [RoomTheme.SHRINE, RoomTheme.RUIN, RoomTheme.FARMHOUSE]
	var ghost_candidates: Array[Dictionary] = []
	for cell in all_cells:
		if cell.theme in ghost_rooms:
			ghost_candidates.append(cell)
	ghost_candidates.shuffle()
	for i in mini(2, ghost_candidates.size()):
		var cell: Dictionary = ghost_candidates[i]
		var pos: Vector3 = cell.world_pos + Vector3(0, 0.5, 0)
		var hs := CELL_SIZE_HAISON * 0.3
		spawns.ghosts.append({
			"pos": pos,
			"patrol_pts": [
				pos + Vector3(hs,  0,  hs), pos + Vector3(-hs, 0,  hs),
				pos + Vector3(-hs, 0, -hs), pos + Vector3(hs,  0, -hs),
			],
		})

	# ドア: FARMHOUSE と SHRINE に設置
	var door_rooms := [RoomTheme.FARMHOUSE, RoomTheme.SHRINE]
	var grid: Array = f0.grid
	for z in f0.grid_h:
		for x in f0.grid_w:
			var cell: Dictionary = grid[z][x]
			if cell.theme not in door_rooms:
				continue
			var placed := false
			for face in [Face.N, Face.E, Face.S, Face.W]:
				if placed:
					break
				if cell.sockets[face] != Socket.OPEN:
					continue
				var off: Vector2i = NEIGHBOR_OFFSET[face]
				var nx: int = x + off.x
				var nz: int = z + off.y
				if nx < 0 or nx >= f0.grid_w or nz < 0 or nz >= f0.grid_h:
					continue
				var neighbor: Dictionary = grid[nz][nx]
				var door_pos: Vector3 = (cell.world_pos + neighbor.world_pos) * 0.5
				door_pos.y = 0.0
				var rot_y := 90.0 if face in [Face.N, Face.S] else 0.0
				spawns.doors.append({
					"pos": door_pos, "rotation_y": rot_y, "locked": false,
				})
				placed = true

	# 鍵: BARNまたはRUINに配置
	for cell in all_cells:
		if cell.theme in [RoomTheme.BARN, RoomTheme.RUIN]:
			spawns.key = cell.world_pos + Vector3(1.0, 1.0, 1.0)
			break

	# PowerCell: 廃村各所に分散
	var pc_candidates: Array[Dictionary] = []
	for cell in all_cells:
		if cell.theme not in [RoomTheme.ENTRANCE]:
			pc_candidates.append(cell)
	pc_candidates.shuffle()
	for i in mini(3, pc_candidates.size()):
		spawns.power_cells.append(
			pc_candidates[i].world_pos + Vector3(
				_rng.randf_range(-3.0, 3.0), 0.5, _rng.randf_range(-3.0, 3.0)))

	return spawns


# ──────────────────────────────────────────────
# デバッグ出力
# ──────────────────────────────────────────────

func _print_debug(result: Dictionary) -> void:
	var floors: Array = result.floors
	var type_name := "HAISON" if result.map_type == MapType.HAISON else "INDUSTRIAL"
	var msg := "=== MAP: %s (cell=%.0fm) ===\n" % [type_name, result.cell_size]
	for fi in floors.size():
		var fd: Dictionary = floors[fi]
		msg += "\n--- 1F (Y=%.1f) ---\n" % fd.floor_y
		for z in fd.grid_h:
			var row_str := ""
			for x in fd.grid_w:
				var cell: Dictionary = fd.grid[z][x]
				row_str += " %-14s" % cell.name
			msg += row_str + "\n"
	msg += "\nPlayer: %s  Exit: %s" % [result.spawns.player, result.spawns.exit]
	msg += "\nItems: %d  Ghosts: %d  Doors: %d" % [
		result.spawns.items.size(), result.spawns.ghosts.size(), result.spawns.doors.size()]
	print(msg)
