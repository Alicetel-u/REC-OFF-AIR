extends SceneTree

func _init():
	var root = Node3D.new()
	root.name = "ShoppingStreetGate"
	
	# Materials
	var rust_mat = StandardMaterial3D.new()
	rust_mat.albedo_color = Color(0.3, 0.12, 0.05)
	rust_mat.metallic = 0.8
	rust_mat.roughness = 0.9
	
	var white_mat = StandardMaterial3D.new()
	white_mat.albedo_color = Color(0.85, 0.85, 0.85)
	white_mat.roughness = 1.0
	
	var clock_mat = StandardMaterial3D.new()
	clock_mat.albedo_color = Color(0.9, 0.9, 0.8)
	
	# Pillars (Left and Right)
	var pillar_radius = 0.15
	var pillar_height = 4.0
	var distance = 6.0 # Total width between pillars 6m
	
	var left_pillar = CSGCylinder3D.new()
	left_pillar.name = "LeftPillar"
	left_pillar.radius = pillar_radius
	left_pillar.height = pillar_height
	left_pillar.position = Vector3(-distance/2.0, pillar_height/2.0, 0)
	left_pillar.material_override = rust_mat
	root.add_child(left_pillar)
	left_pillar.owner = root
	
	var right_pillar = CSGCylinder3D.new()
	right_pillar.name = "RightPillar"
	right_pillar.radius = pillar_radius
	right_pillar.height = pillar_height
	right_pillar.position = Vector3(distance/2.0, pillar_height/2.0, 0)
	right_pillar.material_override = rust_mat
	root.add_child(right_pillar)
	right_pillar.owner = root
	
	# Arch Sign Combiner
	var arch_combiner = CSGCombiner3D.new()
	arch_combiner.name = "ArchSign"
	arch_combiner.position = Vector3(0, pillar_height, 0)
	root.add_child(arch_combiner)
	arch_combiner.owner = root
	
	var outer_arch = CSGCylinder3D.new()
	outer_arch.name = "OuterRing"
	outer_arch.radius = distance / 2.0 + 0.6
	outer_arch.height = 0.2
	outer_arch.rotation = Vector3(PI/2, 0, 0) # Face front Z
	outer_arch.material_override = white_mat
	arch_combiner.add_child(outer_arch)
	outer_arch.owner = root
	
	var inner_arch = CSGCylinder3D.new()
	inner_arch.name = "InnerRing"
	inner_arch.operation = CSGShape3D.OPERATION_SUBTRACTION
	inner_arch.radius = distance / 2.0 - 0.6
	inner_arch.height = 0.4
	inner_arch.rotation = Vector3(PI/2, 0, 0)
	arch_combiner.add_child(inner_arch)
	inner_arch.owner = root
	
	var bottom_cut = CSGBox3D.new()
	bottom_cut.name = "BottomCut"
	bottom_cut.operation = CSGShape3D.OPERATION_SUBTRACTION
	bottom_cut.size = Vector3(distance + 2.0, outer_arch.radius + 1.0, 1.0)
	bottom_cut.position = Vector3(0, -(outer_arch.radius + 1.0)/2.0 + 0.2, 0)
	arch_combiner.add_child(bottom_cut)
	bottom_cut.owner = root
	
	# Crossbeam (Bottom of the sign)
	var crossbeam = CSGBox3D.new()
	crossbeam.name = "CrossBeam"
	crossbeam.size = Vector3(distance + 0.4, 0.15, 0.15)
	crossbeam.position = Vector3(0, pillar_height + 0.2, 0)
	crossbeam.material_override = rust_mat
	root.add_child(crossbeam)
	crossbeam.owner = root
	
	# Clock (Center)
	var clock = CSGCylinder3D.new()
	clock.name = "Clock"
	clock.radius = 0.5
	clock.height = 0.25
	clock.rotation = Vector3(PI/2, 0, 0)
	clock.position = Vector3(0, pillar_height + outer_arch.radius - 1.2, 0)
	clock.material_override = clock_mat
	root.add_child(clock)
	clock.owner = root
	
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://assets/models/environment/ShoppingStreetGate.tscn")
	print("ShoppingStreetGate saved to assets/models/environment/ShoppingStreetGate.tscn")
	
	# Put it in Main.tscn
	var main_tscn = load("res://scenes/Main.tscn")
	if main_tscn:
		var main_root = main_tscn.instantiate()
		
		# Check if already exists
		if main_root.has_node("ShoppingStreetGate"):
			main_root.get_node("ShoppingStreetGate").queue_free()
			
		var loaded_scene = load("res://assets/models/environment/ShoppingStreetGate.tscn")
		var gate_instance = loaded_scene.instantiate()
		gate_instance.name = "ShoppingStreetGate"
		
		# Place at a side path after the village gate.
		gate_instance.position = Vector3(32, 0, 12)
		gate_instance.rotation = Vector3(0, 0, 0) # Face Z
		
		main_root.add_child(gate_instance)
		gate_instance.owner = main_root
		
		var packed_main = PackedScene.new()
		packed_main.pack(main_root)
		ResourceSaver.save(packed_main, "res://scenes/Main.tscn")
		print("ShoppingStreetGate instance added to Main.tscn at (32, 0, 12).")
	
	quit()
