@tool
extends Node3D

## 廃村入口マップ（仮実装）
## 構成: バス停 → 砂利道 → 畑 → 村の門（看板付き）
## CSGBox3D のマテリアル問題を回避するため MeshInstance3D + StaticBody3D で実装

func _ready() -> void:
	for c in get_children(): c.queue_free()
	_build_ground()
	_build_road()
	_build_fields()
	_build_bus_stop()
	_build_gate()
	_build_shopping_gate()
	_build_atmosphere()
	# エディター上で全ノードを選択・移動できるようにする
	if Engine.is_editor_hint():
		_set_editor_owner(self)

func _set_editor_owner(node: Node) -> void:
	for child in node.get_children():
		child.owner = get_tree().edited_scene_root
		_set_editor_owner(child)


# ── ヘルパー（StageHelper に委譲） ────────────────────────
func _deco(pos: Vector3, size: Vector3, col: Color) -> void:
	StageHelper.deco(self, pos, size, col)

func _box(pos: Vector3, size: Vector3, col: Color) -> void:
	StageHelper.box(self, pos, size, col)


# ── 地面 ─────────────────────────────────────────────────────────
func _build_ground() -> void:
	_box(Vector3(0, -0.5, 0), Vector3(200, 1.0, 200), Color(0.18, 0.38, 0.12))


# ── 砂利道 ───────────────────────────────────────────────────────
func _build_road() -> void:
	# Z=19 から Z=-33 まで（村門・商店街ゲートを通過する長さ）
	_box(Vector3(0, 0.01, -7), Vector3(4.5, 0.05, 52), Color(0.55, 0.52, 0.46))
	_box(Vector3(-2.6, 0.03, -7), Vector3(0.3, 0.04, 52), Color(0.40, 0.38, 0.34))
	_box(Vector3( 2.6, 0.03, -7), Vector3(0.3, 0.04, 52), Color(0.40, 0.38, 0.34))


# ── 畑 ───────────────────────────────────────────────────────────
func _build_fields() -> void:
	_box(Vector3(-12, 0.05, -1), Vector3(16, 0.10, 24), Color(0.22, 0.48, 0.14))
	_box(Vector3( 12, 0.05, -1), Vector3(16, 0.10, 24), Color(0.22, 0.48, 0.14))

	for i in range(6):
		_box(Vector3(-12, 0.16, 10.0 - i * 4.0), Vector3(14.0, 0.10, 0.45), Color(0.28, 0.58, 0.18))
	for i in range(6):
		_box(Vector3( 12, 0.16, 10.0 - i * 4.0), Vector3(14.0, 0.10, 0.45), Color(0.28, 0.58, 0.18))


# ── バス停 ───────────────────────────────────────────────────────
func _build_bus_stop() -> void:
	_box(Vector3(8.0, 0.08, 13.0), Vector3(5.0, 0.16, 3.2),  Color(0.50, 0.45, 0.38))  # ベース
	_box(Vector3(8.0, 1.4,  11.7), Vector3(5.0, 2.8,  0.15), Color(0.72, 0.65, 0.55))  # 後壁
	_box(Vector3(8.0, 2.85, 12.8), Vector3(5.2, 0.18, 3.2),  Color(0.78, 0.70, 0.60))  # 屋根
	_box(Vector3(5.6, 1.4,  13.1), Vector3(0.18, 2.8, 0.18), Color(0.60, 0.55, 0.48))  # 左支柱
	_box(Vector3(10.4, 1.4, 13.1), Vector3(0.18, 2.8, 0.18), Color(0.60, 0.55, 0.48))  # 右支柱
	_box(Vector3(8.0, 0.48, 12.0), Vector3(3.8, 0.14, 0.65), Color(0.48, 0.38, 0.28))  # ベンチ座面
	_box(Vector3(6.3, 0.30, 12.0), Vector3(0.14, 0.28, 0.60), Color(0.42, 0.33, 0.24)) # ベンチ脚L
	_box(Vector3(9.7, 0.30, 12.0), Vector3(0.14, 0.28, 0.60), Color(0.42, 0.33, 0.24)) # ベンチ脚R

	# 街灯柱: バス停手前・道路際（プレイヤー初期視線上に配置）
	# プレイヤーが (0,1,15) で右向き(+X方向)を向いたとき正面に見える位置
	_box(Vector3(5.2, 2.2, 14.8), Vector3(0.14, 4.4, 0.14), Color(0.35, 0.35, 0.38))  # 柱
	_box(Vector3(5.2, 4.55, 14.8), Vector3(0.5, 0.18, 0.5),  Color(0.30, 0.30, 0.32)) # 灯具ハウジング

	var street_lamp := SpotLight3D.new()
	street_lamp.position     = Vector3(5.2, 4.4, 14.8)
	street_lamp.light_color  = Color(1.0, 0.92, 0.72)   # 電球色（暖色）
	street_lamp.light_energy = 6.0
	street_lamp.spot_range   = 14.0
	street_lamp.spot_angle   = 60.0
	add_child(street_lamp)
	street_lamp.look_at(Vector3(8.0, 5.0, 12.0))  # バス停後壁の上部に向ける（地面に当てない）


