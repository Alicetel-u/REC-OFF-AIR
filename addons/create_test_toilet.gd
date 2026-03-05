extends SceneTree

func _init():
	var root = Node3D.new()
	root.name = "TestPublicToilet"

	# トイレマップの読み込み
	var toilet_scene = load("res://assets/models/public_toilet/PublicToilet.tscn")
	var toilet = toilet_scene.instantiate()
	root.add_child(toilet)
	toilet.owner = root

	# プレイヤーの代わりとなるカメラ
	var camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 1.5, 4.0) # トイレの入り口付近
	camera.rotation_degrees.y = 180 # 奥を向く
	
	# HandheldCamera.gd（手持ちカメラ＆歩行スクリプト）をアタッチ
	var cam_script = load("res://scenes/HandheldCamera.gd")
	if cam_script:
		camera.set_script(cam_script)
		
	root.add_child(camera)
	camera.owner = root

	# 懐中電灯（カメラ用）
	var flashlight = SpotLight3D.new()
	flashlight.name = "Flashlight"
	flashlight.position = Vector3(0, 1.5, 4.0)
	flashlight.light_energy = 5.0
	flashlight.spot_range = 15.0
	flashlight.spot_angle = 50.0
	flashlight.shadow_enabled = true
	root.add_child(flashlight)
	flashlight.owner = root

	# スクリプトに懐中電灯を登録
	if cam_script:
		camera.set("flashlight_path", NodePath("../Flashlight"))

	# UI (VHSノイズ用) の追加
	var ui_scene = load("res://scenes/StreamUI.tscn")
	if ui_scene:
		var ui = ui_scene.instantiate()
		root.add_child(ui)
		ui.owner = root

	var scene_path = "res://scenes/TestPublicToilet.tscn"
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, scene_path)
	
	print("Test scene created at: ", scene_path)
	quit()
