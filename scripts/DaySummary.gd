extends CanvasLayer

const DISPLAY_DURATION: float = 12.0  # 从10秒延长到12秒，给玩家更多时间看

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
	
	summary_panel.position = Vector2(320, 80)
	summary_panel.size = Vector2(620, 490)
	
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.18, 0.95)
	bg.size = summary_panel.size
	bg.mouse_filter = 0
	summary_panel.add_child(bg)
	
	## 标题
	var title = Label.new()
	title.name = "title_label"
	title.position = Vector2(0, 0)
	title.size = Vector2(620, 50)
	title.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary_panel.add_child(title)
	
	## 核心数据（紧凑横排）
	var info_label = Label.new()
	info_label.name = "info_label"
	info_label.position = Vector2(30, 55)
	info_label.size = Vector2(560, 50)
	info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_panel.add_child(info_label)
	
	## 分隔线
	var sep1 = HSeparator.new()
	sep1.name = "sep1"
	sep1.position = Vector2(30, 110)
	sep1.size = Vector2(560, 2)
	summary_panel.add_child(sep1)
	
	## 熔炉升级进度条
	var furnace_bar = Label.new()
	furnace_bar.name = "furnace_bar"
	furnace_bar.position = Vector2(30, 118)
	furnace_bar.size = Vector2(560, 22)
	furnace_bar.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	furnace_bar.add_theme_font_size_override("font_size", 13)
	summary_panel.add_child(furnace_bar)
	
	## 碎片收集进度条
	var fragment_bar = Label.new()
	fragment_bar.name = "fragment_bar"
	fragment_bar.position = Vector2(30, 143)
	fragment_bar.size = Vector2(560, 22)
	fragment_bar.add_theme_color_override("font_color", Color(0.7, 0.45, 0.85))
	fragment_bar.add_theme_font_size_override("font_size", 13)
	summary_panel.add_child(fragment_bar)
	
	## 里程碑倒计时
	var milestone_label = Label.new()
	milestone_label.name = "milestone_label"
	milestone_label.position = Vector2(30, 170)
	milestone_label.size = Vector2(560, 22)
	milestone_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
	milestone_label.add_theme_font_size_override("font_size", 13)
	summary_panel.add_child(milestone_label)
	
	## 分隔线2
	var sep2 = HSeparator.new()
	sep2.name = "sep2"
	sep2.position = Vector2(30, 198)
	sep2.size = Vector2(560, 2)
	summary_panel.add_child(sep2)
	
	## 明日预告（亮点）
	var tomorrow_label = Label.new()
	tomorrow_label.name = "tomorrow_label"
	tomorrow_label.position = Vector2(30, 205)
	tomorrow_label.size = Vector2(560, 55)
	tomorrow_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	tomorrow_label.add_theme_font_size_override("font_size", 15)
	tomorrow_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_panel.add_child(tomorrow_label)
	
	## 小目标
	var goal_label = Label.new()
	goal_label.name = "goal_label"
	goal_label.position = Vector2(30, 265)
	goal_label.size = Vector2(560, 40)
	goal_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	goal_label.add_theme_font_size_override("font_size", 14)
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_panel.add_child(goal_label)
	
	## 管家来信
	var butler_label = Label.new()
	butler_label.name = "butler_label"
	butler_label.position = Vector2(30, 310)
	butler_label.size = Vector2(560, 55)
	butler_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
	butler_label.add_theme_font_size_override("font_size", 13)
	butler_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	butler_label.visible = false
	summary_panel.add_child(butler_label)
	
	## 世界反馈
	var world_label = Label.new()
	world_label.name = "world_label"
	world_label.position = Vector2(30, 380)
	world_label.size = Vector2(560, 40)
	world_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	world_label.add_theme_font_size_override("font_size", 12)
	world_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	world_label.visible = false
	summary_panel.add_child(world_label)
	
	## 关闭提示
	var hint = Label.new()
	hint.name = "hint_label"
	hint.text = "（点击任意位置继续，或12秒后自动消失……）"
	hint.position = Vector2(0, 455)
	hint.size = Vector2(620, 30)
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
	
	var day = PlayerData.game_day - 1  # game_day 已经+1了
	var season_idx = PlayerData.season_index
	var season_name = PlayerData.SEASON_EMOJI[season_idx] + PlayerData.SEASON_NAMES[season_idx]
	if PlayerData.season_day == 1:
		season_name += " · 新季伊始"
	
	# ---- 标题 ----
	var title = find_child("title_label", true, false)
	if title:
		var period = ""
		if PlayerData.time_of_day < 8:
			period = "🌙"
		elif PlayerData.time_of_day < 12:
			period = "☀️"
		else:
			period = "🌅"
		title.text = "%s 第%d天 · %s" % [period, day, season_name]
	
	# ---- 核心数据（紧凑横排） ----
	var info = find_child("info_label", true, false)
	if info:
		var stones = PlayerData.get_total_stones()
		var inv_count = PlayerData.inventory.size()
		var total_items = 0
		for item in PlayerData.inventory:
			total_items += item.get("count", 1)
		var earned_today = _calc_today_income()
		
		info.text = "💰 %d灵石  |  📦 %d种(%d件)  |  🔥 熔炼%d次  |  💰 今日收入+%d" % [
			stones, inv_count, total_items, PlayerData.daily_refine_count, earned_today
		]
	
	# ---- 熔炉升级进度条 ----
	var furnace_bar = find_child("furnace_bar", true, false)
	if furnace_bar:
		var tier = PlayerData.furnace_tier
		if tier >= 5:
			furnace_bar.text = "🔥 熔炉已满级 Lv.5 — 灵墟最强的炉子！"
		else:
			var cost = PlayerData.get_furnace_upgrade_cost()
			var current = PlayerData.get_total_stones()
			var pct = min(1.0, float(current) / float(cost))
			var bar = _make_bar(pct, 20)
			var diff = max(0, cost - current)
			furnace_bar.text = "🔥 熔炉 Lv.%d→%d  %s  %.0f%%  （还差%d灵石）" % [tier, tier+1, bar, pct*100, diff]
	
	# ---- 碎片收集进度条 ----
	var fragment_bar = find_child("fragment_bar", true, false)
	if fragment_bar:
		var frags = PlayerData.lingxu_fragments
		if frags < PlayerData.FRAGMENT_SECRET:
			var pct = float(frags) / float(PlayerData.FRAGMENT_SECRET)
			var bar = _make_bar(pct, 20)
			fragment_bar.text = "🔮 灵墟碎片  %s  %d/%d  解锁隐藏配方" % [bar, frags, PlayerData.FRAGMENT_SECRET]
		elif frags < PlayerData.FRAGMENT_DISCOUNT:
			fragment_bar.text = "🔮 灵墟碎片  %d/%d  ✨ 已解锁隐藏配方！（%d→熔炉8折）" % [frags, PlayerData.FRAGMENT_DISCOUNT, PlayerData.FRAGMENT_DISCOUNT - frags]
		else:
			fragment_bar.text = "🔮 灵墟碎片  %d  ✨ 隐藏配方+熔炉8折均已解锁！" % frags
	
	# ---- 里程碑倒计时 ----
	var milestone = find_child("milestone_label", true, false)
	if milestone:
		var texts = []
		var days_to_festival = PlayerData.FESTIVAL_INTERVAL - (PlayerData.season_day % PlayerData.FESTIVAL_INTERVAL)
		if days_to_festival == PlayerData.FESTIVAL_INTERVAL:
			days_to_festival = 0
		if PlayerData.is_festival_day():
			texts.append("🎪 今天就是集市大日！")
		elif days_to_festival <= 5:
			texts.append("🎪 距集市大日还有%d天" % days_to_festival)
		
		var days_to_season_end = PlayerData.DAYS_PER_SEASON - PlayerData.season_day
		if days_to_season_end <= 5:
			var next_season = (PlayerData.season_index + 1) % 4
			texts.append("%s 距换季还有%d天" % [PlayerData.SEASON_EMOJI[next_season] + PlayerData.SEASON_NAMES[next_season], days_to_season_end])
		
		# 下一解锁提示
		if PlayerData.game_day < 5:
			texts.append("🔓 Day5解锁熔炉")
		elif PlayerData.game_day < 10:
			texts.append("🔓 Day10解锁切片加工")
		elif PlayerData.game_day < 15:
			texts.append("🔓 Day15解锁灵潮感应")
		
		milestone.text = " | ".join(texts)
	
	# ---- 明日预告 ----
	var tomorrow = find_child("tomorrow_label", true, false)
	if tomorrow:
		tomorrow.text = _get_tomorrow_preview()
	
	# ---- 小目标 ----
	var goal = find_child("goal_label", true, false)
	if goal:
		goal.text = _get_goal_hint()
	
	# ---- 管家来信 ----
	var butler = find_child("butler_label", true, false)
	if butler:
		var msg = _get_butler_msg(PlayerData.game_day)
		if msg != "":
			butler.text = msg
			butler.visible = true
		else:
			butler.visible = false
	
	# ---- 世界反馈 ----
	var world = find_child("world_label", true, false)
	if world:
		var fb = _get_world_feedback()
		if fb != "":
			world.text = fb
			world.visible = true
		else:
			world.visible = false


