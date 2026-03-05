extends SceneTree

func _init():
	var scene = load("res://scenes/Main.tscn")
	var root = scene.instantiate()
	
	_print_node(root)
	quit()

func _print_node(node: Node, indent: String = ""):
	if node is Node3D:
		print(indent + node.name + " at " + str(node.position) + " rot: " + str(node.rotation_degrees))
	else:
		print(indent + node.name)
		
	for child in node.get_children():
		_print_node(child, indent + "  ")
