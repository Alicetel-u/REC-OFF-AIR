extends SceneTree

func _init():
	var subscene_path = "res://assets/models/environment/MountainsAndFields.tscn"
	var model_path = "res://shaders/素材/案山子.glb"
	
	# ファイルの存在確認
	if not FileAccess.file_exists("c:/Users/【RST-11】リバイブ新所沢/OneDrive/デスクトップ/プロジェクト/ホラゲー/shaders/素材/案山子.glb"):
		printerr("CRITICAL: GLB file not found on disk at absolute path.")
		quit()
		return

	var scene = load(subscene_path)
	if not scene:
		printerr("Failed to load MountainsAndFields.tscn")
		quit()
		return
		
	var root = scene.instantiate()
	var scarecrow_grp = root.get_node_or_null("ScarecrowGrp")
	
	if not scarecrow_grp:
		printerr("ScarecrowGrp not found, creating new one.")
		scarecrow_grp = Node3D.new()
		scarecrow_grp.name = "ScarecrowGrp"
		root.add_child(scarecrow_grp)
		scarecrow_grp.owner = root
	
	# 既存の子供を完全に削除
	for child in scarecrow_grp.get_children():
		scarecrow_grp.remove_child(child)
		child.free()
		
	# モデルの読み込み
	var model_scene = load(model_path)
	if not model_scene:
		printerr("Failed to load GLB model via load().")
		quit()
		return
		
	var scarecrow_model = model_scene.instantiate()
	scarecrow_model.name = "ScarecrowModel"
	scarecrow_grp.add_child(scarecrow_model)
	
	# 再帰的にOwnerを設定
	set_owner_recursive(scarecrow_model, root)
	
	# トランスフォーム設定
	scarecrow_grp.position = Vector3(8, -0.2, 12)
	scarecrow_grp.rotation_degrees.y = 180
	
	var packed = PackedScene.new()
	var err = packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, subscene_path)
		print("Successfully saved scene. Error: ", err)
	else:
		printerr("Failed to pack scene.")
		
	quit()

func set_owner_recursive(node, root):
	node.owner = root
	for child in node.get_children():
		set_owner_recursive(child, root)
