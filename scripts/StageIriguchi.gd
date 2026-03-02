extends Node3D

## 廃村入口マップ（仮実装）
## 構成: バス停 → 砂利道 → 畑 → 村の門（看板付き）
## CSGBox3D のマテリアル問題を回避するため MeshInstance3D + StaticBody3D で実装

func _ready() -> void:
	_build_ground()
	_build_road()
	_build_fields()
	_build_bus_stop()
	_build_gate()
	_build_toilet()
	_build_toilet_deco()


# ── ヘルパー: コリジョンなし（装飾専用）────────────────────────
func _deco(pos: Vector3, size: Vector3, col: Color) -> void:
	var mi   := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh   = mesh
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mesh.material = mat
	add_child(mi)


# ── ヘルパー: MeshInstance3D + StaticBody3D を生成 ───────────────
func _box(pos: Vector3, size: Vector3, col: Color) -> void:
	# 表示メッシュ
	var mi   := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh   = mesh
	mi.position = pos

	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mesh.material = mat
	add_child(mi)

	# コリジョン（StaticBody3D）
	var sb    := StaticBody3D.new()
	sb.position = pos
	var cs    := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape   = shape
	sb.add_child(cs)
	add_child(sb)


# ── 地面 ─────────────────────────────────────────────────────────
func _build_ground() -> void:
	_box(Vector3(0, -0.1, 0), Vector3(100, 0.2, 100), Color(0.18, 0.38, 0.12))


# ── 砂利道 ───────────────────────────────────────────────────────
func _build_road() -> void:
	_box(Vector3(0, 0.01, -2), Vector3(4.5, 0.05, 42), Color(0.55, 0.52, 0.46))
	_box(Vector3(-2.6, 0.03, -2), Vector3(0.3, 0.04, 42), Color(0.40, 0.38, 0.34))
	_box(Vector3( 2.6, 0.03, -2), Vector3(0.3, 0.04, 42), Color(0.40, 0.38, 0.34))


# ── 畑 ───────────────────────────────────────────────────────────
func _build_fields() -> void:
	_box(Vector3(-12, 0.05, -1), Vector3(16, 0.10, 24), Color(0.22, 0.48, 0.14))
	_box(Vector3( 12, 0.05, -1), Vector3(16, 0.10, 24), Color(0.22, 0.48, 0.14))

	for i in range(6):
		_box(Vector3(-12, 0.16, 10.0 - i * 4.0), Vector3(14.0, 0.10, 0.45), Color(0.28, 0.58, 0.18))
	for i in range(6):
		_box(Vector3( 12, 0.16, 10.0 - i * 4.0), Vector3(14.0, 0.10, 0.45), Color(0.28, 0.58, 0.18))


# ── バス停 ───────────────────────────────────────────────────────
func _build_bus_stop() -> void:
	_box(Vector3(8.0, 0.08, 13.0), Vector3(5.0, 0.16, 3.2),  Color(0.50, 0.45, 0.38))  # ベース
	_box(Vector3(8.0, 1.4,  11.7), Vector3(5.0, 2.8,  0.15), Color(0.72, 0.65, 0.55))  # 後壁
	_box(Vector3(8.0, 2.85, 12.8), Vector3(5.2, 0.18, 3.2),  Color(0.78, 0.70, 0.60))  # 屋根
	_box(Vector3(5.6, 1.4,  13.1), Vector3(0.18, 2.8, 0.18), Color(0.60, 0.55, 0.48))  # 左支柱
	_box(Vector3(10.4, 1.4, 13.1), Vector3(0.18, 2.8, 0.18), Color(0.60, 0.55, 0.48))  # 右支柱
	_box(Vector3(8.0, 0.48, 12.0), Vector3(3.8, 0.14, 0.65), Color(0.48, 0.38, 0.28))  # ベンチ座面
	_box(Vector3(6.3, 0.30, 12.0), Vector3(0.14, 0.28, 0.60), Color(0.42, 0.33, 0.24)) # ベンチ脚L
	_box(Vector3(9.7, 0.30, 12.0), Vector3(0.14, 0.28, 0.60), Color(0.42, 0.33, 0.24)) # ベンチ脚R

	# 街灯柱: バス停手前・道路際（プレイヤー初期視線上に配置）
	# プレイヤーが (0,1,15) で右向き(+X方向)を向いたとき正面に見える位置
	_box(Vector3(5.2, 2.2, 14.8), Vector3(0.14, 4.4, 0.14), Color(0.35, 0.35, 0.38))  # 柱
	_box(Vector3(5.2, 4.55, 14.8), Vector3(0.5, 0.18, 0.5),  Color(0.30, 0.30, 0.32)) # 灯具ハウジング

	var street_lamp := SpotLight3D.new()
	street_lamp.position     = Vector3(5.2, 4.4, 14.8)
	street_lamp.light_color  = Color(1.0, 0.92, 0.72)   # 電球色（暖色）
	street_lamp.light_energy = 6.0
	street_lamp.spot_range   = 14.0
	street_lamp.spot_angle   = 60.0
	add_child(street_lamp)
	street_lamp.look_at(Vector3(8.0, 5.0, 12.0))  # バス停後壁の上部に向ける（地面に当てない）


