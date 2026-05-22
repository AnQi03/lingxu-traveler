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
	{"name": "石老", "personality": Personality.NAIXIN, "pref_element": MaterialData.Element.TU, "mood": "须发皆白的老修士，总是慢悠悠地逛到你摊前", "bg": "散修联盟的长老，痴迷收集稀有灵材"},
	{"name": "青儿", "personality": Personality.QINGXIN, "pref_element": MaterialData.Element.MU, "mood": "一个蹦蹦跳跳的少女，腰间挂满了药篓", "bg": "万木灵宗的外门弟子，师父让她来历练"},
	{"name": "霍老板", "personality": Personality.JINGMING, "pref_element": MaterialData.Element.HUO, "mood": "穿着考究的中年商人，眼神精明", "bg": "灵墟商会的分区管事，手里有很多进货渠道"},
	{"name": "冷面客", "personality": Personality.DUOYI, "pref_element": MaterialData.Element.SHUI, "mood": "戴斗笠的黑衣人，从不主动说话", "bg": "寒渊宗的影子护卫，替宗门采买物资"},
	{"name": "金娘子", "personality": Personality.LINSE, "pref_element": MaterialData.Element.JIN, "mood": "衣着华贵但钱包捂得紧紧的中年妇人", "bg": "铸魂殿的离任炼器师，开了一家小作坊"},
]

static func generate_customer() -> Dictionary:
	var items = MaterialData.get_market_items()
	var target_item = items[randi() % items.size()]
	
	var personality = randi() % 8
	var name = ""
	var loyalty = 0
	var customer_bg = ""
	
	var known = PlayerData.get_known_customer_names()
	
	# Day1 第一位顾客必是常客——给新手一个好印象
	if PlayerData.game_day == 1 and randf() < 0.8:
		var regular = REGULARS[randi() % REGULARS.size()]
		name = regular.name
		personality = regular.personality
		loyalty = 0
		customer_bg = regular.bg
		if randf() < 0.6:
			var matching = []
			for it in items:
				if it.element == regular.pref_element:
					matching.append(it)
			if not matching.is_empty():
				target_item = matching[randi() % matching.size()]
	# 20%概率生成有名常客
	elif randf() < 0.2:
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
	
	# 价格计算——NPC不了解你的成本，按市场感知出价
	var market_inst = MaterialData.create_market_instance(target_item)
	var unit_price = market_inst.price
	var reference_price = unit_price * count  # 市场参考价
	
	# 初始出价：不同性格差距巨大（可能远低于参考价）
	var offer_ratio = _get_offer_ratio(personality, is_urgent)
	var offer_price = int(reference_price * offer_ratio)
	
	# 心理上限：愿意出到的最高价
	var max_ratio = _get_max_ratio(personality, is_urgent)
	var max_price = int(reference_price * max_ratio)
	
	# 最低接受价：低于此价可能直接走人
	var min_accept = int(offer_price * 0.7)
	
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
		"base_price": reference_price,
		"offer_price": offer_price,
		"max_price": max_price,
		"min_accept": min_accept,
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
	
	# 要价太高可能直接激怒顾客
	if player_offer > customer.max_price * 1.3:
		var anger_chance = 0.3 - float(PlayerData.shang_dao) / 200.0
		if randf() < anger_chance:
			# 10%概率：假走真回——嘴上说走，又回头加价
			if randf() < 0.15:
				result_type = "counter"
				customer.patience += 1
				var comeback_offer = int(customer.offer_price + (customer.max_price - customer.offer_price) * 0.25)
				customer.offer_price = clampi(comeback_offer, customer.offer_price + 1, customer.max_price)
				result_msg = "[😤 转身欲走又回头] " + customer.name + "咬了咬牙：'……%d！真是最后价了！'" % customer.offer_price
				return {"result": result_type, "message": result_msg, "final_price": 0, "customer": customer, "round_mood": round_mood}
			result_type = "walk_away"
			result_msg = "[💢 被激怒了] " + _get_walk_away_msg(customer)
			return {"result": result_type, "message": result_msg, "final_price": 0, "customer": customer, "round_mood": round_mood}
	
	if player_offer <= customer.offer_price:
		result_type = "accept"
		final_price = player_offer
		result_msg = _get_accept_msg(customer)
		
	elif player_offer <= customer.max_price:
		result_type = "accept"
		final_price = player_offer
		result_msg = _get_grudging_accept_msg(customer)
		
	elif customer.round >= customer.patience:
		# 偶尔给最后一次机会
		if randf() < 0.35 and customer.round < customer.patience + 2:
			customer.patience += 1
			var new_offer = int(customer.offer_price + (customer.max_price - customer.offer_price) * 0.15)
			customer.offer_price = clampi(new_offer, customer.offer_price + 1, customer.max_price)
			result_type = "counter"
			result_msg = "[😤 本想走了…] " + customer.name + "站住脚步：'最后一次——%d灵石！'" % customer.offer_price
		else:
			result_type = "walk_away"
			result_msg = _get_walk_away_msg(customer)
		
	else:
		# 让步递减：越往后让步越小
		var gap = customer.max_price - customer.offer_price
		var concession = 0.0
		match customer.round:
			1: concession = 0.35
			2: concession = 0.25
			3: concession = 0.12
			_: concession = 0.05
		
		# 性格调整
		match customer.personality:
			Personality.SHUANGZHI: concession += 0.08
			Personality.JINGMING: concession -= 0.06
			Personality.JIZAO: concession += 0.12
			Personality.NAIXIN: concession -= 0.02
			Personality.LINSE: concession -= 0.10
			Personality.KANGKAI: concession += 0.10
			Personality.DUOYI: concession -= 0.04
		
		# NPC接近上限时可能"松口"加速
		var closeness = float(customer.offer_price) / float(customer.max_price)
		if closeness > 0.8 and randf() < 0.3:
			concession += 0.10  # 快了！突然松口
			result_msg = "[✨ 口风松动] " + customer.name + "犹豫了一下：'要不你再让一步？差不多就成了。'"
		
		var new_offer = int(customer.offer_price + gap * concession)
		new_offer = clampi(new_offer, customer.offer_price + 1, customer.max_price)
		customer.offer_price = new_offer
		result_type = "counter"
		if result_msg == "":
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
	if urgent: return 1.10 + randf() * 0.15
	match personality:
		Personality.SHUANGZHI: return 0.90 + randf() * 0.10
		Personality.JINGMING: return 0.72 + randf() * 0.13
		Personality.JIZAO: return 0.80 + randf() * 0.15
		Personality.NAIXIN: return 0.78 + randf() * 0.12
		Personality.LINSE: return 0.68 + randf() * 0.12
		Personality.KANGKAI: return 1.00 + randf() * 0.15
		Personality.DUOYI: return 0.72 + randf() * 0.13
		Personality.QINGXIN: return 0.85 + randf() * 0.15
	return 0.80

