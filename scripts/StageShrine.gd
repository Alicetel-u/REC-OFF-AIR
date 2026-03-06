@tool
extends Node3D

## 桐原神社ステージ（廃神社・ホラー）
## コンセプト: 参道から一本道 → 本殿内部探索
## 構成: 参道(南Z=30) → 大鳥居(Z=25) → 狛犬(Z=15) → 石段(Z=5→-5) → 本殿(Z=-10→-25) → 出口(Z=-35)
## プレイヤースポーン: Vector3(0, 1.0, 30) / 出口: Vector3(0, 1.0, -35)
##
## Y座標ルール（Z-fighting防止）:
##   地面:   -0.15 (top = 0.0)
##   石畳:    0.02 (top = 0.06)  ← 地面と重ならない
##   床:      0.10 (top = 0.15)  ← 石畳より上
##   小物:    0.16+ (床から離す)

# ════════════════════════════════════════════════════════════════
# テクスチャ
# ════════════════════════════════════════════════════════════════

const TEX_WOOD     := preload("res://assets/models/Industrial_exterior_v2_Box_wood.png")
const TEX_CONCRETE := preload("res://assets/models/Industrial_exterior_v2_Concrete.png")
const TEX_WALL_TEX := preload("res://assets/models/Industrial_exterior_v2_Wall.png")
const TEX_BARREL   := preload("res://assets/models/Industrial_exterior_v2_Barrel_1.png")

# ════════════════════════════════════════════════════════════════
# 色パレット
# ════════════════════════════════════════════════════════════════

const COL_TORII_RED    := Color(0.65, 0.08, 0.05)
const COL_STONE        := Color(0.42, 0.40, 0.36)
const COL_STONE_DARK   := Color(0.28, 0.26, 0.24)
const COL_MOSS         := Color(0.10, 0.18, 0.06)
const COL_GRAVEL       := Color(0.46, 0.42, 0.36)
const COL_SHIMENAWA    := Color(0.72, 0.68, 0.55)
const COL_BARK         := Color(0.15, 0.10, 0.06)
const COL_LEAF_DARK    := Color(0.06, 0.12, 0.04)
const COL_LANTERN_GLOW := Color(1.0, 0.85, 0.50, 0.5)
const COL_BLOOD_STAIN  := Color(0.18, 0.03, 0.02)
const COL_COBWEB       := Color(0.60, 0.58, 0.55, 0.25)
const COL_RUST         := Color(0.30, 0.18, 0.10)

# 定数
const CEIL_H := 3.6
const WALL_THICK := 0.22
const PILLAR_SIZE := 0.18

# ════════════════════════════════════════════════════════════════
# マテリアル
# ════════════════════════════════════════════════════════════════

var _mat_stone  : StandardMaterial3D
var _mat_wood   : StandardMaterial3D
var _mat_torii  : StandardMaterial3D
var _mat_roof   : StandardMaterial3D
var _mat_floor  : StandardMaterial3D
var _mat_shoji  : StandardMaterial3D


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
	_mat_stone = _make_mat(TEX_CONCRETE, COL_STONE,              0.96, Vector3(4, 4, 4))
	_mat_wood  = _make_mat(TEX_WOOD,     Color(0.18, 0.12, 0.06), 0.92, Vector3(3, 6, 3))
	_mat_torii = _make_mat(TEX_BARREL,   COL_TORII_RED,           0.85, Vector3(2, 4, 2), 0.1)
	_mat_roof  = _make_mat(TEX_CONCRETE, Color(0.10, 0.09, 0.08), 0.98, Vector3(6, 6, 6))
	_mat_floor = _make_mat(TEX_WOOD,     Color(0.20, 0.14, 0.08), 0.90, Vector3(6, 1, 6))
	_mat_shoji = _make_mat(null,         Color(0.55, 0.52, 0.45, 0.30), 0.90, Vector3(1, 1, 1))


# ════════════════════════════════════════════════════════════════
# _ready
# ════════════════════════════════════════════════════════════════