# ── 村の門 ───────────────────────────────────────────────────────
func _build_gate() -> void:
	_box(Vector3(-3.5, 2.2, -14.0), Vector3(1.0, 4.4, 1.0), Color(0.58, 0.55, 0.50))  # 左柱
	_box(Vector3( 3.5, 2.2, -14.0), Vector3(1.0, 4.4, 1.0), Color(0.58, 0.55, 0.50))  # 右柱
	_box(Vector3(0, 4.7, -14.0),    Vector3(9.0, 0.8, 0.9), Color(0.52, 0.49, 0.44))  # 上梁
	_box(Vector3(0, 5.65, -14.0),   Vector3(6.5, 1.0, 0.20), Color(0.35, 0.26, 0.16)) # 看板
	_box(Vector3(-2.8, 5.65, -13.92), Vector3(0.12, 0.75, 0.08), Color(0.65, 0.55, 0.40)) # 金具L
	_box(Vector3( 2.8, 5.65, -13.92), Vector3(0.12, 0.75, 0.08), Color(0.65, 0.55, 0.40)) # 金具R
	_box(Vector3(-8.0, 0.5, -14.0), Vector3(8.0, 1.0, 0.8), Color(0.55, 0.52, 0.48))  # 左石垣
	_box(Vector3( 8.0, 0.5, -14.0), Vector3(8.0, 1.0, 0.8), Color(0.55, 0.52, 0.48))  # 右石垣


# ── 公衆トイレ（門くぐって右の脇道奥） ─────────────────────────
func _build_toilet() -> void:
	var col_c := Color(0.50, 0.50, 0.48)  # コンクリート（古びた灰色）
	var col_f := Color(0.42, 0.41, 0.39)  # 床タイル
	var col_w := Color(0.36, 0.28, 0.20)  # 木製仕切り
	var col_s := Color(0.85, 0.84, 0.82)  # 衛生器具

	# ── 脇道（右石垣 X=12 から建物入口 Z=-17 まで） ──
	_box(Vector3(15.5, 0.02, -15.5), Vector3(7.5, 0.05, 3.5), Color(0.46, 0.42, 0.38))

	# ── 建物外壁（X=14.5〜21.5 / Z=-17〜-27） ──
	# 屋根
	_box(Vector3(18.0, 3.3, -22.0), Vector3(7.4, 0.22, 10.4), col_c.darkened(0.15))
	# 床
	_box(Vector3(18.0, 0.02, -22.0), Vector3(6.8, 0.04,  9.8), col_f)
	# 南壁（入口 X=17〜19 が開口 → 2m のスキマ）
	_box(Vector3(15.7, 1.6, -17.0), Vector3(2.4, 3.2, 0.28), col_c)  # 西側
	_box(Vector3(20.5, 1.6, -17.0), Vector3(2.0, 3.2, 0.28), col_c)  # 東側
	# 北壁
	_box(Vector3(18.0, 1.6, -27.0), Vector3(7.0, 3.2, 0.28), col_c)
	# 東壁
	_box(Vector3(21.5, 1.6, -22.0), Vector3(0.28, 3.2, 10.0), col_c)
	# 西壁
	_box(Vector3(14.5, 1.6, -22.0), Vector3(0.28, 3.2, 10.0), col_c)

	# ── 廊下（西側 X=14.5〜17）と個室（東側 X=17〜21.5）を分ける縦仕切り ──
	# 入口付近（Z=-17〜-18.5）は開口させ、奥は壁
	_box(Vector3(17.0, 1.5, -22.8), Vector3(0.22, 3.0, 8.2), col_w)

	# ── 個室の横仕切り（3つの個室に分割） ──
	# 仕切り1（手前〜中の境界）Z=-21
	_box(Vector3(19.5, 1.5, -21.0), Vector3(4.8, 3.0, 0.18), col_w)
	# 仕切り2（中〜奥の境界）Z=-24.5
	_box(Vector3(19.5, 1.5, -24.5), Vector3(4.8, 3.0, 0.18), col_w)

	# ── 個室扉（開放状態 → 廊下側に沿って配置） ──
	_box(Vector3(17.12, 1.0, -19.0), Vector3(0.08, 2.0, 1.5), col_w.lightened(0.05))  # 個室3（手前）
	_box(Vector3(17.12, 1.0, -22.8), Vector3(0.08, 2.0, 1.5), col_w.lightened(0.05))  # 個室2（中・奥から2つ目）
	_box(Vector3(17.12, 1.0, -26.0), Vector3(0.08, 2.0, 1.2), col_w.lightened(0.05))  # 個室1（奥）

	# ── 便器（各個室の北奥に配置） ──
	_box(Vector3(20.5, 0.28, -20.0), Vector3(0.65, 0.55, 0.75), col_s)  # 個室3（手前）
	_box(Vector3(20.5, 0.28, -23.4), Vector3(0.65, 0.55, 0.75), col_s)  # 個室2（奥から2つ目 ★）
	_box(Vector3(20.5, 0.28, -26.3), Vector3(0.65, 0.55, 0.75), col_s)  # 個室1（奥）

	# ── 廊下設備（手洗い台・鏡） ──
	_box(Vector3(15.8, 0.85, -18.5), Vector3(1.2, 0.06, 0.55), col_s)                    # 手洗い台天板
	_box(Vector3(15.8, 0.42, -18.5), Vector3(1.0, 0.80, 0.45), Color(0.70, 0.68, 0.66))  # 台座
	_box(Vector3(15.8, 1.65, -18.4), Vector3(1.0, 1.20, 0.06), Color(0.44, 0.43, 0.41))  # 鏡枠

	# ── 外観：看板（「公衆トイレ」想定 → 後でテキスト追加可） ──
	_box(Vector3(18.0, 2.8, -17.0), Vector3(2.8, 0.65, 0.14), Color(0.30, 0.26, 0.22))  # 板
	_box(Vector3(16.5, 1.4, -17.0), Vector3(0.14, 2.8, 0.14), Color(0.38, 0.34, 0.28)) # 支柱L
	_box(Vector3(19.5, 1.4, -17.0), Vector3(0.14, 2.8, 0.14), Color(0.38, 0.34, 0.28)) # 支柱R

	# ── 廊下の蛍光灯（青白い・不安定な雰囲気） ──
	var lamp := OmniLight3D.new()
	lamp.position     = Vector3(15.8, 2.8, -22.0)
	lamp.light_color  = Color(0.82, 0.90, 0.75)
	lamp.light_energy = 1.6
	lamp.omni_range   = 10.0
	add_child(lamp)


