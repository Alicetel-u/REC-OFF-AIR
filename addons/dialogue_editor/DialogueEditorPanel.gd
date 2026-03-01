@tool
extends Control

# ── 定数 ────────────────────────────────────────────────────────────
const JSON_PATH := "res://dialogue/ch01_entrance.json"

# タイプごとの背景色（エディタ暗色テーマに合わせた彩度低め）
const TYPE_BG : Dictionary = {
	"say":           Color(0.32, 0.20, 0.04, 0.85),   # 橙
	"say_clear":     Color(0.22, 0.14, 0.04, 0.85),   # 暗橙
	"chat":          Color(0.06, 0.18, 0.35, 0.85),   # 青
	"wait":          Color(0.18, 0.18, 0.18, 0.85),   # 灰
	"rot_y":         Color(0.06, 0.28, 0.10, 0.85),   # 緑
	"head_x":        Color(0.06, 0.22, 0.10, 0.85),   # 深緑
	"pos_z":         Color(0.10, 0.30, 0.14, 0.85),   # 緑2
	"pos_z_await":   Color(0.08, 0.22, 0.12, 0.85),   # 緑3
	"walk_set":      Color(0.22, 0.28, 0.06, 0.85),   # 黄緑
	"flashlight_on": Color(0.30, 0.26, 0.02, 0.85),   # 黄
}
const TYPE_LABEL_COLOR : Dictionary = {
	"say":           Color(1.00, 0.75, 0.35),
	"say_clear":     Color(0.80, 0.60, 0.30),
	"chat":          Color(0.55, 0.85, 1.00),
	"wait":          Color(0.70, 0.70, 0.70),
	"rot_y":         Color(0.45, 1.00, 0.55),
	"head_x":        Color(0.35, 0.90, 0.50),
	"pos_z":         Color(0.50, 1.00, 0.60),
	"pos_z_await":   Color(0.40, 0.85, 0.55),
	"walk_set":      Color(0.80, 1.00, 0.35),
	"flashlight_on": Color(1.00, 0.95, 0.35),
}

# ── 内部状態 ─────────────────────────────────────────────────────────
var _events    : Array  = []
var _rows_box  : VBoxContainer = null
var _status_lbl: Label         = null
var _dirty     : bool  = false


# ════════════════════════════════════════════════════════════════════
# 初期化
# ════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_build_ui()
	_load_json()


# ════════════════════════════════════════════════════════════════════
# UI 構築
# ════════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2(0, 220)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_vbox)

	# ── ツールバー ──────────────────────────────────────────────────
	var toolbar := HBoxContainer.new()
	toolbar.custom_minimum_size.y = 30
	root_vbox.add_child(toolbar)

	var file_lbl := Label.new()
	file_lbl.text = JSON_PATH
	file_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	file_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(file_lbl)

	_status_lbl = Label.new()
	_status_lbl.text = ""
	_status_lbl.custom_minimum_size.x = 80
	toolbar.add_child(_status_lbl)

	_make_toolbar_btn(toolbar, "Reload", _load_json)
	_make_toolbar_btn(toolbar, "Save",   _save_json)

	var sep1 := VSeparator.new()
	sep1.custom_minimum_size.x = 8
	toolbar.add_child(sep1)

	_make_toolbar_btn(toolbar, "+ say",   func(): _insert_event({"type": "say",  "text": ""}))
	_make_toolbar_btn(toolbar, "+ chat",  func(): _insert_event({"type": "chat", "msg": "", "user": "", "utype": ""}))
	_make_toolbar_btn(toolbar, "+ wait",  func(): _insert_event({"type": "wait", "sec": 0.5}))
	_make_toolbar_btn(toolbar, "+ rot_y", func(): _insert_event({"type": "rot_y","target": 0.0, "dur": 1.0}))
	_make_toolbar_btn(toolbar, "+ head_x",func(): _insert_event({"type": "head_x","target": 0.0, "dur": 1.0}))
	_make_toolbar_btn(toolbar, "+ pos_z", func(): _insert_event({"type": "pos_z","target": 0.0, "dur": 5.0, "id": "walk1"}))

	# ── ヘッダー行 ──────────────────────────────────────────────────
	var header_bg := PanelContainer.new()
	root_vbox.add_child(header_bg)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 22
	header_bg.add_child(header)

	_make_header_lbl(header, "#",        36)
	_make_header_lbl(header, "Type",     96)
	_make_header_lbl(header, "Content",  -1)   # expand
	_make_header_lbl(header, "Actions",  96)

	# ── スクロール可能なイベントリスト ──────────────────────────────
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	_rows_box = VBoxContainer.new()
	_rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_box.add_theme_constant_override("separation", 1)
	scroll.add_child(_rows_box)


