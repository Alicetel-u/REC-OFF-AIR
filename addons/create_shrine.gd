extends SceneTree

# ============================================================
# 本格的な神社生成スクリプト
# 画像参考: 木造の社殿、狛犬、石造りの台座
# ============================================================

func _init():
	var scene_path = "res://scenes/Main.tscn"
	var main_scene = load(scene_path)
	if not main_scene:
		print("Error: Main.tscn not found")
		quit()
		return
		
	var root = main_scene.instantiate()
	
	# 既存の神社があれば削除して更新
	var old_shrine = root.get_node_or_null("SmallShrine")
	if old_shrine:
		root.remove_child(old_shrine)
		old_shrine.free()
		
	var shrine_root = Node3D.new()
	shrine_root.name = "SmallShrine"
	# 大通りから離し、森の奥側（-Z方向）へ移動
	shrine_root.position = Vector3(12.0, 0, -15.0)
	shrine_root.rotation_degrees.y = 0 # 道路側（+Z方向）を正面にする
	root.add_child(shrine_root)
	shrine_root.owner = root
	
	var mats = _create_materials()
	_build_advanced_shrine(shrine_root, root, mats)
	
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, scene_path)
	print("Advanced Shrine (Photo Match) created at (12.0, 0, -5.0)")
	quit()

func _create_materials() -> Dictionary:
	# 古びた木材（社殿）
	var mat_weathered_wood = StandardMaterial3D.new()
	mat_weathered_wood.albedo_color = Color(0.25, 0.2, 0.15)
	mat_weathered_wood.roughness = 0.95
	
	# 瓦・屋根用（さらに暗い色）
	var mat_roof = StandardMaterial3D.new()
	mat_roof.albedo_color = Color(0.15, 0.15, 0.15)
	mat_roof.roughness = 0.9
	
	# 苔むした石（台座・狛犬）
	var mat_mossy_stone = ShaderMaterial.new()
	mat_mossy_stone.shader = load("res://shaders/mossy_stone.gdshader")
	
	# 怪しく光る目
	var mat_eye = StandardMaterial3D.new()
	mat_eye.albedo_color = Color(1.0, 0.1, 0.0)
	mat_eye.emission_enabled = true
	mat_eye.emission = Color(1.0, 0.1, 0.0)
	mat_eye.emission_energy_multiplier = 2.0

	# 鈴・金属
	var mat_metal = StandardMaterial3D.new()
	mat_metal.albedo_color = Color(0.6, 0.5, 0.3)
	mat_metal.metallic = 0.7
	mat_metal.roughness = 0.5
	
	# 縄・鈴緒
	var mat_rope = StandardMaterial3D.new()
	mat_rope.albedo_color = Color(0.7, 0.6, 0.5)
	mat_rope.roughness = 1.0

	return {
		"wood": mat_weathered_wood,
		"roof": mat_roof,
		"stone": mat_mossy_stone,
		"eye": mat_eye,
		"metal": mat_metal,
		"rope": mat_rope
	}

func _build_advanced_shrine(parent: Node3D, owner_node: Node, mats: Dictionary):
	# --- 地面 ---
	var ground = CSGBox3D.new()
	ground.size = Vector3(6.0, 0.1, 7.0)
	ground.position = Vector3(0, -0.05, 2.0)
	ground.material = mats["stone"]
	_add(ground, parent, owner_node)

	# --- 1. 本殿 (Large Wooden Hall) ---
	_build_main_hall(parent, owner_node, mats)

	# --- 2. 狛犬 (Komainu on Pedestals) ---
	_build_pedestal_and_komainu(parent, owner_node, Vector3(-2.2, 0, 3.5), mats, true) # 阿形 (Left)
	_build_pedestal_and_komainu(parent, owner_node, Vector3(2.2, 0, 3.5), mats, false) # 吽形 (Right)

	# --- 3. 参道 (Stone Path with Edging) ---
	_build_photo_path(parent, owner_node, mats)
	
	# --- 4. 枯れ木 (Dead Trees) ---
	_build_dead_trees(parent, owner_node)

func _build_dead_trees(parent: Node3D, owner_node: Node):
	var tree_path = "res://shaders/素材/dead_tree.glb"
	if not FileAccess.file_exists(tree_path):
		print("ERROR: Dead tree model not found.")
		return
		
	var tree_scene = load(tree_path)
	if not tree_scene: return
	
	# より外側・遠くに配置を修正 (狛犬や参道との干渉回避)
	var positions = [
		Vector3(-7.0, 0, -5.0),  # 左奥（より深く）
		Vector3(8.0, 0, -6.0),   # 右奥（より深く）
		Vector3(-8.5, 0, 5.0),   # 左手前（外側へ）
		Vector3(9.0, 0, 7.5),    # 右手前（外側へ）
		Vector3(0, 0, -12.0)     # 真後ろ（より奥へ）
	]
	
	for i in range(positions.size()):
		var tree = tree_scene.instantiate()
		tree.name = "DeadTree_" + str(i)
		# 位置を 3メートル上に調整
		tree.position = positions[i] + Vector3(0, 3.0, 0)
		# 神社のサイズ(8.0)に合わせて巨大化
		tree.rotation_degrees.y = i * 73.0 
		var s = 7.0 + (i % 3) * 1.5 # 7.0, 8.5, 10.0 のバリエーション
		tree.scale = Vector3(s, s, s)
		
		parent.add_child(tree)
		tree.owner = owner_node
		_set_owner_recursive(tree, owner_node)


