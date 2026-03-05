extends SceneTree

func _init():
	var root = Node3D.new()
	root.name = "ViewToilet"
	
	# トイレの壁を配置
	var walls_scene = load("res://scenes/ToiletWalls.tscn")
	var walls = walls_scene.instantiate()
	root.add_child(walls)
	walls.set_owner(root)
	
	# カメラの配置
	var camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.transform.origin = Vector3(0, 1.5, 3) # 入り口付近
	root.add_child(camera)
	camera.set_owner(root)
	
	# カメラ用スクリプトの適用（マウス操作用）
	var cam_script = load("res://scenes/HandheldCamera.gd")
	if cam_script:
		camera.set_script(cam_script)
	
	# 懐中電灯（カメラに追従）
	var light = SpotLight3D.new()
	light.name = "Flashlight"
	light.light_energy = 5.0
	light.spot_range = 20.0
	light.spot_angle = 45.0
	light.shadow_enabled = true
	camera.add_child(light) # カメラの子にすることで常に前を照らす
	light.set_owner(root)
	
	# スクリプト内で flashlight_path を設定（HandheldCamera.gd が要求する場合があるため）
	if camera.has_method("set"):
		camera.set("flashlight_path", NodePath("Flashlight"))
	
	# 背景を少し明るくするための環境光
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.1, 0.1, 0.1)
	world_env.environment = env
	root.add_child(world_env)
	world_env.set_owner(root)
	
	# シーンの保存
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/ViewToilet.tscn")
	print("Test scene 'ViewToilet.tscn' has been created.")
	quit()
