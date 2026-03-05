extends SceneTree

func _init():
	var scene_path = "res://scenes/Main.tscn"
	var main_scene = load(scene_path)
	if not main_scene:
		print("Error: Main.tscn not found")
		quit()
		return
		
	var root = main_scene.instantiate()
	
	# ShoppingStreetGate を探す
	var gate = root.get_node_or_null("ShoppingStreetGate")
	if gate:
		# スケールを 0.85 に設定（少し小さく）
		gate.scale = Vector3(0.85, 0.85, 0.85)
		print("Scaled 'ShoppingStreetGate' to 0.85")
		
		# シーンを保存
		var packed = PackedScene.new()
		packed.pack(root)
		ResourceSaver.save(packed, scene_path)
		print("Main scene updated successfully.")
	else:
		print("Error: ShoppingStreetGate not found in Main scene.")
		
	quit()
