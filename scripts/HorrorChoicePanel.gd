extends CanvasLayer

## ホラー特化の3択パネル — グリッチ演出 + 視聴者投票風
## EntranceDirector の "choice" イベントから呼ばれる

signal choice_selected(index: int)

const VOTE_DURATION := 25.0  # 25秒で自動決定

# ── カラーパレット ──
const COL_OVERLAY   := Color(0.0, 0.0, 0.0, 0.75)
const COL_PANEL     := Color(0.04, 0.02, 0.02, 0.95)
const COL_BORDER    := Color(0.6, 0.08, 0.08, 0.8)
const COL_TEXT      := Color(0.92, 0.90, 0.88, 1.0)
const COL_MUTED     := Color(0.55, 0.45, 0.45, 1.0)
const COL_RED       := Color(0.9, 0.12, 0.12, 1.0)
const COL_HOVER     := Color(0.18, 0.06, 0.06, 1.0)
const COL_VOTE_BAR  := Color(0.7, 0.10, 0.10, 0.85)

var _voting_active := false
var _timer_elapsed := 0.0
var _glitch_timer  := 0.0

var _overlay       : ColorRect
var _panel         : PanelContainer
var _prompt_label  : RichTextLabel
var _timer_bar     : ProgressBar
var _choice_btns   : Array[Button]      = []
var _vote_bars     : Array[ProgressBar] = []
var _vote_labels   : Array[Label]       = []
var _sub_labels    : Array[Label]       = []
var _vote_targets  : Array[float]       = []
var _vote_current  : Array[float]       = []
var _glitch_label  : Label  # グリッチテキスト用
var _prev_mouse_mode : int = Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	layer = 25  # 全UIの最前面
	visible = false


func show_choice(prompt: String, choices: Array) -> void:
	# マウスカーソルを表示（シネマティック中はCAPTURED状態のため）
	_prev_mouse_mode = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build_ui(prompt, choices)
	_start_vote(choices)


