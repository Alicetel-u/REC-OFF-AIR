class_name WFCStageGenerator
extends Node3D

## マップジオメトリ＋オブジェクト生成器
## インダストリアル / 廃村 両対応

# ──────────────────────────────────────────────
# プリロード
# ──────────────────────────────────────────────

const GhostScene     := preload("res://scenes/Ghost.tscn")
const ItemScene      := preload("res://scenes/Item.tscn")
const DoorScene      := preload("res://Interaction/Door/Door.tscn")
const KeyScene       := preload("res://Interaction/Items/Key/Key.tscn")
const PowerCellScene := preload("res://Interaction/Items/PowerCell/power_cell.tscn")
const ExitScript     := preload("res://scripts/Exit.gd")
const FurnitureScene := preload("res://Interaction/Furniture/furniture.tscn")

# ──────────────────────────────────────────────
# テクスチャ (Industrial_exterior_v2 アセット)
# ──────────────────────────────────────────────

const TEX_WALL      := preload("res://assets/models/Industrial_exterior_v2_Wall.png")
const TEX_CONCRETE  := preload("res://assets/models/Industrial_exterior_v2_Concrete.png")
const TEX_CABINET   := preload("res://assets/models/Industrial_exterior_v2_Metal_cabinet_1.png")
const TEX_CABINET2  := preload("res://assets/models/Industrial_exterior_v2_Metal_cabinet_2.png")
const TEX_CARGO     := preload("res://assets/models/Industrial_exterior_v2_Cargo_1.png")
const TEX_CARGO2    := preload("res://assets/models/Industrial_exterior_v2_Cargo_2.png")
const TEX_BARREL    := preload("res://assets/models/Industrial_exterior_v2_Barrel_1.png")
const TEX_WOOD      := preload("res://assets/models/Industrial_exterior_v2_Box_wood.png")
const TEX_PIPES     := preload("res://assets/models/Industrial_exterior_v2_Pipes.png")

# ──────────────────────────────────────────────
# マテリアル (インダストリアル)
# ──────────────────────────────────────────────

var mat_floor    : StandardMaterial3D
var mat_wall     : StandardMaterial3D
var mat_ceiling  : StandardMaterial3D
var mat_metal    : StandardMaterial3D
var mat_cabinet  : StandardMaterial3D
var mat_cargo    : StandardMaterial3D
var mat_barrel   : StandardMaterial3D
var mat_wood     : StandardMaterial3D
var mat_pipes    : StandardMaterial3D
var mat_fabric   : StandardMaterial3D
var mat_blood    : StandardMaterial3D
var mat_crack    : StandardMaterial3D
var mat_cobweb   : StandardMaterial3D
var mat_baseboard: StandardMaterial3D
var mat_doorframe: StandardMaterial3D

# ──────────────────────────────────────────────
# マテリアル (廃村)
# ──────────────────────────────────────────────

var mat_h_ground   : StandardMaterial3D  # 土・草の地面
var mat_h_wood     : StandardMaterial3D  # 古い木材
var mat_h_thatch   : StandardMaterial3D  # 藁屋根・土壁
var mat_h_stone    : StandardMaterial3D  # 石積み
var mat_h_moss     : StandardMaterial3D  # 苔・草
var mat_h_blood    : StandardMaterial3D  # 血痕
var mat_h_sky      : StandardMaterial3D  # 屋外用ダミー(使わない)

# ──────────────────────────────────────────────
# 公開参照 (Main.gd 用)
# ──────────────────────────────────────────────

var exit_node  : Node3D = null
var ghosts     : Array[Node3D] = []
var item_count : int = 0

# 現在生成中のマップ種別・セルサイズ
var _map_type  : int   = WFCGenerator.MapType.HAISON
var _cell_size : float = WFCGenerator.CELL_SIZE_HAISON
var _ceil_h    : float = WFCGenerator.CEIL_H_HAISON


# ──────────────────────────────────────────────
# 初期化
# ──────────────────────────────────────────────

func _ready() -> void:
	_create_materials()


func _create_materials() -> void:
	# ── インダストリアル ──
	mat_floor    = _make_mat(TEX_CONCRETE, Color(0.32, 0.30, 0.28), 0.92, Vector3(6, 6, 6))
	mat_wall     = _make_mat(TEX_WALL,     Color(0.52, 0.48, 0.42), 0.88, Vector3(3, 2, 3))
	mat_ceiling  = _make_mat(TEX_CONCRETE, Color(0.42, 0.40, 0.38), 0.90, Vector3(4, 4, 4))
	mat_metal    = _make_mat(TEX_CABINET,  Color(0.42, 0.45, 0.48), 0.55, Vector3(1, 1, 1))
	mat_metal.metallic = 0.6
	mat_cabinet  = _make_mat(TEX_CABINET2, Color(0.35, 0.40, 0.38), 0.60, Vector3(1, 1, 1))
	mat_cabinet.metallic = 0.4
	mat_cargo    = _make_mat(TEX_CARGO,    Color(0.55, 0.42, 0.28), 0.82, Vector3(1, 1, 1))
	mat_barrel   = _make_mat(TEX_BARREL,   Color(0.48, 0.38, 0.25), 0.75, Vector3(1, 1, 1))
	mat_wood     = _make_mat(TEX_WOOD,     Color(0.52, 0.38, 0.22), 0.85, Vector3(1, 1, 1))
	mat_pipes    = _make_mat(TEX_PIPES,    Color(0.50, 0.50, 0.52), 0.60, Vector3(2, 2, 2))
	mat_pipes.metallic = 0.5
	mat_fabric   = _make_mat(null, Color(0.28, 0.22, 0.18), 0.95, Vector3(1, 1, 1))
	mat_blood    = _make_mat(null, Color(0.35, 0.04, 0.02), 0.90, Vector3(1, 1, 1))
	mat_crack    = _make_mat(null, Color(0.08, 0.06, 0.04, 0.7), 0.95, Vector3(1, 1, 1))
	mat_crack.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_cobweb   = _make_mat(null, Color(0.80, 0.80, 0.78, 0.3), 0.95, Vector3(1, 1, 1))
	mat_cobweb.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_baseboard = _make_mat(null, Color(0.20, 0.22, 0.24), 0.70, Vector3(1, 1, 1))
	mat_baseboard.metallic = 0.5
	mat_doorframe = _make_mat(null, Color(0.30, 0.32, 0.35), 0.65, Vector3(1, 1, 1))
	mat_doorframe.metallic = 0.4

	# ── 廃村 ──
	mat_h_ground = _make_mat(null, Color(0.22, 0.18, 0.10), 0.98, Vector3(8, 8, 8))
	mat_h_wood   = _make_mat(TEX_WOOD, Color(0.28, 0.20, 0.12), 0.95, Vector3(2, 2, 2))
	mat_h_thatch = _make_mat(null, Color(0.32, 0.24, 0.14), 0.97, Vector3(3, 3, 3))
	mat_h_stone  = _make_mat(TEX_CONCRETE, Color(0.38, 0.34, 0.28), 0.96, Vector3(4, 4, 4))
	mat_h_moss   = _make_mat(null, Color(0.14, 0.18, 0.08), 0.98, Vector3(5, 5, 5))
	mat_h_blood  = _make_mat(null, Color(0.30, 0.03, 0.01), 0.95, Vector3(1, 1, 1))


func _make_mat(tex: Texture2D, color: Color, rough: float, uv_scale: Vector3) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if tex:
		m.albedo_texture = tex
	m.albedo_color = color
	m.roughness = rough
	m.uv1_scale = uv_scale
	return m


# ──────────────────────────────────────────────
# メイン生成
# ──────────────────────────────────────────────

func generate(map_type: int = WFCGenerator.MapType.HAISON) -> Dictionary:
	var wfc := WFCGenerator.new()
	var result: Dictionary = wfc.generate(4, 3, 1, map_type)

	_map_type  = result.map_type
	_cell_size = result.cell_size
	_ceil_h    = result.ceil_h

	var floors: Array = result.floors
	for fi in floors.size():
		var fd: Dictionary = floors[fi]
		_build_floor_geometry(fd, fi)
		_build_floor_props(fd, fi)

	_place_game_objects(result)
	_place_environment()

	return result


# ──────────────────────────────────────────────
# CSG ジオメトリ構築
# ──────────────────────────────────────────────

func _build_floor_geometry(fd: Dictionary, floor_idx: int) -> void:
	for z in fd.grid_h:
		for x in fd.grid_w:
			var cell: Dictionary = fd.grid[z][x]
			_build_cell(cell, floor_idx)


