extends CanvasLayer

## ストーリーマップ（リデザイン版）
## グリッド整列 + リッチビジュアル + ホバーエフェクト

signal closed

const VP := Vector2(1280, 720)

# ── レイアウト（全座標はノード中心） ──
const ROW_CH    : float = 195.0   # チャプター行
const ROW_ROUTE : float = 335.0   # ルート分岐行
const ROW_EARLY : float = 420.0   # CP1/CP2直結 BAD END
const ROW_END   : float = 515.0   # ルート先エンディング
const CHOICE_JUNCTION_Y : float = 267.0  # CP3-2からの分岐ライン合流Y

const X_CP1   : float = 100.0
const X_CP2   : float = 268.0
const X_CP3   : float = 520.0
const X_CP3_1 : float = X_CP3
const X_CP3_2 : float = X_CP3
const X_RA    : float = 782.0
const X_RB    : float = 955.0
const X_RC    : float = 1128.0

const SZ_CH  := Vector2(118.0, 55.0)
const SZ_DEC := SZ_CH
const SZ_BR  := Vector2(128.0, 46.0)
const SZ_END := Vector2(152.0, 66.0)

# ── ノード定義 ──
const FLOW_NODES : Array[Dictionary] = [
	{"id": "cp1",    "label": "CP1",   "name": "廃村入口",    "type": "chapter",  "cx": X_CP1,   "cy": ROW_CH,    "sz": SZ_CH},
	{"id": "cp2",    "label": "CP2",   "name": "廃倉庫",      "type": "chapter",  "cx": X_CP2,   "cy": ROW_CH,    "sz": SZ_CH},
	{"id": "cp3_1",  "label": "CP3-1", "name": "霧原神社",    "type": "chapter",  "cx": X_CP3_1, "cy": ROW_CH,    "sz": SZ_CH},
	{"id": "cp3_2",  "label": "CP3-2", "name": "三択分岐",    "type": "decision", "cx": X_CP3_2, "cy": ROW_CH,    "sz": SZ_DEC},
	{"id": "route_smash", "label": "ROUTE A", "name": "スマホを壊す",     "type": "branch", "cx": X_RA, "cy": ROW_ROUTE, "sz": SZ_BR},
	{"id": "route_take",  "label": "ROUTE B", "name": "スマホを持ち帰る", "type": "branch", "cx": X_RB, "cy": ROW_ROUTE, "sz": SZ_BR},
	{"id": "route_stop",  "label": "ROUTE C", "name": "配信を止める",     "type": "branch", "cx": X_RC, "cy": ROW_ROUTE, "sz": SZ_BR},
	{"id": "bad_hikikomori", "ending_id": "bad_hikikomori", "name": "ひきこもり",      "type": "bad",    "cx": X_CP1, "cy": ROW_EARLY, "sz": SZ_END, "tag": "BAD END"},
	{"id": "bad_eien",       "ending_id": "bad_eien",       "name": "永遠の配信",      "type": "bad",    "cx": X_CP2, "cy": ROW_EARLY, "sz": SZ_END, "tag": "BAD END"},
	{"id": "bad_ido",        "ending_id": "bad_ido",        "name": "アナタノカワリニ", "type": "bad",    "cx": X_RA,  "cy": ROW_END,   "sz": SZ_END, "tag": "BAD END"},
	{"id": "true_bad_end",   "ending_id": "true_bad_end",   "name": "視線ノ供物",      "type": "ending", "cx": X_RB,  "cy": ROW_END,   "sz": SZ_END, "tag": "TRUE BAD END"},
	{"id": "bad_predator",   "ending_id": "bad_predator",   "name": "盲目の捕食者",    "type": "bad",    "cx": X_RC,  "cy": ROW_END,   "sz": SZ_END, "tag": "BAD END"},
]

# ── 接続定義 [from_id, to_id, style] ──
const FLOW_CONNS : Array[Array] = [
	["cp1",    "cp2",           "progress"],
	["cp2",    "cp3_1",         "progress"],
	["cp3_1",  "cp3_2",         "progress"],
	["cp1",    "bad_hikikomori","bad_down"],
	["cp2",    "bad_eien",      "bad_down"],
	["cp3_2",  "route_smash",   "choice"],
	["cp3_2",  "route_take",    "choice"],
	["cp3_2",  "route_stop",    "choice"],
	["route_smash", "bad_ido",      "bad_down"],
	["route_take",  "true_bad_end", "end_down"],
	["route_stop",  "bad_predator", "bad_down"],
]

