extends Area3D

## CP3 村の探索: 固有アイテム（木彫りの頭 / 錆びた鎌 / 写し鏡の御札）

const ItemResourceScript := preload("res://Inventory/ItemResource.gd")

@onready var mesh_inst : MeshInstance3D = $MeshInstance3D
@onready var glow      : OmniLight3D    = $GlowLight

var item_id : String = ""
var item_display_name : String = ""
var item_description  : String = ""
var item_image_path   : String = ""  # ポラロイド用画像パス
var item_dialogue     : String = ""  # 対応するdialogue JSON名
var item_mesh_type    : String = "sphere"  # メッシュ種別
var glow_color : Color = Color(0.3, 0.8, 0.4)

var bob_t : float = 0.0
var _item_resource : Resource = null
var _collected : bool = false


func _ready() -> void:
	bob_t = randf() * TAU
	body_entered.connect(_on_body_entered)

	_item_resource = ItemResourceScript.new()
	_item_resource.item_name = item_display_name
	_item_resource.quantity = 1
	_item_resource.description = item_description

	_setup_appearance()


func _setup_appearance() -> void:
	glow.light_color = glow_color
	glow.light_energy = 1.5
	glow.omni_range = 6.0

	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = glow_color * 0.3
	mat.emission_energy_multiplier = 0.5

	match item_mesh_type:
		"sphere":
			var sphere := SphereMesh.new()
			sphere.radius = 0.2
			sphere.height = 0.4
			mesh_inst.mesh = sphere
			mat.albedo_color = Color(0.45, 0.3, 0.15)
		"box_flat":
			var box := BoxMesh.new()
			box.size = Vector3(0.6, 0.05, 0.15)
			mesh_inst.mesh = box
			mat.albedo_color = Color(0.3, 0.15, 0.1)
		"box_thin":
			var box := BoxMesh.new()
			box.size = Vector3(0.12, 0.2, 0.01)
			mesh_inst.mesh = box
			mat.albedo_color = Color(0.9, 0.85, 0.7)
			mat.emission = glow_color * 0.4
			mat.emission_energy_multiplier = 0.8
		_:
			var sphere := SphereMesh.new()
			sphere.radius = 0.15
			sphere.height = 0.3
			mesh_inst.mesh = sphere
			mat.albedo_color = glow_color

	mesh_inst.material_override = mat


func _process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	bob_t += delta * 1.5
	mesh_inst.position.y = sin(bob_t) * 0.08
	mesh_inst.rotate_y(delta * 1.0)
	glow.light_energy = 1.5 + sin(bob_t * 1.5) * 0.5


func _on_body_entered(body: Node3D) -> void:
	if _collected:
		return
	if not body.is_in_group("player"):
		return
	_collected = true
	GameManager.collect_item()
	Inventory.collect.emit(_item_resource)
	# 鎌入手時: EncodingError に通知
	if item_id == "sabi_kama":
		var enc := get_tree().current_scene.get_node_or_null("EncodingError")
		if enc and enc.has_method("notify_kama_acquired"):
			enc.notify_kama_acquired()

	# ── ポラロイド風演出 ──
	await _show_polaroid()

	# dialogue JSON 演出を実行
	var json_name : String = item_dialogue
	if json_name == "":
		# フォールバック（旧互換）
		match item_id:
			"kibori_head": json_name = "ch02_mura_item_a"
			"sabi_kama":   json_name = "ch02_mura_item_b"
			"utsushi_ofuda": json_name = "ch02_mura_item_c"
	if json_name != "":
		var main : Node = get_tree().current_scene
		if main and main.has_method("_run_chapter_opening"):
			var player_node : Node = main.get_node_or_null("Player")
			if player_node:
				player_node.set("input_disabled", true)
				player_node.set("velocity", Vector3.ZERO)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			var enc_node : Node = main.get_node_or_null("EncodingError")
			if enc_node:
				enc_node.set_physics_process(false)
			await main._run_chapter_opening(json_name)
			if enc_node and is_instance_valid(enc_node) and not GameManager.autotest_active:
				enc_node.set_physics_process(true)
			if is_instance_valid(player_node):
				player_node.set("input_disabled", false)
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	visible = false
	queue_free()


