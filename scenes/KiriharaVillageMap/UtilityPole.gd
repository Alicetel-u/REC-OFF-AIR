@tool
extends Node3D

# --- 古びた電信柱の設定 ---
@export var texture: Texture2D = preload("res://scenes/KiriharaVillageMap/電信柱_basecolor.png")
@export var pole_height: float = 10.0 # 巨大化
@export var pole_radius: float = 0.35 # 太くする
@export var lean_angle: float = 3.0
@export var texture_scale: Vector3 = Vector3(1.0, 4.0, 1.0)

func _ready():
	# 子供（メッシュ）が既にいる場合は、そのマテリアルを更新する
	if get_child_count() > 0:
		_apply_rust_to_existing()
		return
	_create_pole()

func _apply_rust_to_existing():
	# 既存のノードを探してマテリアルを更新
	var nodes = [get_node_or_null("PoleMesh"), get_node_or_null("CrossArm")]
	for node in nodes:
		if node is MeshInstance3D:
			var mat = StandardMaterial3D.new()
			if texture: mat.albedo_texture = texture
			mat.albedo_color = Color(0.45, 0.3, 0.2)
			mat.uv1_scale = texture_scale
			mat.uv1_triplanar = true
			mat.roughness = 1.0
			mat.metallic = 0.4
			node.set_surface_override_material(0, mat)

func _create_pole():
	# メインの柱
	var pole_mesh = MeshInstance3D.new()
	pole_mesh.name = "PoleMesh"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = pole_radius * 0.8
	cylinder.bottom_radius = pole_radius
	cylinder.height = pole_height
	pole_mesh.mesh = cylinder
	
	# マテリアルの設定（錆びついた質感）
	var mat = StandardMaterial3D.new()
	if texture:
		mat.albedo_texture = texture
		# 錆びた赤茶色を乗算
		mat.albedo_color = Color(0.45, 0.3, 0.2) 
	else:
		mat.albedo_color = Color(0.25, 0.15, 0.1) # 濃い錆色
	
	mat.uv1_scale = texture_scale
	mat.uv1_triplanar = true
	mat.roughness = 1.0     # 錆びてカサカサ
	mat.metallic = 0.4      # 錆びた金属の鈍い光
	mat.uv1_world_triplanar = true # タイリングをワールド座標に合わせる
	
	pole_mesh.set_surface_override_material(0, mat)
	
	# 配置と傾き
	pole_mesh.position.y = pole_height / 2.0
	pole_mesh.rotation_degrees.z = lean_angle
	add_child(pole_mesh)
	if Engine.is_editor_hint(): pole_mesh.owner = get_tree().edited_scene_root

	# 横木
	var crossarm = MeshInstance3D.new()
	crossarm.name = "CrossArm"
	var box = BoxMesh.new()
	box.size = Vector3(1.5, 0.15, 0.15)
	crossarm.mesh = box
	crossarm.set_surface_override_material(0, mat)
	crossarm.position = Vector3(0, pole_height * 0.85, 0)
	crossarm.rotation_degrees.z = lean_angle
	add_child(crossarm)
	if Engine.is_editor_hint(): crossarm.owner = get_tree().edited_scene_root
