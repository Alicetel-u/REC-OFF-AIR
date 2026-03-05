extends SceneTree

func _init():
	var root = Node3D.new()
	root.name = "ToiletWalls"
	
	# 新しく生成した汚れたタイルのテクスチャ
	var tile_img = Image.load_from_file("res://assets/textures/dirty_white_tiles.png")
	var tile_tex = ImageTexture.create_from_image(tile_img)
	
	# すべての面に適用するタイルマテリアル
	var tile_mat = StandardMaterial3D.new()
	tile_mat.albedo_texture = tile_tex
	tile_mat.uv1_triplanar = true
	tile_mat.uv1_scale = Vector3(0.5, 0.5, 0.5)
	tile_mat.roughness = 0.5
	
	# 建物構造 (CSG)
	var building = CSGCombiner3D.new()
	building.name = "Building"
	building.use_collision = true
	root.add_child(building)
	building.set_owner(root)
	
	# 外側の箱 (高さ 4m)
	var outer = CSGBox3D.new()
	outer.size = Vector3(6, 4, 8)
	outer.transform.origin = Vector3(0, 2.0, 0)
	outer.material = tile_mat
	building.add_child(outer)
	outer.set_owner(root)
	
	# 内側のくり抜き (高さ 3.8m)
	var inner = CSGBox3D.new()
	inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	inner.size = Vector3(5.6, 3.8, 7.6)
	inner.transform.origin = Vector3(0, 2.0, 0)
	inner.material = tile_mat
	building.add_child(inner)
	inner.set_owner(root)
	
	# 床と天井
	var floor_obj = CSGBox3D.new()
	floor_obj.size = Vector3(5.6, 0.1, 7.6)
	floor_obj.transform.origin = Vector3(0, 0.05, 0)
	floor_obj.material = tile_mat
	root.add_child(floor_obj)
	floor_obj.set_owner(root)
	
	var ceiling_obj = CSGBox3D.new()
	ceiling_obj.size = Vector3(5.6, 0.1, 7.6)
	ceiling_obj.transform.origin = Vector3(0, 3.85, 0)
	ceiling_obj.material = tile_mat
	root.add_child(ceiling_obj)
	ceiling_obj.set_owner(root)
	
	# 入口 (高さを 2.8m に拡大)
	var entrance = CSGBox3D.new()
	entrance.operation = CSGShape3D.OPERATION_SUBTRACTION
	entrance.size = Vector3(1.5, 2.8, 1.2)
	entrance.transform.origin = Vector3(-1.5, 1.4, -4.0)
	building.add_child(entrance)
	entrance.set_owner(root)

	# 個室用の素材 (シンプルで古びた白い壁)
	var stall_img = Image.load_from_file("res://assets/textures/simple_old_white_wall.png")
	var stall_tex = ImageTexture.create_from_image(stall_img)
	
	var stall_mat = StandardMaterial3D.new()
	stall_mat.albedo_texture = stall_tex
	stall_mat.uv1_triplanar = true
	stall_mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
	stall_mat.roughness = 0.9
	
	var stalls = Node3D.new()
	stalls.name = "Stalls"
	root.add_child(stalls)
	stalls.set_owner(root)
	
	for i in range(3):
		var z_pos = -2.0 + (i * 2.2)
		
		var divider = CSGBox3D.new()
		divider.name = "Divider_" + str(i)
		divider.size = Vector3(2.5, 3.0, 0.05)
		divider.transform.origin = Vector3(1.5, 1.5, z_pos)
		divider.material = stall_mat
		stalls.add_child(divider)
		divider.set_owner(root)
		
		var front_fixed = CSGBox3D.new()
		front_fixed.name = "FrontFixed_" + str(i)
		front_fixed.size = Vector3(0.1, 3.0, 1.0)
		front_fixed.transform.origin = Vector3(0.25, 1.5, z_pos + 0.6)
		front_fixed.material = stall_mat
		stalls.add_child(front_fixed)
		front_fixed.set_owner(root)
		
		var door = CSGBox3D.new()
		door.name = "Door_" + str(i)
		var d_width = 1.3
		if i == 0: d_width = 1.5
		door.size = Vector3(0.05, 2.8, d_width)
		
		if i == 1:
			door.transform.origin = Vector3(0.4, 1.4, z_pos - 0.5)
			door.rotation_degrees.y = 8
		else:
			door.transform.origin = Vector3(0.25, 1.4, z_pos - (d_width / 2.0))
		
		door.material = stall_mat
		stalls.add_child(door)
		door.set_owner(root)
		
		# --- ドアノブ（Doorknob Model）の配置 ---
		var knob_scene = load("res://shaders/素材/トイレドアノブl.glb")
		if knob_scene:
			# 外側
			var knob_out = knob_scene.instantiate()
			knob_out.name = "KnobOut_" + str(i)
			# スケールを0.2に設定
			knob_out.scale = Vector3(0.2, 0.2, 0.2)
			# 扉の面に配置、高さ修正、扉の端
			knob_out.transform.origin = Vector3(0.12, -0.03, d_width / 2.0 - 0.15)
			knob_out.rotation_degrees.y = 0
			door.add_child(knob_out)
			knob_out.set_owner(root)
			
			# 内側
			var knob_in = knob_scene.instantiate()
			knob_in.name = "KnobIn_" + str(i)
			knob_in.scale = Vector3(0.2, 0.2, 0.2)
			knob_in.transform.origin = Vector3(-0.12, -0.03, d_width / 2.0 - 0.15)
			knob_in.rotation_degrees.y = 180
			door.add_child(knob_in)
			knob_in.set_owner(root)
		
		# --- 便器（Toilet Model）の配置 ---
		var toilet_scene = load("res://shaders/素材/便器.glb")
		if toilet_scene:
			var toilet = toilet_scene.instantiate()
			toilet.name = "Toilet_" + str(i)
			# 手動調整後の高さと位置
			toilet.transform.origin = Vector3(1.5, 0.11, z_pos - 1.1)
			# 手動調整後の向き（90度回転）
			toilet.rotation_degrees.y = -90 
			stalls.add_child(toilet)
			toilet.set_owner(root)

			# --- トイレレバー（Flush Lever Model）の配置 ---
			var lever_scene = load("res://shaders/素材/トイレレバー.glb")
			if lever_scene:
				var lever = lever_scene.instantiate()
				lever.name = "Lever_" + str(i)
				lever.transform.origin = Vector3(2.4, 0.8, z_pos - 1.1)
				# 45度の補正を維持
				lever.rotation_degrees = Vector3(0, 0, 45)
				stalls.add_child(lever)
				lever.set_owner(root)
		

	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/ToiletWalls.tscn")
	print("ToiletWalls reverted to step 330 state.")
	quit()