static func _get_max_ratio(personality: int, urgent: bool) -> float:
	if urgent: return 1.70 + randf() * 0.30
	match personality:
		Personality.SHUANGZHI: return 1.45 + randf() * 0.20
		Personality.JINGMING: return 1.50 + randf() * 0.25
		Personality.JIZAO: return 1.35 + randf() * 0.20
		Personality.NAIXIN: return 1.50 + randf() * 0.25
		Personality.LINSE: return 1.40 + randf() * 0.20
		Personality.KANGKAI: return 1.65 + randf() * 0.30
		Personality.DUOYI: return 1.45 + randf() * 0.25
		Personality.QINGXIN: return 1.50 + randf() * 0.25
	return 1.45

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
	var msgs = {
		Personality.SHUANGZHI: ["%s爽快地一拍桌子：'成交！老板够意思！'", "%s笑道：'行！我就喜欢痛快的！'"],
		Personality.JINGMING: ["%s眯起眼：'这个价还行……成交。'", "%s仔细点了点灵石：'好，就这个价。'"],
		Personality.JIZAO: ["%s一把抓过灵材：'行行行赶紧的！'", "%s急匆匆道：'成交成交，别磨蹭！'"],
		Personality.NAIXIN: ["%s慢悠悠道：'嗯……这个价可以。'", "%s点点头，不紧不慢地付了灵石。"],
		Personality.LINSE: ["%s咬着牙：'……行吧，算你狠。'", "%s一脸不情愿地掏出灵石：'便宜你了。'"],
		Personality.KANGKAI: ["%s哈哈大笑：'成交！多给你几块灵石当赏钱！'", "%s爽朗一笑：'好买卖！拿着！'"],
		Personality.DUOYI: ["%s反复查验灵材后才点头：'……行，成交。'", "%s狐疑地盯着你：'质量没问题吧？那……成交。'"],
		Personality.QINGXIN: ["%s开心地付了灵石：'成交！老板你人真好！'", "%s笑眯眯道：'好呀好呀，就这个价！'"],
	}
	var pool = msgs.get(c.personality, ["%s点点头：'成交。'" % c.name])
	return pool[randi() % pool.size()] % c.name

