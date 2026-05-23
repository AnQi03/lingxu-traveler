# ============================================================
# 玩家数据全局单例 - PlayerData.gd
# 管理灵石、灵材库存、三道数值、游戏时间
# ============================================================
extends Node

## ---------- 灵石 ----------
var spirit_stones: int = 150          # 下品灵石
var mid_spirit_stones: int = 0       # 中品灵石 (×100)
var high_spirit_stones: int = 0      # 上品灵石 (×10000)
var extreme_spirit_stones: int = 0   # 极品灵石 (×1000000)
var total_earned: int = 0            # 累计收入

## ---------- 三道 ----------
var shang_dao: int = 0
var tian_dao: int = 0
var ren_xin: int = 0

## ---------- 主角身份 ----------
var player_name: String = "安"           # 主角名
var player_title: String = ""            # 称号（三道/成就决定）
var player_motivation: String = "还债"   # 动机：还债/立足/寻父
var has_seen_opening: bool = false       # 是否看过开场
var shang_voice_heard: bool = false      # 商道第一次说话
var tian_voice_heard: bool = false       # 天道第一次说话
var renxin_voice_heard: bool = false     # 人心第一次说话
var first_high_stone: bool = false       # 第一次获得上品灵石
var first_extreme_stone: bool = false    # 第一次获得极品灵石

## ---------- 年度评定 ----------
var year_assessed: bool = false           # 是否已完成首次评定
var assessment_score: int = 0             # 最近一次评定分数
var assessment_rating: int = 0            # 1-5星
const ASSESSMENT_DAY: int = 120           # 评定日（一年）
const ASSESSMENT_WARNING_DAY: int = 90    # 提前30天预告

## ---------- 时间 ----------
var game_day: int = 1
var is_daytime: bool = true
var time_of_day: float = 6.0

## ---------- 季节 ----------
var season_index: int = 0
var season_day: int = 1
var game_year: int = 1
const SEASON_NAMES = ["灵潮季", "炎阳季", "丰收季", "静修季"]
const SEASON_EMOJI = ["🌸", "☀️", "🍂", "❄️"]
const DAYS_PER_SEASON: int = 30
const FESTIVAL_INTERVAL: int = 10

## ---------- 库存 ----------
var inventory: Array = []

## ---------- 熔炼 ----------
var daily_refine_count: int = 0
const MAX_DAILY_REFINE: int = 5

## ---------- 连续出摊 ----------
var consecutive_stall_days: int = 0
var has_stalled_today: bool = false

## ---------- 连胜系统 ----------
var smelt_streak: int = 0      # 熔炼升品连胜
var trade_streak: int = 0      # 交易成功连胜

## ---------- 世界事件 ----------
var today_events: Array = []   # 今日活跃的随机事件

## ---------- 灵墟碎片 ----------
var lingxu_fragments: int = 0  # 熔炼失败时获得，积累解锁隐藏配方
const FRAGMENT_SECRET: int = 10   # 10碎片→解锁隐藏熔炼配方
const FRAGMENT_DISCOUNT: int = 30  # 30碎片→熔炉升级8折

## ---------- 灵识 ----------
var ling_shi: int = 80
const MAX_LING_SHI: int = 100

## ---------- 熔炉升级 ----------
var furnace_tier: int = 1

## ---------- 系统解锁 ----------
func is_furnace_unlocked() -> bool:
	return game_day >= 5

func is_slicing_unlocked() -> bool:
	return game_day >= 10
const FURNACE_UPGRADE_COST = {
	2: 5000,     # 凡→灵 — 0.5上品
	3: 20000,    # 灵→宝 — 2上品
	4: 50000,    # 高阶宝品 — 5上品
	5: 150000,   # 宝→仙 — 15上品，神器
}
const FURNACE_UPGRADE_LUCK = {
	1: [0.40, 0.22, 0.007],
	2: [0.55, 0.28, 0.01],
	3: [0.70, 0.38, 0.03],
	4: [0.82, 0.52, 0.08],
	5: [0.90, 0.65, 0.15]
}

func get_furnace_luck(tier: int) -> Array:
	if FURNACE_UPGRADE_LUCK.has(tier):
		return FURNACE_UPGRADE_LUCK[tier]
	return FURNACE_UPGRADE_LUCK[1]

func get_furnace_upgrade_cost() -> int:
	var next = furnace_tier + 1
	if FURNACE_UPGRADE_COST.has(next):
		return FURNACE_UPGRADE_COST[next]
	return -1

