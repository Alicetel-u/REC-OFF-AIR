extends Node3D

## 仮実装: 公衆トイレ（廃村アーチ通過後の右側）
## BoxMesh + StaticBody3D でコリジョン付き建物を生成

func _ready() -> void:
	_build()


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


func _build() -> void:
	# ── 周囲の地面 ──
	_box(Vector3(0, -0.05, 0), Vector3(14.0, 0.1, 20.0), Color(0.24, 0.31, 0.17))

	# ── 脇道（道路から入口まで） ──
	_box(Vector3(0, 0.02, -7.5), Vector3(3.0, 0.05, 5.0), Color(0.46, 0.42, 0.38))
	_box(Vector3(0, 0.02, -3.5), Vector3(6.0, 0.04, 3.0), Color(0.46, 0.42, 0.38))

	# ── GLBモデルを配置 ──
	var packed := load("res://assets/models/environment/PublicToilet.glb") as PackedScene
	if packed:
		var toilet := packed.instantiate()
		toilet.position = Vector3(0, 3.0, 0)  # Y: モデルが埋まる場合は増やす
		toilet.rotation_degrees.y = 90.0  # 向きが違う場合は 90 / 180 / -90 に変更
		toilet.scale = Vector3(12, 12, 12)
		add_child(toilet)
	else:
		push_warning("PublicToilet.glb が読み込めません")

	# ── 建物コリジョン（GLBにコリジョンがない場合のフォールバック） ──
	var sb    := StaticBody3D.new()
	sb.position = Vector3(0, 1.6, 0)
	var cs    := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(7.0, 3.2, 10.0)
	cs.shape   = shape
	sb.add_child(cs)
	add_child(sb)

	# ── 廊下の蛍光灯 ──
	var lamp := OmniLight3D.new()
	lamp.position     = Vector3(-2.0, 2.8, 0)
	lamp.light_color  = Color(0.82, 0.90, 0.75)
	lamp.light_energy = 1.6
	lamp.omni_range   = 10.0
	add_child(lamp)
