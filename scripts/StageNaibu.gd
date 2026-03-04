@tool
extends Node3D

## 廃村内部マップ（野外・広め）
## CP2（廃村内部）・CP4（廃村内部イベント）・CP5（脱出）で共用
## 構成: 南入口(Z+28) → 廃屋群 → 中央広場（井戸） → 廃屋群 → 北出口(Z-40)
## プレイヤースポーン: Vector3(0, 1.0, 25) / 出口: Vector3(0, 1.5, -38)

func _ready() -> void:
	for c in get_children(): c.queue_free()
	_build_ground()
	_build_path()
	_build_perimeter()
	_build_houses()
	_build_plaza()
	_build_trees()
	_build_pond()
	_build_story_props()
	if Engine.is_editor_hint():
		_set_editor_owner(self)

func _set_editor_owner(node: Node) -> void:
	for child in node.get_children():
		child.owner = get_tree().edited_scene_root
		_set_editor_owner(child)


# ════════════════════════════════════════════════════════════════
# ヘルパー
# ════════════════════════════════════════════════════════════════

## コリジョンあり（壁・床・障害物）
func _box(pos: Vector3, size: Vector3, col: Color) -> void:
	StageHelper.box(self, pos, size, col)

## コリジョンなし（草・瓦礫・葉などの装飾）
func _deco(pos: Vector3, size: Vector3, col: Color) -> void:
	StageHelper.deco(self, pos, size, col)


# ════════════════════════════════════════════════════════════════
# 地面
# ════════════════════════════════════════════════════════════════

func _build_ground() -> void:
	_box(Vector3(0, -0.1, 0), Vector3(160, 0.2, 160), Color(0.12, 0.27, 0.08))
	# 草むらパッチ（視覚的な変化・コリジョンなし）
	var patches := [
		Vector3(-12, 0, 22), Vector3(20, 0, 15), Vector3(-25, 0,  2),
		Vector3( 18, 0,-10), Vector3(-8, 0,-28), Vector3( 22, 0,-32),
		Vector3(-18, 0,-18), Vector3( 5, 0, 20), Vector3(-30, 0, -8),
		Vector3( 28, 0,  8), Vector3(-6, 0, 32), Vector3( 14, 0,-36),
	]
	for p in patches:
		_deco(p, Vector3(3.0, 0.06, 3.0), Color(0.16, 0.38, 0.10))


# ════════════════════════════════════════════════════════════════
# 砂利道（南北メインパス）
# ════════════════════════════════════════════════════════════════

func _build_path() -> void:
	_box(Vector3(0, 0.02, -7), Vector3(4.5, 0.06, 84), Color(0.46, 0.42, 0.36))
	# 轍（コリジョンなし・視覚のみ）
	_deco(Vector3(-1.5, 0.05, -7), Vector3(0.22, 0.04, 84), Color(0.36, 0.32, 0.26))
	_deco(Vector3( 1.5, 0.05, -7), Vector3(0.22, 0.04, 84), Color(0.36, 0.32, 0.26))


# ════════════════════════════════════════════════════════════════
# 外周壁・フェンス
# ════════════════════════════════════════════════════════════════

func _build_perimeter() -> void:
	# 北壁（出口付近・中央4m幅が開口）
	_box(Vector3(-30, 0.65, -40), Vector3(28, 1.3, 0.8), Color(0.52, 0.49, 0.44))
	_box(Vector3( 30, 0.65, -40), Vector3(28, 1.3, 0.8), Color(0.52, 0.49, 0.44))
	# 北出口の門柱（開口部のランドマーク）
	_box(Vector3(-4.5, 1.8, -40), Vector3(0.9, 3.6, 0.9), Color(0.58, 0.55, 0.50))
	_box(Vector3( 4.5, 1.8, -40), Vector3(0.9, 3.6, 0.9), Color(0.58, 0.55, 0.50))
	_box(Vector3(0,    3.8, -40), Vector3(11,  0.7, 0.7), Color(0.52, 0.49, 0.44))

	# 東西外壁（部分的に崩れた石垣）
	_box(Vector3( 40, 0.9, -5), Vector3(0.8, 1.8, 70), Color(0.50, 0.47, 0.41))
	_box(Vector3(-40, 0.9, -5), Vector3(0.8, 1.8, 70), Color(0.50, 0.47, 0.41))

	# 南入口（低い石垣・中央に開口）
	_box(Vector3(-18, 0.4, 28), Vector3(28, 0.8, 0.7), Color(0.48, 0.45, 0.40))
	_box(Vector3( 18, 0.4, 28), Vector3(28, 0.8, 0.7), Color(0.48, 0.45, 0.40))


