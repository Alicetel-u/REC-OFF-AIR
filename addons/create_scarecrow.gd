extends SceneTree

# ============================================================
# 案山子（かかし）生成スクリプト v7
# 棒 + わら + 和服（着物）— 3Dしわ・たるみ付き
# ============================================================

func _init():
	var scene = load("res://assets/models/environment/MountainsAndFields.tscn")
	var instance = scene.instantiate()

	for node_name in ["ScarecrowGrp", "ScarecrowGrp2"]:
		var old = instance.get_node_or_null(node_name)
		if old:
			instance.remove_child(old)
			old.free()

	var mats = _create_materials()

	# 案山子1（道路の向かい側の田んぼ）
	var sg1 = Node3D.new()
	sg1.name = "ScarecrowGrp"
	sg1.position = Vector3(8, -0.2, 12)
	sg1.rotation_degrees.y = 180  # 道路側（-Z方向）を向く
	instance.add_child(sg1)
	sg1.owner = instance
	_build_scarecrow(sg1, instance, mats)

	# 案山子2は削除（ユーザー指定により一体のみに）

	var packed = PackedScene.new()
	packed.pack(instance)
	ResourceSaver.save(packed, "res://assets/models/environment/MountainsAndFields.tscn")
	print("v8: 案山子を一体のみ（バス停付近）に修正し、下半身の円形藁を削除しました。")
	quit()


# ==============================================================
# マテリアル
# ==============================================================
func _create_materials() -> Dictionary:
	var mat_wood = StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.28, 0.18, 0.09)
	mat_wood.roughness = 0.95

	var mat_straw = StandardMaterial3D.new()
	mat_straw.albedo_color = Color(0.72, 0.58, 0.28)
	mat_straw.roughness = 0.92

	var mat_rope = StandardMaterial3D.new()
	mat_rope.albedo_color = Color(0.4, 0.28, 0.12)
	mat_rope.roughness = 0.9

	# 着物（藍色）— 両面描画で中身が透けない
	var mat_kimono = StandardMaterial3D.new()
	mat_kimono.albedo_color = Color(0.22, 0.28, 0.42)
	mat_kimono.roughness = 0.88
	mat_kimono.cull_mode = BaseMaterial3D.CULL_DISABLED

	# 帯（暗い茶色）
	var mat_obi = StandardMaterial3D.new()
	mat_obi.albedo_color = Color(0.35, 0.22, 0.10)
	mat_obi.roughness = 0.85

	# 襟（白っぽい）— 両面描画
	var mat_collar = StandardMaterial3D.new()
	mat_collar.albedo_color = Color(0.82, 0.78, 0.72)
	mat_collar.roughness = 0.8
	mat_collar.cull_mode = BaseMaterial3D.CULL_DISABLED

	# 顔
	var mat_face = StandardMaterial3D.new()
	mat_face.albedo_color = Color(0.92, 0.88, 0.82)
	mat_face.roughness = 0.8

	var mat_black = StandardMaterial3D.new()
	mat_black.albedo_color = Color(0.03, 0.03, 0.03)
	mat_black.roughness = 0.9

	var mat_hat = StandardMaterial3D.new()
	mat_hat.albedo_color = Color(0.72, 0.62, 0.38)
	mat_hat.roughness = 0.92

	var mat_hair = StandardMaterial3D.new()
	mat_hair.albedo_color = Color(0.08, 0.06, 0.04)
	mat_hair.roughness = 0.9

	return {
		"wood": mat_wood, "straw": mat_straw, "rope": mat_rope,
		"kimono": mat_kimono, "obi": mat_obi, "collar": mat_collar,
		"face": mat_face, "black": mat_black, "hat": mat_hat, "hair": mat_hair,
	}


