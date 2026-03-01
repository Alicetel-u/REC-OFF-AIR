extends CharacterBody3D
class_name Ghost

## 幽霊AI: PATROL → ALERT → CHASE → CATCH の状態遷移
## + 3Dモデル＋ゴーストシェーダーによる恐怖演出

enum GhostState { PATROL, ALERT, CHASE, CAUGHT }

const PATROL_SPEED : float = 0.5
const ALERT_SPEED  : float = 0.9
const CHASE_SPEED  : float = 1.4
const GRAVITY      : float = 9.8
const SIGHT_RANGE  : float = 18.0
const PROX_DETECT  : float = 4.5
const CATCH_DIST   : float = 1.5
const ALERT_TIME   : float = 7.0

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

signal ghost_spotted_player
signal ghost_lost_player


func _exit_tree() -> void:
	_is_alive = false


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

	# ランダムに1体のMonsterモデルをロード
	var model_idx := randi() % GHOST_MODELS.size()
	var model_scene : PackedScene = load(GHOST_MODELS[model_idx]) as PackedScene
	if model_scene:
		var model_inst := model_scene.instantiate()
		model_inst.name = "Model"
		model_inst.scale = Vector3(0.3, 0.3, 0.3)
		model_inst.rotation_degrees.y = 180.0
		_ghost_body.add_child(model_inst)

		# テクスチャをロード
		var tex : Texture2D = null
		if model_idx < GHOST_TEXTURES.size():
			tex = load(GHOST_TEXTURES[model_idx]) as Texture2D

		# 不透明StandardMaterial3Dでテクスチャを適用
		_apply_standard_material(model_inst, tex)

	else:
		_create_fallback_mesh()



func _apply_standard_material(node: Node, tex: Texture2D) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mat := StandardMaterial3D.new()
		if tex:
			mat.albedo_texture = tex
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

	move_and_slide()
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
func _do_alert(delta: float) -> void:
	var tgt := last_known
	tgt.y = global_position.y
	var dist := global_position.distance_to(tgt)

	if dist < 1.5:
		velocity.x = 0.0
		velocity.z = 0.0
		alert_t += delta
		if alert_t >= ALERT_TIME:
			alert_t = 0.0
			ghost_state = GhostState.PATROL
			ghost_lost_player.emit()
	else:
		var dir := (tgt - global_position).normalized()
		velocity.x = dir.x * ALERT_SPEED
		velocity.z = dir.z * ALERT_SPEED
		_face(tgt)

	if _can_see_player():
		ghost_state = GhostState.CHASE
		alert_t = 0.0
		ghost_spotted_player.emit()


# ---- 追跡 ----
func _do_chase(delta: float) -> void:
	last_known = player.global_position
	var tgt := player.global_position
	tgt.y = global_position.y

	if global_position.distance_to(player.global_position) <= CATCH_DIST:
		ghost_state = GhostState.CAUGHT
		GameManager.trigger_caught()
		return

	var dir := (tgt - global_position).normalized()
	velocity.x = dir.x * CHASE_SPEED
	velocity.z = dir.z * CHASE_SPEED
	_face(tgt)

	if not _can_see_player() and \
	   global_position.distance_to(player.global_position) > PROX_DETECT * 1.5:
		ghost_state = GhostState.ALERT
		alert_t = 0.0


# ---- プレイヤー検知 ----
func _sense_player() -> void:
	if not is_instance_valid(player):
		return
	var dist := global_position.distance_to(player.global_position)
	if dist <= PROX_DETECT or (dist <= SIGHT_RANGE and _can_see_player()):
		ghost_state = GhostState.CHASE
		last_known = player.global_position
		ghost_spotted_player.emit()


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


# ════════════════════════════════════════════════════════════════
# 恐怖ビジュアル演出
# ════════════════════════════════════════════════════════════════

func _update_visuals(delta: float) -> void:
	if not _ghost_body:
		return

	# ── rage 補間 ──
	var target_rage := 0.0
	match ghost_state:
		GhostState.CHASE:
			target_rage = 1.0
		GhostState.ALERT:
			target_rage = 0.4
		GhostState.CAUGHT:
			target_rage = 1.0
	_rage_current = lerp(_rage_current, target_rage, delta * 3.0)

	# ── シェーダーパラメータ更新 ──
	for mesh in _mesh_parts:
		if not is_instance_valid(mesh):
			continue
		var mat : Material = mesh.material_override
		if mat and mat is ShaderMaterial:
			(mat as ShaderMaterial).set_shader_parameter("rage", _rage_current)

	# ── 状態別パラメータ ──
	var bob_speed   := 1.5
	var bob_amp     := 0.06
	var target_lean := 0.0
	var sway_amp    := 1.5
	match ghost_state:
		GhostState.PATROL:
			bob_speed   = 2.0;  bob_amp = 0.06;  target_lean =  8.0;  sway_amp = 2.0
		GhostState.ALERT:
			bob_speed   = 2.8;  bob_amp = 0.08;  target_lean = 14.0;  sway_amp = 2.5
		GhostState.CHASE:
			bob_speed   = 4.5;  bob_amp = 0.10;  target_lean = 26.0;  sway_amp = 3.5
		GhostState.CAUGHT:
			bob_speed   = 0.5;  bob_amp = 0.02;  target_lean = -4.0;  sway_amp = 0.5

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
	if is_instance_valid(player):
		var dist := global_position.distance_to(player.global_position)
		var swell : float = clampf(1.0 + (1.0 - dist / SIGHT_RANGE) * 0.25, 1.0, 1.3)
		if ghost_state == GhostState.CAUGHT:
			swell = 2.0
		_ghost_body.scale = Vector3(swell, swell, swell)


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