# ════════════════════════════════════════════════════════════════
# 廃屋群（6棟・左右3棟ずつ）
# ════════════════════════════════════════════════════════════════

func _build_houses() -> void:
	# 南エリア
	_build_ruin(Vector3(-14, 0,  18), 10, 8, Color(0.60, 0.54, 0.46))
	_build_ruin(Vector3( 14, 0,  18),  9, 7, Color(0.57, 0.51, 0.43))
	# 中央エリア
	_build_ruin(Vector3(-17, 0,  -1), 12, 9, Color(0.62, 0.56, 0.48))
	_build_ruin(Vector3( 16, 0,  -1), 11, 8, Color(0.58, 0.52, 0.44))
	# 北エリア
	_build_ruin(Vector3(-14, 0, -22),  9, 8, Color(0.56, 0.50, 0.42))
	_build_ruin(Vector3( 14, 0, -22),  8, 9, Color(0.59, 0.53, 0.45))


func _build_ruin(center: Vector3, w: float, d: float, col: Color) -> void:
	var hw  := w * 0.5
	var hd  := d * 0.5
	var wh  := 2.6   # 壁の高さ
	var thk := 0.35  # 壁の厚み

	# 基礎（コリジョンなし）
	_deco(center + Vector3(0, 0.04, 0), Vector3(w, 0.08, d), col.darkened(0.35))

	# 北壁（ほぼ完全に残存）
	_box(center + Vector3(0, wh * 0.5, -hd), Vector3(w, wh, thk), col)
	# 西壁（上半分崩落）
	_box(center + Vector3(-hw, wh * 0.3, 0), Vector3(thk, wh * 0.6, d), col.darkened(0.08))
	# 南壁（部分的に残存）
	_box(center + Vector3(-hw * 0.4, wh * 0.35, hd),
		 Vector3(w * 0.4, wh * 0.7, thk), col.darkened(0.05))
	# 東壁（ほぼ崩落・低い残骸のみ）
	_box(center + Vector3(hw, wh * 0.15, hd * 0.5),
		 Vector3(thk, wh * 0.30, d * 0.45), col.darkened(0.12))

	# 瓦礫（崩れた壁の欠片・コリジョンなし）
	_deco(center + Vector3( hw * 0.55, 0.18,       0), Vector3(2.0, 0.36, 0.9), col.darkened(0.18))
	_deco(center + Vector3(-hw * 0.45, 0.10, hd * 0.6), Vector3(1.1, 0.20, 0.7), col.darkened(0.12))
	_deco(center + Vector3(       0.3, 0.12, hd * 0.3), Vector3(0.6, 0.24, 0.5), col.darkened(0.10))


# ════════════════════════════════════════════════════════════════
# 中央広場
# ════════════════════════════════════════════════════════════════