func _ready() -> void:
	for c in get_children():
		c.queue_free()
	_create_materials()
	_build_foundation()
	_build_sando()
	_build_torii()
	_build_komainu()
	_build_stone_steps()
	_build_honden()
	_build_sub_shrine()
	_build_stone_fence()
	_build_trees()
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
	_tbox(pos + Vector3(0, CEIL_H * 0.5, 0), Vector3(PILLAR_SIZE, CEIL_H, PILLAR_SIZE), _mat_wood)


# ════════════════════════════════════════════════════════════════
# 1. 基礎（地面）80x100
# ════════════════════════════════════════════════════════════════

func _build_foundation() -> void:
	# 暗い土と苔の地面
	_tbox(Vector3(0, -0.15, -2.5), Vector3(80, 0.3, 100), _mat_stone)
	# 苔パッチを散らす
	_deco(Vector3(-8, 0.01, 10), Vector3(6, 0.01, 4), COL_MOSS)
	_deco(Vector3(12, 0.01, -8), Vector3(5, 0.01, 5), COL_MOSS)
	_deco(Vector3(-15, 0.01, -20), Vector3(7, 0.01, 3), COL_MOSS)
	_deco(Vector3(6, 0.01, 22), Vector3(4, 0.01, 6), COL_MOSS)


# ════════════════════════════════════════════════════════════════
# 2. 参道（Z=30→0, 砂利道 + 石灯篭）
# ════════════════════════════════════════════════════════════════

func _build_sando() -> void:
	# 砂利道（中央）
	_box(Vector3(0, 0.02, 15), Vector3(3.5, 0.04, 30), COL_GRAVEL)
	# 石畳の縁石（両側）
	_box(Vector3(-1.9, 0.04, 15), Vector3(0.3, 0.08, 30), COL_STONE_DARK)
	_box(Vector3( 1.9, 0.04, 15), Vector3(0.3, 0.08, 30), COL_STONE_DARK)

	# 石灯篭（参道の両脇、4対）
	for z_pos in [28.0, 20.0, 12.0, 4.0]:
		_build_stone_lantern(Vector3(-3.5, 0, z_pos))
		_build_stone_lantern(Vector3( 3.5, 0, z_pos))


func _build_stone_lantern(pos: Vector3) -> void:
	# 台座
	_tbox(pos + Vector3(0, 0.15, 0), Vector3(0.5, 0.3, 0.5), _mat_stone)
	# 柱
	_tbox(pos + Vector3(0, 0.65, 0), Vector3(0.2, 0.7, 0.2), _mat_stone)
	# 火袋（灯る部分）
	_tbox(pos + Vector3(0, 1.15, 0), Vector3(0.45, 0.35, 0.45), _mat_stone)
	# 笠（屋根）
	_tbox(pos + Vector3(0, 1.45, 0), Vector3(0.6, 0.15, 0.6), _mat_stone)
	# 宝珠
	_deco(pos + Vector3(0, 1.58, 0), Vector3(0.12, 0.12, 0.12), COL_STONE_DARK)
	# 灯り（薄いオレンジ）
	_deco(pos + Vector3(0, 1.15, 0), Vector3(0.2, 0.15, 0.2), COL_LANTERN_GLOW)
	# ひび割れ表現（片側にずれた石片）
	_deco(pos + Vector3(0.22, 0.8, 0.1), Vector3(0.08, 0.12, 0.06), COL_STONE_DARK)
	# 苔
	_deco(pos + Vector3(-0.15, 0.30, 0.2), Vector3(0.2, 0.06, 0.15), COL_MOSS)


# ════════════════════════════════════════════════════════════════
# 3. 大鳥居（Z=25）
# ════════════════════════════════════════════════════════════════

