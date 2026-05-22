extends Node2D

var stall_scene: Node = null
var market_node: Node = null
var dev_console_node: Node = null
var furnace_node: Node = null
var inventory_node: Node = null
var day_summary_node: Node = null
var scene_bg: ColorRect = null
var atmosphere_label: Label = null


func _ready():
	set_process_mode(PROCESS_MODE_ALWAYS)
	
	_create_scene_background()
	
	print("灵墟旅商 loaded!")
	print("初始灵石: %d" % PlayerData.spirit_stones)
	print("时间: %s" % PlayerData.get_time_label())
	
	_create_market()
	_create_dev_console()
	_create_furnace()
	_create_inventory()
	
	var stall = preload("res://scenes/StallScene.tscn")
	if stall:
		stall_scene = stall.instantiate()
		add_child(stall_scene)
	
	DayCycle.start()
	DayCycle.night_falling.connect(_on_night_falling)
	DayCycle.period_changed.connect(_on_period_changed)
	
	var key_hint = "B 集市  |  空格 摆摊  |  E 背包  |  ~ 控制台  |  F5存档 F9读档"
	if PlayerData.is_furnace_unlocked():
		key_hint += "  |  F 熔炉"
	else:
		key_hint += "  |  F 熔炉(Day5解锁)"
	print(key_hint)

func _create_scene_background():
	scene_bg = ColorRect.new()
	scene_bg.name = "SceneBackground"
	scene_bg.size = Vector2(1152, 648)
	scene_bg.color = Color(0.12, 0.15, 0.25)  # 初始晨色
	scene_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scene_bg)
	move_child(scene_bg, 0)  # 放到最底层
	
	atmosphere_label = Label.new()
	atmosphere_label.name = "Atmosphere"
	atmosphere_label.position = Vector2(0, 590)
	atmosphere_label.size = Vector2(1152, 50)
	atmosphere_label.add_theme_font_size_override("font_size", 13)
	atmosphere_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	atmosphere_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(atmosphere_label)
	
	_update_background()

func _update_background():
	var t = PlayerData.time_of_day
	var period = DayCycle.get_period_name(t)
	
	var color: Color
	var atm_text: String
	
	if t >= 5.0 and t < 7.0:
		color = Color(0.15, 0.12, 0.28)  # 拂晓深蓝紫
		atm_text = "晨雾未散，灵墟集市的灯火刚刚亮起……"
	elif t >= 7.0 and t < 10.0:
		color = Color(0.25, 0.20, 0.15)  # 早晨暖棕
		atm_text = "晨光透过薄云洒在荒原上，修士们陆续出摊。"
	elif t >= 10.0 and t < 15.0:
		color = Color(0.30, 0.25, 0.15)  # 上午明亮
		atm_text = "灵墟集市热闹非凡——讨价还价声此起彼伏。"
	elif t >= 15.0 and t < 18.0:
		color = Color(0.28, 0.22, 0.12)  # 下午温暖
		atm_text = "午后阳光慵懒，几个老顾客在摊前慢悠悠地挑着灵材。"
	elif t >= 18.0 and t < 19.0:
		color = Color(0.22, 0.15, 0.18)  # 黄昏橙紫
		atm_text = "夕照将天空染成金紫色，集市里传来收摊的吆喝声。"
	elif t >= 19.0 and t < 21.0:
		color = Color(0.10, 0.06, 0.15)  # 入夜深紫
		atm_text = "夜幕低垂，远处偶尔传来炉火噼啪和修士夜话。"
	else:
		color = Color(0.05, 0.03, 0.12)  # 深夜暗紫
		atm_text = "夜深了。灵墟沉入寂静，只有天道的脉动在黑暗中流淌。"
	
	scene_bg.color = color
	atmosphere_label.text = atm_text
	atmosphere_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))


func _create_market():
	var market_layer = CanvasLayer.new()
	market_layer.name = "Market"
	market_layer.layer = 3
	market_layer.set_process_mode(PROCESS_MODE_WHEN_PAUSED)
	add_child(market_layer)
	
	var script = load("res://scripts/Market.gd")
	if script:
		market_layer.set_script(script)
	
	market_node = market_layer


func _create_dev_console():
	var console_layer = CanvasLayer.new()
	console_layer.name = "DevConsole"
	console_layer.layer = 10
	console_layer.set_process_mode(PROCESS_MODE_WHEN_PAUSED)
	add_child(console_layer)
	
	var script = load("res://scripts/DevConsole.gd")
	if script:
		console_layer.set_script(script)
	
	dev_console_node = console_layer


