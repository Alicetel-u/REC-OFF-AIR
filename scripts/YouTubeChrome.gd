extends CanvasLayer
class_name YouTubeChrome

## YouTube 風リッチ UI — コードのみで完全構築
## layer=20: 全レイヤーの最前面に描画

# ── レイアウト定数 (1280×720) ──────────────────────────────────
const VW        = 1280
const VH        = 720
const TOP_H     = 48
const CTRL_H    = 36
const ENGAGE_H  = 72
const CHAT_W    = 340
const VIDEO_W   = 940   # VW - CHAT_W
const VIDEO_BOT = 612   # VH - CTRL_H - ENGAGE_H

# ── YouTube 配色 ────────────────────────────────────────────────
const C_BG      = Color(0.055, 0.055, 0.055, 1.0)
const C_BG2     = Color(0.040, 0.040, 0.040, 1.0)
const C_BG3     = Color(0.075, 0.075, 0.075, 1.0)
const C_BORDER  = Color(0.16,  0.16,  0.16,  1.0)
const C_TEXT    = Color(1.0,   1.0,   1.0,   1.0)
const C_TEXT2   = Color(0.88,  0.88,  0.88,  1.0)
const C_MUTED   = Color(0.55,  0.55,  0.55,  1.0)
const C_RED     = Color(1.0,   0.067, 0.067, 1.0)
const C_CTRL_BG = Color(0.0,   0.0,   0.0,   0.78)
const C_PILL    = Color(0.14,  0.14,  0.14,  1.0)
const C_PILL_HV = Color(0.22,  0.22,  0.22,  1.0)

# ── チャンネル情報 ─────────────────────────────────────────────
const CH_NAME   = "しゅっちTV"
const CH_SUBS   = "347人"

# ── ユーザータイプ別バッジ文字 ───────────────────────────────────
const USER_BADGES = {
	"owner":     "👑 ",
	"moderator": "🔧 ",
	"member":    "⭐ ",
	"viewer":    "",
}

# ── ランタイム状態 ───────────────────────────────────────────────
var _view_count  : int   = 0
var _like_count  : int   = 0
var _view_label  : Label
var _like_label  : Label
var _live_dot    : Label
var _chat_vbox   : VBoxContainer
var _chat_scroll : ScrollContainer
var _live_t      : float = 0.0
var _view_t      : float = 0.0
var _like_t      : float = 0.0
var _superchat_t : float = 0.0
var _superchat_next : float = 0.0
var _superchat_area : VBoxContainer
var _title_label : Label
var _elapsed     : float = 0.0

const SUPERCHAT_NAMES = ["ゆきんこ77","幽霊ガチ勢","ホラー好き太郎","配信民99","ゴーストハンター"]
const SUPERCHAT_MSGS  = [
	"ガチホラー最高！！", "応援してます！！", "しゅっち無敵！！",
	"ここから勝って！！", "最高の配信でした！！",
]


func _ready() -> void:
	layer = 20
	_view_count = randi_range(1800, 3200)
	_like_count = randi_range(400,  900)
	_superchat_next = randf_range(45.0, 90.0)
	_build_top_bar()
	_build_chat_panel()
	_build_video_controls()
	_build_engagement_bar()


# ════════════════════════════════════════════════════════════════
# トップバー
# ════════════════════════════════════════════════════════════════

