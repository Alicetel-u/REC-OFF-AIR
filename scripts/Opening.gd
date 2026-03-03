extends Control

## ─────────────────────────────────────────
## オープニング演出 — 霧原村シナリオ ver.2
## リッチUI + ホラー演出 + 大きい文字
## ─────────────────────────────────────────

# ── ノード参照（.tscn） ──
@onready var glitch_overlay  : ColorRect     = $GlitchOverlay
@onready var panel_title     : Control       = $PanelTitle
@onready var panel_profile   : Control       = $PanelProfile
@onready var panel_dm        : Control       = $PanelDM
@onready var panel_monologue : Control       = $PanelMonologue
@onready var panel_caption   : Control       = $PanelCaption
@onready var panel_map_select: Control       = $PanelMapSelect
@onready var panel_start     : Control       = $PanelStart
@onready var profile_text    : RichTextLabel = $PanelProfile/ProfileText
@onready var dm_text         : RichTextLabel = $PanelDM/DMText
@onready var monologue_text  : RichTextLabel = $PanelMonologue/MonologueText
@onready var caption_text    : Label         = $PanelCaption/CaptionText

enum Phase { TITLE, VIDEO, PROLOGUE, DONE }

var _phase         : Phase = Phase.TITLE
var _title_ready   : bool  = false
var _skipped       : bool  = false
var _video_player  : VideoStreamPlayer = null
var _video_started : bool  = false
var _skip_btn      : Button = null

# ── タイトル画面アニメーション用 ──
var _title_elapsed   : float = 0.0
var _rec_label       : Label = null
var _time_label      : Label = null
var _viewer_label    : Label = null
var _prompt_label    : Label = null


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_hide_all_panels()
	glitch_overlay.color = Color(1, 1, 1, 0)
	const _DEBUG_SKIP_INTRO := false
	if _DEBUG_SKIP_INTRO:
		_go_to_game()
		return
	_phase = Phase.TITLE
	_run_title()


func _process(delta: float) -> void:
	# ── 動画再生監視 ──
	if _phase == Phase.VIDEO and _video_player and is_instance_valid(_video_player):
		if not _video_started and _video_player.is_playing():
			_video_started = true
		elif _video_started and not _video_player.is_playing():
			_phase = Phase.PROLOGUE
			_on_video_finished()
		return
	# ── タイトル画面アニメーション ──
	if _phase == Phase.TITLE:
		_title_elapsed += delta
		_update_title_anim()


func _update_title_anim() -> void:
	# REC ● 点滅（0.7秒表示 / 0.3秒暗め）
	if is_instance_valid(_rec_label):
		_rec_label.modulate.a = 1.0 if fmod(_title_elapsed, 1.0) < 0.7 else 0.2

	# タイマー表示
	if is_instance_valid(_time_label):
		var t := int(_title_elapsed)
		var frames := int(fmod(_title_elapsed, 1.0) * 30)
		_time_label.text = "%02d:%02d:%02d" % [t / 60, t % 60, frames]

	# 視聴者数（じわじわ増加）
	if is_instance_valid(_viewer_label):
		var v := 0
		if _title_elapsed > 2.5:
			v = int(clampf((_title_elapsed - 2.5) * 2.8, 0, 18))
		_viewer_label.text = "👁 %d" % v

	# プロンプトの明滅
	if is_instance_valid(_prompt_label) and _title_ready:
		_prompt_label.modulate.a = 0.4 + sin(_title_elapsed * 2.5) * 0.4

	# ランダムグリッチ（低確率）
	if randf() < 0.004:
		glitch_overlay.color = Color(randf_range(0.3, 0.7), 0.0, 0.0, randf_range(0.04, 0.12))
		get_tree().create_timer(randf_range(0.03, 0.06)).timeout.connect(
			func(): glitch_overlay.color = Color(1, 1, 1, 0)
		)


func _unhandled_input(event: InputEvent) -> void:
	var is_key   : bool = event is InputEventKey         and event.pressed and not event.echo
	var is_click : bool = event is InputEventMouseButton and event.pressed
	if not (is_key or is_click):
		return
	match _phase:
		Phase.VIDEO:
			return
		Phase.TITLE:
			if _title_ready:
				_advance_from_title()
		Phase.PROLOGUE:
			return


func _hide_all_panels() -> void:
	panel_title.visible      = false
	panel_profile.visible    = false
	panel_dm.visible         = false
	panel_monologue.visible  = false
	panel_caption.visible    = false
	panel_map_select.visible = false
	panel_start.visible      = false


