# ============================================================
# 摆摊场景 - StallScene.gd
# 白天经营的主界面：显示摊位、顾客、议价
# ============================================================
extends CanvasLayer

var stall_manager
var is_trading: bool = false

@onready var bg_sprite: TextureRect = $BG
@onready var stall_panel: Panel = $StallPanel
@onready var open_btn: Button = $StallPanel/OpenBtn
@onready var close_btn: Button = $StallPanel/CloseBtn
@onready var status_label: Label = $StallPanel/StatusLabel
@onready var income_label: Label = $StallPanel/IncomeLabel

@onready var customer_panel: Panel = $CustomerPanel
@onready var customer_name: Label = $CustomerPanel/NameLabel
@onready var customer_mood: Label = $CustomerPanel/MoodLabel
@onready var customer_request: Label = $CustomerPanel/RequestLabel
@onready var customer_price: Label = $CustomerPanel/PriceLabel

@onready var haggle_panel: Panel = $HagglePanel
@onready var haggle_slider: HSlider = $HagglePanel/HSlider
@onready var haggle_value: Label = $HagglePanel/ValueLabel
@onready var haggle_accept: Button = $HagglePanel/AcceptBtn
@onready var haggle_counter: Button = $HagglePanel/CounterBtn
@onready var haggle_reject: Button = $HagglePanel/RejectBtn
@onready var haggle_result: Label = $HagglePanel/ResultLabel

@onready var inventory_info: Label = $StallPanel/InventoryInfo


func _ready() -> void:
	# 初始化摆摊管理器
	stall_manager = StallManager.new()
	stall_manager.name = "StallManager"
	add_child(stall_manager)
	
	# 连接信号
	stall_manager.customer_arrived.connect(_on_customer_arrived)
	stall_manager.trade_completed.connect(_on_trade_completed)
	stall_manager.trade_failed.connect(_on_trade_failed)
	stall_manager.stall_closed.connect(_on_stall_closed)
	
	# 连接按钮
	open_btn.pressed.connect(_on_open_stall)
	close_btn.pressed.connect(_on_close_stall)
	haggle_accept.pressed.connect(_on_accept_price)
	haggle_counter.pressed.connect(_on_counter_offer)
	haggle_reject.pressed.connect(_on_reject_customer)
	haggle_slider.value_changed.connect(_on_slider_changed)
	
	# 初始隐藏
	customer_panel.hide()
	haggle_panel.hide()
	_update_ui()


func _process(_delta: float) -> void:
	_update_ui()


func _update_ui() -> void:
	if stall_manager and stall_manager.is_open:
		status_label.text = "🟢 营业中"
		income_label.text = "今日收入: %d灵石" % stall_manager.daily_income
		open_btn.disabled = true
		close_btn.disabled = false
		
		# 显示库存信息
		var inv = PlayerData.inventory
		var inv_text = "库存:\n"
		for item in inv:
			inv_text += "  %s x%d\n" % [item.name, item.count]
		inventory_info.text = inv_text
	else:
		status_label.text = "🔴 未营业"
		open_btn.disabled = false
		close_btn.disabled = true


func _on_open_stall() -> void:
	stall_manager.open_stall()


func _on_close_stall() -> void:
	stall_manager.close_stall()
	customer_panel.hide()
	haggle_panel.hide()


func _on_stall_closed() -> void:
	is_trading = false
	customer_panel.hide()
	haggle_panel.hide()


func _on_customer_arrived(customer: Dictionary) -> void:
	is_trading = true
	var item = customer.want_item
	var tier_names = ["凡品", "灵品", "宝品", "仙品"]
	var element_icons = ["金", "木", "水", "火", "土"]
	var elem_str = element_icons[item.element] if item.element >= 0 else "无"
	
	customer_name.text = "👤 %s" % customer.name
	customer_mood.text = "状态: %s" % customer.mood
	
	# 商道提示：足够高时显示顾客的议价区间
	if PlayerData.shang_dao >= 30:
		var hint_min = customer.get("min_accept", customer.offer_price)
		var hint_max = customer.max_price
		customer_mood.text += "\n💼 商道眼光：可谈区间 %d~%d灵石" % [hint_min, hint_max]
	elif PlayerData.shang_dao >= 10:
		customer_mood.text += "\n💼 隐约感觉这位顾客还有议价空间"
	
	customer_request.text = "想要: [%s][%s] %s × %d" % [tier_names[item.tier], elem_str, item.name, customer.want_count]
	
	# 显示市场参考价和顾客出价
	var ref_total = customer.base_price  # 市场价总额
	customer_price.text = "出价: %d灵石 | 市场价: %d灵石（%d/个×%d）" % [customer.offer_price, ref_total, customer.unit_price, customer.want_count]
	
	customer_panel.show()
	haggle_panel.show()
	haggle_result.text = ""
	# 滑块从顾客出价到市场价×1.3（给博弈空间）
	haggle_slider.min_value = customer.offer_price
	haggle_slider.max_value = max(customer.max_price, int(ref_total * 1.3))
	haggle_slider.value = customer.offer_price
	_on_slider_changed(haggle_slider.value)


func _on_trade_completed(_item_id: String, _count: int, price: int) -> void:
	haggle_result.text = "✅ 成交！获得 %d灵石" % price
	is_trading = false
	# 2秒后隐藏结果
	await get_tree().create_timer(2.0).timeout
	customer_panel.hide()
	haggle_panel.hide()


func _on_trade_failed(_item_id: String, _count: int, reason: String) -> void:
	haggle_result.text = "❌ %s" % reason
	is_trading = false
	await get_tree().create_timer(1.5).timeout
	customer_panel.hide()
	haggle_panel.hide()


func _on_accept_price() -> void:
	if not is_trading:
		return
	var offer = int(haggle_slider.value)
	# 如果玩家接受自己的出价（等于直接接受顾客的offer）
	var result = stall_manager.start_haggle(offer)
	if result.result == "accept":
		_on_trade_completed("", 0, result.final_price)
	else:
		haggle_result.text = result.message


func _on_counter_offer() -> void:
	if not is_trading:
		return
	var offer = int(haggle_slider.value)
	var result = stall_manager.start_haggle(offer)
	
	if result.result == "accept":
		_on_trade_completed("", 0, result.final_price)
	elif result.result == "counter":
		haggle_result.text = result.message
		var c = result.customer
		customer_price.text = "出价: %d灵石 | 市场价: %d灵石（%d/个×%d）" % [c.offer_price, c.base_price, c.unit_price, c.want_count]
		haggle_slider.min_value = c.offer_price
		haggle_slider.value = c.offer_price
		_on_slider_changed(haggle_slider.value)
	elif result.result == "walk_away":
		_on_trade_failed("", 0, result.message)


func _on_reject_customer() -> void:
	stall_manager.dismiss_customer()
	customer_panel.hide()
	haggle_panel.hide()


func _on_slider_changed(value: float) -> void:
	haggle_value.text = "%d灵石" % int(value)