func upgrade_furnace() -> bool:
	var cost = get_furnace_upgrade_cost()
	if cost < 0:
		return false
	if get_total_stones() < cost:
		return false
	if not spend_stones(cost):
		return false
	furnace_tier += 1
	return true

## ---------- 灵墟碎片 ----------
func add_fragments(count: int) -> void:
	lingxu_fragments += count
	var hud = get_meta("hud", null)
	if hud and hud.has_method("show_toast"):
		hud.show_toast("🔮 获得 %d 灵墟碎片！（共 %d）" % [count, lingxu_fragments], Color(0.7, 0.45, 0.85), 2.5)
	
	if lingxu_fragments >= FRAGMENT_SECRET and not has_meta("fragment_secret_triggered"):
		set_meta("fragment_secret_triggered", true)
		if hud and hud.has_method("show_toast"):
			hud.show_toast("✨ 灵墟碎片共鸣！解锁隐藏熔炼配方！去熔炉看看吧~", Color(1, 0.8, 0.3), 5.0)
	
	if lingxu_fragments >= FRAGMENT_DISCOUNT and not has_meta("fragment_discount_triggered"):
		set_meta("fragment_discount_triggered", true)
		if hud and hud.has_method("show_toast"):
			hud.show_toast("🏷️ 碎片之力汇聚！下次熔炉升级享受8折优惠！", Color(1, 0.8, 0.3), 5.0)


## ---------- 年度评定评分 ----------
func calculate_assessment() -> Dictionary:
	var score = 0
	var parts = []  # 各项得分说明
	
	# 灵石 (0-3分)
	var stones = get_total_stones()
	if stones >= 10000:
		score += 3; parts.append("灵石富可敌城 +3")
	elif stones >= 5000:
		score += 2; parts.append("灵石积累丰厚 +2")
	elif stones >= 1000:
		score += 1; parts.append("灵石小有积蓄 +1")
	else:
		parts.append("灵石不足... 0")
	
	# 熔炉等级 (0-3分)
	if furnace_tier >= 5:
		score += 3; parts.append("熔炉登峰造极 +3")
	elif furnace_tier >= 3:
		score += 2; parts.append("熔炉炉火纯青 +2")
	elif furnace_tier >= 2:
		score += 1; parts.append("熔炉初具规模 +1")
	else:
		parts.append("熔炉尚未升级 0")
	
	# 常客数量 (0-2分)
	var regular_count = get_known_customer_names().size()
	if regular_count >= 5:
		score += 2; parts.append("常客遍布灵墟 +2")
	elif regular_count >= 3:
		score += 1; parts.append("有几位熟客 +1")
	else:
		parts.append("还需多结识常客 0")
	
	# 灵材图鉴 (0-2分)
	var material_count = 0
	for item in inventory:
		material_count += 1
	if material_count >= 15:
		score += 2; parts.append("灵材收藏家 +2")
	elif material_count >= 8:
		score += 1; parts.append("灵材品种渐丰 +1")
	else:
		parts.append("灵材品种太少 0")
	
	# 碎片收集 (0-1分)
	if lingxu_fragments >= 50:
		score += 1; parts.append("灵墟碎片大量收集 +1")
	elif lingxu_fragments >= 20:
		score += 1; parts.append("灵墟碎片小成 +1")
	else:
		parts.append("碎片收集不足 0")
	
	# 连续出摊 (0-1分)
	if consecutive_stall_days >= 30:
		score += 1; parts.append("风雨无阻 +1")
	elif consecutive_stall_days >= 10:
		score += 1; parts.append("勤奋出摊 +1")
	else:
		parts.append("出摊不够勤快 0")
	
	# 评级
	var rating = 1
	var rating_text = "⭐ 初来乍到"
	var rating_color = Color(0.5, 0.5, 0.5)
	if score >= 12:
		rating = 5; rating_text = "⭐⭐⭐⭐⭐ 灵墟传奇"; rating_color = Color(1, 0.8, 0.2)
	elif score >= 9:
		rating = 4; rating_text = "⭐⭐⭐⭐ 杰出商贾"; rating_color = Color(0.3, 0.9, 0.5)
	elif score >= 6:
		rating = 3; rating_text = "⭐⭐⭐ 稳健经营"; rating_color = Color(0.4, 0.7, 1.0)
	elif score >= 3:
		rating = 2; rating_text = "⭐⭐ 还需历练"; rating_color = Color(0.7, 0.7, 0.3)
	
	# 三道影响评级叙事
	var narrative = ""
	if shang_dao >= tian_dao and shang_dao >= ren_xin:
		narrative = "商道之路，你已经走得很远了。"
	elif tian_dao >= shang_dao and tian_dao >= ren_xin:
		narrative = "天道眷顾，你与灵材之间有了奇妙的共鸣。"
	elif ren_xin >= shang_dao and ren_xin >= tian_dao:
		narrative = "人心所向，这灵墟因你而温暖了几分。"
	else:
		narrative = "三道均衡，你走出了属于自己的路。"
	
	if shang_dao >= 50 and tian_dao >= 50 and ren_xin >= 50:
		narrative = "商道、天道、人心——三条路你都走到了深处。灵墟从未见过这样的奇才。"
	
	assessment_score = score
	assessment_rating = rating
	year_assessed = true
	
	return {
		"score": score,
		"max_score": 12,
		"rating": rating,
		"rating_text": rating_text,
		"rating_color": rating_color,
		"parts": parts,
		"narrative": narrative
	}