func _build_torii() -> void:
	var z : float = 25.0
	var pillar_spacing : float = 3.0

	# 主柱（左右）
	_tbox(Vector3(-pillar_spacing, 3.0, z), Vector3(0.35, 6.0, 0.35), _mat_torii)
	_tbox(Vector3( pillar_spacing, 3.0, z), Vector3(0.35, 6.0, 0.35), _mat_torii)

	# 笠木（上の横梁、柱より外に張り出す）
	_tbox(Vector3(0, 6.2, z), Vector3(8.0, 0.4, 0.4), _mat_torii)

	# 島木（笠木の下）
	_tbox(Vector3(0, 5.85, z), Vector3(7.6, 0.2, 0.35), _mat_torii)

	# 貫（下の横梁）
	_tbox(Vector3(0, 4.5, z), Vector3(7.0, 0.25, 0.3), _mat_torii)

	# 額束（貫と笠木の間の板）
	_tbox(Vector3(0, 5.2, z), Vector3(1.2, 0.8, 0.15), _mat_torii)

	# 鳥居額（桐原神社の文字がある板）
	_deco(Vector3(0, 5.2, z - 0.09), Vector3(1.0, 0.6, 0.02), Color(0.90, 0.85, 0.70))

	# 根巻き（柱の根元を石で固定）
	_tbox(Vector3(-pillar_spacing, 0.2, z), Vector3(0.55, 0.4, 0.55), _mat_stone)
	_tbox(Vector3( pillar_spacing, 0.2, z), Vector3(0.55, 0.4, 0.55), _mat_stone)

	# 苔（根元に）
	_deco(Vector3(-pillar_spacing + 0.1, 0.42, z + 0.2), Vector3(0.3, 0.04, 0.2), COL_MOSS)
	_deco(Vector3( pillar_spacing - 0.2, 0.42, z - 0.1), Vector3(0.25, 0.04, 0.25), COL_MOSS)


# ════════════════════════════════════════════════════════════════
# 4. 狛犬（Z=15, 参道の両脇）
# ════════════════════════════════════════════════════════════════

func _build_komainu() -> void:
	_build_komainu_single(Vector3(-4.0, 0, 15.0), false)  # 阿形（口を開けた方）
	_build_komainu_single(Vector3( 4.0, 0, 15.0), true)   # 吽形（口を閉じた方）


func _build_komainu_single(pos: Vector3, is_un: bool) -> void:
	# 台座
	_tbox(pos + Vector3(0, 0.15, 0), Vector3(1.4, 0.3, 1.7), _mat_stone)
	# 胴体
	_tbox(pos + Vector3(0, 0.65, 0), Vector3(1.2, 0.8, 1.5), _mat_stone)
	# 頭部
	var head_x : float = 0.0 if not is_un else 0.0
	_tbox(pos + Vector3(head_x, 1.30, -0.4), Vector3(0.6, 0.5, 0.6), _mat_stone)
	# 口（阿形は開口、吽形は閉口）
	if not is_un:
		_deco(pos + Vector3(0, 1.15, -0.72), Vector3(0.3, 0.12, 0.1), COL_STONE_DARK)
	# 前足
	_tbox(pos + Vector3(-0.35, 0.35, -0.5), Vector3(0.25, 0.4, 0.4), _mat_stone)
	_tbox(pos + Vector3( 0.35, 0.35, -0.5), Vector3(0.25, 0.4, 0.4), _mat_stone)
	# 尻尾（背中に渦巻き状の突起）
	_deco(pos + Vector3(0, 1.15, 0.6), Vector3(0.3, 0.35, 0.25), COL_STONE_DARK)
	# 苔（年月を感じさせる）
	_deco(pos + Vector3(0.3, 0.70, 0.5), Vector3(0.35, 0.08, 0.3), COL_MOSS)
	_deco(pos + Vector3(-0.4, 0.32, -0.3), Vector3(0.2, 0.04, 0.2), COL_MOSS)


# ════════════════════════════════════════════════════════════════
# 5. 石段（Z=5→Z=-5, 3段の石層）
# ════════════════════════════════════════════════════════════════

