extends Node

## SoundManager — 効果音・アンビエント管理 Autoload
## 使い方:
##   SoundManager.start_ambient(GameManager.chapter_index)
##   SoundManager.play_footstep(GameManager.chapter_index, is_dash)
##   SoundManager.play_monster_growl()
##   SoundManager.play_door_creak()

# チャプター別の足音カテゴリ（chapter_index → フォルダ名）
const STEP_CATS : Array = ["concrete", "wooden", "wooden", "gravel", "gravel"]

# チャプター別のアンビエント音量 dB
const AMBIENT_VOLS : Array = [-8.0, -14.0, -12.0, -10.0, -6.0]

var _ambient : AudioStreamPlayer = null
var _step    : AudioStreamPlayer = null
var _monster : AudioStreamPlayer = null
var _door    : AudioStreamPlayer = null

var _ambient_files : Array = []
var _monster_files : Array = []
var _door_files    : Array = []
var _step_cats     : Dictionary = {}   # category → Array of paths

var _monster_idx   : int = 0

var _voice    : AudioStreamPlayer = null
var _bgm      : AudioStreamPlayer = null


func _ready() -> void:
	_ambient = _make_player(0.0)
	_step    = _make_player(0.0)
	_monster = _make_player(0.0)
	_door    = _make_player(0.0)
	_voice   = _make_player(0.0)
	_bgm     = _make_player(0.0)
	_scan_all()


func _process(delta: float) -> void:
	if _step_cooldown > 0.0:
		_step_cooldown -= delta