# ── カラー ──
const C_BG       := Color(0.02, 0.02, 0.04)
const C_CH_BG    := Color(0.05, 0.08, 0.15, 0.97)
const C_CH_ACC   := Color(0.35, 0.58, 0.88)
const C_DEC_BG   := Color(0.13, 0.07, 0.02, 0.97)
const C_DEC_ACC  := Color(0.95, 0.60, 0.15)
const C_BR_BG    := Color(0.09, 0.06, 0.03, 0.95)
const C_BR_ACC   := Color(0.78, 0.38, 0.10)
const C_BAD_BG   := Color(0.13, 0.03, 0.02, 0.97)
const C_BAD_ACC  := Color(0.90, 0.15, 0.10)
const C_TRUE_BG  := Color(0.09, 0.03, 0.12, 0.97)
const C_TRUE_ACC := Color(0.82, 0.28, 0.92)
const C_LOCK_BG  := Color(0.04, 0.04, 0.06, 0.85)
const C_LOCK_ACC := Color(0.22, 0.22, 0.27)
const C_TEXT     := Color(0.92, 0.92, 0.95)
const C_TEXT_DIM := Color(0.30, 0.30, 0.36)

const C_LINE_PROG := Color(0.28, 0.50, 0.80, 0.70)
const C_LINE_BAD  := Color(0.80, 0.12, 0.10, 0.62)
const C_LINE_CHO  := Color(0.78, 0.46, 0.12, 0.62)
const C_LINE_END  := Color(0.65, 0.28, 0.84, 0.65)

var _current_ending_id : String = ""
var _root              : Control = null
var _content           : Control = null
var _time              : float   = 0.0
var _node_controls     : Array[Control] = []
var _line_controls     : Array[Control] = []
var _flow_dots         : Array[Dictionary] = []
var _particles         : Array[Dictionary] = []
var _particle_ctrl     : Control = null
var _scanline_ctrl     : Control = null
var _ending_panels     : Dictionary = {}   # ending_id -> panel (for pulse)
var _return_choice_result : int = -1


func show_flowchart(current_ending_id: String) -> void:
	_current_ending_id = current_ending_id
	layer = 155
	_build()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	# 背景
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)

	# グリッド
	_draw_bg_grid()

	# パーティクル
	_particle_ctrl = Control.new()
	_particle_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_particle_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_particle_ctrl)
	_init_particles(50)

	# コンテンツ
	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_content)

	_build_header()
	_build_section_labels()
	_build_connections()
	_build_nodes()

	# スキャンライン
	_scanline_ctrl = Control.new()
	_scanline_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scanline_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_scanline_ctrl)

	# 閉じるボタン
	var btn := _make_button("閉じる")
	btn.position = Vector2(VP.x - 126.0, VP.y - 56.0)
	btn.modulate.a = 0.0
	_root.add_child(btn)
	btn.pressed.connect(_on_close)

	_animate_entrance(btn)


# ────────────────────────────────────────────────
# ヘッダー
# ────────────────────────────────────────────────
func _build_header() -> void:
	var title := Label.new()
	title.text = "S T O R Y   M A P"
	title.size = Vector2(VP.x, 44.0)
	title.position = Vector2(0.0, 14.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.75, 0.72, 0.84, 0.95))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(title)

	var line := _make_col_rect(Vector2((VP.x - 260.0) * 0.5, 58.0), Vector2(260.0, 1.0), Color(0.4, 0.38, 0.52, 0.4))
	_root.add_child(line)

	var total_e : int = 0
	var unlocked : int = 0
	for nd in FLOW_NODES:
		if nd.has("ending_id"):
			total_e += 1
			if GameManager.is_ending_unlocked(nd["ending_id"]):
				unlocked += 1
	var pct : int = int(float(unlocked) / float(maxi(total_e, 1)) * 100.0)

	var sub := Label.new()
	sub.text = "ENDINGS   %d / %d   —   %d%% COMPLETE" % [unlocked, total_e, pct]
	sub.size = Vector2(VP.x, 22.0)
	sub.position = Vector2(0.0, 62.0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.42, 0.42, 0.52, 0.75))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(sub)

	var bw : float = 240.0
	_root.add_child(_make_col_rect(Vector2((VP.x - bw) * 0.5, 82.0), Vector2(bw, 3.0), Color(0.12, 0.12, 0.18, 0.6)))
	if pct > 0:
		var fill_col : Color = C_CH_ACC if pct < 50 else (C_DEC_ACC if pct < 80 else Color(0.3, 0.78, 0.42))
		_root.add_child(_make_col_rect(Vector2((VP.x - bw) * 0.5, 82.0), Vector2(bw * float(pct) / 100.0, 3.0), fill_col.darkened(0.05)))


# ────────────────────────────────────────────────
# セクションラベル & 分割線
# ────────────────────────────────────────────────
func _build_section_labels() -> void:
	var lbl_l := _make_tiny_label("── MAIN STORY ──", Vector2(16.0, 105.0), Color(0.35, 0.45, 0.65, 0.62))
	_content.add_child(lbl_l)

	var lbl_r := _make_tiny_label("── CP3-2 CHOICES ──", Vector2(686.0, 105.0), Color(0.65, 0.44, 0.18, 0.62))
	_content.add_child(lbl_r)
	_content.add_child(_make_col_rect(Vector2(682.0, 104.0), Vector2(220.0, 16.0), C_BG))
	_content.add_child(_make_tiny_label("笏笏 ROUTES 笏笏", Vector2(686.0, 105.0), Color(0.65, 0.44, 0.18, 0.62)))

	# 分割縦線
	_content.add_child(_make_col_rect(Vector2(662.0, 118.0), Vector2(1.0, 430.0), Color(0.32, 0.32, 0.38, 0.20)))