func _build_cell(cell: Dictionary, floor_idx: int) -> void:
	var pos: Vector3 = cell.world_pos
	var cs  := _cell_size
	var ch  := _ceil_h
	var sockets: Array = cell.sockets
	var is_outdoor: bool = cell.get("outdoor", false)

	var cell_node := Node3D.new()
	cell_node.name = "F%d_%s" % [floor_idx, cell.name]
	cell_node.position = pos
	add_child(cell_node)

	if is_outdoor:
		# 屋外: 地面のみ（天井・壁なし）
		var floor_box := CSGBox3D.new()
		floor_box.name = "Ground"
		floor_box.size = Vector3(cs, 0.3, cs)
		floor_box.position = Vector3(0, -0.15, 0)
		floor_box.use_collision = true
		floor_box.material = mat_h_ground
		cell_node.add_child(floor_box)
		return

	# 屋内: 床・天井・壁
	var floor_mat := mat_floor if _map_type == WFCGenerator.MapType.INDUSTRIAL else mat_h_ground
	var wall_mat  := mat_wall  if _map_type == WFCGenerator.MapType.INDUSTRIAL else mat_h_thatch
	var ceil_mat  := mat_ceiling if _map_type == WFCGenerator.MapType.INDUSTRIAL else mat_h_thatch
	var door_mat  := mat_doorframe if _map_type == WFCGenerator.MapType.INDUSTRIAL else mat_h_wood
	var base_mat  := mat_baseboard if _map_type == WFCGenerator.MapType.INDUSTRIAL else mat_h_stone

	# 床
	var floor_box := CSGBox3D.new()
	floor_box.name = "Floor"
	floor_box.size = Vector3(cs, 0.3, cs)
	floor_box.position = Vector3(0, -0.15, 0)
	floor_box.use_collision = true
	floor_box.material = floor_mat
	cell_node.add_child(floor_box)

	# 天井
	var ceil_box := CSGBox3D.new()
	ceil_box.name = "Ceiling"
	ceil_box.size = Vector3(cs, 0.3, cs)
	ceil_box.position = Vector3(0, ch + 0.15, 0)
	ceil_box.use_collision = true
	ceil_box.material = ceil_mat
	cell_node.add_child(ceil_box)

	# 壁 + ドア枠 + 幅木
	for face in [WFCGenerator.Face.N, WFCGenerator.Face.S,
				  WFCGenerator.Face.E, WFCGenerator.Face.W]:
		_build_wall(cell_node, sockets, face, cs, ch, wall_mat)
		if sockets[face] == WFCGenerator.Socket.OPEN:
			_add_door_frame(cell_node, face, cs, ch, door_mat)
		_add_baseboard(cell_node, sockets, face, cs, base_mat)


func _build_wall(parent: Node3D, sockets: Array, face: int,
		cs: float, ch: float, wall_mat: StandardMaterial3D) -> void:
	var wt := 0.3
	var half := cs * 0.5
	var opening := 2.8

	if sockets[face] == WFCGenerator.Socket.CLOSED:
		var wall := CSGBox3D.new()
		wall.use_collision = true
		wall.material = wall_mat
		match face:
			WFCGenerator.Face.N:
				wall.name = "Wall_N"; wall.size = Vector3(cs, ch, wt)
				wall.position = Vector3(0, ch * 0.5, -half)
			WFCGenerator.Face.S:
				wall.name = "Wall_S"; wall.size = Vector3(cs, ch, wt)
				wall.position = Vector3(0, ch * 0.5, half)
			WFCGenerator.Face.E:
				wall.name = "Wall_E"; wall.size = Vector3(wt, ch, cs)
				wall.position = Vector3(half, ch * 0.5, 0)
			WFCGenerator.Face.W:
				wall.name = "Wall_W"; wall.size = Vector3(wt, ch, cs)
				wall.position = Vector3(-half, ch * 0.5, 0)
		parent.add_child(wall)
	else:
		var seg_len := (cs - opening) * 0.5
		var offset_a := -(opening * 0.5 + seg_len * 0.5)
		var offset_b :=  (opening * 0.5 + seg_len * 0.5)
		var transom_h := ch - 3.0

		var seg_a := CSGBox3D.new()
		var seg_b := CSGBox3D.new()
		var transom := CSGBox3D.new()
		seg_a.use_collision = true; seg_b.use_collision = true
		transom.use_collision = true
		seg_a.material = wall_mat; seg_b.material = wall_mat
		transom.material = wall_mat

		match face:
			WFCGenerator.Face.N:
				seg_a.name = "Wall_N_L"; seg_b.name = "Wall_N_R"
				seg_a.size = Vector3(seg_len, ch, wt); seg_b.size = seg_a.size
				seg_a.position = Vector3(offset_a, ch * 0.5, -half)
				seg_b.position = Vector3(offset_b, ch * 0.5, -half)
				transom.name = "Wall_N_Top"
				transom.size = Vector3(opening, transom_h, wt)
				transom.position = Vector3(0, 3.0 + transom_h * 0.5, -half)
			WFCGenerator.Face.S:
				seg_a.name = "Wall_S_L"; seg_b.name = "Wall_S_R"
				seg_a.size = Vector3(seg_len, ch, wt); seg_b.size = seg_a.size
				seg_a.position = Vector3(offset_a, ch * 0.5, half)
				seg_b.position = Vector3(offset_b, ch * 0.5, half)
				transom.name = "Wall_S_Top"
				transom.size = Vector3(opening, transom_h, wt)
				transom.position = Vector3(0, 3.0 + transom_h * 0.5, half)
			WFCGenerator.Face.E:
				seg_a.name = "Wall_E_L"; seg_b.name = "Wall_E_R"
				seg_a.size = Vector3(wt, ch, seg_len); seg_b.size = seg_a.size
				seg_a.position = Vector3(half, ch * 0.5, offset_a)
				seg_b.position = Vector3(half, ch * 0.5, offset_b)
				transom.name = "Wall_E_Top"
				transom.size = Vector3(wt, transom_h, opening)
				transom.position = Vector3(half, 3.0 + transom_h * 0.5, 0)
			WFCGenerator.Face.W:
				seg_a.name = "Wall_W_L"; seg_b.name = "Wall_W_R"
				seg_a.size = Vector3(wt, ch, seg_len); seg_b.size = seg_a.size
				seg_a.position = Vector3(-half, ch * 0.5, offset_a)
				seg_b.position = Vector3(-half, ch * 0.5, offset_b)
				transom.name = "Wall_W_Top"
				transom.size = Vector3(wt, transom_h, opening)
				transom.position = Vector3(-half, 3.0 + transom_h * 0.5, 0)

		parent.add_child(seg_a)
		parent.add_child(seg_b)
		parent.add_child(transom)


func _add_door_frame(parent: Node3D, face: int, cs: float, ch: float,
		frame_mat: StandardMaterial3D) -> void:
	var opening := 2.8
	var half := cs * 0.5
	var frame_w := 0.10
	var frame_d := 0.18
	var post_h := 3.0

	var left_pos: Vector3
	var right_pos: Vector3
	var lintel_pos: Vector3
	var post_size: Vector3
	var lintel_size: Vector3

	match face:
		WFCGenerator.Face.N, WFCGenerator.Face.S:
			var z_pos := -half if face == WFCGenerator.Face.N else half
			post_size = Vector3(frame_w, post_h, frame_d)
			lintel_size = Vector3(opening + frame_w * 2, frame_w, frame_d)
			left_pos = Vector3(-opening * 0.5 - frame_w * 0.5, post_h * 0.5, z_pos)
			right_pos = Vector3(opening * 0.5 + frame_w * 0.5, post_h * 0.5, z_pos)
			lintel_pos = Vector3(0, post_h + frame_w * 0.5, z_pos)
		WFCGenerator.Face.E, WFCGenerator.Face.W:
			var x_pos := half if face == WFCGenerator.Face.E else -half
			post_size = Vector3(frame_d, post_h, frame_w)
			lintel_size = Vector3(frame_d, frame_w, opening + frame_w * 2)
			left_pos = Vector3(x_pos, post_h * 0.5, -opening * 0.5 - frame_w * 0.5)
			right_pos = Vector3(x_pos, post_h * 0.5, opening * 0.5 + frame_w * 0.5)
			lintel_pos = Vector3(x_pos, post_h + frame_w * 0.5, 0)

	_box(parent, "DFrame_L_%d" % face, post_size,    left_pos,   frame_mat)
	_box(parent, "DFrame_R_%d" % face, post_size,    right_pos,  frame_mat)
	_box(parent, "DFrame_T_%d" % face, lintel_size,  lintel_pos, frame_mat)


