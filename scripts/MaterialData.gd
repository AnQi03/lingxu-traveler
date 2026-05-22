# ============================================================
# 灵材数据 - MaterialData.gd
# 静态数据定义和工具方法
# ============================================================
extends RefCounted
class_name MaterialData

enum Tier { FAN = 0, LING = 1, BAO = 2, XIAN = 3 }
enum Element { JIN = 0, MU = 1, SHUI = 2, HUO = 3, TU = 4 }


static func get_market_items() -> Array:
	return [
		{ "id": "chiyancao_fan", "name": "赤炎草", "tier": Tier.FAN, "element": Element.HUO, "base_price": 10, "desc": "火系灵草，散修日常消耗", "origin": "炎狱域" },
		{ "id": "hanlucao_fan", "name": "寒露草", "tier": Tier.FAN, "element": Element.SHUI, "base_price": 8, "desc": "喜阴湿的灵草，清心丹主料", "origin": "玄冰域" },
		{ "id": "cuilingmu_fan", "name": "翠灵木", "tier": Tier.FAN, "element": Element.MU, "base_price": 12, "desc": "灵木嫩枝，温和的木系灵气", "origin": "苍木域" },
		{ "id": "jinlingsha_fan", "name": "金灵砂", "tier": Tier.FAN, "element": Element.JIN, "base_price": 8, "desc": "通用炼器材料，用量最大", "origin": "金戈域" },
		{ "id": "ronghuoshi_fan", "name": "熔火石", "tier": Tier.FAN, "element": Element.HUO, "base_price": 5, "desc": "最简单的火系矿石", "origin": "炎狱域" },
		{ "id": "bingjingkuang_fan", "name": "冰晶矿", "tier": Tier.FAN, "element": Element.SHUI, "base_price": 6, "desc": "基础炼器材料，冷却用", "origin": "玄冰域" },
		{ "id": "huotongkuang_fan", "name": "火铜矿", "tier": Tier.FAN, "element": Element.HUO, "base_price": 8, "desc": "带火属性的铜铁矿", "origin": "炎狱域" },
		{ "id": "jiditai_fan", "name": "极地苔", "tier": Tier.FAN, "element": Element.SHUI, "base_price": 3, "desc": "最基础的消耗品", "origin": "玄冰域" },
	]


static func create_market_instance(item_def: Dictionary) -> Dictionary:
	var inst = item_def.duplicate()
	var seed_val = inst.base_price * 31 + PlayerData.game_day * 17
	var rng = RandomNumberGenerator.new()
	rng.set_seed(seed_val)
	var variation = rng.randi_range(-2, 3)
	var season_mult = _get_seasonal_price_multiplier()
	inst.price = maxi(1, int((inst.base_price + variation) * season_mult))
	inst.count = 1
	return inst

static func _get_seasonal_price_multiplier() -> float:
	match PlayerData.season_index:
		0: return 1.0   # 灵潮季：灵材丰产，正常价
		1: return 1.2   # 炎阳季：酷暑难采，涨价
		2: return 0.85  # 丰收季：万物成熟，降价
		3: return 1.4   # 静修季：灵材枯竭，暴涨
	return 1.0