static func _get_no_stock_msg(c: Dictionary) -> String:
	var name = c.name
	var bg = c.get("bg", "")
	if bg != "":
		match name:
			"石老": return "石老慢悠悠地看了你一眼：'小友，没有货就不要浪费老朽的时间。'"
			"青儿": return "青儿噘起嘴：'啊？没有啊……那你还摆什么摊嘛！'"
			"霍老板": return "霍老板皱了皱眉：'没货？这可不像做生意的样子。'"
			"冷面客": return "冷面客一言不发，转身就走。"
			"金娘子": return "金娘子哼了一声：'什么也没有出来摆什么摊。'"
	
	var msgs = {
		Personality.SHUANGZHI: ["%s一愣：'啥？没有？早说嘛！'", "%s挠挠头：'没货啊……那我改天来。'"],
		Personality.JINGMING: ["%s扫了一眼空摊：'没货还摆摊？浪费时间。'", "%s摇了摇头：'没准备好就不要开张。'"],
		Personality.JIZAO: ["%s大怒：'没有？！信不信我砸了你这破烂摊子！'", "%s一脚踢在摊位上：'耍老子玩呢？！'", "%s脸都气红了：'没货你摆什么摆！'"],
		Personality.NAIXIN: ["%s也不恼：'没关系，我明天再来看看。'", "%s笑了笑：'不妨事，做生意哪有天天有货的。'"],
		Personality.LINSE: ["%s瞪眼：'什么？亏我大老远跑来！'", "%s哼了一声：'白跑一趟，你得赔我路费！'"],
		Personality.KANGKAI: ["%s摆摆手：'哈哈没事没事，下次有了记得给我留着！'", "%s笑道：'不要紧，改日再来便是。'"],
		Personality.DUOYI: ["%s眯起眼睛：'你是看不起我，还是真没有？'", "%s左右看了看：'该不会是藏起来不卖给我吧？'"],
		Personality.QINGXIN: ["%s失望地低下头：'啊……没有啊……'", "%s有点难过：'我特意跑来的……算了算了。'"],
	}
	var pool = msgs.get(c.personality, ["%s转身走了。" % name])
	return pool[randi() % pool.size()] % name

static func _get_walk_away_msg(c: Dictionary) -> String:
	var name = c.name
	var msgs = {
		Personality.SHUANGZHI: ["%s一摆手：'太贵了，不买了不买了！'", "%s摇头：'这价钱不太实在，走了。'"],
		Personality.JINGMING: ["%s冷笑：'这个价，你当我是冤大头？'", "%s转身就走：'我去别家比比价。'"],
		Personality.JIZAO: ["%s破口大骂：'抢钱啊？！老子不买了！'", "%s一甩袖子：'这破摊子，下次不来了！'", "%s重重哼了一声：'真当自己是仙品了？'"],
		Personality.NAIXIN: ["%s叹了口气：'还是贵了点，下次吧。'", "%s慢悠悠地起身：'不急，我去逛逛别家。'"],
		Personality.LINSE: ["%s攥紧钱袋：'这么贵，你是要我倾家荡产？'", "%s嘀嘀咕咕：'便宜点会死啊……走了。'"],
		Personality.KANGKAI: ["%s笑道：'这价高了点，不过——算了，改天再来。'", "%s拍了拍摊位：'老板，下次便宜点我给你介绍客人！'"],
		Personality.DUOYI: ["%s狐疑地打量你：'你是不是看我好欺负故意抬价？'", "%s阴沉着脸：'我觉得你在骗我。走了。'"],
		Personality.QINGXIN: ["%s一脸为难：'我……我没那么多灵石。对不起。'", "%s小声道：'太贵了……我不买了。'"],
	}
	var pool = msgs.get(c.personality, ["%s摇了摇头走了。" % name])
	return pool[randi() % pool.size()] % name

