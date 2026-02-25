extends CanvasLayer
class_name YouTubeChrome

## YouTube 風リッチ UI — コードのみで完全構築
## layer=20: 全レイヤーの最前面に描画

# ── レイアウト定数 (1280×720) ──────────────────────────────────
const VW        = 1280
const VH        = 720
const TOP_H     = 56
const CTRL_H    = 32
const ENGAGE_H  = 64
const CHAT_W    = 320
const VIDEO_W   = 960   # VW - CHAT_W
const VIDEO_BOT = 624   # VH - CTRL_H - ENGAGE_H

# ── YouTube 配色 ────────────────────────────────────────────────
const C_BG      = Color(0.063, 0.063, 0.063, 1.0)
const C_BG2     = Color(0.047, 0.047, 0.047, 1.0)
const C_BORDER  = Color(0.20,  0.20,  0.20,  1.0)
const C_TEXT    = Color(1.0,   1.0,   1.0,   1.0)
const C_MUTED   = Color(0.60,  0.60,  0.60,  1.0)
const C_RED     = Color(1.0,   0.067, 0.067, 1.0)
const C_CTRL_BG = Color(0.0,   0.0,   0.0,   0.82)

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

const SUPERCHAT_NAMES = ["ゆきんこ77","幽霊ガチ勢","ホラー好き太郎","配信民99","ゴーストハンター"]
const SUPERCHAT_MSGS  = [
	"ガチホラー最高！！", "応援してます！！", "配信タロウ無敵！！",
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

	_pad(hbox, 12)
	_lbl(hbox, "≡", 20, C_MUTED)
	_pad(hbox, 14)

	# ── YouTube ロゴ ──
	var logo_box := HBoxContainer.new()
	logo_box.add_theme_constant_override("separation", 3)
	hbox.add_child(logo_box)

	var icon_wrap := PanelContainer.new()
	icon_wrap.custom_minimum_size = Vector2(24, 18)
	var iws := StyleBoxFlat.new()
	iws.bg_color = C_RED
	iws.set_corner_radius_all(3)
	icon_wrap.add_theme_stylebox_override("panel", iws)
	var icon_lbl := Label.new()
	icon_lbl.text = "▶"
	icon_lbl.add_theme_font_size_override("font_size", 10)
	icon_lbl.add_theme_color_override("font_color", C_TEXT)
	icon_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	icon_wrap.add_child(icon_lbl)
	logo_box.add_child(icon_wrap)

	var yt_lbl := _lbl(logo_box, "YouTube", 15, C_TEXT)
	yt_lbl.add_theme_font_size_override("font_size", 15)

	_spacer(hbox)

	# ── 検索バー ──
	var search_wrap := PanelContainer.new()
	search_wrap.custom_minimum_size = Vector2(340, 34)
	var sw := StyleBoxFlat.new()
	sw.bg_color = Color(0.10, 0.10, 0.10)
	sw.border_color = Color(0.30, 0.30, 0.30)
	sw.set_border_width_all(1)
	sw.corner_radius_bottom_left = 17
	sw.corner_radius_top_left    = 17
	search_wrap.add_theme_stylebox_override("panel", sw)

	var sh := HBoxContainer.new()
	sh.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sh.add_theme_constant_override("separation", 0)
	search_wrap.add_child(sh)
	_pad(sh, 14)
	var sl := _lbl(sh, "深夜ホラー配信を検索", 13, Color(0.40, 0.40, 0.40))
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl(sh, " 🔍", 16, C_MUTED)
	_pad(sh, 10)
	hbox.add_child(search_wrap)

	_pad(hbox, 6)
	_icon_btn(hbox, "🎤", 18)

	_spacer(hbox)

	# ── 右側アイコン群 ──
	_icon_btn(hbox, "📹", 18)
	_pad(hbox, 4)
	_notification_bell(hbox)
	_pad(hbox, 10)
	_avatar_circle(hbox, Color(0.55, 0.08, 0.08), "T", 28)
	_pad(hbox, 14)


# ── 通知ベルバッジ ──
func _notification_bell(parent: Node) -> void:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(30, 30)
	parent.add_child(wrap)
	var bell := _lbl(wrap, "🔔", 20, C_MUTED)
	bell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var badge := PanelContainer.new()
	badge.position = Vector2(16, 0)
	badge.custom_minimum_size = Vector2(14, 14)
	var bs := StyleBoxFlat.new()
	bs.bg_color = C_RED
	bs.set_corner_radius_all(7)
	badge.add_theme_stylebox_override("panel", bs)
	var bl := Label.new()
	bl.text = "9"
	bl.add_theme_font_size_override("font_size", 9)
	bl.add_theme_color_override("font_color", C_TEXT)
	bl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	hs.bg_color = Color(0.08, 0.08, 0.08)
	hs.border_color = C_BORDER
	hs.border_width_bottom = 1
	header.add_theme_stylebox_override("panel", hs)
	vbox.add_child(header)

	var h_hbox := _hbox(header, 0)
	h_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad(h_hbox, 10)

	var live_badge := _make_badge(" LIVE ", C_RED, 11)
	h_hbox.add_child(live_badge)
	_pad(h_hbox, 6)

	_lbl(h_hbox, "ライブチャット", 13, C_TEXT)
	_spacer(h_hbox)
	_lbl(h_hbox, "⚙", 16, C_MUTED)
	_pad(h_hbox, 6)
	_lbl(h_hbox, "✕", 14, C_MUTED)
	_pad(h_hbox, 10)

	# ─ チャットモード切替タブ ─
	var tab_bar := PanelContainer.new()
	tab_bar.custom_minimum_size = Vector2(0, 36)
	var tbs := StyleBoxFlat.new()
	tbs.bg_color = C_BG2
	tbs.border_color = C_BORDER
	tbs.border_width_bottom = 1
	tab_bar.add_theme_stylebox_override("panel", tbs)
	vbox.add_child(tab_bar)

	var tabs := _hbox(tab_bar, 0)
	tabs.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chat_tab(tabs, "トップチャット", true)
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
	_chat_vbox.add_theme_constant_override("separation", 1)
	_chat_scroll.add_child(_chat_vbox)

	# ─ 視聴者数表示 ─
	var view_wrap := PanelContainer.new()
	view_wrap.custom_minimum_size = Vector2(0, 28)
	var vws := StyleBoxFlat.new()
	vws.bg_color = Color(0.07, 0.07, 0.07)
	view_wrap.add_theme_stylebox_override("panel", vws)
	vbox.add_child(view_wrap)
	var vhbox := _hbox(view_wrap, 6)
	vhbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad(vhbox, 8)
	_live_dot = _lbl(vhbox, "●", 10, C_RED)
	_view_label = _lbl(vhbox, "%d 人が視聴中" % _view_count, 11, C_MUTED)
	_view_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# ─ チャット入力エリア ─
	var input_area := PanelContainer.new()
	input_area.custom_minimum_size = Vector2(0, 56)
	var ias := StyleBoxFlat.new()
	ias.bg_color = Color(0.08, 0.08, 0.08)
	ias.border_color = C_BORDER
	ias.border_width_top = 1
	input_area.add_theme_stylebox_override("panel", ias)
	vbox.add_child(input_area)

	var ia_vbox := VBoxContainer.new()
	ia_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ia_vbox.add_theme_constant_override("separation", 4)
	input_area.add_child(ia_vbox)

	_pad(ia_vbox, 4)
	var field_wrap := PanelContainer.new()
	field_wrap.custom_minimum_size = Vector2(0, 28)
	var fws := StyleBoxFlat.new()
	fws.bg_color = Color(0.13, 0.13, 0.13)
	fws.border_color = C_BORDER
	fws.set_border_width_all(1)
	fws.set_corner_radius_all(14)
	field_wrap.add_theme_stylebox_override("panel", fws)
	ia_vbox.add_child(field_wrap)

	var field_hbox := _hbox(field_wrap, 6)
	field_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad(field_hbox, 12)
	_lbl(field_hbox, "💬  チャットする...", 12, Color(0.40, 0.40, 0.40)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl(field_hbox, "😀  送信", 12, C_MUTED)
	_pad(field_hbox, 8)


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

	# ─ シークバー（ライブなので100%） ─
	var seek_wrap := Control.new()
	seek_wrap.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(seek_wrap)

	var track := ColorRect.new()
	track.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	track.color = Color(0.35, 0.35, 0.35)
	seek_wrap.add_child(track)

	var fill := ColorRect.new()
	fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	fill.anchor_right = 1.0
	fill.offset_right = -0.0
	fill.color = C_RED
	seek_wrap.add_child(fill)

	# シークドット（赤い丸）
	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(12, 12)
	dot.color = C_RED
	dot.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	dot.offset_left = -6
	dot.offset_top = -6
	seek_wrap.add_child(dot)

	# ─ コントロールボタン行 ─
	var btn_row := _hbox(vbox, 2)
	btn_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pad(btn_row, 8)
	_ctrl_btn(btn_row, "⏸", 16)
	_ctrl_btn(btn_row, "⏭", 14)
	_pad(btn_row, 4)

	# LIVE バッジ
	var live_w := _make_badge("  LIVE  ", C_RED, 11)
	btn_row.add_child(live_w)
	_pad(btn_row, 8)

	# 時刻表示
	_lbl(btn_row, "00:00 / LIVE", 11, C_MUTED)

	_spacer(btn_row)

	_ctrl_btn(btn_row, "CC", 10)
	_ctrl_btn(btn_row, "⚙", 16)
	_ctrl_btn(btn_row, "⧉", 14)
	_ctrl_btn(btn_row, "🔊", 14)
	_ctrl_btn(btn_row, "⛶", 16)
	_pad(btn_row, 8)


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

	var hbox := _hbox(bar, 0)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad(hbox, 12)

	# ─ アバター ─
	_avatar_circle(hbox, Color(0.55, 0.08, 0.08), "T", 36)
	_pad(hbox, 10)

	# ─ チャンネル名 + 登録者 ─
	var ch_box := VBoxContainer.new()
	ch_box.add_theme_constant_override("separation", 1)
	hbox.add_child(ch_box)
	_lbl(ch_box, "配信タロウ", 13, C_TEXT)
	_lbl(ch_box, "登録者 1.28万人", 11, C_MUTED)

	_pad(hbox, 12)

	# ─ 登録ボタン（赤） ─
	var sub_wrap := PanelContainer.new()
	var ss := StyleBoxFlat.new()
	ss.bg_color = C_RED
	ss.set_corner_radius_all(18)
	sub_wrap.add_theme_stylebox_override("panel", ss)
	hbox.add_child(sub_wrap)
	var sub_hbox := _hbox(sub_wrap, 4)
	_pad(sub_hbox, 14)
	_lbl(sub_hbox, "チャンネル登録", 13, C_TEXT)
	_lbl(sub_hbox, "🔔", 14, C_TEXT)
	_pad(sub_hbox, 14)

	_spacer(hbox)

	# ─ 高評価ボタン（ピル形） ─
	var like_wrap := PanelContainer.new()
	var lws := StyleBoxFlat.new()
	lws.bg_color = Color(0.16, 0.16, 0.16)
	lws.set_corner_radius_all(18)
	like_wrap.add_theme_stylebox_override("panel", lws)
	hbox.add_child(like_wrap)
	var like_hbox := _hbox(like_wrap, 6)
	_pad(like_hbox, 14)
	_like_label = _lbl(like_hbox, "👍  %s" % _fmt_count(_like_count), 13, C_TEXT)
	_lbl(like_hbox, "┃", 14, Color(0.30, 0.30, 0.30))
	_lbl(like_hbox, "👎", 14, C_TEXT)
	_pad(like_hbox, 14)

	_pad(hbox, 8)

	# ─ その他ボタン ─
	for btn_text: String in ["→  シェア", "✂  クリップ", "≡  保存", "⋯"]:
		var bw := PanelContainer.new()
		var bws := StyleBoxFlat.new()
		bws.bg_color = Color(0.16, 0.16, 0.16)
		bws.set_corner_radius_all(18)
		bw.add_theme_stylebox_override("panel", bws)
		hbox.add_child(bw)
		var bhbox := _hbox(bw, 0)
		_pad(bhbox, 12)
		_lbl(bhbox, btn_text, 12, C_TEXT)
		_pad(bhbox, 12)
		_pad(hbox, 6)

	_pad(hbox, 6)


# ════════════════════════════════════════════════════════════════
# フレーム更新
# ════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	# LIVE ドット点滅
	_live_t += delta
	if _live_t >= 0.6:
		_live_t = 0.0
		if is_instance_valid(_live_dot):
			_live_dot.visible = not _live_dot.visible

	# 視聴者数ゆらぎ
	_view_t += delta
	if _view_t >= 3.5:
		_view_t = 0.0
		_view_count = max(800, _view_count + randi_range(-30, 60))
		if is_instance_valid(_view_label):
			_view_label.text = "%d 人が視聴中" % _view_count

	# 高評価数ゆらぎ
	_like_t += delta
	if _like_t >= randf_range(20.0, 40.0):
		_like_t = 0.0
		_like_count += randi_range(5, 30)
		if is_instance_valid(_like_label):
			_like_label.text = "👍  %s" % _fmt_count(_like_count)

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
		"owner": Color(1.00, 0.84, 0.00),
		"moderator": Color(0.37, 0.52, 0.95),
		"member": Color(0.17, 0.65, 0.25),
		"viewer": Color(0.78, 0.78, 0.78),
	}

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_chat_vbox.add_child(row)

	_pad(row, 6)

	# メッセージ本体
	var txt := RichTextLabel.new()
	txt.bbcode_enabled = true
	txt.scroll_active = false
	txt.fit_content = true
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt.add_theme_font_size_override("normal_font_size", 12)

	var badge   : String = USER_BADGES.get(user_type, "")
	var col     : Color  = user_colors.get(user_type, Color(0.78, 0.78, 0.78))
	var col_hex : String = _col_to_hex(col)
	txt.bbcode_text = "%s[color=%s][b]%s[/b][/color]  [color=#b0b0b0]%s[/color]" \
		% [badge, col_hex, user, msg]
	row.add_child(txt)
	_pad(row, 6)

	# 上限25件
	while _chat_vbox.get_child_count() > 30:
		_chat_vbox.get_child(0).queue_free()

	await get_tree().process_frame
	if is_instance_valid(_chat_scroll):
		_chat_scroll.scroll_vertical = int(_chat_scroll.get_v_scroll_bar().max_value)


# ストーリー用スーパーチャット（名前・メッセージ・金額を指定）
func spawn_story_superchat(sc_name: String, sc_msg: String, amount: int) -> void:
	if not is_instance_valid(_superchat_area):
		return
	var tiers := [
		{ "min": 10000, "bg": Color(0.90, 0.10, 0.29) },
		{ "min": 5000,  "bg": Color(0.96, 0.45, 0.00) },
		{ "min": 2000,  "bg": Color(1.00, 0.76, 0.03) },
		{ "min": 1000,  "bg": Color(0.00, 0.74, 0.63) },
		{ "min": 200,   "bg": Color(0.13, 0.59, 0.95) },
	]
	var tier_col := Color(0.13, 0.59, 0.95)
	for t in tiers:
		if amount >= int(t["min"]):
			tier_col = t["bg"]
			break
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 52)
	var sc := StyleBoxFlat.new()
	sc.bg_color = tier_col
	sc.set_corner_radius_all(4)
	card.add_theme_stylebox_override("panel", sc)
	_superchat_area.add_child(card)
	var cvbox := VBoxContainer.new()
	cvbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(cvbox)
	var crow := _hbox(cvbox, 6)
	_pad(crow, 8)
	_avatar_circle(crow, tier_col.darkened(0.4), sc_name.substr(0, 1), 20)
	var nl := _lbl(crow, sc_name, 12, C_TEXT)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl(crow, "¥%d" % amount, 13, C_TEXT)
	_pad(crow, 8)
	var ml := _lbl(cvbox, "  " + sc_msg, 12, C_TEXT)
	ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	get_tree().create_timer(12.0).timeout.connect(card.queue_free, CONNECT_ONE_SHOT)