## ---------- 进度条工具 ----------
func _make_bar(pct: float, width: int) -> String:
	var filled = int(pct * width)
	var bar = ""
	for i in range(width):
		if i < filled:
			bar += "█"
		else:
			bar += "░"
	return bar


## ---------- 今日收入计算 ----------
func _calc_today_income() -> int:
	# 从 StallManager 推断当日收入（简化：如果有 StallManager 实例取其 daily_income）
	var main = get_node("/root/Main")
	if main and main.has_method("get_stall_income"):
		return main.get_stall_income()
	return 0


## ---------- 明日预告（升级版） ----------
func _get_tomorrow_preview() -> String:
	var day = PlayerData.game_day
	var season_idx = PlayerData.season_index
	var tomorrow_season_day = PlayerData.season_day + 1
	
	var parts = []
	
	# 季节信息
	parts.append("📅 %s第%d天" % [PlayerData.SEASON_EMOJI[season_idx] + PlayerData.SEASON_NAMES[season_idx], tomorrow_season_day])
	
	# 集市大日检测
	var next_festival = PlayerData.FESTIVAL_INTERVAL - (PlayerData.season_day % PlayerData.FESTIVAL_INTERVAL)
	if next_festival == PlayerData.FESTIVAL_INTERVAL:
		next_festival = 0
	if PlayerData.is_festival_day():
		parts.append("🎪 今天就是集市大日！客流量翻倍，灵材种类更多！")
	elif next_festival == 1:
		parts.append("🎪 明天就是集市大日！准备好灵石，稀有灵材会出现！")
	
	# 随机事件预告（30%概率）
	if randf() < 0.3:
		var events = _tomorrow_random_events()
		parts.append(events[randi() % events.size()])
	
	# 季节性具体建议
	match season_idx:
		0:  # 灵潮季
			if tomorrow_season_day <= 5:
				parts.append("🌱 灵潮刚起，五行灵材都很温和，适合新手熔炼")
		1:  # 炎阳季
			parts.append("☀️ 火系灵材更活跃，熔炼火属性灵材成功率+5%")
		2:  # 丰收季
			parts.append("🍂 灵材价格普降，是囤货的好时机")
		3:  # 静修季
			var frags = PlayerData.lingxu_fragments
			if frags > 0:
				parts.append("❄️ 天寒地冻，但灵墟碎片在冬季更容易共鸣")
	
	# 常客预告（忠诚度高的顾客更可能明天来）
	var regular_names = PlayerData.get_known_customer_names()
	if not regular_names.is_empty():
		var loyal_regular = ""
		for name in regular_names:
			if PlayerData.get_customer_loyalty(name) >= 4:
				loyal_regular = name
				break
		if loyal_regular != "" and randf() < 0.4:
			parts.append("👤 %s明天可能会来——她最近常来光顾" % loyal_regular)
	
	# 商道感知（高级商道给市场预测）
	if PlayerData.shang_dao >= 30:
		var season_idx2 = PlayerData.season_index
		var hints = ["明天灵材市场似乎有不少好东西", "隐约感觉明天来的顾客会比较大方", "明天适合多熔炼几次"]
		parts.append("💼 " + hints[randi() % hints.size()])
	
	return "\n".join(parts)

