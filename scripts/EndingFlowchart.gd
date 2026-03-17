extends CanvasLayer

## BAD END後に表示するストーリー分岐フローチャート（リッチ版）

signal closed

const VP := Vector2(1280, 720)

# ── ノード定義 ──
const FLOW_NODES : Array[Dictionary] = [
	{"id": "cp1", "label": "CP1", "name": "廃村入口", "type": "chapter", "pos": Vector2(110, 200)},
	{"id": "cp2", "label": "CP2", "name": "廃倉庫", "type": "chapter", "pos": Vector2(300, 200)},
	{"id": "cp3", "label": "CP3", "name": "村の探索", "type": "chapter", "pos": Vector2(500, 200)},
	{"id": "cp4", "label": "CP4", "name": "???", "type": "chapter", "pos": Vector2(720, 200)},
	{"id": "cp5", "label": "CP5", "name": "???", "type": "chapter", "pos": Vector2(940, 200)},
	{"id": "bad_hikikomori", "ending_id": "bad_hikikomori", "name": "ひきこもり", "type": "bad",
	 "pos": Vector2(150, 380), "tag": "BAD END"},
	{"id": "bad_eien", "ending_id": "bad_eien", "name": "永遠の配信", "type": "bad",
	 "pos": Vector2(400, 380), "tag": "BAD END"},
	{"id": "bad_ido", "ending_id": "bad_ido", "name": "アナタノカワリニ", "type": "bad",
	 "pos": Vector2(600, 310), "tag": "BAD END"},
	{"id": "true_archive", "ending_id": "true_archive", "name": "永遠のアーカイブ", "type": "ending",
	 "pos": Vector2(600, 420), "tag": "TRUE END"},
	{"id": "bad_predator", "ending_id": "bad_predator", "name": "盲目の捕食者", "type": "bad",
	 "pos": Vector2(600, 530), "tag": "BAD END"},
	{"id": "normal_end", "ending_id": "normal_end", "name": "???", "type": "ending",
	 "pos": Vector2(1100, 310), "tag": "NORMAL END"},
	{"id": "true_end", "ending_id": "true_end", "name": "???", "type": "ending",
	 "pos": Vector2(1100, 420), "tag": "TRUE END"},
	{"id": "bad_thumbnail", "ending_id": "bad_thumbnail", "name": "???", "type": "bad",
	 "pos": Vector2(1100, 530), "tag": "BAD END"},
]

# ── 接続定義 [from_id, to_id, style] ──
const FLOW_CONNS : Array[Array] = [
	["cp1", "cp2", "progress"],
	["cp2", "cp3", "progress"],
	["cp3", "cp4", "progress"],
	["cp4", "cp5", "progress"],
	["cp1", "bad_hikikomori", "bad"],
	["cp2", "bad_eien", "bad"],
	["cp3", "bad_eien", "bad"],
	["cp3", "bad_ido", "bad"],
	["cp3", "true_archive", "ending"],
	["cp3", "bad_predator", "bad"],
	["cp5", "normal_end", "ending"],
	["cp5", "true_end", "ending"],
	["cp5", "bad_thumbnail", "bad"],
]

# ── 色定義 ──
const COL_BG          := Color(0.01, 0.01, 0.03, 0.96)
const COL_CHAPTER_BG  := Color(0.06, 0.06, 0.12, 0.9)
const COL_CHAPTER_BD  := Color(0.3, 0.35, 0.5, 0.6)
const COL_UNLOCK_BG   := Color(0.14, 0.03, 0.03, 0.9)
const COL_UNLOCK_BD   := Color(0.7, 0.15, 0.1, 0.8)
const COL_LOCK_BG     := Color(0.04, 0.03, 0.06, 0.7)
const COL_LOCK_BD     := Color(0.2, 0.2, 0.28, 0.4)
const COL_CURRENT_BD  := Color(1.0, 0.4, 0.3, 0.95)
const COL_LINE_PROG   := Color(0.25, 0.35, 0.55, 0.5)
const COL_LINE_BAD    := Color(0.5, 0.08, 0.08, 0.5)
const COL_LINE_END    := Color(0.3, 0.4, 0.35, 0.5)
const COL_TEXT         := Color(0.92, 0.92, 0.95)
const COL_TEXT_DIM     := Color(0.32, 0.32, 0.4)
const COL_TAG_RED     := Color(0.85, 0.18, 0.12)
const COL_TAG_NORMAL  := Color(0.3, 0.65, 0.85)
const COL_TAG_TRUE    := Color(0.85, 0.75, 0.3)