func _build_plaza() -> void:
	# 石畳（コリジョンなし・路面より明るい）
	_deco(Vector3(0, 0.03, -6), Vector3(22, 0.06, 18), Color(0.44, 0.41, 0.37))

	# 井戸（パスの左脇・X=-6）
	_build_well(Vector3(-6, 0, -8))

	# 石のベンチ
	_box(Vector3( 6, 0.22, -6), Vector3(2.0, 0.44, 0.65), Color(0.50, 0.48, 0.44))
	_box(Vector3(-9, 0.22, -4), Vector3(2.0, 0.44, 0.65), Color(0.50, 0.48, 0.44))

	# 朽ちた掲示板
	_box(Vector3(7, 0.7, 10),    Vector3(0.12, 1.4, 0.12), Color(0.32, 0.25, 0.16))
	_deco(Vector3(7, 1.55, 10),  Vector3(1.8,  0.9, 0.10), Color(0.40, 0.32, 0.20))

	# 朽ちた農機具（大きな箱）
	_box(Vector3(-10, 0.35, 14), Vector3(3.0, 0.70, 1.5), Color(0.38, 0.34, 0.28))
	_box(Vector3(-10, 0.80, 14), Vector3(1.0, 0.40, 1.2), Color(0.32, 0.28, 0.22))


func _build_well(pos: Vector3) -> void:
	# 井戸枠（8角形近似）
	for i in range(8):
		var angle := i * TAU / 8.0
		var wx := cos(angle) * 0.85
		var wz := sin(angle) * 0.85
		_box(pos + Vector3(wx, 0.45, wz), Vector3(0.30, 0.90, 0.30), Color(0.48, 0.46, 0.42))
	# 支柱
	_box(pos + Vector3(-0.8, 1.9, 0), Vector3(0.14, 2.0, 0.14), Color(0.38, 0.30, 0.20))
	_box(pos + Vector3( 0.8, 1.9, 0), Vector3(0.14, 2.0, 0.14), Color(0.38, 0.30, 0.20))
	# 横梁
	_box(pos + Vector3(0, 2.95, 0), Vector3(1.8, 0.12, 0.12), Color(0.34, 0.26, 0.16))
	# 桶受け（コリジョンなし）
	_deco(pos + Vector3(0, 3.06, 0), Vector3(2.2, 0.10, 0.50), Color(0.30, 0.22, 0.12))


# ════════════════════════════════════════════════════════════════
# 木々
# ════════════════════════════════════════════════════════════════

func _build_trees() -> void:
	var positions := [
		Vector3(-26, 0,  22), Vector3(-30, 0,   5), Vector3(-27, 0, -14),
		Vector3(-23, 0, -30), Vector3( 26, 0,  22), Vector3( 30, 0,   5),
		Vector3( 27, 0, -14), Vector3( 23, 0, -30), Vector3(  8, 0,  26),
		Vector3( -8, 0,  26), Vector3(  0, 0, -36),
	]
	for p in positions:
		_build_tree(p)


func _build_tree(pos: Vector3) -> void:
	# 幹（コリジョンあり）
	_box(pos + Vector3(0, 2.5, 0), Vector3(0.45, 5.0, 0.45), Color(0.28, 0.20, 0.12))
	# 葉（コリジョンなし・3段）
	_deco(pos + Vector3(0, 5.5, 0), Vector3(4.0, 1.0, 4.0), Color(0.07, 0.19, 0.05))
	_deco(pos + Vector3(0, 6.6, 0), Vector3(3.0, 0.8, 3.0), Color(0.05, 0.15, 0.04))
	_deco(pos + Vector3(0, 7.5, 0), Vector3(1.8, 0.6, 1.8), Color(0.04, 0.11, 0.03))


# ════════════════════════════════════════════════════════════════
# 鏡の池（CP4 ストーリースポット・X=18 Z=-30 付近）
# ════════════════════════════════════════════════════════════════

