extends CanvasLayer

const DISPLAY_DURATION: float = 10.0

var summary_panel: Panel = null
var timer: float = 0.0
var is_showing: bool = false


func _ready():
	set_process_mode(PROCESS_MODE_ALWAYS)
	_build_ui()
	if is_instance_valid(summary_panel):
		summary_panel.visible = false


func _build_ui():
	summary_panel = Panel.new()
	summary_panel.visible = false
	add_child(summary_panel)
	
	summary_panel.position = Vector2(340, 160)
	summary_panel.size = Vector2(600, 360)
	
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.18, 0.95)
	bg.size = summary_panel.size
	bg.mouse_filter = 0
	summary_panel.add_child(bg)
	
	var title = Label.new()
	title.text = "🌙 营业结束"
	title.position = Vector2(0, 0)
	title.size = Vector2(600, 50)
	title.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary_panel.add_child(title)
	
	var info_label = Label.new()
	info_label.name = "info_label"
	info_label.position = Vector2(30, 60)
	info_label.size = Vector2(540, 110)
	info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_panel.add_child(info_label)
	
	var tomorrow_label = Label.new()
	tomorrow_label.name = "tomorrow_label"
	tomorrow_label.position = Vector2(30, 180)
	tomorrow_label.size = Vector2(540, 30)
	tomorrow_label.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9))
	tomorrow_label.add_theme_font_size_override("font_size", 14)
	summary_panel.add_child(tomorrow_label)
	
	var goal_label = Label.new()
	goal_label.name = "goal_label"
	goal_label.position = Vector2(30, 215)
	goal_label.size = Vector2(540, 30)
	goal_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	goal_label.add_theme_font_size_override("font_size", 14)
	summary_panel.add_child(goal_label)
	
	var hint = Label.new()
	hint.name = "hint_label"
	hint.text = "（点击任意位置关闭，或10秒后自动消失……）"
	hint.position = Vector2(0, 320)
	hint.size = Vector2(600, 30)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	hint.add_theme_font_size_override("font_size", 12)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_panel.add_child(hint)
	
	bg.gui_input.connect(_on_bg_clicked)


func _process(delta):
	if summary_panel.visible:
		timer -= delta
		if timer <= 0.0:
			_dismiss()


func show_summary():
	if not is_instance_valid(summary_panel):
		_build_ui()
	
	summary_panel.visible = true
	is_showing = true
	timer = DISPLAY_DURATION
	
	var info = find_child("info_label", true, false)
	if info:
		var day = PlayerData.game_day
		var players = PlayerData.spirit_stones
		var inv_count = 0
		var total_items = 0
		for item in PlayerData.inventory:
			inv_count += 1
			total_items += item.get("count", 1)
		
		info.text = "第%d天营业结束\n\n当前灵石：%d 下品\n库存：%d 种（%d 件）\n熔炼次数：%d/5" % [
			day - 1, players, inv_count, total_items, PlayerData.daily_refine_count
		]
	
	var tomorrow = find_child("tomorrow_label", true, false)
	if tomorrow:
		tomorrow.text = _get_tomorrow_hint(PlayerData.game_day)
	
	var goal = find_child("goal_label", true, false)
	if goal:
		goal.text = _get_goal_hint()


func _get_tomorrow_hint(day: int) -> String:
	var season = PlayerData.SEASON_EMOJI[PlayerData.season_index] + PlayerData.SEASON_NAMES[PlayerData.season_index]
	var hint = "📅 %s 第%d天" % [season, PlayerData.season_day]
	
	# 季节价格提示
	match PlayerData.season_index:
		0: hint += " | 灵材丰产，价格平稳"
		1: hint += " | 酷暑涨价，精打细算"
		2: hint += " | 丰收降价，多进货！"
		3: hint += " | 灵材枯竭，价格暴涨"
	
	if PlayerData.is_festival_day():
		hint += " | 🎪 集市大日！"
	if day <= 7:
		return hint + " — 灵材市场照常开市，多囤点凡品灵材吧。"
	elif day <= 14:
		return hint + " — 有传言说灵材需求要涨，抓住机会！"
	elif day <= 21:
		return hint + " — 集市可能上新货，记得去看看。"
	else:
		return hint + " — 老顾客会越来越多，稳住口碑。"


func _get_goal_hint() -> String:
	var total = PlayerData.get_total_stones()
	var ling = PlayerData.ling_shi
	
	if total < 200:
		return "💡 小目标：攒够200灵石，升级熔炉！（当前灵识：%d）" % ling
	
	var refine_ready = 0
	for item in PlayerData.inventory:
		if item.get("tier", 0) < 3:
			refine_ready += item.get("count", 0)
	
	if refine_ready > 0 and PlayerData.daily_refine_count < PlayerData.MAX_DAILY_REFINE:
		return "💡 你有灵材还没熔炼——明天试试运气？（当前灵识：%d）" % ling
	
	if total < 500:
		return "💡 小目标：攒够500灵石，解锁更多功能！（当前灵识：%d）" % ling
	
	return "💡 生意渐入佳境，继续保持！（当前灵识：%d）" % ling


func _dismiss():
	is_showing = false
	summary_panel.visible = false
	queue_free()


func _on_bg_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		_dismiss()