func _build_top_bar() -> void:
	var bar := _panel_rect(Vector2(0, 0), Vector2(VW, TOP_H), C_BG)
	_border_bottom(bar, C_BORDER)
	add_child(bar)

	var hbox := _hbox(bar, 0)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_pad(hbox, 14)

	# ── ハンバーガーメニュー ──
	var menu_btn := _lbl(hbox, "≡", 22, C_TEXT2)
	menu_btn.custom_minimum_size = Vector2(36, 0)
	menu_btn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pad(hbox, 10)

	# ── YouTube ロゴ ──
	var logo_box := HBoxContainer.new()
	logo_box.add_theme_constant_override("separation", 2)
	hbox.add_child(logo_box)

	var icon_wrap := PanelContainer.new()
	icon_wrap.custom_minimum_size = Vector2(28, 20)
	var iws := StyleBoxFlat.new()
	iws.bg_color = C_RED
	iws.set_corner_radius_all(4)
	icon_wrap.add_theme_stylebox_override("panel", iws)
	var icon_lbl := Label.new()
	icon_lbl.text = "▶"
	icon_lbl.add_theme_font_size_override("font_size", 11)
	icon_lbl.add_theme_color_override("font_color", C_TEXT)
	icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	icon_wrap.add_child(icon_lbl)
	logo_box.add_child(icon_wrap)

	var yt_lbl := _lbl(logo_box, "YouTube", 17, C_TEXT)
	yt_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_pad(hbox, 4)

	# ── JP バッジ ──
	var jp_badge := _make_badge("JP", Color(0.25, 0.25, 0.25), 9)
	hbox.add_child(jp_badge)

	_spacer(hbox)

	# ── 検索バー ──
	var search_outer := HBoxContainer.new()
	search_outer.add_theme_constant_override("separation", 0)
	hbox.add_child(search_outer)

	var search_wrap := PanelContainer.new()
	search_wrap.custom_minimum_size = Vector2(360, 32)
	var sw := StyleBoxFlat.new()
	sw.bg_color = Color(0.07, 0.07, 0.07)
	sw.border_color = Color(0.25, 0.25, 0.25)
	sw.set_border_width_all(1)
	sw.corner_radius_top_left    = 16
	sw.corner_radius_bottom_left = 16
	search_wrap.add_theme_stylebox_override("panel", sw)

	var sh := HBoxContainer.new()
	sh.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sh.add_theme_constant_override("separation", 0)
	search_wrap.add_child(sh)
	_pad(sh, 16)
	var sl := _lbl(sh, "検索", 13, Color(0.38, 0.38, 0.38))
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_outer.add_child(search_wrap)

	# 検索ボタン（虫眼鏡）
	var search_btn := PanelContainer.new()
	search_btn.custom_minimum_size = Vector2(52, 32)
	var sbs := StyleBoxFlat.new()
	sbs.bg_color = Color(0.14, 0.14, 0.14)
	sbs.border_color = Color(0.25, 0.25, 0.25)
	sbs.set_border_width_all(1)
	sbs.corner_radius_top_right    = 16
	sbs.corner_radius_bottom_right = 16
	search_btn.add_theme_stylebox_override("panel", sbs)
	var sb_lbl := Label.new()
	sb_lbl.text = "🔍"
	sb_lbl.add_theme_font_size_override("font_size", 16)
	sb_lbl.add_theme_color_override("font_color", C_TEXT2)
	sb_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sb_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sb_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	search_btn.add_child(sb_lbl)
	search_outer.add_child(search_btn)

	_pad(hbox, 8)

	# マイクボタン
	var mic := _circle_icon_btn("🎤", 34, Color(0.14, 0.14, 0.14))
	hbox.add_child(mic)

	_spacer(hbox)

	# ── 右側アイコン群 ──
	var create_btn := _circle_icon_btn("＋", 34, Color(0.14, 0.14, 0.14))
	hbox.add_child(create_btn)
	_pad(hbox, 6)
	_notification_bell(hbox)
	_pad(hbox, 8)
	_avatar_circle(hbox, Color(0.30, 0.55, 0.85), "し", 30)
	_pad(hbox, 14)


# ── 通知ベルバッジ ──
func _notification_bell(parent: Node) -> void:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(34, 34)
	parent.add_child(wrap)
	var bell := _lbl(wrap, "🔔", 20, C_TEXT2)
	bell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bell.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	var badge := PanelContainer.new()
	badge.position = Vector2(18, 2)
	badge.custom_minimum_size = Vector2(16, 16)
	var bs := StyleBoxFlat.new()
	bs.bg_color = C_RED
	bs.set_corner_radius_all(8)
	badge.add_theme_stylebox_override("panel", bs)
	var bl := Label.new()
	bl.text = "9+"
	bl.add_theme_font_size_override("font_size", 8)
	bl.add_theme_color_override("font_color", C_TEXT)
	bl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(bl)
	wrap.add_child(badge)


# ════════════════════════════════════════════════════════════════
# 右チャットパネル
# ════════════════════════════════════════════════════════════════

