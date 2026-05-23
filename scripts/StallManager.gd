# ============================================================
# 摆摊系统 - StallManager.gd
# 管理摆摊状态、顾客队列、交易流程
# ============================================================
extends Node
class_name StallManager

signal customer_arrived(customer_data: Dictionary)
signal trade_completed(item_id: String, count: int, price: int)
signal trade_failed(item_id: String, reason: String)
signal stall_closed()
signal order_available(order_data: Dictionary)

var is_open: bool = false          # 摊位是否开张
var customer_queue: Array = []      # 等待中的顾客
var current_customer: Dictionary = {}  # 当前正在交易的顾客
var customer_timer: float = 0.0    # 下一位顾客到来的倒计时
var spawn_interval: float = 8.0    # 顾客生成间隔（秒）
var max_daily_customers: int = 10  # 每日最大顾客数
var today_customers: int = 0       # 今日已接待顾客数
var daily_income: int = 0          # 今日收入


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if not is_open or current_customer:
		return
	if today_customers >= max_daily_customers:
		return
	
	customer_timer -= delta
	if customer_timer <= 0.0:
		_spawn_customer()
		customer_timer = spawn_interval + randf_range(-2.0, 2.0)


func open_stall() -> void:
	is_open = true
	customer_timer = 2.0  # 开张后2秒来第一位顾客
	
	var msg = "摊位开张了！"
	var streak = PlayerData.consecutive_stall_days + 1  # +1 because we're about to start today
	if streak >= 7:
		msg += " [🔥 连续出摊%d天！老顾客都等着你呢]" % streak
	elif streak >= 3:
		msg += " [📅 连续出摊%d天]" % streak
	
	var hot_items = MaterialData.get_daily_hot_items()
	if not hot_items.is_empty():
		var hot_names = []
		var cold_names = []
		for it in hot_items:
			if it.get("hot"):
				hot_names.append(it.name)
			else:
				cold_names.append(it.name)
		if not hot_names.is_empty():
			msg += " | 📈 热门: %s" % "/".join(hot_names)
		if not cold_names.is_empty():
			msg += " | 📉 冷门: %s" % "/".join(cold_names)
	
	print(msg)


func close_stall() -> void:
	is_open = false
	current_customer = {}
	stall_closed.emit()
	print("收摊了。今日收入: %d灵石" % daily_income)


## 开始和当前顾客议价
func start_haggle(player_offer: int) -> Dictionary:
	if current_customer.is_empty():
		return { "result": "error", "message": "没有顾客" }
	
	# 先查库存，没货不扣灵识
	var item = current_customer.want_item
	if PlayerData.find_item(item.id).get("count", 0) < current_customer.want_count:
		var msg = CustomerGenerator._get_no_stock_msg(current_customer)
		trade_failed.emit(item.id, 0, msg)
		current_customer = {}
		return { "result": "error", "message": msg }
	
	if not PlayerData.spend_ling_shi(3):
		return { "result": "error", "message": "灵识耗尽！今天你已经太累了，休息吧。" }
	
	var result = CustomerGenerator.handle_haggle(current_customer, player_offer)
	current_customer = result.customer
	
	match result.result:
		"accept":
			# 交易成功
			var total_price = result.final_price
			var count = current_customer.want_count
			
			# 交易连胜加成（3/5/7连）
			PlayerData.trade_streak += 1
			var streak_bonus = 0
			if PlayerData.trade_streak >= 7:
				streak_bonus = int(total_price * 0.12)
				result.message += "\n💎 财源滚滚！连成%d单，+%d灵石！" % [PlayerData.trade_streak, streak_bonus]
			elif PlayerData.trade_streak >= 5:
				streak_bonus = int(total_price * 0.07)
				result.message += "\n✨ 生意兴隆！连成%d单，+%d灵石！" % [PlayerData.trade_streak, streak_bonus]
			elif PlayerData.trade_streak >= 3:
				streak_bonus = int(total_price * 0.03)
				result.message += "\n🔥 手感正热！连成%d单，+%d灵石！" % [PlayerData.trade_streak, streak_bonus]
			
			PlayerData.remove_item(item.id, count)
			PlayerData.earn_stones(total_price + streak_bonus)
			daily_income += total_price + streak_bonus
			today_customers += 1
			PlayerData.update_customer_relation(current_customer.name, 2)
			PlayerData.shang_dao += 1  # 商道成长：每次成功交易+1
			PlayerData.has_stalled_today = true  # 连续出摊追踪
			
			# 商道初体验
			if not PlayerData.shang_voice_heard and PlayerData.shang_dao >= 1:
				PlayerData.shang_voice_heard = true
				var hud = PlayerData.get_meta("hud")
				if hud and hud.has_method("show_toast"):
					hud.show_toast("💼 商道：「这人的绸缎料子不错——出得起价。记住，察言观色是第一课。」", Color(0.3, 0.85, 0.3), 6.0)
			
			# 人心初体验（有回头客时触发）
			if not PlayerData.renxin_voice_heard and PlayerData.ren_xin >= 1:
				PlayerData.renxin_voice_heard = true
				var hud = PlayerData.get_meta("hud")
				if hud and hud.has_method("show_toast"):
					hud.show_toast("❤️ 人心：「他记得你。这灵墟里，真心比灵石更难得。」", Color(1, 0.6, 0.6), 6.0)
			
			# 常客心级事件
			var new_loyalty = PlayerData.get_customer_loyalty(current_customer.name)
			var event_data = CustomerGenerator.get_loyalty_event(current_customer.name, new_loyalty)
			if event_data.message != "":
				result.message = event_data.message + "\n\n" + result.message
				_apply_loyalty_reward(event_data.reward, result.final_price + streak_bonus)
				var hud = PlayerData.get_meta("hud")
				if hud and hud.has_method("show_toast"):
					hud.show_toast("💎 %s 好感 Lv.%d！" % [current_customer.name, new_loyalty], Color(0.8, 0.4, 1.0), 5.0)
			trade_completed.emit(item.id, count, total_price)
			PlayerData.remember_deal(current_customer.name, total_price, "accept")
			current_customer = {}
				
		"walk_away":
			# 顾客走了
			PlayerData.update_customer_relation(current_customer.name, -1)
			PlayerData.remember_deal(current_customer.name, 0, "walk_away")
			trade_failed.emit(current_customer.want_item.id, 0, result.message)
			current_customer = {}
			PlayerData.trade_streak = 0  # 连胜中断
			
		"counter":
			# 顾客还价——保留current_customer等待下一轮
			pass
	
	return result