func _build_stone_steps() -> void:
	# 3段の石段（南→北へ登っていく）
	# 段1: Z=5→Z=2, Y=0.0→0.3
	_tbox(Vector3(0, 0.15, 3.5), Vector3(5.0, 0.3, 3.0), _mat_stone)
	# 段2: Z=2→Z=-1, Y=0.3→0.6
	_tbox(Vector3(0, 0.45, 0.5), Vector3(5.0, 0.3, 3.0), _mat_stone)
	# 段3: Z=-1→Z=-4, Y=0.6→0.9
	_tbox(Vector3(0, 0.75, -2.5), Vector3(5.0, 0.3, 3.0), _mat_stone)

	# 段の蹴上げ面（影を強調）
	_deco(Vector3(0, 0.15, 2.0), Vector3(5.0, 0.3, 0.05), COL_STONE_DARK)
	_deco(Vector3(0, 0.45, -1.0), Vector3(5.0, 0.3, 0.05), COL_STONE_DARK)
	_deco(Vector3(0, 0.75, -4.0), Vector3(5.0, 0.3, 0.05), COL_STONE_DARK)

	# 石段の苔（古びた感じ）
	_deco(Vector3(-1.5, 0.32, 4.0), Vector3(1.2, 0.01, 0.8), COL_MOSS)
	_deco(Vector3(1.8, 0.62, 0.0), Vector3(0.8, 0.01, 0.6), COL_MOSS)
	_deco(Vector3(-0.5, 0.92, -3.0), Vector3(1.0, 0.01, 0.7), COL_MOSS)

	# 石段の両脇に低い石壁
	_tbox(Vector3(-3.0, 0.45, 0.5), Vector3(0.5, 0.9, 10.0), _mat_stone)
	_tbox(Vector3( 3.0, 0.45, 0.5), Vector3(0.5, 0.9, 10.0), _mat_stone)


# ════════════════════════════════════════════════════════════════
# 6. 本殿（Z=-10→-25, 木造建築）
# ════════════════════════════════════════════════════════════════

