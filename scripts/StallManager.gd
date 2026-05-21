# ============================================================
# 摆摊系统 - StallManager.gd
# 管理摆摊状态、顾客队列、交易流程
# ============================================================
extends Node
class_name StallManager

signal customer_arrived(customer_data: Dictionary)
signal trade_completed(item_id: String, count: int, price: int)
signal trade_failed(item_id: String, reason: String)

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
	print("摊位开张了！")


func close_stall() -> void:
	is_open = false
	current_customer = {}
	print("收摊了。今日收入: %d灵石" % daily_income)


## 开始和当前顾客议价
func start_haggle(player_offer: int) -> Dictionary:
	if current_customer.is_empty():
		return { "result": "error", "message": "没有顾客" }
	
	var result = CustomerGenerator.handle_haggle(current_customer, player_offer)
	current_customer = result.customer
	
	match result.result:
		"accept":
			# 交易成功
			var item = current_customer.want_item
			var total_price = result.final_price
			var count = current_customer.want_count
			
			# 检查库存
			if PlayerData.find_item(item.id).get("count", 0) >= count:
				PlayerData.remove_item(item.id, count)
				PlayerData.earn_stones(total_price)
				daily_income += total_price
				today_customers += 1
				trade_completed.emit(item.id, count, total_price)
				current_customer = {}
			else:
				result.result = "no_stock"
				result.message = "你没有足够的%s" % item.name
				trade_failed.emit(item.id, 0, "库存不足")
				current_customer = {}
				
		"walk_away":
			# 顾客走了
			trade_failed.emit(current_customer.want_item.id, 0, "顾客走了")
			current_customer = {}
			
		"counter":
			# 顾客还价——保留current_customer等待下一轮
			pass
	
	return result


## 逐出当前顾客（玩家不想卖了）
func dismiss_customer() -> void:
	if not current_customer.is_empty():
		trade_failed.emit(current_customer.want_item.id, 0, "玩家拒绝交易")
		current_customer = {}


func _spawn_customer() -> void:
	var customer = CustomerGenerator.generate_customer()
	customer_queue.append(customer)
	current_customer = customer
	customer_arrived.emit(customer)