func _build_chat_panel() -> void:
	var panel := _panel_rect(
		Vector2(VIDEO_W, 0),
		Vector2(CHAT_W, VH),
		C_BG2
	)
	_border_left(panel, C_BORDER)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	# ─ チャットヘッダー ─
	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, TOP_H)
	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(0.06, 0.06, 0.06)
	hs.border_color = C_BORDER
	hs.border_width_bottom = 1
	header.add_theme_stylebox_override("panel", hs)
	vbox.add_child(header)

	var h_hbox := _hbox(header, 0)
	h_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad(h_hbox, 12)

	var live_badge := _make_badge(" ● LIVE ", C_RED, 11)
	h_hbox.add_child(live_badge)
	_pad(h_hbox, 8)

	_lbl(h_hbox, "ライブチャット", 13, C_TEXT)
	_spacer(h_hbox)

	# チャットヘッダーの右アイコン群
	var opt_wrap := HBoxContainer.new()
	opt_wrap.add_theme_constant_override("separation", 2)
	h_hbox.add_child(opt_wrap)
	_lbl(opt_wrap, "⤢", 16, C_MUTED)
	_pad(opt_wrap, 4)
	_lbl(opt_wrap, "⋮", 18, C_MUTED)
	_pad(h_hbox, 10)

	# ─ チャットモード切替タブ ─
	var tab_bar := PanelContainer.new()
	tab_bar.custom_minimum_size = Vector2(0, 34)
	var tbs := StyleBoxFlat.new()
	tbs.bg_color = C_BG2
	tbs.border_color = C_BORDER
	tbs.border_width_bottom = 1
	tab_bar.add_theme_stylebox_override("panel", tbs)
	vbox.add_child(tab_bar)

	var tabs := _hbox(tab_bar, 0)
	tabs.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chat_tab(tabs, "上位チャット", true)
	_chat_tab(tabs, "ライブチャット", false)

	# ─ スーパーチャットエリア ─
	_superchat_area = VBoxContainer.new()
	_superchat_area.add_theme_constant_override("separation", 2)
	_superchat_area.custom_minimum_size = Vector2(0, 0)
	vbox.add_child(_superchat_area)

	# ─ メッセージエリア ─
	_chat_scroll = ScrollContainer.new()
	_chat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chat_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_chat_scroll.follow_focus = true
	var cs := StyleBoxFlat.new()
	cs.bg_color = C_BG2
	_chat_scroll.add_theme_stylebox_override("panel", cs)
	vbox.add_child(_chat_scroll)

	_chat_vbox = VBoxContainer.new()
	_chat_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_vbox.add_theme_constant_override("separation", 2)
	_chat_scroll.add_child(_chat_vbox)

	# ─ 視聴者数表示 ─
	var view_wrap := PanelContainer.new()
	view_wrap.custom_minimum_size = Vector2(0, 30)
	var vws := StyleBoxFlat.new()
	vws.bg_color = Color(0.06, 0.06, 0.06)
	vws.border_color = C_BORDER
	vws.border_width_top = 1
	view_wrap.add_theme_stylebox_override("panel", vws)
	vbox.add_child(view_wrap)
	var vhbox := _hbox(view_wrap, 6)
	vhbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad(vhbox, 10)
	_live_dot = _lbl(vhbox, "●", 9, C_RED)
	_view_label = _lbl(vhbox, "%s 人が視聴中" % _fmt_count(_view_count), 11, C_MUTED)
	_view_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# ─ チャット入力エリア ─
	var input_area := PanelContainer.new()
	input_area.custom_minimum_size = Vector2(0, 58)
	var ias := StyleBoxFlat.new()
	ias.bg_color = Color(0.06, 0.06, 0.06)
	ias.border_color = C_BORDER
	ias.border_width_top = 1
	input_area.add_theme_stylebox_override("panel", ias)
	vbox.add_child(input_area)

	var ia_hbox := HBoxContainer.new()
	ia_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ia_hbox.add_theme_constant_override("separation", 6)
	input_area.add_child(ia_hbox)

	_pad(ia_hbox, 8)

	# ユーザーアバター
	_avatar_circle(ia_hbox, Color(0.30, 0.55, 0.85), "し", 24)

	# 入力フィールド
	var field_wrap := PanelContainer.new()
	field_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field_wrap.custom_minimum_size = Vector2(0, 30)
	var fws := StyleBoxFlat.new()
	fws.bg_color = Color.TRANSPARENT
	fws.border_color = Color(0.25, 0.25, 0.25)
	fws.border_width_bottom = 1
	field_wrap.add_theme_stylebox_override("panel", fws)
	ia_hbox.add_child(field_wrap)

	var field_lbl := Label.new()
	field_lbl.text = "チャット..."
	field_lbl.add_theme_font_size_override("font_size", 12)
	field_lbl.add_theme_color_override("font_color", Color(0.38, 0.38, 0.38))
	field_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	field_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	field_wrap.add_child(field_lbl)

	# 絵文字 & 送信ボタン
	_lbl(ia_hbox, "😀", 16, C_MUTED)
	var send_lbl := _lbl(ia_hbox, "➤", 18, Color(0.30, 0.30, 0.30))
	send_lbl.custom_minimum_size = Vector2(24, 0)
	send_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pad(ia_hbox, 6)


