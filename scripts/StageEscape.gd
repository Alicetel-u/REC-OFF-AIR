extends Node3D

## CP5 脱出路 — 霧に閉ざされた林道
## 構成: 南端スポーン(Z=65) → 林道(霧) → バス停(Z=-58) → バス(Z=-75)
## プレイヤーは JSON 自動走行で北上してバスに到達

func _ready() -> void:
	_build_ground()
	_build_road()
	_build_forest()
	_build_roadside_stones()
	_build_lights()
	_build_bus_stop()
	_build_bus()


# ════════════════════════════════════════════════════════════════
# ヘルパー
# ════════════════════════════════════════════════════════════════

func _box(pos: Vector3, size: Vector3, col: Color) -> void:
	var mi   := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh   = mesh
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mesh.material = mat
	add_child(mi)

	var sb    := StaticBody3D.new()
	sb.position = pos
	var cs    := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape   = shape
	sb.add_child(cs)
	add_child(sb)


func _deco(pos: Vector3, size: Vector3, col: Color) -> void:
	var mi   := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh   = mesh
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mesh.material = mat
	add_child(mi)


# ════════════════════════════════════════════════════════════════
# 地面
# ════════════════════════════════════════════════════════════════

func _build_ground() -> void:
	# 泥道（全体）
	_box(Vector3(0, -0.1, 0), Vector3(80, 0.2, 160), Color(0.10, 0.08, 0.06))


# ════════════════════════════════════════════════════════════════
# 砂利道（幅 4m・中央）
# ════════════════════════════════════════════════════════════════

func _build_road() -> void:
	_box(Vector3(0, 0.02, 0), Vector3(4.2, 0.05, 155), Color(0.32, 0.29, 0.24))
	# 轍
	_deco(Vector3(-1.3, 0.05, 0), Vector3(0.18, 0.03, 155), Color(0.22, 0.19, 0.15))
	_deco(Vector3( 1.3, 0.05, 0), Vector3(0.18, 0.03, 155), Color(0.22, 0.19, 0.15))


# ════════════════════════════════════════════════════════════════
# 道端の石（歩道目安）
# ════════════════════════════════════════════════════════════════

func _build_roadside_stones() -> void:
	var z := -72.0
	while z <= 68.0:
		if z > -68.0 and z < -48.0:
			z += 4.0
			continue  # バス停前後はクリア
		_deco(Vector3(-2.4, 0.06, z), Vector3(0.28, 0.12, 0.28), Color(0.40, 0.37, 0.33))
		_deco(Vector3( 2.4, 0.06, z), Vector3(0.28, 0.12, 0.28), Color(0.40, 0.37, 0.33))
		z += 4.0


# ════════════════════════════════════════════════════════════════
# 密生した森（道の両側）
# ════════════════════════════════════════════════════════════════

func _build_forest() -> void:
	# 西側（X負・第1列 X≈-6〜-10）
	var west1 := [-70.0, -62.0, -52.0, -44.0, -34.0, -25.0, -15.0, -5.0, 5.0,
				   15.0,  25.0,  35.0,  44.0,  54.0,  62.0]
	for z in west1:
		_build_tree(Vector3(randf_range(-7.0, -9.0), 0, z))
	# 西側 第2列
	var west2 := [-68.0, -55.0, -42.0, -28.0, -15.0, 0.0, 15.0, 28.0, 42.0, 57.0]
	for z in west2:
		_build_tree(Vector3(randf_range(-12.0, -16.0), 0, z))
	# 西側 第3列（奥まった密林）
	var west3 := [-65.0, -48.0, -32.0, -18.0, 0.0, 18.0, 32.0, 48.0, 62.0]
	for z in west3:
		_build_tree(Vector3(randf_range(-18.0, -24.0), 0, z))

	# 東側（X正・第1列 X≈6〜10）
	var east1 := [-66.0, -57.0, -47.0, -38.0, -28.0, -18.0, -8.0, 2.0,
				   12.0,  22.0,  33.0,  43.0,  52.0,  61.0]
	for z in east1:
		_build_tree(Vector3(randf_range(7.0, 10.0), 0, z))
	# 東側 第2列
	var east2 := [-64.0, -50.0, -38.0, -22.0, -8.0, 8.0, 22.0, 38.0, 54.0]
	for z in east2:
		_build_tree(Vector3(randf_range(13.0, 17.0), 0, z))
	# 東側 第3列
	var east3 := [-60.0, -45.0, -28.0, -12.0, 5.0, 20.0, 36.0, 52.0]
	for z in east3:
		_build_tree(Vector3(randf_range(19.0, 25.0), 0, z))


