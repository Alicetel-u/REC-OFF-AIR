extends CharacterBody3D
class_name Ghost

## 幽霊AI: PATROL → ALERT → CHASE → CATCH の状態遷移
## + 3Dモデル＋ゴーストシェーダーによる恐怖演出

enum GhostState { PATROL, ALERT, CHASE, CAUGHT }

const PATROL_SPEED : float = 0.5
const ALERT_SPEED  : float = 0.9
const CHASE_SPEED  : float = 1.6
const CHASE_BURST  : float = 4.5   # 瞬間ダッシュ速度
const CHASE_STRAFE : float = 2.5   # 横移動の速さ
const GRAVITY      : float = 9.8
const SIGHT_RANGE  : float = 25.0
const PROX_DETECT  : float = 4.5
const CATCH_DIST   : float = 1.5
const ALERT_TIME   : float = 7.0

# 状態別ビジュアルパラメータ
const STATE_VISUALS := {
	GhostState.PATROL: {"bob_speed": 2.0, "bob_amp": 0.06, "target_lean":  8.0, "sway_amp": 2.0, "rage": 0.0},
	GhostState.ALERT:  {"bob_speed": 2.8, "bob_amp": 0.08, "target_lean": 14.0, "sway_amp": 2.5, "rage": 0.4},
	GhostState.CHASE:  {"bob_speed": 4.5, "bob_amp": 0.10, "target_lean": 26.0, "sway_amp": 3.5, "rage": 1.0},
	GhostState.CAUGHT: {"bob_speed": 0.5, "bob_amp": 0.02, "target_lean": -4.0, "sway_amp": 0.5, "rage": 1.0},
}

# 人型キャラクターモデルのパス（FBX）
const GHOST_MODELS : Array[String] = [
	"res://assets/models/characters/female/Character_17_Female_Police.fbx",
	"res://assets/models/characters/female/Character_18_Female_Police.fbx",
	"res://assets/models/characters/female/Character_23_Female_Doctor.fbx",
	"res://assets/models/characters/female/Character_24_Female_Doctor.fbx",
	"res://assets/models/characters/female/Character_29_Female.fbx",
	"res://assets/models/characters/female/Character_30_Female.fbx",
]
# テクスチャパス（モデルと対応）
const GHOST_TEXTURES : Array[String] = [
	"res://assets/textures/characters/Character_17_Female_Police.png",
	"res://assets/textures/characters/Character_18_Female_Police.png",
	"res://assets/textures/characters/Character_23_Female_Doctor.png",
	"res://assets/textures/characters/Character_24_Female_Doctor.png",
	"res://assets/textures/characters/Character_29_Female.png",
	"res://assets/textures/characters/Character_30_Female.png",
]
var ghost_state : GhostState = GhostState.PATROL
var player      : Node3D     = null
var last_known  : Vector3    = Vector3.ZERO
var alert_t     : float      = 0.0
var patrol_pts  : Array[Vector3] = []
var patrol_idx  : int   = 0
var patrol_wait : float = 0.0

# ── ビジュアル演出用 ──
var _ghost_body   : Node3D      = null
var _ghost_light  : OmniLight3D = null
var _mesh_parts   : Array[MeshInstance3D] = []
var _rage_current : float = 0.0
var _flicker_t    : float = 0.0
var _flicker_next : float = 0.0
var _bob_phase    : float = 0.0
var _head_tilt_t  : float = 0.0
var _lean_current : float = 0.0
var _is_alive     : bool  = true
var _growl_timer    : float = 0.0
var _growl_interval : float = 5.0
# ── フェイクラッシュ演出用 ──
var _fake_rush_timer : float = 0.0
var _fake_rush_next  : float = 8.0
var _fake_rushing     : bool  = false
# ── 不規則追跡用 ──
var _erratic_timer  : float = 0.0   # 次の行動切替までのタイマー
var _erratic_mode   : int   = 0     # 0=直進 1=横移動 2=急停止 3=バースト
var _erratic_dir    : Vector3 = Vector3.ZERO  # 不規則方向
var custom_model_path : String = ""
var custom_model_scale : Vector3 = Vector3(1.2, 1.2, 1.2)
var _physics_ready : bool = false

signal ghost_spotted_player
signal ghost_lost_player