## ポラロイド風アイテム入手演出
func _show_polaroid() -> void:
	SoundManager.play_sfx_file("metal/impactMetal_heavy_001.ogg")

	var main : Node = get_tree().current_scene
	var player_node : Node = main.get_node_or_null("Player") if main else null
	if player_node:
		player_node.set("input_disabled", true)

	var vp_size := get_viewport().get_visible_rect().size
	var canvas := CanvasLayer.new()
	canvas.layer = 140
	get_tree().root.add_child(canvas)

	# 背景暗幕
	var dim := ColorRect.new()
	dim.size = vp_size
	dim.color = Color(0, 0, 0, 0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(dim)

	# カードサイズ
	var card_w : float = 260.0
	var card_h : float = 350.0
	var card_x : float = (vp_size.x - card_w) * 0.5
	var card_y : float = (vp_size.y - card_h) * 0.5

	# 影
	var shadow := ColorRect.new()
	shadow.size = Vector2(card_w, card_h)
	shadow.position = Vector2(card_x + 5, card_y + 45.0)
	shadow.color = Color(0, 0, 0, 0.35)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.modulate.a = 0.0
	canvas.add_child(shadow)

	# ポラロイド白枠
	var polaroid := ColorRect.new()
	polaroid.size = Vector2(card_w, card_h)
	polaroid.position = Vector2(card_x, card_y + 40.0)
	polaroid.color = Color(0.94, 0.92, 0.88, 1.0)
	polaroid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	polaroid.modulate.a = 0.0
	polaroid.pivot_offset = Vector2(card_w * 0.5, card_h * 0.5)
	canvas.add_child(polaroid)

	# ── 写真エリア（画像 or グラデーション） ──
	var img_margin : float = 16.0
	var img_w : float = card_w - img_margin * 2
	var img_h : float = 180.0

	if item_image_path != "":
		var tex := load(item_image_path) as Texture2D
		if tex:
			var img_rect := TextureRect.new()
			img_rect.texture = tex
			img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			img_rect.custom_minimum_size = Vector2(img_w, img_h)
			img_rect.size = Vector2(img_w, img_h)
			img_rect.position = Vector2(img_margin, img_margin)
			img_rect.clip_contents = true
			img_rect.modulate = Color(0.92, 0.88, 0.82, 1.0)
			img_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			polaroid.add_child(img_rect)
	else:
		# 画像なしの場合はグラデーション的な背景
		var placeholder := ColorRect.new()
		placeholder.size = Vector2(img_w, img_h)
		placeholder.position = Vector2(img_margin, img_margin)
		placeholder.color = Color(0.15, 0.12, 0.1, 1.0)
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		polaroid.add_child(placeholder)

	# ── 写真の下にテープ風の飾り ──
	var tape := ColorRect.new()
	tape.size = Vector2(60, 14)
	tape.position = Vector2(card_w * 0.5 - 30, img_margin + img_h - 7)
	tape.color = Color(0.85, 0.8, 0.6, 0.4)
	tape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	polaroid.add_child(tape)

	# ── アイテム名 ──
	var title_lbl := Label.new()
	title_lbl.text = item_display_name
	title_lbl.size = Vector2(card_w, 32)
	title_lbl.position = Vector2(0, img_h + img_margin + 14)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08, 1.0))
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	polaroid.add_child(title_lbl)

	# ── 説明文 ──
	var desc_lbl := Label.new()
	desc_lbl.text = item_description
	desc_lbl.size = Vector2(card_w - 30, 40)
	desc_lbl.position = Vector2(15, img_h + img_margin + 46)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.35, 0.3, 0.25, 1.0))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	polaroid.add_child(desc_lbl)

	# ── 取得数（右下隅、手書き風） ──
	var count_lbl := Label.new()
	count_lbl.text = "%d / %d" % [GameManager.items_found, GameManager.items_total]
	count_lbl.size = Vector2(card_w - 20, 20)
	count_lbl.position = Vector2(10, card_h - 28)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_lbl.add_theme_font_size_override("font_size", 13)
	count_lbl.add_theme_color_override("font_color", Color(0.5, 0.4, 0.35, 0.7))
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	polaroid.add_child(count_lbl)

	# ── 画面上部テキスト ──
	var top_lbl := Label.new()
	top_lbl.text = "— %s を入手 —" % item_display_name
	top_lbl.size = Vector2(vp_size.x, 40)
	top_lbl.position = Vector2(0, card_y - 50)
	top_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_lbl.add_theme_font_size_override("font_size", 16)
	top_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 0.9))
	top_lbl.add_theme_constant_override("shadow_offset_x", 1)
	top_lbl.add_theme_constant_override("shadow_offset_y", 1)
	top_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	top_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_lbl.modulate.a = 0.0
	canvas.add_child(top_lbl)

	# ══ アニメーション ══

	# Phase 1: 暗幕 + ポラロイドがスッと現れる
	polaroid.rotation_degrees = randf_range(-5.0, 5.0)
	var tw_in := create_tween().set_parallel(true)
	tw_in.tween_property(dim, "color:a", 0.55, 0.3)
	tw_in.tween_property(shadow, "modulate:a", 1.0, 0.3)
	tw_in.tween_property(polaroid, "modulate:a", 1.0, 0.3)
	tw_in.tween_property(polaroid, "position:y", card_y, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_in.tween_property(shadow, "position:y", card_y + 5, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_in.tween_property(top_lbl, "modulate:a", 1.0, 0.3).set_delay(0.2)
	await tw_in.finished

	# Phase 2: 表示キープ
	await get_tree().create_timer(2.0).timeout

	# 全回収時: 金色に光る
	if GameManager.items_found >= GameManager.items_total:
		var tw_glow := create_tween()
		tw_glow.tween_property(polaroid, "modulate", Color(1.3, 1.15, 0.8, 1.0), 0.15)
		tw_glow.tween_property(polaroid, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
		await tw_glow.finished
		await get_tree().create_timer(0.5).timeout

	# Phase 3: フェードアウト
	var tw_out := create_tween().set_parallel(true)
	tw_out.tween_property(polaroid, "modulate:a", 0.0, 0.3)
	tw_out.tween_property(polaroid, "position:y", card_y - 25.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_out.tween_property(polaroid, "scale", Vector2(0.92, 0.92), 0.35)
	tw_out.tween_property(shadow, "modulate:a", 0.0, 0.25)
	tw_out.tween_property(dim, "color:a", 0.0, 0.35)
	tw_out.tween_property(top_lbl, "modulate:a", 0.0, 0.25)
	await tw_out.finished

	canvas.queue_free()


func _find_hud() -> Control:
	var main := get_tree().current_scene
	if main and main.has_node("HUDLayer/HUDRoot"):
		return main.get_node("HUDLayer/HUDRoot") as Control
	return null
