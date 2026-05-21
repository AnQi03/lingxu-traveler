extends CanvasLayer

var is_open: bool = false
var market_ui: Panel = null
var item_grid: GridContainer = null


func _ready():
	_build_ui()
	market_ui.visible = false


func _build_ui():
	# 创建集市UI面板
	market_ui = Panel.new()
	market_ui.visible = false
	add_child(market_ui)
	
	# 锚点设置
	market_ui.position = Vector2(100, 40)
	market_ui.size = Vector2(1080, 600)
	
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.15, 0.25, 0.95)
	bg.size = market_ui.size
	bg.mouse_filter = 0
	market_ui.add_child(bg)
	
	# 标题栏
	var title_bar = HBoxContainer.new()
	title_bar.position = Vector2(0, 0)
	title_bar.size = Vector2(1080, 40)
	market_ui.add_child(title_bar)
	
	var title = Label.new()
	title.text = "  中央荒原 · 集市"
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_font_size_override("font_size", 20)
	title_bar.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = "  关闭 [M]  "
	close_btn.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(_on_close)
	title_bar.add_child(close_btn)
	
	# 滚动容器
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(20, 50)
	scroll.size = Vector2(1040, 530)
	market_ui.add_child(scroll)
	
	# 物品网格
	item_grid = GridContainer.new()
	item_grid.columns = 2
	item_grid.add_theme_constant_override("h_separation", 10)
	item_grid.add_theme_constant_override("v_separation", 10)
	item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(item_grid)


func _input(event):
	if event.is_action_pressed("open_market"):
		if is_open:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func open():
	is_open = true
	market_ui.visible = true
	_refresh_grid()
	get_tree().paused = true


func close():
	is_open = false
	market_ui.visible = false
	get_tree().paused = false


func _on_close():
	close()


func _refresh_grid():
	for child in item_grid.get_children():
		child.queue_free()
	
	var tier_names = ["凡品", "灵品", "宝品", "仙品"]
	var element_icons = ["金", "木", "水", "火", "土"]
	var items = MaterialData.get_market_items()
	
	for item_def in items:
		var inst = MaterialData.create_market_instance(item_def)
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
	if PlayerData.spend_stones(data.price):
		PlayerData.add_item({
			"id": data.id,
			"name": data.name,
			"tier": data.tier,
			"element": data.element,
			"price": data.price,
			"count": 1
		})
		print("购买了 %s，花费 %d 灵石" % [data.name, data.price])
		_refresh_grid()
	else:
		print("灵石不够！需要 %d 灵石" % data.price)
