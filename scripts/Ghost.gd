extends CharacterBody3D

## 幽霊AI: PATROL → ALERT → CHASE → CATCH の状態遷移

enum GhostState { PATROL, ALERT, CHASE, CAUGHT }

const PATROL_SPEED : float = 1.8
const ALERT_SPEED  : float = 3.2
const CHASE_SPEED  : float = 5.6
const GRAVITY      : float = 9.8
const SIGHT_RANGE  : float = 18.0   # 視線検知距離
const PROX_DETECT  : float = 4.5    # 視線なしの近接検知距離
const CATCH_DIST   : float = 1.5    # 捕捉距離
const ALERT_TIME   : float = 7.0    # 最後に見た位置で待機する時間

var ghost_state : GhostState = GhostState.PATROL
var player      : Node3D     = null
var last_known  : Vector3    = Vector3.ZERO
var alert_t     : float      = 0.0
var patrol_pts  : Array[Vector3] = []
var patrol_idx  : int   = 0
var patrol_wait : float = 0.0

signal ghost_spotted_player
signal ghost_lost_player


func _ready() -> void:
	add_to_group("ghost")
	var p = get_tree().get_first_node_in_group("player")
	if p is Node3D:
		player = p
	_build_patrol()


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

	move_and_slide()


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

	# 視線が切れて距離が離れたら警戒に移行
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
