@tool
extends Node3D

## 霧原村マップ — 手動配置ノードのコリジョン管理 + デバッグ可視化

# デバッグ: コリジョンを赤い半透明ボックスで可視化（F12キーで切り替え）
var _debug_show_collision := false

@export_group("Actions")
@export var edit_mode: bool = true : set = _on_edit_mode_changed


func _ready():
	if not Engine.is_editor_hint():
		_add_collisions_to_manual_nodes()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		_debug_show_collision = not _debug_show_collision
		for body in get_tree().get_nodes_in_group("debug_collision"):
			var has_mesh := false
			for child in body.get_children():
				if child is MeshInstance3D:
					child.visible = _debug_show_collision
					has_mesh = true
			# 初回ON時にメッシュを生成
			if _debug_show_collision and not has_mesh:
				for child in body.get_children():
					if child is CollisionShape3D and child.shape is BoxShape3D:
						_add_debug_mesh(body, child.shape.size, child.position, true)
		print("[MapGenerator] コリジョン可視化: ", "ON" if _debug_show_collision else "OFF")


func _on_edit_mode_changed(val):
	edit_mode = val
	var light = get_node_or_null("DirectionalLight3D")
	var env_node = get_node_or_null("WorldEnvironment")
	if light:
		light.light_energy = 4.0 if val else 0.1
	if env_node and env_node.environment:
		env_node.environment.fog_enabled = !val
		env_node.environment.background_mode = 1
		env_node.environment.background_color = Color(0.1, 0.1, 0.12) if !val else Color(0.8, 0.8, 0.9)
		env_node.environment.ambient_light_source = 2
		env_node.environment.ambient_light_color = Color(0.05, 0.05, 0.1) if !val else Color(0.7, 0.7, 0.8)
		env_node.environment.ambient_light_energy = 3.0 if val else 0.5


# ════════════════════════════════════════════════════════════════
# 当たり判定 — AABBベース自動サイジング
# ════════════════════════════════════════════════════════════════

## ノードのメッシュAABBからコリジョンを自動生成
func _add_collision_from_aabb(node: Node3D) -> void:
	var aabb := _get_world_aabb(node)
	if aabb.size.length() < 0.1:
		return
	var box_size : Vector3 = aabb.size
	box_size.x = maxf(box_size.x, 1.0)
	box_size.y = maxf(box_size.y, 2.0)
	box_size.z = maxf(box_size.z, 1.0)
	var offset : Vector3 = aabb.position + aabb.size * 0.5
	_add_collision_at(node.global_position, node.global_rotation, box_size, offset)


func _get_world_aabb(node: Node3D) -> AABB:
	var s : Vector3 = node.transform.basis.get_scale()
	return _find_mesh_aabb(node, s)


func _find_mesh_aabb(node: Node, parent_scale: Vector3) -> AABB:
	if node is MeshInstance3D:
		var local_aabb : AABB = node.get_aabb()
		return AABB(local_aabb.position * parent_scale, local_aabb.size * parent_scale)
	for child in node.get_children():
		var result : AABB = _find_mesh_aabb(child, parent_scale)
		if result.size.length() > 0.01:
			return result
	return AABB()


## グローバル座標でコリジョンを配置（親スケールの影響を完全に回避）
func _add_collision_at(global_pos: Vector3, euler_rot: Vector3,
		box_size: Vector3, offset: Vector3 = Vector3.ZERO) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	col.shape = shape
	col.position = offset
	body.add_child(col)
	add_child(body)
	body.global_position = global_pos
	body.rotation = euler_rot
	body.add_to_group("debug_collision")
	# デバッグメッシュはF12で初回ON時に生成（GPU メモリ節約）


## 手動配置された全ノードにAABBベースでコリジョンを自動追加
func _add_collisions_to_manual_nodes() -> void:
	var count : int = 0
	var _collision_log : Array = []
	for child in get_children():
		if not (child is Node3D):
			continue
		var n : String = child.name
		if n == "GroundStaticBody" or n == "MapContainer":
			continue
		if n.begins_with("Grass"):
			continue
		if n.begins_with("WorldEnvironment") or n.begins_with("DirectionalLight"):
			continue
		if child is StaticBody3D:
			continue
		var aabb := _get_world_aabb(child)
		if aabb.size.length() < 0.1:
			continue
		_add_collision_from_aabb(child)
		var gpos : Vector3 = child.global_position
		var box_sz : Vector3 = aabb.size
		box_sz.x = maxf(box_sz.x, 1.0)
		box_sz.y = maxf(box_sz.y, 2.0)
		box_sz.z = maxf(box_sz.z, 1.0)
		var rot_y : float = child.global_rotation.y
		_collision_log.append("COL|%s|%.2f|%.2f|%.2f|%.2f|%.2f" % [n, gpos.x, gpos.z, box_sz.x, box_sz.z, rot_y])
		count += 1
	# コリジョンの実際のワールド座標4隅を出力（マップエディター用）
	var f := FileAccess.open("res://collision_data.txt", FileAccess.WRITE)
	if f:
		for line in _collision_log:
			f.store_line(line)
		f.close()
	# 4隅データも出力
	var f2 := FileAccess.open("res://collision_corners.txt", FileAccess.WRITE)
	if f2:
		for body in get_tree().get_nodes_in_group("debug_collision"):
			var col_shape : CollisionShape3D = null
			for child in body.get_children():
				if child is CollisionShape3D:
					col_shape = child
					break
			if col_shape == null:
				continue
			var shape = col_shape.shape
			if not (shape is BoxShape3D):
				continue
			var half : Vector3 = shape.size * 0.5
			var t : Transform3D = body.global_transform * Transform3D(Basis.IDENTITY, col_shape.position)
			# 4隅（上面のXZ平面）
			var c0 : Vector3 = t * Vector3(-half.x, 0, -half.z)
			var c1 : Vector3 = t * Vector3(half.x, 0, -half.z)
			var c2 : Vector3 = t * Vector3(half.x, 0, half.z)
			var c3 : Vector3 = t * Vector3(-half.x, 0, half.z)
			f2.store_line("QUAD|%.2f,%.2f|%.2f,%.2f|%.2f,%.2f|%.2f,%.2f" % [c0.x,c0.z,c1.x,c1.z,c2.x,c2.z,c3.x,c3.z])
		f2.close()
		print("[MapGenerator] collision_corners.txt 出力")
	print("[MapGenerator] コリジョン追加: %d 個" % count)


## デバッグ用: コリジョンを赤い半透明ボックスで可視化
func _add_debug_mesh(body: StaticBody3D, box_size: Vector3, offset: Vector3, visible_init: bool = false) -> void:
	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size
	mesh_inst.mesh = box_mesh
	mesh_inst.position = offset
	var debug_mat := StandardMaterial3D.new()
	debug_mat.albedo_color = Color(1.0, 0.0, 0.0, 0.3)
	debug_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	debug_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	debug_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.set_surface_override_material(0, debug_mat)
	mesh_inst.visible = visible_init
	body.add_child(mesh_inst)