func _create_furnace():
	var furnace_layer = CanvasLayer.new()
	furnace_layer.name = "Furnace"
	furnace_layer.layer = 4
	furnace_layer.set_process_mode(PROCESS_MODE_WHEN_PAUSED)
	add_child(furnace_layer)
	
	var script = load("res://scripts/Furnace.gd")
	if script:
		furnace_layer.set_script(script)
	
	furnace_node = furnace_layer


func _create_inventory():
	var inv_layer = CanvasLayer.new()
	inv_layer.name = "Inventory"
	inv_layer.layer = 5
	inv_layer.set_process_mode(PROCESS_MODE_WHEN_PAUSED)
	add_child(inv_layer)
	
	var script = load("res://scripts/Inventory.gd")
	if script:
		inv_layer.set_script(script)
	
	inventory_node = inv_layer


func is_any_panel_open() -> bool:
	if day_summary_node and is_instance_valid(day_summary_node) and day_summary_node.get("is_showing"):
		return true
	if market_node and market_node.get("is_open"):
		return true
	if furnace_node and furnace_node.get("is_open"):
		return true
	if inventory_node and inventory_node.get("is_open"):
		return true
	return false


func _is_stall_open() -> bool:
	if not stall_scene:
		return false
	var manager = stall_scene.get_node("StallManager")
	return manager and manager.is_open


func force_close_stall():
	if stall_scene:
		var manager = stall_scene.get_node("StallManager")
		if manager and manager.is_open:
			manager.close_stall()


func _on_night_falling():
	force_close_stall()
	var summary = load("res://scripts/DaySummary.gd")
	if summary:
		var layer = CanvasLayer.new()
		layer.name = "DaySummary"
		layer.layer = 20
		layer.set_script(summary)
		add_child(layer)
		day_summary_node = layer
		if layer.has_method("show_summary"):
			layer.show_summary()

func _on_period_changed(_period: String):
	_update_background()


func _input(event):
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		# F5 存档 / F9 读档
		if event.keycode == KEY_F5:
			PlayerData.save_game()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_F9:
			if PlayerData.load_game():
				var hud = PlayerData.get_meta("hud")
				if hud and hud.has_method("show_toast"):
					hud.show_toast("📂 读档成功！第%d天" % PlayerData.game_day, Color(0.5, 1.0, 0.7), 3.0)
			get_viewport().set_input_as_handled()
			return
		
		if event.keycode == KEY_QUOTELEFT:
			if dev_console_node and dev_console_node.has_method("toggle"):
				dev_console_node.toggle()
			get_viewport().set_input_as_handled()
			return
		
		if day_summary_node and is_instance_valid(day_summary_node) and day_summary_node.get("is_showing"):
			get_viewport().set_input_as_handled()
			return
		
		if event.keycode == KEY_SPACE:
			if stall_scene:
				var manager = stall_scene.get_node("StallManager")
				if manager:
					if not DayCycle.can_stall(PlayerData.time_of_day) and not manager.is_open:
						get_viewport().set_input_as_handled()
						return
					if not manager.is_open and is_any_panel_open():
						get_viewport().set_input_as_handled()
						return
					if manager.is_open:
						manager.close_stall()
					else:
						manager.open_stall()
			get_viewport().set_input_as_handled()
			return
		
		if is_any_panel_open():
			var handled = false
			match event.keycode:
				KEY_B:
					if market_node and market_node.get("is_open"):
						market_node.toggle()
						handled = true
				KEY_F:
					if furnace_node and furnace_node.get("is_open"):
						furnace_node.toggle()
						handled = true
				KEY_E:
					if inventory_node and inventory_node.get("is_open"):
						inventory_node.toggle()
						handled = true
			match event.keycode:
				KEY_B, KEY_E, KEY_F:
					if not handled:
						handled = true
			if handled:
				get_viewport().set_input_as_handled()
			return
		
		if _is_stall_open():
			match event.keycode:
				KEY_B, KEY_F:
					get_viewport().set_input_as_handled()
				KEY_E:
					# 摆摊时可打开背包查看库存
					if inventory_node and inventory_node.has_method("toggle"):
						inventory_node.toggle()
					get_viewport().set_input_as_handled()
			return
		
		match event.keycode:
			KEY_B:
				if market_node and market_node.has_method("toggle"):
					market_node.toggle()
				get_viewport().set_input_as_handled()
			KEY_E:
				if inventory_node and inventory_node.has_method("toggle"):
					inventory_node.toggle()
				get_viewport().set_input_as_handled()
			KEY_F:
				if furnace_node and furnace_node.has_method("toggle"):
					if not PlayerData.is_furnace_unlocked():
						print("熔炉 Day5解锁")
						get_viewport().set_input_as_handled()
						return
					furnace_node.toggle()
				get_viewport().set_input_as_handled()