func _add_baseboard(parent: Node3D, sockets: Array, face: int, cs: float,
		base_mat: StandardMaterial3D) -> void:
	var bb_h := 0.10
	var bb_d := 0.05
	var half := cs * 0.5

	if sockets[face] == WFCGenerator.Socket.CLOSED:
		match face:
			WFCGenerator.Face.N:
				_box(parent, "BB_N", Vector3(cs, bb_h, bb_d),
					Vector3(0, bb_h * 0.5, -half + bb_d * 0.5), base_mat)
			WFCGenerator.Face.S:
				_box(parent, "BB_S", Vector3(cs, bb_h, bb_d),
					Vector3(0, bb_h * 0.5, half - bb_d * 0.5), base_mat)
			WFCGenerator.Face.E:
				_box(parent, "BB_E", Vector3(bb_d, bb_h, cs),
					Vector3(half - bb_d * 0.5, bb_h * 0.5, 0), base_mat)
			WFCGenerator.Face.W:
				_box(parent, "BB_W", Vector3(bb_d, bb_h, cs),
					Vector3(-half + bb_d * 0.5, bb_h * 0.5, 0), base_mat)


# ──────────────────────────────────────────────
# 部屋別プロップ配置
# ──────────────────────────────────────────────

func _build_floor_props(fd: Dictionary, floor_idx: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for z in fd.grid_h:
		for x in fd.grid_w:
			var cell: Dictionary = fd.grid[z][x]
			var parent: Node3D = get_node_or_null("F%d_%s" % [floor_idx, cell.name])
			if not parent:
				continue

			if _map_type == WFCGenerator.MapType.HAISON:
				_build_props_haison(cell, parent, rng)
			else:
				_build_props_industrial(cell, parent, rng)

			_add_horror_details(parent, cell, rng)


# ──────────────────────────────────────────────
# インダストリアル プロップ
# ──────────────────────────────────────────────

func _build_props_industrial(cell: Dictionary, parent: Node3D,
		rng: RandomNumberGenerator) -> void:
	match cell.theme:
		WFCGenerator.RoomTheme.MACHINE_RM:   _props_machine_rm(parent)
		WFCGenerator.RoomTheme.GENERATOR:    _props_generator(parent)
		WFCGenerator.RoomTheme.CONTROL_RM:   _props_control_rm(parent)
		WFCGenerator.RoomTheme.STORAGE:      _props_storage(parent)
		WFCGenerator.RoomTheme.CORRIDOR:     _props_corridor(parent)
		WFCGenerator.RoomTheme.WORKSHOP:     _props_workshop(parent)
		WFCGenerator.RoomTheme.CORRIDOR2:    _props_corridor2(parent)
		WFCGenerator.RoomTheme.STORAGE2:     _props_storage2(parent)
		WFCGenerator.RoomTheme.LOADING:      _props_loading(parent)
		WFCGenerator.RoomTheme.ENTRANCE:     _props_entrance(parent)
		WFCGenerator.RoomTheme.BREAK_ROOM:   _props_break_room(parent)
		WFCGenerator.RoomTheme.LOCKER:       _props_locker(parent)

	if cell.theme in [WFCGenerator.RoomTheme.WORKSHOP,
					   WFCGenerator.RoomTheme.BREAK_ROOM]:
		_add_glb_furniture(parent, cell, rng)


# ══════════════════════════════════════════════
# インダストリアル 部屋別プロップ
# ══════════════════════════════════════════════

func _props_machine_rm(p: Node3D) -> void:
	_box(p, "Machine_A",   Vector3(4.5, 3.8, 1.6), Vector3(-1.8, 1.9, -3.8),  mat_metal)
	_box(p, "Machine_B",   Vector3(2.8, 2.5, 1.4), Vector3( 2.8, 1.25, -3.8), mat_metal)
	_box(p, "Machine_A_Panel", Vector3(3.8, 0.15, 0.05), Vector3(-1.8, 3.0, -3.04), mat_cabinet)
	_box(p, "Machine_B_Panel", Vector3(2.2, 0.15, 0.05), Vector3( 2.8, 2.0, -3.12), mat_cabinet)
	_box(p, "Pipe_H1", Vector3(0.22, 0.22, 6.5), Vector3(-4.2, 4.8, -0.5), mat_pipes)
	_box(p, "Pipe_H2", Vector3(0.18, 0.18, 5.0), Vector3(-4.2, 3.5, -1.0), mat_pipes)
	_box(p, "Pipe_V1", Vector3(0.22, 4.0, 0.22), Vector3(-4.2, 2.0, -3.2), mat_pipes)
	_box(p, "Pipe_V2", Vector3(0.22, 3.0, 0.22), Vector3(-4.2, 1.5,  2.5), mat_pipes)
	_cyl(p, "Drum1", 0.35, 0.95, Vector3(-3.5, 0.475, -3.5), mat_barrel)
	_cyl(p, "Drum2", 0.35, 0.95, Vector3(-2.7, 0.475, -3.5), mat_barrel)
	_cyl(p, "Drum3", 0.35, 0.95, Vector3(-3.5, 0.475, -2.7), mat_barrel)
	_box(p, "CtrlBox", Vector3(0.6, 1.2, 0.35), Vector3(-4.2, 0.6, 1.5), mat_cabinet)


func _props_generator(p: Node3D) -> void:
	_cyl(p, "Gen_A", 1.0, 2.8, Vector3(-2.5, 1.4, -3.2), mat_metal)
	_cyl(p, "Gen_B", 1.0, 2.8, Vector3( 1.5, 1.4, -3.2), mat_metal)
	_box(p, "GenBase_A", Vector3(2.2, 0.25, 2.2), Vector3(-2.5, 0.125, -3.2), mat_metal)
	_box(p, "GenBase_B", Vector3(2.2, 0.25, 2.2), Vector3( 1.5, 0.125, -3.2), mat_metal)
	_box(p, "ElecPanel",  Vector3(3.5, 1.8, 0.35), Vector3(3.5, 0.9, -4.1), mat_cabinet)
	_box(p, "ElecPanel2", Vector3(1.5, 1.5, 0.35), Vector3(-0.5, 0.75, -4.1), mat_cabinet)
	_box(p, "Pipe_Gen1", Vector3(0.22, 0.22, 7.0), Vector3(-2.5, 5.0, 0.0), mat_pipes)
	_box(p, "Pipe_Gen2", Vector3(0.22, 0.22, 7.0), Vector3( 1.5, 5.0, 0.0), mat_pipes)
	_cyl(p, "Drum_G1", 0.35, 0.95, Vector3( 3.5, 0.475, 3.0), mat_barrel)
	_cyl(p, "Drum_G2", 0.35, 0.95, Vector3( 3.5, 0.475, 3.8), mat_barrel)
	_box(p, "CableDuct", Vector3(0.4, 0.12, 6.0), Vector3(0, 0.06, 0), mat_metal)


func _props_control_rm(p: Node3D) -> void:
	_box(p, "Console_Main", Vector3(7.5, 1.0, 0.75), Vector3(0, 0.5, -3.8), mat_cabinet)
	_box(p, "Console_Top",  Vector3(7.5, 0.08, 0.75), Vector3(0, 1.04, -3.8), mat_metal)
	for i in 4:
		_box(p, "Monitor_%d" % i, Vector3(0.85, 0.55, 0.08),
			Vector3(-3.3 + i * 2.2, 1.65, -3.85), mat_metal)
	_box(p, "Chair_Seat", Vector3(0.55, 0.06, 0.55), Vector3(0, 0.55, -2.5), mat_fabric)
	_box(p, "Chair_Back", Vector3(0.55, 0.60, 0.06), Vector3(0, 0.90, -2.25), mat_fabric)
	_box(p, "SubConsole", Vector3(0.65, 0.85, 2.5), Vector3(-4.2, 0.425, -1.5), mat_cabinet)
	_box(p, "Papers",     Vector3(1.5, 0.03, 0.35), Vector3(2.0, 1.09, -3.6), mat_wood)
	_cyl(p, "Trash",  0.22, 0.45, Vector3(3.5, 0.225, -2.5), mat_metal)


func _props_storage(p: Node3D) -> void:
	_box(p, "Shelf_E_Unit", Vector3(0.40, 3.5, 7.0), Vector3(4.2, 1.75, 0), mat_metal)
	for i in 4:
		_box(p, "ShelfBoard_E_%d" % i, Vector3(0.36, 0.05, 6.8),
			Vector3(4.2, 0.6 + i * 0.8, 0), mat_metal)
	_box(p, "Shelf_N_Unit", Vector3(6.5, 2.8, 0.40), Vector3(0, 1.4, -4.2), mat_metal)
	for i in 3:
		_box(p, "ShelfBoard_N_%d" % i, Vector3(6.3, 0.05, 0.36),
			Vector3(0, 0.6 + i * 0.95, -4.2), mat_metal)
	_box(p, "Cargo_A", Vector3(2.0, 1.4, 1.5), Vector3(3.0, 0.7, -3.2), mat_cargo)
	_box(p, "Cargo_B", Vector3(1.5, 1.0, 1.2), Vector3(2.5, 0.5, -1.5), mat_cargo)
	_box(p, "Crate_A", Vector3(1.2, 1.2, 1.2), Vector3(-1.5, 0.6,  2.5), mat_wood)
	_box(p, "Crate_B", Vector3(1.0, 1.0, 1.0), Vector3(-2.5, 0.5,  3.0), mat_wood)
	_box(p, "Crate_C", Vector3(1.2, 1.2, 1.2), Vector3(-1.5, 1.8,  2.5), mat_wood)
	_cyl(p, "Drum_S1", 0.35, 0.95, Vector3(-3.5, 0.475,  3.5), mat_barrel)


func _props_corridor(p: Node3D) -> void:
	for i in 4:
		_box(p, "Locker_%d" % i, Vector3(0.50, 2.0, 0.60),
			Vector3(-4.1, 1.0, -3.0 + i * 1.8), mat_cabinet)
		_box(p, "LkDoor_%d" % i, Vector3(0.04, 1.8, 0.55),
			Vector3(-3.88, 1.0, -3.0 + i * 1.8), mat_metal)
	_box(p, "Bench",     Vector3(0.40, 0.06, 3.5), Vector3(-4.1, 0.46, 1.5), mat_metal)
	_box(p, "Bench_Leg", Vector3(0.04, 0.43, 3.0), Vector3(-4.1, 0.22, 1.5), mat_metal)
	_cyl(p, "FireExt", 0.12, 0.55, Vector3(-4.0, 0.275, -4.0), mat_metal)


func _props_workshop(p: Node3D) -> void:
	_box(p, "Workbench_Main", Vector3(4.5, 0.90, 1.2), Vector3( 0.5, 0.45, -1.5), mat_metal)
	_box(p, "WB_Overhang",   Vector3(4.5, 0.08, 1.2), Vector3( 0.5, 0.94, -1.5), mat_metal)
	for i in 4:
		_box(p, "WB_Leg_%d" % i, Vector3(0.08, 0.90, 0.08),
			Vector3(-1.8 + i * 1.4, 0.45, -1.5 + (1 if i % 2 == 0 else -1) * 0.52), mat_metal)
	_box(p, "Workbench_Sub", Vector3(2.5, 0.85, 0.90), Vector3(-2.5, 0.425, -3.3), mat_metal)
	_box(p, "ToolPanel", Vector3(2.0, 1.5, 0.06), Vector3( 3.0, 2.0, -4.4), mat_metal)
	_box(p, "ToolBox_A", Vector3(0.70, 0.55, 0.45), Vector3( 0.5, 0.50, -1.0), mat_cabinet)
	_box(p, "ToolBox_B", Vector3(0.55, 0.45, 0.40), Vector3(-2.5, 0.42, -2.9), mat_cabinet)
	_cyl(p, "Drum_W1", 0.35, 0.95, Vector3( 3.5, 0.475, 3.0), mat_barrel)
	_cyl(p, "Drum_W2", 0.35, 0.95, Vector3( 3.5, 0.475, 3.8), mat_barrel)
	_cyl(p, "CableReel", 0.5, 0.3, Vector3(-3.0, 0.15, 3.0), mat_metal)


func _props_corridor2(p: Node3D) -> void:
	_cyl(p, "Cone1", 0.18, 0.60, Vector3(-3.0, 0.30, -3.0), mat_metal)
	_cyl(p, "Cone2", 0.18, 0.60, Vector3( 3.0, 0.30, -3.0), mat_metal)
	_box(p, "CableDuct_H", Vector3(0.35, 0.10, 9.0), Vector3(0, 0.05, 0), mat_metal)
	_box(p, "CableDuct_V", Vector3(9.0, 0.10, 0.35), Vector3(0, 0.05, 0), mat_metal)
	_box(p, "ElecBox", Vector3(0.35, 0.55, 0.20), Vector3(-4.2, 1.5, -3.0), mat_cabinet)
	_box(p, "Trash1",  Vector3(0.40, 0.55, 0.40), Vector3( 3.5, 0.275, 3.5), mat_metal)


func _props_storage2(p: Node3D) -> void:
	_box(p, "Shelf_E2_Unit", Vector3(0.40, 3.0, 6.5), Vector3(4.2, 1.5, -0.5), mat_metal)
	for i in 3:
		_box(p, "ShelfE2_%d" % i, Vector3(0.36, 0.05, 6.2),
			Vector3(4.2, 0.7 + i * 0.90, -0.5), mat_metal)
	_box(p, "Container_A", Vector3(3.0, 2.0, 1.0), Vector3(-1.5, 1.0, 4.0), mat_cargo)
	_box(p, "Container_B", Vector3(2.0, 1.5, 1.0), Vector3( 2.5, 0.75, 4.0), mat_cargo)
	_box(p, "Crate_S2A", Vector3(1.1, 1.1, 1.1), Vector3( 3.5, 0.55, 3.0), mat_wood)
	_box(p, "Crate_S2B", Vector3(0.9, 0.9, 0.9), Vector3( 3.5, 1.65, 3.0), mat_wood)
	_cyl(p, "Drum_S2", 0.35, 0.95, Vector3(-3.5, 0.475, 3.5), mat_barrel)


func _props_loading(p: Node3D) -> void:
	_box(p, "Dock_Platform", Vector3(7.5, 0.50, 1.5), Vector3(0, 0.25, 3.5), mat_metal)
	_box(p, "Pallet_A", Vector3(4.0, 0.18, 3.5), Vector3(-2.0, 0.09, 0.5), mat_wood)
	_box(p, "Pallet_B", Vector3(3.5, 0.18, 3.0), Vector3( 2.5, 0.09, 1.0), mat_wood)
	_box(p, "Load_A1", Vector3(3.8, 1.6, 3.2), Vector3(-2.0, 1.08, 0.5), mat_cargo)
	_box(p, "Load_B1", Vector3(3.2, 1.2, 2.8), Vector3( 2.5, 0.78, 1.0), mat_cargo)
	_box(p, "WShelf_Unit", Vector3(0.40, 2.5, 6.0), Vector3(-4.2, 1.25, 0), mat_metal)
	for i in 3:
		_box(p, "WShelf_%d" % i, Vector3(0.36, 0.05, 5.8),
			Vector3(-4.2, 0.6 + i * 0.85, 0), mat_metal)
	_box(p, "Crate_WL1", Vector3(1.3, 1.3, 1.3), Vector3(-3.5, 0.65, -2.0), mat_wood)
	_box(p, "Crate_WL2", Vector3(1.0, 1.0, 1.0), Vector3(-3.5, 1.95, -2.0), mat_wood)
	_cyl(p, "Drum_L1", 0.35, 0.95, Vector3(-3.5, 0.475, 2.5), mat_barrel)
	_cyl(p, "Drum_L2", 0.35, 0.95, Vector3(-2.7, 0.475, 2.5), mat_barrel)
	_cyl(p, "Drum_L3", 0.35, 0.95, Vector3(-3.5, 0.475, 3.5), mat_barrel)


func _props_entrance(p: Node3D) -> void:
	_box(p, "Reception_Base", Vector3(4.5, 1.10, 0.75), Vector3(0, 0.55, 3.6),  mat_cabinet)
	_box(p, "Reception_Top",  Vector3(4.5, 0.06, 0.75), Vector3(0, 1.13, 3.6),  mat_metal)
	_box(p, "Desk_Shelf", Vector3(3.5, 2.0, 0.35), Vector3(0, 1.0, 4.2), mat_cabinet)
	for i in 2:
		var cx := -1.0 + i * 2.0
		_box(p, "Chair_S_%d" % i, Vector3(0.50, 0.06, 0.50), Vector3(cx, 0.50, 2.2), mat_fabric)
		_box(p, "Chair_B_%d" % i, Vector3(0.50, 0.55, 0.06), Vector3(cx, 0.83, 2.48), mat_fabric)
	_box(p, "Sign",     Vector3(2.0, 0.55, 0.05), Vector3(0, 3.5, 4.4), mat_cabinet)
	_box(p, "SignText", Vector3(1.8, 0.35, 0.03), Vector3(0, 3.5, 4.44), mat_metal)
	_box(p, "Barrier",  Vector3(0.08, 1.2, 1.5), Vector3(-2.5, 0.6, 1.0), mat_metal)
	_cyl(p, "FireExt_E", 0.12, 0.55, Vector3(-4.0, 0.275, 3.5), mat_metal)


func _props_break_room(p: Node3D) -> void:
	_box(p, "Vending_A", Vector3(0.75, 1.95, 0.55), Vector3(-3.5, 0.975, 3.8), mat_cabinet)
	_box(p, "Vending_B", Vector3(0.75, 1.95, 0.55), Vector3(-2.7, 0.975, 3.8), mat_cabinet)
	_box(p, "Vending_Screen", Vector3(0.50, 0.55, 0.03), Vector3(-3.5, 1.3, 3.55), mat_metal)
	_box(p, "Locker_BR1", Vector3(0.50, 2.0, 0.60), Vector3(3.8, 1.0, 3.7), mat_cabinet)
	_box(p, "Locker_BR2", Vector3(0.50, 2.0, 0.60), Vector3(3.2, 1.0, 3.7), mat_cabinet)
	_box(p, "BreakTable", Vector3(2.5, 0.06, 1.2), Vector3(0, 0.78, -0.5), mat_metal)
	_box(p, "BT_Leg1", Vector3(0.06, 0.75, 0.06), Vector3(-1.1, 0.375, -1.0), mat_metal)
	_box(p, "BT_Leg2", Vector3(0.06, 0.75, 0.06), Vector3( 1.1, 0.375, -1.0), mat_metal)
	_box(p, "BT_Leg3", Vector3(0.06, 0.75, 0.06), Vector3(-1.1, 0.375,  0.0), mat_metal)
	_box(p, "BT_Leg4", Vector3(0.06, 0.75, 0.06), Vector3( 1.1, 0.375,  0.0), mat_metal)
	for i in 3:
		var cz := -1.0 + i * 0.5
		_box(p, "BChair_S_%d" % i, Vector3(0.48, 0.06, 0.48), Vector3(0, 0.50, cz + 0.9), mat_fabric)
		_box(p, "BChair_B_%d" % i, Vector3(0.48, 0.50, 0.06), Vector3(0, 0.80, cz + 0.68), mat_fabric)
	_box(p, "Coffee", Vector3(0.40, 0.55, 0.35), Vector3(-3.5, 0.50, 2.5), mat_metal)
	_cyl(p, "Trash_BR", 0.22, 0.45, Vector3( 3.5, 0.225, 2.2), mat_metal)


func _props_locker(p: Node3D) -> void:
	for i in 5:
		_box(p, "LockerN_%d" % i, Vector3(0.55, 2.0, 0.62),
			Vector3(-4.0 + i * 1.9, 1.0, -3.8), mat_cabinet)
	for i in 5:
		_box(p, "LockerE_%d" % i, Vector3(0.62, 2.0, 0.55),
			Vector3(3.8, 1.0, -3.8 + i * 1.7), mat_cabinet)
	for i in 3:
		_box(p, "LockerS_%d" % i, Vector3(0.55, 2.0, 0.62),
			Vector3(-4.0 + i * 1.9, 1.0, 3.8), mat_cabinet)
	_box(p, "LkBench", Vector3(0.45, 0.06, 5.0), Vector3(0, 0.46, 0), mat_metal)
	_box(p, "LkBench_Leg", Vector3(0.04, 0.43, 4.8), Vector3(0, 0.22, 0), mat_metal)


# ──────────────────────────────────────────────
# 廃村 プロップ
# ──────────────────────────────────────────────

func _build_props_haison(cell: Dictionary, parent: Node3D,
		rng: RandomNumberGenerator) -> void:
	match cell.theme:
		WFCGenerator.RoomTheme.OUTDOOR:    _props_outdoor(parent, rng)
		WFCGenerator.RoomTheme.SHRINE:     _props_shrine(parent)
		WFCGenerator.RoomTheme.FARMHOUSE:  _props_farmhouse(parent, rng)
		WFCGenerator.RoomTheme.BARN:       _props_barn(parent)
		WFCGenerator.RoomTheme.WELL:       _props_well(parent)
		WFCGenerator.RoomTheme.VILLAGE_SQ: _props_village_sq(parent)
		WFCGenerator.RoomTheme.RUIN:       _props_ruin(parent, rng)
		WFCGenerator.RoomTheme.ENTRANCE:   _props_haison_exit(parent)


# 野外通路・広場（草木・石）
func _props_outdoor(p: Node3D, rng: RandomNumberGenerator) -> void:
	var half := _cell_size * 0.5
	# ランダムな草むら・石
	var stone_count := rng.randi_range(0, 3)
	for i in stone_count:
		var sx := rng.randf_range(-half + 1.0, half - 1.0)
		var sz := rng.randf_range(-half + 1.0, half - 1.0)
		var ss := rng.randf_range(0.3, 0.9)
		_box(p, "Stone_%d" % i, Vector3(ss, ss * 0.6, ss), Vector3(sx, ss * 0.3, sz), mat_h_stone)
	# 草（平らな板）
	var grass_count := rng.randi_range(1, 3)
	for i in grass_count:
		var gx := rng.randf_range(-half + 0.5, half - 0.5)
		var gz := rng.randf_range(-half + 0.5, half - 0.5)
		_box(p, "Grass_%d" % i,
			Vector3(rng.randf_range(1.0, 2.5), 0.05, rng.randf_range(1.0, 2.5)),
			Vector3(gx, 0.025, gz), mat_h_moss)


# 神社本殿
func _props_shrine(p: Node3D) -> void:
	var h := _cell_size * 0.5
	# 賽銭箱（中央前方）
	_box(p, "SaisenBox",  Vector3(0.8, 0.7, 0.8), Vector3(0, 0.35, 1.5),  mat_h_wood)
	_box(p, "SaisenTop",  Vector3(0.8, 0.06, 0.8), Vector3(0, 0.73, 1.5), mat_h_wood)
	# 本殿土台
	_box(p, "Altar_Base", Vector3(3.5, 0.4, 2.5), Vector3(0, 0.2, -2.0),  mat_h_stone)
	_box(p, "Altar_Top",  Vector3(2.8, 0.8, 1.8), Vector3(0, 0.8, -2.0),  mat_h_wood)
	# 鳥居の柱（入口）
	_box(p, "Torii_L", Vector3(0.25, 3.5, 0.25), Vector3(-2.0, 1.75, h - 1.0), mat_h_wood)
	_box(p, "Torii_R", Vector3(0.25, 3.5, 0.25), Vector3( 2.0, 1.75, h - 1.0), mat_h_wood)
	_box(p, "Torii_H", Vector3(4.5, 0.25, 0.25), Vector3(0, 3.5, h - 1.0),    mat_h_wood)
	# 石灯籠
	_cyl(p, "Lantern_L_Base", 0.25, 0.6, Vector3(-1.5, 0.3, 0.5), mat_h_stone)
	_box(p, "Lantern_L_Top",  Vector3(0.5, 0.5, 0.5), Vector3(-1.5, 0.85, 0.5), mat_h_stone)
	_cyl(p, "Lantern_R_Base", 0.25, 0.6, Vector3( 1.5, 0.3, 0.5), mat_h_stone)
	_box(p, "Lantern_R_Top",  Vector3(0.5, 0.5, 0.5), Vector3( 1.5, 0.85, 0.5), mat_h_stone)
	# 倒れた石碑
	_box(p, "Stele", Vector3(0.25, 1.2, 0.1), Vector3(-3.0, 0.2, -1.0), mat_h_stone)
	_box(p, "Stele", Vector3(0.25, 1.2, 0.1), Vector3(-3.0, 0.2, -1.0), mat_h_stone)


# 民家（廃屋）
func _props_farmhouse(p: Node3D, rng: RandomNumberGenerator) -> void:
	# 囲炉裏（中央）
	_box(p, "Irori_Frame", Vector3(1.2, 0.08, 1.2), Vector3(0, 0.04, 0.5), mat_h_stone)
	_box(p, "Irori_Ash",   Vector3(0.8, 0.06, 0.8), Vector3(0, 0.07, 0.5), mat_h_blood)
	# 箪笥
	_box(p, "Tansu",       Vector3(1.2, 1.2, 0.5), Vector3(-3.0, 0.6, -2.5), mat_h_wood)
	_box(p, "Tansu_Door",  Vector3(0.55, 1.0, 0.05), Vector3(-3.0, 0.6, -2.25), mat_h_wood)
	# 布団（床置き）
	_box(p, "Futon", Vector3(1.0, 0.18, 2.0), Vector3(2.0, 0.09, -1.5), mat_fabric)
	_box(p, "Pillow", Vector3(0.8, 0.15, 0.4), Vector3(2.0, 0.24, -2.3), mat_fabric)
	# 柱
	_box(p, "Pillar_NW", Vector3(0.2, _ceil_h, 0.2), Vector3(-3.5, _ceil_h * 0.5, -3.5), mat_h_wood)
	_box(p, "Pillar_NE", Vector3(0.2, _ceil_h, 0.2), Vector3( 3.5, _ceil_h * 0.5, -3.5), mat_h_wood)
	# ランダム小物
	if rng.randf() > 0.4:
		_box(p, "BrokenPot", Vector3(0.4, 0.4, 0.4), Vector3(
			rng.randf_range(-2.0, 2.0), 0.2, rng.randf_range(-2.0, 2.0)), mat_h_stone)


# 納屋
func _props_barn(p: Node3D) -> void:
	var h := _cell_size * 0.5
	# 藁の山
	_box(p, "Hay_A", Vector3(3.0, 1.2, 1.5), Vector3(-1.5, 0.6, -3.0), mat_h_thatch)
	_box(p, "Hay_B", Vector3(2.0, 0.9, 1.2), Vector3( 2.0, 0.45, -3.0), mat_h_thatch)
	# 農具掛け（壁）
	_box(p, "ToolRack", Vector3(3.0, 0.1, 0.08), Vector3(0, 2.5, -(h - 0.5)), mat_h_wood)
	# 農具（鍬・鎌のシルエット）
	_box(p, "Kwa", Vector3(0.06, 1.5, 0.06), Vector3(-0.8, 1.8, -(h - 0.45)), mat_h_wood)
	_box(p, "Kama", Vector3(0.06, 1.2, 0.06), Vector3( 0.2, 1.7, -(h - 0.45)), mat_h_wood)
	# 木箱・壺
	_box(p, "Crate1", Vector3(1.0, 1.0, 1.0), Vector3( 3.0, 0.5, 2.0), mat_h_wood)
	_box(p, "Crate2", Vector3(0.9, 0.9, 0.9), Vector3( 3.0, 1.45, 2.0), mat_h_wood)
	_cyl(p, "Jar1", 0.3, 0.75, Vector3(-3.5, 0.375, 2.5), mat_h_stone)
	_cyl(p, "Jar2", 0.25, 0.6, Vector3(-2.8, 0.3, 2.5), mat_h_stone)
	# 水桶
	_cyl(p, "Bucket", 0.35, 0.55, Vector3(1.0, 0.275, 3.0), mat_h_wood)


# 井戸広場
func _props_well(p: Node3D) -> void:
	# 井戸本体
	_cyl(p, "Well_Ring1", 0.85, 0.08, Vector3(0, 0.04, 0), mat_h_stone)
	_cyl(p, "Well_Ring2", 0.78, 0.6,  Vector3(0, 0.3,  0), mat_h_stone)
	_cyl(p, "Well_Inner", 0.55, 0.62, Vector3(0, 0.31, 0), mat_h_ground)
	# 井戸の屋根柱
	_box(p, "Well_Post_NW", Vector3(0.12, 1.5, 0.12), Vector3(-0.7, 0.75, -0.7), mat_h_wood)
	_box(p, "Well_Post_NE", Vector3(0.12, 1.5, 0.12), Vector3( 0.7, 0.75, -0.7), mat_h_wood)
	_box(p, "Well_Post_SW", Vector3(0.12, 1.5, 0.12), Vector3(-0.7, 0.75,  0.7), mat_h_wood)
	_box(p, "Well_Post_SE", Vector3(0.12, 1.5, 0.12), Vector3( 0.7, 0.75,  0.7), mat_h_wood)
	_box(p, "Well_Beam",    Vector3(1.5, 0.12, 0.12), Vector3(0, 1.56, 0), mat_h_wood)
	# 周辺石
	_box(p, "Stone_A", Vector3(0.5, 0.25, 0.4), Vector3(-2.0, 0.125, 1.5), mat_h_stone)
	_box(p, "Stone_B", Vector3(0.4, 0.20, 0.3), Vector3( 2.2, 0.10,  1.0), mat_h_stone)
	# 苔
	_box(p, "Moss_A", Vector3(2.0, 0.02, 1.5), Vector3(1.5, 0.01, 2.0), mat_h_moss)


# 村広場
func _props_village_sq(p: Node3D) -> void:
	# 中央の古い集会台
	_box(p, "Stage",      Vector3(4.0, 0.35, 3.0), Vector3(0, 0.175, 0), mat_h_wood)
	_box(p, "Stage_Step", Vector3(4.0, 0.20, 0.5), Vector3(0, 0.10, 1.75), mat_h_stone)
	# 椅子代わりの石
	for i in 4:
		var angle := i * 90.0
		var rx := sin(deg_to_rad(angle)) * 4.5
		var rz := cos(deg_to_rad(angle)) * 4.5
		_box(p, "Seat_%d" % i, Vector3(0.8, 0.45, 0.5), Vector3(rx, 0.225, rz), mat_h_stone)
	# 掲示板（腐りかけ）
	_box(p, "Board_Post_L", Vector3(0.1, 1.8, 0.1), Vector3(-1.0, 0.9, -4.5), mat_h_wood)
	_box(p, "Board_Post_R", Vector3(0.1, 1.8, 0.1), Vector3( 1.0, 0.9, -4.5), mat_h_wood)
	_box(p, "Board_Panel",  Vector3(2.0, 0.9, 0.06), Vector3(0, 1.6, -4.5), mat_h_wood)
	# 燃えた後（灰）
	_box(p, "Ash_Pile", Vector3(1.5, 0.08, 1.5), Vector3(3.0, 0.04, 3.0), mat_h_blood)


# 廃墟（崩れた建物の残骸）
func _props_ruin(p: Node3D, rng: RandomNumberGenerator) -> void:
	var h := _cell_size * 0.5
	# 崩れた壁の残骸
	_box(p, "Wall_Ruin_A", Vector3(3.5, 2.2, 0.4), Vector3(-1.0, 1.1, -(h - 0.5)), mat_h_stone)
	_box(p, "Wall_Ruin_B", Vector3(1.8, 1.4, 0.4), Vector3( 2.5, 0.7, -(h - 0.5)), mat_h_stone)
	_box(p, "Wall_Ruin_C", Vector3(0.4, 3.0, 2.0), Vector3(-(h - 0.5), 1.5,  0.0), mat_h_stone)
	# 崩れた木材
	for i in 3:
		var lx := rng.randf_range(-3.0, 3.0)
		var lz := rng.randf_range(-3.0, 3.0)
		var lr := rng.randf_range(0, 3.14)
		var beam := CSGBox3D.new()
		beam.name = "Beam_%d" % i
		beam.size = Vector3(rng.randf_range(1.5, 3.5), 0.15, 0.15)
		beam.position = Vector3(lx, 0.08, lz)
		beam.rotation.y = lr
		beam.use_collision = true
		beam.material = mat_h_wood
		p.add_child(beam)
	# 瓦礫の山
	_box(p, "Rubble_A", Vector3(1.8, 0.7, 1.5), Vector3( 2.5, 0.35, 2.0), mat_h_stone)
	_box(p, "Rubble_B", Vector3(1.2, 0.5, 1.0), Vector3(-2.0, 0.25, 2.5), mat_h_stone)
	# 血痕
	if rng.randf() > 0.3:
		_box(p, "Blood_Ruin", Vector3(rng.randf_range(0.5, 1.5), 0.005, rng.randf_range(0.4, 1.0)),
			Vector3(rng.randf_range(-2.0, 2.0), 0.003, rng.randf_range(-2.0, 2.0)), mat_h_blood)


# 廃村 出口エリア (EXIT_HALL に ENTRANCE テーマを再利用)
func _props_haison_exit(p: Node3D) -> void:
	var h := _cell_size * 0.5
	# 村の入口表示（腐った木の看板）
	_box(p, "Sign_Post_L", Vector3(0.12, 2.5, 0.12), Vector3(-1.5, 1.25, h - 0.8), mat_h_wood)
	_box(p, "Sign_Post_R", Vector3(0.12, 2.5, 0.12), Vector3( 1.5, 1.25, h - 0.8), mat_h_wood)
	_box(p, "Sign_Board",  Vector3(3.0, 0.6, 0.08), Vector3(0, 2.2, h - 0.8),      mat_h_wood)
	# 石畳（出口付近）
	_box(p, "Paving_A", Vector3(4.0, 0.08, 1.5), Vector3(0, 0.04, h - 1.5), mat_h_stone)


# ──────────────────────────────────────────────
# ホラーディテール（共通）
# ──────────────────────────────────────────────

func _add_horror_details(parent: Node3D, cell: Dictionary, rng: RandomNumberGenerator) -> void:
	var theme: int = cell.theme
	var sockets: Array = cell.sockets
	var is_outdoor: bool = cell.get("outdoor", false)

	var blood_mat := mat_blood if _map_type == WFCGenerator.MapType.INDUSTRIAL else mat_h_blood

	# 血痕（床）
	var blood_chance := 0.20
	if theme in [WFCGenerator.RoomTheme.MACHINE_RM, WFCGenerator.RoomTheme.STORAGE,
				  WFCGenerator.RoomTheme.RUIN]:
		blood_chance = 0.55
	if rng.randf() < blood_chance:
		var count := rng.randi_range(1, 2)
		for i in count:
			_box(parent, "Blood_%d" % i,
				Vector3(rng.randf_range(0.4, 1.5), 0.005, rng.randf_range(0.3, 1.0)),
				Vector3(rng.randf_range(-3.0, 3.0), 0.003, rng.randf_range(-3.0, 3.0)),
				blood_mat)

	if is_outdoor:
		return  # 屋外はひび割れ・蜘蛛の巣なし

	var closed_faces: Array[int] = []
	for face in [WFCGenerator.Face.N, WFCGenerator.Face.E,
				  WFCGenerator.Face.S, WFCGenerator.Face.W]:
		if sockets[face] == WFCGenerator.Socket.CLOSED:
			closed_faces.append(face)

	# 壁のひび割れ
	if closed_faces.size() > 0 and rng.randf() < 0.55:
		var crack_count := rng.randi_range(1, 2)
		for i in crack_count:
			var cw := rng.randf_range(0.01, 0.025)
			var crk_h := rng.randf_range(0.4, 1.8)
			var face: int = closed_faces[rng.randi_range(0, closed_faces.size() - 1)]
			var half := _cell_size * 0.5
			var cy := rng.randf_range(0.5, 3.0)
			var cx := rng.randf_range(-3.0, 3.0)
			var pos: Vector3
			var sz: Vector3
			match face:
				WFCGenerator.Face.N: pos = Vector3(cx, cy, -half + 0.18); sz = Vector3(cw, crk_h, 0.005)
				WFCGenerator.Face.S: pos = Vector3(cx, cy,  half - 0.18); sz = Vector3(cw, crk_h, 0.005)
				WFCGenerator.Face.E: pos = Vector3(half - 0.18, cy, cx);  sz = Vector3(0.005, crk_h, cw)
				_:                   pos = Vector3(-half + 0.18, cy, cx); sz = Vector3(0.005, crk_h, cw)
			_box(parent, "Crack_%d" % i, sz, pos, mat_crack)

	# 蜘蛛の巣（角）
	if closed_faces.size() >= 2 and rng.randf() < 0.40:
		var half := _cell_size * 0.5
		var ceil_h := _ceil_h
		var has_n := WFCGenerator.Face.N in closed_faces
		var has_s := WFCGenerator.Face.S in closed_faces
		var has_e := WFCGenerator.Face.E in closed_faces
		var has_w := WFCGenerator.Face.W in closed_faces
		var corners: Array[Vector3] = []
		if has_n and has_w: corners.append(Vector3(-half + 0.4, ceil_h - 0.25, -half + 0.4))
		if has_n and has_e: corners.append(Vector3( half - 0.4, ceil_h - 0.25, -half + 0.4))
		if has_s and has_w: corners.append(Vector3(-half + 0.4, ceil_h - 0.25,  half - 0.4))
		if has_s and has_e: corners.append(Vector3( half - 0.4, ceil_h - 0.25,  half - 0.4))
		if corners.size() > 0:
			var corner: Vector3 = corners[rng.randi_range(0, corners.size() - 1)]
			_box(parent, "Cobweb", Vector3(1.5, 0.003, 1.5), corner, mat_cobweb)


# ──────────────────────────────────────────────
# GLB家具配置（インダストリアル専用）
# ──────────────────────────────────────────────

func _add_glb_furniture(parent: Node3D, cell: Dictionary, rng: RandomNumberGenerator) -> void:
	var furn := FurnitureScene.instantiate()
	furn.name = "Furniture_GLB"
	var half := _cell_size * 0.5
	var sockets: Array = cell.sockets

	var px := 0.0
	var pz := 0.0
	if sockets[WFCGenerator.Face.S] == WFCGenerator.Socket.CLOSED:
		px = rng.randf_range(-half + 1.5, half - 1.5)
		pz = half - 0.8
	elif sockets[WFCGenerator.Face.N] == WFCGenerator.Socket.CLOSED:
		px = rng.randf_range(-half + 1.5, half - 1.5)
		pz = -half + 0.8
	elif sockets[WFCGenerator.Face.E] == WFCGenerator.Socket.CLOSED:
		px = half - 0.8
		pz = rng.randf_range(-half + 1.5, half - 1.5)
	elif sockets[WFCGenerator.Face.W] == WFCGenerator.Socket.CLOSED:
		px = -half + 0.8
		pz = rng.randf_range(-half + 1.5, half - 1.5)
	else:
		px = rng.randf_range(-1.5, 1.5)
		pz = rng.randf_range(-1.5, 1.5)

	furn.position = Vector3(px, 0, pz)
	furn.scale = Vector3(1.1, 1.1, 1.1)
	parent.add_child(furn)


# ──────────────────────────────────────────────
# ゲームオブジェクト動的配置
# ──────────────────────────────────────────────

func _place_game_objects(result: Dictionary) -> void:
	var spawns: Dictionary = result.spawns

	# --- VHSアイテム ---
	var items_arr: Array = spawns.items
	item_count = items_arr.size()
	for i in items_arr.size():
		var item := ItemScene.instantiate()
		item.name = "Item_%d" % (i + 1)
		item.position = items_arr[i]
		add_child(item)

	# --- ゴースト (一時無効化) ---
	#var ghosts_arr: Array = spawns.ghosts
	#for i in ghosts_arr.size():
	#	...

	# --- ドア ---
	var doors_arr: Array = spawns.doors
	for i in doors_arr.size():
		var dd: Dictionary = doors_arr[i]
		var door := DoorScene.instantiate()
		door.name = "Door_%d" % (i + 1)
		var rot_y: float = dd.rotation_y
		var s := 2.0
		var cos_r := cos(deg_to_rad(rot_y))
		var sin_r := sin(deg_to_rad(rot_y))
		door.transform = Transform3D(
			Vector3(s * cos_r, 0, -s * sin_r),
			Vector3(0, s, 0),
			Vector3(s * sin_r, 0, s * cos_r),
			dd.pos
		)
		if dd.get("locked", false):
			door.set("key_name", "Key1")
			door.set("locked_message", "施錠されている…鍵が必要だ")
			door.set("open_message", "鍵が開いた！")
			door.set("on_lock_message", "施錠した")
			door.set("locking_open_message", "先にドアを閉めろ！")
			door.set("wrong_item_message", "この鍵では開かない")
		else:
			door.set("is_locked", false)
		add_child(door)

	# --- 鍵 ---
	if spawns.key != Vector3.ZERO:
		var key := KeyScene.instantiate()
		key.name = "Key_1"
		key.position = spawns.key
		add_child(key)
		var key_light := OmniLight3D.new()
		key_light.name = "KeyLight"
		key_light.position = spawns.key + Vector3(0, 0.5, 0)
		key_light.light_color = Color(1, 0.85, 0.3)
		key_light.light_energy = 0.35
		key_light.omni_range = 4.0
		add_child(key_light)

	# --- PowerCell ---
	var pc_arr: Array = spawns.power_cells
	for i in pc_arr.size():
		var pc := PowerCellScene.instantiate()
		pc.name = "PowerCell_%d" % (i + 1)
		pc.position = pc_arr[i]
		add_child(pc)

	# --- 出口 ---
	_create_exit(spawns.exit)


func _create_exit(pos: Vector3) -> void:
	var exit := Area3D.new()
	exit.name = "Exit"
	exit.position = pos

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.0, 3.0, 2.0)
	shape.shape = box
	exit.add_child(shape)

	var mesh := CSGBox3D.new()
	mesh.name = "ExitMesh"
	mesh.size = Vector3(2.5, 3.0, 0.3)
	mesh.use_collision = false
	var exit_mat := StandardMaterial3D.new()
	exit_mat.albedo_color = Color(0.15, 0.5, 0.2)
	exit_mat.emission_enabled = true
	exit_mat.emission = Color(0.1, 0.4, 0.15)
	exit_mat.emission_energy_multiplier = 0.5
	mesh.material = exit_mat
	exit.add_child(mesh)

	var light := OmniLight3D.new()
	light.name = "ExitLight"
	light.light_color = Color(0.2, 1.0, 0.35)
	light.light_energy = 0.6
	light.omni_range = 8.0
	exit.add_child(light)

	exit.script = ExitScript
	add_child(exit)
	exit_node = exit


