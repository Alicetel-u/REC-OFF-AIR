extends Node

## ゲーム全体の状態を管理するシングルトン (Autoload: GameManager)

enum State { PLAYING, CAUGHT, WIN }

var state      : State = State.PLAYING
var items_found: int   = 0
var items_total: int   = 5

## ── チャプターシステム ──
const ChapterDataScript := preload("res://scripts/ChapterData.gd")
var current_chapter: Resource = null
var chapter_index: int = 0

var chapter_order: Array[String] = [
	"res://chapters/ch01_haison_iriguchi.tres",
	"res://chapters/ch01_haison_souko.tres",
]

signal item_collected(count: int, total: int)
signal player_caught
signal player_won


func load_chapter(index: int) -> void:
	chapter_index = index
	if index < chapter_order.size():
		current_chapter = load(chapter_order[index])
	else:
		push_error("Chapter index %d out of range" % index)


func advance_chapter() -> bool:
	if chapter_index + 1 < chapter_order.size():
		chapter_index += 1
		load_chapter(chapter_index)
		return true
	return false


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


func advance_to_next_chapter() -> void:
	## 次チャプターへ進む。最終チャプターならWINにする
	if advance_chapter():
		items_found = 0
		get_tree().reload_current_scene()
	else:
		trigger_win()


func restart() -> void:
	state      = State.PLAYING
	items_found = 0
	get_tree().reload_current_scene()
