extends Control

# ── ノード参照 ──
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

enum Phase { TITLE, PROLOGUE, MAP_SELECT, DONE }

var _phase       : Phase = Phase.TITLE
var _title_ready : bool  = false
var _skipped     : bool  = false


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_hide_all_panels()
	glitch_overlay.color = Color(1, 1, 1, 0)
	_run_title()


func _unhandled_input(event: InputEvent) -> void:
	var is_key   : bool = event is InputEventKey         and event.pressed and not event.echo
	var is_click : bool = event is InputEventMouseButton and event.pressed
	if not (is_key or is_click):
		return

	match _phase:
		Phase.TITLE:
			if _title_ready:
				_advance_from_title()
		Phase.PROLOGUE:
			if not _skipped:
				_skip_to_start()


func _hide_all_panels() -> void:
	panel_title.visible      = false
	panel_profile.visible    = false
	panel_dm.visible         = false
	panel_monologue.visible  = false
	panel_caption.visible    = false
	panel_map_select.visible = false
	panel_start.visible      = false


# ──────────────────────────────────────────────
# タイトル画面
# ──────────────────────────────────────────────

func _run_title() -> void:
	panel_title.visible    = true
	panel_title.modulate.a = 0.0
	await get_tree().create_timer(0.4).timeout
	await _fade(panel_title, 1.0, 1.6)
	_title_ready = true


func _advance_from_title() -> void:
	_title_ready = false             # 二重起動防止
	_phase       = Phase.PROLOGUE
	await _fade(panel_title, 0.0, 1.1)
	panel_title.visible = false
	await get_tree().create_timer(0.3).timeout
	_run_sequence()


# ──────────────────────────────────────────────
# プロローグ シーケンス
# ──────────────────────────────────────────────

func _skip_to_start() -> void:
	_skipped = true
	_hide_all_panels()
	glitch_overlay.color = Color(1, 1, 1, 0)
	_show_map_select()


func _run_sequence() -> void:
	await get_tree().create_timer(1.0).timeout

	# ━━ Panel 1: SNS プロフィール ━━
	panel_profile.visible    = true
	panel_profile.modulate.a = 0.0
	await _fade(panel_profile, 1.0, 0.7)
	if _skipped: return
	await _typewrite(profile_text, _profile_bbcode(), 0.022)
	if _skipped: return
	await get_tree().create_timer(2.0).timeout
	if _skipped: return
	await _fade(panel_profile, 0.0, 0.5)
	panel_profile.visible = false
	await get_tree().create_timer(0.4).timeout
	if _skipped: return

	# ━━ Panel 2: DM ━━
	panel_dm.visible    = true
	panel_dm.modulate.a = 0.0
	await _fade(panel_dm, 1.0, 0.5)
	if _skipped: return
	await _typewrite(dm_text, _dm_bbcode(), 0.026)
	if _skipped: return
	await get_tree().create_timer(0.5).timeout
	if _skipped: return
	await _do_glitch(4)
	if _skipped: return
	await get_tree().create_timer(1.2).timeout
	if _skipped: return
	await _fade(panel_dm, 0.0, 0.5)
	panel_dm.visible = false
	await get_tree().create_timer(0.4).timeout
	if _skipped: return

	# ━━ Panel 3: 主人公の独白 ━━
	panel_monologue.visible    = true
	panel_monologue.modulate.a = 0.0
	await _fade(panel_monologue, 1.0, 0.5)
	if _skipped: return
	await _typewrite(monologue_text, _monologue_bbcode(), 0.048)
	if _skipped: return
	await get_tree().create_timer(1.8).timeout
	if _skipped: return
	await _fade(panel_monologue, 0.0, 0.5)
	panel_monologue.visible = false
	await get_tree().create_timer(0.4).timeout
	if _skipped: return

	# ━━ Panel 4: 場所テロップ ━━
	panel_caption.visible    = true
	panel_caption.modulate.a = 0.0
	await _fade(panel_caption, 1.0, 0.9)
	if _skipped: return
	await get_tree().create_timer(2.8).timeout
	if _skipped: return
	await _caption_warning_glitch()
	if _skipped: return
	await get_tree().create_timer(1.2).timeout
	if _skipped: return
	await _fade(panel_caption, 0.0, 0.7)
	panel_caption.visible = false
	await get_tree().create_timer(0.5).timeout
	if _skipped: return

	# ━━ マップ選択画面へ ━━
	_show_map_select()