func _build_honden() -> void:
	var base_y : float = 0.9  # 石段の上

	# ── 床 ──
	_tbox(Vector3(0, base_y + 0.05, -17.5), Vector3(14, 0.1, 15), _mat_floor)

	# ── 壁 ──
	# 北壁（奥）
	_tbox(Vector3(0, base_y + CEIL_H * 0.5, -24.8), Vector3(14, CEIL_H, WALL_THICK), _mat_wood)
	# 東壁
	_tbox(Vector3(6.9, base_y + CEIL_H * 0.5, -17.5), Vector3(WALL_THICK, CEIL_H, 15), _mat_wood)
	# 西壁
	_tbox(Vector3(-6.9, base_y + CEIL_H * 0.5, -17.5), Vector3(WALL_THICK, CEIL_H, 15), _mat_wood)
	# 南壁（入口開口あり）
	_tbox(Vector3(-5.0, base_y + CEIL_H * 0.5, -10.1), Vector3(4.0, CEIL_H, WALL_THICK), _mat_wood)
	_tbox(Vector3( 5.0, base_y + CEIL_H * 0.5, -10.1), Vector3(4.0, CEIL_H, WALL_THICK), _mat_wood)
	# 入口上の鴨居
	_tbox(Vector3(0, base_y + CEIL_H * 0.85, -10.1), Vector3(6.0, 0.15, WALL_THICK + 0.05), _mat_wood)

	# ── 天井 ──
	_tdeco(Vector3(0, base_y + CEIL_H, -17.5), Vector3(14, 0.08, 15), _mat_wood)

	# ── 屋根（入母屋風、厚い暗い板） ──
	_tdeco(Vector3(0, base_y + CEIL_H + 0.6, -17.5), Vector3(16, 0.2, 17), _mat_roof)
	# 棟木
	_tdeco(Vector3(0, base_y + CEIL_H + 1.0, -17.5), Vector3(0.2, 0.2, 17), _mat_wood)
	# 千木（屋根の両端の交差した木）
	_tdeco(Vector3(-7.5, base_y + CEIL_H + 1.2, -17.5), Vector3(0.1, 0.8, 0.1), _mat_wood)
	_tdeco(Vector3( 7.5, base_y + CEIL_H + 1.2, -17.5), Vector3(0.1, 0.8, 0.1), _mat_wood)

	# ── 柱（本殿を支える） ──
	for x in [-6.5, -3.0, 0.0, 3.0, 6.5]:
		_tbox(Vector3(x, base_y + CEIL_H * 0.5, -10.1), Vector3(PILLAR_SIZE, CEIL_H, PILLAR_SIZE), _mat_wood)
	for x in [-6.5, 0.0, 6.5]:
		_tbox(Vector3(x, base_y + CEIL_H * 0.5, -24.8), Vector3(PILLAR_SIZE, CEIL_H, PILLAR_SIZE), _mat_wood)
	# 中間柱
	for x in [-6.5, 6.5]:
		_tbox(Vector3(x, base_y + CEIL_H * 0.5, -17.5), Vector3(PILLAR_SIZE, CEIL_H, PILLAR_SIZE), _mat_wood)

	# ── 鈴（入口に吊り下げた鈴、四角近似） ──
	_deco(Vector3(0, base_y + CEIL_H * 0.7, -10.3), Vector3(0.3, 0.3, 0.3), COL_RUST)
	# 鈴緒（太い縄）
	_deco(Vector3(0, base_y + CEIL_H * 0.4, -10.4), Vector3(0.08, CEIL_H * 0.5, 0.08), COL_SHIMENAWA)

	# ── しめ縄（入口上部） ──
	_deco(Vector3(0, base_y + CEIL_H * 0.8, -10.0), Vector3(5.0, 0.18, 0.18), COL_SHIMENAWA)
	# 紙垂（しで）
	for x_off in [-1.5, -0.5, 0.5, 1.5]:
		_deco(Vector3(x_off, base_y + CEIL_H * 0.65, -10.0), Vector3(0.12, 0.25, 0.02), Color(0.90, 0.88, 0.82))

	# ── 障子（内部仕切り） ──
	_tdeco(Vector3(-4.0, base_y + CEIL_H * 0.44, -18.0), Vector3(0.05, CEIL_H * 0.88, 3.0), _mat_shoji)
	_tdeco(Vector3( 4.0, base_y + CEIL_H * 0.44, -18.0), Vector3(0.05, CEIL_H * 0.88, 3.0), _mat_shoji)

	# ── 賽銭箱（入口前、倒れている） ──
	_tbox(Vector3(1.5, base_y + 0.2, -9.0), Vector3(1.0, 0.4, 0.6), _mat_wood)
	# 倒れた賽銭箱
	_tbox(Vector3(-2.0, base_y + 0.15, -8.5), Vector3(0.6, 0.3, 1.0), _mat_wood)
	# 散らばった賽銭（小さい金属片）
	_deco(Vector3(-1.5, base_y + 0.02, -8.0), Vector3(0.04, 0.01, 0.04), COL_RUST)
	_deco(Vector3(-2.3, base_y + 0.02, -8.8), Vector3(0.04, 0.01, 0.04), COL_RUST)
	_deco(Vector3(-1.8, base_y + 0.02, -9.2), Vector3(0.04, 0.01, 0.04), COL_RUST)

	# ── 内部：祭壇 ──
	# 祭壇台
	_tbox(Vector3(0, base_y + 0.45, -23.5), Vector3(4.0, 0.8, 2.0), _mat_wood)
	# 白木の箱（みゆきの頭がある）
	_tbox(Vector3(0, base_y + 1.0, -23.5), Vector3(0.6, 0.4, 0.5), _mat_floor)
	_deco(Vector3(0, base_y + 1.22, -23.5), Vector3(0.55, 0.02, 0.45), Color(0.85, 0.82, 0.75))
	# 祭壇の上の燭台
	_deco(Vector3(-1.2, base_y + 0.95, -23.5), Vector3(0.06, 0.14, 0.06), Color(0.65, 0.55, 0.25))
	_deco(Vector3( 1.2, base_y + 0.95, -23.5), Vector3(0.06, 0.14, 0.06), Color(0.65, 0.55, 0.25))
	# 蝋燭の炎
	_deco(Vector3(-1.2, base_y + 1.04, -23.5), Vector3(0.02, 0.04, 0.02), Color(1.0, 0.8, 0.3))
	_deco(Vector3( 1.2, base_y + 1.04, -23.5), Vector3(0.02, 0.04, 0.02), Color(1.0, 0.8, 0.3))
	# 榊（供え物の枯れた枝）
	_deco(Vector3(-1.6, base_y + 0.92, -23.3), Vector3(0.1, 0.2, 0.08), Color(0.20, 0.15, 0.08))
	_deco(Vector3( 1.6, base_y + 0.92, -23.3), Vector3(0.1, 0.2, 0.08), Color(0.20, 0.15, 0.08))

	# ── 血痕（本殿内床） ──
	_deco(Vector3(-1.0, base_y + 0.12, -20.0), Vector3(0.8, 0.005, 1.2), COL_BLOOD_STAIN)
	_deco(Vector3(2.0, base_y + 0.12, -22.0), Vector3(0.5, 0.005, 0.6), COL_BLOOD_STAIN)
	_deco(Vector3(0.3, base_y + 0.12, -23.0), Vector3(1.5, 0.005, 0.4), COL_BLOOD_STAIN)
	# 祭壇から滴った血痕
	_deco(Vector3(0.2, base_y + 0.12, -22.5), Vector3(0.15, 0.005, 2.0), COL_BLOOD_STAIN)

	# ── 蜘蛛の巣（天井隅） ──
	_deco(Vector3(-6.7, base_y + CEIL_H - 0.1, -24.5), Vector3(0.8, 0.6, 0.02), COL_COBWEB)
	_deco(Vector3( 6.7, base_y + CEIL_H - 0.1, -24.5), Vector3(0.7, 0.5, 0.02), COL_COBWEB)
	_deco(Vector3(-6.7, base_y + CEIL_H - 0.1, -10.5), Vector3(0.6, 0.5, 0.02), COL_COBWEB)
	_deco(Vector3( 6.7, base_y + CEIL_H - 0.1, -10.5), Vector3(0.5, 0.6, 0.02), COL_COBWEB)
	# 天井中央にも大きな蜘蛛の巣
	_deco(Vector3(0, base_y + CEIL_H - 0.05, -15.0), Vector3(1.5, 0.8, 0.02), COL_COBWEB)

	# ── 出口通路（北へ） ──
	_tbox(Vector3(0, base_y + 0.05, -30.0), Vector3(3.0, 0.1, 10), _mat_floor)
	_tbox(Vector3(-1.4, base_y + CEIL_H * 0.5, -30.0), Vector3(WALL_THICK, CEIL_H, 10), _mat_wood)
	_tbox(Vector3( 1.4, base_y + CEIL_H * 0.5, -30.0), Vector3(WALL_THICK, CEIL_H, 10), _mat_wood)