func _build_pond() -> void:
	# 池の水面（反射を想起させる暗い水色・コリジョンなし）
	_deco(Vector3(18, 0.04, -30), Vector3(9.0, 0.06, 7.0), Color(0.04, 0.08, 0.14))

	# 水面の光沢（中央に薄い明るい層）
	_deco(Vector3(18, 0.055, -30), Vector3(7.5, 0.01, 5.5), Color(0.06, 0.12, 0.20, 0.7))

	# 池縁の石（コリジョンあり）
	var rim_stones := [
		# 北辺
		Vector3(13.5, 0.12, -33.5), Vector3(15.5, 0.10, -33.5),
		Vector3(18.0, 0.12, -33.5), Vector3(20.5, 0.10, -33.5),
		Vector3(22.5, 0.12, -33.5),
		# 南辺
		Vector3(13.5, 0.12, -26.5), Vector3(16.0, 0.10, -26.5),
		Vector3(18.0, 0.12, -26.5), Vector3(20.0, 0.10, -26.5),
		Vector3(22.5, 0.12, -26.5),
		# 西辺
		Vector3(13.5, 0.12, -29.0), Vector3(13.5, 0.10, -31.0),
		# 東辺
		Vector3(22.5, 0.12, -29.0), Vector3(22.5, 0.10, -31.0),
	]
	for s in rim_stones:
		_box(s, Vector3(0.7, 0.24, 0.5), Color(0.44, 0.41, 0.37))

	# 池の前に立つ朽ちた木製看板（「立入禁止」想定）
	_box(Vector3(14.5, 0.9, -26.0), Vector3(0.12, 1.8, 0.12), Color(0.30, 0.22, 0.14))
	_deco(Vector3(14.5, 1.95, -26.0), Vector3(1.4, 0.55, 0.10), Color(0.38, 0.28, 0.18))

	# OmniLight（池の反射を演出する薄い青白い光）
	var pond_light := OmniLight3D.new()
	pond_light.position     = Vector3(18.0, 1.2, -30.0)
	pond_light.light_color  = Color(0.42, 0.62, 0.90)
	pond_light.light_energy = 0.8
	pond_light.omni_range   = 8.0
	add_child(pond_light)


# ════════════════════════════════════════════════════════════════
# ストーリー小物（目のない人形・鳥居+祠・スマホの山）
# ════════════════════════════════════════════════════════════════

func _build_story_props() -> void:
	_build_dolls()
	_build_shrine()
	_build_phone_pile()


## 眼のない白磁人形を3棟の廃屋内に配置
func _build_dolls() -> void:
	# 南西廃屋（X=-14, Z=18）、東中央廃屋（X=16, Z=-1）、北西廃屋（X=-14, Z=-22）
	var doll_pts : Array[Vector3] = [
		Vector3(-12.0, 0.0,  20.0),
		Vector3( 17.0, 0.0,  -1.5),
		Vector3(-12.0, 0.0, -20.0),
	]
	for dp in doll_pts:
		_build_doll(dp)


func _build_doll(pos: Vector3) -> void:
	var col_porcelain := Color(0.90, 0.88, 0.84)   # 白磁
	var col_eye_hole  := Color(0.06, 0.04, 0.04)   # 黒い眼窩（目がない）
	var col_hair      := Color(0.08, 0.06, 0.05)   # 黒髪

	# 胴体（着物風の縦長ブロック）
	_deco(pos + Vector3(0, 0.40, 0), Vector3(0.20, 0.80, 0.13), col_porcelain)
	# 頭
	_deco(pos + Vector3(0, 0.90, 0), Vector3(0.17, 0.17, 0.17), col_porcelain)
	# 髪（頭の上）
	_deco(pos + Vector3(0, 1.00, 0), Vector3(0.18, 0.08, 0.18), col_hair)
	# 眼窩・左（目のない空洞）
	_deco(pos + Vector3(-0.04, 0.93, -0.09), Vector3(0.04, 0.04, 0.02), col_eye_hole)
	# 眼窩・右
	_deco(pos + Vector3( 0.04, 0.93, -0.09), Vector3(0.04, 0.04, 0.02), col_eye_hole)

	# 薄い青白い光（人形の怪異感）
	var doll_light := OmniLight3D.new()
	doll_light.position     = pos + Vector3(0, 0.8, 0)
	doll_light.light_color  = Color(0.80, 0.85, 1.0)
	doll_light.light_energy = 0.35
	doll_light.omni_range   = 3.5
	add_child(doll_light)