func _chat_tab(parent: Node, text: String, active: bool) -> void:
	var wrap := PanelContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ws := StyleBoxFlat.new()
	ws.bg_color = Color.TRANSPARENT
	if active:
		ws.border_color = C_TEXT
		ws.border_width_bottom = 2
	wrap.add_theme_stylebox_override("panel", ws)
	parent.add_child(wrap)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", C_TEXT if active else C_MUTED)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	wrap.add_child(lbl)


# ════════════════════════════════════════════════════════════════
# 動画コントロールバー
# ════════════════════════════════════════════════════════════════

func _build_video_controls() -> void:
	var bar := _panel_rect(
		Vector2(0, VIDEO_BOT),
		Vector2(VIDEO_W, CTRL_H),
		C_CTRL_BG
	)
	add_child(bar)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	bar.add_child(vbox)

	# ─ シークバー（ライブ = 100%赤） ─
	var seek_wrap := Control.new()
	seek_wrap.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(seek_wrap)

	var track := ColorRect.new()
	track.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	track.color = Color(0.30, 0.30, 0.30)
	seek_wrap.add_child(track)

	var fill := ColorRect.new()
	fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	fill.anchor_right = 1.0
	fill.color = C_RED
	seek_wrap.add_child(fill)

	# シークドット（赤い丸）
	var dot := PanelContainer.new()
	dot.custom_minimum_size = Vector2(14, 14)
	var ds := StyleBoxFlat.new()
	ds.bg_color = C_RED
	ds.set_corner_radius_all(7)
	dot.add_theme_stylebox_override("panel", ds)
	dot.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	dot.position = Vector2(-7, -5)
	seek_wrap.add_child(dot)

	# ─ コントロールボタン行 ─
	var btn_row := _hbox(vbox, 0)
	btn_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pad(btn_row, 10)
	_ctrl_btn(btn_row, "⏮", 14)
	_ctrl_btn(btn_row, "⏸", 18)
	_ctrl_btn(btn_row, "⏭", 14)
	_pad(btn_row, 4)
	_ctrl_btn(btn_row, "🔊", 14)
	_pad(btn_row, 6)

	# 時間表示
	_title_label = _lbl(btn_row, "0:00 ", 11, C_MUTED)

	_pad(btn_row, 6)

	# LIVE バッジ（小さめ・角丸）
	var live_w := PanelContainer.new()
	var lvs := StyleBoxFlat.new()
	lvs.bg_color = C_RED
	lvs.set_corner_radius_all(3)
	lvs.content_margin_left = 8
	lvs.content_margin_right = 8
	lvs.content_margin_top = 2
	lvs.content_margin_bottom = 2
	live_w.add_theme_stylebox_override("panel", lvs)
	btn_row.add_child(live_w)
	var live_lbl := Label.new()
	live_lbl.text = "ライブ"
	live_lbl.add_theme_font_size_override("font_size", 10)
	live_lbl.add_theme_color_override("font_color", C_TEXT)
	live_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	live_w.add_child(live_lbl)

	_spacer(btn_row)

	# 右側コントロール
	_ctrl_btn(btn_row, "CC", 10)
	_pad(btn_row, 2)
	_ctrl_btn(btn_row, "⚙", 16)
	_pad(btn_row, 2)
	_ctrl_btn(btn_row, "🖵", 14)
	_pad(btn_row, 2)
	_ctrl_btn(btn_row, "⛶", 16)
	_pad(btn_row, 10)


# ════════════════════════════════════════════════════════════════
# エンゲージメントバー（チャンネル情報 + ボタン）
# ════════════════════════════════════════════════════════════════