# ────────────────────────────────────────────────
# 接続線
# ────────────────────────────────────────────────
func _build_connections() -> void:
	var center_map : Dictionary = {}
	var size_map   : Dictionary = {}
	for nd in FLOW_NODES:
		center_map[nd["id"]] = Vector2(nd["cx"], nd["cy"])
		size_map[nd["id"]]   = nd.get("sz", SZ_CH)

	for conn in FLOW_CONNS:
		var fid    : String  = conn[0]
		var tid    : String  = conn[1]
		var style  : String  = conn[2]
		if fid == "cp3_1" and tid == "cp3_2":
			continue
		if fid == "cp3_2":
			fid = "cp3_1"
		if tid == "cp3_2":
			tid = "cp3_1"
		var fc     : Vector2 = center_map.get(fid, Vector2.ZERO)
		var tc     : Vector2 = center_map.get(tid, Vector2.ZERO)
		var fsz    : Vector2 = size_map.get(fid,   SZ_CH)
		var tsz    : Vector2 = size_map.get(tid,   SZ_CH)

		var line := _make_connection(fc, fsz, tc, tsz, style, _is_connection_on_current_path(fid, tid))
		line.modulate.a = 0.0
		_content.add_child(line)
		_line_controls.append(line)


func _make_connection(fc: Vector2, fsz: Vector2, tc: Vector2, tsz: Vector2, style: String, is_current_path: bool = false) -> Control:
	var container := Control.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	match style:
		"progress":
			# 横線（チャプター間）
			var col : Color = Color(0.72, 0.86, 1.0, 0.95) if is_current_path else C_LINE_PROG
			var thick : float = 7.0 if is_current_path else 2.5
			var x0 : float = fc.x + fsz.x * 0.5
			var x1 : float = tc.x - tsz.x * 0.5
			if is_current_path:
				container.add_child(_make_col_rect(Vector2(x0, fc.y - 7.0), Vector2(x1 - x0, 14.0), Color(col.r, col.g, col.b, 0.18)))
			container.add_child(_make_col_rect(Vector2(x0, fc.y - thick * 0.5), Vector2(x1 - x0, thick), col))
			_add_flow_dot(container, Vector2(x0, fc.y), Vector2(x1, tc.y), col)

		"bad_down", "end_down":
			# 縦線（真下方向）
			var col : Color = C_LINE_END if style == "end_down" else C_LINE_BAD
			if is_current_path:
				col = Color(1.0, 0.42, 0.28, 0.98) if style == "bad_down" else Color(0.96, 0.66, 1.0, 0.98)
			var thick : float = 7.0 if is_current_path else 2.0
			var y0 : float = fc.y + fsz.y * 0.5
			var y1 : float = tc.y - tsz.y * 0.5
			if is_current_path:
				container.add_child(_make_col_rect(Vector2(fc.x - 7.0, y0), Vector2(14.0, y1 - y0), Color(col.r, col.g, col.b, 0.18)))
			container.add_child(_make_col_rect(Vector2(fc.x - thick * 0.5, y0), Vector2(thick, y1 - y0), col))
			_add_flow_dot(container, Vector2(fc.x, y0), Vector2(tc.x, y1), col)

		"choice":
			# CP3-2 → ルート: 下に trunk → 横 → 縦
			var col : Color = Color(1.0, 0.78, 0.36, 0.94) if is_current_path else C_LINE_CHO
			var thick : float = 6.0 if is_current_path else 1.8
			var trunk_x  : float = fc.x
			var trunk_y0 : float = fc.y + fsz.y * 0.5
			var trunk_y1 : float = CHOICE_JUNCTION_Y
			var branch_x : float = tc.x
			var branch_y1 : float = tc.y - tsz.y * 0.5

			# 縦: trunk
			if is_current_path:
				container.add_child(_make_col_rect(
					Vector2(trunk_x - 6.5, trunk_y0),
					Vector2(13.0, trunk_y1 - trunk_y0), Color(col.r, col.g, col.b, 0.18)))
			container.add_child(_make_col_rect(
				Vector2(trunk_x - thick * 0.5, trunk_y0),
				Vector2(thick, trunk_y1 - trunk_y0), col))
			# 横: junction → branch x
			var hx0 : float = minf(trunk_x, branch_x)
			var hx1 : float = maxf(trunk_x, branch_x)
			if is_current_path:
				container.add_child(_make_col_rect(
					Vector2(hx0, trunk_y1 - 6.5),
					Vector2(hx1 - hx0, 13.0), Color(col.r, col.g, col.b, 0.18)))
			container.add_child(_make_col_rect(
				Vector2(hx0, trunk_y1 - thick * 0.5),
				Vector2(hx1 - hx0, thick), col))
			# 縦: branch x down to route
			if is_current_path:
				container.add_child(_make_col_rect(
					Vector2(branch_x - 6.5, trunk_y1),
					Vector2(13.0, branch_y1 - trunk_y1), Color(col.r, col.g, col.b, 0.18)))
			container.add_child(_make_col_rect(
				Vector2(branch_x - thick * 0.5, trunk_y1),
				Vector2(thick, branch_y1 - trunk_y1), col))
			_add_flow_dot(container, Vector2(trunk_x, trunk_y0), Vector2(branch_x, branch_y1), col)

	return container