## ---------- 顾客关系 ----------
var customer_relations: Dictionary = {}
var loyalty_events_triggered: Array = []  # 已触发的常客事件 ["石老_3", "青儿_5", ...]

## ---------- 顾客记忆 ----------
# { "石老": {"last_price": 50, "last_result": "accept", "visit_count": 12, "last_day": 45} }
var customer_memory: Dictionary = {}

func remember_deal(customer_name: String, price: int, result: String) -> void:
	if not customer_memory.has(customer_name):
		customer_memory[customer_name] = {"visit_count": 0}
	customer_memory[customer_name]["last_price"] = price
	customer_memory[customer_name]["last_result"] = result
	customer_memory[customer_name]["last_day"] = game_day
	customer_memory[customer_name]["visit_count"] = customer_memory[customer_name].get("visit_count", 0) + 1

func get_customer_memory(customer_name: String) -> Dictionary:
	if customer_memory.has(customer_name):
		return customer_memory[customer_name]
	return {}


# ============================================================
# 灵石
# ============================================================

func get_total_stones() -> int:
	return spirit_stones + mid_spirit_stones * 100 + high_spirit_stones * 10000 + extreme_spirit_stones * 1000000

func spend_stones(amount: int) -> bool:
	var total = get_total_stones()
	if total < amount:
		return false
	
	var remaining = amount
	while remaining >= 1000000 and extreme_spirit_stones > 0:
		var use: int = mini(extreme_spirit_stones, int(float(remaining) / 1000000.0))
		extreme_spirit_stones -= use
		remaining -= use * 1000000
	while remaining >= 10000 and high_spirit_stones > 0:
		var use: int = mini(high_spirit_stones, int(float(remaining) / 10000.0))
		high_spirit_stones -= use
		remaining -= use * 10000
	while remaining >= 100 and mid_spirit_stones > 0:
		var use: int = mini(mid_spirit_stones, int(float(remaining) / 100.0))
		mid_spirit_stones -= use
		remaining -= use * 100
	if spirit_stones < remaining:
		return false  # 灵石不够，去灵石庄兑换
	spirit_stones -= remaining
	return true

func earn_stones(amount: int) -> void:
	total_earned += amount
	var old_high = high_spirit_stones
	var old_extreme = extreme_spirit_stones
	var total = amount
	while total >= 1000000:
		extreme_spirit_stones += 1
		total -= 1000000
	while total >= 10000:
		high_spirit_stones += 1
		total -= 10000
	while total >= 100:
		mid_spirit_stones += 1
		total -= 100
	spirit_stones += total
	# 第一次获得上品灵石
	if high_spirit_stones > old_high and not first_high_stone:
		first_high_stone = true
		var hud = get_meta("hud")
		if hud and hud.has_method("show_toast"):
			hud.show_toast("💎 你获得了第一块上品灵石！灵墟商会都为之侧目…", Color(1, 0.85, 0.2), 5.0)
	# 第一次获得极品灵石
	if extreme_spirit_stones > old_extreme and not first_extreme_stone:
		first_extreme_stone = true
		var hud = get_meta("hud")
		if hud and hud.has_method("show_toast"):
			hud.show_toast("✨ 极品灵石！灵脉之核…整个灵墟都在震颤。你已踏入传说之列。", Color(1, 0.5, 0.9), 6.0)

