extends SceneTree

func _init():
	replace_scarecrow()
	quit()

func replace_scarecrow():
	var subscene_path = "res://assets/models/environment/MountainsAndFields.tscn"
	var model_path = "res://shaders/素材/案山子.glb"
	
	var scene = load(subscene_path)
	if not scene:
		printerr("Failed to load MountainsAndFields.tscn")
		return
		
	var root = scene.instantiate()
	var scarecrow_grp = root.get_node_or_null("ScarecrowGrp")
	
	if not scarecrow_grp:
		printerr("ScarecrowGrp not found in MountainsAndFields.tscn")
		return
		
	print("Found ScarecrowGrp. Children count before cleaning: ", scarecrow_grp.get_child_count())
	
	# Remove old procedural parts
	for child in scarecrow_grp.get_children():
		print("Removing child: ", child.name)
		scarecrow_grp.remove_child(child)
		child.queue_free() # Use queue_free in scripts sometimes safer or free()
		
	# Instantiate new model
	var model_scene = load(model_path)
	if not model_scene:
		printerr("Failed to load scarecrow model: ", model_path)
		return
		
	var scarecrow_model = model_scene.instantiate()
	scarecrow_model.name = "ScarecrowModel"
	
	# Adjustments
	scarecrow_model.scale = Vector3(1, 1, 1)
	scarecrow_model.position = Vector3(0, 0, 0)
	
	scarecrow_grp.add_child(scarecrow_model)
	set_owner_recursive(scarecrow_model, root)
	
	print("Children count after adding model: ", scarecrow_grp.get_child_count())
	
	var packed = PackedScene.new()
	var err = packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, subscene_path)
		print("Successfully replaced scarecrow with GLB model. Save result code: ", err)
		if err == OK:
			print("File saved successfully to ", subscene_path)
		else:
			printerr("ResourceSaver.save failed with error code: ", err)
	else:
		printerr("Failed to pack scene: ", err)

func set_owner_recursive(node, root):
	node.owner = root
	for child in node.get_children():
		set_owner_recursive(child, root)