func _build_engagement_bar() -> void:
	var bar := _panel_rect(
		Vector2(0, VIDEO_BOT + CTRL_H),
		Vector2(VIDEO_W, ENGAGE_H),
		C_BG
	)
	_border_top(bar, C_BORDER)
	add_child(bar)

	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 2)
	bar.add_child(outer)

	# ── 配信タイトル行 ──
	var title_wrap := HBoxContainer.new()
	title_wrap.add_theme_constant_override("separation", 0)
	outer.add_child(title_wrap)
	_pad(title_wrap, 14)
	var stream_title := _lbl(title_wrap, "【深夜凸】霧原村 廃村ホラー生配信【しゅっちTV】", 13, C_TEXT)
	stream_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stream_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_pad(title_wrap, 4)
	_lbl(title_wrap, "▾", 14, C_TEXT2)
	_pad(title_wrap, 14)

	# ── チャンネル情報行 ──
	var hbox := _hbox(outer, 0)
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pad(hbox, 14)

	# ─ アバター（グラデーション風アイコン） ─
	_avatar_circle(hbox, Color(0.85, 0.20, 0.15), "し", 38)
	_pad(hbox, 10)

	# ─ チャンネル名 + 登録者 ─
	var ch_box := VBoxContainer.new()
	ch_box.add_theme_constant_override("separation", 0)
	hbox.add_child(ch_box)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 4)
	ch_box.add_child(name_row)
	_lbl(name_row, CH_NAME, 14, C_TEXT)
	# 認証バッジ
	var verify := _make_badge("✓", Color(0.40, 0.40, 0.40), 10)
	name_row.add_child(verify)

	_lbl(ch_box, "登録者数 %s" % CH_SUBS, 11, C_MUTED)

	_pad(hbox, 14)

	# ─ 登録ボタン ─
	var sub_wrap := PanelContainer.new()
	var ss := StyleBoxFlat.new()
	ss.bg_color = C_TEXT
	ss.set_corner_radius_all(20)
	ss.content_margin_left = 16
	ss.content_margin_right = 16
	ss.content_margin_top = 6
	ss.content_margin_bottom = 6
	sub_wrap.add_theme_stylebox_override("panel", ss)
	hbox.add_child(sub_wrap)
	var sub_lbl := Label.new()
	sub_lbl.text = "チャンネル登録"
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05))
	sub_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub_wrap.add_child(sub_lbl)

	_spacer(hbox)

	# ─ 高評価・低評価 (ピル形) ─
	var like_pill := PanelContainer.new()
	var lps := StyleBoxFlat.new()
	lps.bg_color = C_PILL
	lps.set_corner_radius_all(20)
	like_pill.add_theme_stylebox_override("panel", lps)
	hbox.add_child(like_pill)
	var like_hbox := _hbox(like_pill, 0)
	_pad(like_hbox, 14)
	_lbl(like_hbox, "👍", 14, C_TEXT)
	_pad(like_hbox, 4)
	_like_label = _lbl(like_hbox, _fmt_count(_like_count), 12, C_TEXT)
	_pad(like_hbox, 10)
	# 区切り線
	var sep_line := ColorRect.new()
	sep_line.custom_minimum_size = Vector2(1, 20)
	sep_line.color = Color(0.30, 0.30, 0.30)
	like_hbox.add_child(sep_line)
	_pad(like_hbox, 10)
	_lbl(like_hbox, "👎", 14, C_TEXT)
	_pad(like_hbox, 14)

	_pad(hbox, 8)

	# ─ シェアボタン ─
	_pill_button(hbox, "⤴ シェア")
	_pad(hbox, 6)

	# ─ その他 ─
	_pill_button(hbox, "⋯")
	_pad(hbox, 14)


# ════════════════════════════════════════════════════════════════
# フレーム更新
# ════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	_elapsed += delta

	# LIVE ドット点滅
	_live_t += delta
	if _live_t >= 0.6:
		_live_t = 0.0
		if is_instance_valid(_live_dot):
			_live_dot.visible = not _live_dot.visible

	# 時間表示更新
	if is_instance_valid(_title_label):
		var m := int(_elapsed / 60.0)
		var s := int(fmod(_elapsed, 60.0))
		_title_label.text = "%d:%02d " % [m, s]

	# 視聴者数ゆらぎ
	_view_t += delta
	if _view_t >= 3.5:
		_view_t = 0.0
		_view_count = max(800, _view_count + randi_range(-30, 60))
		if is_instance_valid(_view_label):
			_view_label.text = "%s 人が視聴中" % _fmt_count(_view_count)

	# 高評価数ゆらぎ
	_like_t += delta
	if _like_t >= randf_range(20.0, 40.0):
		_like_t = 0.0
		_like_count += randi_range(5, 30)
		if is_instance_valid(_like_label):
			_like_label.text = _fmt_count(_like_count)

	# スーパーチャット
	_superchat_t += delta
	if _superchat_t >= _superchat_next:
		_superchat_t = 0.0
		_superchat_next = randf_range(50.0, 110.0)
		_spawn_superchat()


