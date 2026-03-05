extends SceneTree

func _init():
	var scene = load("res://scenes/Main.tscn")
	var root = scene.instantiate()
	var shrine = root.get_node_or_null("SmallShrine")
	if shrine:
		print("--- Shrine Hierarchy ---")
		_print_tree(shrine, 0)
	else:
		print("SmallShrine not found in Main.tscn")
	quit()

func _print_tree(node, level):
	var indent = ""
	for i in range(level):
		indent += "  "
	print(indent + node.name + " (" + node.get_class() + ") pos:" + str(node.position if node is Node3D else "N/A"))
	for child in node.get_children():
		_print_tree(child, level + 1)
