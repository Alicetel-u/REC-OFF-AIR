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

	# ── TSCNモデルを配置 ──
	var packed := load("res://assets/models/public_toilet/PublicToilet.tscn") as PackedScene
	if packed:
		var toilet := packed.instantiate()
		toilet.position = Vector3(0, 0, 0)
		add_child(toilet)
	else:
		push_warning("PublicToilet.tscn が読み込めません")
