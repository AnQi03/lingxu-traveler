extends CanvasLayer

var is_open: bool = false
var market_ui: Panel = null
var item_grid: GridContainer = null


func _ready():
	set_process_mode(PROCESS_MODE_WHEN_PAUSED)
	_build_ui()
	if is_instance_valid(market_ui):
		market_ui.visible = false


func _build_ui():
	market_ui = Panel.new()
	market_ui.visible = false
	add_child(market_ui)
	
	market_ui.position = Vector2(100, 40)
	market_ui.size = Vector2(1080, 600)
	
	var bg = ColorRect.new()
	bg.color = Color(0.14, 0.10, 0.06, 0.95)  # 暖暗底，仿羊皮纸暗面
	bg.size = market_ui.size
	bg.mouse_filter = 0
	market_ui.add_child(bg)
	
	# 像素面板边框纹理覆盖
	var border_tex = load("res://assets/img/ui/ui/panel_border.png")
	if border_tex:
		var border = TextureRect.new()
		border.texture = border_tex
		border.size = market_ui.size
		border.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		border.stretch_mode = TextureRect.STRETCH_SCALE
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		market_ui.add_child(border)
		market_ui.move_child(border, 1)  # 放在bg上面，内容下面
	
	var title_bar = HBoxContainer.new()
	title_bar.position = Vector2(0, 0)
	title_bar.size = Vector2(1080, 40)
	market_ui.add_child(title_bar)
	
	var title = Label.new()
	title.text = "  中央荒原 · 集市"
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))  # 琥珀金
	title.add_theme_font_size_override("font_size", 20)
	title_bar.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = "  关闭 [ESC]  "
	close_btn.add_theme_color_override("font_color", Color(0.8, 0.4, 0.3))  # 丹砂红
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(_on_close)
	title_bar.add_child(close_btn)
	
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(20, 50)
	scroll.size = Vector2(1040, 530)
	market_ui.add_child(scroll)
	
	item_grid = GridContainer.new()
	item_grid.columns = 2
	item_grid.add_theme_constant_override("h_separation", 10)
	item_grid.add_theme_constant_override("v_separation", 10)
	item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(item_grid)
	
	# 批量购买滑块
	var qty_label = Label.new()
	qty_label.name = "qty_label"
	qty_label.text = "数量: ×1"
	qty_label.position = Vector2(20, 50)
	qty_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	qty_label.add_theme_font_size_override("font_size", 13)
	market_ui.add_child(qty_label)
	
	var qty_slider = HSlider.new()
	qty_slider.name = "qty_slider"
	qty_slider.position = Vector2(120, 52)
	qty_slider.size = Vector2(200, 20)
	qty_slider.min_value = 1
	qty_slider.max_value = 20
	qty_slider.step = 1
	qty_slider.value = 1
	qty_slider.value_changed.connect(_on_qty_changed)
	market_ui.add_child(qty_slider)
	
	var qty_max_btn = Button.new()
	qty_max_btn.name = "qty_max_btn"
	qty_max_btn.text = "最大"
	qty_max_btn.position = Vector2(330, 50)
	qty_max_btn.size = Vector2(50, 24)
	qty_max_btn.add_theme_font_size_override("font_size", 11)
	qty_max_btn.pressed.connect(_on_qty_max)
	market_ui.add_child(qty_max_btn)
	
	# 调整 scroll 位置让出滑块空间
	scroll.position = Vector2(20, 80)
	scroll.size = Vector2(1040, 470)
	
	# ---- 灵石庄 ----
	var exchange_bg = ColorRect.new()
	exchange_bg.name = "exchange_bg"
	exchange_bg.position = Vector2(20, 555)
	exchange_bg.size = Vector2(1040, 35)
	exchange_bg.color = Color(0.08, 0.05, 0.15, 0.8)
	market_ui.add_child(exchange_bg)
	
	var exchange_label = Label.new()
	exchange_label.name = "exchange_label"
	exchange_label.position = Vector2(30, 557)
	exchange_label.size = Vector2(500, 30)
	exchange_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	exchange_label.add_theme_font_size_override("font_size", 12)
	market_ui.add_child(exchange_label)
	
	var btn_high = Button.new()
	btn_high.name = "exchange_high_btn"
	btn_high.text = "💎 上品→中品(1换100)"
	btn_high.position = Vector2(500, 557)
	btn_high.size = Vector2(170, 30)
	btn_high.add_theme_font_size_override("font_size", 11)
	btn_high.pressed.connect(_exchange_high)
	market_ui.add_child(btn_high)
	
	var btn_mid = Button.new()
	btn_mid.name = "exchange_mid_btn"
	btn_mid.text = "💰 中品→下品(1换100)"
	btn_mid.position = Vector2(675, 557)
	btn_mid.size = Vector2(170, 30)
	btn_mid.add_theme_font_size_override("font_size", 11)
	btn_mid.pressed.connect(_exchange_mid)
	market_ui.add_child(btn_mid)
	
	var btn_extreme = Button.new()
	btn_extreme.name = "exchange_extreme_btn"
	btn_extreme.text = "✨ 极品→上品(1换100)"
	btn_extreme.position = Vector2(850, 557)
	btn_extreme.size = Vector2(170, 30)
	btn_extreme.add_theme_font_size_override("font_size", 11)
	btn_extreme.pressed.connect(_exchange_extreme)
	market_ui.add_child(btn_extreme)
	
	var exchange_note = Label.new()
	exchange_note.position = Vector2(920, 560)
	exchange_note.size = Vector2(130, 25)
	exchange_note.text = "⚠ 仅高兑低"
	exchange_note.add_theme_color_override("font_color", Color(0.5, 0.4, 0.3))
	exchange_note.add_theme_font_size_override("font_size", 10)
	market_ui.add_child(exchange_note)


