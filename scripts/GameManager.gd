extends Node

## ゲーム全体の状態を管理するシングルトン (Autoload: GameManager)

enum State { PLAYING, CAUGHT, WIN }

var state      : State = State.PLAYING
var items_found: int   = 0
var items_total: int   = 5

## 選択されたマップ種別
## 0 = INDUSTRIAL (廃工場・WFC生成)
## 1 = HAISON     (廃村・WFC生成)
## Opening.gd でセットされ、Main.gd が使用する
var selected_map_type: int = 1  # デフォルト: HAISON

signal item_collected(count: int, total: int)
signal player_caught
signal player_won


func collect_item() -> void:
	if state != State.PLAYING:
		return
	items_found += 1
	item_collected.emit(items_found, items_total)


func trigger_caught() -> void:
	if state != State.PLAYING:
		return
	state = State.CAUGHT
	player_caught.emit()


func trigger_win() -> void:
	if state != State.PLAYING:
		return
	state = State.WIN
	player_won.emit()


func restart() -> void:
	state      = State.PLAYING
	items_found = 0
	get_tree().reload_current_scene()