# ── 村の門 ───────────────────────────────────────────────────────
func _build_gate() -> void:
	_box(Vector3(-3.5, 2.2, -14.0), Vector3(1.0, 4.4, 1.0), Color(0.58, 0.55, 0.50))  # 左柱
	_box(Vector3( 3.5, 2.2, -14.0), Vector3(1.0, 4.4, 1.0), Color(0.58, 0.55, 0.50))  # 右柱
	_box(Vector3(0, 4.7, -14.0),    Vector3(9.0, 0.8, 0.9), Color(0.52, 0.49, 0.44))  # 上梁
	_box(Vector3(0, 5.65, -14.0),   Vector3(6.5, 1.0, 0.20), Color(0.35, 0.26, 0.16)) # 看板
	_box(Vector3(-2.8, 5.65, -13.92), Vector3(0.12, 0.75, 0.08), Color(0.65, 0.55, 0.40)) # 金具L
	_box(Vector3( 2.8, 5.65, -13.92), Vector3(0.12, 0.75, 0.08), Color(0.65, 0.55, 0.40)) # 金具R
	_box(Vector3(-8.0, 0.5, -14.0), Vector3(8.0, 1.0, 0.8), Color(0.55, 0.52, 0.48))  # 左石垣
	_box(Vector3( 8.0, 0.5, -14.0), Vector3(8.0, 1.0, 0.8), Color(0.55, 0.52, 0.48))  # 右石垣


# ── 商店街ゲート（村門の先） ───────────────────────────────────
func _build_shopping_gate() -> void:
	var packed := load("res://assets/models/environment/ShoppingStreetGate.tscn") as PackedScene
	if packed:
		var gate := packed.instantiate()
		gate.position = Vector3(0, 0, -28.0)
		add_child(gate)
	else:
		push_warning("ShoppingStreetGate.tscn が読み込めません")


