@tool
extends Node3D

## 廃屋敷ステージ（木造和風）
## コンセプト: 入口から一本道 → 大きな屋敷の内部探索
## 構成: 玄関(南Z=12) → 土間廊下 → 広間 → 廊下分岐 → 和室群 → 中庭 → 奥座敷(北Z=-28)
## プレイヤースポーン: Vector3(0, 0.1, 11) / 出口: Vector3(0, 0.1, -18)
##
## Y座標ルール（Z-fighting防止）:
##   地面:   -0.15 (top = 0.0)
##   床:     0.01  (top = 0.09)  ← 地面と重ならない
##   畳:     0.10  (top = 0.14)  ← 床より上
##   小物:   0.15+ (床から離す)

# ════════════════════════════════════════════════════════════════
# テクスチャ
# ════════════════════════════════════════════════════════════════

const TEX_WOOD     := preload("res://assets/models/Industrial_exterior_v2_Box_wood.png")
const TEX_CONCRETE := preload("res://assets/models/Industrial_exterior_v2_Concrete.png")
const TEX_WALL_TEX := preload("res://assets/models/Industrial_exterior_v2_Wall.png")
const TEX_BARREL   := preload("res://assets/models/Industrial_exterior_v2_Barrel_1.png")

# ════════════════════════════════════════════════════════════════
# マテリアル
# ════════════════════════════════════════════════════════════════

var _mat_pillar    : StandardMaterial3D
var _mat_wall      : StandardMaterial3D
var _mat_wall_aged : StandardMaterial3D  # 経年劣化した壁
var _mat_floor     : StandardMaterial3D
var _mat_floor_old : StandardMaterial3D  # 古びた板の間
var _mat_ceiling   : StandardMaterial3D
var _mat_earth     : StandardMaterial3D
var _mat_tatami    : StandardMaterial3D
var _mat_tatami_old: StandardMaterial3D  # 色褪せた畳
var _mat_stone     : StandardMaterial3D
var _mat_fusuma    : StandardMaterial3D
var _mat_shoji     : StandardMaterial3D
var _mat_roof      : StandardMaterial3D
var _mat_rust      : StandardMaterial3D  # 錆びた金属