var _current_ending_id : String = ""
var _root : Control = null
var _content : Control = null
var _time : float = 0.0
var _node_controls : Array[Control] = []
var _line_controls : Array[Control] = []
var _particles : Array[Dictionary] = []
var _particle_ctrl : Control = null
var _scanline_ctrl : Control = null
var _flow_dots : Array[Dictionary] = []


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

	# ── パーティクル（背景の浮遊粒子） ──
	_particle_ctrl = Control.new()
	_particle_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_particle_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_particle_ctrl)
	_init_particles(60)

	# ── コンテンツ ──
	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_content)

	# ── ヘッダー ──
	var header := Label.new()
	header.text = "S T O R Y   M A P"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.size = Vector2(VP.x, 50)
	header.position = Vector2(0, 22)
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color(0.55, 0.5, 0.6, 0.9))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(header)

	# ── ヘッダー下線 ──
	var header_line := ColorRect.new()
	header_line.size = Vector2(320, 1)
	header_line.position = Vector2((VP.x - 320) * 0.5, 54)
	header_line.color = Color(0.4, 0.35, 0.5, 0.3)
	header_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(header_line)

	# ── 達成率 ──
	var total_endings : int = 0
	var unlocked_count : int = 0
	for nd in FLOW_NODES:
		if nd.has("ending_id"):
			total_endings += 1
			if GameManager.is_ending_unlocked(nd["ending_id"]):
				unlocked_count += 1
	var pct : int = int(float(unlocked_count) / float(maxi(total_endings, 1)) * 100.0)

	var sub := Label.new()
	sub.text = "ENDINGS  %d / %d — %d%%" % [unlocked_count, total_endings, pct]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(VP.x, 30)
	sub.position = Vector2(0, 60)
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.45, 0.4, 0.5, 0.7))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(sub)

	# ── 達成率バー ──
	var bar_w : float = 200.0
	var bar_bg := ColorRect.new()
	bar_bg.size = Vector2(bar_w, 3)
	bar_bg.position = Vector2((VP.x - bar_w) * 0.5, 80)
	bar_bg.color = Color(0.15, 0.15, 0.2, 0.5)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bar_bg)

	var bar_fill := ColorRect.new()
	var fill_w : float = bar_w * float(pct) / 100.0
	bar_fill.size = Vector2(fill_w, 3)
	bar_fill.position = bar_bg.position
	bar_fill.color = Color(0.7, 0.3, 0.25, 0.8) if pct < 50 else Color(0.3, 0.6, 0.4, 0.8)
	bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bar_fill)

	# ── 接続線 ──
	_build_connections()

	# ── ノード ──
	_build_nodes()

	# ── VHSスキャンライン ──
	_scanline_ctrl = Control.new()
	_scanline_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scanline_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_scanline_ctrl)

	# ── ボタン ──
	var btn := _make_styled_button("タイトルに戻る")
	btn.position = Vector2((VP.x - 200) * 0.5, VP.y - 75)
	btn.modulate.a = 0.0
	_root.add_child(btn)
	btn.pressed.connect(_on_close)

	# ── アニメーション ──
	_animate_entrance(btn)


func _build_nodes() -> void:
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
	var w : float = 130.0
	var h : float = 56.0
	var panel := Control.new()
	panel.size = Vector2(w, h)

	# グラデーション背景
	var bg := ColorRect.new()
	bg.size = Vector2(w, h)
	bg.color = COL_CHAPTER_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	# 上部アクセントライン
	var accent_line := ColorRect.new()
	accent_line.size = Vector2(w, 2)
	accent_line.color = Color(0.3, 0.4, 0.7, 0.6)
	accent_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(accent_line)

	_add_border(panel, Vector2(w, h), COL_CHAPTER_BD)

	# CPラベル
	var lbl_tag := Label.new()
	lbl_tag.text = nd.get("label", "")
	lbl_tag.size = Vector2(w, 16)
	lbl_tag.position = Vector2(0, 6)
	lbl_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_tag.add_theme_font_size_override("font_size", 9)
	lbl_tag.add_theme_color_override("font_color", Color(0.4, 0.45, 0.6, 0.8))
	lbl_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl_tag)

	# チャプター名
	var lbl_name := Label.new()
	lbl_name.text = nd.get("name", "")
	lbl_name.size = Vector2(w, 22)
	lbl_name.position = Vector2(0, 22)
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_name.add_theme_font_size_override("font_size", 14)
	lbl_name.add_theme_color_override("font_color", COL_TEXT)
	lbl_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl_name)

	# 進行度ドット（到達済みチャプターなら光る）
	var chapter_idx : int = _get_chapter_index(nd["id"])
	var reached : bool = chapter_idx <= GameManager.chapter_index
	var dot_y : float = h - 10.0
	for d in range(3):
		var dot := ColorRect.new()
		dot.size = Vector2(4, 4)
		dot.position = Vector2(w * 0.5 - 10 + float(d) * 10, dot_y)
		dot.color = Color(0.4, 0.6, 0.9, 0.8) if (reached and d <= chapter_idx) else Color(0.2, 0.2, 0.3, 0.4)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(dot)

	return panel


