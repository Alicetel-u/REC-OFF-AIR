extends Node3D

# --- みゆき専用：不気味歩行・腕操作コントローラー ---
@export_group("基本設定")
@export var ターゲット: Node3D
@export var 逆さまにする: bool = false

@export_group("不気味な歩行")
@export var 歩く: bool = true
@export var 歩行速度: float = 0.3
@export var 歩幅: float = 0.2
@export var 揺れの速さ: float = 0.8

@export_group("【新機能】腕のポーズ調整")
@export_range(-1.0, 2.0) var 腕を広げる: float = 0.5
@export_range(-180, 180) var 腕の前後振り: float = 0.0
@export var 腕をゆらゆらさせる: bool = true

@export_group("痙攣（けいれん）設定")
@export var 痙攣を有効にする: bool = true
@export_range(0.0, 2.0) var 痙攣の激しさ: float = 0.4 # 初期値を下げました
@export_range(0.0, 1.0) var 関節のガクつき: float = 0.2 # マイルドにしました

@export_group("ポーズ手動調整")
@export_range(-180, 180) var 腰のねじれ: float = 0.0
@export_range(-180, 180) var 首の角度: float = 0.0

# --- 内部変数 ---
var time: float = 0.0
var mesh_node: MeshInstance3D
var base_pos: Vector3

func _ready():
	_find_mesh(self)
	if mesh_node:
		base_pos = mesh_node.position
	if 逆さまにする:
		rotation.x = PI

func _find_mesh(node: Node):
	for child in node.get_children():
		if child is MeshInstance3D:
			mesh_node = child
			return
		_find_mesh(child)

func _process(delta):
	time += delta * 揺れの速さ
	
	if ターゲット:
		# 常にターゲット（プレイヤー）を凝視する
		var look_target = ターゲット.global_position
		look_target.y = global_position.y
		look_at(look_target, Vector3.UP)
		if 逆さまにする:
			rotate_object_local(Vector3.RIGHT, PI)

		# 接近処理
		if 歩く:
			var dir = (ターゲット.global_position - global_position).normalized()
			dir.y = 0
			global_position += dir * 歩行速度 * delta

	# --- アニメーション：骨がなくても「歩行・腕・痙攣」を再現する ---
	if mesh_node:
		var final_rot = Vector3.ZERO
		var final_pos = base_pos
		var final_scale = Vector3.ONE
		
		# 1. 歩行による体の揺れ（控えめに）
		if 歩く:
			var walk_cycle = sin(time * 4.0)
			final_pos.y += abs(walk_cycle) * 歩幅 * 0.03
			final_rot.z += walk_cycle * 0.01
			final_rot.y += cos(time * 2.0) * 0.015

		# 2. 腕の動き（擬似的にスケールと回転で表現）
		final_scale.x = 1.0 + (腕を広げる * 0.05)
		if 腕をゆらゆらさせる:
			final_rot.z += sin(time * 1.5) * 0.015
		final_rot.x += deg_to_rad(腕の前後振り)

		# 3. 痙攣（微かなピクピク — 回転のみ、位置はずらさない）
		if 痙攣を有効にする:
			if randf() < 関節のガクつき:
				final_rot.x += randf_range(-0.02, 0.02) * 痙攣の激しさ
				final_rot.z += randf_range(-0.01, 0.01) * 痙攣の激しさ
		
		# 4. 手動設定の反映
		final_rot.y += deg_to_rad(腰のねじれ)
		final_rot.x += deg_to_rad(首の角度)
		
		# 最終的なポーズを適用
		mesh_node.position = final_pos
		mesh_node.rotation = final_rot
		mesh_node.scale = final_scale