# ──────────────────────────────────────────────
# 環境照明
# ──────────────────────────────────────────────

func _place_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR

	if _map_type == WFCGenerator.MapType.HAISON:
		# 廃村: 深夜の野外（月明かり・薄い霧）
		env.background_color = Color(0.01, 0.01, 0.03)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color  = Color(0.06, 0.06, 0.10)
		env.ambient_light_energy = 0.10
		env.fog_enabled    = true
		env.fog_light_color = Color(0.02, 0.02, 0.06)
		env.fog_light_energy = 0.05
		env.fog_density    = 0.018
	else:
		# インダストリアル: 完全な闇
		env.background_color = Color(0.0, 0.0, 0.0)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color  = Color(0.06, 0.05, 0.08)
		env.ambient_light_energy = 0.06
		env.fog_enabled    = true
		env.fog_light_color = Color(0.02, 0.01, 0.03)
		env.fog_light_energy = 0.04
		env.fog_density    = 0.014

	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	add_child(we)

	_add_room_lights()


func _add_room_lights() -> void:
	print("[StageGen] _add_room_lights() 実行中 (map_type=%d)" % _map_type)

	if _map_type == WFCGenerator.MapType.HAISON:
		_add_room_lights_haison()
	else:
		_add_room_lights_industrial()