# ════════════════════════════════════════════════════════════════════
# JSON ロード / セーブ
# ════════════════════════════════════════════════════════════════════

func _load_json() -> void:
	var abs_path := ProjectSettings.globalize_path(JSON_PATH)
	if not FileAccess.file_exists(abs_path):
		_set_status("File not found", Color(1, 0.4, 0.4))
		return

	var text := FileAccess.get_file_as_string(abs_path)
	var json  := JSON.new()
	if json.parse(text) != OK:
		_set_status("Parse error: " + json.get_error_message(), Color(1, 0.4, 0.4))
		return

	var data  : Dictionary = json.get_data()
	_events = data.get("events", []).duplicate(true)
	_dirty  = false
	_rebuild_rows()
	_set_status("Loaded  (%d events)" % _events.size(), Color(0.5, 1.0, 0.5))


func _save_json() -> void:
	var data := {"chapter": "ch01_haison_iriguchi", "events": _events}
	var text := JSON.stringify(data, "\t")

	var abs_path := ProjectSettings.globalize_path(JSON_PATH)
	var f := FileAccess.open(abs_path, FileAccess.WRITE)
	if f == null:
		_set_status("Save failed (can't open file)", Color(1, 0.4, 0.4))
		return
	f.store_string(text)
	f.close()

	_dirty = false
	_set_status("Saved ✓", Color(0.5, 1.0, 0.5))


# ════════════════════════════════════════════════════════════════════
# 行の再描画
# ════════════════════════════════════════════════════════════════════

func _rebuild_rows() -> void:
	for child in _rows_box.get_children():
		child.queue_free()

	for i in _events.size():
		_rows_box.add_child(_make_row(i))


func _make_row(idx: int) -> Control:
	var ev    : Dictionary = _events[idx]
	var etype : String     = ev.get("type", "")
	var bg_col : Color     = TYPE_BG.get(etype, Color(0.15, 0.15, 0.15, 0.85))

	# 背景パネル
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg_col
	style.set_content_margin_all(2)
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	panel.add_child(hbox)

	# ── インデックス ──
	var idx_lbl := Label.new()
	idx_lbl.text = str(idx + 1)
	idx_lbl.custom_minimum_size.x = 32
	idx_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
	idx_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	idx_lbl.add_theme_font_size_override("font_size", 11)
	hbox.add_child(idx_lbl)

	# ── タイプラベル ──
	var type_lbl := Label.new()
	type_lbl.text = etype
	type_lbl.custom_minimum_size.x = 92
	type_lbl.add_theme_color_override("font_color", TYPE_LABEL_COLOR.get(etype, Color(0.8, 0.8, 0.8)))
	type_lbl.add_theme_font_size_override("font_size", 12)
	hbox.add_child(type_lbl)

	# ── コンテンツ ──
	var content := HBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 4)
	hbox.add_child(content)

	match etype:
		"say":
			_add_line_edit(content, ev, "text", "セリフ…", true, idx)
		"chat":
			_add_line_edit(content, ev, "msg",  "メッセージ…", true, idx)
			_add_line_edit(content, ev, "user", "ユーザー名", false, idx, 120)
		"wait":
			_add_spin(content, ev, "sec", 0.0, 30.0, 0.1, idx)
			var sec_lbl := Label.new(); sec_lbl.text = "sec"
			sec_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			content.add_child(sec_lbl)
		"rot_y", "head_x":
			_add_spin(content, ev, "target", -3.14, 3.14, 0.01, idx)
			var lbl1 := Label.new(); lbl1.text = "  dur:"
			lbl1.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			content.add_child(lbl1)
			_add_spin(content, ev, "dur", 0.05, 10.0, 0.05, idx)
			var lbl2 := Label.new(); lbl2.text = "sec"
			lbl2.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			content.add_child(lbl2)
		"pos_z":
			var lbl_t := Label.new(); lbl_t.text = "target:"
			lbl_t.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			content.add_child(lbl_t)
			_add_spin(content, ev, "target", -100.0, 100.0, 0.5, idx)
			var lbl_d := Label.new(); lbl_d.text = "  dur:"
			lbl_d.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			content.add_child(lbl_d)
			_add_spin(content, ev, "dur", 0.1, 30.0, 0.1, idx)
			var lbl_i := Label.new(); lbl_i.text = "  id:"
			lbl_i.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			content.add_child(lbl_i)
			_add_line_edit(content, ev, "id", "walk1", false, idx, 70)
		"pos_z_await":
			_add_line_edit(content, ev, "id", "walk1", false, idx, 80)
		"walk_set":
			var chk := CheckBox.new()
			chk.text    = "walking"
			chk.button_pressed = ev.get("on", false)
			chk.toggled.connect(func(v: bool) -> void:
				_events[idx]["on"] = v
				_mark_dirty()
			)
			content.add_child(chk)
		"flashlight_on", "say_clear":
			var placeholder := Label.new()
			placeholder.text = "(no params)"
			placeholder.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
			content.add_child(placeholder)

	# ── アクションボタン ──
	var actions := HBoxContainer.new()
	actions.custom_minimum_size.x = 94
	hbox.add_child(actions)

	_make_icon_btn(actions, "↑", func(): _move_event(idx, -1))
	_make_icon_btn(actions, "↓", func(): _move_event(idx, +1))
	_make_icon_btn(actions, "✕", func(): _delete_event(idx), Color(1.0, 0.5, 0.5))

	return panel


