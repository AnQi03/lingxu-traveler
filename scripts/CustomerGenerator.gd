extends RefCounted
class_name CustomerGenerator

enum Personality { 
	SHUANGZHI = 0,
	JINGMING = 1,
	JIZAO = 2,
	NAIXIN = 3,
	LINSE = 4,
	KANGKAI = 5,
	DUOYI = 6,
	QINGXIN = 7
}

const FIRST_NAMES = [
	"老赵", "刘姐", "王伯", "李婶", "陈道友",
	"周散人", "吴炼师", "郑采药", "孙铁匠", "钱掌柜",
	"马老三", "胡郎中", "何阵师", "吕符师", "林器师"
]

const REGULARS = [
	{"name": "石老", "personality": Personality.NAIXIN, "pref_element": Element.TU, "mood": "须发皆白的老修士，总是慢悠悠地逛到你摊前", "bg": "散修联盟的长老，痴迷收集稀有灵材"},
	{"name": "青儿", "personality": Personality.QINGXIN, "pref_element": Element.MU, "mood": "一个蹦蹦跳跳的少女，腰间挂满了药篓", "bg": "万木灵宗的外门弟子，师父让她来历练"},
	{"name": "霍老板", "personality": Personality.JINGMING, "pref_element": Element.HUO, "mood": "穿着考究的中年商人，眼神精明", "bg": "灵墟商会的分区管事，手里有很多进货渠道"},
	{"name": "冷面客", "personality": Personality.DUOYI, "pref_element": Element.SHUI, "mood": "戴斗笠的黑衣人，从不主动说话", "bg": "寒渊宗的影子护卫，替宗门采买物资"},
	{"name": "金娘子", "personality": Personality.LINSE, "pref_element": Element.JIN, "mood": "衣着华贵但钱包捂得紧紧的中年妇人", "bg": "铸魂殿的离任炼器师，开了一家小作坊"},
]

static func generate_customer() -> Dictionary:
	var items = MaterialData.get_market_items()
	var target_item = items[randi() % items.size()]
	
	var personality = randi() % 8
	var name = ""
	var loyalty = 0
	var customer_bg = ""
	
	var known = PlayerData.get_known_customer_names()
	
	# 20%概率生成有名常客
	if randf() < 0.2:
		var regular = REGULARS[randi() % REGULARS.size()]
		name = regular.name
		personality = regular.personality
		loyalty = PlayerData.get_customer_loyalty(name)
		customer_bg = regular.bg
		# 常客偏好特定五行，60%概率要对应灵材
		if randf() < 0.6:
			var matching = []
			for it in items:
				if it.element == regular.pref_element:
					matching.append(it)
			if not matching.is_empty():
				target_item = matching[randi() % matching.size()]
	elif not known.is_empty() and randf() < 0.3:
		name = known[randi() % known.size()]
		loyalty = PlayerData.get_customer_loyalty(name)
	else:
		name = FIRST_NAMES[randi() % FIRST_NAMES.size()]
	
	var is_urgent = randf() < 0.25
	
	var day = PlayerData.game_day
	var count = 0
	if day <= 7:
		count = randi_range(1, 2)
	elif day <= 15:
		count = randi_range(1, 3)
	elif day <= 30:
		count = randi_range(2, 4)
	else:
		count = randi_range(2, 5)
	
	# 价格计算——用集市当天的实际价格（和集市面板一致）
	var market_inst = MaterialData.create_market_instance(target_item)
	var unit_price = market_inst.price
	var total_base = unit_price * count
	var offer_ratio = _get_offer_ratio(personality, is_urgent)
	var offer_price = maxi(total_base + 1, int(total_base * offer_ratio))
	var max_ratio = _get_max_ratio(personality, is_urgent)
	var max_price = maxi(offer_price + 1, int(total_base * max_ratio))
	
	# 好感度加成
	if loyalty >= 7:
		max_price = int(max_price * 1.2)
	elif loyalty >= 4:
		max_price = int(max_price * 1.1)
	
	var patience = _get_patience(personality, is_urgent)
	if loyalty >= 1:
		patience += 1
	if loyalty >= 7:
		patience += 1
	
	# 商道加成：更高的商道让顾客更耐心、出价更高
	if PlayerData.shang_dao >= 50:
		max_price = int(max_price * 1.10)
		patience += 1
	elif PlayerData.shang_dao >= 30:
		max_price = int(max_price * 1.05)
	elif PlayerData.shang_dao >= 10:
		patience += 1
	
	var mood = _get_mood(personality, is_urgent)
	if loyalty >= 5:
		mood = "⭐ 老顾客(好感%d) — " % loyalty + mood
	elif loyalty >= 1:
		mood = "回头客(好感%d) — " % loyalty + mood
	elif customer_bg != "":
		mood = "🏷 " + customer_bg
	
	return {
		"name": name,
		"personality": personality,
		"want_item": target_item,
		"want_count": count,
		"unit_price": unit_price,
		"base_price": total_base,
		"offer_price": offer_price,
		"max_price": max(offer_price + 1, max_price),
		"patience": patience,
		"round": 0,
		"is_urgent": is_urgent,
		"mood": mood,
		"loyalty": loyalty,
		"bg": customer_bg
	}