func _add_room_lights_industrial() -> void:
	var lights := {
		"MACHINE_RM": { "color": Color(0.80, 0.55, 0.25), "energy": 0.22, "range": 14.0 },
		"GENERATOR":  { "color": Color(0.75, 0.65, 0.35), "energy": 0.18, "range": 12.0 },
		"CONTROL_RM": { "color": Color(0.55, 0.70, 1.00), "energy": 0.25, "range": 12.0 },
		"STORAGE":    { "color": Color(0.75, 0.55, 0.28), "energy": 0.16, "range": 14.0 },
		"CORRIDOR":   { "color": Color(0.70, 0.55, 0.28), "energy": 0.14, "range": 14.0 },
		"WORKSHOP":   { "color": Color(0.85, 0.75, 0.45), "energy": 0.28, "range": 14.0 },
		"CORRIDOR2":  { "color": Color(0.65, 0.45, 0.20), "energy": 0.10, "range": 12.0 },
		"STORAGE2":   { "color": Color(0.60, 0.42, 0.18), "energy": 0.09, "range": 12.0 },
		"LOADING":    { "color": Color(0.82, 0.72, 0.40), "energy": 0.30, "range": 18.0 },
		"ENTRANCE":   { "color": Color(0.90, 0.80, 0.48), "energy": 0.38, "range": 14.0 },
		"BREAK_ROOM": { "color": Color(0.85, 0.72, 0.42), "energy": 0.22, "range": 12.0 },
		"LOCKER":     { "color": Color(0.75, 0.65, 0.38), "energy": 0.16, "range": 10.0 },
		"VAULT":      { "color": Color(0.55, 0.60, 0.65), "energy": 0.12, "range": 12.0 },
		"MACHINE_B":  { "color": Color(0.80, 0.52, 0.22), "energy": 0.18, "range": 12.0 },
		"UTILITY":    { "color": Color(0.82, 0.78, 0.42), "energy": 0.24, "range": 12.0 },
		"PUMP_RM":    { "color": Color(0.78, 0.50, 0.22), "energy": 0.20, "range": 14.0 },
		"BOILER":     { "color": Color(0.90, 0.45, 0.18), "energy": 0.22, "range": 14.0 },
		"ARCHIVE":    { "color": Color(0.88, 0.82, 0.58), "energy": 0.20, "range": 12.0 },
		"FURNACE":    { "color": Color(1.00, 0.35, 0.12), "energy": 0.28, "range": 14.0 },
		"EXIT_HALL":  { "color": Color(0.65, 0.80, 0.50), "energy": 0.32, "range": 16.0 },
	}
	for room_name in lights:
		var node: Node3D = get_node_or_null("F0_%s" % room_name)
		if node:
			_create_room_light(node, room_name, lights[room_name])