# ==============================================================
# 案山子の組み立て
# ==============================================================
func _build_scarecrow(parent: Node3D, owner_node: Node, mats: Dictionary):
	# 1. 縦棒（服の中は見えないので上下に分割）
	# 下部分（地面～着物の裾）
	var pole_bottom = CSGCylinder3D.new()
	pole_bottom.name = "PoleBottom"
	pole_bottom.radius = 0.018; pole_bottom.height = 0.50; pole_bottom.sides = 8
	pole_bottom.position = Vector3(0, 0.25, 0)
	pole_bottom.material = mats["wood"]
	_add(pole_bottom, parent, owner_node)

	# 上部分（着物の肩～頭の上）
	var pole_top = CSGCylinder3D.new()
	pole_top.name = "PoleTop"
	pole_top.radius = 0.018; pole_top.height = 0.75; pole_top.sides = 8
	pole_top.position = Vector3(0, 1.85, 0)
	pole_top.material = mats["wood"]
	_add(pole_top, parent, owner_node)

	# 2. 横棒
	var arm_bar = CSGCylinder3D.new()
	arm_bar.name = "ArmBar"
	arm_bar.radius = 0.015; arm_bar.height = 1.5; arm_bar.sides = 8  # 細く短くして服の中に収める
	arm_bar.rotation_degrees.z = 90
	arm_bar.position = Vector3(0, 1.45, 0)
	arm_bar.material = mats["wood"]
	_add(arm_bar, parent, owner_node)

	# 3. 体のわら
	_build_body_straw(parent, owner_node, mats)

	# 4. 手のわら
	_build_hand_straw(parent, owner_node, mats, -1)
	_build_hand_straw(parent, owner_node, mats, 1)

	# 5. 首のわら
	_build_neck_straw(parent, owner_node, mats)

	# 6. 和服（着物）— 3Dしわ付き
	_build_kimono(parent, owner_node, mats)

	# 7. 頭・顔・帽子
	_build_head(parent, owner_node, mats)


# ==============================================================
# 体のわら
# ==============================================================
func _build_body_straw(parent: Node3D, owner_node: Node, mats: Dictionary):
	# 円形の藁束が服から突き出るため、下半身の藁パーツ（StrawSkirt）を削除
	pass


# ==============================================================
# 手のわら
# ==============================================================
func _build_hand_straw(parent: Node3D, owner_node: Node, mats: Dictionary, side: int):
	var s = float(side)
	var wrist_x = s * 0.78
	for i in range(8):
		var t = float(i) / 7.0
		var vert_angle = lerpf(-35.0, 35.0, t)
		var horiz_angle = sin(t * PI * 2.3) * 20.0
		var strand = CSGCylinder3D.new()
		strand.name = "HandStraw_%s_%d" % ["L" if side == -1 else "R", i]
		strand.radius = 0.006
		strand.height = lerpf(0.15, 0.28, abs(sin(t * PI * 1.5)))
		strand.cone = true; strand.sides = 5
		strand.position = Vector3(wrist_x + s * strand.height * 0.4, 1.45, 0)
		strand.rotation_degrees = Vector3(horiz_angle, 0, -s * 80.0 + vert_angle)
		strand.material = mats["straw"]
		_add(strand, parent, owner_node)


# ==============================================================
# 首のわら
# ==============================================================
func _build_neck_straw(parent: Node3D, owner_node: Node, mats: Dictionary):
	for i in range(10):
		var angle = deg_to_rad(i * 36.0)
		var strand = CSGCylinder3D.new()
		strand.name = "NeckStraw_%d" % i
		strand.radius = 0.005; strand.height = 0.08
		strand.cone = true; strand.sides = 5
		strand.position = Vector3(cos(angle)*0.06, 1.55, sin(angle)*0.06)
		strand.rotation_degrees = Vector3(sin(angle)*25, 0, -cos(angle)*25)
		strand.material = mats["straw"]
		_add(strand, parent, owner_node)