func _build_main_hall(parent: Node3D, owner_node: Node, mats: Dictionary):
	var hall_model_path = "res://shaders/素材/shrine_building.glb"
	
	if not FileAccess.file_exists(hall_model_path):
		print("ERROR: Shrine hall model not found at ", hall_model_path)
		return

	var hall_scene = load(hall_model_path)
	if not hall_scene:
		print("ERROR: Failed to load Shrine hall model.")
		return

	var hall = hall_scene.instantiate()
	hall.name = "MainHall"
	# 位置を10センチ下げ(3.3)に変更
	hall.position = Vector3(0, 3.3, 0)
	hall.scale = Vector3(8.0, 8.0, 8.0)
	hall.rotation_degrees.y = -90 
	
	parent.add_child(hall)
	hall.owner = owner_node
	_set_owner_recursive(hall, owner_node)

	print("Successfully placed Shrine hall model on the ground.")

	print("Successfully placed Shrine hall model.")

func _set_owner_recursive(node: Node, owner_node: Node):
	for child in node.get_children():
		child.owner = owner_node
		_set_owner_recursive(child, owner_node)

func _build_pedestal_and_komainu(parent: Node3D, owner_node: Node, pos: Vector3, mats: Dictionary, is_agyo: bool):
	var pedestal = Node3D.new()
	pedestal.name = "Pedestal_Model_A" if is_agyo else "Pedestal_Model_Un"
	pedestal.position = pos
	parent.add_child(pedestal)
	pedestal.owner = owner_node

	# --- 台座 ---
	var base_ped = CSGCombiner3D.new()
	_add(base_ped, pedestal, owner_node)
	
	var p1 = CSGBox3D.new()
	p1.size = Vector3(1.3, 0.7, 1.3)
	p1.position = Vector3(0, 0.35, 0)
	p1.material = mats["stone"]
	_add(p1, base_ped, owner_node)
	
	var p2 = CSGBox3D.new()
	p2.size = Vector3(1.1, 0.4, 1.1)
	p2.position = Vector3(0, 0.9, 0)
	p2.material = mats["stone"]
	_add(p2, base_ped, owner_node)
	
	# --- 狛犬モデルのロードとインスタンス化 ---
	var model_path = "res://shaders/素材/komainu.glb"
	
	if not FileAccess.file_exists(model_path):
		print("ERROR: File does not exist at ", model_path)
		# .importファイルがない場合もFileAccess.file_existsはtrueを返す場合があるが、
		# load()は失敗するので、その判定を行う。
	
	var model_scene = load(model_path)
	if model_scene:
		print("Loading Komainu model: ", model_path)
		var model = model_scene.instantiate()
		# スケールを調整 (台座の幅1.1に合わせて調整)
		model.scale = Vector3(1.2, 1.2, 1.2) 
		model.position = Vector3(0, 1.6, 0) # さらに高く(1.6)調整
		
		# 道路側（参拝者）を向くように回転 (反転)
		model.rotation_degrees.y = (25 if is_agyo else -25)
		
		pedestal.add_child(model)
		model.owner = owner_node
		_set_owner_recursive(model, owner_node)
		
		# 光る目 (モデルのスケールに合わせて位置を調整)
		var eyes_root = Node3D.new()
		eyes_root.name = "Eyes"
		# 狛犬の高さ(1.6)に合わせて目を調整
		eyes_root.position = Vector3(0, 1.6 + 0.15, 0.1) 
		pedestal.add_child(eyes_root)
		eyes_root.owner = owner_node
		
		for x in [-1, 1]:
			var eye_glow = CSGSphere3D.new()
			eye_glow.radius = 0.015 # 目も少し小さく
			eye_glow.position = Vector3(x * 0.05, 0, 0)
			eye_glow.material = mats["eye"]
			_add(eye_glow, eyes_root, owner_node)
		
		print("Successfully placed Komainu model ", "A" if is_agyo else "Un")
	else:
		print("ERROR: Failed to load Komainu model at ", model_path)
		print("Check if the model is correctly imported in Godot Editor (check for .import file).")



func _build_photo_path(parent: Node3D, owner_node: Node, mats: Dictionary):
	# 指定の長さ 16.0m に調整
	var path = CSGBox3D.new()
	path.size = Vector3(1.5, 0.03, 16.0)
	path.position = Vector3(0, 0.015, 8.0)
	path.material = mats["stone"]
	_add(path, parent, owner_node)
	
	# 縁取りの石も 16.0m に合わせて調整（40個）
	for i in range(40):
		for j in [-1, 1]:
			var stone = CSGSphere3D.new()
			stone.radius = 0.15
			stone.position = Vector3(j * 0.9, 0.05, 0.5 + i * 0.4)
			stone.material = mats["stone"]
			stone.scale.y = 0.5
			_add(stone, parent, owner_node)


func _add(node: Node, parent: Node, owner_node: Node):
	parent.add_child(node)
	node.owner = owner_node