# ──────────────────────────────────────────────
# ヘルパー
# ──────────────────────────────────────────────

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
			randf_range(0.0, 0.15),
			randf_range(0.0, 0.15),
			randf_range(0.08, 0.22)
		)
		await get_tree().create_timer(randf_range(0.04, 0.09)).timeout
		glitch_overlay.color = Color(1, 1, 1, 0)
		await get_tree().create_timer(randf_range(0.03, 0.07)).timeout


func _caption_warning_glitch() -> void:
	var orig_text := caption_text.text
	caption_text.text = "⚠  立入禁止  無断侵入  ⚠"
	caption_text.add_theme_color_override("font_color", Color(1.0, 0.08, 0.08, 1))
	glitch_overlay.color = Color(0.7, 0.0, 0.0, 0.18)
	await get_tree().create_timer(0.22).timeout
	caption_text.text = orig_text
	caption_text.remove_theme_color_override("font_color")
	glitch_overlay.color = Color(1, 1, 1, 0)


func _show_map_select() -> void:
	_phase = Phase.DONE
	GameManager.selected_map_type = 0  # 廃工場固定
	_hide_all_panels()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.3)
	await tw.finished
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


# ──────────────────────────────────────────────
# テキストコンテンツ
# ──────────────────────────────────────────────

func _profile_bbcode() -> String:
	var s := "[color=#666666]━━━  SnapshotTube  ━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]\n\n"
	s += "[color=#f0f0f0][font_size=22][b]夜道 サクラ[/b][/font_size][/color]"
	s += "   [color=#888888]@yami_sakura_ch[/color]\n\n"
	s += "[color=#cccccc]廃墟探索 × ホラー配信　女子高生 YouTuber\n"
	s += "「見てくれる人がいる限り、どこでも行く」[/color]\n\n"
	s += "[color=#888888]▶ 動画  [color=#ffffff]12 本[/color]　　"
	s += "👥 [color=#ffffff]12,847[/color] 人登録[/color]\n\n"
	s += "[color=#444444]─────────────────────────────────────────────[/color]\n"
	s += "[color=#555555]最近の投稿\n"
	s += "　・廃病院に一人で行ったら本当に怖かった話\n"
	s += "　・夜の工場地帯、侵入して追いかけられた[/color]"
	return s


func _dm_bbcode() -> String:
	var s := "[color=#888888]✉  ダイレクトメッセージ[/color]\n\n"
	s += "[color=#ff3333][b]⚠ アカウント削除済み[/b][/color]   [color=#555555]23:02[/color]\n"
	s += "[color=#3a3a3a]─────────────────────────────────────────────[/color]\n\n"
	s += "[color=#dddddd]はじめまして。夜道サクラさんですよね。\n\n"
	s += "廃工場に [b]VHS テープを 5 本[/b]、\n"
	s += "置き忘れてしまいました。\n\n"
	s += "取ってきてもらえますか？\n"
	s += "謝礼はします。[/color]\n\n"
	s += "[color=#3a3a3a]─────────────────────────────────────────────[/color]\n\n"
	s += "[color=#dddddd]場所は「旧ヤマネ精工　第三工場跡」です。\n\n"
	s += "[b]必ず、5 本全部、持ってきてください。[/b][/color]"
	return s


func _monologue_bbcode() -> String:
	var s := "[color=#555555][i]（自室、深夜 ── 画面の外）[/i][/color]\n\n"
	s += "[color=#ffffff]「…あやしすぎる」[/color]\n\n"
	s += "[color=#cccccc]「でも廃工場か……」[/color]\n\n"
	s += "[color=#cccccc]「絶対バズるじゃん」[/color]\n\n"
	s += "[color=#aaaaaa]「配信してる間は大丈夫でしょ。\n視聴者もいるし。」[/color]\n\n"
	s += "[color=#ffffff][font_size=22][b]「──行こう。」[/b][/font_size][/color]"
	return s