func _build_ui(prompt: String, choices: Array) -> void:
	# 既存UIをクリア
	for child in get_children():
		child.queue_free()
	_choice_btns.clear()
	_vote_bars.clear()
	_vote_labels.clear()
	_sub_labels.clear()
	_vote_targets.clear()
	_vote_current.clear()

	# ── 半透明オーバーレイ ──
	_overlay = ColorRect.new()
	_overlay.color = COL_OVERLAY
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.size = Vector2(1280, 720)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # クリックを透過
	add_child(_overlay)

	# ── グリッチテキスト（背景に薄く流れる） ──
	_glitch_label = Label.new()
	_glitch_label.text = "見ている 見ている 見ている 見ている 見ている 見ている "
	_glitch_label.add_theme_font_size_override("font_size", 72)
	_glitch_label.add_theme_color_override("font_color", Color(0.15, 0.03, 0.03, 0.25))
	_glitch_label.position = Vector2(-100, 280)
	_glitch_label.rotation = deg_to_rad(-8)
	_glitch_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # クリックを透過
	add_child(_glitch_label)

	# ── メインパネル ──
	_panel = PanelContainer.new()
	_panel.position = Vector2(170, 110)
	_panel.custom_minimum_size = Vector2(600, 0)
	_panel.size = Vector2(600, 500)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COL_PANEL
	panel_style.border_color = COL_BORDER
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(20)
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(vbox)

	# ── タイトル ──
	var title := RichTextLabel.new()
	title.bbcode_enabled = true
	title.fit_content = true
	title.scroll_active = false
	title.bbcode_text = "[center][color=#ff3333][font_size=20]▼  最 後 の 選 択  ▼[/font_size][/color][/center]"
	vbox.add_child(title)

	# ── お札残数 ──
	var ofuda_row := HBoxContainer.new()
	ofuda_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ofuda_row.add_theme_constant_override("separation", 4)
	vbox.add_child(ofuda_row)
	var ofuda_label := Label.new()
	ofuda_label.text = "残りのお札: %d枚" % GameManager.ofuda_count
	ofuda_label.add_theme_font_size_override("font_size", 13)
	ofuda_label.add_theme_color_override("font_color", COL_MUTED)
	ofuda_row.add_child(ofuda_label)

	# ── 区切り線 ──
	var sep1 := HSeparator.new()
	sep1.add_theme_color_override("color", Color(0.35, 0.1, 0.1, 0.6))
	vbox.add_child(sep1)

	# ── プロンプト ──
	_prompt_label = RichTextLabel.new()
	_prompt_label.bbcode_enabled = true
	_prompt_label.fit_content = true
	_prompt_label.scroll_active = false
	_prompt_label.bbcode_text = "[color=#ddcccc][font_size=15]%s[/font_size][/color]" % prompt
	vbox.add_child(_prompt_label)

	# ── 区切り線 ──
	var sep2 := HSeparator.new()
	sep2.add_theme_color_override("color", Color(0.35, 0.1, 0.1, 0.6))
	vbox.add_child(sep2)

	# ── 3択 ──
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var choice_container := VBoxContainer.new()
		choice_container.add_theme_constant_override("separation", 2)
		vbox.add_child(choice_container)

		# 選択肢ボタン行
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		choice_container.add_child(row)

		var btn := Button.new()
		btn.text = "  [%s]  %s" % [["A","B","C"][i], choice.get("text", "")]
		btn.custom_minimum_size = Vector2(360, 36)
		btn.add_theme_font_size_override("font_size", 14)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0.10, 0.04, 0.04, 0.9)
		normal_style.border_color = Color(0.4, 0.12, 0.12, 0.7)
		normal_style.set_border_width_all(1)
		normal_style.set_corner_radius_all(3)
		normal_style.set_content_margin_all(6)
		btn.add_theme_stylebox_override("normal", normal_style)
		var hover_style := normal_style.duplicate()
		hover_style.bg_color = COL_HOVER
		hover_style.border_color = COL_RED
		btn.add_theme_stylebox_override("hover", hover_style)
		var pressed_style := normal_style.duplicate()
		pressed_style.bg_color = Color(0.05, 0.02, 0.02, 1.0)
		btn.add_theme_stylebox_override("pressed", pressed_style)
		btn.add_theme_color_override("font_color", COL_TEXT)
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.85, 0.85))
		var idx := i
		btn.pressed.connect(func() -> void: _on_choice(idx))
		row.add_child(btn)
		_choice_btns.append(btn)

		# 投票バー
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = 0
		bar.custom_minimum_size = Vector2(140, 24)
		bar.show_percentage = false
		var bar_bg := StyleBoxFlat.new()
		bar_bg.bg_color = Color(0.12, 0.06, 0.06, 0.8)
		bar_bg.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("background", bar_bg)
		var bar_fill := StyleBoxFlat.new()
		bar_fill.bg_color = COL_VOTE_BAR
		bar_fill.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("fill", bar_fill)
		row.add_child(bar)
		_vote_bars.append(bar)

		# パーセント表示
		var pct := Label.new()
		pct.text = "0%"
		pct.custom_minimum_size = Vector2(40, 0)
		pct.add_theme_font_size_override("font_size", 13)
		pct.add_theme_color_override("font_color", COL_MUTED)
		row.add_child(pct)
		_vote_labels.append(pct)

		# サブテキスト（選択肢の補足説明）
		var sub := Label.new()
		sub.text = "　　　%s" % choice.get("sub", "")
		sub.add_theme_font_size_override("font_size", 11)
		sub.add_theme_color_override("font_color", Color(0.5, 0.4, 0.4, 0.7))
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choice_container.add_child(sub)
		_sub_labels.append(sub)

	# ── タイマーバー ──
	_timer_bar = ProgressBar.new()
	_timer_bar.min_value = 0
	_timer_bar.max_value = 100
	_timer_bar.value = 100
	_timer_bar.custom_minimum_size = Vector2(0, 5)
	_timer_bar.show_percentage = false
	var timer_bg := StyleBoxFlat.new()
	timer_bg.bg_color = Color(0.15, 0.08, 0.08, 0.8)
	timer_bg.set_corner_radius_all(2)
	_timer_bar.add_theme_stylebox_override("background", timer_bg)
	var timer_fill := StyleBoxFlat.new()
	timer_fill.bg_color = COL_RED
	timer_fill.set_corner_radius_all(2)
	_timer_bar.add_theme_stylebox_override("fill", timer_fill)
	vbox.add_child(_timer_bar)

	# ── フッター ──
	var footer := Label.new()
	footer.text = "視聴者の投票が反映されます…"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", Color(0.4, 0.3, 0.3, 0.5))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(footer)


