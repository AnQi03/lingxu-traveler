extends Node
## 音频管理器 — 预留音效播放接口

var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 0.7

func _ready():
	set_process_mode(PROCESS_MODE_ALWAYS)

func play_sfx(sfx_name: String, volume: float = 1.0):
	# 音效播放接口 — 预留
	# 未来挂载音效文件后，从资源池加载并播放
	# sfx_name: "coin" "smelt_success" "smelt_destroy" "deal" "customer_arrive" "day_start" "night"
	pass

func play_music(music_name: String):
	# 背景音乐接口 — 预留
	pass

func set_master_volume(vol: float):
	master_volume = clampf(vol, 0.0, 1.0)

## 常用音效快捷方法
func sfx_coin(): play_sfx("coin", 0.8)
func sfx_smelt_success(): play_sfx("smelt_success", 0.6)
func sfx_smelt_destroy(): play_sfx("smelt_destroy", 0.5)
func sfx_deal(): play_sfx("deal", 0.7)
func sfx_customer_arrive(): play_sfx("customer_arrive", 0.4)
