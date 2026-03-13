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
const CHAT_W    = 380
const VIDEO_W   = 900   # VW - CHAT_W
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
const CH_AVATAR = "res://assets/textures/tachie/きらきら.png"
const CH_ICON   = "res://assets/textures/shucchi_icon.png"

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
var _like_next   : float = 30.0
var _superchat_t : float = 0.0
var _superchat_next : float = 0.0
var _superchat_area : VBoxContainer
var _title_label : Label
var _elapsed          : float = 0.0
var _last_display_sec : int   = -1
var _chat_panel_ref   : Control = null  # チャットパネル本体
var _horror_overlay   : ColorRect = null  # ホラー演出用オーバーレイ
var _speed_btn        : Button   = null  # 倍速トグルボタン
var _speed_idx        : int      = 0     # 現在の速度インデックス
const SPEED_OPTIONS   = [1.0, 2.0, 4.0]
var _stage_btn        : Button   = null  # ステージ切替ボタン

const SUPERCHAT_NAMES = ["ゆきんこ77","幽霊ガチ勢","ホラー好き太郎","配信民99","ゴーストハンター"]
const SUPERCHAT_MSGS  = [
	"ガチホラー最高！！", "応援してます！！", "しゅっち無敵！！",
	"ここから勝って！！", "最高の配信でした！！",
]


func _ready() -> void:
	layer = 20
	add_to_group("youtube_chrome")
	_view_count = randi_range(1800, 3200)
	_like_count = randi_range(400,  900)
	_superchat_next = randf_range(45.0, 90.0)
	_build_top_bar()
	_build_chat_panel()
	_build_video_controls()
	_build_engagement_bar()
	call_deferred("_initial_scroll_chat")


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
	_avatar_icon(hbox, CH_ICON, 30)
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
	_chat_panel_ref = panel
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

	var live_badge := _make_badge(" ● LIVE ", C_RED, 13)
	h_hbox.add_child(live_badge)
	_pad(h_hbox, 8)

	_lbl(h_hbox, "ライブチャット", 16, C_TEXT)
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
	_chat_vbox.add_theme_constant_override("separation", 4)
	_chat_scroll.add_child(_chat_vbox)

	# 配信開始前のチャット履歴（エリアを埋めるため）
	var pre_msgs := [
		["霊感あるの？", "スピリチュアル系"],
		["夜中に見てる人〜", "深夜勢"],
		["お守り持ってきた？", "心配な人"],
		["廃村系好きすぎる", "廃墟マニア"],
		["配信安定してる！", "回線気にする人"],
		["BGMこわっ", "音感鋭い人"],
		["コメント読んでー！", "かまってちゃん"],
		["しゅっち最強！", "推し活"],
		["無事に帰ってね", "お母さん"],
		["録画してるｗ", "後から見る人"],
		["霧原村…マジ？", "夜更かし部"],
		["待ってた！", "ゆう☆"],
		["よろよろ〜", "にゃんこ99"],
		["心霊スポット好きすぎｗ", "深夜のテンション"],
		["ここの話聞いたことある", "地元民"],
		["ちゃんと帰れよ", "心配性な人"],
		["カメラ大丈夫？", "機材マン"],
		["一人で行くの？！", "ガクブル太郎"],
		["ゆきんこ77さんいる？", "新規さん"],
		["来たー！！", "ホラー好き太郎"],
	]
	for pm in pre_msgs:
		_add_pre_chat(pm[0], pm[1])

	# ─ 視聴者数表示 ─
	var view_wrap := PanelContainer.new()
	view_wrap.custom_minimum_size = Vector2(0, 36)
	var vws := StyleBoxFlat.new()
	vws.bg_color = Color(0.06, 0.06, 0.06)
	vws.border_color = C_BORDER
	vws.border_width_top = 1
	view_wrap.add_theme_stylebox_override("panel", vws)
	vbox.add_child(view_wrap)
	var vhbox := _hbox(view_wrap, 6)
	vhbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad(vhbox, 10)
	_live_dot = _lbl(vhbox, "●", 11, C_RED)
	_view_label = _lbl(vhbox, "%s 人が視聴中" % _fmt_count(_view_count), 14, C_MUTED)
	_view_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# ─ チャット入力エリア ─
	var input_area := PanelContainer.new()
	input_area.custom_minimum_size = Vector2(0, 64)
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
	_avatar_icon(ia_hbox, CH_ICON, 24)

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
	field_lbl.add_theme_font_size_override("font_size", 14)
	field_lbl.add_theme_color_override("font_color", Color(0.38, 0.38, 0.38))
	field_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	field_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	field_wrap.add_child(field_lbl)

	# 絵文字 & 送信ボタン
	_lbl(ia_hbox, "😀", 18, C_MUTED)
	var send_lbl := _lbl(ia_hbox, "➤", 20, Color(0.30, 0.30, 0.30))
	send_lbl.custom_minimum_size = Vector2(24, 0)
	send_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pad(ia_hbox, 6)

	# ホラー演出用オーバーレイ（全UI構築後に最前面へ配置）
	_horror_overlay = ColorRect.new()
	_horror_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_horror_overlay.color = Color(0, 0, 0, 0)
	_horror_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_horror_overlay)


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
	lbl.add_theme_font_size_override("font_size", 14)
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
	_speed_btn = _ctrl_button(btn_row, "▶▶", 12)
	_speed_btn.pressed.connect(_toggle_speed)
	_pad(btn_row, 2)
	_stage_btn = _ctrl_button(btn_row, "📍", 12)
	_stage_btn.pressed.connect(_open_stage_menu)
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

	# ─ アバター（アイコン） ─
	_avatar_icon(hbox, CH_ICON, 38)
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

	# 時間表示更新（秒が変わった時のみ）
	var cur_sec := int(_elapsed)
	if cur_sec != _last_display_sec:
		_last_display_sec = cur_sec
		if is_instance_valid(_title_label):
			_title_label.text = "%d:%02d " % [cur_sec / 60, cur_sec % 60]

	# 視聴者数ゆらぎ
	_view_t += delta
	if _view_t >= 3.5:
		_view_t = 0.0
		_view_count = max(800, _view_count + randi_range(-30, 60))
		if is_instance_valid(_view_label):
			_view_label.text = "%s 人が視聴中" % _fmt_count(_view_count)

	# 高評価数ゆらぎ（次回閾値を事前計算して毎フレームのrandf_rangeを回避）
	_like_t += delta
	if _like_t >= _like_next:
		_like_t = 0.0
		_like_next = randf_range(20.0, 40.0)
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