static func _get_counter_msg(c: Dictionary) -> String:
	var name = c.name
	var msgs = {
		Personality.SHUANGZHI: ["%s直说道：'不行不行，最多%d灵石。'", "%s想了想：'说实在的，%d灵石顶天了。'"],
		Personality.JINGMING: ["%s精打细算道：'我给你算过了，%d灵石才合理。'", "%s伸出几根手指：'这个数——%d，多了没有。'"],
		Personality.JIZAO: ["%s不耐烦地敲着桌子：'快点！%d灵石，卖不卖？！'", "%s吼道：'磨蹭什么！%d爱卖不卖！'"],
		Personality.NAIXIN: ["%s不急不缓：'再想想——%d灵石如何？'", "%s温和地说：'不着急，你再考虑考虑，%d灵石。'"],
		Personality.LINSE: ["%s一脸肉疼：'%d……已经是我的极限了。'", "%s咬着牙：'最多最多——%d！多了我真的买不起。'"],
		Personality.KANGKAI: ["%s笑道：'咱们各退一步，%d灵石，成不？'", "%s豪爽道：'这样，我再加一点——%d灵石！'"],
		Personality.DUOYI: ["%s警惕地看着你：'我觉得你在宰我。最多%d。'", "%s压低声音：'别唬我，我知道市价——%d。'"],
		Personality.QINGXIN: ["%s怯生生道：'%d灵石可不可以……'", "%s试探着问：'那个……%d灵石行吗？'"],
	}
	var pool = msgs.get(c.personality, ["%s还价道：'%d灵石。'"])
	# 每轮换一句，不重复
	var idx = (c.round - 1) % pool.size()
	return pool[idx] % [name, c.offer_price]

static func _get_dismiss_msg(c: Dictionary) -> String:
	var name = c.name
	var bg = c.get("bg", "")
	if bg != "":
		match name:
			"石老": return "石老叹了口气：'年轻人，这么没耐心可不行。'"
			"青儿": return "青儿气鼓鼓地走了：'再也不来你这了！'"
			"霍老板": return "霍老板冷笑：'这就是你的待客之道？'"
	
	var msgs = {
		Personality.SHUANGZHI: ["%s一摆手：'不卖拉倒！'" % name, "%s头也不回：'行，买卖不成仁义在。'" % name],
		Personality.JINGMING: ["%s冷着脸：'你会后悔的。'" % name, "%s不屑道：'不做生意也好，省得亏本。'" % name],
		Personality.JIZAO: ["%s暴跳如雷：'耍我？！你这摊子我记住了！'" % name, "%s一脚踢飞石子：'什么玩意儿！'" % name],
		Personality.NAIXIN: ["%s也不生气：'没事，买卖嘛，讲不成就算了。'" % name, "%s点点头：'那我就不打扰了。'" % name],
		Personality.LINSE: ["%s骂骂咧咧：'白费我半天功夫……'" % name, "%s甩手走了：'真晦气！'" % name],
		Personality.KANGKAI: ["%s哈哈大笑：'没关系！生意不成情意在！'" % name, "%s拍拍你肩膀：'下次再说，下次再说。'" % name],
		Personality.DUOYI: ["%s冷冷道：'果然有猫腻。'" % name, "%s用怀疑的眼神最后看了你一眼才走。" % name],
		Personality.QINGXIN: ["%s委屈巴巴：'好吧……那我走了。'" % name, "%s小声道歉：'对不起打扰了……'" % name],
	}
	var pool = msgs.get(c.personality, ["%s转身走了。" % name])
	return pool[randi() % pool.size()]

# ============================================================
# 常客心级事件 — loyalty 3/5/7 触发专属对话
# ============================================================