func _add_room_lights_haison() -> void:
	# 屋内のみ薄い光を置く。屋外は月光（ambient）のみ
	var lights := {
		"SHRINE":      { "color": Color(0.90, 0.80, 0.50), "energy": 0.18, "range": 16.0 },
		"FARMHOUSE_A": { "color": Color(0.85, 0.65, 0.35), "energy": 0.12, "range": 12.0 },
		"FARMHOUSE_B": { "color": Color(0.85, 0.65, 0.35), "energy": 0.12, "range": 12.0 },
		"FARMHOUSE_C": { "color": Color(0.85, 0.65, 0.35), "energy": 0.12, "range": 12.0 },
		"FARMHOUSE_D": { "color": Color(0.85, 0.65, 0.35), "energy": 0.12, "range": 12.0 },
		"FARMHOUSE_E": { "color": Color(0.85, 0.65, 0.35), "energy": 0.12, "range": 12.0 },
		"FARMHOUSE_F": { "color": Color(0.85, 0.65, 0.35), "energy": 0.12, "range": 12.0 },
		"BARN":        { "color": Color(0.80, 0.55, 0.25), "energy": 0.10, "range": 14.0 },
		"RUIN":        { "color": Color(0.70, 0.50, 0.22), "energy": 0.08, "range": 10.0 },
		"EXIT_HALL":   { "color": Color(0.60, 0.80, 0.45), "energy": 0.25, "range": 14.0 },
	}
	for room_name in lights:
		var node: Node3D = get_node_or_null("F0_%s" % room_name)
		if node:
			_create_room_light(node, room_name, lights[room_name])