## 配信開始前の履歴チャット（薄めに表示、スクロールなし）
func _add_pre_chat(msg: String, user: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.modulate = Color(1, 1, 1, 0.35)
	_chat_vbox.add_child(row)
	_pad(row, 8)
	_avatar_circle(row, Color(0.25, 0.25, 0.28).darkened(0.3), user.substr(0, 1), 24)
	_pad(row, 6)
	var name_lbl := Label.new()
	name_lbl.text = user
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	row.add_child(name_lbl)
	var msg_lbl := Label.new()
	msg_lbl.text = "  " + msg
	msg_lbl.add_theme_font_size_override("font_size", 13)
	msg_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.50))
	msg_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(msg_lbl)
	_pad(row, 8)


func add_message(msg: String, user: String, user_type: String = "viewer") -> void:
	if not is_instance_valid(_chat_vbox):
		return

	# ── Kユーザー判定（ホラー演出） ──
	var is_k := user_type == "horror" or user == "K"

	var user_colors: Dictionary = {
		"owner":     Color(1.00, 0.84, 0.00),
		"moderator": Color(0.37, 0.52, 0.95),
		"member":    Color(0.17, 0.65, 0.25),
		"viewer":    Color(0.78, 0.78, 0.78),
		"horror":    Color(0.85, 0.08, 0.08),
	}
	var col: Color = user_colors.get(user_type, Color(0.78, 0.78, 0.78))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_chat_vbox.add_child(row)

	_pad(row, 8)

	# ミニアバター
	var avatar_icon := "👁" if is_k else user.substr(0, 1)
	var avatar_bg   := Color(0.35, 0.0, 0.0) if is_k else col.darkened(0.3)
	_avatar_circle(row, avatar_bg, avatar_icon, 24)
	_pad(row, 6)

	# ユーザー名ラベル（軽量Label、BBCode不使用）
	var badge: String = USER_BADGES.get(user_type, "")
	var name_lbl := Label.new()
	name_lbl.text = badge + user
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", col)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_lbl)

	_pad(row, 4)

	# メッセージ本体
	var msg_color := Color(0.90, 0.15, 0.10) if is_k else Color(0.88, 0.88, 0.88)
	var msg_lbl := Label.new()
	msg_lbl.text = msg
	msg_lbl.add_theme_font_size_override("font_size", 15)
	msg_lbl.add_theme_color_override("font_color", msg_color)
	msg_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(msg_lbl)

	_pad(row, 8)

	# 上限20件（古いものから順に削除）
	while _chat_vbox.get_child_count() > 20:
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
	SoundManager.play_superchat_chime()
	var tier_col := _superchat_tier_color(amount)
	var card := _build_superchat_card(sc_name, sc_msg, amount, tier_col)
	_superchat_area.add_child(card)
	get_tree().create_timer(12.0).timeout.connect(card.queue_free, CONNECT_ONE_SHOT)


