extends Area3D

## 脱出ポイント: 全テープ収集後に有効化
## アイテムが0個のチャプターでは最初からアクティブになり、次チャプターへ進む
## アイテム未収集で触れると「扉が開かない」セリフを表示

@onready var exit_light : OmniLight3D = $ExitLight

var active  : bool  = false
var pulse_t : float = 0.0
var _locked_msg_cooldown : float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	GameManager.item_collected.connect(_on_item_collected)
	if GameManager.items_total == 0:
		active = true
		exit_light.light_energy = 3.0
	else:
		active = false
		exit_light.light_energy = 0.5


func _process(delta: float) -> void:
	if _locked_msg_cooldown > 0.0:
		_locked_msg_cooldown -= delta
	if not active:
		return
	pulse_t += delta * 3.0
	exit_light.light_energy = 2.5 + sin(pulse_t) * 0.8


func _on_item_collected(count: int, total: int) -> void:
	if count >= total:
		active = true
		exit_light.light_energy = 3.0


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if active:
		GameManager.advance_to_next_chapter()
	else:
		_show_locked_message()


func _show_locked_message() -> void:
	if _locked_msg_cooldown > 0.0:
		return
	_locked_msg_cooldown = 5.0
	var hud := _find_hud()
	if hud and hud.has_method("show_monologue"):
		hud.show_monologue("扉がなぜか開かない！どうしよう！")
		# 3秒後に自動で消す
		var tree := get_tree()
		if tree:
			await tree.create_timer(3.0).timeout
			if is_instance_valid(hud) and hud.has_method("hide_monologue"):
				hud.hide_monologue()


func _find_hud() -> Control:
	var main := get_tree().current_scene
	if main and main.has_node("HUDLayer/HUDRoot"):
		return main.get_node("HUDLayer/HUDRoot") as Control
	return null
