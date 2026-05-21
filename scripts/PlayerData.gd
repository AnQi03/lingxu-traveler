# ============================================================
# 玩家数据全局单例 - PlayerData.gd
# 管理灵石、灵材库存、三道数值、游戏时间
# ============================================================
extends Node

## ---------- 灵石 ----------
var spirit_stones: int = 30          # 下品灵石
var mid_spirit_stones: int = 0       # 中品灵石
var high_spirit_stones: int = 0      # 上品灵石

## ---------- 三道 ----------
var shang_dao: int = 0
var tian_dao: int = 0
var ren_xin: int = 0

## ---------- 时间 ----------
var game_day: int = 1
var is_daytime: bool = true
var time_of_day: float = 6.0

## ---------- 库存 ----------
var inventory: Array = []

## ---------- 熔炼 ----------
var daily_refine_count: int = 0
const MAX_DAILY_REFINE: int = 5


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
	var total = amount
	while total >= 10000:
		high_spirit_stones += 1
		total -= 10000
	while total >= 100:
		mid_spirit_stones += 1
		total -= 100
	spirit_stones += total


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
	if time_of_day >= 24.0:
		time_of_day -= 24.0
		game_day += 1
		daily_refine_count = 0
	is_daytime = time_of_day >= 5.0 and time_of_day < 19.0

func get_time_label() -> String:
	var hour = int(time_of_day)
	var period = "上午" if hour < 12 else "下午"
	var hour_str = str(hour) if hour <= 12 else str(hour - 12)
	return "第%d天 · %s%s时" % [game_day, period, hour_str]