# ════════════════════════════════════════════════════════════════
# 7. 小さな祠（X=-12, 脇に佇む）
# ════════════════════════════════════════════════════════════════

func _build_sub_shrine() -> void:
	var pos := Vector3(-12, 0, -5)

	# 台座（石積み）
	_tbox(pos + Vector3(0, 0.25, 0), Vector3(2.0, 0.5, 1.8), _mat_stone)
	# 祠本体（小さな木造）
	_tbox(pos + Vector3(0, 0.8, 0), Vector3(1.2, 0.8, 1.0), _mat_wood)
	# 屋根
	_tdeco(pos + Vector3(0, 1.35, 0), Vector3(1.6, 0.12, 1.4), _mat_roof)
	_tdeco(pos + Vector3(0, 1.50, 0), Vector3(0.08, 0.08, 1.4), _mat_wood)
	# 入口（開口を暗く表現）
	_deco(pos + Vector3(0, 0.70, -0.5), Vector3(0.4, 0.5, 0.02), Color(0.02, 0.02, 0.02))
	# お供え物（崩れた）
	_deco(pos + Vector3(-0.3, 0.55, -0.7), Vector3(0.12, 0.08, 0.12), COL_STONE)
	_deco(pos + Vector3(0.2, 0.52, -0.8), Vector3(0.08, 0.05, 0.1), COL_STONE_DARK)
	# 苔が侵食
	_deco(pos + Vector3(0.5, 0.52, 0.4), Vector3(0.6, 0.04, 0.5), COL_MOSS)
	_deco(pos + Vector3(-0.7, 0.28, -0.6), Vector3(0.4, 0.03, 0.3), COL_MOSS)
	# しめ縄（小さい、朽ちかけ）
	_deco(pos + Vector3(0, 1.22, -0.5), Vector3(1.0, 0.08, 0.08), COL_SHIMENAWA)