static func get_loyalty_event(customer_name: String, loyalty: int) -> String:
	var event_key = "%s_%d" % [customer_name, loyalty]
	if event_key in PlayerData.loyalty_events_triggered:
		return ""
	
	PlayerData.loyalty_events_triggered.append(event_key)
	
	match customer_name:
		"石老":
			match loyalty:
				2: return "石老慢悠悠地从袖中取出一枚旧玉简：'年轻人，老夫观察你许久了。你对灵材的感知，不一般。'"
				4: return "石老难得地露出笑容：'老夫年轻时也曾在散修联盟闯荡……看到你，就像看到当年的自己。'"
				6: return "石老郑重地递过一枚令牌：'这是老夫的引荐信。散修联盟的门，永远为你开着。'"
		"青儿":
			match loyalty:
				2: return "青儿兴奋地比划着：'老板老板！我按你说的买了那株赤炎草，师父都夸我有眼光！'"
				4: return "青儿眼睛亮晶晶的：'等我筑基成功了，一定要请你来万木灵宗看看！师父说要请你吃饭！'"
				6: return "青儿神秘兮兮地凑近：'师父说，你的熔炼手法不是凡人能会的。老板，你到底是什么来头呀？'"
		"霍老板":
			match loyalty:
				2: return "霍老板压低声音：'小兄弟，有批货我想让你过过眼。一般人我不放心。'"
				4: return "霍老板递来一张契约：'灵墟商会有个规矩——合作满五次以上的伙伴，可以免押金赊账。你够格了。'"
				6: return "霍老板神色凝重：'天机子大人最近身体不太好……商会暗流涌动。你是少数我信得过的人。'"
		"冷面客":
			match loyalty:
				2: return "黑衣人在案板上放了块冰蓝色的令牌，什么也没说就走了。令牌上刻着：寒渊。"
				4: return "冷面客终于开口：'你的灵材……品相很好。寒渊宗需要长期供货。'声音低沉沙哑。"
				6: return "冷面客摘下斗笠——是一张年轻却带着疤痕的脸：'我叫沈霜。既然你信得过我，我也就不再藏着了。'"
		"金娘子":
			match loyalty:
				2: return "金娘子挑剔地翻看着你的灵材：'嗯……勉强入眼。不过比东市那几家好多了。'"
				4: return "金娘子叹了口气：'我那作坊缺个懂灵材的。你要是哪天不想摆摊了，随时来找我。'"
				6: return "金娘子忽然红了眼眶：'当年铸魂殿把我赶出来时，我以为这辈子完了……谢谢你一直认真对待我的每一单生意。'"
	
	return ""


static func _get_grudging_accept_msg(c: Dictionary) -> String:
	var name = c.name
	var msgs = {
		Personality.SHUANGZHI: ["%s想了想：'有点贵……不过算了，成交。'", "%s犹豫一下：'行吧行吧，就这个价。'"],
		Personality.JINGMING: ["%s盘算了一会：'……勉强不亏，成交。'", "%s小声嘀咕：'其实还能再低点的……算了。'"],
		Personality.JIZAO: ["%s不耐烦道：'行行行就这个价赶紧的！'", "%s一把抓过灵材：'成交！别废话了！'"],
		Personality.NAIXIN: ["%s沉吟片刻：'嗯……这个价也还行。成交。'", "%s不紧不慢：'好吧，就依你。'"],
		Personality.LINSE: ["%s咬了咬牙，手抖着递出灵石：'……行。'", "%s一脸肉疼：'我这可是大出血了……'"],
		Personality.KANGKAI: ["%s笑道：'这个价不算贵，成交！'", "%s爽快掏钱：'行！就当交个朋友！'"],
		Personality.DUOYI: ["%s反复检查了灵材：'……没做手脚吧？行，成交。'", "%s犹豫了一会才点头：'好吧，信你一次。'"],
		Personality.QINGXIN: ["%s开心道：'可以可以！谢谢你！'", "%s松了口气：'好，那就这个价！'"],
	}
	var pool = msgs.get(c.personality, ["%s犹豫了一下：'……好吧。'" % name])
	return pool[randi() % pool.size()] % name
