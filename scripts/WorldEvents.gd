# ============================================================
# 灵墟之眼 — AI Director 每日事件系统
# 让世界「活着」——事件不只是文字，有真实的机械影响
# ============================================================
extends RefCounted
class_name WorldEvents

# 事件池
static func get_event_pool() -> Array:
	return [
		# === 市场事件 ===
		{
			"id": "rare_mats", "icon": "📦", "name": "稀有灵材到货",
			"desc": "一位远行商人路过灵墟，带来了几件稀有灵材。",
			"market_rare_bonus": 3, "market_price_mod": 1.0
		},
		{
			"id": "price_surge", "icon": "📈", "name": "灵材涨价",
			"desc": "邻域宗门大肆采购，灵墟灵材价格水涨船高。",
			"market_price_mod": 1.4
		},
		{
			"id": "price_drop", "icon": "📉", "name": "灵材丰收",
			"desc": "五大域同时传来灵材丰产的消息，价格普降。",
			"market_price_mod": 0.7
		},
		{
			"id": "fire_demand", "icon": "🔥", "name": "火系热潮",
			"desc": "炎狱域一位炼器大师放出风声要收火系灵材，火系价格翻倍。",
			"element_boost": 3, "market_price_mod": 1.0  # 火系=3
		},
		{
			"id": "water_demand", "icon": "💧", "name": "水系短缺",
			"desc": "玄冰域突降暴雪，水系灵材采集停滞，价格暴涨。",
			"element_boost": 2, "market_price_mod": 1.0  # 水系=2
		},
		# === 熔炼事件 ===
		{
			"id": "spirit_surge", "icon": "✨", "name": "灵潮涌动",
			"desc": "灵墟下方的古灵脉今日异常活跃，熔炉中灵气翻涌。",
			"smelt_luck_bonus": 0.12
		},
		{
			"id": "spirit_drain", "icon": "🌫️", "name": "灵气枯竭",
			"desc": "天地灵气莫名稀薄，熔炼变得格外困难。",
			"smelt_luck_bonus": -0.08
		},
		{
			"id": "heaven_watch", "icon": "👁️", "name": "天道注视",
			"desc": "冥冥中似有天道垂眸。今日熔炼失败时，灵墟碎片翻倍。",
			"smelt_luck_bonus": 0.05, "fragment_bonus": 2
		},
		# === 顾客事件 ===
		{
			"id": "caravan", "icon": "🐪", "name": "商队抵达",
			"desc": "一支来自远方的商队抵达灵墟。今日摆摊的顾客格外多。",
			"customer_bonus": 3
		},
		{
			"id": "noble_visit", "icon": "👑", "name": "贵客将至",
			"desc": "传闻一位大人物今天会到灵墟集市。准备好你的好货。",
			"vip_chance": 0.3
		},
		{
			"id": "quiet_day", "icon": "🍂", "name": "集市冷清",
			"desc": "天寒地冻，行人稀少。今日摆摊的顾客比往日少。",
			"customer_bonus": -2
		},
		# === 世界事件 ===
		{
			"id": "sect_war", "icon": "⚔️", "name": "宗门冲突",
			"desc": "金戈域和炎狱域边境发生摩擦，金系和火系灵材需求暴增。",
			"element_boost": 0, "market_price_mod": 1.3  # 双属性 金=0 火=3
		},
		{
			"id": "meteor", "icon": "☄️", "name": "天外陨星",
			"desc": "夜观天象，有陨星划破长空。传说陨星附近能捡到稀有矿石。",
			"smelt_luck_bonus": 0.10, "market_rare_bonus": 1
		},
		{
			"id": "festival_eve", "icon": "🏮", "name": "大日前夕",
			"desc": "明日就是集市大日！商贩们都在囤货，今日灵材价格略涨。",
			"market_price_mod": 1.15
		},
	]


# 每日生成1-2个随机事件
static func roll_daily_events() -> Array:
	var pool = get_event_pool()
	var rng = RandomNumberGenerator.new()
	rng.set_seed(PlayerData.game_day * 131 + PlayerData.season_index * 47)
	
	var count = 1
	if rng.randf() < 0.35:  # 35%概率出两个事件
		count = 2
	
	var result: Array = []
	var used_indices = {}
	
	for _i in range(count):
		var idx = rng.randi() % pool.size()
		var loops = 0
		while used_indices.has(idx) and loops < 30:
			idx = rng.randi() % pool.size()
			loops += 1
		used_indices[idx] = true
		result.append(pool[idx].duplicate())
	
	return result


# 应用事件到市场灵材价格
static func apply_market_event(item_price: int, item_element: int, events: Array) -> int:
	var mod = 1.0
	for ev in events:
		if ev.has("market_price_mod"):
			mod *= ev.market_price_mod
		if ev.has("element_boost") and ev.element_boost == item_element:
			mod *= 1.5  # 被点名的元素+50%
		if ev.get("id") == "sect_war":
			if item_element == 0 or item_element == 3:  # 金或火
				mod *= 1.4
	return maxi(1, int(float(item_price) * mod))


# 应用事件到熔炼成功率
static func get_smelt_luck_bonus(events: Array) -> float:
	var bonus = 0.0
	for ev in events:
		if ev.has("smelt_luck_bonus"):
			bonus += ev.smelt_luck_bonus
	return bonus


# 应用事件到碎片掉落
static func get_fragment_bonus(events: Array) -> int:
	var bonus = 0
	for ev in events:
		if ev.has("fragment_bonus"):
			bonus += ev.fragment_bonus
	return bonus


# 获取额外顾客数
static func get_customer_bonus(events: Array) -> int:
	var bonus = 0
	for ev in events:
		if ev.has("customer_bonus"):
			bonus += ev.customer_bonus
	return bonus


# 获取VIP出现概率
static func get_vip_chance(events: Array) -> float:
	var chance = 0.0
	for ev in events:
		if ev.has("vip_chance"):
			chance += ev.vip_chance
	return chance


# 今日有多少额外稀有灵材出现在市场
static func get_rare_bonus(events: Array) -> int:
	var bonus = 0
	for ev in events:
		if ev.has("market_rare_bonus"):
			bonus += ev.market_rare_bonus
	return bonus