func _tomorrow_random_events() -> Array:
	return [
		"📰 灵墟商会传出消息：明天可能有稀有灵材到货",
		"🗣️ 听说有位远道而来的大商人明天会来灵墟",
		"🌙 管家说今晚星象有异——明天熔炉运势似乎不错",
		"🔔 隔壁摊主说明天有个大客户要来集市——准备好货！",
		"💬 几个散修在讨论一种新的熔炼配方……也许明天能打听到",
		"✨ 你感觉明天的灵材市场会有一批好货",
	]


## ---------- 小目标（动态 + 进度感知） ----------
func _get_goal_hint() -> String:
	var total = PlayerData.get_total_stones()
	
	# 优先级1：熔炉升级
	var upgrade_cost = PlayerData.get_furnace_upgrade_cost()
	if upgrade_cost > 0:
		var diff = max(0, upgrade_cost - total)
		if diff > 0:
			var days_est = 1
			var today_income = _calc_today_income()
			if today_income > 0:
				days_est = max(1, ceil(float(diff) / float(today_income)))
			return "🎯 目标：攒够%d灵石升级熔炉（还差%d，约%d天）" % [upgrade_cost, diff, days_est]
		else:
			return "🎯 灵石够了！明天就去升级熔炉吧！（当前%d灵石 → Lv.%d需要%d）" % [total, PlayerData.furnace_tier+1, upgrade_cost]
	
	# 优先级2：碎片收集
	var frags = PlayerData.lingxu_fragments
	if frags >= PlayerData.FRAGMENT_SECRET and frags < PlayerData.FRAGMENT_DISCOUNT:
		var diff = PlayerData.FRAGMENT_DISCOUNT - frags
		return "🎯 再收集%d个灵墟碎片，熔炉升级即可8折！（已解锁隐藏配方✨）" % diff
	elif frags < PlayerData.FRAGMENT_SECRET:
		var diff = PlayerData.FRAGMENT_SECRET - frags
		return "🎯 再收集%d个灵墟碎片，解锁隐藏熔炼配方！（熔炼失败也会给碎片🔮）" % diff
	
	# 优先级3：常客关系
	var regulars = PlayerData.get_known_customer_names()
	if regulars.size() < 3:
		return "🎯 多摆摊、少赶人——让3位顾客成为常客吧（当前%d人）" % regulars.size()
	
	# 优先级4：多元化经营
	var inv = PlayerData.inventory
	if inv.size() <= 5:
		return "🎯 你的库存品种太少！多去集市进货，至少囤8种灵材"
	
	# 默认鼓励
	var refine_ready = 0
	for item in inv:
		if item.get("tier", 0) < 3:
			refine_ready += item.get("count", 0)
	if refine_ready > 0 and PlayerData.daily_refine_count < PlayerData.MAX_DAILY_REFINE:
		return "🎯 背包里还有%d个可熔炼的灵材——明天试试手气！" % refine_ready
	
	return "🎯 生意蒸蒸日上，继续稳住口碑！"


