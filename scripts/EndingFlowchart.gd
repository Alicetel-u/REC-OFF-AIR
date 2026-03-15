extends CanvasLayer

## BAD END後に表示するストーリー分岐フローチャート

signal closed

const VP := Vector2(1280, 720)

# ── ノード定義 ──
const FLOW_NODES : Array[Dictionary] = [
	{"id": "cp1", "label": "CP1", "name": "廃村入口", "type": "chapter", "pos": Vector2(120, 190)},
	{"id": "cp2", "label": "CP2", "name": "廃倉庫", "type": "chapter", "pos": Vector2(310, 190)},
	{"id": "cp3", "label": "CP3", "name": "村の探索", "type": "chapter", "pos": Vector2(510, 190)},
	{"id": "cp4", "label": "CP4", "name": "???", "type": "chapter", "pos": Vector2(740, 190)},
	{"id": "cp5", "label": "CP5", "name": "???", "type": "chapter", "pos": Vector2(950, 190)},
	{"id": "bad_eien", "ending_id": "bad_eien", "name": "永遠の配信", "type": "bad",
	 "pos": Vector2(410, 370), "tag": "BAD END"},
	{"id": "bad_ido", "ending_id": "bad_ido", "name": "アナタノカワリニ", "type": "bad",
	 "pos": Vector2(620, 370), "tag": "BAD END"},
	{"id": "bad_dare", "ending_id": "bad_dare", "name": "わたしはだあれ", "type": "bad",
	 "pos": Vector2(620, 480), "tag": "BAD END"},
	{"id": "normal_end", "ending_id": "normal_end", "name": "???", "type": "ending",
	 "pos": Vector2(1100, 320), "tag": "NORMAL END"},
	{"id": "true_end", "ending_id": "true_end", "name": "???", "type": "ending",
	 "pos": Vector2(1100, 420), "tag": "TRUE END"},
	{"id": "bad_thumbnail", "ending_id": "bad_thumbnail", "name": "???", "type": "bad",
	 "pos": Vector2(1100, 520), "tag": "BAD END"},
]

# ── 接続定義 [from_id, to_id, style] ──
const FLOW_CONNS : Array[Array] = [
	["cp1", "cp2", "progress"],
	["cp2", "cp3", "progress"],
	["cp3", "cp4", "progress"],
	["cp4", "cp5", "progress"],
	["cp2", "bad_eien", "bad"],
	["cp3", "bad_eien", "bad"],
	["cp3", "bad_ido", "bad"],
	["cp3", "bad_dare", "bad"],
	["cp5", "normal_end", "ending"],
	["cp5", "true_end", "ending"],
	["cp5", "bad_thumbnail", "bad"],
]

# ── 色定義 ──
const COL_BG          := Color(0.02, 0.02, 0.05, 0.95)
const COL_CHAPTER_BG  := Color(0.08, 0.07, 0.10, 0.9)
const COL_CHAPTER_BD  := Color(0.4, 0.4, 0.45, 0.6)
const COL_UNLOCK_BG   := Color(0.12, 0.03, 0.03, 0.9)
const COL_UNLOCK_BD   := Color(0.6, 0.15, 0.1, 0.8)
const COL_LOCK_BG     := Color(0.04, 0.03, 0.05, 0.7)
const COL_LOCK_BD     := Color(0.2, 0.2, 0.25, 0.4)
const COL_CURRENT_BD  := Color(1.0, 0.85, 0.8, 0.9)
const COL_LINE_PROG   := Color(0.35, 0.35, 0.4, 0.5)
const COL_LINE_BAD    := Color(0.4, 0.1, 0.1, 0.5)
const COL_LINE_END    := Color(0.3, 0.3, 0.35, 0.4)
const COL_TEXT         := Color(0.9, 0.9, 0.9)
const COL_TEXT_DIM     := Color(0.35, 0.35, 0.4)
const COL_TAG_RED     := Color(0.8, 0.2, 0.15)
const COL_SCANLINE    := Color(0.0, 0.0, 0.0, 0.06)

var _current_ending_id : String = ""
var _root : Control = null
var _content : Control = null
var _time : float = 0.0
var _node_controls : Array[Control] = []
var _line_controls : Array[Control] = []
var _scanline_offset : float = 0.0