# ════════════════════════════════════════════════════════════════
# 8. 石垣（外周の石壁）
# ════════════════════════════════════════════════════════════════

func _build_stone_fence() -> void:
	var h : float = 1.2
	var th : float = 0.4
	# 東壁
	_tbox(Vector3(18, h * 0.5, -2.5), Vector3(th, h, 70), _mat_stone)
	# 西壁
	_tbox(Vector3(-18, h * 0.5, -2.5), Vector3(th, h, 70), _mat_stone)
	# 北壁
	_tbox(Vector3(0, h * 0.5, -37), Vector3(36.4, h, th), _mat_stone)
	# 南壁（入口開口あり）
	_tbox(Vector3(-11, h * 0.5, 32), Vector3(14, h, th), _mat_stone)
	_tbox(Vector3( 11, h * 0.5, 32), Vector3(14, h, th), _mat_stone)

	# 石壁の上の苔
	_deco(Vector3(18, h + 0.02, 5), Vector3(0.4, 0.03, 8), COL_MOSS)
	_deco(Vector3(-18, h + 0.02, -10), Vector3(0.4, 0.03, 6), COL_MOSS)
	_deco(Vector3(5, h + 0.02, -37), Vector3(10, 0.03, 0.4), COL_MOSS)


# ════════════════════════════════════════════════════════════════
# 9. 杉の木（外周に高い木のシルエット）
# ════════════════════════════════════════════════════════════════

func _build_trees() -> void:
	# 細長いboxで杉の幹を表現（円柱の代わり）
	var tree_positions : Array = [
		# 東側
		Vector3(15, 0, 25), Vector3(16, 0, 18), Vector3(14, 0, 10),
		Vector3(15, 0, 2), Vector3(16, 0, -8), Vector3(14, 0, -18),
		Vector3(15, 0, -28),
		# 西側
		Vector3(-15, 0, 28), Vector3(-16, 0, 20), Vector3(-14, 0, 12),
		Vector3(-15, 0, 5), Vector3(-16, 0, -5), Vector3(-14, 0, -15),
		Vector3(-15, 0, -25), Vector3(-16, 0, -32),
		# 北側
		Vector3(-8, 0, -34), Vector3(8, 0, -33), Vector3(-3, 0, -35),
		Vector3(5, 0, -36),
	]

	for pos in tree_positions:
		var trunk_h : float = 12.0 + randf_range(-2.0, 3.0)
		# 幹（暗い樹皮色）
		_box(pos + Vector3(0, trunk_h * 0.5, 0), Vector3(0.4, trunk_h, 0.4), COL_BARK)
		# 枝葉（上部に暗い塊）
		var canopy_y : float = trunk_h * 0.65
		_deco(pos + Vector3(0, canopy_y, 0), Vector3(2.5, trunk_h * 0.5, 2.5), COL_LEAF_DARK)
		_deco(pos + Vector3(0.5, canopy_y + 1.0, 0.3), Vector3(1.8, trunk_h * 0.3, 1.8), COL_LEAF_DARK)
		# 根元の苔
		_deco(pos + Vector3(0, 0.05, 0), Vector3(0.8, 0.05, 0.8), COL_MOSS)