func _spawn_superchat() -> void:
	if not is_instance_valid(_superchat_area):
		return
	var amount : int    = [200, 500, 1000, 2000, 5000][randi() % 5]
	var name_  : String = SUPERCHAT_NAMES[randi() % SUPERCHAT_NAMES.size()]
	var msg_   : String = SUPERCHAT_MSGS[randi()  % SUPERCHAT_MSGS.size()]

	var superchat_tiers: Array = [
		{ "min": 10000, "bg": Color(0.90, 0.10, 0.29) },
		{ "min": 5000,  "bg": Color(0.96, 0.45, 0.00) },
		{ "min": 2000,  "bg": Color(1.00, 0.76, 0.03) },
		{ "min": 1000,  "bg": Color(0.00, 0.74, 0.63) },
		{ "min": 200,   "bg": Color(0.13, 0.59, 0.95) },
	]
	var tier_col := Color(0.13, 0.59, 0.95)
	for t: Dictionary in superchat_tiers:
		if amount >= int(t["min"]):
			tier_col = t["bg"]
			break

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 52)
	var cs := StyleBoxFlat.new()
	cs.bg_color = tier_col
	cs.set_corner_radius_all(4)
	card.add_theme_stylebox_override("panel", cs)
	_superchat_area.add_child(card)

	var cvbox := VBoxContainer.new()
	cvbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(cvbox)

	var crow := _hbox(cvbox, 6)
	_pad(crow, 8)
	_avatar_circle(crow, tier_col.darkened(0.4), name_.substr(0, 1), 20)
	var name_lbl := _lbl(crow, name_, 12, C_TEXT)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl(crow, "¥%d" % amount, 13, C_TEXT)
	_pad(crow, 8)
	var msg_lbl := _lbl(cvbox, "  " + msg_, 12, C_TEXT)
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# 一定時間後に削除
	await get_tree().create_timer(12.0).timeout
	if is_instance_valid(card):
		card.queue_free()


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
	w.add_theme_stylebox_override("panel", s)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", C_TEXT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	w.add_child(l)
	return w


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
	lbl.add_theme_font_size_override("font_size", int(size * 0.5))
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
	var l := _lbl(parent, icon, size, C_MUTED)
	l.custom_minimum_size = Vector2(28, 0)
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