func _start_vote(choices: Array) -> void:
	_vote_targets.clear()
	_vote_current.clear()
	# 投票ターゲット生成 — BAD END(C)が最初は人気に見える演出
	var targets := [30.0, 15.0, 55.0]  # A=30%, B=15%, C=55%
	for i in range(choices.size()):
		_vote_targets.append(targets[i] if i < targets.size() else 20.0)
		_vote_current.append(0.0)

	_timer_elapsed = 0.0
	_glitch_timer = 0.0
	_voting_active = true
	visible = true

	# フェードイン
	_overlay.modulate.a = 0.0
	_panel.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_overlay, "modulate:a", 1.0, 0.5)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.8).set_delay(0.2)


func _process(delta: float) -> void:
	if not _voting_active:
		return

	_timer_elapsed += delta
	var ratio := 1.0 - _timer_elapsed / VOTE_DURATION
	_timer_bar.value = ratio * 100.0

	# 投票アニメーション
	for i in range(_vote_targets.size()):
		_vote_current[i] = move_toward(_vote_current[i], _vote_targets[i], delta * 8.0)
		if i < _vote_bars.size():
			_vote_bars[i].value = _vote_current[i]
		if i < _vote_labels.size():
			_vote_labels[i].text = "%d%%" % int(_vote_current[i])

	# グリッチ演出
	_glitch_timer += delta
	if is_instance_valid(_glitch_label):
		_glitch_label.position.x = -100 + sin(_glitch_timer * 0.7) * 20
		# 残り5秒でグリッチ激化
		if ratio < 0.2:
			_glitch_label.modulate.a = 0.25 + sin(_glitch_timer * 12.0) * 0.15
			if is_instance_valid(_panel):
				_panel.position.x = 170 + sin(_glitch_timer * 20.0) * (2.0 if ratio < 0.1 else 1.0)

	# タイムアウト → BAD END(C)を自動選択
	if _timer_elapsed >= VOTE_DURATION:
		_on_choice(2)


func _on_choice(idx: int) -> void:
	if not _voting_active:
		return
	_voting_active = false

	# 選択したボタンをハイライト
	for i in range(_choice_btns.size()):
		_choice_btns[i].disabled = true
		if i == idx:
			var sel_style := StyleBoxFlat.new()
			sel_style.bg_color = Color(0.5, 0.08, 0.08, 0.9)
			sel_style.border_color = COL_RED
			sel_style.set_border_width_all(2)
			sel_style.set_corner_radius_all(3)
			sel_style.set_content_margin_all(6)
			_choice_btns[i].add_theme_stylebox_override("disabled", sel_style)

	# フェードアウト後にシグナル発火
	await get_tree().create_timer(1.5).timeout
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_overlay, "modulate:a", 0.0, 0.6)
	tw.tween_property(_panel, "modulate:a", 0.0, 0.6)
	await tw.finished
	visible = false
	# マウスモードを元に戻す
	Input.set_mouse_mode(_prev_mouse_mode)
	choice_selected.emit(idx)
