extends Node3D

## 案山子のメッシュにほんのり茶色の発光を追加する

const GLOW_COLOR := Color(0.6, 0.35, 0.1)  # 茶色系
const GLOW_ENERGY := 0.35

func _ready() -> void:
	_apply_glow(self)

func _apply_glow(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for i in mi.get_surface_override_material_count():
			var base_mat := mi.mesh.surface_get_material(i)
			if base_mat is StandardMaterial3D:
				var mat := base_mat.duplicate() as StandardMaterial3D
				mat.emission_enabled = true
				mat.emission = GLOW_COLOR
				mat.emission_energy_multiplier = GLOW_ENERGY
				mi.set_surface_override_material(i, mat)
	for child in node.get_children():
		_apply_glow(child)
