extends SceneTree

func _init():
	var root = Node3D.new()
	root.name = "ViewPhysicalToilet"
	
	# 物理タイルシーンを配置
	var walls_scene = load("res://scenes/PhysicalToilet.tscn")
	var walls = walls_scene.instantiate()
	root.add_child(walls)
	walls.set_owner(root)
	
	# カメラの配置
	var camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.transform.origin = Vector3(0, 1.5, 3) 
	root.add_child(camera)
	camera.set_owner(root)
	
	# マウス操作スクリプト
	var cam_script = load("res://scenes/HandheldCamera.gd")
	if cam_script:
		camera.set_script(cam_script)
	
	# 強力なスポットライト（タイルの凹凸を際立たせるため水平気味に照射）
	var light = SpotLight3D.new()
	light.name = "Flashlight"
	light.light_energy = 8.0
	light.spot_range = 30.0
	light.spot_angle = 40.0
	light.shadow_enabled = true
	camera.add_child(light)
	light.set_owner(root)
	
	# 環境
	var env = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0,0,0)
	root.add_child(env)
	env.set_owner(root)
	
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/ViewPhysicalToilet.tscn")
	print("Test scene for physical tiles ready.")
	quit()
