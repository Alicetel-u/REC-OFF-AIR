extends SceneTree

func _init():
	var scene_path = "res://scenes/Main.tscn"
	var main_scene = load(scene_path)
	if not main_scene:
		print("Error: Main.tscn not found")
		quit()
		return
		
	var root = main_scene.instantiate()
	
	# === 枯れ木の配置 ===
	var tree_model_path = "res://shaders/素材/dead_tree.glb"
	if not FileAccess.file_exists(tree_model_path):
		print("ERROR: Tree model not found at ", tree_model_path)
		quit()
		return

	var tree_scene = load(tree_model_path)
	if not tree_scene:
		print("ERROR: Failed to load Tree model.")
		quit()
		return
	print("Loaded tree model successfully.")

	# 既存の枯れ木を削除
	var count = 0
	for child in root.get_children():
		if child.name.begins_with("GateDeadTree"):
			root.remove_child(child)
			child.queue_free()
			count += 1
	print("Removed ", count, " existing trees.")

	# ゲート (38, 0, -4.0) の位置を基準に配置
	# Y座標を 2.0 に上げて、スケールを 10.0 以上にする
	
	# 1. 左側の木
	var tree_left = tree_scene.instantiate()
	tree_left.name = "GateDeadTree_Left"
	tree_left.position = Vector3(30.0, 2.0, 0.0) # さらに外側・手前に
	tree_left.scale = Vector3(10.0, 12.0, 10.0)     
	tree_left.rotation_degrees.y = 20          
	root.add_child(tree_left)
	tree_left.owner = root
	_set_owner_recursive(tree_left, root)
	
	# 2. 右側の木
	var tree_right = tree_scene.instantiate()
	tree_right.name = "GateDeadTree_Right"
	tree_right.position = Vector3(46.0, 2.0, -2.0) 
	tree_right.scale = Vector3(12.0, 15.0, 12.0)    
	tree_right.rotation_degrees.y = -50         
	root.add_child(tree_right)
	tree_right.owner = root
	_set_owner_recursive(tree_right, root)

	print("Added new trees. Root child count: ", root.get_child_count())

	# シーンを保存
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, scene_path)
	print("Placed asymmetrical dead trees in front of the gate.")
	quit()

func _set_owner_recursive(node: Node, owner_node: Node):
	for child in node.get_children():
		child.owner = owner_node
		_set_owner_recursive(child, owner_node)