# ==============================================================
# 頭・顔・帽子
# ==============================================================
func _build_head(parent: Node3D, owner_node: Node, mats: Dictionary):
	var head = CSGSphere3D.new()
	head.name = "Head"; head.radius = 0.17
	head.position = Vector3(0, 1.75, 0.02)
	head.material = mats["face"]
	_add(head, parent, owner_node)

	var hair = CSGSphere3D.new()
	hair.name = "HairBack"; hair.radius = 0.175
	hair.position = Vector3(0, 1.75, -0.02)
	hair.material = mats["hair"]
	_add(hair, parent, owner_node)

	# 菅笠
	var hat = CSGCylinder3D.new()
	hat.name = "SugeGasa"
	hat.radius = 0.4; hat.height = 0.3
	hat.cone = true; hat.sides = 24
	hat.position = Vector3(0, 1.95, 0.02)
	hat.material = mats["hat"]
	_add(hat, parent, owner_node)

	var brim = CSGCylinder3D.new()
	brim.name = "HatBrim"
	brim.radius = 0.42; brim.height = 0.02; brim.sides = 24
	brim.position = Vector3(0, 1.81, 0.02)
	brim.material = mats["hat"]
	_add(brim, parent, owner_node)

	# 顔パーツ
	var fz = 0.2
	for d in [{"n":"BrowL","p":Vector3(-0.05,1.79,fz),"r":28.0},
			  {"n":"BrowR","p":Vector3(0.05,1.79,fz),"r":-28.0}]:
		var b = CSGBox3D.new()
		b.name = d["n"]; b.size = Vector3(0.07,0.022,0.006)
		b.position = d["p"]; b.rotation_degrees.z = d["r"]
		b.material = mats["black"]; _add(b, parent, owner_node)

	for d in [{"n":"EyeL","p":Vector3(-0.05,1.74,fz)},
			  {"n":"EyeR","p":Vector3(0.05,1.74,fz)}]:
		var e = CSGBox3D.new()
		e.name = d["n"]; e.size = Vector3(0.03,0.025,0.006)
		e.position = d["p"]; e.material = mats["black"]
		_add(e, parent, owner_node)

	var mouth = CSGBox3D.new()
	mouth.name = "Mouth"; mouth.size = Vector3(0.05,0.014,0.006)
	mouth.position = Vector3(0, 1.68, fz)
	mouth.material = mats["black"]
	_add(mouth, parent, owner_node)