## 鳥居 + 祠（東側・中央エリア）
func _build_shrine() -> void:
	var pos := Vector3(24.0, 0.0, -10.0)
	var col_torii := Color(0.70, 0.10, 0.05)   # 朱赤（経年で暗い）
	var col_wood  := Color(0.44, 0.38, 0.28)   # 木材

	# 鳥居・左柱
	_box(pos + Vector3(-0.90, 1.55, 0.0), Vector3(0.20, 3.1, 0.20), col_torii)
	# 鳥居・右柱
	_box(pos + Vector3( 0.90, 1.55, 0.0), Vector3(0.20, 3.1, 0.20), col_torii)
	# 鳥居・笠木（上横梁）
	_box(pos + Vector3(0, 3.25, 0.0),     Vector3(2.3, 0.16, 0.22), col_torii)
	# 鳥居・島木（下横梁）
	_box(pos + Vector3(0, 2.85, 0.0),     Vector3(2.0, 0.12, 0.18), col_torii)

	# 祠・基礎台
	_box(pos + Vector3(0, 0.15, -2.8),   Vector3(1.6, 0.30, 1.4), col_wood.darkened(0.2))
	# 祠・本体
	_box(pos + Vector3(0, 0.80, -2.8),   Vector3(1.4, 1.0, 1.2),  col_wood)
	# 祠・屋根
	_deco(pos + Vector3(0, 1.45, -2.8),  Vector3(1.7, 0.22, 1.5), col_wood.darkened(0.25))

	# 参道の石畳（鳥居から祠まで）
	_deco(pos + Vector3(0, 0.02, -1.4),  Vector3(1.0, 0.04, 2.8), Color(0.42, 0.39, 0.35))

	# 薄い赤みがかった光（古い鳥居の雰囲気）
	var shrine_light := OmniLight3D.new()
	shrine_light.position     = pos + Vector3(0, 2.0, -2.0)
	shrine_light.light_color  = Color(1.0, 0.55, 0.30)
	shrine_light.light_energy = 0.5
	shrine_light.omni_range   = 5.5
	add_child(shrine_light)


## 西中央廃屋（X=-17, Z=-1）内に積み重なったスマホの山
func _build_phone_pile() -> void:
	var base := Vector3(-15.5, 0.0, -2.0)
	var phone_dark := Color(0.12, 0.12, 0.15)
	var screen_glow := Color(0.50, 0.68, 0.95, 0.85)

	# スマホ本体（不規則に積み重ね・5台）
	_deco(base + Vector3( 0.00, 0.018, 0.00), Vector3(0.13, 0.018, 0.065), phone_dark)
	_deco(base + Vector3( 0.04, 0.038, 0.02), Vector3(0.13, 0.018, 0.065), phone_dark)
	_deco(base + Vector3(-0.03, 0.058, -0.01), Vector3(0.12, 0.018, 0.060), phone_dark)
	_deco(base + Vector3( 0.02, 0.078, 0.03), Vector3(0.13, 0.018, 0.065), phone_dark)
	_deco(base + Vector3(-0.02, 0.098, -0.02), Vector3(0.11, 0.018, 0.058), phone_dark)

	# 画面の淡い発光（不気味な青白い光）
	_deco(base + Vector3( 0.00, 0.026, 0.00), Vector3(0.10, 0.004, 0.055), screen_glow)
	_deco(base + Vector3(-0.03, 0.066, -0.01), Vector3(0.09, 0.004, 0.050), screen_glow)

	# スマホ山のグロー光（青白い）
	var pile_light := OmniLight3D.new()
	pile_light.position     = base + Vector3(0, 0.5, 0)
	pile_light.light_color  = Color(0.55, 0.72, 1.0)
	pile_light.light_energy = 0.7
	pile_light.omni_range   = 4.5
	add_child(pile_light)
