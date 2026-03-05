extends CanvasLayer

## ミニキャラ揺れローディングオーバーレイ（Autoload）
## LoadingScreen.show_loading() で表示、LoadingScreen.fade_out() で消去

var _chibi: TextureRect
var _label: Label
var _root: Control
var _dot_count := 0
var _dot_timer := 0.0
var _active := false

const CHIBI_TEX_PATH := "res://assets/textures/loading_chibi.png"


func _ready() -> void:
	layer = 100
	_build_ui()
	_root.visible = false


func _process(delta: float) -> void:
	if not _active:
		return
	_dot_timer += delta
	if _dot_timer >= 0.4:
		_dot_timer = 0.0
		_dot_count = (_dot_count + 1) % 4
		_label.text = "Now Loading" + ".".repeat(_dot_count + 1)


func show_loading() -> void:
	_root.visible = true
	_root.modulate.a = 1.0
	_active = true
	_dot_count = 0
	_dot_timer = 0.0
	_label.text = "Now Loading..."
	_start_chibi_anim()


func fade_out() -> void:
	_active = false
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.6)
	await tw.finished
	_root.visible = false


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	# 背景
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.016, 0.03, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	# ミニキャラ
	_chibi = TextureRect.new()
	var tex := load(CHIBI_TEX_PATH) as Texture2D
	if tex:
		_chibi.texture = tex
	_chibi.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_chibi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_chibi.set_anchors_preset(Control.PRESET_CENTER)
	_chibi.offset_left = -100
	_chibi.offset_top = -80
	_chibi.offset_right = 100
	_chibi.offset_bottom = 180
	_chibi.pivot_offset = Vector2(100, 130)
	_root.add_child(_chibi)

	# テキスト
	_label = Label.new()
	_label.text = "Now Loading..."
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_label.offset_left = -200
	_label.offset_top = -80
	_label.offset_right = 200
	_label.offset_bottom = -40
	_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
	_label.add_theme_font_size_override("font_size", 22)
	_root.add_child(_label)


func _start_chibi_anim() -> void:
	# 既存Tweenをリセット
	_chibi.rotation_degrees = 0.0

	# 左右揺れ
	var tw_rot := create_tween().set_loops()
	tw_rot.tween_property(_chibi, "rotation_degrees", 5.0, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw_rot.tween_property(_chibi, "rotation_degrees", -5.0, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 上下ふわふわ
	var base_y := _chibi.position.y
	var tw_bob := create_tween().set_loops()
	tw_bob.tween_property(_chibi, "position:y", base_y - 8.0, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw_bob.tween_property(_chibi, "position:y", base_y + 8.0, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