# ════════════════════════════════════════════════════════════════════
# イベント操作
# ════════════════════════════════════════════════════════════════════

func _insert_event(ev: Dictionary) -> void:
	_events.append(ev)
	_mark_dirty()
	_rebuild_rows()


func _move_event(idx: int, delta: int) -> void:
	var new_idx := idx + delta
	if new_idx < 0 or new_idx >= _events.size():
		return
	var tmp := _events[idx]
	_events[idx]     = _events[new_idx]
	_events[new_idx] = tmp
	_mark_dirty()
	_rebuild_rows()


func _delete_event(idx: int) -> void:
	_events.remove_at(idx)
	_mark_dirty()
	_rebuild_rows()


# ════════════════════════════════════════════════════════════════════
# ウィジェット生成ヘルパー
# ════════════════════════════════════════════════════════════════════

func _add_line_edit(parent: Control, ev: Dictionary, key: String,
		placeholder: String, expand: bool, idx: int, min_w: int = 0) -> void:
	var le := LineEdit.new()
	le.text             = str(ev.get(key, ""))
	le.placeholder_text = placeholder
	if expand:
		le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	elif min_w > 0:
		le.custom_minimum_size.x = min_w
	le.text_changed.connect(func(v: String) -> void:
		_events[idx][key] = v
		_mark_dirty()
	)
	parent.add_child(le)


func _add_spin(parent: Control, ev: Dictionary, key: String,
		mn: float, mx: float, step: float, idx: int) -> void:
	var sp := SpinBox.new()
	sp.min_value     = mn
	sp.max_value     = mx
	sp.step          = step
	sp.value         = float(ev.get(key, 0.0))
	sp.custom_minimum_size.x = 72
	sp.value_changed.connect(func(v: float) -> void:
		_events[idx][key] = v
		_mark_dirty()
	)
	parent.add_child(sp)


func _make_toolbar_btn(parent: Control, label: String, cb: Callable) -> void:
	var btn := Button.new()
	btn.text = label
	btn.pressed.connect(cb)
	parent.add_child(btn)


func _make_icon_btn(parent: Control, label: String, cb: Callable,
		col: Color = Color(0.75, 0.75, 0.75)) -> void:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(26, 0)
	btn.add_theme_color_override("font_color", col)
	btn.pressed.connect(cb)
	parent.add_child(btn)


func _make_header_lbl(parent: Control, text: String, min_w: int) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	if min_w < 0:
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		lbl.custom_minimum_size.x = min_w
	parent.add_child(lbl)


# ════════════════════════════════════════════════════════════════════
# 状態管理
# ════════════════════════════════════════════════════════════════════

func _mark_dirty() -> void:
	_dirty = true
	_set_status("● 未保存", Color(1.0, 0.75, 0.2))


func _set_status(text: String, col: Color = Color(0.7, 0.7, 0.7)) -> void:
	if is_instance_valid(_status_lbl):
		_status_lbl.text = text
		_status_lbl.add_theme_color_override("font_color", col)
