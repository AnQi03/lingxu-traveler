# ============================================================
# 顾客NPC生成器 - CustomerGenerator.gd
# 生成随机顾客，管理顾客队列和议价流程
# ============================================================
extends RefCounted
class_name CustomerGenerator

## 顾客性格类型
enum Personality { 
	SHUANGZHI = 0,  # 爽直
	JINGMING = 1,   # 精明
	JIZAO = 2,      # 急躁
	NAIXIN = 3,     # 耐心
	LINSE = 4,      # 吝啬
	KANGKAI = 5,    # 慷慨
	DUOYI = 6,      # 多疑
	QINGXIN = 7     # 轻信
}

## 顾客数据结构
## {
##   "name": String,
##   "personality": int,
##   "want_item_id": String,
##   "want_count": int,
##   "base_price": int,     # 市场参考价
##   "offer_price": int,    # 顾客出价
##   "max_price": int,      # 顾客心理底价
##   "patience": int,       # 议价轮次上限
##   "round": int,          # 当前轮次
##   "is_urgent": bool,     # 是否急需
##   "mood": String         # 情绪描述（用于察言观色）
## }


const FIRST_NAMES = [
	"老赵", "刘姐", "王伯", "李婶", "陈道友",
	"周散人", "吴炼师", "郑采药", "孙铁匠", "钱掌柜",
	"马老三", "胡郎中", "何阵师", "吕符师", "林器师"
]

## 生成一个随机顾客
static func generate_customer() -> Dictionary:
	var items = MaterialData.get_market_items()
	var target_item = items[randi() % items.size()]
	
	# 随机性格
	var personality = randi() % 8
	var name = FIRST_NAMES[randi() % FIRST_NAMES.size()]
	var is_urgent = randf() < 0.25  # 25%概率是急需客
	var count = randi_range(1, 5)
	
	# 价格计算
	var base_price = target_item.base_price * count
	var offer_ratio = _get_offer_ratio(personality, is_urgent)
	var offer_price = int(base_price * offer_ratio)
	var max_ratio = _get_max_ratio(personality, is_urgent)
	var max_price = int(base_price * max_ratio)
	
	# 议价轮次
	var patience = _get_patience(personality, is_urgent)
	
	# 情绪/动作描述
	var mood = _get_mood(personality, is_urgent)
	
	return {
		"name": name,
		"personality": personality,
		"want_item": target_item,
		"want_count": count,
		"base_price": base_price,
		"offer_price": offer_price,
		"max_price": max(offer_price + 1, max_price),
		"patience": patience,
		"round": 0,
		"is_urgent": is_urgent,
		"mood": mood
	}


## 处理玩家的还价
## 返回: { "result": "accept"/"reject"/"counter"/"walk_away", "message": String, "final_price": int }
static func handle_haggle(customer: Dictionary, player_offer: int) -> Dictionary:
	customer.round += 1
	
	var result_msg = ""
	var result_type = ""
	var final_price = 0
	
	if player_offer <= customer.offer_price:
		# 玩家出价低于等于顾客当前出价 → 顾客直接接受
		result_type = "accept"
		final_price = player_offer
		result_msg = _get_accept_msg(customer)
		
	elif player_offer <= customer.max_price:
		# 玩家出价在顾客心理底价内 → 顾客接受但说两句
		result_type = "accept"
		final_price = player_offer
		result_msg = _get_grudging_accept_msg(customer)
		
	elif customer.round >= customer.patience:
		# 超过耐心上限 → 顾客走人
		result_type = "walk_away"
		result_msg = _get_walk_away_msg(customer)
		
	else:
		# 顾客讨价还价
		var new_offer = int(customer.offer_price + (customer.max_price - customer.offer_price) * 0.3)
		new_offer = mini(new_offer, customer.max_price)
		customer.offer_price = new_offer
		result_type = "counter"
		result_msg = _get_counter_msg(customer)
	
	return {
		"result": result_type,
		"message": result_msg,
		"final_price": final_price,
		"customer": customer
	}


# ========== 私有辅助方法 ==========

static func _get_offer_ratio(personality: int, urgent: bool) -> float:
	if urgent: return 0.9 + randf() * 0.3  # 急需客出价较高
	match personality:
		Personality.SHUANGZHI: return 0.7 + randf() * 0.1
		Personality.JINGMING: return 0.5 + randf() * 0.15
		Personality.JIZAO: return 0.75 + randf() * 0.1
		Personality.NAIXIN: return 0.65 + randf() * 0.1
		Personality.LINSE: return 0.45 + randf() * 0.15
		Personality.KANGKAI: return 0.8 + randf() * 0.1
		Personality.DUOYI: return 0.6 + randf() * 0.1
		Personality.QINGXIN: return 0.7 + randf() * 0.1
	return 0.7

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