# ════════════════════════════════════════════════════════════════
# 10. ライティング（不気味な雰囲気）
# ════════════════════════════════════════════════════════════════

func _build_lighting() -> void:
	# 月明かり（薄青、斜め上から）
	var moon := DirectionalLight3D.new()
	moon.light_color   = Color(0.35, 0.40, 0.55)
	moon.light_energy  = 0.3
	moon.rotation_degrees = Vector3(-45, 30, 0)
	add_child(moon)

	# 参道の環境光（微かな月光）
	var ambient := OmniLight3D.new()
	ambient.position     = Vector3(0, 6.0, 15.0)
	ambient.light_color  = Color(0.30, 0.35, 0.50)
	ambient.light_energy = 0.4
	ambient.omni_range   = 25.0
	add_child(ambient)

	# 石灯篭の灯り（赤みを帯びた薄い光）
	for z_pos in [28.0, 20.0, 12.0, 4.0]:
		for x_pos in [-3.5, 3.5]:
			var lantern := OmniLight3D.new()
			lantern.position     = Vector3(x_pos, 1.2, z_pos)
			lantern.light_color  = Color(1.0, 0.75, 0.40)
			lantern.light_energy = 0.25
			lantern.omni_range   = 4.0
			add_child(lantern)

	# 鳥居の不気味な赤い照り返し
	var torii_glow := OmniLight3D.new()
	torii_glow.position     = Vector3(0, 3.0, 25.0)
	torii_glow.light_color  = Color(0.8, 0.15, 0.10)
	torii_glow.light_energy = 0.3
	torii_glow.omni_range   = 6.0
	add_child(torii_glow)

	# 本殿内部（不気味な薄暗い光）
	var honden_interior := OmniLight3D.new()
	honden_interior.position     = Vector3(0, 3.0, -17.5)
	honden_interior.light_color  = Color(0.25, 0.30, 0.45)
	honden_interior.light_energy = 0.4
	honden_interior.omni_range   = 12.0
	add_child(honden_interior)

	# 祭壇の蝋燭光（暖色、不安を煽る揺らぎ感）
	var altar_candle := OmniLight3D.new()
	altar_candle.position     = Vector3(0, 2.0, -23.5)
	altar_candle.light_color  = Color(1.0, 0.70, 0.30)
	altar_candle.light_energy = 0.6
	altar_candle.omni_range   = 5.0
	add_child(altar_candle)

	# 白木の箱に当たる不気味な光
	var hakobako := SpotLight3D.new()
	hakobako.position     = Vector3(0, 3.5, -22.0)
	hakobako.light_color  = Color(0.50, 0.55, 0.75)
	hakobako.light_energy = 0.5
	hakobako.spot_range   = 4.0
	hakobako.spot_angle   = 25.0
	add_child(hakobako)
	hakobako.look_at(Vector3(0, 1.0, -23.5))

	# 小祠の微かな光
	var sub_shrine_light := OmniLight3D.new()
	sub_shrine_light.position     = Vector3(-12, 1.5, -5)
	sub_shrine_light.light_color  = Color(0.60, 0.80, 0.50)
	sub_shrine_light.light_energy = 0.2
	sub_shrine_light.omni_range   = 4.0
	add_child(sub_shrine_light)

	# 出口方向の誘導光（非常に暗い）
	var exit_hint := OmniLight3D.new()
	exit_hint.position     = Vector3(0, 1.5, -35.0)
	exit_hint.light_color  = Color(0.40, 0.45, 0.60)
	exit_hint.light_energy = 0.3
	exit_hint.omni_range   = 5.0
	add_child(exit_hint)
