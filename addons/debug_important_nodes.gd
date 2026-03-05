extends SceneTree

func _init():
	var scene = load("res://scenes/Main.tscn")
	var root = scene.instantiate()
	
	_print_important_nodes(root)
	quit()

func _print_important_nodes(node: Node):
	var important_names = ["ShoppingStreetGate", "SmallShrine", "ScarecrowGrp", "ScarecrowGrp2", "StreetRoot", "VillageGate"]
	
	for important in important_names:
		var n = node.get_node_or_null(important)
		if n:
			print(n.name + " at " + str(n.position) + " rotation: " + str(n.rotation_degrees))
			# Also check for road inside gate
			if n.name == "ShoppingStreetGate":
				var road = n.get_node_or_null("ConcreteRoad")
				if road:
					print("  ConcreteRoad at " + str(road.position) + " size: " + str(road.size))
