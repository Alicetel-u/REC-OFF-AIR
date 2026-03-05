extends SceneTree

func _init():
	var root = Node3D.new()
	root.name = "PhysicalToilet"
	
	# --- 素材（マテリアル）の設定 ---
	var shader = load("res://assets/models/public_toilet/shaders/ancient_dirty_tile.gdshader")
	
	# 地壁（タイルの後ろ側）
	var base_wall_mat = StandardMaterial3D.new()
	base_wall_mat.albedo_color = Color(0.15, 0.15, 0.15) # 暗いコンクリートの色
	base_wall_mat.roughness = 1.0
	
	# タイル単体用マテリアル
	var tile_mat = ShaderMaterial.new()
	tile_mat.shader = shader
	tile_mat.set_shader_parameter("base_color", Color(0.4, 0.5, 0.3, 1.0)) # 緑
	tile_mat.set_shader_parameter("tile_size", 0.0) # シェーダー側の目地は不要（物理で作るため）
	tile_mat.set_shader_parameter("moss_amount", 0.5)
	tile_mat.set_shader_parameter("rust_amount", 0.4)

	# --- 部屋の基本構造 ---
	var room_size = Vector3(6, 3, 8)
	var tile_dim = Vector2(0.3, 0.15) # タイル1枚のサイズ (30cm x 15cm)
	var gap = 0.01 # 目地の隙間
	
	# 6つの面（床、天井、壁4枚）を生成
	create_physical_face(root, "Floor", Vector3(room_size.x, 0.1, room_size.z), Vector3(0, 0, 0), tile_dim, gap, tile_mat, base_wall_mat, 0.4)
	create_physical_face(root, "Ceiling", Vector3(room_size.x, 0.1, room_size.z), Vector3(0, room_size.y, 0), tile_dim, gap, tile_mat, base_wall_mat, 0.2)
	create_physical_face(root, "Wall_Back", Vector3(room_size.x, room_size.y, 0.1), Vector3(0, room_size.y/2.0, -room_size.z/2.0), tile_dim, gap, tile_mat, base_wall_mat, 0.7)
	create_physical_face(root, "Wall_Left", Vector3(0.1, room_size.y, room_size.z), Vector3(-room_size.x/2.0, room_size.y/2.0, 0), tile_dim, gap, tile_mat, base_wall_mat, 0.6)
	create_physical_face(root, "Wall_Right", Vector3(0.1, room_size.y, room_size.z), Vector3(room_size.x/2.0, room_size.y/2.0, 0), tile_dim, gap, tile_mat, base_wall_mat, 0.5)

	# シーン保存
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/PhysicalToilet.tscn")
	print("Physical tile generation complete: res://scenes/PhysicalToilet.tscn")
	quit()

# 面（壁・床など）をタイルで埋め尽くす関数
func create_physical_face(parent, face_name, size, pos, t_dim, gap, t_mat, b_mat, dirt_intensity):
	var node = Node3D.new()
	node.name = face_name
	node.transform.origin = pos
	parent.add_child(node)
	node.set_owner(parent.get_owner() if parent.get_owner() else parent)
	
	# ベースとなる地壁
	var base = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	base.mesh = box
	base.material_override = b_mat
	node.add_child(base)
	base.set_owner(parent.get_owner() if parent.get_owner() else parent)
	
	# タイルの配置計算
	# 面の向き（法線）を判定してグリッドを生成
	var is_horizontal = size.y < 0.2
	var width = size.x if not size.x < 0.2 else size.z
	var height = size.y if not size.y < 0.2 else size.z
	if is_horizontal: width = size.x; height = size.z

	var cols = int(width / (t_dim.x + gap))
	var rows = int(height / (t_dim.y + gap))
	
	# MultiMeshInstance3D を使用して効率的に配置
	var mm = MultiMeshInstance3D.new()
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = BoxMesh.new()
	multimesh.mesh.size = Vector3(t_dim.x, 0.02, t_dim.y) if is_horizontal else Vector3(t_dim.x, t_dim.y, 0.02)
	multimesh.instance_count = cols * rows
	mm.multimesh = multimesh
	mm.material_override = t_mat
	node.add_child(mm)
	mm.set_owner(parent.get_owner() if parent.get_owner() else parent)
	
	var rand = RandomNumberGenerator.new()
	rand.seed = face_name.hash()
	
	var idx = 0
	for c in range(cols):
		for r in range(rows):
			var x = (c - cols/2.0) * (t_dim.x + gap)
			var y = (r - rows/2.0) * (t_dim.y + gap)
			
			var t = Transform3D()
			if is_horizontal:
				t.origin = Vector3(x, size.y/2.0 + 0.01, y)
			elif size.x < 0.2: # 左右の壁
				t.origin = Vector3(size.x/2.0 + 0.01 if pos.x > 0 else -size.x/2.0 - 0.01, y, x)
			else: # 奥の壁
				t.origin = Vector3(x, y, size.z/2.0 + 0.01 if pos.z > 0 else -size.z/2.0 - 0.01)
			
			# --- リアリティのためのランダム性 ---
			# 一部を「剥がれ落ちた」ことにしてスキップ
			if rand.randf() < 0.05 * dirt_intensity:
				t.origin = Vector3(0,-100,0) # 画面外へ
			else:
				# わずかな傾き
				t = t.rotated(Vector3(1,0,0), rand.randf_range(-0.02, 0.02))
				t = t.rotated(Vector3(0,1,0), rand.randf_range(-0.02, 0.02))
				# わずかな位置のズレ
				t.origin += Vector3(rand.randf_range(-0.005, 0.005), rand.randf_range(-0.005, 0.005), rand.randf_range(-0.005, 0.005))
			
			multimesh.set_instance_transform(idx, t)
			idx += 1
