extends Area3D

## CP3 村の探索: アイテム使用ポイント（案山子に頭を載せる / 門の紐を鎌で切る）

var required_item : String = ""      # Inventory 内の item_name と一致させる
var use_message   : String = ""      # 使用成功時のメッセージ
var locked_message: String = ""      # アイテム未所持時のメッセージ
var point_id      : String = ""      # "kakashi" / "mon"

var _used : bool = false
var _cooldown : float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or _used:
		return
	if _cooldown > 0.0:
		return

	var has_item : bool = Inventory.items.has(required_item)
	if has_item:
		_used = true
		Inventory.remove_item(required_item)
		_play_use_effect()
		_show_message(use_message)
		_play_visual_effect(body)
	else:
		_cooldown = 5.0
		_show_message(locked_message)


func _play_use_effect() -> void:
	match point_id:
		"kakashi":
			SoundManager.play_sfx_file("metal/impactMetal_heavy_003.ogg")
		"mon":
			SoundManager.play_sfx_file("door/creak1.ogg")


func _play_visual_effect(player: Node3D) -> void:
	# 画面フラッシュ + カメラシェイク
	var hud := _find_hud()
	if not hud:
		return

	# カメラシェイク
	if player.has_method("start_camera_shake"):
		player.start_camera_shake(0.04, 0.6)

	match point_id:
		"kakashi":
			# 案山子: 赤い閃光 → 結界解除の不気味な光
			_flash_screen(hud, Color(0.6, 0.05, 0.05, 0.5), 0.8)
		"mon":
			# 門: 白い閃光 → 切断の鋭い光
			_flash_screen(hud, Color(0.9, 0.9, 1.0, 0.6), 0.4)

	# 使用ポイントのライトを消す
	var light := get_node_or_null("PointLight")
	if light:
		var tw := create_tween()
		tw.tween_property(light, "light_energy", 0.0, 1.0)


func _flash_screen(hud: Control, color: Color, duration: float) -> void:
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = color
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(flash)
	var tw := hud.create_tween()
	tw.tween_property(flash, "color:a", 0.0, duration)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_callback(flash.queue_free)


func _show_message(msg: String) -> void:
	var hud := _find_hud()
	if hud and hud.has_method("show_monologue"):
		hud.show_monologue(msg)
		var tree := get_tree()
		if tree:
			await tree.create_timer(4.0).timeout
			if is_instance_valid(hud) and hud.has_method("hide_monologue"):
				hud.hide_monologue()


func _find_hud() -> Control:
	var main := get_tree().current_scene
	if main and main.has_node("HUDLayer/HUDRoot"):
		return main.get_node("HUDLayer/HUDRoot") as Control
	return null
