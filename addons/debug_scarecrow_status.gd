extends SceneTree

func _init():
	var main_scene = load("res://scenes/Main.tscn")
	if not main_scene:
		print("KAKASHI_DEBUG: Failed to load Main.tscn")
		quit()
		return
		
	var root = main_scene.instantiate()
	
	var m_and_f = root.get_node_or_null("MountainsAndFields")
	if m_and_f:
		var grp = m_and_f.get_node_or_null("ScarecrowGrp")
		if grp:
			print("KAKASHI_DEBUG: ScarecrowGrp found")
			print("KAKASHI_DEBUG: Position=", grp.position)
			print("KAKASHI_DEBUG: Global Transform=", grp.transform)
			print("KAKASHI_DEBUG: Children=", grp.get_child_count())
			for child in grp.get_children():
				print("KAKASHI_DEBUG: Child=", child.name, " Type=", child.get_class(), " Scale=", child.scale, " Visible=", child.visible)
				_print_tree(child, "  ")
		else:
			print("KAKASHI_DEBUG: ScarecrowGrp NOT FOUND")
	else:
		print("KAKASHI_DEBUG: MountainsAndFields NOT FOUND")
	
	quit()

func _print_tree(node, indent):
	for child in node.get_children():
		var info = indent + child.name + " (" + child.get_class() + ")"
		if child is MeshInstance3D:
			info += " HAS_MESH"
		print("KAKASHI_DEBUG: ", info)
		_print_tree(child, indent + "  ")