# ── 雰囲気演出（ライティング＋霧パーティクル） ─────────────────────
func _build_atmosphere() -> void:
	# ── 月明かり（青白DirectionalLight3D・強め） ──
	var moon := DirectionalLight3D.new()
	moon.light_color  = Color(0.55, 0.62, 0.90)
	moon.light_energy = 0.45
	moon.rotation_degrees = Vector3(-35, 25, 0)
	moon.shadow_enabled = true
	moon.shadow_bias = 0.3
	moon.shadow_normal_bias = 2.0
	add_child(moon)

	# ── 道路沿いの街灯（SpotLight3D × 5） ──
	var lamp_data := [
		[Vector3(2.5, 5.5, 10.0), 8.0],   # バス停付近
		[Vector3(-2.5, 5.5, 4.0), 7.0],   # 道路中間
		[Vector3(2.5, 5.5, -3.0), 7.0],   # 畑あたり
		[Vector3(-2.5, 5.5, -10.0), 8.0], # 村門手前
		[Vector3(2.5, 5.5, -22.0), 6.0],  # 商店街手前
	]
	for d in lamp_data:
		var pos : Vector3 = d[0]
		var energy : float = d[1]
		var lamp := SpotLight3D.new()
		lamp.position     = pos
		lamp.light_color  = Color(1.0, 0.85, 0.55)
		lamp.light_energy = energy
		lamp.spot_range   = 20.0
		lamp.spot_angle   = 60.0
		lamp.rotation_degrees = Vector3(-80, 0, 0)
		lamp.shadow_enabled = true
		lamp.shadow_bias = 0.3
		lamp.shadow_normal_bias = 2.0
		add_child(lamp)
		# 街灯の柱
		_box(pos - Vector3(0, 2.75, 0), Vector3(0.12, 5.5, 0.12), Color(0.28, 0.28, 0.32))
		# 灯具ハウジング
		_box(pos + Vector3(0, 0.15, 0), Vector3(0.45, 0.15, 0.45), Color(0.22, 0.22, 0.26))

	# ── 畑を照らすOmniLight（青白い月光の反射風） ──
	for side in [-1.0, 1.0]:
		var fl := OmniLight3D.new()
		fl.position     = Vector3(12.0 * side, 4.0, 2.0)
		fl.light_color  = Color(0.40, 0.50, 0.80)
		fl.light_energy = 3.0
		fl.omni_range   = 22.0
		fl.omni_attenuation = 1.2
		add_child(fl)

	# ── 道路の地面を照らす低いOmniLight（懐中電灯以外でも道が見える） ──
	for z_pos in [12.0, 4.0, -4.0, -12.0, -20.0]:
		var road_l := OmniLight3D.new()
		road_l.position     = Vector3(0, 1.5, z_pos)
		road_l.light_color  = Color(0.65, 0.60, 0.50)
		road_l.light_energy = 1.2
		road_l.omni_range   = 8.0
		road_l.omni_attenuation = 2.0
		add_child(road_l)

	# ── 村門付近の不気味な赤みライト ──
	var gate_light := OmniLight3D.new()
	gate_light.position     = Vector3(0, 4.0, -14.0)
	gate_light.light_color  = Color(0.85, 0.25, 0.10)
	gate_light.light_energy = 5.0
	gate_light.omni_range   = 14.0
	gate_light.omni_attenuation = 1.5
	add_child(gate_light)
	# 門の左右にも薄い赤
	for side in [-4.0, 4.0]:
		var gl := OmniLight3D.new()
		gl.position     = Vector3(side, 2.5, -14.0)
		gl.light_color  = Color(0.70, 0.20, 0.10)
		gl.light_energy = 2.5
		gl.omni_range   = 8.0
		gl.omni_attenuation = 1.8
		add_child(gl)

	# ── 霧パーティクル ──
	_add_fog_particles(Vector3(0, 1.5, 0), Vector3(80, 5, 70), 120, 10.0, 0.25)      # 広域霧
	_add_fog_particles(Vector3(0, 0.8, -14), Vector3(24, 4, 14), 60, 8.0, 0.35)       # 村門濃霧
	_add_fog_particles(Vector3(0, 2.5, 5), Vector3(40, 6, 30), 40, 12.0, 0.18)        # 上空の薄霧


## 霧パーティクル生成ヘルパー
func _add_fog_particles(center: Vector3, area: Vector3, count: int, life: float, alpha: float) -> void:
	var particles := GPUParticles3D.new()
	particles.position = center
	particles.amount = count
	particles.lifetime = life
	particles.randomness = 0.5
	particles.visibility_aabb = AABB(-area, area * 2)

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = area / 2
	mat.direction = Vector3(1, 0.05, 0.3)
	mat.spread = 40.0
	mat.initial_velocity_min = 0.3
	mat.initial_velocity_max = 0.8
	mat.gravity = Vector3(0, 0, 0)
	mat.scale_min = 5.0
	mat.scale_max = 12.0
	mat.color = Color(0.75, 0.78, 0.85, alpha)
	particles.process_material = mat

	# メッシュ（大きめビルボードQuad）
	var mesh := QuadMesh.new()
	mesh.size = Vector2(2.0, 2.0)
	var mesh_mat := StandardMaterial3D.new()
	mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_mat.albedo_color = Color(0.85, 0.87, 0.90, alpha)
	mesh_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_mat.no_depth_test = true
	mesh.material = mesh_mat
	particles.draw_pass_1 = mesh

	add_child(particles)