# 灵石兑换：仅支持高→低单向（保持稀有度）
# 1极品=100上品, 1上品=100中品, 1中品=100下品
func exchange_down() -> int:
	var options = 0
	if extreme_spirit_stones > 0: options += 1
	if high_spirit_stones > 0: options += 1
	if mid_spirit_stones > 0: options += 1
	return options

func exchange_do(from_tier: int) -> bool:
	"""from_tier: 3=极品→上品, 2=上品→中品, 1=中品→下品"""
	if from_tier == 3 and extreme_spirit_stones > 0:
		extreme_spirit_stones -= 1
		high_spirit_stones += 100
		return true
	if from_tier == 2 and high_spirit_stones > 0:
		high_spirit_stones -= 1
		mid_spirit_stones += 100
		return true
	if from_tier == 1 and mid_spirit_stones > 0:
		mid_spirit_stones -= 1
		spirit_stones += 100
		return true
	return false


## ---------- 灵识 ----------

func spend_ling_shi(amount: int) -> bool:
	if ling_shi < amount:
		return false
	ling_shi -= amount
	return true

func reset_ling_shi() -> void:
	ling_shi = MAX_LING_SHI


## ---------- 顾客关系 ----------

func update_customer_relation(customer_name: String, delta: int) -> void:
	if not customer_relations.has(customer_name):
		customer_relations[customer_name] = {"loyalty": 0, "visits": 0, "last_seen": 0}
	var r = customer_relations[customer_name]
	
	# 人心加成：好人缘让成交好感+1，赶人的惩罚减轻
	if delta > 0 and PlayerData.ren_xin >= 30:
		delta += 1
	if delta < 0 and PlayerData.ren_xin >= 10:
		delta += 1
	if delta < 0 and PlayerData.ren_xin >= 50:
		delta += 1
	
	r.loyalty = clampi(r.loyalty + delta, 0, 10)
	r.visits += 1
	r.last_seen = game_day
	
	if delta > 0:
		ren_xin += 1  # 人心成长：好感增加时+1

func get_customer_loyalty(customer_name: String) -> int:
	if not customer_relations.has(customer_name):
		return 0
	return customer_relations[customer_name].loyalty

func get_known_customer_names() -> Array:
	var names = []
	for name in customer_relations:
		if customer_relations[name].loyalty > 0:
			names.append(name)
	return names


# ============================================================
# 库存
# ============================================================

func add_item(item_data: Dictionary) -> void:
	var existing = find_item(item_data.id)
	if not existing:
		# ID 不匹配：尝试按 名字+品阶 找同类物品（兼容不同 ID 命名体系）
		existing = find_similar_item(item_data.get("name", ""), item_data.get("tier", -1))
	if existing and existing.has("count"):
		existing.count += item_data.get("count", 1)
		# 统一 ID 为库存中已有物品的 ID
		item_data.id = existing.id
	else:
		var new_item = item_data.duplicate()
		if not new_item.has("count"):
			new_item.count = 1
		inventory.append(new_item)

func find_similar_item(item_name: String, item_tier: int) -> Dictionary:
	if item_name == "" or item_tier < 0:
		return {}
	for item in inventory:
		if item.get("name", "") == item_name and item.get("tier", -1) == item_tier:
			return item
	return {}

func remove_item(item_id: String, count: int = 1) -> bool:
	for i in range(inventory.size()):
		if inventory[i].id == item_id:
			if inventory[i].count >= count:
				inventory[i].count -= count
				if inventory[i].count <= 0:
					inventory.remove_at(i)
				return true
			return false
	return false

func find_item(item_id: String) -> Dictionary:
	for item in inventory:
		if item.id == item_id:
			return item
	return {}


# ============================================================
# 时间
# ============================================================

func advance_time(hours: float) -> void:
	time_of_day += hours
	while time_of_day >= 24.0:
		time_of_day -= 24.0
		game_day += 1
		daily_refine_count = 0
		reset_ling_shi()
		
		# 每日随机事件
		today_events = WorldEvents.roll_daily_events()
		
		# 连续出摊追踪
		if has_stalled_today:
			consecutive_stall_days += 1
		else:
			consecutive_stall_days = 0
		has_stalled_today = false
		
		season_day += 1
		if season_day > DAYS_PER_SEASON:
			season_day = 1
			season_index += 1
			if season_index >= 4:
				season_index = 0
				game_year += 1
	is_daytime = time_of_day >= 5.0 and time_of_day < 19.0

func get_time_label() -> String:
	var hour = int(time_of_day)
	var period = "上午" if hour < 12 else "下午"
	var hour_str = str(hour) if hour <= 12 else str(hour - 12)
	return "第%d天 · %s%s时" % [game_day, period, hour_str]

