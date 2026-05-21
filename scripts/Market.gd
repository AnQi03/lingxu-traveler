extends CanvasLayer

var is_open: bool = false

@onready var market_ui: Panel = $MarketUI
@onready var item_grid: GridContainer = $MarketUI/ItemListContainer/ItemGrid
@onready var close_btn: Button = $MarketUI/TitleBar/CloseButton


func _ready():
	visible = true
	market_ui.visible = false
	close_btn.pressed.connect(_on_close)


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
