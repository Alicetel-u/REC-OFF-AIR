class_name StageHelper

## ステージ構築ヘルパー（StageIriguchi / StageNaibu 共通）
## コリジョンあり/なしの BoxMesh 生成を統一

## コリジョンあり（壁・床・障害物）
static func box(parent: Node3D, pos: Vector3, size: Vector3, col: Color) -> void:
	var mi   := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh   = mesh
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mesh.material = mat
	parent.add_child(mi)

	var sb    := StaticBody3D.new()
	sb.position = pos
	var cs    := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape   = shape
	sb.add_child(cs)
	parent.add_child(sb)


## コリジョンなし（装飾専用）
static func deco(parent: Node3D, pos: Vector3, size: Vector3, col: Color) -> void:
	var mi   := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh   = mesh
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mesh.material = mat
	parent.add_child(mi)