func get_season_label() -> String:
	return "第%d年 %s%s 第%d天" % [game_year, SEASON_EMOJI[season_index], SEASON_NAMES[season_index], season_day]

func is_festival_day() -> bool:
	return game_day % FESTIVAL_INTERVAL == 0

func advance_one_season() -> void:
	season_day = 1
	season_index += 1
	if season_index >= 4:
		season_index = 0
		game_year += 1

func advance_one_year() -> void:
	game_year += 1
	season_index = 0
	season_day = 1

# ============================================================
# 存档系统 — JSON 序列化
# ============================================================

func save_game() -> void:
	var data = {
		"spirit_stones": spirit_stones,
		"mid_spirit_stones": mid_spirit_stones,
		"high_spirit_stones": high_spirit_stones,
		"extreme_spirit_stones": extreme_spirit_stones,
		"total_earned": total_earned,
		"ling_shi": ling_shi,
		"shang_dao": shang_dao,
		"tian_dao": tian_dao,
		"ren_xin": ren_xin,
		"game_day": game_day,
		"time_of_day": time_of_day,
		"season_index": season_index,
		"season_day": season_day,
		"game_year": game_year,
		"furnace_tier": furnace_tier,
		"smelt_streak": smelt_streak,
		"trade_streak": trade_streak,
		"today_events": today_events,
		"consecutive_stall_days": consecutive_stall_days,
		"inventory": inventory,
		"customer_relations": customer_relations,
		"loyalty_events_triggered": loyalty_events_triggered,
		"lingxu_fragments": lingxu_fragments,
		"has_seen_opening": has_seen_opening,
		"shang_voice_heard": shang_voice_heard,
		"tian_voice_heard": tian_voice_heard,
		"renxin_voice_heard": renxin_voice_heard,
		"first_high_stone": first_high_stone,
		"first_extreme_stone": first_extreme_stone,
		"year_assessed": year_assessed,
		"assessment_score": assessment_score,
		"assessment_rating": assessment_rating,
		"customer_memory": customer_memory
	}
	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("存档成功！")

func load_game() -> bool:
	if not FileAccess.file_exists("user://save.json"):
		return false
	var file = FileAccess.open("user://save.json", FileAccess.READ)
	if not file:
		return false
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	if error != OK:
		return false
	var data = json.get_data()
	if not data is Dictionary:
		return false
	
	spirit_stones = data.get("spirit_stones", 150)
	mid_spirit_stones = data.get("mid_spirit_stones", 0)
	high_spirit_stones = data.get("high_spirit_stones", 0)
	extreme_spirit_stones = data.get("extreme_spirit_stones", 0)
	total_earned = data.get("total_earned", 0)
	ling_shi = data.get("ling_shi", 80)
	shang_dao = data.get("shang_dao", 0)
	tian_dao = data.get("tian_dao", 0)
	ren_xin = data.get("ren_xin", 0)
	game_day = data.get("game_day", 1)
	time_of_day = data.get("time_of_day", 6.0)
	season_index = data.get("season_index", 0)
	season_day = data.get("season_day", 1)
	game_year = data.get("game_year", 1)
	furnace_tier = data.get("furnace_tier", 1)
	smelt_streak = data.get("smelt_streak", 0)
	trade_streak = data.get("trade_streak", 0)
	today_events = data.get("today_events", [])
	consecutive_stall_days = data.get("consecutive_stall_days", 0)
	inventory = data.get("inventory", [])
	customer_relations = data.get("customer_relations", {})
	loyalty_events_triggered = data.get("loyalty_events_triggered", [])
	lingxu_fragments = data.get("lingxu_fragments", 0)
	has_seen_opening = data.get("has_seen_opening", false)
	shang_voice_heard = data.get("shang_voice_heard", false)
	tian_voice_heard = data.get("tian_voice_heard", false)
	renxin_voice_heard = data.get("renxin_voice_heard", false)
	first_high_stone = data.get("first_high_stone", false)
	first_extreme_stone = data.get("first_extreme_stone", false)
	year_assessed = data.get("year_assessed", false)
	assessment_score = data.get("assessment_score", 0)
	assessment_rating = data.get("assessment_rating", 0)
	customer_memory = data.get("customer_memory", {})
	
	is_daytime = time_of_day >= 5.0 and time_of_day < 19.0
	print("读档成功！第%d天" % game_day)
	return true