# ==============================================================
# 和服（着物）— SurfaceToolでしわ・たるみを3D生成
# ==============================================================
func _build_kimono(parent: Node3D, owner_node: Node, mats: Dictionary):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# ※ Z軸: 正=前面（顔側）, 負=背面

	# === 背面パネル（大きめで中身を覆う）===
	_add_cloth_panel(st,
		Vector3(-0.19, 0.50, -0.15),
		Vector3(0.19, 0.50, -0.15),
		Vector3(0.19, 1.47, -0.15),
		Vector3(-0.19, 1.47, -0.15),
		10, 16, 0.008, 0.02)

	# === 前面左パネル ===
	_add_cloth_panel(st,
		Vector3(-0.19, 0.50, 0.15),
		Vector3(-0.01, 0.50, 0.15),
		Vector3(-0.01, 1.47, 0.15),
		Vector3(-0.19, 1.47, 0.15),
		6, 16, 0.008, 0.015)

	# === 前面右パネル ===
	_add_cloth_panel(st,
		Vector3(0.01, 0.50, 0.15),
		Vector3(0.19, 0.50, 0.15),
		Vector3(0.19, 1.47, 0.15),
		Vector3(0.01, 1.47, 0.15),
		6, 16, 0.008, 0.015)

	# === 左側面パネル ===
	_add_cloth_panel(st,
		Vector3(-0.19, 0.50, -0.15),
		Vector3(-0.19, 0.50, 0.15),
		Vector3(-0.19, 1.47, 0.15),
		Vector3(-0.19, 1.47, -0.15),
		6, 16, 0.006, 0.01)

	# === 右側面パネル ===
	_add_cloth_panel(st,
		Vector3(0.19, 0.50, 0.15),
		Vector3(0.19, 0.50, -0.15),
		Vector3(0.19, 1.47, -0.15),
		Vector3(0.19, 1.47, 0.15),
		6, 16, 0.006, 0.01)

	# === 上面（肩）パネル — 上から中身が見えない ===
	_add_cloth_panel(st,
		Vector3(-0.19, 1.47, -0.15),
		Vector3(0.19, 1.47, -0.15),
		Vector3(0.19, 1.47, 0.15),
		Vector3(-0.19, 1.47, 0.15),
		6, 4, 0.003, 0.0)

	# === V字の前合わせ（隙間を閉じる斜めパネル）===
	_add_cloth_panel(st,
		Vector3(-0.01, 0.95, 0.155),
		Vector3(-0.08, 0.95, 0.155),
		Vector3(-0.08, 1.47, 0.155),
		Vector3(-0.01, 1.47, 0.155),
		3, 8, 0.003, 0.0)
	_add_cloth_panel(st,
		Vector3(0.08, 0.95, 0.155),
		Vector3(0.01, 0.95, 0.155),
		Vector3(0.01, 1.47, 0.155),
		Vector3(0.08, 1.47, 0.155),
		3, 8, 0.003, 0.0)

	st.generate_normals()
	var mi = MeshInstance3D.new()
	mi.name = "KimonoBody"
	mi.mesh = st.commit()
	mi.material_override = mats["kimono"]
	_add(mi, parent, owner_node)

	# === 衿（白い布）===
	var collar_st = SurfaceTool.new()
	collar_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_cloth_panel(collar_st,
		Vector3(-0.02, 1.0, 0.16),
		Vector3(-0.08, 1.0, 0.16),
		Vector3(-0.08, 1.50, 0.16),
		Vector3(-0.02, 1.50, 0.16),
		3, 8, 0.002, 0.0)
	_add_cloth_panel(collar_st,
		Vector3(0.08, 1.0, 0.16),
		Vector3(0.02, 1.0, 0.16),
		Vector3(0.02, 1.50, 0.16),
		Vector3(0.08, 1.50, 0.16),
		3, 8, 0.002, 0.0)
	collar_st.generate_normals()
	var collar_mi = MeshInstance3D.new()
	collar_mi.name = "KimonoCollar"
	collar_mi.mesh = collar_st.commit()
	collar_mi.material_override = mats["collar"]
	_add(collar_mi, parent, owner_node)

	# === 袖（左右）===
	_build_kimono_sleeve(parent, owner_node, mats, -1)
	_build_kimono_sleeve(parent, owner_node, mats, 1)

	# === 帯（大きめで隙間なし）===
	var obi = CSGCylinder3D.new()
	obi.name = "Obi"
	obi.radius = 0.21; obi.height = 0.08; obi.sides = 16
	obi.position = Vector3(0, 1.0, 0)
	obi.material = mats["obi"]
	_add(obi, parent, owner_node)

	# 帯の結び目（背中側 = 負Z）
	var knot = CSGBox3D.new()
	knot.name = "ObiKnot"
	knot.size = Vector3(0.1, 0.12, 0.06)
	knot.position = Vector3(0, 1.0, -0.24)
	knot.material = mats["obi"]
	_add(knot, parent, owner_node)


# ==============================================================
# 着物の袖 — 棒に掛かって垂れ下がる布
# ==============================================================
func _build_kimono_sleeve(parent: Node3D, owner_node: Node, mats: Dictionary, side: int):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var s = float(side)
	var x_inner = s * 0.17   # 体との接合点
	var x_outer = s * 0.75   # 袖の先端

	var y_top = 1.47    # 横棒の上
	var y_bar = 1.43    # 横棒の高さ
	var y_bottom = 1.15 # 袖の下端（垂れ下がり）

	var z_front = 0.12
	var z_back = -0.12

	# 上面パネル（横棒の上に乗る布）
	_add_cloth_panel(st,
		Vector3(x_inner, y_top, z_back),
		Vector3(x_outer, y_top, z_back),
		Vector3(x_outer, y_top, z_front),
		Vector3(x_inner, y_top, z_front),
		10, 4, 0.005, 0.01)

	# 前面パネル（前側に垂れ下がる布）
	_add_cloth_panel(st,
		Vector3(x_inner, y_bottom, z_front),
		Vector3(x_outer, y_bottom - 0.05, z_front),
		Vector3(x_outer, y_top, z_front),
		Vector3(x_inner, y_top, z_front),
		10, 8, 0.01, 0.025)

	# 背面パネル（後ろ側に垂れ下がる布）
	_add_cloth_panel(st,
		Vector3(x_outer, y_bottom - 0.05, z_back),
		Vector3(x_inner, y_bottom, z_back),
		Vector3(x_inner, y_top, z_back),
		Vector3(x_outer, y_top, z_back),
		10, 8, 0.01, 0.025)

	# 底面パネル（袖の下端、垂れた布の底）
	_add_cloth_panel(st,
		Vector3(x_inner, y_bottom, z_back),
		Vector3(x_outer, y_bottom - 0.05, z_back),
		Vector3(x_outer, y_bottom - 0.05, z_front),
		Vector3(x_inner, y_bottom, z_front),
		10, 4, 0.008, 0.02)

	st.generate_normals()
	var mi = MeshInstance3D.new()
	mi.name = "KimonoSleeve" + ("L" if side == -1 else "R")
	mi.mesh = st.commit()
	mi.material_override = mats["kimono"]
	_add(mi, parent, owner_node)