static func handle_haggle(customer: Dictionary, player_offer: int) -> Dictionary:
	customer.round += 1
	
	var result_msg = ""
	var result_type = ""
	var final_price = 0
	
	# 察言观色：每轮顾客情绪变化
	var round_mood = _get_round_mood(customer)
	
	if player_offer <= customer.offer_price:
		result_type = "accept"
		final_price = player_offer
		result_msg = _get_accept_msg(customer)
		
	elif player_offer <= customer.max_price:
		result_type = "accept"
		final_price = player_offer
		result_msg = _get_grudging_accept_msg(customer)
		
	elif customer.round >= customer.patience:
		result_type = "walk_away"
		result_msg = _get_walk_away_msg(customer)
		
	else:
		var new_offer = int(customer.offer_price + (customer.max_price - customer.offer_price) * 0.3)
		new_offer = mini(new_offer, customer.max_price)
		customer.offer_price = new_offer
		result_type = "counter"
		result_msg = _get_counter_msg(customer)
	
	# 情绪提示附加到消息
	if result_type == "counter" or result_type == "walk_away":
		result_msg = "[" + round_mood + "] " + result_msg
	
	return {
		"result": result_type,
		"message": result_msg,
		"final_price": final_price,
		"customer": customer,
		"round_mood": round_mood
	}


static func _get_round_mood(customer: Dictionary) -> String:
	var remaining = customer.patience - customer.round
	match remaining:
		0: return "💢 快没耐心了"
		1: return "🤨 有些不耐烦"
		2: return "😐 还在犹豫"
		_: return "🤔 在考虑中"


static func _get_offer_ratio(personality: int, urgent: bool) -> float:
	if urgent: return 1.1 + randf() * 0.3
	match personality:
		Personality.SHUANGZHI: return 0.9 + randf() * 0.1
		Personality.JINGMING: return 0.85 + randf() * 0.1
		Personality.JIZAO: return 0.95 + randf() * 0.1
		Personality.NAIXIN: return 0.9 + randf() * 0.1
		Personality.LINSE: return 0.8 + randf() * 0.1
		Personality.KANGKAI: return 1.0 + randf() * 0.1
		Personality.DUOYI: return 0.85 + randf() * 0.1
		Personality.QINGXIN: return 0.9 + randf() * 0.1
	return 0.9

static func _get_max_ratio(personality: int, urgent: bool) -> float:
	if urgent: return 1.3 + randf() * 0.5
	match personality:
		Personality.SHUANGZHI: return 0.85 + randf() * 0.1
		Personality.JINGMING: return 0.75 + randf() * 0.15
		Personality.JIZAO: return 0.9 + randf() * 0.1
		Personality.NAIXIN: return 0.8 + randf() * 0.1
		Personality.LINSE: return 0.65 + randf() * 0.1
		Personality.KANGKAI: return 1.0 + randf() * 0.15
		Personality.DUOYI: return 0.7 + randf() * 0.1
		Personality.QINGXIN: return 0.9 + randf() * 0.1
	return 0.85

static func _get_patience(personality: int, urgent: bool) -> int:
	if urgent: return 1
	match personality:
		Personality.SHUANGZHI: return 2
		Personality.JINGMING: return 4
		Personality.JIZAO: return 1
		Personality.NAIXIN: return 5
		Personality.LINSE: return 4
		Personality.KANGKAI: return 3
		Personality.DUOYI: return 3
		Personality.QINGXIN: return 2
	return 3

static func _get_mood(personality: int, urgent: bool) -> String:
	if urgent: return "神色匆匆，似乎很着急"
	match personality:
		Personality.SHUANGZHI: return "大大咧咧，不拘小节"
		Personality.JINGMING: return "目光锐利，四处打量"
		Personality.JIZAO: return "不耐烦地跺着脚"
		Personality.NAIXIN: return "气定神闲，不急不慢"
		Personality.LINSE: return "攥着钱袋，一脸不舍"
		Personality.KANGKAI: return "笑眯眯的，看起来很和善"
		Personality.DUOYI: return "上下打量你，一脸怀疑"
		Personality.QINGXIN: return "看起来很信任你的样子"
	return "神色如常"

static func _get_accept_msg(c: Dictionary) -> String:
	return "%s爽快地付了灵石：'成交！'" % c.name

static func _get_grudging_accept_msg(c: Dictionary) -> String:
	return "%s犹豫了一下：'……好吧，就这个价。'" % c.name

static func _get_walk_away_msg(c: Dictionary) -> String:
	return "%s摇了摇头：'太贵了太贵了，我去别家看看。'说完转身走了。" % c.name

static func _get_counter_msg(c: Dictionary) -> String:
	return "%s皱了皱眉：'这个价不行。最多……%d灵石。'" % [c.name, c.offer_price]
