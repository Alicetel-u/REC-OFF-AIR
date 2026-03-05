extends SceneTree

func _init():
	var scene = load("res://assets/models/environment/MountainsAndFields.tscn")
	if not scene: 
		print("MountainsAndFields.tscn not found")
		quit()
		return
	var root = scene.instantiate()
	_find_shrine(root)
	quit()

func _find_shrine(node: Node, path: String = ""):
	var current_path = path + "/" + node.name if path != "" else node.name
	if "Shrine" in node.name:
		print("Found shrine in MountainsAndFields: " + current_path + " at " + str(node.position if node is Node3D else "N/A"))
	for child in node.get_children():
		_find_shrine(child, current_path)