func _make_ending_node(nd: Dictionary) -> Control:
	var ending_id : String = nd.get("ending_id", "")
	var is_unlocked : bool = GameManager.is_ending_unlocked(ending_id)
	var is_current : bool = ending_id == _current_ending_id
	var tag_text : String = nd.get("tag", "BAD END")

	var w : float = 160.0
	var h : float = 62.0
	var panel := Control.new()
	panel.size = Vector2(w, h)

	# 背景
	var bg := ColorRect.new()
	bg.size = Vector2(w, h)
	if is_unlocked:
		bg.color = COL_UNLOCK_BG
	else:
		bg.color = COL_LOCK_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	# 上部アクセントライン（タグ色に応じて変化）
	var accent_col : Color = _get_tag_color(tag_text, is_unlocked)
	var accent_line := ColorRect.new()
	accent_line.size = Vector2(w, 2)
	accent_line.color = accent_col
	accent_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(accent_line)

	# ボーダー
	var bd_col : Color
	if is_current:
		bd_col = COL_CURRENT_BD
	elif is_unlocked:
		bd_col = COL_UNLOCK_BD
	else:
		bd_col = COL_LOCK_BD
	_add_border(panel, Vector2(w, h), bd_col)

	# タグ
	var lbl_tag := Label.new()
	lbl_tag.text = tag_text if is_unlocked else "? ? ?"
	lbl_tag.size = Vector2(w, 16)
	lbl_tag.position = Vector2(0, 7)
	lbl_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_tag.add_theme_font_size_override("font_size", 9)
	lbl_tag.add_theme_color_override("font_color", accent_col if is_unlocked else COL_TEXT_DIM)
	lbl_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl_tag)

	# セパレーター
	var sep := ColorRect.new()
	sep.size = Vector2(w * 0.5, 1)
	sep.position = Vector2(w * 0.25, 24)
	sep.color = Color(accent_col.r, accent_col.g, accent_col.b, 0.2) if is_unlocked else Color(0.2, 0.2, 0.25, 0.2)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sep)

	# 名前
	var display_name : String = nd.get("name", "???") if is_unlocked else "???"
	var lbl_name := Label.new()
	lbl_name.text = display_name
	lbl_name.size = Vector2(w, 22)
	lbl_name.position = Vector2(0, 30)
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_name.add_theme_font_size_override("font_size", 13)
	lbl_name.add_theme_color_override("font_color", COL_TEXT if is_unlocked else COL_TEXT_DIM)
	lbl_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl_name)

	# 未到達
	if not is_unlocked and not is_current:
		panel.modulate = Color(1, 1, 1, 0.45)

	# 今回到達: グロー + マーカー
	if is_current:
		# 外側グロー
		var glow := ColorRect.new()
		glow.size = Vector2(w + 12, h + 12)
		glow.position = Vector2(-6, -6)
		glow.color = Color(1.0, 0.25, 0.15, 0.06)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(glow)
		panel.move_child(glow, 0)
		# 内側グロー
		var inner_glow := ColorRect.new()
		inner_glow.size = Vector2(w + 4, h + 4)
		inner_glow.position = Vector2(-2, -2)
		inner_glow.color = Color(1.0, 0.3, 0.2, 0.04)
		inner_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(inner_glow)
		panel.move_child(inner_glow, 1)
		# ▶ マーカー
		var marker := Label.new()
		marker.text = "▶"
		marker.position = Vector2(-20, h * 0.5 - 10)
		marker.add_theme_font_size_override("font_size", 16)
		marker.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3, 0.9))
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(marker)
		# 「NOW」ラベル
		var now_lbl := Label.new()
		now_lbl.text = "NOW"
		now_lbl.size = Vector2(w, 12)
		now_lbl.position = Vector2(0, h + 4)
		now_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		now_lbl.add_theme_font_size_override("font_size", 8)
		now_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3, 0.7))
		now_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(now_lbl)

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

		var line := _make_line(from_pos, to_pos, col, style)
		line.modulate.a = 0.0
		_content.add_child(line)
		_line_controls.append(line)