# ──────────────────────────────────────────────
# タイトル画面（REC / LIVE / 視聴者数 / タイマー）
# ──────────────────────────────────────────────

func _run_title() -> void:
	panel_title.visible    = true
	panel_title.modulate.a = 0.0
	_build_title_hud()
	await get_tree().create_timer(0.3).timeout
	await _fade(panel_title, 1.0, 1.8)
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(_prompt_label):
		_prompt_label.visible = true
	_title_ready = true


func _build_title_hud() -> void:
	# ── 暗めオーバーレイ（コントラスト向上） ──
	var dark := ColorRect.new()
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark.color = Color(0, 0, 0, 0.25)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_title.add_child(dark)

	# ── REC ● ──
	_rec_label = Label.new()
	_rec_label.text = "●  REC"
	_rec_label.add_theme_font_size_override("font_size", 26)
	_rec_label.add_theme_color_override("font_color", Color(1.0, 0.12, 0.12, 1.0))
	_rec_label.position = Vector2(30, 22)
	_rec_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_title.add_child(_rec_label)

	# ── タイマー ──
	_time_label = Label.new()
	_time_label.text = "00:00:00"
	_time_label.add_theme_font_size_override("font_size", 20)
	_time_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.6))
	_time_label.position = Vector2(155, 26)
	_time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_title.add_child(_time_label)

	# ── LIVE バッジ（赤背景 + 白文字） ──
	var live_bg := ColorRect.new()
	live_bg.color = Color(0.88, 0.08, 0.08, 0.92)
	live_bg.size = Vector2(76, 30)
	live_bg.position = Vector2(280, 20)
	live_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_title.add_child(live_bg)

	var live_lbl := Label.new()
	live_lbl.text = "  LIVE"
	live_lbl.add_theme_font_size_override("font_size", 18)
	live_lbl.add_theme_color_override("font_color", Color.WHITE)
	live_lbl.position = Vector2(283, 23)
	live_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_title.add_child(live_lbl)

	# ── 視聴者数（右上） ──
	_viewer_label = Label.new()
	_viewer_label.text = "👁 0"
	_viewer_label.add_theme_font_size_override("font_size", 22)
	_viewer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.75))
	_viewer_label.anchor_left = 1.0
	_viewer_label.anchor_right = 1.0
	_viewer_label.offset_left = -120
	_viewer_label.offset_right = -20
	_viewer_label.offset_top = 24
	_viewer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_title.add_child(_viewer_label)

	# ── スタートプロンプト（画面下部） ──
	_prompt_label = Label.new()
	_prompt_label.text = "─── 画面をクリック / キーを押して開始 ───"
	_prompt_label.add_theme_font_size_override("font_size", 22)
	_prompt_label.add_theme_color_override("font_color", Color(0.88, 0.85, 0.80, 0.85))
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt_label.offset_top = -65
	_prompt_label.offset_bottom = -25
	_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_label.visible = false
	panel_title.add_child(_prompt_label)


func _advance_from_title() -> void:
	_title_ready = false
	_phase       = Phase.VIDEO
	await _fade(panel_title, 0.0, 1.1)
	panel_title.visible = false
	await get_tree().create_timer(0.1).timeout
	_play_video()


# ──────────────────────────────────────────────
# オープニング動画
# ──────────────────────────────────────────────

func _play_video() -> void:
	const VIDEO_PATH := "res://assets/video/opm.ogv"
	if not ResourceLoader.exists(VIDEO_PATH):
		_phase = Phase.PROLOGUE
		_run_sequence()
		return
	_video_player = VideoStreamPlayer.new()
	_video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	_video_player.expand = true
	_video_player.stream = load(VIDEO_PATH)
	add_child(_video_player)
	_video_player.play()
	_video_started = false
	_create_skip_button()


func _on_video_finished() -> void:
	_video_started = false
	_cleanup_video()
	_phase = Phase.PROLOGUE
	await get_tree().create_timer(0.3).timeout
	_run_sequence()


func _skip_video() -> void:
	if _phase != Phase.VIDEO:
		return
	_phase = Phase.PROLOGUE
	if _video_player and is_instance_valid(_video_player):
		_video_player.stop()
	_cleanup_video()
	_run_sequence()


