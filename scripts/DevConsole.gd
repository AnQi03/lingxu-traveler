extends CanvasLayer

var is_open: bool = false
var dev_panel: Panel = null


func _ready():
	set_process_mode(PROCESS_MODE_WHEN_PAUSED)
	_build_ui()
	if is_instance_valid(dev_panel):
		dev_panel.visible = false


func _build_ui():
	dev_panel = Panel.new()
	dev_panel.visible = false
	add_child(dev_panel)
	
	dev_panel.position = Vector2(100, 30)
	dev_panel.size = Vector2(1100, 640)
	
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.15, 0.97)
	bg.size = dev_panel.size
	bg.mouse_filter = 0
	dev_panel.add_child(bg)
	
	var title_bar = HBoxContainer.new()
	title_bar.position = Vector2(0, 0)
	title_bar.size = Vector2(1100, 36)
	dev_panel.add_child(title_bar)
	
	var title = Label.new()
	title.text = "  🧪 开发者控制台"
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	title.add_theme_font_size_override("font_size", 22)
	title_bar.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = "  关闭 [~]  "
	close_btn.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(_on_close)
	title_bar.add_child(close_btn)
	
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(15, 45)
	scroll.size = Vector2(1070, 575)
	dev_panel.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)
	
	# 灵石区块
	_add_section_header(vbox, "💎 灵石修改")
	_add_field_row(vbox, "下品灵石", "_set_spirit_stones", 30)
	_add_field_row(vbox, "中品灵石", "_set_mid_stones", 0)
	_add_field_row(vbox, "上品灵石", "_set_high_stones", 0)
	
	# 时间区块
	_add_section_header(vbox, "⏰ 时间修改")
	_add_field_row(vbox, "当前天数", "_set_day", 1)
	_add_field_row(vbox, "当前时辰(0-23)", "_set_hour", 6)
	
	# 推进时间按钮
	var advance_hbox = HBoxContainer.new()
	advance_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var advance_label = Label.new()
	advance_label.text = "时间推进:"
	advance_label.add_theme_color_override("font_color", Color.WHITE)
	advance_label.add_theme_font_size_override("font_size", 14)
	advance_label.custom_minimum_size = Vector2(120, 0)
	advance_hbox.add_child(advance_label)
	
	var advance_1h = Button.new()
	advance_1h.text = "+1时辰"
	advance_1h.pressed.connect(_advance_time.bind(2.0))
	advance_hbox.add_child(advance_1h)
	
	var advance_6h = Button.new()
	advance_6h.text = "+6时辰"
	advance_6h.pressed.connect(_advance_time.bind(6.0))
	advance_hbox.add_child(advance_6h)
	
	var advance_1d = Button.new()
	advance_1d.text = "+1天"
	advance_1d.pressed.connect(_advance_time.bind(24.0))
	advance_hbox.add_child(advance_1d)
	
	var advance_7d = Button.new()
	advance_7d.text = "+7天"
	advance_7d.pressed.connect(_advance_time.bind(168.0))
	advance_hbox.add_child(advance_7d)
	
	vbox.add_child(advance_hbox)
	
	# 灵材区块
	_add_section_header(vbox, "🧪 添加灵材到背包")
	
	var item_hbox = HBoxContainer.new()
	item_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var item_label = Label.new()
	item_label.text = "选择灵材:"
	item_label.add_theme_color_override("font_color", Color.WHITE)
	item_label.add_theme_font_size_override("font_size", 14)
	item_label.custom_minimum_size = Vector2(120, 0)
	item_hbox.add_child(item_label)
	
	var item_option = OptionButton.new()
	item_option.name = "item_selector"
	item_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_option.custom_minimum_size = Vector2(350, 0)
	
	var tier_names = ["凡", "灵", "宝", "仙"]
	var element_icons = ["金", "木", "水", "火", "土"]
	for item_def in MaterialData.get_market_items():
		var tier_str = tier_names[item_def.tier] if item_def.tier < tier_names.size() else "?"
		var elem_str = element_icons[item_def.element] if item_def.element >= 0 and item_def.element < element_icons.size() else "?"
		item_option.add_item("[%s][%s] %s (%d灵石)" % [tier_str, elem_str, item_def.name, item_def.base_price])
		item_option.set_item_metadata(item_option.item_count - 1, item_def)
	
	item_hbox.add_child(item_option)
	
	var count_spin = SpinBox.new()
	count_spin.name = "item_count"
	count_spin.min_value = 1
	count_spin.max_value = 999
	count_spin.value = 1
	count_spin.custom_minimum_size = Vector2(80, 0)
	item_hbox.add_child(count_spin)
	
	var add_item_btn = Button.new()
	add_item_btn.text = "添加"
	add_item_btn.pressed.connect(_add_item_from_option.bind(item_option, count_spin))
	item_hbox.add_child(add_item_btn)
	
	vbox.add_child(item_hbox)
	
	# 三道区块
	_add_section_header(vbox, "📊 三道路径修改")
	_add_field_row(vbox, "商道", "_set_shang_dao", 0)
	_add_field_row(vbox, "天道", "_set_tian_dao", 0)
	_add_field_row(vbox, "人心", "_set_ren_xin", 0)
	
	# 熔炼区块
	_add_section_header(vbox, "🔥 熔炼修改")
	_add_field_row(vbox, "今日熔炼次数", "_set_refine_count", 0)
	
	# 快捷预设
	_add_section_header(vbox, "⚡ 快捷预设")
	
	var preset_hbox = HBoxContainer.new()
	preset_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var btn1 = Button.new()
	btn1.text = "开局默认"
	btn1.pressed.connect(_preset_default)
	preset_hbox.add_child(btn1)
	
	var btn2 = Button.new()
	btn2.text = "测试摆摊 (5000灵石+物品)"
	btn2.pressed.connect(_preset_stall_test)
	preset_hbox.add_child(btn2)
	
	var btn3 = Button.new()
	btn3.text = "测试熔炉 (大量灵材)"
	btn3.pressed.connect(_preset_furnace_test)
	preset_hbox.add_child(btn3)
	
	var btn4 = Button.new()
	btn4.text = "满属性测试 (9999灵材)"
	btn4.pressed.connect(_preset_full_test)
	preset_hbox.add_child(btn4)
	
	vbox.add_child(preset_hbox)
	
	# 状态显示
	_add_section_header(vbox, "📋 当前状态")
	
	var status_label = Label.new()
	status_label.name = "status_label"
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(status_label)
	
	_refresh_status()