# ────────────────────────────────────────────────
# ノード
# ────────────────────────────────────────────────
func _build_nodes() -> void:
	for nd in FLOW_NODES:
		if nd["id"] == "cp3_2":
			continue
		var ctrl : Control
		match nd["type"]:
			"chapter":  ctrl = _make_chapter_node(nd)
			"decision": ctrl = _make_decision_node(nd)
			"branch":   ctrl = _make_branch_node(nd)
			_:          ctrl = _make_ending_node(nd)
		var sz : Vector2 = nd.get("sz", SZ_CH)
		ctrl.position = Vector2(nd["cx"] - sz.x * 0.5, nd["cy"] - sz.y * 0.5)
		ctrl.modulate.a = 0.0
		_content.add_child(ctrl)
		_node_controls.append(ctrl)


func _make_chapter_node(nd: Dictionary) -> Control:
	var sz      : Vector2 = nd.get("sz", SZ_CH)
	var reached : bool    = _is_chapter_reached(nd["id"])
	var on_path : bool    = _is_node_on_current_path(nd["id"])
	var acc     : Color   = C_CH_ACC if reached else Color(0.2, 0.26, 0.42, 0.5)
	var bg_col  : Color   = C_CH_BG  if reached else Color(0.03, 0.04, 0.07, 0.9)

	var panel := Control.new()
	panel.size = sz
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if reached:
		var glow_alpha : float = 0.12 if on_path else 0.06
		var glow_pad : float = 7.0 if on_path else 6.0
		panel.add_child(_glow_rect(sz, Color(acc.r, acc.g, acc.b, glow_alpha), glow_pad))
	panel.add_child(_make_col_rect(Vector2.ZERO, sz, bg_col))
	if on_path:
		panel.add_child(_make_col_rect(Vector2.ZERO, sz, Color(acc.r, acc.g, acc.b, 0.10)))
	panel.add_child(_make_col_rect(Vector2.ZERO, Vector2(3.0, sz.y), acc))
	panel.add_child(_make_col_rect(Vector2.ZERO, Vector2(sz.x, 1.0), Color(acc.r, acc.g, acc.b, 0.35)))
	_add_border(panel, sz, Color(acc.r, acc.g, acc.b, 0.72 if on_path else (0.38 if reached else 0.18)))
	if on_path:
		var inner_frame := Control.new()
		inner_frame.position = Vector2(4.0, 4.0)
		inner_frame.size = sz - Vector2(8.0, 8.0)
		_add_border(inner_frame, inner_frame.size, Color(acc.r, acc.g, acc.b, 0.42))
		panel.add_child(inner_frame)

	var chapter_label : String = "CP3" if nd["id"] == "cp3_1" else nd.get("label", "")
	panel.add_child(_make_label(chapter_label, Vector2(8.0, 7.0), Vector2(sz.x - 8.0, 15.0), 9,
		Color(acc.r, acc.g, acc.b, 0.88) if reached else C_TEXT_DIM))
	panel.add_child(_make_label(nd.get("name", ""), Vector2(8.0, 22.0), Vector2(sz.x - 8.0, 22.0), 14,
		C_TEXT if reached else C_TEXT_DIM))

	# 進行ドット
	var cidx : int = _get_chapter_index(nd["id"])
	for d in range(3):
		var dc : Color = Color(acc.r, acc.g, acc.b, 0.85) if (reached and d <= cidx) else Color(0.2, 0.2, 0.28, 0.38)
		panel.add_child(_make_col_rect(Vector2(8.0 + float(d) * 9.0, sz.y - 10.0), Vector2(4.0, 4.0), dc))

	return panel