func _create_skip_button() -> void:
	_remove_skip_button()
	_skip_btn = Button.new()
	_skip_btn.text = "スキップ ▶▶"
	_skip_btn.add_theme_font_size_override("font_size", 20)
	_skip_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_skip_btn.flat = true
	_skip_btn.anchor_left   = 1.0
	_skip_btn.anchor_top    = 0.0
	_skip_btn.anchor_right  = 1.0
	_skip_btn.anchor_bottom = 0.0
	_skip_btn.offset_left   = -190
	_skip_btn.offset_top    = 16
	_skip_btn.offset_right  = -16
	_skip_btn.offset_bottom = 56
	_skip_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	if _phase == Phase.VIDEO:
		_skip_btn.pressed.connect(_skip_video)
	else:
		_skip_btn.pressed.connect(_skip_to_start)
	add_child(_skip_btn)


func _remove_skip_button() -> void:
	if _skip_btn and is_instance_valid(_skip_btn):
		_skip_btn.queue_free()
	_skip_btn = null


func _cleanup_video() -> void:
	_remove_skip_button()
	if _video_player and is_instance_valid(_video_player):
		_video_player.queue_free()
	_video_player = null


# ──────────────────────────────────────────────
# プロローグ シーケンス
# ──────────────────────────────────────────────

func _skip_to_start() -> void:
	_skipped = true
	_remove_skip_button()
	_hide_all_panels()
	glitch_overlay.color = Color(1, 1, 1, 0)
	_go_to_game()


func _run_sequence() -> void:
	_create_skip_button()
	# パネル背景を追加（暗い半透明 + 赤アクセント線）
	_add_panel_bg(panel_profile)
	_add_panel_bg(panel_dm)
	_add_panel_bg(panel_monologue)
	await get_tree().create_timer(0.8).timeout

	# ━━ Panel 1: SNSプロフィール ━━
	panel_profile.visible    = true
	panel_profile.modulate.a = 0.0
	await _fade(panel_profile, 1.0, 0.7)
	if _skipped: return
	await _typewrite(profile_text, _profile_bbcode(), 0.018)
	if _skipped: return
	await get_tree().create_timer(2.5).timeout
	if _skipped: return
	await _fade(panel_profile, 0.0, 0.5)
	panel_profile.visible = false
	await get_tree().create_timer(0.5).timeout
	if _skipped: return

	# ━━ Panel 2: DM ━━
	panel_dm.visible    = true
	panel_dm.modulate.a = 0.0
	await _fade(panel_dm, 1.0, 0.5)
	if _skipped: return
	await _typewrite(dm_text, _dm_bbcode(), 0.022)
	if _skipped: return
	await get_tree().create_timer(0.6).timeout
	if _skipped: return
	await _do_glitch(5)
	if _skipped: return
	await get_tree().create_timer(1.5).timeout
	if _skipped: return
	await _fade(panel_dm, 0.0, 0.5)
	panel_dm.visible = false
	await get_tree().create_timer(0.3).timeout
	if _skipped: return

	# ━━ 恐怖インサート: 「見ている」 ━━
	await _scary_flash("見 て い る")
	if _skipped: return
	await get_tree().create_timer(0.6).timeout
	if _skipped: return

	# ━━ Panel 3: 主人公の独白 ━━
	panel_monologue.visible    = true
	panel_monologue.modulate.a = 0.0
	await _fade(panel_monologue, 1.0, 0.5)
	if _skipped: return
	await _typewrite(monologue_text, _monologue_bbcode(), 0.036)
	if _skipped: return
	await get_tree().create_timer(2.0).timeout
	if _skipped: return
	await _fade(panel_monologue, 0.0, 0.5)
	panel_monologue.visible = false
	await get_tree().create_timer(0.5).timeout
	if _skipped: return

	# ━━ Panel 4: 場所テロップ（タイプライト + グリッチ警告） ━━
	caption_text.text = ""
	caption_text.add_theme_font_size_override("font_size", 46)
	panel_caption.visible    = true
	panel_caption.modulate.a = 0.0
	await _fade(panel_caption, 1.0, 1.0)
	if _skipped: return
	# 一文字ずつ表示
	for line in ["霧 原 村", "", "深 夜   0 : 0 0"]:
		if line == "":
			caption_text.text += "\n"
			await get_tree().create_timer(0.5).timeout
		else:
			for ch in line:
				if _skipped: return
				caption_text.text += ch
				await get_tree().create_timer(0.07).timeout
			caption_text.text += "\n"
			await get_tree().create_timer(0.3).timeout
	if _skipped: return
	await get_tree().create_timer(2.5).timeout
	if _skipped: return
	await _caption_warning_glitch()
	if _skipped: return
	await get_tree().create_timer(1.0).timeout
	if _skipped: return
	await _fade(panel_caption, 0.0, 0.8)
	panel_caption.visible = false
	await get_tree().create_timer(0.5).timeout
	if _skipped: return

	# ━━ ゲームへ ━━
	_go_to_game()


