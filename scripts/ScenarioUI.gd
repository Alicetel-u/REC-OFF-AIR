extends CanvasLayer
class_name ScenarioUI

## 視聴者投票パネル + 配信者セリフ字幕
## コードのみでUIを構築する

signal choice_made(scenario: Dictionary, choice_idx: int)

const VOTE_DURATION     := 20.0
const RESPONSE_DURATION := 3.5

# YouTube 配色
const COL_BG      := Color(0.06, 0.06, 0.06, 0.93)
const COL_BORDER  := Color(0.22, 0.22, 0.22, 1.0)
const COL_TEXT    := Color(1.0,  1.0,  1.0,  1.0)
const COL_MUTED   := Color(0.65, 0.65, 0.65, 1.0)
const COL_BLUE    := Color(0.24, 0.54, 0.99, 1.0)  # 投票バー

# レイアウト定数 (1280x720 基準)
const BOTTOM_BAR_H := 64
const RIGHT_PANEL_W := 320

var _scenario: Dictionary = {}
var _choice_btns : Array[Button]      = []
var _vote_bars   : Array[ProgressBar] = []
var _vote_labels : Array[Label]       = []
var _vote_targets: Array[float]       = []
var _vote_current: Array[float]       = []

var _timer_bar    : ProgressBar
var _timer_elapsed: float = 0.0
var _voting_active: bool  = false

var _panel          : PanelContainer
var _response_panel : PanelContainer
var _response_label : Label
var _prompt_label   : Label


func _ready() -> void:
	layer = 8  # HUD(2) より上、IntroLayer(5) より上、OverlayLayer(10) より下
	_build_poll_panel()
	_build_response_panel()
	visible = false


# ── 投票パネル ────────────────────────────────────────────────

func _build_poll_panel() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	# 左下から: BottomBar分上げた位置に配置
	_panel.position = Vector2(20, -(220 + BOTTOM_BAR_H))
	_panel.custom_minimum_size = Vector2(390, 0)
	_panel.add_theme_stylebox_override("panel", _make_stylebox(COL_BG, COL_BORDER, 6))
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	# タイトル行
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 6)
	vbox.add_child(title_row)
	_add_label(title_row, "📊", 14, COL_MUTED)
	_add_label(title_row, "視聴者アンケート", 12, COL_MUTED)

	# プロンプト
	_prompt_label = _add_label(vbox, "", 15, COL_TEXT)
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.28, 0.28, 0.28))
	vbox.add_child(sep)

	# 3択
	const LABELS: Array[String] = ["A", "B", "C"]
	for i in range(3):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)

		var btn := Button.new()
		btn.text = ""
		btn.custom_minimum_size = Vector2(160, 28)
		btn.add_theme_font_size_override("font_size", 12)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_stylebox_override("normal",  _make_stylebox(Color(0.14, 0.14, 0.14), COL_BORDER, 4))
		btn.add_theme_stylebox_override("hover",   _make_stylebox(Color(0.22, 0.22, 0.22), COL_BORDER, 4))
		btn.add_theme_stylebox_override("pressed", _make_stylebox(Color(0.08, 0.08, 0.08), COL_BORDER, 4))
		var idx := i
		btn.pressed.connect(func() -> void: _on_choice(idx))
		row.add_child(btn)
		_choice_btns.append(btn)

		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = 0
		bar.custom_minimum_size = Vector2(130, 20)
		bar.show_percentage = false
		bar.add_theme_stylebox_override("background", _make_stylebox(Color(0.18, 0.18, 0.18), Color.TRANSPARENT, 3))
		bar.add_theme_stylebox_override("fill",       _make_stylebox(COL_BLUE, Color.TRANSPARENT, 3))
		row.add_child(bar)
		_vote_bars.append(bar)

		var pct := _add_label(row, "0%", 12, COL_MUTED)
		pct.custom_minimum_size = Vector2(38, 0)
		_vote_labels.append(pct)

	# タイマーバー
	_timer_bar = ProgressBar.new()
	_timer_bar.min_value = 0
	_timer_bar.max_value = 100
	_timer_bar.value = 100
	_timer_bar.custom_minimum_size = Vector2(0, 4)
	_timer_bar.show_percentage = false
	_timer_bar.add_theme_stylebox_override("background", _make_stylebox(Color(0.2, 0.2, 0.2), Color.TRANSPARENT, 2))
	_timer_bar.add_theme_stylebox_override("fill",       _make_stylebox(Color(1, 0, 0), Color.TRANSPARENT, 2))
	vbox.add_child(_timer_bar)


# ── 配信者セリフ字幕 ──────────────────────────────────────────

func _build_response_panel() -> void:
	_response_panel = PanelContainer.new()
	_response_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_response_panel.position = Vector2(20, -(44 + BOTTOM_BAR_H))
	_response_panel.custom_minimum_size = Vector2(620, 36)
	_response_panel.add_theme_stylebox_override("panel", _make_stylebox(Color(0, 0, 0, 0.78), Color.TRANSPARENT, 4))
	_response_panel.visible = false
	add_child(_response_panel)

	_response_label = _add_label(_response_panel, "", 14, COL_TEXT)


# ── 公開 API ──────────────────────────────────────────────────

func show_scenario(scenario: Dictionary) -> void:
	_scenario = scenario
	var choices: Array = scenario["choices"]

	_prompt_label.text = scenario["prompt"]
	_vote_targets.clear()
	_vote_current.clear()

	for i in range(3):
		_choice_btns[i].text = "  [%s]  %s" % [["A","B","C"][i], choices[i]["text"]]
		_vote_bars[i].value = 0
		_vote_labels[i].text = "0%"
		_vote_targets.append(randf_range(15.0, 65.0))
		_vote_current.append(0.0)

	# 合計100%に正規化
	var total: float = 0.0
	for v: float in _vote_targets:
		total += v
	for i in range(3):
		_vote_targets[i] = (_vote_targets[i] / total) * 100.0

	_timer_elapsed = 0.0
	_voting_active = true
	_timer_bar.value = 100
	_panel.visible = true
	visible = true


# ── 内部処理 ──────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _voting_active:
		return

	_timer_elapsed += delta
	_timer_bar.value = (1.0 - _timer_elapsed / VOTE_DURATION) * 100.0

	# 投票数アニメーション
	for i in range(3):
		_vote_current[i] = move_toward(_vote_current[i], _vote_targets[i], delta * 10.0)
		_vote_bars[i].value = _vote_current[i]
		_vote_labels[i].text = "%d%%" % int(_vote_current[i])

	if _timer_elapsed >= VOTE_DURATION:
		# タイムアウト → 最多票を自動選択
		var best := 0
		for i in range(1, 3):
			if _vote_targets[i] > _vote_targets[best]:
				best = i
		_on_choice(best)


func _on_choice(idx: int) -> void:
	if not _voting_active:
		return
	_voting_active = false
	_panel.visible = false

	var choice: Dictionary = _scenario["choices"][idx]
	_show_response(choice["response"])
	choice_made.emit(_scenario, idx)


func _show_response(text: String) -> void:
	_response_label.text = "  ▶  「%s」" % text
	_response_panel.visible = true
	await get_tree().create_timer(RESPONSE_DURATION).timeout
	_response_panel.visible = false
	visible = false
	_panel.visible = true  # 次回 show_scenario 用にリセット


# ── ヘルパー ──────────────────────────────────────────────────

func _make_stylebox(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	if border != Color.TRANSPARENT:
		s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	return s


func _add_label(parent: Node, text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l