func _make_decision_node(nd: Dictionary) -> Control:
	var sz      : Vector2 = nd.get("sz", SZ_DEC)
	var reached : bool    = _is_chapter_reached(nd["id"])
	var on_path : bool    = _is_node_on_current_path(nd["id"])
	var acc     : Color   = C_DEC_ACC if reached else Color(0.42, 0.30, 0.10, 0.5)
	var bg_col  : Color   = C_DEC_BG  if reached else Color(0.05, 0.04, 0.02, 0.9)

	var panel := Control.new()
	panel.size = sz
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if reached:
		var glow_alpha : float = 0.15 if on_path else 0.08
		var glow_pad : float = 8.0 if on_path else 7.0
		panel.add_child(_glow_rect(sz, Color(acc.r, acc.g, acc.b, glow_alpha), glow_pad))
	panel.add_child(_make_col_rect(Vector2.ZERO, sz, bg_col))
	if on_path:
		panel.add_child(_make_col_rect(Vector2.ZERO, sz, Color(acc.r, acc.g, acc.b, 0.12)))
	panel.add_child(_make_col_rect(Vector2.ZERO, Vector2(3.0, sz.y), acc))
	panel.add_child(_make_col_rect(Vector2.ZERO, Vector2(sz.x, 2.0), Color(acc.r, acc.g, acc.b, 0.45)))
	_add_border(panel, sz, Color(acc.r, acc.g, acc.b, 0.78 if on_path else (0.5 if reached else 0.2)))
	if on_path:
		var inner_frame := Control.new()
		inner_frame.position = Vector2(4.0, 4.0)
		inner_frame.size = sz - Vector2(8.0, 8.0)
		_add_border(inner_frame, inner_frame.size, Color(acc.r, acc.g, acc.b, 0.48))
		panel.add_child(inner_frame)

	panel.add_child(_make_label(nd.get("label", ""), Vector2(8.0, 7.0), Vector2(sz.x - 26.0, 15.0), 9,
		Color(acc.r, acc.g, acc.b, 0.95) if reached else C_TEXT_DIM))
	panel.add_child(_make_label(nd.get("name", ""), Vector2(8.0, 23.0), Vector2(sz.x - 8.0, 22.0), 14,
		C_TEXT if reached else C_TEXT_DIM))

	if reached:
		panel.add_child(_make_label("◈", Vector2(sz.x - 20.0, 5.0), Vector2(18.0, 18.0), 14,
			Color(acc.r, acc.g, acc.b, 0.72)))

	return panel


func _make_branch_node(nd: Dictionary) -> Control:
	var sz      : Vector2 = nd.get("sz", SZ_BR)
	var reached : bool    = _is_chapter_reached(nd["id"])
	var on_path : bool    = _is_node_on_current_path(nd["id"])
	var acc     : Color   = C_BR_ACC if reached else Color(0.32, 0.22, 0.08, 0.5)
	var bg_col  : Color   = C_BR_BG  if reached else Color(0.04, 0.03, 0.02, 0.88)

	var panel := Control.new()
	panel.size = sz
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if reached:
		var glow_alpha : float = 0.14 if on_path else 0.06
		var glow_pad : float = 8.0 if on_path else 7.0
		panel.add_child(_glow_rect(sz, Color(acc.r, acc.g, acc.b, glow_alpha), glow_pad))
	panel.add_child(_make_col_rect(Vector2.ZERO, sz, bg_col))
	if on_path:
		panel.add_child(_make_col_rect(Vector2.ZERO, sz, Color(acc.r, acc.g, acc.b, 0.11)))
	panel.add_child(_make_col_rect(Vector2.ZERO, Vector2(3.0, sz.y), acc))
	_add_border(panel, sz, Color(acc.r, acc.g, acc.b, 0.74 if on_path else (0.38 if reached else 0.16)))
	if on_path:
		var inner_frame := Control.new()
		inner_frame.position = Vector2(4.0, 4.0)
		inner_frame.size = sz - Vector2(8.0, 8.0)
		_add_border(inner_frame, inner_frame.size, Color(acc.r, acc.g, acc.b, 0.44))
		panel.add_child(inner_frame)

	panel.add_child(_make_label(nd.get("label", ""), Vector2(8.0, 4.0), Vector2(sz.x - 8.0, 14.0), 8,
		Color(acc.r, acc.g, acc.b, 0.90) if reached else C_TEXT_DIM))
	panel.add_child(_make_label(nd.get("name", ""), Vector2(8.0, 19.0), Vector2(sz.x - 8.0, 20.0), 11,
		C_TEXT if reached else C_TEXT_DIM))

	if not reached:
		panel.modulate.a = 0.55

	return panel


