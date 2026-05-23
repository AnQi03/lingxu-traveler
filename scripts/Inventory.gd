extends CanvasLayer

var is_open: bool = false
var inv_panel: Panel = null
var item_grid: GridContainer = null
var tier_names = ["凡品", "灵品", "宝品", "仙品"]
var element_icons = ["金", "木", "水", "火", "土"]
var element_colors = [
	Color(1, 0.84, 0.2),
	Color(0.3, 0.8, 0.3),
	Color(0.3, 0.6, 1.0),
	Color(1, 0.4, 0.2),
	Color(0.6, 0.4, 0.2)
]
var filter_tier: int = -1


func _ready():
	set_process_mode(PROCESS_MODE_WHEN_PAUSED)
	_build_ui()
	if is_instance_valid(inv_panel):
		inv_panel.visible = false


func _build_ui():
	inv_panel = Panel.new()
	inv_panel.visible = false
	add_child(inv_panel)
	
	inv_panel.position = Vector2(180, 45)
	inv_panel.size = Vector2(1575, 960)
	
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.1, 0.15, 0.97)
	bg.size = inv_panel.size
	bg.mouse_filter = 0
	inv_panel.add_child(bg)
	
	var title_bar = HBoxContainer.new()
	title_bar.position = Vector2(0, 0)
	title_bar.size = Vector2(1575, 54)
	inv_panel.add_child(title_bar)
	
	var title = Label.new()
	title.text = "  🎒 背包"
	title.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	title.add_theme_font_size_override("font_size", 22)
	title_bar.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = "  关闭 [ESC]  "
	close_btn.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(_on_close)
	title_bar.add_child(close_btn)
	
	var filter_hbox = HBoxContainer.new()
	filter_hbox.position = Vector2(22, 63)
	filter_hbox.size = Vector2(1530, 45)
	inv_panel.add_child(filter_hbox)
	
	var filter_label = Label.new()
	filter_label.text = "筛选品阶:"
	filter_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	filter_label.add_theme_font_size_override("font_size", 14)
	filter_label.custom_minimum_size = Vector2(120, 0)
	filter_hbox.add_child(filter_label)
	
	var all_btn = Button.new()
	all_btn.text = "全部"
	all_btn.pressed.connect(_set_filter.bind(-1))
	filter_hbox.add_child(all_btn)
	
	for ti in range(tier_names.size()):
		var btn = Button.new()
		btn.text = tier_names[ti]
		btn.pressed.connect(_set_filter.bind(ti))
		filter_hbox.add_child(btn)
	
	var count_label = Label.new()
	count_label.name = "count_label"
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	count_label.add_theme_font_size_override("font_size", 12)
	filter_hbox.add_child(count_label)
	
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(22, 117)
	scroll.size = Vector2(1530, 832)
	inv_panel.add_child(scroll)
	
	item_grid = GridContainer.new()
	item_grid.name = "item_grid"
	item_grid.columns = 3
	item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_grid.add_theme_constant_override("h_separation", 8)
	item_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(item_grid)


func _set_filter(tier: int):
	filter_tier = tier
	_refresh_items()


func toggle():
	if is_open:
		close()
	else:
		open()


func open():
	if not is_instance_valid(inv_panel):
		_build_ui()
	if not is_instance_valid(inv_panel):
		return
	
	is_open = true
	inv_panel.visible = true
	_refresh_items()
	get_tree().paused = true


func close():
	is_open = false
	if is_instance_valid(inv_panel):
		inv_panel.visible = false
	get_tree().paused = false


func _on_close():
	close()


func _refresh_items():
	for child in item_grid.get_children():
		child.queue_free()
	
	var total_kinds = 0
	var total_count = 0
	var tier_counts = [0, 0, 0, 0]
	
	for item in PlayerData.inventory:
		var c = item.get("count", 1)
		total_kinds += 1
		total_count += c
		if item.tier >= 0 and item.tier < 4:
			tier_counts[item.tier] += c
	
	var count_label = find_child("count_label", true, false)
	if count_label:
		count_label.text = "共 %d 种 / %d 件  [凡:%d 灵:%d 宝:%d 仙:%d]" % [total_kinds, total_count, tier_counts[0], tier_counts[1], tier_counts[2], tier_counts[3]]
	
	var display_items = []
	for item in PlayerData.inventory:
		if filter_tier < 0 or item.tier == filter_tier:
			display_items.append(item)
	
	if display_items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "   背包为空（或没有符合条件的灵材）"
		empty_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		empty_label.add_theme_font_size_override("font_size", 14)
		item_grid.add_child(empty_label)
		return
	
	for item in display_items:
		var tier_str = tier_names[item.tier] if item.tier < tier_names.size() else "?"
		var elem_str = element_icons[item.element] if item.element >= 0 and item.element < element_icons.size() else "?"
		var elem_col = element_colors[item.element] if item.element >= 0 and item.element < element_colors.size() else Color.WHITE
		
		var card_color = Color(0.12, 0.12, 0.18, 0.9)
		match item.tier:
			0: card_color = Color(0.12, 0.12, 0.18, 0.9)
			1: card_color = Color(0.12, 0.18, 0.25, 0.9)
			2: card_color = Color(0.2, 0.15, 0.08, 0.9)
			3: card_color = Color(0.2, 0.08, 0.2, 0.9)
		
		var card = ColorRect.new()
		card.color = card_color
		card.custom_minimum_size = Vector2(495, 105)
		
		var elem_bar = ColorRect.new()
		elem_bar.color = elem_col
		elem_bar.size = Vector2(6, 105)
		card.add_child(elem_bar)
		
		var name_label = Label.new()
		name_label.text = "[%s] %s" % [tier_str, item.name]
		name_label.position = Vector2(18, 9)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.add_theme_font_size_override("font_size", 15)
		card.add_child(name_label)
		
		var info_label = Label.new()
		info_label.text = "五行: %s  |  数量: ×%d" % [elem_str, item.get("count", 1)]
		info_label.position = Vector2(18, 42)
		info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		info_label.add_theme_font_size_override("font_size", 12)
		card.add_child(info_label)
		
		var price_label = Label.new()
		price_label.text = "%d灵石/个" % item.get("price", 0)
		price_label.position = Vector2(18, 69)
		price_label.add_theme_color_override("font_color", Color(1, 0.87, 0.53))
		price_label.add_theme_font_size_override("font_size", 12)
		card.add_child(price_label)
		
		if item.has("origin") and item.origin != "":
			var origin_label = Label.new()
			origin_label.text = "来源: %s" % item.origin
			origin_label.position = Vector2(300, 69)
			origin_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			origin_label.add_theme_font_size_override("font_size", 11)
			card.add_child(origin_label)
		
		item_grid.add_child(card)