func _exit_tree() -> void:
	_is_alive = false
	_mesh_parts.clear()


func _ready() -> void:
	add_to_group("ghost")
	var p = get_tree().get_first_node_in_group("player")
	if p is Node3D:
		player = p
	_build_patrol()
	_init_visuals()


func _build_patrol() -> void:
	for c in get_children():
		if c is Marker3D:
			patrol_pts.append(c.global_position)
	if patrol_pts.is_empty():
		var o := global_position
		patrol_pts = [
			o + Vector3( 8, 0,  8),
			o + Vector3(-8, 0,  8),
			o + Vector3(-8, 0, -8),
			o + Vector3( 8, 0, -8),
		]


func _init_visuals() -> void:
	_ghost_body = get_node_or_null("GhostBody")
	_ghost_light = get_node_or_null("GhostLight") as OmniLight3D
	_bob_phase = randf() * TAU
	_flicker_next = randf_range(4.0, 12.0)

	if not _ghost_body:
		return

	# カスタムモデル指定がある場合はそちらを使う（みゆき等）
	if not custom_model_path.is_empty():
		var custom_scene : PackedScene = load(custom_model_path) as PackedScene
		if custom_scene:
			var model_inst := custom_scene.instantiate()
			model_inst.name = "Model"
			model_inst.scale = custom_model_scale
			model_inst.rotation_degrees.y = 0.0
			_ghost_body.add_child(model_inst)
			# カスタムモデルは元のマテリアルを維持（MeshInstance3Dだけ追跡）
			_collect_mesh_parts(model_inst)
		else:
			_create_fallback_mesh()
		return

	# ランダムに1体のMonsterモデルをロード
	var model_idx := randi() % GHOST_MODELS.size()
	var model_scene : PackedScene = load(GHOST_MODELS[model_idx]) as PackedScene
	if model_scene:
		var model_inst := model_scene.instantiate()
		model_inst.name = "Model"
		model_inst.scale = Vector3(1.2, 1.2, 1.2)
		model_inst.rotation_degrees.y = 0.0
		_ghost_body.add_child(model_inst)

		# テクスチャをロード
		var tex : Texture2D = null
		if model_idx < GHOST_TEXTURES.size():
			tex = load(GHOST_TEXTURES[model_idx]) as Texture2D

		# 不透明StandardMaterial3Dでテクスチャを適用
		_apply_standard_material(model_inst, tex)

	else:
		_create_fallback_mesh()



func _collect_mesh_parts(node: Node) -> void:
	if node is MeshInstance3D:
		_mesh_parts.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_mesh_parts(child)


func _apply_standard_material(node: Node, tex: Texture2D) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mat := StandardMaterial3D.new()
		if tex:
			mat.albedo_texture = tex
		# 暗所でもシルエットが見えるよう自発光
		mat.emission_enabled = true
		mat.emission = Color(0.15, 0.04, 0.04)
		mat.emission_energy_multiplier = 0.8
		mi.material_override = mat
		_mesh_parts.append(mi)
	for child in node.get_children():
		_apply_standard_material(child, tex)


func _create_fallback_mesh() -> void:
	# FBXが読めない場合のプリミティブメッシュ（StandardMaterial3D使用）
	var fallback_mat := StandardMaterial3D.new()
	fallback_mat.albedo_color = Color(0.8, 0.85, 1.0)
	fallback_mat.emission_enabled = true
	fallback_mat.emission = Color(0.3, 0.4, 0.8)
	fallback_mat.emission_energy_multiplier = 0.5

	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.16
	head_mesh.height = 0.32
	head.mesh = head_mesh
	head.position = Vector3(0, 1.55, 0)
	head.material_override = fallback_mat
	_ghost_body.add_child(head)
	_mesh_parts.append(head)

	var torso := MeshInstance3D.new()
	torso.name = "Torso"
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.18
	torso_mesh.height = 0.7
	torso.mesh = torso_mesh
	torso.position = Vector3(0, 1.05, 0)
	torso.material_override = fallback_mat
	_ghost_body.add_child(torso)
	_mesh_parts.append(torso)

	var skirt := MeshInstance3D.new()
	skirt.name = "Skirt"
	var skirt_mesh := CylinderMesh.new()
	skirt_mesh.top_radius = 0.2
	skirt_mesh.bottom_radius = 0.42
	skirt_mesh.height = 0.95
	skirt.mesh = skirt_mesh
	skirt.position = Vector3(0, 0.35, 0)
	skirt.material_override = fallback_mat
	_ghost_body.add_child(skirt)
	_mesh_parts.append(skirt)


