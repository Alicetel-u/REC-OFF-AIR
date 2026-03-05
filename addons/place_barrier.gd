extends SceneTree

func _init():
	var scene_path = "res://scenes/Main.tscn"
	var main_scene = load(scene_path)
	if not main_scene:
		print("Error: Main.tscn not found")
		quit()
		return
		
	var root = main_scene.instantiate()
	
	# === 立ち入り禁止バリケードの配置 ===
	# 幸福通り (ShoppingStreetGate) は (38, 0, -4.0) に設置されている
	# その手前（大通りとの境目付近）に配置する
	
	var barrier_model_path = "res://shaders/素材/立ち入り禁止.glb"
	if not FileAccess.file_exists(barrier_model_path):
		print("ERROR: Barrier model not found at ", barrier_model_path)
		quit()
		return

	var barrier_scene = load(barrier_model_path)
	if not barrier_scene:
		print("ERROR: Failed to load Barrier model.")
		quit()
		return

	# 既存のバリケードがあれば削除
	for child in root.get_children():
		if child.name.begins_with("NoEntryBarrier"):
			root.remove_child(child)
			child.queue_free()

	# ゲート中央に1つだけ配置
	var x_pos = 38.0
	var z_pos = -4.0 # ゲートの真下に配置
	
	var barrier = barrier_scene.instantiate()
	barrier.name = "NoEntryBarrier"
	barrier.position = Vector3(x_pos, 1.0, z_pos) # 50センチ上げる (0.5 -> 1.0)
	barrier.scale = Vector3(6.0, 6.0, 6.0)
	barrier.rotation_degrees.y = 270
	
	root.add_child(barrier)
	barrier.owner = root
	_set_owner_recursive(barrier, root)

	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, scene_path)
	print("Placed 'No Entry' barriers in front of Kofuku Street.")
	quit()

func _set_owner_recursive(node: Node, owner_node: Node):
	for child in node.get_children():
		child.owner = owner_node
		_set_owner_recursive(child, owner_node)