func _make_mat(tex: Texture2D, col: Color, rough: float, uv: Vector3, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if tex:
		m.albedo_texture = tex
	m.albedo_color = col
	m.roughness = rough
	m.uv1_scale = uv
	if metal > 0.0:
		m.metallic = metal
	if col.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _create_materials() -> void:
	_mat_pillar    = _make_mat(TEX_WOOD,     Color(0.20, 0.13, 0.07), 0.95, Vector3(2, 6, 2))
	_mat_wall      = _make_mat(TEX_WALL_TEX, Color(0.30, 0.22, 0.13), 0.92, Vector3(3, 2, 3))
	_mat_wall_aged = _make_mat(TEX_WALL_TEX, Color(0.24, 0.18, 0.10), 0.96, Vector3(2, 2, 2))
	_mat_floor     = _make_mat(TEX_WOOD,     Color(0.26, 0.18, 0.10), 0.88, Vector3(6, 1, 6))
	_mat_floor_old = _make_mat(TEX_WOOD,     Color(0.20, 0.14, 0.08), 0.94, Vector3(5, 1, 5))
	_mat_ceiling   = _make_mat(TEX_WOOD,     Color(0.16, 0.12, 0.07), 0.96, Vector3(4, 1, 4))
	_mat_earth     = _make_mat(TEX_CONCRETE, Color(0.22, 0.18, 0.13), 0.98, Vector3(5, 5, 5))
	_mat_tatami    = _make_mat(null,         Color(0.28, 0.30, 0.16), 0.96, Vector3(1, 1, 1))
	_mat_tatami_old = _make_mat(null,        Color(0.24, 0.25, 0.14), 0.98, Vector3(1, 1, 1))
	_mat_stone     = _make_mat(TEX_CONCRETE, Color(0.38, 0.36, 0.32), 0.96, Vector3(3, 3, 3))
	_mat_fusuma    = _make_mat(TEX_WALL_TEX, Color(0.34, 0.28, 0.20), 0.94, Vector3(1, 2, 1))
	_mat_shoji     = _make_mat(null,         Color(0.55, 0.52, 0.45, 0.35), 0.90, Vector3(1, 1, 1))
	_mat_roof      = _make_mat(TEX_CONCRETE, Color(0.14, 0.12, 0.10), 0.98, Vector3(6, 6, 6))
	_mat_rust      = _make_mat(TEX_BARREL,   Color(0.30, 0.18, 0.10), 0.85, Vector3(1, 1, 1), 0.3)


# ════════════════════════════════════════════════════════════════
# 色パレット（テクスチャ無し小物用）
# ════════════════════════════════════════════════════════════════

const COL_TATAMI_EDGE := Color(0.18, 0.14, 0.09)
const COL_MOSS        := Color(0.10, 0.18, 0.06)
const COL_ASH         := Color(0.05, 0.04, 0.03)
const COL_EMBER       := Color(0.22, 0.05, 0.02)
const COL_SOOT        := Color(0.04, 0.03, 0.02)
const COL_CANDLE_GOLD := Color(0.65, 0.55, 0.25)
const COL_SHOE        := Color(0.08, 0.06, 0.05)
const COL_BLOOD_STAIN := Color(0.18, 0.03, 0.02)
const COL_COBWEB      := Color(0.60, 0.58, 0.55, 0.25)
const COL_DUST        := Color(0.30, 0.26, 0.20, 0.15)

# 天井高
const CEIL_H := 2.9
const WALL_THICK := 0.22
const PILLAR_SIZE := 0.16


func _ready() -> void:
	for c in get_children():
		c.queue_free()
	_create_materials()
	_build_foundation()
	_build_genkan()
	_build_doma_corridor()
	_build_hiroma()
	_build_west_rooms()
	_build_east_rooms()
	_build_nakaniwa()
	_build_oku_zashiki()
	_build_outer_walls()
	_build_roof()
	_build_aging_details()
	_build_lighting()
	if Engine.is_editor_hint():
		_set_editor_owner(self)


func _set_editor_owner(node: Node) -> void:
	for child in node.get_children():
		child.owner = get_tree().edited_scene_root
		_set_editor_owner(child)


# ════════════════════════════════════════════════════════════════
# ヘルパー
# ════════════════════════════════════════════════════════════════

func _box(pos: Vector3, size: Vector3, col: Color) -> void:
	StageHelper.box(self, pos, size, col)

func _deco(pos: Vector3, size: Vector3, col: Color) -> void:
	StageHelper.deco(self, pos, size, col)

func _tbox(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	mi.mesh = mesh
	mi.position = pos
	add_child(mi)
	var sb := StaticBody3D.new()
	sb.position = pos
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	sb.add_child(cs)
	add_child(sb)

func _tdeco(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	mi.mesh = mesh
	mi.position = pos
	add_child(mi)

func _pillar(pos: Vector3) -> void:
	_tbox(pos + Vector3(0, CEIL_H * 0.5, 0), Vector3(PILLAR_SIZE, CEIL_H, PILLAR_SIZE), _mat_pillar)

func _beam_x(pos: Vector3, length: float) -> void:
	_tdeco(pos + Vector3(0, CEIL_H - 0.08, 0), Vector3(length, 0.14, 0.14), _mat_pillar)

func _beam_z(pos: Vector3, length: float) -> void:
	_tdeco(pos + Vector3(0, CEIL_H - 0.08, 0), Vector3(0.14, 0.14, length), _mat_pillar)

func _wall_x(pos: Vector3, length: float, height: float = CEIL_H, mat: StandardMaterial3D = null) -> void:
	_tbox(pos + Vector3(0, height * 0.5, 0), Vector3(length, height, WALL_THICK), mat if mat else _mat_wall)

func _wall_z(pos: Vector3, length: float, height: float = CEIL_H, mat: StandardMaterial3D = null) -> void:
	_tbox(pos + Vector3(0, height * 0.5, 0), Vector3(WALL_THICK, height, length), mat if mat else _mat_wall)

func _floor_panel(pos: Vector3, sx: float, sz: float, mat: StandardMaterial3D = null) -> void:
	_tbox(pos + Vector3(0, 0.045, 0), Vector3(sx, 0.09, sz), mat if mat else _mat_floor)

func _ceiling_panel(pos: Vector3, sx: float, sz: float) -> void:
	_tdeco(pos + Vector3(0, CEIL_H, 0), Vector3(sx, 0.06, sz), _mat_ceiling)

func _tatami(pos: Vector3, rotated: bool = false, old: bool = false) -> void:
	var sx : float = 1.8 if not rotated else 0.9
	var sz : float = 0.9 if not rotated else 1.8
	var mat : StandardMaterial3D = _mat_tatami_old if old else _mat_tatami
	_tdeco(pos + Vector3(0, 0.10, 0), Vector3(sx, 0.04, sz), mat)
	if not rotated:
		_deco(pos + Vector3(0, 0.125, -0.44), Vector3(sx, 0.01, 0.03), COL_TATAMI_EDGE)
		_deco(pos + Vector3(0, 0.125,  0.44), Vector3(sx, 0.01, 0.03), COL_TATAMI_EDGE)
	else:
		_deco(pos + Vector3(-0.44, 0.125, 0), Vector3(0.03, 0.01, sz), COL_TATAMI_EDGE)
		_deco(pos + Vector3( 0.44, 0.125, 0), Vector3(0.03, 0.01, sz), COL_TATAMI_EDGE)

## 障子枠付き（格子を表現）
func _shoji_panel(pos: Vector3, width: float, along_x: bool) -> void:
	var h : float = CEIL_H * 0.88
	if along_x:
		_tdeco(pos + Vector3(0, h * 0.5, 0), Vector3(width, h, 0.05), _mat_shoji)
		# 枠
		_tdeco(pos + Vector3(0, h, 0),          Vector3(width, 0.04, 0.06), _mat_pillar)
		_tdeco(pos + Vector3(0, 0.02, 0),       Vector3(width, 0.04, 0.06), _mat_pillar)
		_tdeco(pos + Vector3(-width * 0.5, h * 0.5, 0), Vector3(0.04, h, 0.06), _mat_pillar)
		_tdeco(pos + Vector3( width * 0.5, h * 0.5, 0), Vector3(0.04, h, 0.06), _mat_pillar)
		# 横桟
		_tdeco(pos + Vector3(0, h * 0.33, 0), Vector3(width, 0.02, 0.04), _mat_pillar)
		_tdeco(pos + Vector3(0, h * 0.66, 0), Vector3(width, 0.02, 0.04), _mat_pillar)
	else:
		_tdeco(pos + Vector3(0, h * 0.5, 0), Vector3(0.05, h, width), _mat_shoji)
		_tdeco(pos + Vector3(0, h, 0),          Vector3(0.06, 0.04, width), _mat_pillar)
		_tdeco(pos + Vector3(0, 0.02, 0),       Vector3(0.06, 0.04, width), _mat_pillar)
		_tdeco(pos + Vector3(0, h * 0.5, -width * 0.5), Vector3(0.06, h, 0.04), _mat_pillar)
		_tdeco(pos + Vector3(0, h * 0.5,  width * 0.5), Vector3(0.06, h, 0.04), _mat_pillar)
		_tdeco(pos + Vector3(0, h * 0.33, 0), Vector3(0.04, 0.02, width), _mat_pillar)
		_tdeco(pos + Vector3(0, h * 0.66, 0), Vector3(0.04, 0.02, width), _mat_pillar)

## 襖（枠付き）
func _fusuma_panel(pos: Vector3, width: float, along_x: bool) -> void:
	var h : float = CEIL_H * 0.88
	if along_x:
		_tdeco(pos + Vector3(0, h * 0.5, 0), Vector3(width, h, 0.06), _mat_fusuma)
		_tdeco(pos + Vector3(0, h, 0),       Vector3(width + 0.04, 0.04, 0.07), _mat_pillar)
		_tdeco(pos + Vector3(0, 0.02, 0),    Vector3(width + 0.04, 0.04, 0.07), _mat_pillar)
		# 引き手（小さい丸の代わりに小さい四角）
		_deco(pos + Vector3(width * 0.3, h * 0.45, -0.035), Vector3(0.06, 0.08, 0.01), COL_CANDLE_GOLD)
	else:
		_tdeco(pos + Vector3(0, h * 0.5, 0), Vector3(0.06, h, width), _mat_fusuma)
		_tdeco(pos + Vector3(0, h, 0),       Vector3(0.07, 0.04, width + 0.04), _mat_pillar)
		_tdeco(pos + Vector3(0, 0.02, 0),    Vector3(0.07, 0.04, width + 0.04), _mat_pillar)
		_deco(pos + Vector3(-0.035, h * 0.45, width * 0.3), Vector3(0.01, 0.08, 0.06), COL_CANDLE_GOLD)


# ════════════════════════════════════════════════════════════════
# 基礎（地面のみ・デコ重ねなし）
# ════════════════════════════════════════════════════════════════

func _build_foundation() -> void:
	_tbox(Vector3(0, -0.15, -8), Vector3(30, 0.3, 50), _mat_earth)


# ════════════════════════════════════════════════════════════════
# 玄関（南端・入口）Z=9.7〜12.2
# ════════════════════════════════════════════════════════════════

func _build_genkan() -> void:
	# 土間の床
	_floor_panel(Vector3(0, -0.05, 11), 4.0, 2.5, _mat_earth)
	# 上がり框（装飾のみ）
	_tdeco(Vector3(0, 0.05, 9.7), Vector3(3.6, 0.08, 0.25), _mat_pillar)
	# 板の間
	_floor_panel(Vector3(0, 0.0, 9.0), 4.0, 1.2)

	# 壁
	_wall_z(Vector3(-2.0, 0, 10.5), 3.5)
	_wall_z(Vector3( 2.0, 0, 10.5), 3.5)
	_wall_x(Vector3(-1.4, 0, 12.2), 1.5)
	_wall_x(Vector3( 1.4, 0, 12.2), 1.5)
	_ceiling_panel(Vector3(0, 0, 10.5), 4.0, 3.5)

	# 柱
	_pillar(Vector3(-2.0, 0, 8.5))
	_pillar(Vector3( 2.0, 0, 8.5))
	_pillar(Vector3(-2.0, 0, 12.2))
	_pillar(Vector3( 2.0, 0, 12.2))

	# 靴（土間床top=0.04 の上に置く）
	_deco(Vector3(-0.4, 0.06, 11.3), Vector3(0.22, 0.04, 0.10), COL_SHOE)
	_deco(Vector3(-0.2, 0.06, 11.4), Vector3(0.22, 0.04, 0.10), COL_SHOE)
	# 傘立て
	_tbox(Vector3(1.6, 0.25, 11.5), Vector3(0.25, 0.50, 0.25), _mat_rust)


# ════════════════════════════════════════════════════════════════
# 土間廊下（玄関→広間）Z=4.7〜8.7
# ════════════════════════════════════════════════════════════════

func _build_doma_corridor() -> void:
	_floor_panel(Vector3(0, 0, 6.7), 2.2, 4.0)
	_wall_z(Vector3(-1.1, 0, 6.7), 4.0)
	_wall_z(Vector3( 1.1, 0, 6.7), 4.0)
	_ceiling_panel(Vector3(0, 0, 6.7), 2.2, 4.0)

	_beam_x(Vector3(0, 0, 7.5), 2.2)
	_beam_x(Vector3(0, 0, 5.5), 2.2)
	_pillar(Vector3(-1.1, 0, 4.7))
	_pillar(Vector3( 1.1, 0, 4.7))

	# 壁掛け（古い額縁）
	_tdeco(Vector3(-1.0, 1.5, 7.0), Vector3(0.04, 0.5, 0.4), _mat_fusuma)
	_tdeco(Vector3(-1.0, 1.5, 7.0), Vector3(0.02, 0.55, 0.45), _mat_pillar)


# ════════════════════════════════════════════════════════════════
# 広間（中央ハブ）Z=-0.2〜4.7
# ════════════════════════════════════════════════════════════════

func _build_hiroma() -> void:
	_floor_panel(Vector3(0, 0, 2.3), 8.0, 5.0)
	_ceiling_panel(Vector3(0, 0, 2.3), 8.0, 5.0)

	# 壁（開口部あり）
	_wall_x(Vector3(-3.0, 0, -0.2), 2.2)
	_wall_x(Vector3( 3.0, 0, -0.2), 2.2)
	_wall_x(Vector3(-2.6, 0, 4.7), 3.0)
	_wall_x(Vector3( 2.6, 0, 4.7), 3.0)
	_wall_z(Vector3(-4.0, 0, 3.6), 2.0)
	_wall_z(Vector3(-4.0, 0, 0.7), 1.8)
	_wall_z(Vector3( 4.0, 0, 3.6), 2.0)
	_wall_z(Vector3( 4.0, 0, 0.7), 1.8)

	# 柱
	_pillar(Vector3(-4.0, 0, 4.7))
	_pillar(Vector3( 4.0, 0, 4.7))
	_pillar(Vector3(-4.0, 0, -0.2))
	_pillar(Vector3( 4.0, 0, -0.2))
	_pillar(Vector3( 0.0, 0, -0.2))

	# 梁
	_beam_x(Vector3(0, 0, 2.3), 8.0)
	_beam_z(Vector3(-2.0, 0, 2.3), 5.0)
	_beam_z(Vector3( 2.0, 0, 2.3), 5.0)

	# 囲炉裏（石枠は床より十分上に）
	_tbox(Vector3(0, 0.14, 2.3), Vector3(1.2, 0.18, 1.2), _mat_stone)
	_deco(Vector3(0, 0.24, 2.3), Vector3(0.85, 0.02, 0.85), COL_ASH)
	_deco(Vector3( 0.12, 0.26, 2.2), Vector3(0.18, 0.03, 0.12), COL_EMBER)
	_deco(Vector3(-0.15, 0.26, 2.4), Vector3(0.14, 0.03, 0.10), COL_EMBER)
	# 自在鉤
	_tdeco(Vector3(0, CEIL_H * 0.55, 2.3), Vector3(0.04, CEIL_H * 0.9, 0.04), _mat_pillar)
	# 鉤の横棒
	_tdeco(Vector3(0, 0.40, 2.3), Vector3(0.30, 0.03, 0.03), _mat_rust)


# ════════════════════════════════════════════════════════════════
# 西の間（台所＋六畳和室）
# ════════════════════════════════════════════════════════════════

func _build_west_rooms() -> void:
	# ── 台所（土間） ──
	_floor_panel(Vector3(-6.7, -0.04, 3.0), 5.0, 3.5, _mat_earth)
	_ceiling_panel(Vector3(-6.7, 0, 3.0), 5.0, 3.5)
	_wall_z(Vector3(-9.2, 0, 3.0), 3.5, CEIL_H, _mat_wall_aged)
	_wall_x(Vector3(-6.7, 0, 4.7), 5.0)
	_wall_x(Vector3(-5.8, 0, 1.2), 1.8)
	_wall_x(Vector3(-8.4, 0, 1.2), 1.8)

	# かまど
	_tbox(Vector3(-8.2, 0.35, 4.0), Vector3(1.0, 0.70, 0.8), _mat_stone)
	_deco(Vector3(-8.2, 0.75, 4.0), Vector3(0.7, 0.10, 0.5), COL_SOOT)
	# 煙突（天井まで）
	_tdeco(Vector3(-8.2, 1.5, 4.0), Vector3(0.30, 2.0, 0.30), _mat_stone)
	# 棚
	_tbox(Vector3(-8.8, 0.80, 2.0), Vector3(0.6, 0.06, 1.4), _mat_pillar)
	_tbox(Vector3(-8.8, 1.30, 2.0), Vector3(0.6, 0.06, 1.4), _mat_pillar)
	# 棚の上の壺
	_tdeco(Vector3(-8.7, 0.92, 1.6), Vector3(0.14, 0.18, 0.14), _mat_stone)
	_tdeco(Vector3(-8.9, 0.92, 2.3), Vector3(0.12, 0.16, 0.12), _mat_earth)
	# 水瓶
	_tbox(Vector3(-5.5, 0.25, 4.2), Vector3(0.50, 0.50, 0.50), _mat_stone)

	_pillar(Vector3(-9.2, 0, 4.7))
	_pillar(Vector3(-9.2, 0, 1.2))
	_pillar(Vector3(-4.2, 0, 1.2))
	_beam_x(Vector3(-6.7, 0, 3.0), 5.0)

	# ── 六畳和室 ──
	_floor_panel(Vector3(-6.7, 0, -0.5), 5.0, 3.5, _mat_floor_old)
	_ceiling_panel(Vector3(-6.7, 0, -0.5), 5.0, 3.5)

	_tatami(Vector3(-5.8, 0, 0.2))
	_tatami(Vector3(-5.8, 0, -1.2), false, true)
	_tatami(Vector3(-7.6, 0, 0.2), false, true)
	_tatami(Vector3(-7.6, 0, -1.2))
	_tatami(Vector3(-5.8, 0, -0.5), true)
	_tatami(Vector3(-7.6, 0, -0.5), true, true)

	_wall_z(Vector3(-9.2, 0, -0.5), 3.5, CEIL_H, _mat_wall_aged)
	_wall_x(Vector3(-6.7, 0, -2.2), 5.0, CEIL_H, _mat_wall_aged)

	# 襖（枠付き）
	_fusuma_panel(Vector3(-4.1, 0, -0.8), 1.4, false)

	_pillar(Vector3(-9.2, 0, -2.2))
	_pillar(Vector3(-4.2, 0, -2.2))


# ════════════════════════════════════════════════════════════════
# 東の間（座敷＋仏間）
# ════════════════════════════════════════════════════════════════

func _build_east_rooms() -> void:
	# ── 座敷 ──
	_floor_panel(Vector3(6.7, 0, 3.0), 5.0, 3.5)
	_ceiling_panel(Vector3(6.7, 0, 3.0), 5.0, 3.5)

	_tatami(Vector3(5.8, 0, 3.7))
	_tatami(Vector3(5.8, 0, 2.3))
	_tatami(Vector3(7.6, 0, 3.7))
	_tatami(Vector3(7.6, 0, 2.3))

	_wall_z(Vector3(9.2, 0, 3.0), 3.5)
	_wall_x(Vector3(6.7, 0, 4.7), 5.0)

	# 障子（枠付き）
	_shoji_panel(Vector3(9.05, 0, 3.0), 2.8, false)

	# 座卓
	_tbox(Vector3(6.7, 0.20, 3.0), Vector3(1.0, 0.05, 0.6), _mat_pillar)
	_tbox(Vector3(6.3, 0.10, 2.8), Vector3(0.05, 0.20, 0.05), _mat_pillar)
	_tbox(Vector3(7.1, 0.10, 2.8), Vector3(0.05, 0.20, 0.05), _mat_pillar)
	_tbox(Vector3(6.3, 0.10, 3.2), Vector3(0.05, 0.20, 0.05), _mat_pillar)
	_tbox(Vector3(7.1, 0.10, 3.2), Vector3(0.05, 0.20, 0.05), _mat_pillar)
	# 座卓の上の湯呑み
	_deco(Vector3(6.5, 0.26, 2.9), Vector3(0.06, 0.06, 0.06), Color(0.65, 0.62, 0.55))

	_pillar(Vector3(9.2, 0, 4.7))
	_pillar(Vector3(9.2, 0, 1.2))
	_pillar(Vector3(4.2, 0, 1.2))
	_beam_x(Vector3(6.7, 0, 3.0), 5.0)

	# ── 仏間 ──
	_floor_panel(Vector3(6.7, 0, -0.5), 5.0, 3.5, _mat_floor_old)
	_ceiling_panel(Vector3(6.7, 0, -0.5), 5.0, 3.5)

	_tatami(Vector3(5.8, 0, 0.2), false, true)
	_tatami(Vector3(5.8, 0, -1.2), false, true)
	_tatami(Vector3(7.6, 0, 0.2), false, true)
	_tatami(Vector3(7.6, 0, -1.2), false, true)

	_wall_z(Vector3(9.2, 0, -0.5), 3.5, CEIL_H, _mat_wall_aged)
	_wall_x(Vector3(6.7, 0, -2.2), 5.0, CEIL_H, _mat_wall_aged)

	# 仏壇
	_tbox(Vector3(7.0, 0.50, -1.9), Vector3(1.2, 1.0, 0.6), _mat_pillar)
	_tdeco(Vector3(6.3, 0.70, -1.65), Vector3(0.04, 0.65, 0.30), _mat_fusuma)
	_tdeco(Vector3(7.7, 0.70, -1.65), Vector3(0.04, 0.65, 0.30), _mat_fusuma)
	# 燭台
	_deco(Vector3(6.5, 1.05, -1.85), Vector3(0.05, 0.12, 0.05), COL_CANDLE_GOLD)
	_deco(Vector3(7.5, 1.05, -1.85), Vector3(0.05, 0.12, 0.05), COL_CANDLE_GOLD)
	# 蝋燭の炎（微小な明るいブロック）
	_deco(Vector3(6.5, 1.13, -1.85), Vector3(0.02, 0.03, 0.02), Color(1.0, 0.8, 0.3))
	_deco(Vector3(7.5, 1.13, -1.85), Vector3(0.02, 0.03, 0.02), Color(1.0, 0.8, 0.3))
	# 位牌
	_deco(Vector3(7.0, 1.08, -1.88), Vector3(0.08, 0.16, 0.03), Color(0.12, 0.08, 0.04))
	# 線香立て
	_tdeco(Vector3(7.0, 1.04, -1.75), Vector3(0.08, 0.06, 0.08), _mat_stone)

	_fusuma_panel(Vector3(4.1, 0, -0.8), 1.4, false)

	_pillar(Vector3(9.2, 0, -2.2))
	_pillar(Vector3(4.2, 0, -2.2))


# ════════════════════════════════════════════════════════════════
# 中庭（天井なし）Z=-2〜-8
# ════════════════════════════════════════════════════════════════

func _build_nakaniwa() -> void:
	# 地面（苔＋砂利を高さで分離）
	_box(Vector3(0, 0.03, -5), Vector3(6.0, 0.04, 6.0), COL_MOSS)
	_tdeco(Vector3(0, 0.08, -5), Vector3(3.5, 0.02, 3.5), _mat_stone)

	# 庭石
	_tbox(Vector3(-1.5, 0.25, -5.5), Vector3(1.0, 0.44, 0.7), _mat_stone)
	_tbox(Vector3(1.2, 0.18, -4.2), Vector3(0.6, 0.30, 0.5), _mat_stone)
	_tdeco(Vector3(0.5, 0.12, -6.0), Vector3(0.35, 0.16, 0.30), _mat_stone)
	# 苔パッチ（石より上）
	_deco(Vector3(-1.5, 0.48, -5.5), Vector3(0.4, 0.02, 0.3), COL_MOSS)

	# 小さな灯篭
	_tbox(Vector3(1.8, 0.20, -6.2), Vector3(0.20, 0.40, 0.20), _mat_stone)
	_tbox(Vector3(1.8, 0.50, -6.2), Vector3(0.30, 0.20, 0.30), _mat_stone)
	_deco(Vector3(1.8, 0.62, -6.2), Vector3(0.12, 0.04, 0.12), Color(1.0, 0.9, 0.6, 0.5))

	# コの字廊下
	# 西廊下
	_floor_panel(Vector3(-4.0, 0, -5), 2.0, 6.0)
	_ceiling_panel(Vector3(-4.0, 0, -5), 2.0, 6.0)
	_wall_z(Vector3(-5.0, 0, -5), 6.0)
	# 東廊下
	_floor_panel(Vector3(4.0, 0, -5), 2.0, 6.0)
	_ceiling_panel(Vector3(4.0, 0, -5), 2.0, 6.0)
	_wall_z(Vector3(5.0, 0, -5), 6.0)
	# 北廊下
	_floor_panel(Vector3(0, 0, -8.0), 10.0, 2.0)
	_ceiling_panel(Vector3(0, 0, -8.0), 10.0, 2.0)

	# 縁側の柱（手すりの代わりに柱を列にして和風感UP）
	for z_pos in [-2.0, -5.0, -8.0]:
		_pillar(Vector3(-3.0, 0, z_pos))
		_pillar(Vector3( 3.0, 0, z_pos))

	# 外側の柱
	_pillar(Vector3(-5.0, 0, -2.0))
	_pillar(Vector3(-5.0, 0, -8.0))
	_pillar(Vector3( 5.0, 0, -2.0))
	_pillar(Vector3( 5.0, 0, -8.0))

	_beam_x(Vector3(-4.0, 0, -5.0), 2.0)
	_beam_x(Vector3( 4.0, 0, -5.0), 2.0)
	_beam_z(Vector3( 0.0, 0, -8.0), 2.0)


# ════════════════════════════════════════════════════════════════
# 奥座敷（北端）Z=-9〜-16
# ════════════════════════════════════════════════════════════════

func _build_oku_zashiki() -> void:
	_floor_panel(Vector3(0, 0, -12.5), 10.0, 7.0, _mat_floor_old)
	_ceiling_panel(Vector3(0, 0, -12.5), 10.0, 7.0)

	# 畳（4x3）
	for ix in range(4):
		for iz in range(3):
			var tx : float = -2.7 + ix * 1.85
			var tz : float = -11.0 + iz * -1.85
			_tatami(Vector3(tx, 0, tz), ix % 2 == 0, iz == 2)

	# 壁
	_wall_x(Vector3(-3.5, 0, -16.0), 3.2, CEIL_H, _mat_wall_aged)
	_wall_x(Vector3( 3.5, 0, -16.0), 3.2, CEIL_H, _mat_wall_aged)
	_wall_z(Vector3(-5.0, 0, -12.5), 7.0, CEIL_H, _mat_wall_aged)
	_wall_z(Vector3( 5.0, 0, -12.5), 7.0, CEIL_H, _mat_wall_aged)
	_wall_x(Vector3(-3.5, 0, -9.0), 3.2)
	_wall_x(Vector3( 3.5, 0, -9.0), 3.2)

	# 床の間
	_tbox(Vector3(3.5, 0.16, -15.2), Vector3(2.6, 0.22, 1.4), _mat_floor)
	# 掛け軸
	_tdeco(Vector3(4.2, 1.6, -15.88), Vector3(0.55, 1.5, 0.02), _mat_fusuma)
	_tdeco(Vector3(4.2, 1.6, -15.88), Vector3(0.60, 0.03, 0.03), _mat_pillar)  # 軸棒
	_tdeco(Vector3(4.2, 2.38, -15.88), Vector3(0.60, 0.03, 0.03), _mat_pillar)
	# 花瓶
	_tdeco(Vector3(3.0, 0.42, -15.3), Vector3(0.10, 0.22, 0.10), _mat_stone)
	# 枯れた花（花瓶から）
	_deco(Vector3(3.0, 0.58, -15.3), Vector3(0.15, 0.12, 0.08), Color(0.25, 0.18, 0.10))

	# 柱
	_pillar(Vector3(-5.0, 0, -9.0))
	_pillar(Vector3( 5.0, 0, -9.0))
	_pillar(Vector3(-5.0, 0, -16.0))
	_pillar(Vector3( 5.0, 0, -16.0))
	_pillar(Vector3( 0.0, 0, -9.0))
	_pillar(Vector3( 0.0, 0, -16.0))
	# 中間柱（大部屋の構造を強調）
	_pillar(Vector3(-2.5, 0, -12.5))
	_pillar(Vector3( 2.5, 0, -12.5))

	# 梁
	_beam_x(Vector3(0, 0, -12.5), 10.0)
	_beam_x(Vector3(0, 0, -9.5), 10.0)
	_beam_x(Vector3(0, 0, -15.5), 10.0)
	_beam_z(Vector3(-2.5, 0, -12.5), 7.0)
	_beam_z(Vector3( 2.5, 0, -12.5), 7.0)

	# 出口通路
	_floor_panel(Vector3(0, 0, -17.5), 2.5, 3.0)
	_wall_z(Vector3(-1.2, 0, -17.5), 3.0)
	_wall_z(Vector3( 1.2, 0, -17.5), 3.0)
	_ceiling_panel(Vector3(0, 0, -17.5), 2.5, 3.0)


# ════════════════════════════════════════════════════════════════
# 外壁補助
# ════════════════════════════════════════════════════════════════

func _build_outer_walls() -> void:
	_wall_z(Vector3(-9.2, 0, -2.2), 0.5, CEIL_H, _mat_wall_aged)
	_wall_z(Vector3(-5.0, 0, -0.5), 3.0)
	_wall_z(Vector3(9.2, 0, -2.2), 0.5, CEIL_H, _mat_wall_aged)
	_wall_z(Vector3(5.0, 0, -0.5), 3.0)
	_wall_x(Vector3(-5.0, 0, -19.0), 7.8, CEIL_H, _mat_wall_aged)
	_wall_x(Vector3( 5.0, 0, -19.0), 7.8, CEIL_H, _mat_wall_aged)


# ════════════════════════════════════════════════════════════════
# 屋根
# ════════════════════════════════════════════════════════════════

func _build_roof() -> void:
	_tdeco(Vector3(0, CEIL_H + 0.8, 2.5), Vector3(20.0, 0.15, 16.0), _mat_roof)
	_tdeco(Vector3(0, CEIL_H + 1.0, 2.5), Vector3(0.16, 0.16, 16.0), _mat_pillar)
	_tdeco(Vector3(0, CEIL_H + 0.8, -12.5), Vector3(12.0, 0.15, 9.0), _mat_roof)
	_tdeco(Vector3(0, CEIL_H + 1.0, -12.5), Vector3(0.16, 0.16, 9.0), _mat_pillar)


# ════════════════════════════════════════════════════════════════
# 経年劣化ディテール（蜘蛛の巣・埃・シミ）
# ════════════════════════════════════════════════════════════════

func _build_aging_details() -> void:
	# 蜘蛛の巣（天井の隅）
	_deco(Vector3(-3.9, CEIL_H - 0.1, 4.6), Vector3(0.8, 0.6, 0.02), COL_COBWEB)
	_deco(Vector3( 3.9, CEIL_H - 0.1, 4.6), Vector3(0.6, 0.5, 0.02), COL_COBWEB)
	_deco(Vector3(-9.1, CEIL_H - 0.1, 4.6), Vector3(0.5, 0.4, 0.02), COL_COBWEB)
	_deco(Vector3(-4.9, CEIL_H - 0.1, -7.9), Vector3(0.7, 0.5, 0.02), COL_COBWEB)
	_deco(Vector3( 4.9, CEIL_H - 0.1, -7.9), Vector3(0.5, 0.6, 0.02), COL_COBWEB)

	# 埃（廊下の隅に溜まった感じ）
	_deco(Vector3(-0.9, 0.10, 6.0), Vector3(0.4, 0.01, 0.3), COL_DUST)
	_deco(Vector3( 0.9, 0.10, 7.2), Vector3(0.3, 0.01, 0.4), COL_DUST)

	# 床のシミ（仏間に薄い血痕）
	_deco(Vector3(6.0, 0.11, -0.8), Vector3(0.5, 0.005, 0.7), COL_BLOOD_STAIN)

	# 壁の傷跡（広間の壁に3本線）
	for i in range(3):
		var y_off : float = 1.2 + i * 0.15
		_deco(Vector3(-3.88, y_off, 1.0 + i * 0.08), Vector3(0.01, 0.4, 0.02), Color(0.10, 0.07, 0.04))


# ════════════════════════════════════════════════════════════════
# ライティング
# ════════════════════════════════════════════════════════════════

func _build_lighting() -> void:
	# 中庭の月明かり
	var moon := OmniLight3D.new()
	moon.position      = Vector3(0, 8.0, -5.0)
	moon.light_color   = Color(0.50, 0.55, 0.75)
	moon.light_energy  = 1.5
	moon.omni_range    = 16.0
	add_child(moon)

	# 囲炉裏の残り火
	var irori := OmniLight3D.new()
	irori.position     = Vector3(0, 0.35, 2.3)
	irori.light_color  = Color(1.0, 0.50, 0.15)
	irori.light_energy = 0.8
	irori.omni_range   = 6.0
	add_child(irori)

	# 仏壇の蝋燭
	var candle := OmniLight3D.new()
	candle.position     = Vector3(7.0, 1.2, -1.85)
	candle.light_color  = Color(1.0, 0.70, 0.30)
	candle.light_energy = 0.6
	candle.omni_range   = 4.0
	add_child(candle)

	# 奥座敷
	var oku := OmniLight3D.new()
	oku.position     = Vector3(0, 2.0, -12.5)
	oku.light_color  = Color(0.45, 0.50, 0.70)
	oku.light_energy = 0.5
	oku.omni_range   = 9.0
	add_child(oku)

	# 玄関の外光（入口からの薄明かり）
	var genkan := SpotLight3D.new()
	genkan.position    = Vector3(0, 2.5, 13.0)
	genkan.light_color = Color(0.40, 0.45, 0.60)
	genkan.light_energy = 0.8
	genkan.spot_range  = 8.0
	genkan.spot_angle  = 50.0
	add_child(genkan)
	genkan.look_at(Vector3(0, 0.5, 10.0))

	# 灯篭（中庭）
	var lantern := OmniLight3D.new()
	lantern.position     = Vector3(1.8, 0.6, -6.2)
	lantern.light_color  = Color(1.0, 0.85, 0.50)
	lantern.light_energy = 0.3
	lantern.omni_range   = 3.0
	add_child(lantern)

	# 障子越しの光（東座敷）
	var shoji_light := OmniLight3D.new()
	shoji_light.position     = Vector3(9.5, 1.5, 3.0)
	shoji_light.light_color  = Color(0.50, 0.55, 0.75)
	shoji_light.light_energy = 0.4
	shoji_light.omni_range   = 4.0
	add_child(shoji_light)
