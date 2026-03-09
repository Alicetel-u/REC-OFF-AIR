extends Node

## ゲーム全体の状態を管理するシングルトン (Autoload: GameManager)

enum State { PLAYING, CAUGHT, WIN }

var state      : State = State.PLAYING
var items_found: int   = 0
var items_total: int   = 5
var hit_count  : int   = 0

## デバッグ: シナリオ中自由移動フラグ（F9 でトグル）
var debug_free_move: bool = false

## 演出早送り倍率
var playback_speed: float = 1.0

## セクションスキップ（CP1のstage_swap区切りサブセクション指定）
## 0=最初から、1=1回目のstage_swap後から、2=2回目のstage_swap後から
var start_section: int = 0

var _hit_invincible : bool = false
const HIT_MAX       : int  = 3

## ── エンディング分岐 ──
## -1=未選択, 0=NORMAL(鈴), 1=TRUE(スマホ), 2=BAD(使わない)
var ending_route: int = -1
## お札の残数 (初期3枚)
var ofuda_count: int = 3

## ── チャプターシステム ──
const ChapterDataScript := preload("res://scripts/ChapterData.gd")
var current_chapter: Resource = null
var chapter_index: int = 0

var chapter_order: Array[String] = [
	"res://chapters/ch01_haison_iriguchi.tres",   # CP1: 廃村入口→トイレ
	"res://chapters/ch02_yashiki.tres",            # CP2: 村長の屋敷
	"res://chapters/ch01_haison_souko.tres",       # CP3: 廃倉庫
	"res://chapters/ch04_kirihara_jinja.tres",     # CP4: 桐原神社
	"res://chapters/ch05_haison_dasshutsu.tres",   # CP5: 脱出＋最終分岐
]

signal item_collected(count: int, total: int)
signal player_caught
signal player_won
signal player_hit(count: int)


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


func trigger_hit() -> void:
	## ゴーストに当たった（3回で CAUGHT）
	if state != State.PLAYING or _hit_invincible:
		return
	hit_count += 1
	_hit_invincible = true
	get_tree().create_timer(3.0).timeout.connect(func() -> void: _hit_invincible = false)
	if hit_count >= HIT_MAX:
		trigger_caught()
	else:
		player_hit.emit(hit_count)


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
	hit_count   = 0
	_hit_invincible = false
	ending_route = -1
	ofuda_count  = 3
	get_tree().reload_current_scene()