func _spawn_superchat() -> void:
	if not is_instance_valid(_superchat_area):
		return
	SoundManager.play_superchat_chime()
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
	return str(n)


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


## 立ち絵の顔部分を丸く切り抜いてアバター表示
## CH_AVATAR_FACE_RECT: 顔領域 (x, y, w, h) — 画像内の顔の矩形
const CH_AVATAR_FACE_RECT = Rect2(380, 80, 750, 750)

func _avatar_image(parent: Node, tex_path: String, size: int) -> void:
	var tex := ResourceLoader.load(tex_path, "Texture2D") as Texture2D
	if not tex:
		_avatar_circle(parent, Color(0.85, 0.20, 0.15), "し", size)
		return
	# AtlasTexture で顔領域だけ切り出す
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = CH_AVATAR_FACE_RECT
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(size, size)
	var ws := StyleBoxFlat.new()
	ws.bg_color = Color(0.85, 0.20, 0.15)
	ws.set_corner_radius_all(size / 2)
	wrap.add_theme_stylebox_override("panel", ws)
	wrap.clip_contents = true
	parent.add_child(wrap)
	var tr := TextureRect.new()
	tr.texture = atlas
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.custom_minimum_size = Vector2(size, size)
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(tr)


## アイコン画像を正円で表示（PNG自体が円形マスク済み → TextureRectのみ）
func _avatar_icon(parent: Node, tex_path: String, size: int) -> void:
	var tex := ResourceLoader.load(tex_path, "Texture2D") as Texture2D
	if not tex:
		_avatar_circle(parent, Color(0.85, 0.20, 0.15), "し", size)
		return
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.custom_minimum_size = Vector2(size, size)
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tr)


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


func _ctrl_button(parent: Node, text: String, size: int) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.flat = true
	btn.custom_minimum_size = Vector2(36, 0)
	btn.add_theme_font_size_override("font_size", size)
	btn.add_theme_color_override("font_color", C_TEXT2)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(btn)
	return btn


func _toggle_speed() -> void:
	_speed_idx = (_speed_idx + 1) % SPEED_OPTIONS.size()
	var spd : float = SPEED_OPTIONS[_speed_idx]
	GameManager.playback_speed = spd
	if is_instance_valid(_speed_btn):
		if spd == 1.0:
			_speed_btn.text = "▶▶"
			_speed_btn.add_theme_color_override("font_color", C_TEXT2)
		else:
			_speed_btn.text = "x%d" % int(spd)
			_speed_btn.add_theme_color_override("font_color", C_RED)


# ── ステージ切替メニュー ──
var _stage_popup : PopupMenu = null

## CP1 サブセクション定義（stage_swap 境界で区切られる）
const CP1_SECTIONS : Array[String] = ["CP1-1 廃村入口", "CP1-2 商店街", "CP1-3 トイレ", "CP1-4 トイレ後"]

func _open_stage_menu() -> void:
	if _stage_popup and is_instance_valid(_stage_popup):
		_stage_popup.queue_free()
	_stage_popup = PopupMenu.new()
	_stage_popup.add_theme_font_size_override("font_size", 12)
	# 全チャプターをリストに追加（CP1はサブセクション展開）
	for i in GameManager.chapter_order.size():
		var path : String = GameManager.chapter_order[i]
		var ch := load(path) as Resource
		if i == 0:
			# CP1: サブセクション展開
			for sec_idx in CP1_SECTIONS.size():
				var label : String = CP1_SECTIONS[sec_idx]
				if i == GameManager.chapter_index and sec_idx == GameManager.start_section:
					label = "▶ " + label
				# id = sec_idx（0〜2）→ _on_stage_selected で CP1 + セクション指定
				_stage_popup.add_item(label, sec_idx)
		else:
			var label : String = ch.chapter_name if ch else "CP%d" % (i + 1)
			if i == GameManager.chapter_index:
				label = "▶ " + label
			# id = 10 + i（10〜14）→ 通常チャプター
			_stage_popup.add_item(label, 10 + i)
	# テスト用チャプターも追加
	_stage_popup.id_pressed.connect(_on_stage_selected)
	add_child(_stage_popup)
	# ボタンの上にポップアップ表示
	var btn_rect := _stage_btn.get_global_rect()
	_stage_popup.popup(Rect2i(int(btn_rect.position.x), int(btn_rect.position.y - _stage_popup.size.y - 10), 0, 0))


