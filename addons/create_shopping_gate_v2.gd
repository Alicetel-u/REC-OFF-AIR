extends SceneTree

func _init():
	var root = Node3D.new()
	root.name = "ShoppingStreetGate"
	
	# === マテリアル設定 ===
	var rust_mat = ShaderMaterial.new()
	var heavy_rust = load("res://assets/models/environment/shaders/heavy_rust.gdshader")
	if heavy_rust:
		rust_mat.shader = heavy_rust
		rust_mat.set_shader_parameter("base_paint_color", Color(0.2, 0.05, 0.02))
		rust_mat.set_shader_parameter("rust_color1", Color(0.35, 0.15, 0.05))
		rust_mat.set_shader_parameter("rust_color2", Color(0.15, 0.05, 0.0))
		rust_mat.set_shader_parameter("rust_amount", 0.9) # 全身ほぼサビだらけ
	else:
		rust_mat = StandardMaterial3D.new()
		rust_mat.albedo_color = Color(0.25, 0.1, 0.05)
		rust_mat.metallic = 0.8
		rust_mat.roughness = 0.95
	
	var white_mat = ShaderMaterial.new()
	if heavy_rust:
		white_mat.shader = heavy_rust
		white_mat.set_shader_parameter("base_paint_color", Color(0.65, 0.60, 0.55)) # 汚い白ベース
		white_mat.set_shader_parameter("rust_color1", Color(0.4, 0.15, 0.05))
		white_mat.set_shader_parameter("rust_color2", Color(0.1, 0.05, 0.02))
		white_mat.set_shader_parameter("rust_amount", 0.75) # 白い塗装がボロボロに剥がれた状態
	else:
		white_mat = StandardMaterial3D.new()
		white_mat.albedo_color = Color(0.8, 0.78, 0.75) # 汚れた白
		white_mat.roughness = 1.0
	
	var sign_tex = load("res://assets/models/environment/textures/happy_street_sign.png")
	if not sign_tex:
		var img = Image.new()
		if img.load("res://assets/models/environment/textures/happy_street_sign.png") == OK:
			sign_tex = ImageTexture.create_from_image(img)
	
	var road_mat = ShaderMaterial.new()
	var shader = load("res://assets/models/environment/shaders/dark_asphalt.gdshader")
	if shader:
		road_mat.shader = shader
	else:
		road_mat = StandardMaterial3D.new()
		road_mat.albedo_color = Color(0.12, 0.12, 0.13) # fallback dark color
		road_mat.roughness = 0.95
	
	# === 寸法設定 ===
	var gate_width = 7.0   # ゲートの内側の道幅
	var pillar_radius = 0.18
	var pillar_height = 4.5
	var road_length = 30.0 # 商店街の通りの長さ（とりあえず30m生成）
	
	# === ゲートの構造 ===
	var gate_structure = Node3D.new()
	gate_structure.name = "GateStructure"
	root.add_child(gate_structure)
	gate_structure.owner = root
	
	# 左柱
	var left_pillar = CSGCylinder3D.new()
	left_pillar.name = "LeftPillar"
	left_pillar.radius = pillar_radius
	left_pillar.height = pillar_height
	left_pillar.position = Vector3(-gate_width/2.0, pillar_height/2.0, 0)
	left_pillar.material_override = rust_mat
	gate_structure.add_child(left_pillar)
	left_pillar.owner = root
	
	# 右柱
	var right_pillar = CSGCylinder3D.new()
	right_pillar.name = "RightPillar"
	right_pillar.radius = pillar_radius
	right_pillar.height = pillar_height
	right_pillar.position = Vector3(gate_width/2.0, pillar_height/2.0, 0)
	right_pillar.material_override = rust_mat
	gate_structure.add_child(right_pillar)
	right_pillar.owner = root
	
	# アーチ看板のベース (結合処理で半月状の板を作る)
	var arch_combiner = CSGCombiner3D.new()
	arch_combiner.name = "ArchSign"
	arch_combiner.position = Vector3(0, pillar_height, 0)
	gate_structure.add_child(arch_combiner)
	arch_combiner.owner = root
	
	var outer_arch = CSGCylinder3D.new()
	outer_arch.name = "OuterRing"
	outer_arch.radius = gate_width / 2.0 + 0.5
	outer_arch.height = 0.15 # 看板の厚み
	outer_arch.rotation = Vector3(PI/2, 0, 0) # 真っ直ぐ正面を向くようにZ軸回転
	outer_arch.material_override = white_mat
	arch_combiner.add_child(outer_arch)
	outer_arch.owner = root
	
	var inner_arch = CSGCylinder3D.new()
	inner_arch.name = "InnerRing"
	inner_arch.operation = CSGShape3D.OPERATION_SUBTRACTION
	inner_arch.radius = gate_width / 2.0 - 0.7
	inner_arch.height = 0.3 # くり抜くため少し厚め
	inner_arch.rotation = Vector3(PI/2, 0, 0)
	arch_combiner.add_child(inner_arch)
	inner_arch.owner = root
	
	var bottom_cut = CSGBox3D.new()
	bottom_cut.name = "BottomCut"
	bottom_cut.operation = CSGShape3D.OPERATION_SUBTRACTION
	bottom_cut.size = Vector3(gate_width + 2.0, outer_arch.radius + 1.0, 1.0)
	bottom_cut.position = Vector3(0, -(outer_arch.radius + 1.0)/2.0 + 0.1, 0)
	arch_combiner.add_child(bottom_cut)
	bottom_cut.owner = root
	
	# === 看板画像用のDecal（プロジェクション） ===
	# 物理的な板ではなく、Decalを使ってアーチの表面に直接テクスチャを焼き付けます。
	var decal = Decal.new()
	decal.name = "SignDecal"
	if sign_tex:
		decal.texture_albedo = sign_tex
	
	# =========================================================
	# 【画像の歪みと見切れの修正】
	# === 表面用（大通りから見える手前側）のDecal ===
	decal.size = Vector3(8.5, 0.15, 4.0)
	# プレートの中央（Y=7.9）に文字の中心が来るように調整
	decal.position = Vector3(0, 7.675, 0.075)
	
	# 手前側の面（Z+向き）に正しく投影し、文字が反転せずに読めるようにします
	decal.rotation_degrees = Vector3(90, 0, 0)
	decal.modulate = Color(0.9, 0.9, 0.9)
	decal.albedo_mix = 1.0
	
	gate_structure.add_child(decal)
	decal.owner = root
	
	# === 裏面用（商店街の奥から見える側）のDecal ===
	var decal_back = decal.duplicate()
	decal_back.name = "SignDecalBack"
	# 裏側の表面だけに当たるよう、奥側（Z=-0.075）に配置します
	decal_back.position = Vector3(0, 7.675, -0.075)
	
	# 奥側の面（Z-向き）に投影し、裏側から読んだ時にも文字が反転しないようY軸で180度回転します
	decal_back.rotation_degrees = Vector3(90, 180, 0)
	gate_structure.add_child(decal_back)
	decal_back.owner = root
	
	# 看板下の横梁
	var crossbeam = CSGBox3D.new()
	crossbeam.name = "CrossBeam"
	crossbeam.size = Vector3(gate_width + 0.4, 0.15, 0.15)
	crossbeam.position = Vector3(0, pillar_height + 0.1, 0)
	crossbeam.material_override = rust_mat
	gate_structure.add_child(crossbeam)
	crossbeam.owner = root
	
	# === 商店街の道（コンクリート） ===
	# ゲートから直角に（X方向など）横に伸びるように配置する
	var road = CSGBox3D.new()
	road.name = "ConcreteRoad"
	var final_road_length = 30.0
	road.size = Vector3(gate_width, 0.2, final_road_length) # 大通りと同じ厚さ0.2に合わせる
	# 大通り（Zの中心が4.3でY=-0.1に厚さ0.2。つまり上面はY=0）の道際ギリギリで止める
	road.position = Vector3(0, -0.1, 5.3 - (final_road_length / 2.0))
	road.material_override = road_mat
	root.add_child(road)
	road.owner = root
	
	# シーンの保存
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://assets/models/environment/ShoppingStreetGate.tscn")
	print("Saved to assets/models/environment/ShoppingStreetGate.tscn")
	
	# Main.tscn に再配置
	var main_tscn = load("res://scenes/Main.tscn")
	if main_tscn:
		var main_root = main_tscn.instantiate()
		
		# 既存のゲートを自動削除 (同期的に行い、ゴミが残らないようにする)
		if main_root.has_node("ShoppingStreetGate"):
			var old = main_root.get_node("ShoppingStreetGate")
			main_root.remove_child(old)
			old.free()
			
		var loaded_scene = load("res://assets/models/environment/ShoppingStreetGate.tscn")
		var gate_instance = loaded_scene.instantiate()
		gate_instance.name = "ShoppingStreetGate"
		
		# 位置と回転の適用
		# 大通り（Z方向=4.3 をX軸正に伸びている）に対して「横に伸びる道」。
		# そのため、Z奥の座標(例: Z=-6)にゲートを置き、大通りの道（横側）からそれるように作る。
		gate_instance.position = Vector3(38, 0, -4.0) 
		gate_instance.rotation_degrees = Vector3(0, 0, 0)
		gate_instance.scale = Vector3(0.85, 0.85, 0.85) # スケールを0.85に調整
		
		main_root.add_child(gate_instance)
		
		# インスタンスとして保存するための正しい `owner` の設定
		gate_instance.owner = main_root
		
		var packed_main = PackedScene.new()
		packed_main.pack(main_root)
		ResourceSaver.save(packed_main, "res://scenes/Main.tscn")
		print("ShoppingStreetGate instance moved to (38, 0, -4.0) with concrete road.")
		
	quit()
