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
	stall_manager.order_available.connect(_on_order_available)
	
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
	SoundManager.sfx_customer_arrive()
	is_trading = true
	var item = customer.want_item
	var tier_names = ["凡品", "灵品", "宝品", "仙品"]
	var element_icons = ["金", "木", "水", "火", "土"]
	var elem_str = element_icons[item.element] if item.element >= 0 else "无"
	
	customer_name.text = "👤 %s" % customer.name
	customer_mood.text = "状态: 😐  %s" % customer.mood
	
	# 显示顾客对话（有名字的顾客优先用对话池）
	var greeting = ""
	if customer.name in ["石老", "青儿", "霍老板", "冷面客", "金娘子"]:
		greeting = CustomerGenerator.get_customer_greeting(customer.name, customer)
	elif randf() < 0.3:
		var pool = ["来看看。", "今天有什么好货？", "随便看看。", "这个怎么卖？"]
		greeting = pool[randi() % pool.size()]
	
	# 需求文本：先清再写
	customer_request.text = "想要: [%s][%s] %s × %d" % [tier_names[item.tier], elem_str, item.name, customer.want_count]
	if greeting != "":
		customer_request.text += "\n💬 %s" % greeting
	
	# 商道提示：越高越能感知顾客底线（不追加，直接替换mood行）
	
	# 显示市场参考价和顾客出价
	var ref_total = customer.base_price  # 市场价总额
	var price_text = "出价: %d灵石 | 市场价: %d灵石（%d/个×%d）" % [customer.offer_price, ref_total, customer.unit_price, customer.want_count]
	if customer.offer_price < ref_total:
		price_text += "\n⚠️ 出价低于市场价，需要谈判抬价！"
	customer_price.text = price_text
	
	customer_panel.show()
	haggle_panel.show()
	haggle_result.text = ""
	
	# 顾客到达弹出
	customer_panel.scale = Vector2(0.8, 0.8)
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(customer_panel, "scale", Vector2(1.0, 1.0), 0.25)
	# 滑块从顾客出价到市场价×1.3（给博弈空间）
	haggle_slider.min_value = customer.offer_price
	haggle_slider.max_value = max(customer.max_price, int(ref_total * 1.6))
	haggle_slider.value = customer.offer_price
	_on_slider_changed(haggle_slider.value)


func _on_trade_completed(_item_id: String, _count: int, price: int) -> void:
	SoundManager.sfx_deal()
	var streak = PlayerData.trade_streak
	var bonus_text = ""
	if streak >= 7:
		bonus_text = "\n💎 财源滚滚！连续成交 %d 笔！" % streak
	elif streak >= 5:
		bonus_text = "\n✨ 生意兴隆！连续成交 %d 笔！" % streak
	elif streak >= 3:
		bonus_text = "\n🔥 手感正热！连续成交 %d 笔！" % streak
	
	haggle_result.text = "✅ 成交！获得 %d灵石%s" % [price, bonus_text]
	haggle_result.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	is_trading = false
	
	# 成交特效 — 面板闪绿 + 数字弹跳 + 灵石粒子
	_flash_panel_green(haggle_panel)
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(haggle_result, "scale", Vector2(1.3, 1.3), 0.12)
	tw.tween_property(haggle_result, "scale", Vector2(1.0, 1.0), 0.22)
	_spawn_coin_particles(price)
	
	await get_tree().create_timer(2.5).timeout
	customer_panel.hide()
	haggle_panel.hide()
	
	# 内心声音
	var hud = PlayerData.get_meta("hud")
	InnerVoice.maybe_speak("haggle_success", hud)


## 灵石入账粒子特效 — 金色粒子从成交面板飞出
func _spawn_coin_particles(amount: int) -> void:
	var count: int
	if amount > 1000:
		count = 15
	elif amount > 500:
		count = 12
	elif amount > 100:
		count = 8
	else:
		count = 5
	
	var center = haggle_result.position + haggle_result.size / 2
	for i in range(count):
		var p = ColorRect.new()
		p.size = Vector2(8, 8)
		p.position = center - Vector2(4, 4)
		p.color = Color(1.0, 0.85, 0.2, 0.95)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		haggle_panel.add_child(p)
		
		var angle = randf_range(0, TAU)
		var dist = randf_range(30, 80)
		var target = center + Vector2(cos(angle), sin(angle)) * dist
		var tw2 = create_tween().set_parallel(true)
		tw2.tween_property(p, "position", target, randf_range(0.3, 0.6))
		tw2.tween_property(p, "color:a", 0.0, randf_range(0.3, 0.6))
		tw2.chain().tween_callback(p.queue_free)


