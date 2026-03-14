extends Node

## CP3「10FPSの呪い」— Encoding Error ゲージシステム
## Main.gd の子ノードとして追加（CP3専用、Autoloadにしない）

signal gauge_changed(value: float)
signal gauge_maxed

var gauge : float = 0.0    # 0.0 ~ 100.0
var _player : Node3D = null
var _has_kama : bool = false
var _chrome : Node = null   # YouTubeChrome（同接数参照用）

# ── 蓄積レート (/sec) ──
const RATE_GHOST_VISIBLE : float = 5.0   # ゴーストがカメラ方向にいる
const RATE_STAGNANT      : float = 1.0   # 同エリア滞留
const RATE_DARKNESS      : float = 0.8   # 暗闇（懐中電灯OFF）
const RATE_BASE          : float = 0.15  # 基本蓄積（常にじわじわ増える）
const KAMA_MULTIPLIER    : float = 1.5   # 鎌所持で蓄積率1.5倍

# ── 同接数による蓄積ブースト ──
const VIEWERS_THRESHOLD  : int   = 5000  # この人数を超えると蓄積加速
const VIEWERS_MAX_MULT   : float = 1.8   # 最大倍率（10000人以上）

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
const STAGNANT_THRESHOLD : float = 30.0

# ── シェーダー参照 ──
var _vhs_material : ShaderMaterial = null

# ── オーディオグリッチ ──
var _glitch_timer : float = 0.0

# ── しゅっちセリフ（段階ごとに1回だけ） ──
var _said_50 : bool = false
var _said_80 : bool = false

# ── ゲームオーバー発動済みフラグ ──
var _maxed : bool = false


func setup(player: Node3D, vhs_mat: ShaderMaterial, chrome: Node = null) -> void:
	_player = player
	_vhs_material = vhs_mat
	_chrome = chrome
	if is_instance_valid(_player):
		_last_pos = _player.global_position


func notify_kama_acquired() -> void:
	_has_kama = true


func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	if not is_instance_valid(_player) or _maxed:
		return

	var rate : float = RATE_BASE

	# ── ゴースト視認チェック ──
	rate += _calc_ghost_rate()

	# ── 滞留チェック ──
	rate += _calc_stagnant_rate(delta)

	# ── 暗闇チェック ──
	if not _player.flashlight_on:
		rate += RATE_DARKNESS

	# ── 回復: カメラを地面に向ける ──
	if _player.head.rotation.x < -0.5:
		rate += RATE_GROUND_LOOK

	# ── 鎌所持で蓄積率アップ（蓄積方向のみ） ──
	if _has_kama and rate > 0.0:
		rate *= KAMA_MULTIPLIER

	# ── 同接数による蓄積ブースト ──
	if rate > 0.0:
		rate *= _calc_viewers_multiplier()

	gauge = clampf(gauge + rate * delta, 0.0, STAGE_MAX)
	gauge_changed.emit(gauge)

	# ── しゅっちセリフ ──
	_check_monologue()

	if gauge >= STAGE_MAX and not _maxed:
		_maxed = true
		gauge_maxed.emit()

	_apply_visual_effects(delta)


func _calc_ghost_rate() -> float:
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
	var pos := _player.global_position
	if pos.distance_to(_last_pos) > STAGNANT_RADIUS:
		_last_pos = pos
		_stagnant_time = 0.0
		return 0.0
	_stagnant_time += delta
	if _stagnant_time >= STAGNANT_THRESHOLD:
		return RATE_STAGNANT
	return 0.0


func _calc_viewers_multiplier() -> float:
	if not is_instance_valid(_chrome):
		return 1.0
	var count : int = _chrome._view_count if "_view_count" in _chrome else 0
	if count <= VIEWERS_THRESHOLD:
		return 1.0
	var extra : float = float(count - VIEWERS_THRESHOLD) / float(VIEWERS_THRESHOLD)
	return minf(1.0 + extra * (VIEWERS_MAX_MULT - 1.0), VIEWERS_MAX_MULT)


func _check_monologue() -> void:
	var hud : Control = _find_hud()
	if not hud or not hud.has_method("show_monologue"):
		return

	if gauge >= 50.0 and not _said_50:
		_said_50 = true
		hud.show_monologue("あれ、なんかPC重くない？ 回線のせいか……？")
		_auto_hide_monologue(hud, 4.0)

	elif gauge >= 80.0 and not _said_80:
		_said_80 = true
		hud.show_monologue("クソ、カクカクして……リスナーも『ラグい』って騒いでる！\nでも今やめたら……！")
		_auto_hide_monologue(hud, 5.0)


func _auto_hide_monologue(hud: Control, sec: float) -> void:
	var tree := get_tree()
	if tree:
		await tree.create_timer(sec).timeout
		if is_instance_valid(hud) and hud.has_method("hide_monologue"):
			hud.hide_monologue()


func _apply_visual_effects(delta: float) -> void:
	if not is_instance_valid(_vhs_material):
		return

	var pct := gauge / STAGE_MAX

	# ── noise_strength: 0.01 → 0.15 ──
	var noise : float = lerpf(0.01, 0.15, pct)
	_vhs_material.set_shader_parameter("noise_strength", noise)

	# ── chroma_offset: 0.001 → 0.012 ──
	var chroma : float = lerpf(0.001, 0.012, pct)
	_vhs_material.set_shader_parameter("chroma_offset", chroma)

	# ── scanline_intensity: 0.0 → 0.30（低ゲージ時はスキャンライン無し） ──
	var scanline : float = lerpf(0.0, 0.30, pct)
	_vhs_material.set_shader_parameter("scanline_intensity", scanline)

	# ── block_noise: 0.0 → 0.8（70%以上で発動） ──
	var block : float = 0.0
	if gauge >= STAGE_MID:
		block = lerpf(0.0, 0.8, (gauge - STAGE_MID) / (STAGE_MAX - STAGE_MID))
	_vhs_material.set_shader_parameter("block_noise", block)

	# ── Player 操作鈍化（70%以上） ──
	if is_instance_valid(_player) and _player.has_method("set_input_lag"):
		if gauge >= STAGE_MID:
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
	SoundManager.play_sfx_file("metal/impactMetal_heavy_000.ogg", -20.0)


func _find_hud() -> Control:
	var main := get_tree().current_scene
	if main and main.has_node("HUDLayer/HUDRoot"):
		return main.get_node("HUDLayer/HUDRoot") as Control
	return null