# ── トイレ内部デコレーション（目の札・スマホ破片） ─────────────
func _build_toilet_deco() -> void:
	var col_wood := Color(0.32, 0.24, 0.14)
	var col_eye  := Color(0.06, 0.04, 0.04)   # 黒い眼窩

	# ── 個室扉の上部に貼られた「目の札」（3枚） ──
	# 個室3扉（Z≈-19）
	_build_eye_tag(Vector3(17.06, 1.6, -19.0), col_wood, col_eye)
	# 個室2扉（Z≈-22.8）★スマホのある個室
	_build_eye_tag(Vector3(17.06, 1.6, -22.8), col_wood, col_eye)
	# 個室1扉（Z≈-26.0）
	_build_eye_tag(Vector3(17.06, 1.6, -26.0), col_wood, col_eye)

	# ── 個室2の床にあるスマホ破片（1994年刻印・霊の遺物） ──
	# 画面割れたスマホ本体
	_deco(Vector3(20.0, 0.03, -23.5), Vector3(0.13, 0.018, 0.065), Color(0.14, 0.14, 0.17))
	# 割れた画面（青白い光で内側から光っている）
	_deco(Vector3(20.0, 0.04, -23.5), Vector3(0.10, 0.005, 0.055), Color(0.55, 0.70, 0.95, 0.7))
	# スマホの青白いグロー光
	var phone_light := OmniLight3D.new()
	phone_light.position     = Vector3(20.0, 0.35, -23.5)
	phone_light.light_color  = Color(0.65, 0.80, 1.0)
	phone_light.light_energy = 0.9
	phone_light.omni_range   = 2.8
	add_child(phone_light)


func _build_eye_tag(pos: Vector3, col_wood: Color, col_eye: Color) -> void:
	# 木製の札（縦長・薄い板）
	_deco(pos,                                   Vector3(0.04, 0.28, 0.18), col_wood)
	# 左の眼窩（暗い楕円を2つのboxで近似）
	_deco(pos + Vector3(0.03, 0.04,  0.04),      Vector3(0.02, 0.07, 0.05), col_eye)
	# 右の眼窩
	_deco(pos + Vector3(0.03, 0.04, -0.04),      Vector3(0.02, 0.07, 0.05), col_eye)