# ──────────────────────────────────────────────
# ヘルパー
# ──────────────────────────────────────────────

func _add_panel_bg(panel: Control) -> void:
	## パネルに暗い背景 + 赤アクセントを追加
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.015, 0.02, 0.94)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)
	panel.move_child(bg, 0)
	# 上部の赤アクセント線
	var accent := ColorRect.new()
	accent.set_anchors_preset(Control.PRESET_TOP_WIDE)
	accent.offset_bottom = 2
	accent.color = Color(0.7, 0.08, 0.08, 0.6)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(accent)
	panel.move_child(accent, 1)


func _fade(node: CanvasItem, to: float, duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(node, "modulate:a", to, duration)
	await tw.finished


func _typewrite(label: RichTextLabel, bbcode: String, speed: float) -> void:
	label.bbcode_enabled     = true
	label.bbcode_text        = bbcode
	label.visible_characters = 0
	var total := label.get_total_character_count()
	for i in range(1, total + 1):
		if _skipped:
			label.visible_characters = -1
			return
		label.visible_characters = i
		await get_tree().create_timer(speed).timeout


func _do_glitch(count: int) -> void:
	for _i in range(count):
		if _skipped: return
		glitch_overlay.color = Color(
			randf_range(0.4, 0.9),
			randf_range(0.0, 0.12),
			randf_range(0.0, 0.12),
			randf_range(0.08, 0.25)
		)
		await get_tree().create_timer(randf_range(0.04, 0.09)).timeout
		glitch_overlay.color = Color(1, 1, 1, 0)
		await get_tree().create_timer(randf_range(0.03, 0.07)).timeout


func _scary_flash(text: String) -> void:
	## DM後の「見ている」フラッシュ演出
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 72)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.05, 0.05, 0.75))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	# 赤フラッシュ × 2
	glitch_overlay.color = Color(0.5, 0.0, 0.0, 0.2)
	await get_tree().create_timer(0.12).timeout
	if _skipped:
		lbl.queue_free()
		return
	glitch_overlay.color = Color(1, 1, 1, 0)
	await get_tree().create_timer(0.45).timeout
	if _skipped:
		lbl.queue_free()
		return
	glitch_overlay.color = Color(0.6, 0.0, 0.0, 0.15)
	await get_tree().create_timer(0.08).timeout
	glitch_overlay.color = Color(1, 1, 1, 0)
	await get_tree().create_timer(0.35).timeout
	lbl.queue_free()


func _caption_warning_glitch() -> void:
	## 「立入禁止」グリッチ警告
	var orig_text := caption_text.text
	caption_text.text = "⚠  立 入 禁 止  ⚠"
	caption_text.add_theme_color_override("font_color", Color(1.0, 0.06, 0.06, 1))
	caption_text.add_theme_font_size_override("font_size", 52)
	glitch_overlay.color = Color(0.7, 0.0, 0.0, 0.22)
	await get_tree().create_timer(0.15).timeout
	if _skipped: return
	glitch_overlay.color = Color(1, 1, 1, 0)
	await get_tree().create_timer(0.06).timeout
	glitch_overlay.color = Color(0.5, 0.0, 0.0, 0.18)
	await get_tree().create_timer(0.12).timeout
	caption_text.text = orig_text
	caption_text.remove_theme_color_override("font_color")
	caption_text.add_theme_font_size_override("font_size", 46)
	glitch_overlay.color = Color(1, 1, 1, 0)


func _go_to_game() -> void:
	_phase = Phase.DONE
	_remove_skip_button()
	GameManager.load_chapter(0)
	_hide_all_panels()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.3)
	await tw.finished
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


# ──────────────────────────────────────────────
# テキストコンテンツ（大きいフォント・リッチ演出）
# ──────────────────────────────────────────────