func _on_stage_selected(id: int) -> void:
	GameManager.state = GameManager.State.PLAYING
	GameManager.items_found = 0
	GameManager.hit_count = 0
	GameManager._hit_invincible = false
	if id < 10:
		# CP1 サブセクション（id = 0〜2）
		GameManager.start_section = id
		GameManager.load_chapter(0)
		get_tree().reload_current_scene()
	elif id < 100:
		# 通常チャプター（id = 10 + chapter_index）
		GameManager.start_section = 0
		GameManager.load_chapter(id - 10)
		get_tree().reload_current_scene()
	else:
		pass
				GameManager.chapter_index = -1
				get_tree().reload_current_scene()


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


# ════════════════════════════════════════════════════════════════
# ホラー演出 API（EntranceDirector / HUD から呼ばれる）
# ════════════════════════════════════════════════════════════════

## チャットパネルを赤くフラッシュさせる
func horror_flash(duration: float = 0.3, color: Color = Color(0.6, 0.0, 0.0, 0.4)) -> void:
	if not is_instance_valid(_horror_overlay):
		return
	_horror_overlay.color = color
	var tw := create_tween()
	tw.tween_property(_horror_overlay, "color:a", 0.0, duration)


## チャットパネルに暗い色味をじわっとかける（恐怖の雰囲気）
func horror_tint(color: Color = Color(0.15, 0.0, 0.0, 0.25), fade_in: float = 1.0) -> void:
	if not is_instance_valid(_horror_overlay):
		return
	var tw := create_tween()
	tw.tween_property(_horror_overlay, "color", color, fade_in)


## チャットパネルの色味を元に戻す
func horror_tint_clear(fade_out: float = 0.5) -> void:
	if not is_instance_valid(_horror_overlay):
		return
	var tw := create_tween()
	tw.tween_property(_horror_overlay, "color:a", 0.0, fade_out)


## チャット欄をグリッチ風に乱す（一瞬ずらして戻す）
func horror_glitch(intensity: float = 8.0, count: int = 3) -> void:
	if not is_instance_valid(_chat_panel_ref):
		return
	var orig_pos := _chat_panel_ref.position
	var tw := create_tween()
	for i in count:
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(_chat_panel_ref, "position", orig_pos + offset, 0.04)
		tw.tween_property(_chat_panel_ref, "position", orig_pos, 0.04)


## Kのメッセージを連投する（ホラーイベント用）
func horror_k_spam(messages: Array, interval: float = 0.15) -> void:
	for i in messages.size():
		if i > 0:
			await get_tree().create_timer(interval).timeout
		add_message(messages[i], "K", "horror")


## チャット欄をホラーモードにする（赤背景＋脈動＋ノイズ）
var _chat_horror_active : bool = false
var _chat_horror_tween  : Tween = null
var _chat_header_ref    : PanelContainer = null
var _chat_orig_style    : StyleBoxFlat = null

func chat_horror_mode(dur: float = 10.0) -> void:
	if not is_instance_valid(_chat_panel_ref) or _chat_horror_active:
		return
	_chat_horror_active = true

	# チャットパネル背景を血の赤に
	if not is_instance_valid(_horror_overlay):
		return
	_horror_overlay.color = Color(0.4, 0.0, 0.0, 0.55)

	# パネル全体の脈動（明滅）
	_chat_horror_tween = create_tween().set_loops()
	_chat_horror_tween.tween_property(_horror_overlay, "color:a", 0.7, 0.8).set_trans(Tween.TRANS_SINE)
	_chat_horror_tween.tween_property(_horror_overlay, "color:a", 0.3, 0.8).set_trans(Tween.TRANS_SINE)

	# 一定時間後に自動解除
	if dur > 0.0:
		get_tree().create_timer(dur).timeout.connect(chat_horror_clear, CONNECT_ONE_SHOT)


func chat_horror_clear() -> void:
	if not _chat_horror_active:
		return
	_chat_horror_active = false
	if _chat_horror_tween and _chat_horror_tween.is_valid():
		_chat_horror_tween.kill()
		_chat_horror_tween = null
	if is_instance_valid(_horror_overlay):
		var tw := create_tween()
		tw.tween_property(_horror_overlay, "color:a", 0.0, 1.5)


## 視聴者数を急変させる（急増 or ゼロ落ち演出）
func set_viewers(count: int) -> void:
	_view_count = count
	if is_instance_valid(_view_label):
		_view_label.text = "%s 人が視聴中" % _fmt_count(_view_count)


## 初期チャット表示を最下部にスクロール（_ready から call_deferred で呼ぶ）
func _initial_scroll_chat() -> void:
	if is_instance_valid(_chat_scroll):
		_chat_scroll.scroll_vertical = int(_chat_scroll.get_v_scroll_bar().max_value)