## 面板闪绿效果 — 成交瞬间的绿色闪光
func _flash_panel_green(panel: Panel) -> void:
	var flash = ColorRect.new()
	flash.size = panel.size
	flash.position = Vector2.ZERO
	flash.color = Color(0.0, 0.9, 0.0, 0.2)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(flash)
	var tw = create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.2)
	tw.chain().tween_callback(flash.queue_free)


func _on_trade_failed(_item_id: String, _count: int, reason: String) -> void:
	var fail_text = "❌ %s" % reason
	# 给点鼓励——不是所有失败都是坏事
	if "走了" in reason or "离开" in reason:
		fail_text += "\n💡 下次试试降低要价？"
	elif "激怒" in reason or "生气" in reason:
		fail_text += "\n💡 这个顾客对价格很敏感，下次注意"
	
	haggle_result.text = fail_text
	haggle_result.add_theme_color_override("font_color", Color(0.9, 0.35, 0.25))
	is_trading = false
	await get_tree().create_timer(2.0).timeout
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
	var val = int(value)
	var risk_text = ""
	var risk_color = Color(0.5, 0.5, 0.5)
	var expression = "😐"
	
	if stall_manager and stall_manager.current_customer:
		var c = stall_manager.current_customer
		var max_p = c.max_price
		var offer_p = c.offer_price
		var pers = c.get("personality", 1)
		
		# 性格修正系数：敏感型阈值更低，大方型阈值更高
		var mod = _personality_threshold_mod(pers)
		
		# 价格区间判定 + 表情映射
		if val <= offer_p:
			risk_text = "🟢 顾客肯定接受"
			risk_color = Color(0.3, 0.9, 0.3)
			expression = "😊"
		elif val <= max_p * (0.45 + mod):
			risk_text = "🟢 这个价格很安全"
			risk_color = Color(0.3, 0.85, 0.3)
			expression = "🙂"
		elif val <= max_p * (0.7 + mod):
			risk_text = "🟡 很大概率成交"
			risk_color = Color(0.8, 0.8, 0.3)
			expression = "🤔"
		elif val <= max_p * (0.9 + mod):
			risk_text = "🟠 对方可能犹豫"
			risk_color = Color(0.9, 0.6, 0.2)
			expression = "😰"
		elif val <= max_p:
			risk_text = "🟠 接近对方底线了！"
			risk_color = Color(0.95, 0.45, 0.15)
			expression = "😣"
		else:
			risk_text = "🔴 对方很可能拒绝！"
			risk_color = Color(0.9, 0.2, 0.2)
			expression = "😡"
		
		# 商道提示：级别越高越准确
		if PlayerData.shang_dao >= 50:
			risk_text += " 💼「他的底线大约在%d灵石左右」" % max_p
		elif PlayerData.shang_dao >= 25:
			risk_text += " 💼「大概还能再加点...」"
		
		# 更新顾客表情显示
		customer_mood.text = "状态: %s  %s" % [expression, c.mood]
	
	haggle_value.text = "%d灵石 %s" % [val, risk_text]
	haggle_value.add_theme_color_override("font_color", risk_color)

## 性格→阈值修正（负数=更敏感，正数=更大方）
func _personality_threshold_mod(personality: int) -> float:
	match personality:
		0: return 0.15   # 爽直 — 不太讲价
		4: return -0.15  # 吝啬 — 对价格极敏感
		5: return 0.20   # 慷慨 — 大方
		2: return -0.08  # 急躁 — 容易生气
		3: return 0.12   # 耐心 — 慢慢磨
		6: return -0.05  # 多疑 — 略带怀疑
		7: return 0.10   # 轻信 — 容易开心
		_: return 0.0    # 精明(1) — 标准


func _on_order_available(order: Dictionary):
	var element_names = ["金", "木", "水", "火", "土"]
	var tier_names = ["凡品", "灵品"]
	var elem = element_names[order.item_element]
	var tier = tier_names[order.item_tier]
	customer_request.text += "\n\n📜 %s下单: %d个[%s][%s]灵材, %d天后交货\n报酬: %d灵石  [接受订单?]"
	var decline = Button.new()
	decline.text = "拒绝"
	var accept = Button.new()
	accept.text = "接受"
	accept.pressed.connect(func():
		PlayerData.add_order(order.customer_name, order.item_tier, order.item_element, order.count, order.days, order.reward)
		customer_request.text += "\n📜 已接受%s的订单!" % order.customer_name
		accept.queue_free()
		decline.queue_free()
	)
	decline.pressed.connect(func():
		accept.queue_free()
		decline.queue_free()
	)
	customer_panel.add_child(accept)
	customer_panel.add_child(decline)