func show_flowchart(current_ending_id: String) -> void:
	_current_ending_id = current_ending_id
	layer = 155
	_build()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	# ── 背景 ──
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = COL_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)

	# ── コンテンツ（ノードと線の親） ──
	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_content)

	# ── ヘッダー ──
	var header := Label.new()
	header.text = "STORY MAP"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.size = Vector2(VP.x, 50)
	header.position = Vector2(0, 30)
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 0.8))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(header)

	# サブヘッダー
	var sub := Label.new()
	sub.text = "到達したエンディングが記録されます"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(VP.x, 30)
	sub.position = Vector2(0, 62)
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4, 0.6))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(sub)

	# ── 接続線を先に描画（ノードの下） ──
	_build_connections()

	# ── ノード ──
	_build_nodes()

	# ── タイトルに戻るボタン ──
	var btn := Button.new()
	btn.text = "タイトルに戻る"
	btn.custom_minimum_size = Vector2(200, 42)
	btn.size = Vector2(200, 42)
	btn.position = Vector2((VP.x - 200) * 0.5, VP.y - 80)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.1, 0.8)
	sb.border_color = Color(0.4, 0.35, 0.4, 0.6)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_hover := sb.duplicate()
	sb_hover.border_color = Color(0.7, 0.6, 0.7, 0.8)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", COL_TEXT)
	btn.add_theme_color_override("font_hover_color", Color(1, 0.9, 0.8))
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.modulate.a = 0.0
	_root.add_child(btn)
	btn.pressed.connect(_on_close)

	# ── 走査線コンテナ ──
	var scan_ctrl := Control.new()
	scan_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	scan_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scan_ctrl.set_script(null)
	_root.add_child(scan_ctrl)

	# ── 出現アニメーション ──
	_animate_entrance(btn)


func _build_nodes() -> void:
	var pos_map := {}
	for nd in FLOW_NODES:
		pos_map[nd["id"]] = nd["pos"]

	for nd in FLOW_NODES:
		var ctrl : Control
		if nd["type"] == "chapter":
			ctrl = _make_chapter_node(nd)
		else:
			ctrl = _make_ending_node(nd)
		ctrl.position = nd["pos"] - ctrl.size * 0.5
		ctrl.modulate.a = 0.0
		ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content.add_child(ctrl)
		_node_controls.append(ctrl)


func _make_chapter_node(nd: Dictionary) -> Control:
	var w : float = 120.0
	var h : float = 50.0
	var panel := Control.new()
	panel.size = Vector2(w, h)

	var bg := ColorRect.new()
	bg.size = Vector2(w, h)
	bg.color = COL_CHAPTER_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	# ボーダー（4辺）
	_add_border(panel, Vector2(w, h), COL_CHAPTER_BD)

	# ラベル（CP1等）
	var lbl_tag := Label.new()
	lbl_tag.text = nd.get("label", "")
	lbl_tag.size = Vector2(w, 18)
	lbl_tag.position = Vector2(0, 5)
	lbl_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_tag.add_theme_font_size_override("font_size", 10)
	lbl_tag.add_theme_color_override("font_color", COL_TEXT_DIM)
	lbl_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl_tag)

	# 名前
	var lbl_name := Label.new()
	lbl_name.text = nd.get("name", "")
	lbl_name.size = Vector2(w, 22)
	lbl_name.position = Vector2(0, 24)
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_name.add_theme_font_size_override("font_size", 13)
	lbl_name.add_theme_color_override("font_color", COL_TEXT)
	lbl_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl_name)

	return panel


func _make_ending_node(nd: Dictionary) -> Control:
	var ending_id : String = nd.get("ending_id", "")
	var is_unlocked : bool = GameManager.is_ending_unlocked(ending_id)
	var is_current : bool = ending_id == _current_ending_id

	var w : float = 150.0
	var h : float = 55.0
	var panel := Control.new()
	panel.size = Vector2(w, h)

	# 背景
	var bg := ColorRect.new()
	bg.size = Vector2(w, h)
	bg.color = COL_UNLOCK_BG if is_unlocked else COL_LOCK_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	# ボーダー
	var bd_col : Color
	if is_current:
		bd_col = COL_CURRENT_BD
	elif is_unlocked:
		bd_col = COL_UNLOCK_BD
	else:
		bd_col = COL_LOCK_BD
	_add_border(panel, Vector2(w, h), bd_col)

	# タグ（BAD END等）
	var tag_text : String = nd.get("tag", "BAD END")
	var lbl_tag := Label.new()
	lbl_tag.text = tag_text if is_unlocked else "???"
	lbl_tag.size = Vector2(w, 16)
	lbl_tag.position = Vector2(0, 5)
	lbl_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_tag.add_theme_font_size_override("font_size", 10)
	lbl_tag.add_theme_color_override("font_color", COL_TAG_RED if is_unlocked else COL_TEXT_DIM)
	lbl_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl_tag)

	# 名前
	var display_name : String = nd.get("name", "???") if is_unlocked else "???"
	var lbl_name := Label.new()
	lbl_name.text = display_name
	lbl_name.size = Vector2(w, 22)
	lbl_name.position = Vector2(0, 26)
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_name.add_theme_font_size_override("font_size", 14)
	lbl_name.add_theme_color_override("font_color", COL_TEXT if is_unlocked else COL_TEXT_DIM)
	lbl_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl_name)

	# 未到達時は全体を暗く
	if not is_unlocked:
		panel.modulate = Color(1, 1, 1, 0.5)

	# 今回到達: グロー
	if is_current:
		var glow := ColorRect.new()
		glow.size = Vector2(w + 8, h + 8)
		glow.position = Vector2(-4, -4)
		glow.color = Color(1.0, 0.3, 0.2, 0.08)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(glow)
		panel.move_child(glow, 0)
		# ▶ マーカー
		var marker := Label.new()
		marker.text = "▶"
		marker.position = Vector2(-18, h * 0.5 - 10)
		marker.add_theme_font_size_override("font_size", 14)
		marker.add_theme_color_override("font_color", Color(1.0, 0.85, 0.7))
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(marker)

	return panel