func _create_room_light(parent: Node3D, room_name: String, cfg: Dictionary) -> void:
	var light := OmniLight3D.new()
	light.name = "RoomLight_%s" % room_name
	light.position = Vector3(0, _ceil_h - 0.5, 0)
	light.light_color = cfg.color
	light.light_energy = cfg.energy
	light.omni_range = cfg.range
	light.shadow_enabled = false
	parent.add_child(light)

	# 天井ランプメッシュ（屋外セルには天井なしなので不要）
	var lamp_mesh := CSGBox3D.new()
	lamp_mesh.name = "LampFixture_%s" % room_name
	lamp_mesh.size = Vector3(1.2, 0.08, 0.15)
	lamp_mesh.position = Vector3(0, _ceil_h - 0.04, 0)
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.albedo_color = cfg.color
	lamp_mat.emission_enabled = true
	lamp_mat.emission = cfg.color
	lamp_mat.emission_energy_multiplier = 1.8
	lamp_mesh.material = lamp_mat
	parent.add_child(lamp_mesh)


# ──────────────────────────────────────────────
# ヘルパー
# ──────────────────────────────────────────────

func _box(parent: Node3D, n: String, sz: Vector3, pos: Vector3,
		  mat: StandardMaterial3D) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.name = n
	b.size = sz
	b.position = pos
	b.use_collision = true
	b.material = mat
	parent.add_child(b)
	return b


func _cyl(parent: Node3D, n: String, r: float, h: float, pos: Vector3,
		  mat: StandardMaterial3D) -> CSGCylinder3D:
	var c := CSGCylinder3D.new()
	c.name = n
	c.radius = r
	c.height = h
	c.sides = 12
	c.position = pos
	c.use_collision = true
	c.material = mat
	parent.add_child(c)
	return c