func _make_player(vol_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.volume_db = vol_db
	add_child(p)
	return p


# ════════════════════════════════════════════════════════════════
# ファイルスキャン（DirAccess + ResourceLoader フォールバック）
# エクスポートビルドでは DirAccess が空を返す場合があるため
# ResourceLoader.exists() で既知パターンを探索する
# ════════════════════════════════════════════════════════════════

# ディレクトリ → ファイル名プレフィックス（全 SFX は "Name (N).mp3" 形式）
const SFX_PREFIXES := {
	"res://assets/audio/sfx/ambient_wind":      "Ambient Wind",
	"res://assets/audio/sfx/monster":           "Monster Growl",
	"res://assets/audio/sfx/door":              "Creaking Door",
	"res://assets/audio/sfx/footsteps/leaves":  "Leaves Footsteps",
	"res://assets/audio/sfx/footsteps/concrete":"Concrete Footsteps",
	"res://assets/audio/sfx/footsteps/carpet":  "Carpet Footstep",
	"res://assets/audio/sfx/footsteps/metal":   "Metal Footsteps",
	"res://assets/audio/sfx/footsteps/wind":    "Wind Footsteps",
	"res://assets/audio/sfx/footsteps/gravel":  "Gravel Footsteps",
	"res://assets/audio/sfx/footsteps/mud":     "Mud Footsteps",
	"res://assets/audio/sfx/footsteps/stairs":  "Stair Footsteps",
	"res://assets/audio/sfx/footsteps/wooden":  "Wooden Foosteps",
}

func _scan_all() -> void:
	_ambient_files = _scan_dir("res://assets/audio/sfx/ambient_wind")
	_monster_files = _scan_dir("res://assets/audio/sfx/monster")
	_door_files    = _scan_dir("res://assets/audio/sfx/door")
	for cat in ["leaves", "concrete", "carpet", "metal", "wind",
				"gravel", "mud", "stairs", "wooden"]:
		_step_cats[cat] = _scan_dir("res://assets/audio/sfx/footsteps/" + cat)


func _scan_dir(path: String) -> Array:
	var list : Array = []
	# 1) DirAccess でスキャン（開発環境で動作）
	var d := DirAccess.open(path)
	if d:
		d.list_dir_begin()
		var fname := d.get_next()
		while fname != "":
			if not d.current_is_dir() and fname.to_lower().ends_with(".mp3"):
				list.append(path + "/" + fname)
			fname = d.get_next()
		d.list_dir_end()
	# 2) エクスポートビルド用フォールバック: ResourceLoader で既知パターン探索
	if list.is_empty() and SFX_PREFIXES.has(path):
		var prefix : String = SFX_PREFIXES[path]
		for i in range(1, 30):
			var p := "%s/%s (%d).mp3" % [path, prefix, i]
			if ResourceLoader.exists(p):
				list.append(p)
	return list


# ════════════════════════════════════════════════════════════════
# 統一オーディオローダー
# エクスポートビルドでは ResourceLoader 経由（import済み .sample/.mp3str を読む）
# 開発環境では FileAccess 生バイト読み込みにフォールバック
# ════════════════════════════════════════════════════════════════

func _load_audio(path: String) -> AudioStream:
	# 1) ResourceLoader（エクスポートビルドではこちらが必須）
	if ResourceLoader.exists(path):
		var s = load(path)
		if s is AudioStream:
			return s
	# 2) フォールバック: 生バイト読み込み（開発環境 / import未対応ファイル用）
	if path.to_lower().ends_with(".mp3"):
		return _load_mp3_raw(path)
	if path.to_lower().ends_with(".wav"):
		return _load_wav_raw(path)
	return null


func _load_mp3_raw(path: String) -> AudioStreamMP3:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return null
	var bytes := f.get_buffer(f.get_length())
	f.close()
	var s := AudioStreamMP3.new()
	s.data = bytes
	return s


# ════════════════════════════════════════════════════════════════
# 公開 API
# ════════════════════════════════════════════════════════════════

## アンビエント風音を開始（ループ再生）
func start_ambient(chapter_index: int) -> void:
	if _ambient_files.is_empty():
		return
	var vol : float  = AMBIENT_VOLS[clamp(chapter_index, 0, AMBIENT_VOLS.size() - 1)]
	var path : String = _ambient_files[randi() % _ambient_files.size()]
	var s := _load_audio(path)
	if not s:
		return
	s.set("loop", true)
	_ambient.stream    = s
	_ambient.volume_db = vol
	_ambient.play()


## 足音を再生（クールダウンで連打防止）
var _step_cooldown : float = 0.0
func play_footstep(chapter_index: int, is_dash: bool) -> void:
	if _step_cooldown > 0.0:
		return
	var cat  : String = STEP_CATS[clamp(chapter_index, 0, STEP_CATS.size() - 1)]
	var list : Array  = _step_cats.get(cat, [])
	if list.is_empty():
		return
	var s := _load_audio(list[randi() % list.size()])
	if not s:
		return
	_step.stream      = s
	_step.volume_db   = -4.0 if is_dash else -8.0
	_step.pitch_scale = randf_range(0.92, 1.08)
	_step.play()
	_step_cooldown = 0.25 if is_dash else 0.38


## ゴーストの唸り声を再生（ファイルを順番に使い回す）
func play_monster_growl(vol_db: float = -5.0) -> void:
	if _monster.playing or _monster_files.is_empty():
		return
	var s := _load_audio(_monster_files[_monster_idx % _monster_files.size()])
	_monster_idx = (_monster_idx + 1) % _monster_files.size()
	if not s:
		return
	_monster.stream    = s
	_monster.volume_db = vol_db
	_monster.play()


## ドアの軋み音を再生
func play_door_creak() -> void:
	if _door_files.is_empty():
		return
	var s := _load_audio(_door_files[randi() % _door_files.size()])
	if not s:
		return
	_door.stream    = s
	_door.volume_db = -6.0
	_door.play()


## ボイス（WAV）を再生 — 直前のボイスは停止してから再生
func play_voice(path: String, vol_db: float = 0.0) -> void:
	var s := _load_audio(path)
	if not s:
		push_warning("SoundManager: voice not found: " + path)
		return
	_voice.stop()
	_voice.stream    = s
	_voice.volume_db = vol_db
	_voice.play()


## ボイスを停止
func stop_voice() -> void:
	_voice.stop()


## BGM を再生（ループ再生）
func play_bgm(path: String, vol_db: float = -10.0) -> void:
	var s := _load_audio(path)
	if not s:
		push_warning("SoundManager: BGM not found: " + path)
		return
	s.set("loop", true)
	_bgm.stop()
	_bgm.stream    = s
	_bgm.volume_db = vol_db
	_bgm.play()


## BGM をフェードアウトして停止
func stop_bgm(fade_sec: float = 1.0) -> void:
	if not _bgm.playing:
		return
	if fade_sec <= 0.0:
		_bgm.stop()
		return
	var tw := create_tween()
	var target_vol := _bgm.volume_db
	tw.tween_property(_bgm, "volume_db", -60.0, fade_sec)
	tw.tween_callback(func() -> void:
		_bgm.stop()
		_bgm.volume_db = target_vol
	)


## ボイス再生中かどうかを返す
func is_voice_playing() -> bool:
	return _voice.playing


## ボイス再生が終わるまで待機（再生中でなければ即リターン）
## finished シグナルに頼らずポーリングで待機（stop()時にシグナルが来ないバグ回避）
## max_sec: タイムアウト秒数（Webビルドで音声APIが停止した場合の安全策）
func await_voice(max_sec: float = 15.0) -> void:
	var elapsed := 0.0
	while _voice.playing:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if elapsed >= max_sec:
			push_warning("SoundManager: await_voice timed out after %.1fs" % max_sec)
			_voice.stop()
			break


# ════════════════════════════════════════════════════════════════
# WAV ローダー（バイト読み込み方式 — 開発環境フォールバック用）
# ════════════════════════════════════════════════════════════════

func _load_wav_raw(path: String) -> AudioStreamWAV:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		push_warning("SoundManager: WAV not found: " + path)
		return null
	var bytes := f.get_buffer(f.get_length())
	f.close()

	if bytes.size() < 44:
		return null

	# WAV ヘッダを解析
	var channels        := bytes.decode_u16(22)
	var sample_rate     := bytes.decode_u32(24)
	var bits_per_sample := bytes.decode_u16(34)

	# "data" チャンクを探す（fmt チャンクが可変長の場合に対応）
	var offset := 12
	while offset + 8 <= bytes.size():
		var chunk_id := bytes.slice(offset, offset + 4).get_string_from_ascii()
		var chunk_sz := bytes.decode_u32(offset + 4)
		offset += 8
		if chunk_id == "data":
			break
		offset += chunk_sz

	if offset >= bytes.size():
		return null

	var stream          := AudioStreamWAV.new()
	stream.data          = bytes.slice(offset)
	stream.mix_rate      = int(sample_rate)
	stream.stereo        = (channels == 2)
	stream.format        = AudioStreamWAV.FORMAT_16_BITS if bits_per_sample == 16 \
							else AudioStreamWAV.FORMAT_8_BITS
	return stream


## スーパーチャット通知チャイム（プログラム生成・昇順2音）
func play_superchat_chime(vol_db: float = -6.0) -> void:
	const RATE    := 44100
	const FREQ1   := 523.0   # C5
	const FREQ2   := 659.0   # E5
	const DUR1    := 0.13    # 秒
	const DUR2    := 0.16

	var gen := AudioStreamGenerator.new()
	gen.mix_rate     = float(RATE)
	gen.buffer_length = DUR1 + DUR2 + 0.05

	var player := AudioStreamPlayer.new()
	player.stream    = gen
	player.volume_db = vol_db
	add_child(player)
	player.play()

	var pb := player.get_stream_playback() as AudioStreamGeneratorPlayback

	# 第1音（C5）
	var n1 := int(RATE * DUR1)
	for i in n1:
		var t   := float(i) / RATE
		var env := sin(PI * t / DUR1)          # 半周期 sin エンベロープ
		var v   := sin(TAU * FREQ1 * t) * env * 0.45
		pb.push_frame(Vector2(v, v))

	# 第2音（E5）
	var n2 := int(RATE * DUR2)
	for i in n2:
		var t   := float(i) / RATE
		var env := sin(PI * t / DUR2)
		var v   := sin(TAU * FREQ2 * t) * env * 0.45
		pb.push_frame(Vector2(v, v))

	await get_tree().create_timer(DUR1 + DUR2 + 0.05).timeout
	player.queue_free()