func toggle():
	if is_open:
		close()
	else:
		open()


func open():
	if not is_instance_valid(market_ui):
		_build_ui()
	if not is_instance_valid(market_ui):
		return
	
	is_open = true
	market_ui.visible = true
	market_ui.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(market_ui, "modulate:a", 1.0, 0.2)
	_refresh_grid()
	_refresh_exchange()
	get_tree().paused = true


func close():
	is_open = false
	if is_instance_valid(market_ui):
		var tw = create_tween()
		tw.tween_property(market_ui, "modulate:a", 0.0, 0.15)
		market_ui.visible = false
	get_tree().paused = false


func _on_close():
	close()


func _refresh_grid():
	for child in item_grid.get_children():
		child.queue_free()
	
	var tier_names = ["凡品", "灵品", "宝品", "仙品"]
	var element_icons = ["金", "木", "水", "火", "土"]
	var items = MaterialData.get_daily_market_items()
	
	# 世界事件：稀有灵材到货
	var rare_bonus = WorldEvents.get_rare_bonus(PlayerData.today_events)
	if rare_bonus > 0:
		var all_rare = []
		for it in MaterialData.get_market_items():
			if it.get("market_rare", false):
				all_rare.append(it)
		var rng = RandomNumberGenerator.new()
		rng.set_seed(PlayerData.game_day * 37)
		for _i in range(mini(rare_bonus, all_rare.size())):
			var idx = rng.randi() % all_rare.size()
			items.append(all_rare[idx])
	
	for item_def in items:
		var inst = MaterialData.create_market_instance(item_def)
		# 世界事件影响价格
		inst.price = WorldEvents.apply_market_event(inst.price, inst.element, PlayerData.today_events)
		var elem_str = element_icons[inst.element] if inst.element >= 0 else "无"
		
		var card = Panel.new()
		card.custom_minimum_size = Vector2(500, 80)
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_child(vbox)
		
		var name_label = Label.new()
		name_label.text = "[%s][%s] %s" % [tier_names[inst.tier], elem_str, inst.name]
		name_label.add_theme_color_override("font_color", Color.WHITE)
		vbox.add_child(name_label)
		
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var desc = Label.new()
		desc.text = inst.desc
		desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		desc.add_theme_font_size_override("font_size", 12)
		hbox.add_child(desc)
		
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(spacer)
		
		var price = Label.new()
		price.text = "%d灵石" % inst.price
		price.add_theme_color_override("font_color", Color(1, 0.87, 0.53))
		hbox.add_child(price)
		
		var buy_btn = Button.new()
		buy_btn.text = "购买"
		buy_btn.pressed.connect(_buy.bind(inst))
		hbox.add_child(buy_btn)
		
		vbox.add_child(hbox)
		item_grid.add_child(card)


func _buy(data):
	if data.is_empty():
		return
	
	var qty = 1
	var total_cost = data.price
	
	# 从滑块读取数量
	var slider = market_ui.find_child("qty_slider", true, false)
	if slider:
		qty = maxi(1, int(slider.value))
		var max_afford = maxi(1, int(float(PlayerData.get_total_stones()) / float(data.price)))
		qty = mini(qty, max_afford)
	
	total_cost = data.price * qty
	
	if PlayerData.spend_stones(total_cost):
		PlayerData.add_item({
			"id": data.id,
			"name": data.name,
			"tier": data.tier,
			"element": data.element,
			"price": data.price,
			"count": qty
		})
		_refresh_grid()
		_refresh_exchange()


func _on_qty_changed(value: float):
	var label = market_ui.find_child("qty_label", true, false)
	if label:
		label.text = "数量: ×%d" % int(value)

func _on_qty_max():
	var slider = market_ui.find_child("qty_slider", true, false)
	if slider:
		slider.value = slider.max_value


func _exchange_high():
	if PlayerData.exchange_do(2):
		PlayerData.emit_signal("stones_changed")
		_refresh_exchange()

func _exchange_mid():
	if PlayerData.exchange_do(1):
		PlayerData.emit_signal("stones_changed")
		_refresh_exchange()

func _exchange_extreme():
	if PlayerData.exchange_do(3):
		PlayerData.emit_signal("stones_changed")
		_refresh_exchange()

func _refresh_exchange():
	var label = market_ui.find_child("exchange_label", true, false)
	if label:
		label.text = "💎 灵石庄 | 极品:%d  上品:%d  中品:%d  下品:%d" % [
			PlayerData.extreme_spirit_stones, PlayerData.high_spirit_stones,
			PlayerData.mid_spirit_stones, PlayerData.spirit_stones
		]
	var btn_e = market_ui.find_child("exchange_extreme_btn", true, false)
	if btn_e:
		btn_e.disabled = (PlayerData.extreme_spirit_stones <= 0)
	var btn_h = market_ui.find_child("exchange_high_btn", true, false)
	if btn_h:
		btn_h.disabled = (PlayerData.high_spirit_stones <= 0)
	var btn_m = market_ui.find_child("exchange_mid_btn", true, false)
	if btn_m:
		btn_m.disabled = (PlayerData.mid_spirit_stones <= 0)

## 像素角标 — 已替换为面板纹理