func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		velocity = Vector3.ZERO
		return
	if not is_instance_valid(player):
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	match ghost_state:
		GhostState.PATROL:
			_do_patrol(delta)
			_sense_player()
		GhostState.ALERT:
			_do_alert(delta)
		GhostState.CHASE:
			_do_chase(delta)
		GhostState.CAUGHT:
			velocity.x = 0.0
			velocity.z = 0.0
			_face(player.global_position)

	if _physics_ready:
		move_and_slide()
	elif is_inside_tree():
		_physics_ready = true
	_update_visuals(delta)


# ---- 巡回 ----
func _do_patrol(delta: float) -> void:
	if patrol_pts.is_empty():
		return
	var tgt := patrol_pts[patrol_idx]
	tgt.y = global_position.y
	var dist := global_position.distance_to(tgt)

	if dist < 1.2:
		velocity.x = 0.0
		velocity.z = 0.0
		patrol_wait += delta
		if patrol_wait >= 2.5:
			patrol_wait = 0.0
			patrol_idx = (patrol_idx + 1) % patrol_pts.size()
		if is_instance_valid(player):
			_face(player.global_position)
	else:
		var dir := (tgt - global_position).normalized()
		velocity.x = dir.x * PATROL_SPEED
		velocity.z = dir.z * PATROL_SPEED
		_face(tgt)


# ---- 警戒(最後の位置へ移動) ----
const ALERT_MIN_TIME : float = 3.0  # CHASEに遷移するまでの最低警戒時間

func _do_alert(delta: float) -> void:
	alert_t += delta
	var tgt := last_known
	tgt.y = global_position.y
	var dist := global_position.distance_to(tgt)

	if dist < 1.5:
		velocity.x = 0.0
		velocity.z = 0.0
		if alert_t >= ALERT_TIME:
			alert_t = 0.0
			ghost_state = GhostState.PATROL
			ghost_lost_player.emit()
	else:
		var dir := (tgt - global_position).normalized()
		velocity.x = dir.x * ALERT_SPEED
		velocity.z = dir.z * ALERT_SPEED
		_face(tgt)

	# 最低3秒警戒してからCHASEに遷移
	if alert_t >= ALERT_MIN_TIME:
		var chase_dist := global_position.distance_to(player.global_position)
		if chase_dist <= SIGHT_RANGE:
			ghost_state = GhostState.CHASE
			_erratic_timer = 0.0  # CHASE開始時にすぐモード選択
			alert_t = 0.0
			ghost_spotted_player.emit()
			SoundManager.play_monster_growl(-6.0)


# ---- 追跡（不規則挙動）----
# 常にプレイヤーに向かうが、速度・横ブレ・急停止が不規則
func _do_chase(delta: float) -> void:
	# 定期的な唸り声
	_growl_timer += delta
	if _growl_timer >= _growl_interval:
		_growl_timer = 0.0
		_growl_interval = randf_range(3.0, 6.0)
		var dist := global_position.distance_to(player.global_position)
		SoundManager.play_monster_growl(-3.0 if dist < 8.0 else -10.0)

	last_known = player.global_position
	var tgt := player.global_position
	tgt.y = global_position.y

	# 接触判定: Y軸を無視した水平距離
	var ghost_xz := Vector2(global_position.x, global_position.z)
	var player_xz := Vector2(player.global_position.x, player.global_position.z)
	if ghost_xz.distance_to(player_xz) <= CATCH_DIST:
		ghost_state = GhostState.CAUGHT
		GameManager.trigger_caught()
		return

	var to_player := (tgt - global_position).normalized()
	var strafe := Vector3(-to_player.z, 0, to_player.x)

	# ── 不規則ブレ（常時）──
	_erratic_timer -= delta
	if _erratic_timer <= 0.0:
		# 新しいブレパターンを生成
		_erratic_timer = randf_range(0.08, 0.3)
		var roll := randf()
		if roll < 0.15:
			# 急停止（ピタッと止まる不気味さ）
			_erratic_mode = 2
		elif roll < 0.35:
			# バースト（超高速で詰める）
			_erratic_mode = 3
		else:
			# 横ブレ付き前進
			_erratic_mode = 1
			_erratic_dir = strafe * randf_range(-1.0, 1.0)

	# ── 常にプレイヤー方向へ移動 + 不規則な味付け ──
	var speed : float = CHASE_SPEED
	var lateral : float = 0.0  # 横方向の追加速度

	match _erratic_mode:
		1:  # 横ブレ（前進しつつ横に揺れる）
			lateral = _erratic_dir.length() * CHASE_STRAFE
			speed = CHASE_SPEED * randf_range(0.8, 1.3)
		2:  # 急停止
			speed = 0.0
		3:  # バースト
			speed = CHASE_BURST

	velocity.x = to_player.x * speed + strafe.x * lateral
	velocity.z = to_player.z * speed + strafe.z * lateral

	# 常にプレイヤーの方を向く
	_face(tgt)

	if global_position.distance_to(player.global_position) > SIGHT_RANGE:
		ghost_state = GhostState.ALERT
		alert_t = 0.0