## ---------- 管家来信 ----------
func _get_butler_msg(day: int) -> String:
	match day:
		1: return "📜 管家来信：'少爷，灵墟虽小，却是修真的好地方。老仆已经打点好了住处。明天开始，集市就是你的战场了。'"
		3: return "📜 管家来信：'少爷，攒够100灵石才有本钱做下一笔生意。多摆摊，少乱花。'"
		5: return "📜 管家来信：'老仆托人弄了些耐火砖，炉子可以启用了——试试熔炼吧。'"
		7: return "📜 管家来信：'听说东市有人卖耐火砖——该给炉子升个级了。'"
		10: return "📜 管家来信：'少爷，老仆给你弄了把切玉刀——灵材切片能多卖15%，试试看。'"
		14: return "📜 管家来信：'北街有个空铺面在招租。不急，但可以先去看看。'"
		15: return "📜 管家来信：'少爷，老仆昨夜观星——明夜灵潮异动，熔炉或有奇效。你在熔炼时多留神。'"
		20: return "📜 管家来信：'灵墟的地下也有交易——人们叫它暗市。不过那里水深，老仆不建议少爷现在涉足……但可以留个心眼。'"
		21: return "📜 管家来信：'灵墟最近有拍卖会——入场费100灵石。想不想去开开眼？'"
		30: return "📜 管家来信：'第一季过去了。少爷在灵墟已经不是新人了。老仆甚慰。'"
		45: return "📜 管家来信：'五大宗门最近在灵墟活动频繁。有人打听你……少爷的熔炼名声，已经开始传出去了。'"
		60: return "📜 管家来信：'听说暗市开张了——不过那里水深，少爷多留个心眼。'"
		90: return "📜 管家来信：'半年了。少爷的摊子——不，该叫店铺了——真是越来越像样了。'"
		91: return "📜 管家来信：'少爷，老仆听说了一个消息——灵墟商会每120天会评定一次摊位。您还有约一个月时间。该准备了。'"
		_: return ""


## ---------- 世界反馈 ----------
func _get_world_feedback() -> String:
	var earned = PlayerData.total_earned
	var regulars = PlayerData.get_known_customer_names().size()
	var parts = []
	
	if earned >= 10000:
		parts.append("灵墟没有人不知道你的摊位了。")
	elif earned >= 5000:
		parts.append("你的名字开始在灵墟商界流传。")
	elif earned >= 2000:
		parts.append("灵墟商会的管事开始留意你的摊位。")
	elif earned >= 500:
		parts.append("你的摊位在周边小有名气了。")
	
	if regulars >= 5:
		parts.append("几位常客已经把你当成了灵墟最可靠的商人。")
	elif regulars >= 3:
		parts.append("几位熟客成了你的固定主顾。")
	
	if PlayerData.shang_dao >= 40:
		parts.append("同行们提起你都点点头。")
	if PlayerData.tian_dao >= 40:
		parts.append("你能感受到灵材在你手中微微颤动。")
	if PlayerData.ren_xin >= 40:
		parts.append("街坊邻居提起你都竖大拇指。")
	
	return " | ".join(parts)


## ---------- 关闭 ----------
func _dismiss():
	is_showing = false
	summary_panel.visible = false
	PlayerData.save_game()
	queue_free()


func _on_bg_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		_dismiss()
