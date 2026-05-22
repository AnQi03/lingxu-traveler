extends Node
## 音频管理器 — 程序化音效播放

var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 0.7

## 预加载的音效资源
var sfx_library: Dictionary = {}

## 音效播放器池（支持同时播放多个音效）
var audio_players: Array[AudioStreamPlayer] = []
var player_index: int = 0
const MAX_PLAYERS: int = 8


func _ready():
	set_process_mode(PROCESS_MODE_ALWAYS)
	_load_sfx()
	_create_player_pool()


func _load_sfx():
	## 加载 assets/audio/ 下的所有音效
	var sfx_names = [
		"coin", "deal", "smelt_success", "smelt_destroy",
		"smelt_normal", "customer_arrive", "day_transition", "ui_click"
	]
	for name in sfx_names:
		var path = "res://assets/audio/%s.wav" % name
		if ResourceLoader.exists(path):
			sfx_library[name] = load(path)
		else:
			print("[SoundManager] WARNING: audio file not found: %s" % path)


func _create_player_pool():
	for i in range(MAX_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = "Master"
		add_child(player)
		audio_players.append(player)


func play_sfx(sfx_name: String, volume: float = 1.0):
	## 播放指定音效。从池中取一个空闲的播放器。
	if not sfx_library.has(sfx_name):
		return
	
	var stream: AudioStream = sfx_library[sfx_name]
	var player = audio_players[player_index]
	player.stream = stream
	player.volume_db = linear_to_db(volume * sfx_volume * master_volume)
	player.play()
	
	player_index = (player_index + 1) % MAX_PLAYERS


func play_music(music_name: String):
	## 背景音乐接口 — 预留
	pass


func set_master_volume(vol: float):
	master_volume = clampf(vol, 0.0, 1.0)


## 常用音效快捷方法
func sfx_coin(): play_sfx("coin", 0.8)
func sfx_smelt_success(): play_sfx("smelt_success", 0.6)
func sfx_smelt_destroy(): play_sfx("smelt_destroy", 0.5)
func sfx_deal(): play_sfx("deal", 0.7)
func sfx_customer_arrive(): play_sfx("customer_arrive", 0.4)
func sfx_day_transition(): play_sfx("day_transition", 0.5)
func sfx_ui_click(): play_sfx("ui_click", 0.6)
