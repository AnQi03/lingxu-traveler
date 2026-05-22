extends Node

# ================================================================
# 昼夜循环控制器 - DayCycle.gd
# 管理时间流动、时段判断、过夜结算
# ================================================================

signal day_started(game_day: int)
signal period_changed(period: String)  # "morning"/"afternoon"/"evening"/"night"
signal night_falling()  # 即将入夜
signal day_ended(game_day: int, income: int)

# 时间流速：每 real_seconds_per_tick 秒前进 game_minutes_per_tick 分钟
const REAL_SECONDS_PER_TICK: float = 3.0
const GAME_MINUTES_PER_TICK: float = 60.0  # 每次前进1小时
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
	
	# 如果任何面板打开（集市/熔炉/背包），时间暂停
	if _any_panel_open():
		return
	
	tick_timer += delta
	if tick_timer >= REAL_SECONDS_PER_TICK:
		tick_timer = 0.0
		_advance_one_hour()


func _any_panel_open() -> bool:
	# 检查 Main.gd 中是否有面板打开
	var main = get_node("/root/Main")
	if not main:
		return false
	if main.has_method("is_any_panel_open"):
		return main.is_any_panel_open()
	return false


func _advance_one_hour():
	var old_period = _get_period_name(PlayerData.time_of_day)
	var old_day = PlayerData.game_day
	
	PlayerData.advance_time(GAME_HOURS_PER_TICK)
	
	var new_period = _get_period_name(PlayerData.time_of_day)
	
	# 检测时段变化
	if new_period != old_period:
		period_changed.emit(new_period)
		
		# 进入傍晚时触发收摊提醒
		if new_period == "evening":
			print("DayCycle: 傍晚了，该收摊了")
		
		# 进入夜间时触发过夜
		if new_period == "night":
			night_falling.emit()
			_do_night_settle()
		
		# 新的一天开始
		if PlayerData.game_day != old_day:
			day_started.emit(PlayerData.game_day)
			_do_day_start()


func _do_night_settle():
	# 强制收摊
	var main = get_node("/root/Main")
	if main and main.has_method("force_close_stall"):
		main.force_close_stall()
	
	print("DayCycle: 🌙 入夜了，今日营业结束")


func _do_day_start():
	print("DayCycle: ☀️ 第%d天开始了" % PlayerData.game_day)


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
