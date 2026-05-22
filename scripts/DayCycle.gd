extends Node

signal day_started(game_day: int)
signal period_changed(period: String)
signal night_falling()

const REAL_SECONDS_PER_TICK: float = 25.0
const GAME_HOURS_PER_TICK: float = 1.0

var is_running: bool = false
var tick_timer: float = 0.0


func _ready():
	set_process_mode(PROCESS_MODE_ALWAYS)


func start():
	is_running = true
	tick_timer = 0.0
	print("DayCycle: 昼夜循环已启动")


func stop():
	is_running = false


func _process(delta):
	if not is_running:
		return
	
	var main = get_node("/root/Main")
	if main and main.has_method("is_any_panel_open") and main.is_any_panel_open():
		return
	
	tick_timer += delta
	if tick_timer >= REAL_SECONDS_PER_TICK:
		tick_timer = 0.0
		_advance_one_hour()


func _advance_one_hour():
	var old_period = get_period_name(PlayerData.time_of_day)
	var old_day = PlayerData.game_day
	
	PlayerData.advance_time(GAME_HOURS_PER_TICK)
	
	var new_period = get_period_name(PlayerData.time_of_day)
	
	if new_period != old_period:
		period_changed.emit(new_period)
		if new_period == "night":
			night_falling.emit()
			var main_node = get_node("/root/Main")
			if main_node and main_node.has_method("force_close_stall"):
				main_node.force_close_stall()
			print("DayCycle: 入夜了")
		if PlayerData.game_day != old_day:
			day_started.emit(PlayerData.game_day)
			print("DayCycle: 第%d天开始了" % PlayerData.game_day)


static func get_period_name(time_of_day: float) -> String:
	if time_of_day >= 5.0 and time_of_day < 12.0:
		return "morning"
	elif time_of_day >= 12.0 and time_of_day < 18.0:
		return "afternoon"
	elif time_of_day >= 18.0 and time_of_day < 20.0:
		return "evening"
	else:
		return "night"


static func get_period_label(time_of_day: float) -> String:
	match get_period_name(time_of_day):
		"morning": return "☀️ 上午"
		"afternoon": return "☀️ 下午"
		"evening": return "🌅 傍晚"
		"night": return "🌙 夜间"
		_: return "未知"


static func can_stall(time_of_day: float) -> bool:
	var p = get_period_name(time_of_day)
	return p == "morning" or p == "afternoon"