func _add_section_header(parent: VBoxContainer, title: String):
	var label = Label.new()
	label.text = title
	label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	label.add_theme_font_size_override("font_size", 16)
	parent.add_child(label)


func _add_field_row(parent: VBoxContainer, label_text: String, setter_method: String, default_value: int):
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var label = Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 14)
	label.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(label)
	
	var line_edit = LineEdit.new()
	line_edit.name = "input_" + setter_method
	line_edit.text = str(default_value)
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(line_edit)
	
	var set_btn = Button.new()
	set_btn.text = "设置"
	set_btn.pressed.connect(_make_setter(setter_method, line_edit))
	hbox.add_child(set_btn)
	
	parent.add_child(hbox)


func _make_setter(method: String, line_edit: LineEdit) -> Callable:
	return func():
		var val = int(line_edit.text)
		call(method, val)
		_refresh_status()


func _set_spirit_stones(val: int):
	PlayerData.spirit_stones = max(0, val)

func _set_mid_stones(val: int):
	PlayerData.mid_spirit_stones = max(0, val)

func _set_high_stones(val: int):
	PlayerData.high_spirit_stones = max(0, val)

func _set_day(val: int):
	PlayerData.game_day = max(1, val)

func _set_hour(val: int):
	PlayerData.time_of_day = float(clampi(val, 0, 23))

func _set_shang_dao(val: int):
	PlayerData.shang_dao = max(0, val)

func _set_tian_dao(val: int):
	PlayerData.tian_dao = max(0, val)

func _set_ren_xin(val: int):
	PlayerData.ren_xin = max(0, val)

func _set_refine_count(val: int):
	PlayerData.daily_refine_count = max(0, val)