func _build_connections() -> void:
	var pos_map := {}
	for nd in FLOW_NODES:
		pos_map[nd["id"]] = nd["pos"]

	for conn in FLOW_CONNS:
		var from_pos : Vector2 = pos_map.get(conn[0], Vector2.ZERO)
		var to_pos   : Vector2 = pos_map.get(conn[1], Vector2.ZERO)
		var style    : String  = conn[2]

		var col : Color
		match style:
			"progress": col = COL_LINE_PROG
			"bad":      col = COL_LINE_BAD
			"ending":   col = COL_LINE_END
			_:          col = COL_LINE_PROG

		var line := _make_line(from_pos, to_pos, col)
		line.modulate.a = 0.0
		_content.add_child(line)
		_line_controls.append(line)


func _make_line(from: Vector2, to: Vector2, col: Color) -> Control:
	var container := Control.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var thickness : float = 2.0

	var dx : float = to.x - from.x
	var dy : float = to.y - from.y

	if absf(dy) < 5.0:
		# 水平線
		var rect := ColorRect.new()
		rect.size = Vector2(absf(dx), thickness)
		rect.position = Vector2(minf(from.x, to.x), from.y - thickness * 0.5)
		rect.color = col
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(rect)
	else:
		# L字型: 水平→垂直
		var mid_x : float = from.x + dx * 0.3
		# 水平部分
		var h_rect := ColorRect.new()
		h_rect.size = Vector2(absf(mid_x - from.x), thickness)
		h_rect.position = Vector2(minf(from.x, mid_x), from.y - thickness * 0.5)
		h_rect.color = col
		h_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(h_rect)
		# 垂直部分
		var v_rect := ColorRect.new()
		v_rect.size = Vector2(thickness, absf(dy))
		v_rect.position = Vector2(mid_x - thickness * 0.5, minf(from.y, to.y))
		v_rect.color = col
		v_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(v_rect)
		# 水平部分（到着）
		var h2_rect := ColorRect.new()
		h2_rect.size = Vector2(absf(to.x - mid_x), thickness)
		h2_rect.position = Vector2(minf(mid_x, to.x), to.y - thickness * 0.5)
		h2_rect.color = col
		h2_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(h2_rect)

	return container


func _add_border(parent: Control, sz: Vector2, col: Color) -> void:
	var t : float = 1.5
	# 上
	var top := ColorRect.new()
	top.size = Vector2(sz.x, t)
	top.color = col
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(top)
	# 下
	var bot := ColorRect.new()
	bot.size = Vector2(sz.x, t)
	bot.position = Vector2(0, sz.y - t)
	bot.color = col
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bot)
	# 左
	var lft := ColorRect.new()
	lft.size = Vector2(t, sz.y)
	lft.color = col
	lft.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lft)
	# 右
	var rgt := ColorRect.new()
	rgt.size = Vector2(t, sz.y)
	rgt.position = Vector2(sz.x - t, 0)
	rgt.color = col
	rgt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rgt)


func _animate_entrance(btn: Control) -> void:
	# 線を先にフェードイン
	var delay : float = 0.3
	for i in range(_line_controls.size()):
		var tw := create_tween()
		tw.tween_property(_line_controls[i], "modulate:a", 1.0, 0.3).set_delay(delay + float(i) * 0.06)

	# ノードを順次フェードイン
	delay = 0.5
	for i in range(_node_controls.size()):
		var tw := create_tween()
		tw.tween_property(_node_controls[i], "modulate:a", 1.0, 0.25).set_delay(delay + float(i) * 0.12)

	# ボタンを最後にフェードイン
	var total_delay : float = delay + float(_node_controls.size()) * 0.12 + 0.3
	var tw_btn := create_tween()
	tw_btn.tween_property(btn, "modulate:a", 1.0, 0.4).set_delay(total_delay)


func _process(delta: float) -> void:
	_time += delta
	# 今回到達したノードのグロー脈動
	if _current_ending_id != "":
		for i in range(FLOW_NODES.size()):
			if i >= _node_controls.size():
				break
			var nd : Dictionary = FLOW_NODES[i]
			if nd.get("ending_id", "") == _current_ending_id:
				var ctrl := _node_controls[i]
				# グローのColorRectを見つけて脈動
				if ctrl.get_child_count() > 0:
					var glow := ctrl.get_child(0)
					if glow is ColorRect and glow.size.x > 155:
						var pulse : float = 0.06 + 0.04 * sin(_time * 3.0)
						glow.color.a = pulse


func _on_close() -> void:
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.5)
	await tw.finished
	closed.emit()
	queue_free()