# ════════════════════════════════════════════════════════════════
# チャット API（HUD.gd から呼ばれる）
# ════════════════════════════════════════════════════════════════

func add_message(msg: String, user: String, user_type: String = "viewer") -> void:
	if not is_instance_valid(_chat_vbox):
		return

	var user_colors: Dictionary = {
		"owner":     Color(1.00, 0.84, 0.00),
		"moderator": Color(0.37, 0.52, 0.95),
		"member":    Color(0.17, 0.65, 0.25),
		"viewer":    Color(0.78, 0.78, 0.78),
	}
	var col: Color = user_colors.get(user_type, Color(0.78, 0.78, 0.78))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_chat_vbox.add_child(row)

	_pad(row, 8)

	# ミニアバター
	_avatar_circle(row, col.darkened(0.3), user.substr(0, 1), 18)
	_pad(row, 6)

	# ユーザー名ラベル（軽量Label、BBCode不使用）
	var badge: String = USER_BADGES.get(user_type, "")
	var name_lbl := Label.new()
	name_lbl.text = badge + user
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", col)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_lbl)

	_pad(row, 4)

	# メッセージ本体（RichTextLabel→Label に変更してメモリ削減）
	var msg_lbl := Label.new()
	msg_lbl.text = msg
	msg_lbl.add_theme_font_size_override("font_size", 12)
	msg_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	msg_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(msg_lbl)

	_pad(row, 8)

	# 上限15件（remove_childで即座に親から切り離してからfree）
	while _chat_vbox.get_child_count() > 15:
		var old := _chat_vbox.get_child(0)
		_chat_vbox.remove_child(old)
		old.queue_free()

	await get_tree().process_frame
	if is_instance_valid(_chat_scroll):
		_chat_scroll.scroll_vertical = int(_chat_scroll.get_v_scroll_bar().max_value)


# ストーリー用スーパーチャット（名前・メッセージ・金額を指定）
func spawn_story_superchat(sc_name: String, sc_msg: String, amount: int) -> void:
	if not is_instance_valid(_superchat_area):
		return
	var tier_col := _superchat_tier_color(amount)
	var card := _build_superchat_card(sc_name, sc_msg, amount, tier_col)
	_superchat_area.add_child(card)
	get_tree().create_timer(12.0).timeout.connect(card.queue_free, CONNECT_ONE_SHOT)


func _spawn_superchat() -> void:
	if not is_instance_valid(_superchat_area):
		return
	var amount : int    = [200, 500, 1000, 2000, 5000][randi() % 5]
	var name_  : String = SUPERCHAT_NAMES[randi() % SUPERCHAT_NAMES.size()]
	var msg_   : String = SUPERCHAT_MSGS[randi()  % SUPERCHAT_MSGS.size()]
	var tier_col := _superchat_tier_color(amount)
	var card := _build_superchat_card(name_, msg_, amount, tier_col)
	_superchat_area.add_child(card)
	await get_tree().create_timer(12.0).timeout
	if is_instance_valid(card):
		card.queue_free()


func _superchat_tier_color(amount: int) -> Color:
	var tiers := [
		{ "min": 10000, "bg": Color(0.90, 0.10, 0.29) },
		{ "min": 5000,  "bg": Color(0.96, 0.45, 0.00) },
		{ "min": 2000,  "bg": Color(1.00, 0.76, 0.03) },
		{ "min": 1000,  "bg": Color(0.00, 0.74, 0.63) },
		{ "min": 200,   "bg": Color(0.13, 0.59, 0.95) },
	]
	for t in tiers:
		if amount >= int(t["min"]):
			return t["bg"]
	return Color(0.13, 0.59, 0.95)