func _build_tree(pos: Vector3) -> void:
	var trunk_h := randf_range(5.5, 9.0)
	var leaf_w  := randf_range(3.5, 5.5)
	# 幹（コリジョンあり）
	_box(pos + Vector3(0, trunk_h * 0.5, 0),
		 Vector3(0.40, trunk_h, 0.40), Color(0.18, 0.12, 0.08))
	# 葉（3段・コリジョンなし）
	_deco(pos + Vector3(0, trunk_h + 0.4, 0),
		  Vector3(leaf_w, 1.1, leaf_w), Color(0.04, 0.09, 0.03))
	_deco(pos + Vector3(0, trunk_h + 1.4, 0),
		  Vector3(leaf_w * 0.72, 0.85, leaf_w * 0.72), Color(0.03, 0.07, 0.03))
	_deco(pos + Vector3(0, trunk_h + 2.2, 0),
		  Vector3(leaf_w * 0.45, 0.65, leaf_w * 0.45), Color(0.02, 0.06, 0.02))


# ════════════════════════════════════════════════════════════════
# 街灯（間隔 20m）
# ════════════════════════════════════════════════════════════════

func _build_lights() -> void:
	var light_zs := [60.0, 40.0, 20.0, 0.0, -20.0, -40.0]
	for lz in light_zs:
		# ポール
		_box(Vector3(-3.0, 3.2, lz), Vector3(0.12, 6.4, 0.12), Color(0.32, 0.30, 0.28))
		var sl := SpotLight3D.new()
		sl.position      = Vector3(-3.0, 6.3, lz)
		sl.light_color   = Color(0.88, 0.82, 0.65)   # 電球色
		sl.light_energy  = 2.8
		sl.spot_range    = 14.0
		sl.spot_angle    = 55.0
		add_child(sl)
		sl.rotation_degrees.x = 90.0  # 下向き


# ════════════════════════════════════════════════════════════════
# バス停（Z=-55 付近・道路右側 X=3〜8）
# ════════════════════════════════════════════════════════════════

func _build_bus_stop() -> void:
	var z   := -55.0
	var col_c := Color(0.46, 0.44, 0.40)   # コンクリート
	var col_r := Color(0.50, 0.48, 0.44)   # 屋根

	# 基礎
	_box(Vector3(5.5, 0.08,  z),        Vector3(5.0, 0.16, 3.2), col_c)
	# 後壁
	_box(Vector3(5.5, 1.45,  z - 1.4),  Vector3(5.0, 2.9,  0.18), col_c)
	# 屋根
	_box(Vector3(5.5, 3.0,   z),        Vector3(5.2, 0.20, 3.4), col_r)
	# 左支柱
	_box(Vector3(3.2, 1.4,   z + 1.4),  Vector3(0.18, 2.8, 0.18), col_c.darkened(0.15))
	# 右支柱
	_box(Vector3(7.8, 1.4,   z + 1.4),  Vector3(0.18, 2.8, 0.18), col_c.darkened(0.15))
	# ベンチ
	_box(Vector3(5.5, 0.48,  z - 0.7),  Vector3(3.8, 0.14, 0.62), Color(0.38, 0.30, 0.20))
	_box(Vector3(3.8, 0.30,  z - 0.7),  Vector3(0.14, 0.28, 0.58), Color(0.30, 0.24, 0.16))
	_box(Vector3(7.2, 0.30,  z - 0.7),  Vector3(0.14, 0.28, 0.58), Color(0.30, 0.24, 0.16))

	# バス停標識ポール（道路際）
	_box(Vector3(2.8, 2.4,   z + 1.6),  Vector3(0.12, 4.8, 0.12), Color(0.35, 0.35, 0.42))
	_deco(Vector3(2.8, 5.1,  z + 1.6),  Vector3(0.72, 0.55, 0.10), Color(0.14, 0.24, 0.52))

	# バス停灯（温かい白）
	var stop_light := OmniLight3D.new()
	stop_light.position     = Vector3(5.5, 2.8, z)
	stop_light.light_color  = Color(1.0, 0.92, 0.75)
	stop_light.light_energy = 2.5
	stop_light.omni_range   = 9.0
	add_child(stop_light)


