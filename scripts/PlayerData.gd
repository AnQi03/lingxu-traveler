# ============================================================
# 玩家数据全局单例 - PlayerData.gd
# 管理灵石、灵材库存、三道数值、游戏时间
# ============================================================
extends Node

## ---------- 灵石 ----------
var spirit_stones: int = 100          # 下品灵石
var mid_spirit_stones: int = 0       # 中品灵石
var high_spirit_stones: int = 0      # 上品灵石
var total_earned: int = 0            # 累计收入

## ---------- 三道 ----------
var shang_dao: int = 0
var tian_dao: int = 0
var ren_xin: int = 0

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

## ---------- 灵识 ----------
var ling_shi: int = 100
const MAX_LING_SHI: int = 100

## ---------- 熔炉升级 ----------
var furnace_tier: int = 1
const FURNACE_UPGRADE_COST = {
	2: 200,
	3: 800,
	4: 3000,
	5: 15000
}
const FURNACE_UPGRADE_LUCK = {
	1: [0.35, 0.20, 0.007],
	2: [0.50, 0.25, 0.01],
	3: [0.65, 0.35, 0.03],
	4: [0.80, 0.50, 0.08],
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

## ---------- 顾客关系 ----------
var customer_relations: Dictionary = {}


# ============================================================
# 灵石
# ============================================================

func get_total_stones() -> int:
	return spirit_stones + mid_spirit_stones * 100 + high_spirit_stones * 10000

func spend_stones(amount: int) -> bool:
	var total = get_total_stones()
	if total < amount:
		return false
	
	var remaining = amount
	while remaining >= 10000 and high_spirit_stones > 0:
		var use: int = mini(high_spirit_stones, int(float(remaining) / 10000.0))
		high_spirit_stones -= use
		remaining -= use * 10000
	while remaining >= 100 and mid_spirit_stones > 0:
		var use: int = mini(mid_spirit_stones, int(float(remaining) / 100.0))
		mid_spirit_stones -= use
		remaining -= use * 100
	spirit_stones -= remaining
	return true

func earn_stones(amount: int) -> void:
	total_earned += amount
	var total = amount
	while total >= 10000:
		high_spirit_stones += 1
		total -= 10000
	while total >= 100:
		mid_spirit_stones += 1
		total -= 100
	spirit_stones += total


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
	if existing and existing.has("count"):
		existing.count += item_data.get("count", 1)
	else:
		var new_item = item_data.duplicate()
		if not new_item.has("count"):
			new_item.count = 1
		inventory.append(new_item)

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
