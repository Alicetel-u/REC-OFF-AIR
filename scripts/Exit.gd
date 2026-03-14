extends Area3D

## 脱出ポイント: 全テープ収集後に有効化
## アイテムが0個のチャプターでは最初からアクティブになり、次チャプターへ進む
## アイテム未収集で触れると「扉が開かない」セリフを表示

@onready var exit_light : OmniLight3D = $ExitLight

var active  : bool  = false
var pulse_t : float = 0.0
var _locked_msg_cooldown : float = 0.0
var _requires_ofuda : bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	GameManager.item_collected.connect(_on_item_collected)
	# 演出の邪魔にならないよう、ライトは無効化（必要に応じて復帰可能）
	exit_light.light_energy = 0.0
	active = (GameManager.items_total == 0)


func _process(delta: float) -> void:
	if _locked_msg_cooldown > 0.0:
		_locked_msg_cooldown -= delta
	# パルス（明滅）演出は廃止
	pass


func _on_item_collected(count: int, total: int) -> void:
	if count >= total:
		active = true


## ゴール到達時の演出コールバック（Main.gd から設定）
## 設定されている場合、演出完了後に遷移する
var on_exit_callback : Callable = Callable()

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if active:
		# お札が必要なチャプター（CP3）: お札なしでは脱出不可
		if _requires_ofuda and GameManager.ofuda_count <= 0:
			_show_ofuda_message()
			return
		active = false  # 二重トリガー防止
		if _requires_ofuda:
			GameManager.ofuda_count -= 1
		if on_exit_callback.is_valid():
			await on_exit_callback.call()
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


func _show_ofuda_message() -> void:
	if _locked_msg_cooldown > 0.0:
		return
	_locked_msg_cooldown = 5.0
	var hud := _find_hud()
	if hud and hud.has_method("show_monologue"):
		hud.show_monologue("お札がない！ ここを通るにはお札が必要みたい……！")
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
