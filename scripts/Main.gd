extends Node2D

var stall_scene: Node = null
var market_node: Node = null
var dev_console_node: Node = null
var furnace_node: Node = null
var inventory_node: Node = null


func _ready():
	set_process_mode(PROCESS_MODE_ALWAYS)
	
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
	
	# 启动昼夜循环
	DayCycle.start()
	
	print("B 集市  |  空格 摆摊  |  F 熔炉  |  E 背包  |  ~ 控制台")


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


# === 面板互斥检查（供 DayCycle 调用）===

func is_any_panel_open() -> bool:
	if market_node and market_node.get("is_open"):
		return true
	if furnace_node and furnace_node.get("is_open"):
		return true
	if inventory_node and inventory_node.get("is_open"):
		return true
	if _is_stall_open():
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
			print("DayCycle: 已强制收摊")


# === 输入处理 ===

func _input(event):
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		# 开发者控制台总是可用
		if event.keycode == KEY_QUOTELEFT:
			if dev_console_node and dev_console_node.has_method("toggle"):
				dev_console_node.toggle()
			get_viewport().set_input_as_handled()
			return
		
		# 空格：切换摆摊
		if event.keycode == KEY_SPACE:
			if stall_scene:
				var manager = stall_scene.get_node("StallManager")
				if manager:
					# 夜间不能摆摊
					if not DayCycle.can_stall(PlayerData.time_of_day) and not manager.is_open:
						print("夜间不能摆摊")
						get_viewport().set_input_as_handled()
						return
					if manager.is_open:
						manager.close_stall()
					else:
						manager.open_stall()
			get_viewport().set_input_as_handled()
			return
		
		# 如果已有面板打开，只允许关闭当前面板
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
			if handled:
				get_viewport().set_input_as_handled()
			return
		
		# 无面板打开时正常处理
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
					furnace_node.toggle()
				get_viewport().set_input_as_handled()