func _make_ending_node(nd: Dictionary) -> Control:
	var sz         : Vector2 = nd.get("sz", SZ_END)
	var node_id    : String  = nd.get("id", "")
	var ending_id  : String  = nd.get("ending_id", "")
	var is_unlocked : bool   = GameManager.is_ending_unlocked(ending_id)
	var is_current  : bool   = ending_id == _current_ending_id
	var on_path     : bool   = _is_node_on_current_path(node_id)
	var tag         : String = nd.get("tag", "BAD END")
	var active      : bool   = is_unlocked or is_current

	var acc    : Color
	var bg_col : Color
	if not active:
		acc = C_LOCK_ACC; bg_col = C_LOCK_BG
	elif tag == "TRUE BAD END":
		acc = C_TRUE_ACC; bg_col = C_TRUE_BG
	else:
		acc = C_BAD_ACC; bg_col = C_BAD_BG

	var panel := Control.new()
	panel.size = sz
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# グロー
	var glow_a : float = 0.18 if is_current else (0.12 if on_path else (0.05 if is_unlocked else 0.0))
	if glow_a > 0.0:
		panel.add_child(_glow_rect(sz, Color(acc.r, acc.g, acc.b, glow_a), 8.0 if on_path else 6.0))

	panel.add_child(_make_col_rect(Vector2.ZERO, sz, bg_col))
	if on_path:
		panel.add_child(_make_col_rect(Vector2.ZERO, sz, Color(acc.r, acc.g, acc.b, 0.14 if is_current else 0.10)))
	panel.add_child(_make_col_rect(Vector2.ZERO, Vector2(4.0, sz.y), acc))
	panel.add_child(_make_col_rect(Vector2.ZERO, Vector2(sz.x, 1.0), Color(acc.r, acc.g, acc.b, 0.5 if active else 0.14)))
	_add_border(panel, sz, Color(acc.r, acc.g, acc.b, 1.0 if is_current else (0.86 if on_path else (0.55 if active else 0.18))))
	if on_path:
		var inner_frame := Control.new()
		inner_frame.position = Vector2(5.0, 5.0)
		inner_frame.size = sz - Vector2(10.0, 10.0)
		_add_border(inner_frame, inner_frame.size, Color(acc.r, acc.g, acc.b, 0.52 if is_current else 0.40))
		panel.add_child(inner_frame)

	# タグ
	var top_y : float = 22.0 if is_current else 6.0
	var line_y : float = 38.0 if is_current else 22.0
	var name_y : float = 43.0 if is_current else 27.0
	panel.add_child(_make_label(
		tag if active else "? ? ?",
		Vector2(10.0, top_y), Vector2(sz.x - 28.0, 14.0), 9,
		Color(acc.r, acc.g, acc.b, 0.90) if active else C_TEXT_DIM))

	# セパレーター
	panel.add_child(_make_col_rect(Vector2(10.0, line_y), Vector2(sz.x * 0.6, 1.0),
		Color(acc.r, acc.g, acc.b, 0.20 if active else 0.07)))

	# 名前
	panel.add_child(_make_label(
		nd.get("name", "") if active else "? ? ? ? ? ?",
		Vector2(10.0, name_y), Vector2(sz.x - 14.0, 26.0), 14,
		C_TEXT if active else C_TEXT_DIM))

	# アイコン
	var icon_text : String = "✓" if is_unlocked else ("◀" if is_current else "🔒")
	var icon_col  : Color  = (Color(acc.r, acc.g, acc.b, 0.75) if is_unlocked
							  else (Color(1.0, 0.5, 0.3, 0.9) if is_current
							  else Color(0.3, 0.3, 0.36, 0.5)))
	panel.add_child(_make_label(icon_text, Vector2(sz.x - 22.0, sz.y - 21.0), Vector2(18.0, 18.0), 11, icon_col))

	if is_current:
		panel.add_child(_glow_rect(sz, Color(acc.r, acc.g, acc.b, 0.16), 12.0))
		var focus := Control.new()
		focus.name = "CurrentFocusFrame"
		focus.position = Vector2(-8.0, -8.0)
		focus.size = sz + Vector2(16.0, 16.0)
		_add_border(focus, focus.size, Color(acc.r, acc.g, acc.b, 0.95))
		panel.add_child(focus)
		panel.add_child(_make_label("YOU ARE HERE", Vector2(10.0, 8.0), Vector2(sz.x - 20.0, 14.0), 9, Color(1.0, 0.92, 0.82, 0.96)))

	if not active:
		panel.modulate.a = 0.48

	if active:
		_ending_panels[ending_id] = panel

	return panel


# ────────────────────────────────────────────────
# アニメーション
# ────────────────────────────────────────────────
func _animate_entrance(btn: Control) -> void:
	for i in range(_line_controls.size()):
		create_tween().tween_property(_line_controls[i], "modulate:a", 1.0, 0.35).set_delay(0.12 + float(i) * 0.055)

	for i in range(_node_controls.size()):
		var ctrl := _node_controls[i]
		ctrl.scale = Vector2(0.82, 0.82)
		ctrl.pivot_offset = ctrl.size * 0.5
		var target_a : float = 1.0 if ctrl.modulate.a > 0.6 else 0.5
		var d : float = 0.28 + float(i) * 0.075
		var tw := create_tween().set_parallel(true)
		tw.tween_property(ctrl, "modulate:a", target_a, 0.28).set_delay(d)
		tw.tween_property(ctrl, "scale", Vector2(1.0, 1.0), 0.30).set_delay(d).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var total_d : float = 0.28 + float(_node_controls.size()) * 0.075 + 0.25
	create_tween().tween_property(btn, "modulate:a", 1.0, 0.4).set_delay(total_d)


