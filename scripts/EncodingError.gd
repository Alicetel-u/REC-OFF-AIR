extends Node

## CP3「10FPSの呪い」— Encoding Error ゲージシステム
## Main.gd の子ノードとして追加（CP3専用、Autoloadにしない）

signal gauge_changed(value: float)
signal gauge_maxed

var gauge : float = 0.0    # 0.0 ~ 100.0
var _player : Node3D = null
var _has_kama : bool = false

# ── 蓄積レート (/sec) ──
const RATE_GHOST_VISIBLE : float = 5.0   # ゴーストがカメラ方向にいる
const RATE_STAGNANT      : float = 1.0   # 同エリア滞留
const RATE_DARKNESS      : float = 0.8   # 暗闇（懐中電灯OFF）
const RATE_BASE          : float = 0.15  # 基本蓄積（常にじわじわ増える）
const KAMA_MULTIPLIER    : float = 1.5   # 鎌所持で蓄積率1.5倍

# ── 回復レート (/sec) ──
const RATE_GROUND_LOOK   : float = -3.0  # カメラを地面に向ける

# ── 段階閾値 ──
const STAGE_MILD : float = 40.0
const STAGE_MID  : float = 70.0
const STAGE_MAX  : float = 100.0

# ── 滞留検知 ──
var _last_pos : Vector3 = Vector3.ZERO
var _stagnant_time : float = 0.0
const STAGNANT_RADIUS : float = 8.0
const STAGNANT_THRESHOLD : float = 30.0  # 30秒以上同じ場所

# ── シェーダー参照 ──
var _vhs_material : ShaderMaterial = null

# ── オーディオグリッチ ──
var _glitch_timer : float = 0.0


func setup(player: Node3D, vhs_mat: ShaderMaterial) -> void:
	_player = player
	_vhs_material = vhs_mat
	if is_instance_valid(_player):
		_last_pos = _player.global_position


func notify_kama_acquired() -> void:
	_has_kama = true


func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	if not is_instance_valid(_player):
		return

	var rate : float = RATE_BASE

	# ── ゴースト視認チェック ──
	rate += _calc_ghost_rate()

	# ── 滞留チェック ──
	rate += _calc_stagnant_rate(delta)

	# ── 暗闇チェック ──
	if is_instance_valid(_player) and not _player.flashlight_on:
		rate += RATE_DARKNESS

	# ── 回復: カメラを地面に向ける ──
	if is_instance_valid(_player) and _player.head.rotation.x < -0.5:
		rate += RATE_GROUND_LOOK

	# ── 鎌所持で蓄積率アップ（蓄積方向のみ） ──
	if _has_kama and rate > 0.0:
		rate *= KAMA_MULTIPLIER

	gauge = clampf(gauge + rate * delta, 0.0, STAGE_MAX)
	gauge_changed.emit(gauge)

	if gauge >= STAGE_MAX:
		gauge_maxed.emit()

	_apply_visual_effects(delta)


func _calc_ghost_rate() -> float:
	if not is_instance_valid(_player):
		return 0.0
	var cam : Camera3D = _player.get_node_or_null("Head/Camera3D")
	if not cam:
		return 0.0

	var total : float = 0.0
	for ghost_node: Node in get_tree().get_nodes_in_group("ghost"):
		if not is_instance_valid(ghost_node) or not ghost_node.visible:
			continue
		var ghost_3d : Node3D = ghost_node as Node3D
		if not ghost_3d:
			continue
		var to_ghost : Vector3 = ghost_3d.global_position - cam.global_position
		var dist : float = to_ghost.length()
		if dist > 30.0:
			continue
		var forward : Vector3 = -cam.global_transform.basis.z
		var dot : float = forward.normalized().dot(to_ghost.normalized())
		if dot > 0.5:
			var intensity : float = 1.0 - (dist / 30.0)
			total += RATE_GHOST_VISIBLE * intensity
	return total


func _calc_stagnant_rate(delta: float) -> float:
	if not is_instance_valid(_player):
		return 0.0
	var pos := _player.global_position
	if pos.distance_to(_last_pos) > STAGNANT_RADIUS:
		_last_pos = pos
		_stagnant_time = 0.0
		return 0.0
	_stagnant_time += delta
	if _stagnant_time >= STAGNANT_THRESHOLD:
		return RATE_STAGNANT
	return 0.0


func _apply_visual_effects(delta: float) -> void:
	if not is_instance_valid(_vhs_material):
		return

	var pct := gauge / STAGE_MAX

	# ── シェーダーパラメータ制御 ──
	# noise_strength: 0.035 (通常) → 0.12 (最大)
	var noise : float = lerpf(0.035, 0.12, pct)
	_vhs_material.set_shader_parameter("noise_strength", noise)

	# chroma_offset: 0.0025 (通常) → 0.008 (最大)
	var chroma : float = lerpf(0.0025, 0.008, pct)
	_vhs_material.set_shader_parameter("chroma_offset", chroma)

	# scanline_intensity: 0.10 (通常) → 0.35 (最大)
	var scanline : float = lerpf(0.10, 0.35, pct)
	_vhs_material.set_shader_parameter("scanline_intensity", scanline)

	# ── Player 操作鈍化（70%以上） ──
	if is_instance_valid(_player) and _player.has_method("set_input_lag"):
		if gauge >= STAGE_MID:
			# 70-100%: 1.0 → 0.3 に鈍化
			var lag_pct := (gauge - STAGE_MID) / (STAGE_MAX - STAGE_MID)
			var lag : float = lerpf(1.0, 0.3, lag_pct)
			_player.set_input_lag(lag)
		else:
			_player.set_input_lag(1.0)

	# ── オーディオグリッチ（40%以上） ──
	if gauge >= STAGE_MILD:
		_glitch_timer += delta
		var interval : float = lerpf(3.0, 0.5, (gauge - STAGE_MILD) / (STAGE_MAX - STAGE_MILD))
		if _glitch_timer >= interval:
			_glitch_timer = 0.0
			_do_audio_glitch()


func _do_audio_glitch() -> void:
	# ピッチを一瞬変える（不気味なノイズ効果）
	SoundManager.play_sfx_file("metal/impactMetal_heavy_000.ogg", -20.0)