# 推进时间（会自动重置熔炼次数）
func _advance_time(hours: float):
	PlayerData.advance_time(hours)
	_refresh_status()


func _add_item_from_option(option_btn: OptionButton, spin: SpinBox):
	var idx = option_btn.selected
	if idx < 0:
		return
	var item_def = option_btn.get_item_metadata(idx)
	if item_def.is_empty():
		return
	var count = int(spin.value)
	
	PlayerData.add_item({
		"id": item_def.id,
		"name": item_def.name,
		"tier": item_def.tier,
		"element": item_def.element,
		"price": item_def.base_price,
		"count": count
	})
	_refresh_status()


func _preset_default():
	PlayerData.spirit_stones = 30
	PlayerData.mid_spirit_stones = 0
	PlayerData.high_spirit_stones = 0
	PlayerData.inventory.clear()
	PlayerData.game_day = 1
	PlayerData.time_of_day = 6.0
	PlayerData.shang_dao = 0
	PlayerData.tian_dao = 0
	PlayerData.ren_xin = 0
	PlayerData.daily_refine_count = 0
	_refresh_status()


func _preset_stall_test():
	PlayerData.spirit_stones = 5000
	PlayerData.mid_spirit_stones = 0
	PlayerData.high_spirit_stones = 0
	PlayerData.inventory.clear()
	
	for item_def in MaterialData.get_market_items():
		PlayerData.add_item({
			"id": item_def.id,
			"name": item_def.name,
			"tier": item_def.tier,
			"element": item_def.element,
			"price": item_def.base_price,
			"count": 10
		})
	_refresh_status()


func _preset_furnace_test():
	PlayerData.spirit_stones = 500
	PlayerData.mid_spirit_stones = 5
	PlayerData.high_spirit_stones = 2
	PlayerData.inventory.clear()
	
	for item_def in MaterialData.get_market_items():
		PlayerData.add_item({
			"id": item_def.id,
			"name": item_def.name,
			"tier": item_def.tier,
			"element": item_def.element,
			"price": item_def.base_price,
			"count": 20
		})
	_refresh_status()


func _preset_full_test():
	PlayerData.spirit_stones = 9999
	PlayerData.mid_spirit_stones = 99
	PlayerData.high_spirit_stones = 99
	PlayerData.inventory.clear()
	
	for item_def in MaterialData.get_market_items():
		for _i in range(50):
			PlayerData.add_item({
				"id": item_def.id,
				"name": item_def.name,
				"tier": item_def.tier,
				"element": item_def.element,
				"price": item_def.base_price,
				"count": 200
			})
	PlayerData.shang_dao = 999
	PlayerData.tian_dao = 999
	PlayerData.ren_xin = 999
	_refresh_status()


func toggle():
	if is_open:
		close()
	else:
		open()


func open():
	if not is_instance_valid(dev_panel):
		_build_ui()
	if not is_instance_valid(dev_panel):
		return
	
	is_open = true
	dev_panel.visible = true
	_refresh_status()
	get_tree().paused = true


func close():
	is_open = false
	if is_instance_valid(dev_panel):
		dev_panel.visible = false
	get_tree().paused = false


func _on_close():
	close()


func _refresh_status():
	var status_node = find_child("status_label", true, false)
	if not status_node:
		return
	
	var inv_count = 0
	var total_items = 0
	for item in PlayerData.inventory:
		inv_count += 1
		total_items += item.get("count", 1)
	
	var text = "灵石: %d 下品 + %d 中品 + %d 上品 | 天数: %d · %d时 | 库存: %d 种 (%d件) | 商道:%d 天道:%d 人心:%d | 熔炼:%d/%d" % [
		PlayerData.spirit_stones,
		PlayerData.mid_spirit_stones,
		PlayerData.high_spirit_stones,
		PlayerData.game_day,
		int(PlayerData.time_of_day),
		inv_count,
		total_items,
		PlayerData.shang_dao,
		PlayerData.tian_dao,
		PlayerData.ren_xin,
		PlayerData.daily_refine_count,
		PlayerData.MAX_DAILY_REFINE
	]
	
	status_node.text = text
