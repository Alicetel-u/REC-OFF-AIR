extends CanvasLayer

## スマホ警告ダイアログ演出
## EntranceDirector の "phone_warning" イベントから呼ばれる
## dialogs 配列を順番に表示し、最後は赤フラッシュ → finished を emit

signal finished

var _dialogs: Array = []
var _current: int = 0
var _root_ctrl: Control
var _panel: PanelContainer
var _title_label: Label
var _msg_label: Label
var _ok_btn: Button


func show_dialogs(dialogs: Array) -> void:
	_dialogs = dialogs
	_current = 0
	_build_ui()
	_show_current()


func _build_ui() -> void:
	layer = 20

	# フルスクリーン基底 Control
	_root_ctrl = Control.new()
	_root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root_ctrl)

	# 暗幕
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_ctrl.add_child(dim)

	# ダイアログパネル（iOS風白ダイアログ）
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(380, 0)

	var style := StyleBoxFlat.new()
	style.bg_color                   = Color(0.96, 0.96, 0.96)
	style.corner_radius_top_left     = 12
	style.corner_radius_top_right    = 12
	style.corner_radius_bottom_left  = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left   = 24.0
	style.content_margin_right  = 24.0
	style.content_margin_top    = 22.0
	style.content_margin_bottom = 16.0
	_panel.add_theme_stylebox_override("panel", style)
	_root_ctrl.add_child(_panel)

	# 縦並びコンテンツ
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(vbox)

	# タイトル（赤・太め）
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_color_override("font_color", Color(0.78, 0.07, 0.07))
	_title_label.add_theme_font_size_override("font_size", 17)
	vbox.add_child(_title_label)

	# メッセージ（グレー・小さめ）
	_msg_label = Label.new()
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_msg_label.add_theme_color_override("font_color", Color(0.18, 0.18, 0.18))
	_msg_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_msg_label)

	# 区切り線
	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color            = Color(0.78, 0.78, 0.78)
	sep_style.content_margin_top  = 1.0
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# OKボタン（iOSっぽいフラット青）
	_ok_btn = Button.new()
	_ok_btn.text = "OK"
	_ok_btn.flat = true
	_ok_btn.add_theme_color_override("font_color", Color(0.10, 0.42, 0.88))
	_ok_btn.add_theme_font_size_override("font_size", 16)
	_ok_btn.pressed.connect(_on_ok_pressed)
	vbox.add_child(_ok_btn)


func _show_current() -> void:
	if _current >= _dialogs.size():
		finished.emit()
		queue_free()
		return

	var d: Dictionary = _dialogs[_current]
	_title_label.text  = d.get("title", "")
	_msg_label.text    = d.get("msg", "")
	_msg_label.visible = not d.get("msg", "").is_empty()
	_ok_btn.disabled   = false

	# フェードイン
	_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, 0.18)


func _on_ok_pressed() -> void:
	_ok_btn.disabled = true

	if _current == _dialogs.size() - 1:
		# 最後のダイアログ → 赤フラッシュ → finished
		var flash := ColorRect.new()
		flash.color = Color(0.85, 0.0, 0.0, 0.0)
		flash.set_anchors_preset(Control.PRESET_FULL_RECT)
		_root_ctrl.add_child(flash)

		var tw := create_tween()
		tw.tween_property(flash, "color", Color(0.85, 0.0, 0.0, 0.88), 0.08)
		tw.tween_property(flash, "color", Color(0.85, 0.0, 0.0, 0.0),  0.40)
		await tw.finished

		finished.emit()
		queue_free()
	else:
		_current += 1
		_show_current()