# ---- プレイヤー検知 ----
func _sense_player() -> void:
	if not is_instance_valid(player):
		return
	var dist := global_position.distance_to(player.global_position)
	if dist <= PROX_DETECT or (dist <= SIGHT_RANGE and _can_see_player()):
		# まずALERTに遷移（いきなりCHASE→即CATCHを防ぐ）
		ghost_state = GhostState.ALERT
		alert_t = 0.0
		last_known = player.global_position
		ghost_spotted_player.emit()
		SoundManager.play_monster_growl(-4.0)


# ---- 視線チェック (raycast) ----
func _can_see_player() -> bool:
	if not is_instance_valid(player):
		return false
	var dist := global_position.distance_to(player.global_position)
	if dist > SIGHT_RANGE:
		return false
	var space := get_world_3d().direct_space_state
	var from  := global_position + Vector3(0, 1.4, 0)
	var to    := player.global_position + Vector3(0, 1.0, 0)
	var q     := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [self]
	var hit   := space.intersect_ray(q)
	return hit.is_empty() or hit.get("collider") == player


func _face(target: Vector3) -> void:
	var t := target
	t.y = global_position.y
	if t.distance_to(global_position) > 0.1:
		look_at(t, Vector3.UP)
		rotation.y += PI * 0.5


# ════════════════════════════════════════════════════════════════
# 恐怖ビジュアル演出
# ════════════════════════════════════════════════════════════════

func _update_visuals(delta: float) -> void:
	if not _ghost_body:
		return

	# ── rage 補間 ──
	var target_rage : float = STATE_VISUALS.get(ghost_state, STATE_VISUALS[GhostState.PATROL])["rage"]
	_rage_current = lerp(_rage_current, target_rage, delta * 3.0)

	# ── シェーダーパラメータ更新 ──
	for mesh in _mesh_parts:
		if not is_instance_valid(mesh):
			continue
		var mat : Material = mesh.material_override
		if mat and mat is ShaderMaterial:
			(mat as ShaderMaterial).set_shader_parameter("rage", _rage_current)

	# ── 状態別パラメータ ──
	var p : Dictionary = STATE_VISUALS.get(ghost_state, STATE_VISUALS[GhostState.PATROL])
	var bob_speed   : float = p["bob_speed"]
	var bob_amp     : float = p["bob_amp"]
	var target_lean : float = p["target_lean"]
	var sway_amp    : float = p["sway_amp"]

	# ── ボブ・前傾き・スウェイ ──
	_bob_phase    += delta * bob_speed
	_lean_current  = lerp(_lean_current, target_lean, delta * 5.0)
	var bob_y  := sin(_bob_phase) * bob_amp
	var sway_z := sin(_bob_phase * 0.6) * sway_amp
	_ghost_body.position.y          = bob_y
	_ghost_body.rotation_degrees.x  = _lean_current
	_ghost_body.rotation_degrees.z  = sway_z

	# ── GhostLight 状態連動 ──
	if _ghost_light:
		var base_energy := 0.8
		var chase_energy := 2.5
		_ghost_light.light_energy = lerp(base_energy, chase_energy, _rage_current)
		var base_col := Color(0.6, 0.08, 0.08)
		var chase_col := Color(1.0, 0.02, 0.02)
		_ghost_light.light_color = base_col.lerp(chase_col, _rage_current)

	# ── ちらつき ──
	_flicker_t += delta
	if _flicker_t >= _flicker_next:
		_flicker_t = 0.0
		_flicker_next = randf_range(3.0, 10.0)
		_do_flicker()

	# ── 接近膨張 ──
	if is_instance_valid(player) and not _fake_rushing:
		var dist := global_position.distance_to(player.global_position)
		var swell : float = clampf(1.0 + (1.0 - dist / SIGHT_RANGE) * 0.25, 1.0, 1.3)
		if ghost_state == GhostState.CAUGHT:
			swell = 2.0
		_ghost_body.scale = Vector3(swell, swell, swell)

	# ── フェイクラッシュ（CHASE/ALERT中にランダム発動）──
	if ghost_state in [GhostState.CHASE, GhostState.ALERT] and not _fake_rushing:
		_fake_rush_timer += delta
		if _fake_rush_timer >= _fake_rush_next:
			_fake_rush_timer = 0.0
			_fake_rush_next = randf_range(6.0, 14.0)
			_do_fake_rush()