# ────────────────────────────────────────────────
# _process
# ────────────────────────────────────────────────
func _process(delta: float) -> void:
	_time += delta

	# フロードット
	for fd in _flow_dots:
		var ctrl : ColorRect = fd["ctrl"]
		if not is_instance_valid(ctrl):
			continue
		var t : float = fmod(fd["offset"] + _time * 0.20, 1.0)
		var pos : Vector2 = (fd["from"] as Vector2).lerp(fd["to"], t)
		ctrl.position = Vector2(pos.x - 3.0, pos.y - 3.0)
		ctrl.color.a = 0.20 + 0.70 * sin(t * PI)

	# 解放済みエンディングノードのグロー脈動
	for eid in _ending_panels:
		var p : Control = _ending_panels[eid]
		if not is_instance_valid(p) or p.get_child_count() == 0:
			continue
		var g := p.get_child(0)
		if g is ColorRect and g.size.x > SZ_END.x:
			var pulse_speed : float = 3.2 if eid == _current_ending_id else 2.0
			var base_a : float = 0.09 if eid == _current_ending_id else 0.04
			g.color.a = base_a + base_a * sin(_time * pulse_speed)
		var focus := p.get_node_or_null("CurrentFocusFrame")
		if focus is Control:
			focus.modulate.a = 0.72 + 0.28 * (0.5 + 0.5 * sin(_time * 3.6))

	_update_particles(delta)
	_draw_scanlines()


# ────────────────────────────────────────────────
# パーティクル
# ────────────────────────────────────────────────
func _init_particles(count: int) -> void:
	_particles.clear()
	for _i in range(count):
		_particles.append({
			"x": randf() * VP.x,
			"y": randf() * VP.y,
			"vx": randf_range(-2.0, 2.0),
			"vy": randf_range(-7.0, -1.5),
			"size": randf_range(1.0, 2.5),
			"alpha": randf_range(0.03, 0.10),
		})


func _update_particles(delta: float) -> void:
	if not is_instance_valid(_particle_ctrl):
		return
	for c in _particle_ctrl.get_children():
		c.queue_free()
	for p in _particles:
		p["y"] += p["vy"] * delta * 10.0
		p["x"] += p["vx"] * delta * 2.0
		if p["y"] < -5.0:
			p["y"] = VP.y + 5.0
			p["x"] = randf() * VP.x
		var dot := ColorRect.new()
		var s : float = p["size"]
		dot.size = Vector2(s, s)
		dot.position = Vector2(p["x"], p["y"])
		dot.color = Color(0.72, 0.14, 0.10, p["alpha"] * (0.6 + 0.4 * sin(_time * 1.5 + p["x"] * 0.012)))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_particle_ctrl.add_child(dot)


func _draw_scanlines() -> void:
	if not is_instance_valid(_scanline_ctrl):
		return
	for c in _scanline_ctrl.get_children():
		c.queue_free()
	var offset : float = fmod(_time * 35.0, 4.0)
	var y : float = offset
	while y < VP.y:
		var ln := ColorRect.new()
		ln.size = Vector2(VP.x, 1.0)
		ln.position = Vector2(0.0, y)
		ln.color = Color(0.0, 0.0, 0.0, 0.03)
		ln.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_scanline_ctrl.add_child(ln)
		y += 4.0


# ────────────────────────────────────────────────
# 背景グリッド
# ────────────────────────────────────────────────
func _draw_bg_grid() -> void:
	var grid := Control.new()
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(grid)
	var col := Color(0.10, 0.10, 0.15, 0.16)
	var step : float = 64.0
	var x : float = 0.0
	while x <= VP.x:
		grid.add_child(_make_col_rect(Vector2(x, 0.0), Vector2(1.0, VP.y), col))
		x += step
	var y : float = 0.0
	while y <= VP.y:
		grid.add_child(_make_col_rect(Vector2(0.0, y), Vector2(VP.x, 1.0), col))
		y += step