## 逐出当前顾客（玩家不想卖了）
func dismiss_customer() -> void:
	if not current_customer.is_empty():
		PlayerData.update_customer_relation(current_customer.name, -2)
		PlayerData.trade_streak = 0  # 连胜中断
		var msg = CustomerGenerator._get_dismiss_msg(current_customer)
		trade_failed.emit(current_customer.want_item.id, 0, msg)
		current_customer = {}


func _spawn_customer() -> void:
	var customer = CustomerGenerator.generate_customer()
	customer_queue.append(customer)
	current_customer = customer
	customer_arrived.emit(customer)
	
	# 常客可能下订单（忠诚≥2，25%概率）
	var loyalty = PlayerData.get_customer_loyalty(customer.name)
	if loyalty >= 2 and randf() < 0.25 and PlayerData.orders.size() < 3:
		var order = _generate_order(customer)
		if not order.is_empty():
			order_available.emit(order)

func _generate_order(customer: Dictionary) -> Dictionary:
	var tier = randi_range(0, 1)  # 凡品或灵品
	var element = customer.want_item.element
	var count = randi_range(2, 5)
	var days = randi_range(3, 7)
	var price_per = [8, 80][tier]  # 凡品8/灵品80
	var reward = int(count * price_per * randf_range(1.3, 1.8))
	return {
		"customer_name": customer.name,
		"item_tier": tier,
		"item_element": element,
		"count": count,
		"days": days,
		"reward": reward
	}

func _apply_loyalty_reward(reward: String, trade_price: int) -> void:
	match reward:
		"blessing_shangdao_3":
			PlayerData.shang_dao += 3
		"blessing_shangdao_5":
			PlayerData.shang_dao += 5
		"blessing_tiandao_3":
			PlayerData.tian_dao += 3
		"blessing_tiandao_5":
			PlayerData.tian_dao += 5
		"blessing_renxin_3":
			PlayerData.ren_xin += 3
		"blessing_renxin_5":
			PlayerData.ren_xin += 5
		"blessing_all_3":
			PlayerData.shang_dao += 3
			PlayerData.tian_dao += 3
			PlayerData.ren_xin += 3
		"blessing_all_5":
			PlayerData.shang_dao += 5
			PlayerData.tian_dao += 5
			PlayerData.ren_xin += 5
		"gift_stones_50":
			PlayerData.earn_stones(50)
			daily_income += 50
		"gift_extra_loyalty":
			PlayerData.update_customer_relation(current_customer.name, 1)
		"refund_ling_shi":
			PlayerData.ling_shi = mini(PlayerData.ling_shi + 3, PlayerData.MAX_LING_SHI)
		"price_boost_20":
			PlayerData.earn_stones(int(trade_price * 0.2))
			daily_income += int(trade_price * 0.2)
		"gift_item_shui":
			PlayerData.add_item({"id":"bingjingkuang_fan","name":"冰晶矿","tier":0,"element":2,"price":6,"count":1})
		"stone_earth":
			PlayerData.add_item({"id":"jinlingsha_fan","name":"金灵砂","tier":0,"element":0,"price":8,"count":1})