# ════════════════════════════════════════════════════════════════
# バス（Z=-73 付近・道路中央）
# ════════════════════════════════════════════════════════════════

func _build_bus() -> void:
	var z       := -73.0
	var col_bus := Color(0.22, 0.30, 0.48)   # 夜間バス（紺青）
	var col_win := Color(0.58, 0.68, 0.82)   # 窓ガラス（薄いグレー青）
	var col_tir := Color(0.14, 0.12, 0.10)   # タイヤ

	# 車体
	_box(Vector3(0, 1.60, z),           Vector3(2.7, 2.8, 8.5), col_bus)
	# 前面（南端）フロントガラス
	_deco(Vector3(0, 2.0,  z + 4.35),   Vector3(2.2, 1.6, 0.08), col_win.darkened(0.25))
	# 背面窓
	_deco(Vector3(0, 2.0,  z - 4.35),   Vector3(1.8, 1.2, 0.08), col_win.darkened(0.35))
	# 側面窓（西・乗降口側） 4枚
	for i in range(4):
		_deco(Vector3(-1.38, 2.0, z - 2.2 + i * 1.5),
			  Vector3(0.08, 1.0, 1.1), col_win.darkened(0.2))
	# 乗降ドア（前方 南側）
	_deco(Vector3(-1.40, 1.35, z + 3.0), Vector3(0.08, 1.8, 1.6), col_win.darkened(0.5))
	# タイヤ（4個）
	_box(Vector3(-1.45, 0.42, z + 2.6), Vector3(0.55, 0.85, 0.90), col_tir)
	_box(Vector3( 1.45, 0.42, z + 2.6), Vector3(0.55, 0.85, 0.90), col_tir)
	_box(Vector3(-1.45, 0.42, z - 2.6), Vector3(0.55, 0.85, 0.90), col_tir)
	_box(Vector3( 1.45, 0.42, z - 2.6), Vector3(0.55, 0.85, 0.90), col_tir)
	# ヘッドライト（南向き）
	_deco(Vector3(-0.8, 1.3,  z + 4.38), Vector3(0.5, 0.3, 0.06), Color(0.92, 0.90, 0.78))
	_deco(Vector3( 0.8, 1.3,  z + 4.38), Vector3(0.5, 0.3, 0.06), Color(0.92, 0.90, 0.78))

	# 車内灯（温かみのある光）
	var bus_light := OmniLight3D.new()
	bus_light.position     = Vector3(0, 2.2, z)
	bus_light.light_color  = Color(1.0, 0.90, 0.68)
	bus_light.light_energy = 4.0
	bus_light.omni_range   = 9.0
	add_child(bus_light)

	# ヘッドライト投光
	var head_light := SpotLight3D.new()
	head_light.position     = Vector3(0, 1.5, z + 4.4)
	head_light.light_color  = Color(0.92, 0.90, 0.85)
	head_light.light_energy = 6.0
	head_light.spot_range   = 25.0
	head_light.spot_angle   = 28.0
	add_child(head_light)
	head_light.rotation_degrees.x = -8.0  # わずかに地面を照らす