func _do_fake_rush() -> void:
	## フェイクラッシュ — 見た目だけ超高速でプレイヤーに突っ込む演出
	## 実際のCharacterBody3D位置は一切変わらない
	if not _ghost_body or not is_instance_valid(player):
		return
	_fake_rushing = true
	SoundManager.play_monster_growl(-1.0)

	# プレイヤー方向のローカルベクトル
	var rush_local := global_transform.basis.inverse() * (player.global_position - global_position).normalized()
	rush_local.y = 0.0
	if rush_local.length() < 0.01:
		rush_local = Vector3(0, 0, -1)
	rush_local = rush_local.normalized()

	var orig_pos := _ghost_body.position
	var orig_scale := _ghost_body.scale

	# Phase 1: 一瞬消える（溜め）
	_ghost_body.visible = false
	await get_tree().create_timer(0.08).timeout
	if not _is_alive or not is_instance_valid(_ghost_body):
		_fake_rushing = false
		return

	# Phase 2: 遠くから超高速で突っ込む（巨大化しながら）
	_ghost_body.visible = true
	_ghost_body.position = orig_pos + rush_local * 8.0
	_ghost_body.scale = orig_scale * 0.5

	var tw := create_tween().set_parallel(true)
	tw.tween_property(_ghost_body, "position", orig_pos + rush_local * -1.5, 0.18)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.tween_property(_ghost_body, "scale", orig_scale * 2.8, 0.18)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await tw.finished
	if not _is_alive or not is_instance_valid(_ghost_body):
		_fake_rushing = false
		return

	# Phase 3: 一瞬画面いっぱい + 金属音
	SoundManager.play_sfx_file("metal/impactMetal_heavy_002.ogg")
	await get_tree().create_timer(0.06).timeout
	if not _is_alive or not is_instance_valid(_ghost_body):
		_fake_rushing = false
		return

	# Phase 4: パッと消えて元に戻る
	_ghost_body.visible = false
	await get_tree().create_timer(0.12).timeout
	if not _is_alive or not is_instance_valid(_ghost_body):
		_fake_rushing = false
		return

	_ghost_body.position = orig_pos
	_ghost_body.scale = orig_scale
	_ghost_body.visible = true
	_fake_rushing = false


func _do_flicker() -> void:
	if not _ghost_body:
		return
	_ghost_body.visible = false
	await get_tree().create_timer(randf_range(0.05, 0.15)).timeout
	if not _is_alive or not is_instance_valid(_ghost_body):
		return
	_ghost_body.visible = true
	if randf() < 0.4:
		await get_tree().create_timer(0.08).timeout
		if not _is_alive or not is_instance_valid(_ghost_body):
			return
		_ghost_body.visible = false
		await get_tree().create_timer(randf_range(0.03, 0.1)).timeout
		if not _is_alive or not is_instance_valid(_ghost_body):
			return
		_ghost_body.visible = true
