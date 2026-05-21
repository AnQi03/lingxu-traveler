# ============================================================
# 集市场景 - Market.gd
# 按M打开/关闭，显示灵材列表，可购买
# ============================================================
extends CanvasLayer

var is_open: bool = false

@onready var market_ui: Panel = $MarketUI
@onready var item_grid: GridContainer = $MarketUI/ItemListContainer/ItemGrid
@onready var close_btn: Button = $MarketUI/TitleBar/CloseButton


func _ready() -> void:
	visible = true
	market_ui.visible = false
	close_btn.pressed.connect(_on_close)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_market"):
		if is_open:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func open() -> void:
	is_open = true
	market_ui.visible = true
	_refresh_grid()
	get_tree().paused = true


func close() -> void:
	is_open = false
	market_ui.visible = false
	get_tree().paused = false


func _on_close() -> void:
	close()


func _refresh_grid() -> void:
	# 清除旧的商品格
	for child in item_grid.get_children():
		child.queue_free()
	
	var items = MaterialData.get_market_items()
	for item_def in items:
		var inst = MaterialData.create_market_instance(item_def)
		_create_card(inst)


func _create_card(data: Dictionary) -> void:
	var tier_names = ["凡品", "灵品", "宝品", "仙品"]
	var element_icons = ["金", "木", "水", "火", "土"]
	var elem_str = element_icons[data.element] if data.element >= 0 else "无"
	
	var card = Panel.new()
	card.custom_minimum_size = Vector2(500, 80)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(vbox)
	
	# 名称行
	var name_label = Label.new()
	name_label.text = "[%s][%s] %s" % [tier_names[data.tier], elem_str, data.name]
	name_label.theme_override_colors/font_color = Color.WHITE
	vbox.add_child(name_label)
	
	# 信息行
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var desc = Label.new()
	desc.text = data.desc
	desc.theme_override_colors/font_color = Color(0.7, 0.7, 0.7, 1)
	desc.theme_override_font_sizes/font_size = 12
	hbox.add_child(desc)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	var price = Label.new()
	price.text = "%d灵石" % data.price
	price.theme_override_colors/font_color = Color(1, 0.87, 0.53, 1)
	hbox.add_child(price)
	
	var buy_btn = Button.new()
	buy_btn.text = "购买"
	buy_btn.pressed.connect(func():
		_buy(data)
	)
	hbox.add_child(buy_btn)
	
	vbox.add_child(hbox)
	item_grid.add_child(card)


func _buy(data: Dictionary) -> void:
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