func _make_line(from: Vector2, to: Vector2, col: Color, style: String) -> Control:
	var container := Control.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var thickness : float = 2.0

	var dx : float = to.x - from.x
	var dy : float = to.y - from.y

	# 進行ラインは太く
	if style == "progress":
		thickness = 3.0

	if absf(dy) < 5.0:
		var rect := ColorRect.new()
		rect.size = Vector2(absf(dx), thickness)
		rect.position = Vector2(minf(from.x, to.x), from.y - thickness * 0.5)
		rect.color = col
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(rect)
		# 進行線に矢印ドット
		if style == "progress":
			_add_flow_dot(container, from, to, col)
	else:
		var mid_x : float = from.x + dx * 0.35
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


func _add_flow_dot(parent: Control, from: Vector2, to: Vector2, col: Color) -> void:
	var dot := ColorRect.new()
	dot.size = Vector2(6, 6)
	dot.color = Color(col.r + 0.3, col.g + 0.3, col.b + 0.3, 0.8)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(dot)
	_flow_dots.append({"ctrl": dot, "from": from, "to": to, "offset": randf()})


func _add_border(parent: Control, sz: Vector2, col: Color) -> void:
	var t : float = 1.5
	for data in [
		[Vector2(sz.x, t), Vector2.ZERO],
		[Vector2(sz.x, t), Vector2(0, sz.y - t)],
		[Vector2(t, sz.y), Vector2.ZERO],
		[Vector2(t, sz.y), Vector2(sz.x - t, 0)],
	]:
		var r := ColorRect.new()
		r.size = data[0]
		r.position = data[1]
		r.color = col
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(r)


