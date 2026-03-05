extends SceneTree

func _init():
	var root = Node3D.new()
	root.name = "PublicToilet"

	# シェーダーマテリアルのロードと設定
	var shader = load("res://assets/models/public_toilet/shaders/dirty_tile.gdshader")
	if not shader:
		printerr("Failed to load dirty_tile.gdshader")
		quit()
		return

	var wall_mat = ShaderMaterial.new()
	wall_mat.shader = shader
	wall_mat.set_shader_parameter("base_color", Color(0.85, 0.9, 0.85)) # くすんだ白緑
	wall_mat.set_shader_parameter("dirt_color", Color(0.2, 0.3, 0.1))   # 苔汚れっぽく
	wall_mat.set_shader_parameter("tile_size", 10.0)

	var floor_mat = ShaderMaterial.new()
	floor_mat.shader = shader
	floor_mat.set_shader_parameter("base_color", Color(0.6, 0.6, 0.6))
	floor_mat.set_shader_parameter("dirt_color", Color(0.1, 0.05, 0.0)) # 黒ずんだ泥
	floor_mat.set_shader_parameter("tile_size", 5.0)

	# --- 建物本体 (CSGCombiner) ---
	var building = CSGCombiner3D.new()
	building.name = "Building"
	building.use_collision = true
	root.add_child(building)
	building.owner = root

	# 外枠 ( 6m x 3m x 8m )
	var outer_box = CSGBox3D.new()
	outer_box.size = Vector3(6, 3, 8)
	outer_box.position = Vector3(0, 1.5, 0)
	outer_box.material = wall_mat
	building.add_child(outer_box)
	outer_box.owner = root

	# くり抜き ( 5.6m x 2.8m x 7.6m )
	var inner_box = CSGBox3D.new()
	inner_box.operation = CSGShape3D.OPERATION_SUBTRACTION
	inner_box.size = Vector3(5.6, 2.8, 7.6)
	inner_box.position = Vector3(0, 1.5, 0)
	inner_box.material = wall_mat
	building.add_child(inner_box)
	inner_box.owner = root

	# 入り口のくり抜き
	var entrance_hole = CSGBox3D.new()
	entrance_hole.operation = CSGShape3D.OPERATION_SUBTRACTION
	entrance_hole.size = Vector3(2.0, 2.2, 1.0)
	entrance_hole.position = Vector3(0, 1.1, 4.0)
	building.add_child(entrance_hole)
	entrance_hole.owner = root

	# --- 内装 (床と仕切り) ---
	var floor = CSGBox3D.new()
	floor.name = "Floor"
	floor.size = Vector3(5.6, 0.1, 7.6)
	floor.position = Vector3(0, 0.05, 0)
	floor.material = floor_mat
	floor.use_collision = true
	root.add_child(floor)
	floor.owner = root

	# 個室の仕切り壁を作成するループ
	var stalls_root = Node3D.new()
	stalls_root.name = "Stalls"
	root.add_child(stalls_root)
	stalls_root.owner = root

	var num_stalls = 4 # 手前から4つの個室（奥から2つ目は3番目）
	for i in range(num_stalls):
		var z_pos = -3.0 + (i * 1.5) # 奥から手前へ配置
		
		# 横壁
		var div = CSGBox3D.new()
		div.name = "Divider_" + str(i)
		div.size = Vector3(2.5, 2.2, 0.1)
		div.position = Vector3(1.5, 1.1, z_pos)
		div.material = wall_mat
		div.use_collision = true
		stalls_root.add_child(div)
		div.owner = root

		# 前壁（ドアの枠）
		var front_wall = CSGBox3D.new()
		front_wall.name = "FrontWall_" + str(i)
		front_wall.size = Vector3(0.5, 2.2, 1.5)
		front_wall.position = Vector3(0.25, 1.1, z_pos + 0.75)
		front_wall.material = wall_mat
		front_wall.use_collision = true
		stalls_root.add_child(front_wall)
		front_wall.owner = root

		# 【怪異ポイント】ここに後でドアのアニメーションやギミックを入れます
		var door = CSGBox3D.new()
		if i == 1: # 【奥から2番目】(ループ順は奥(0)から手前なので index 1)
			door.name = "IncidentDoor_Target" 
			# 少し隙間を開けてみる（不気味演出）
			door.rotation_degrees.y = 15
		else:
			door.name = "Door_" + str(i)
			
		door.size = Vector3(0.05, 2.0, 0.9)
		door.position = Vector3(0.25, 1.0, z_pos + 0.75) # ドアの基本位置
		var door_mat = StandardMaterial3D.new()
		door_mat.albedo_color = Color(0.4, 0.4, 0.4) # サビた金属っぽい色
		door_mat.roughness = 0.8
		door.material = door_mat
		door.use_collision = true
		stalls_root.add_child(door)
		door.owner = root

	# --- ライティング ---
	var lights = Node3D.new()
	lights.name = "Lights"
	root.add_child(lights)
	lights.owner = root

	# 薄暗いチカチカする蛍光灯
	var main_light = OmniLight3D.new()
	main_light.name = "FlickeringFluorescent"
	main_light.position = Vector3(0, 2.6, 0)
	main_light.light_color = Color(0.6, 0.9, 0.8) # 青白い不健康な光
	main_light.light_energy = 0.3
	main_light.shadow_enabled = true
	main_light.omni_range = 8.0
	lights.add_child(main_light)
	main_light.owner = root

	# さらに奥を不気味にする赤寄りの暗いライト（血の匂いを無意識に感じさせる）
	var back_light = OmniLight3D.new()
	back_light.name = "BackDarkLight"
	back_light.position = Vector3(1.5, 0.5, -3.0)
	back_light.light_color = Color(0.2, 0.05, 0.05)
	back_light.light_energy = 0.1
	back_light.shadow_enabled = true
	back_light.omni_range = 3.0
	lights.add_child(back_light)
	back_light.owner = root

	# --- 手洗い場 ---
	var sink_area = CSGBox3D.new()
	sink_area.name = "SinkArea"
	sink_area.size = Vector3(2.0, 0.8, 0.6)
	sink_area.position = Vector3(-1.8, 0.4, 2.0)
	sink_area.material = floor_mat
	sink_area.use_collision = true
	root.add_child(sink_area)
	sink_area.owner = root

	# 鏡
	var mirror = CSGBox3D.new()
	mirror.name = "Mirror"
	mirror.size = Vector3(1.8, 1.0, 0.05)
	mirror.position = Vector3(-2.75, 1.5, 2.0)
	var mirror_mat = StandardMaterial3D.new()
	mirror_mat.albedo_color = Color(0.1, 0.1, 0.1)
	mirror_mat.metallic = 1.0
	mirror_mat.roughness = 0.2
	mirror.material = mirror_mat
	root.add_child(mirror)
	mirror.owner = root

	# シーンの保存
	var scene_path = "res://assets/models/public_toilet/PublicToilet.tscn"
	var packed = PackedScene.new()
	packed.pack(root)
	var err = ResourceSaver.save(packed, scene_path)
	
	if err == OK:
		print("Successfully generated PublicToilet.tscn at: ", scene_path)
	else:
		printerr("Failed to save scene. Error code: ", err)
		
	quit()
