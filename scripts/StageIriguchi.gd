extends Node3D

## 廃村入口マップ（仮実装）
## 構成: バス停 → 砂利道 → 畑 → 村の門（看板付き）
## CSGBox3D のマテリアル問題を回避するため MeshInstance3D + StaticBody3D で実装

func _ready() -> void:
	_build_ground()
	_build_road()
	_build_fields()
	_build_bus_stop()
	_build_gate()


# ── ヘルパー: MeshInstance3D + StaticBody3D を生成 ───────────────
func _box(pos: Vector3, size: Vector3, col: Color) -> void:
	# 表示メッシュ
	var mi   := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh   = mesh
	mi.position = pos

	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mesh.material = mat
	add_child(mi)

	# コリジョン（StaticBody3D）
	var sb    := StaticBody3D.new()
	sb.position = pos
	var cs    := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape   = shape
	sb.add_child(cs)
	add_child(sb)


# ── 地面 ─────────────────────────────────────────────────────────
func _build_ground() -> void:
	_box(Vector3(0, -0.1, 0), Vector3(100, 0.2, 100), Color(0.18, 0.38, 0.12))


# ── 砂利道 ───────────────────────────────────────────────────────
func _build_road() -> void:
	_box(Vector3(0, 0.01, -2), Vector3(4.5, 0.05, 42), Color(0.55, 0.52, 0.46))
	_box(Vector3(-2.6, 0.03, -2), Vector3(0.3, 0.04, 42), Color(0.40, 0.38, 0.34))
	_box(Vector3( 2.6, 0.03, -2), Vector3(0.3, 0.04, 42), Color(0.40, 0.38, 0.34))


# ── 畑 ───────────────────────────────────────────────────────────
func _build_fields() -> void:
	_box(Vector3(-12, 0.05, -1), Vector3(16, 0.10, 24), Color(0.22, 0.48, 0.14))
	_box(Vector3( 12, 0.05, -1), Vector3(16, 0.10, 24), Color(0.22, 0.48, 0.14))

	for i in range(6):
		_box(Vector3(-12, 0.16, 10.0 - i * 4.0), Vector3(14.0, 0.10, 0.45), Color(0.28, 0.58, 0.18))
	for i in range(6):
		_box(Vector3( 12, 0.16, 10.0 - i * 4.0), Vector3(14.0, 0.10, 0.45), Color(0.28, 0.58, 0.18))


# ── バス停 ───────────────────────────────────────────────────────
func _build_bus_stop() -> void:
	_box(Vector3(8.0, 0.08, 13.0), Vector3(5.0, 0.16, 3.2),  Color(0.50, 0.45, 0.38))  # ベース
	_box(Vector3(8.0, 1.4,  11.7), Vector3(5.0, 2.8,  0.15), Color(0.72, 0.65, 0.55))  # 後壁
	_box(Vector3(8.0, 2.85, 12.8), Vector3(5.2, 0.18, 3.2),  Color(0.78, 0.70, 0.60))  # 屋根
	_box(Vector3(5.6, 1.4,  13.1), Vector3(0.18, 2.8, 0.18), Color(0.60, 0.55, 0.48))  # 左支柱
	_box(Vector3(10.4, 1.4, 13.1), Vector3(0.18, 2.8, 0.18), Color(0.60, 0.55, 0.48))  # 右支柱
	_box(Vector3(8.0, 0.48, 12.0), Vector3(3.8, 0.14, 0.65), Color(0.48, 0.38, 0.28))  # ベンチ座面
	_box(Vector3(6.3, 0.30, 12.0), Vector3(0.14, 0.28, 0.60), Color(0.42, 0.33, 0.24)) # ベンチ脚L
	_box(Vector3(9.7, 0.30, 12.0), Vector3(0.14, 0.28, 0.60), Color(0.42, 0.33, 0.24)) # ベンチ脚R

	# 街灯柱: バス停手前・道路際（プレイヤー初期視線上に配置）
	# プレイヤーが (0,1,15) で右向き(+X方向)を向いたとき正面に見える位置
	_box(Vector3(5.2, 2.2, 14.8), Vector3(0.14, 4.4, 0.14), Color(0.35, 0.35, 0.38))  # 柱
	_box(Vector3(5.2, 4.55, 14.8), Vector3(0.5, 0.18, 0.5),  Color(0.30, 0.30, 0.32)) # 灯具ハウジング

	var street_lamp := SpotLight3D.new()
	street_lamp.position     = Vector3(5.2, 4.4, 14.8)
	street_lamp.light_color  = Color(1.0, 0.92, 0.72)   # 電球色（暖色）
	street_lamp.light_energy = 6.0
	street_lamp.spot_range   = 14.0
	street_lamp.spot_angle   = 60.0
	add_child(street_lamp)
	street_lamp.look_at(Vector3(8.0, 5.0, 12.0))  # バス停後壁の上部に向ける（地面に当てない）


# ── 村の門 ───────────────────────────────────────────────────────
func _build_gate() -> void:
	_box(Vector3(-3.5, 2.2, -14.0), Vector3(1.0, 4.4, 1.0), Color(0.58, 0.55, 0.50))  # 左柱
	_box(Vector3( 3.5, 2.2, -14.0), Vector3(1.0, 4.4, 1.0), Color(0.58, 0.55, 0.50))  # 右柱
	_box(Vector3(0, 4.7, -14.0),    Vector3(9.0, 0.8, 0.9), Color(0.52, 0.49, 0.44))  # 上梁
	_box(Vector3(0, 5.65, -14.0),   Vector3(6.5, 1.0, 0.20), Color(0.35, 0.26, 0.16)) # 看板
	_box(Vector3(-2.8, 5.65, -13.92), Vector3(0.12, 0.75, 0.08), Color(0.65, 0.55, 0.40)) # 金具L
	_box(Vector3( 2.8, 5.65, -13.92), Vector3(0.12, 0.75, 0.08), Color(0.65, 0.55, 0.40)) # 金具R
	_box(Vector3(-8.0, 0.5, -14.0), Vector3(8.0, 1.0, 0.8), Color(0.55, 0.52, 0.48))  # 左石垣
	_box(Vector3( 8.0, 0.5, -14.0), Vector3(8.0, 1.0, 0.8), Color(0.55, 0.52, 0.48))  # 右石垣