func _animate_entrance(btn: Control) -> void:
	# 線フェードイン
	var delay : float = 0.2
	for i in range(_line_controls.size()):
		var tw := create_tween()
		tw.tween_property(_line_controls[i], "modulate:a", 1.0, 0.4).set_delay(delay + float(i) * 0.05)

	# ノードフェードイン + スケール
	delay = 0.4
	for i in range(_node_controls.size()):
		var ctrl := _node_controls[i]
		ctrl.scale = Vector2(0.8, 0.8)
		ctrl.pivot_offset = ctrl.size * 0.5
		var tw := create_tween().set_parallel(true)
		tw.tween_property(ctrl, "modulate:a", 1.0, 0.3).set_delay(delay + float(i) * 0.1)
		tw.tween_property(ctrl, "scale", Vector2(1.0, 1.0), 0.35).set_delay(delay + float(i) * 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# ボタン
	var total_delay : float = delay + float(_node_controls.size()) * 0.1 + 0.3
	var tw_btn := create_tween()
	tw_btn.tween_property(btn, "modulate:a", 1.0, 0.4).set_delay(total_delay)


func _process(delta: float) -> void:
	_time += delta

	# パーティクル更新
	_update_particles(delta)

	# フロードット（進行線上を流れる光）
	for fd in _flow_dots:
		var ctrl : ColorRect = fd["ctrl"]
		if not is_instance_valid(ctrl):
			continue
		var t : float = fmod(fd["offset"] + _time * 0.15, 1.0)
		var pos : Vector2 = fd["from"].lerp(fd["to"], t)
		ctrl.position = Vector2(pos.x - 3, pos.y - 3)
		ctrl.color.a = 0.3 + 0.5 * sin(t * PI)

	# 今回到達ノードのグロー脈動
	if _current_ending_id != "":
		for i in range(FLOW_NODES.size()):
			if i >= _node_controls.size():
				break
			var nd : Dictionary = FLOW_NODES[i]
			if nd.get("ending_id", "") == _current_ending_id:
				var ctrl := _node_controls[i]
				if ctrl.get_child_count() > 0:
					var glow := ctrl.get_child(0)
					if glow is ColorRect and glow.size.x > 165:
						glow.color.a = 0.04 + 0.04 * sin(_time * 2.5)
					var inner := ctrl.get_child(1) if ctrl.get_child_count() > 1 else null
					if inner is ColorRect and inner.size.x > 160:
						inner.color.a = 0.03 + 0.03 * sin(_time * 3.5 + 1.0)

	# VHSスキャンライン描画
	if is_instance_valid(_scanline_ctrl):
		_draw_scanlines()


# ── パーティクル ──
func _init_particles(count: int) -> void:
	_particles.clear()
	for _i in range(count):
		_particles.append({
			"x": randf() * VP.x,
			"y": randf() * VP.y,
			"vx": randf_range(-3, 3),
			"vy": randf_range(-8, -2),
			"size": randf_range(1.0, 3.0),
			"alpha": randf_range(0.02, 0.12),
			"color": Color(0.7 + randf() * 0.3, 0.1 + randf() * 0.15, 0.1 + randf() * 0.1),
		})


func _update_particles(delta: float) -> void:
	if not is_instance_valid(_particle_ctrl):
		return
	# 古いの消す
	for c in _particle_ctrl.get_children():
		c.queue_free()
	# 新規描画
	for p in _particles:
		p["y"] += p["vy"] * delta * 12.0
		p["x"] += p["vx"] * delta * 3.0
		if p["y"] < -10:
			p["y"] = VP.y + 10
			p["x"] = randf() * VP.x
		var dot := ColorRect.new()
		var s : float = p["size"]
		dot.size = Vector2(s, s)
		dot.position = Vector2(p["x"], p["y"])
		dot.color = Color(p["color"].r, p["color"].g, p["color"].b, p["alpha"] * (0.5 + 0.5 * sin(_time * 2.0 + p["x"] * 0.01)))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_particle_ctrl.add_child(dot)


func _draw_scanlines() -> void:
	for c in _scanline_ctrl.get_children():
		c.queue_free()
	var offset : float = fmod(_time * 40.0, 4.0)
	var y : float = offset
	while y < VP.y:
		var line := ColorRect.new()
		line.size = Vector2(VP.x, 1)
		line.position = Vector2(0, y)
		line.color = Color(0, 0, 0, 0.04)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_scanline_ctrl.add_child(line)
		y += 4.0


func _get_tag_color(tag: String, unlocked: bool) -> Color:
	if not unlocked:
		return COL_TEXT_DIM
	match tag:
		"NORMAL END": return COL_TAG_NORMAL
		"TRUE END":   return COL_TAG_TRUE
		"BAD END":    return COL_TAG_RED
		_:            return COL_TAG_RED


func _get_chapter_index(id: String) -> int:
	match id:
		"cp1": return 0
		"cp2": return 1
		"cp3": return 2
		"cp4": return 3
		"cp5": return 4
		_:     return -1


func _make_styled_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 42)
	btn.size = Vector2(200, 42)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.04, 0.1, 0.85)
	sb.border_color = Color(0.35, 0.3, 0.45, 0.6)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_hover := sb.duplicate()
	sb_hover.border_color = Color(0.7, 0.55, 0.7, 0.8)
	sb_hover.bg_color = Color(0.1, 0.06, 0.15, 0.9)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", COL_TEXT)
	btn.add_theme_color_override("font_hover_color", Color(1, 0.9, 0.8))
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	return btn


func _on_close() -> void:
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.5)
	await tw.finished
	closed.emit()
	queue_free()


## play_endingから呼ばれる: 「選択肢に戻る / タイトルに戻る」を表示
## 戻り値: 0=選択肢に戻る, 1=タイトルに戻る
func show_return_choice() -> int:
	# 既存ボタン削除
	for child in _root.get_children():
		if child is Button:
			child.queue_free()

	var result : int = -1

	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.size = Vector2(VP.x, 50)
	btn_container.position = Vector2(0, VP.y - 75)
	btn_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_container.modulate.a = 0.0
	_root.add_child(btn_container)

	var btn_retry := _make_styled_button("選択肢の直前に戻る")
	btn_retry.custom_minimum_size.x = 220
	btn_container.add_child(btn_retry)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(30, 0)
	btn_container.add_child(spacer)

	var btn_title := _make_styled_button("タイトルに戻る")
	btn_title.custom_minimum_size.x = 220
	btn_container.add_child(btn_title)

	var total_delay : float = 0.5 + float(_node_controls.size()) * 0.1 + 0.5
	var tw_btn := create_tween()
	tw_btn.tween_property(btn_container, "modulate:a", 1.0, 0.4).set_delay(total_delay)

	btn_retry.pressed.connect(func() -> void: result = 0)
	btn_title.pressed.connect(func() -> void: result = 1)

	while result < 0:
		await get_tree().process_frame

	var tw_out := create_tween()
	tw_out.tween_property(_root, "modulate:a", 0.0, 0.5)
	await tw_out.finished

	return result