func _profile_bbcode() -> String:
	var s := ""
	s += "[center][color=#444444]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color][/center]\n"
	s += "[center][color=#888888][font_size=20]SnapshotTube[/font_size][/color][/center]\n"
	s += "[center][color=#444444]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color][/center]\n\n"
	s += "[color=#f0f0f0][font_size=30][b]しゅっち ch[/b][/font_size][/color]"
	s += "   [color=#777777][font_size=20]@shucchi_horror[/font_size][/color]\n\n"
	s += "[color=#cccccc][font_size=22]JK配信者 / ホラー凸 / 心霊スポット巡り[/font_size][/color]\n"
	s += "[color=#bbbbbb][font_size=22]「配信で一発当てて、人生変えてやる」[/font_size][/color]\n\n"
	s += "[color=#888888][font_size=22]▶ 動画  [color=#ffffff]7 本[/color]　　"
	s += "👥 [color=#ffffff]347[/color] 人登録[/font_size][/color]\n\n"
	s += "[color=#333333]──────────────────────────────────[/color]\n"
	s += "[color=#666666][font_size=19]最近の投稿[/font_size][/color]\n"
	s += "[color=#555555][font_size=18]　・深夜の廃病院、制服で行ってみた（再生数 210）\n"
	s += "　・心霊スポット行ったけど何も起きなかった（再生数 83）\n"
	s += "　・廃トンネルに潜入したら…（再生数 41）[/font_size][/color]\n\n"
	s += "[color=#333333]──────────────────────────────────[/color]\n"
	s += "[color=#993333][font_size=18]　収益化まであと [color=#ff4444]653人[/color]……[/font_size][/color]"
	return s


func _dm_bbcode() -> String:
	var s := ""
	s += "[color=#888888][font_size=22]✉  ダイレクトメッセージ[/font_size][/color]\n\n"
	s += "[color=#ff2222][font_size=24][b]⚠ アカウント削除済み[/b][/font_size][/color]"
	s += "   [color=#555555][font_size=18]23:47[/font_size][/color]\n"
	s += "[color=#333333]──────────────────────────────────────[/color]\n\n"
	s += "[color=#dddddd][font_size=24]はじめまして。しゅっちさんですよね。[/font_size][/color]\n\n"
	s += "[color=#f0f0f0][font_size=26][b]今夜、霧原村に行ってみてください。[/b][/font_size][/color]\n\n"
	s += "[color=#dddddd][font_size=22]1994年に「事件」があった廃村です。\n"
	s += "倉庫にVHSテープが残っているはず。\n"
	s += "配信すれば…間違いなく、バズります。[/font_size][/color]\n\n"
	s += "[color=#333333]──────────────────────────────────────[/color]\n\n"
	s += "[color=#dddddd][font_size=22]場所は県道沿い、霧の多い山道を進んだ先。\n\n"
	s += "[b]必ず、深夜0時に入ってください。[/b][/font_size][/color]\n\n"
	s += "[color=#993333][font_size=22][i]…あなたのこと、見ています。[/i][/font_size][/color]"
	return s


func _monologue_bbcode() -> String:
	var s := ""
	s += "[color=#555555][font_size=20][i]（ 自室、深夜 ── スマホの画面を見つめて ）[/i][/font_size][/color]\n\n\n"
	s += "[color=#f0f0f0][font_size=28]「…怪しいDM。アカウントも消えてるし」[/font_size][/color]\n\n"
	s += "[color=#cccccc][font_size=26]「でも……廃村にVHSテープ、か」[/font_size][/color]\n\n"
	s += "[color=#cccccc][font_size=26]「本物だったらマジでバズるかも」[/font_size][/color]\n\n"
	s += "[color=#aaaaaa][font_size=24]「再生数ぜんっぜん伸びない。登録者347人」[/font_size][/color]\n"
	s += "[color=#aaaaaa][font_size=24]「収益化なんて夢のまた夢」[/font_size][/color]\n\n"
	s += "[color=#999999][font_size=24]「来月の携帯代も怪しいのに」[/font_size][/color]\n"
	s += "[color=#999999][font_size=24]「お母さんにはこれ以上頼れない……」[/font_size][/color]\n\n"
	s += "[color=#bbbbbb][font_size=26]「あたしには配信しかないんだ」[/font_size][/color]\n"
	s += "[color=#999999][font_size=24]「誰かが見てくれてる限り、あたしは大丈夫」[/font_size][/color]\n\n\n"
	s += "[color=#555555][font_size=20][i]（ ── 深夜0時。霧原村行き最終バスに乗り込んだ ）[/i][/font_size][/color]\n\n"
	s += "[color=#ffffff][font_size=34][b]「── 行くしかない」[/b][/font_size][/color]"
	return s
