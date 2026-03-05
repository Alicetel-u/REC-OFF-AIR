extends SceneTree

func _init():
	var path = "res://assets/models/environment/MountainsAndFields.tscn"
	var model_path = "res://shaders/素材/案山子.glb"
	
	var scene = load(path)
	if not scene:
		printerr("Failed to load MountainsAndFields.tscn")
		quit()
		return
		
	var root = scene.instantiate()
	
	# ScarecrowGrpをノードごと削除して完全にクリーンにする
	var old_grp = root.get_node_or_null("ScarecrowGrp")
	if old_grp:
		print("Removing old ScarecrowGrp...")
		root.remove_child(old_grp)
		old_grp.free()
	
	# 新しくScarecrowGrpを作成
	var new_grp = Node3D.new()
	new_grp.name = "ScarecrowGrp"
	new_grp.position = Vector3(8, -0.2, 12)
	new_grp.rotation_degrees.y = 180
	root.add_child(new_grp)
	new_grp.owner = root
	
	# 新しいGLBモデルを読み込んで配置
	var model_scene = load(model_path)
	if model_scene:
		var model = model_scene.instantiate()
		model.name = "ScarecrowModel"
		new_grp.add_child(model)
		set_owner_recursive(model, root)
		print("Added new GLB model to ScarecrowGrp.")
	else:
		printerr("Failed to load model: ", model_path)
		
	var packed = PackedScene.new()
	var err = packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
		print("Successfully saved MountainsAndFields.tscn. Error code: ", err)
	else:
		printerr("Failed to pack scene.")
		
	quit()

func set_owner_recursive(node, root):
	node.owner = root
	for child in node.get_children():
		set_owner_recursive(child, root)