# ==============================================================
# 布パネル生成 — しわ・たるみ付きの分割四角形
# p00=左下, p10=右下, p11=右上, p01=左上
# ==============================================================
func _add_cloth_panel(st: SurfaceTool,
	p00: Vector3, p10: Vector3, p11: Vector3, p01: Vector3,
	seg_u: int, seg_v: int, wrinkle_str: float, sag_str: float):

	# パネルの法線方向を計算（しわ変位の方向）
	var edge1 = p10 - p00
	var edge2 = p01 - p00
	var normal = edge1.cross(edge2).normalized()

	var grid = []
	var uv_grid = []

	for iv in range(seg_v + 1):
		var row = []
		var uv_row = []
		var v = float(iv) / seg_v

		for iu in range(seg_u + 1):
			var u = float(iu) / seg_u

			# 双線形補間で基本位置を計算
			var pos = p00 * (1.0-u) * (1.0-v) + p10 * u * (1.0-v) + p11 * u * v + p01 * (1.0-u) * v

			# === しわ変位（法線方向に凹凸を付ける）===
			# 大きなしわ（縦方向の波）
			var wrinkle = sin(u * 8.0 + v * 2.0) * wrinkle_str
			# 中くらいのしわ（横方向の波）
			wrinkle += sin(v * 12.0 + u * 3.0) * wrinkle_str * 0.6
			# 細かいしわ（ノイズ的）
			wrinkle += sin(u * 20.0 + v * 15.0) * wrinkle_str * 0.3
			# 帯付近（v=0.5あたり）でしわが多い
			var obi_wrinkle = exp(-pow((v - 0.5) * 4.0, 2.0)) * wrinkle_str * 1.5
			wrinkle += sin(u * 15.0) * obi_wrinkle

			pos += normal * wrinkle

			# === 重力たるみ（中央が下がる）===
			if sag_str > 0.001:
				var sag = sin(u * PI) * sag_str * (1.0 - v)  # 下ほどたるむ
				pos.y -= sag

			row.append(pos)
			uv_row.append(Vector2(u, v))

		grid.append(row)
		uv_grid.append(uv_row)

	# 三角形生成
	for iv in range(seg_v):
		for iu in range(seg_u):
			_add_quad(st,
				grid[iv][iu], grid[iv+1][iu], grid[iv+1][iu+1], grid[iv][iu+1],
				uv_grid[iv][iu], uv_grid[iv+1][iu], uv_grid[iv+1][iu+1], uv_grid[iv][iu+1])


# ==============================================================
# ユーティリティ
# ==============================================================
func _add(node: Node, parent: Node, owner_node: Node):
	parent.add_child(node)
	node.owner = owner_node

func _add_quad(st: SurfaceTool,
	v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3,
	uv0: Vector2, uv1: Vector2, uv2: Vector2, uv3: Vector2):
	st.set_uv(uv0); st.add_vertex(v0)
	st.set_uv(uv1); st.add_vertex(v1)
	st.set_uv(uv2); st.add_vertex(v2)
	st.set_uv(uv0); st.add_vertex(v0)
	st.set_uv(uv2); st.add_vertex(v2)
	st.set_uv(uv3); st.add_vertex(v3)