func _build_superchat_card(sc_name: String, sc_msg: String, amount: int, bg: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 52)
	var sc := StyleBoxFlat.new()
	sc.bg_color = bg
	sc.set_corner_radius_all(6)
	sc.content_margin_left = 4
	sc.content_margin_right = 4
	card.add_theme_stylebox_override("panel", sc)

	var cvbox := VBoxContainer.new()
	cvbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cvbox.add_theme_constant_override("separation", 2)
	card.add_child(cvbox)

	var crow := _hbox(cvbox, 6)
	_pad(crow, 6)
	_avatar_circle(crow, bg.darkened(0.4), sc_name.substr(0, 1), 22)
	var nl := _lbl(crow, sc_name, 12, C_TEXT)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl(crow, "¥%s" % _fmt_count(amount), 13, C_TEXT)
	_pad(crow, 6)

	var ml := _lbl(cvbox, "  " + sc_msg, 12, C_TEXT)
	ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	return card


# ════════════════════════════════════════════════════════════════
# ユーティリティ
# ════════════════════════════════════════════════════════════════

func _fmt_count(n: int) -> String:
	if n >= 10000:
		return "%.1f万" % (n / 10000.0)
	if n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(n)


func _col_to_hex(c: Color) -> String:
	return "#%02x%02x%02x" % [int(c.r * 255), int(c.g * 255), int(c.b * 255)]


func _panel_rect(pos: Vector2, size: Vector2, bg: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = pos
	p.size = size
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	p.add_theme_stylebox_override("panel", s)
	return p


func _make_badge(text: String, bg: Color, font_size: int) -> PanelContainer:
	var w := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(3)
	s.content_margin_left = 4
	s.content_margin_right = 4
	s.content_margin_top = 1
	s.content_margin_bottom = 1
	w.add_theme_stylebox_override("panel", s)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", C_TEXT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w.add_child(l)
	return w


func _pill_button(parent: Node, text: String) -> void:
	var wrap := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = C_PILL
	s.set_corner_radius_all(20)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	wrap.add_theme_stylebox_override("panel", s)
	parent.add_child(wrap)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", C_TEXT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wrap.add_child(l)


func _circle_icon_btn(icon: String, size: int, bg: Color) -> PanelContainer:
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(size, size)
	var ws := StyleBoxFlat.new()
	ws.bg_color = bg
	ws.set_corner_radius_all(size / 2)
	wrap.add_theme_stylebox_override("panel", ws)
	var lbl := Label.new()
	lbl.text = icon
	lbl.add_theme_font_size_override("font_size", int(size * 0.45))
	lbl.add_theme_color_override("font_color", C_TEXT2)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	wrap.add_child(lbl)
	return wrap


func _avatar_circle(parent: Node, bg: Color, initial: String, size: int) -> void:
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(size, size)
	var ws := StyleBoxFlat.new()
	ws.bg_color = bg
	ws.set_corner_radius_all(size / 2)
	wrap.add_theme_stylebox_override("panel", ws)
	parent.add_child(wrap)
	var lbl := Label.new()
	lbl.text = initial
	lbl.add_theme_font_size_override("font_size", int(size * 0.48))
	lbl.add_theme_color_override("font_color", C_TEXT)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	wrap.add_child(lbl)


func _icon_btn(parent: Node, icon: String, size: int) -> void:
	var w := Control.new()
	w.custom_minimum_size = Vector2(36, 36)
	parent.add_child(w)
	var l := Label.new()
	l.text = icon
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", C_MUTED)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	w.add_child(l)


func _ctrl_btn(parent: Node, icon: String, size: int) -> void:
	var l := _lbl(parent, icon, size, C_TEXT2)
	l.custom_minimum_size = Vector2(30, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _hbox(parent: Node, sep: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	parent.add_child(h)
	return h


func _lbl(parent: Node, text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l


func _spacer(parent: Node) -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(c)
	return c


func _pad(parent: Node, px: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(px, px)
	parent.add_child(c)
	return c


func _border_bottom(node: PanelContainer, color: Color) -> void:
	var s := node.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	s.border_color = color
	s.border_width_bottom = 1
	node.add_theme_stylebox_override("panel", s)


func _border_top(node: PanelContainer, color: Color) -> void:
	var s := node.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	s.border_color = color
	s.border_width_top = 1
	node.add_theme_stylebox_override("panel", s)


func _border_left(node: PanelContainer, color: Color) -> void:
	var s := node.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	s.border_color = color
	s.border_width_left = 1
	node.add_theme_stylebox_override("panel", s)