# ────────────────────────────────────────────────
# ヘルパー
# ────────────────────────────────────────────────
func _make_col_rect(pos: Vector2, sz: Vector2, col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = sz
	r.color = col
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _glow_rect(node_sz: Vector2, col: Color, margin: float) -> ColorRect:
	var g := ColorRect.new()
	g.size = node_sz + Vector2(margin * 2.0, margin * 2.0)
	g.position = Vector2(-margin, -margin)
	g.color = col
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return g


func _make_label(text: String, pos: Vector2, sz: Vector2, font_size: int, col: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.size = sz
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", col)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _make_tiny_label(text: String, pos: Vector2, col: Color) -> Label:
	return _make_label(text, pos, Vector2(300.0, 16.0), 9, col)


func _add_border(parent: Control, sz: Vector2, col: Color) -> void:
	var t : float = 1.0
	for data : Array in [
		[Vector2(sz.x, t),  Vector2(0.0, 0.0)],
		[Vector2(sz.x, t),  Vector2(0.0, sz.y - t)],
		[Vector2(t, sz.y),  Vector2(0.0, 0.0)],
		[Vector2(t, sz.y),  Vector2(sz.x - t, 0.0)],
	]:
		parent.add_child(_make_col_rect(data[1], data[0], col))


func _add_flow_dot(parent: Control, from: Vector2, to: Vector2, col: Color) -> void:
	var dot := ColorRect.new()
	dot.size = Vector2(6.0, 6.0)
	dot.color = Color(minf(col.r + 0.35, 1.0), minf(col.g + 0.35, 1.0), minf(col.b + 0.35, 1.0), 0.85)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(dot)
	_flow_dots.append({"ctrl": dot, "from": from, "to": to, "offset": randf()})


func _get_chapter_index(id: String) -> int:
	match id:
		"cp1":   return 0
		"cp2":   return 1
		"cp3_1": return 2
		_:       return -1


func _is_chapter_reached(id: String) -> bool:
	var cidx : int = _get_chapter_index(id)
	if cidx >= 0:
		if cidx <= GameManager.chapter_index:
			return true
		if id == "cp3_1":
			for eid in ["bad_ido", "true_bad_end", "bad_predator"]:
				if eid == _current_ending_id or GameManager.is_ending_unlocked(eid):
					return true
		return false
	if id in ["route_smash", "route_take", "route_stop"]:
		for eid in ["bad_ido", "true_bad_end", "bad_predator"]:
			if eid == _current_ending_id or GameManager.is_ending_unlocked(eid):
				return true
	return false


func _is_connection_on_current_path(from_id: String, to_id: String) -> bool:
	var path := _get_current_path_ids()
	for i in range(path.size() - 1):
		if path[i] == from_id and path[i + 1] == to_id:
			return true
	return false


func _is_node_on_current_path(node_id: String) -> bool:
	return node_id in _get_current_path_ids()


func _get_current_path_ids() -> Array[String]:
	match _current_ending_id:
		"bad_hikikomori":
			return ["cp1", "bad_hikikomori"]
		"bad_eien":
			return ["cp1", "cp2", "bad_eien"]
		"bad_ido":
			return ["cp1", "cp2", "cp3_1", "route_smash", "bad_ido"]
		"true_bad_end":
			return ["cp1", "cp2", "cp3_1", "route_take", "true_bad_end"]
		"bad_predator":
			return ["cp1", "cp2", "cp3_1", "route_stop", "bad_predator"]
		_:
			return []


func _make_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(110.0, 36.0)
	btn.size = Vector2(110.0, 36.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.04, 0.09, 0.88)
	sb.border_color = Color(0.30, 0.28, 0.42, 0.55)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate()
	sbh.border_color = Color(0.65, 0.55, 0.74, 0.80)
	sbh.bg_color = Color(0.09, 0.07, 0.15, 0.92)
	btn.add_theme_stylebox_override("hover", sbh)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", C_TEXT)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.8))
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	return btn


# 後方互換エイリアス（show_return_choice から呼ばれる）
func _make_styled_button(text: String) -> Button:
	var btn := _make_button(text)
	btn.custom_minimum_size.x = 200.0
	btn.size.x = 200.0
	return btn


func _on_close() -> void:
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.45)
	await tw.finished
	closed.emit()
	queue_free()


func _on_return_choice_selected(choice: int) -> void:
	_return_choice_result = choice


## play_endingから呼ばれる: 「選択肢に戻る / タイトルに戻る」を表示
## 戻り値: 0=選択肢に戻る, 1=タイトルに戻る
func show_return_choice() -> int:
	for child in _root.get_children():
		if child is Button:
			child.queue_free()

	_return_choice_result = -1

	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.size = Vector2(VP.x, 50.0)
	btn_container.position = Vector2(0.0, VP.y - 72.0)
	btn_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_container.modulate.a = 0.0
	_root.add_child(btn_container)

	var btn_retry := _make_styled_button("選択肢の直前に戻る")
	btn_retry.custom_minimum_size.x = 220.0
	btn_container.add_child(btn_retry)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(30.0, 0.0)
	btn_container.add_child(spacer)

	var btn_title := _make_styled_button("タイトルに戻る")
	btn_title.custom_minimum_size.x = 220.0
	btn_container.add_child(btn_title)

	var total_d : float = 0.28 + float(_node_controls.size()) * 0.075 + 0.5
	create_tween().tween_property(btn_container, "modulate:a", 1.0, 0.4).set_delay(total_d)

	btn_retry.pressed.connect(_on_return_choice_selected.bind(0))
	btn_title.pressed.connect(_on_return_choice_selected.bind(1))

	while _return_choice_result < 0:
		await get_tree().process_frame

	var tw_out := create_tween()
	tw_out.tween_property(_root, "modulate:a", 0.0, 0.5)
	await tw_out.finished

	return _return_choice_result
