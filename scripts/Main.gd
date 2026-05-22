extends Node2D

var stall_scene: Node = null
var market_node: Node = null
var dev_console_node: Node = null
var furnace_node: Node = null
var inventory_node: Node = null


func _ready():
	set_process_mode(PROCESS_MODE_ALWAYS)
	
	_setup_actions()
	
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
	
	print("M 集市  |  S 摆摊  |  F 熔炉  |  I 背包  |  ~ 控制台")


func _setup_actions():
	if not InputMap.has_action("open_market"):
		InputMap.add_action("open_market")
		var ev = InputEventKey.new()
		ev.keycode = KEY_M
		InputMap.action_add_event("open_market", ev)
	if not InputMap.has_action("stall_action"):
		InputMap.add_action("stall_action")
		var ev = InputEventKey.new()
		ev.keycode = KEY_S
		InputMap.action_add_event("stall_action", ev)
	if not InputMap.has_action("open_furnace"):
		InputMap.add_action("open_furnace")
		var ev = InputEventKey.new()
		ev.keycode = KEY_F
		InputMap.action_add_event("open_furnace", ev)
	if not InputMap.has_action("open_inventory"):
		InputMap.add_action("open_inventory")
		var ev = InputEventKey.new()
		ev.keycode = KEY_I
		InputMap.action_add_event("open_inventory", ev)


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
	inv_layer.layer = 2
	inv_layer.set_process_mode(PROCESS_MODE_WHEN_PAUSED)
	add_child(inv_layer)
	
	var script = load("res://scripts/Inventory.gd")
	if script:
		inv_layer.set_script(script)
	
	inventory_node = inv_layer


func _input(event):
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		return
	
	if event.is_action_pressed("open_market"):
		if market_node and market_node.has_method("toggle"):
			market_node.toggle()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("stall_action"):
		if stall_scene:
			var manager = stall_scene.get_node("StallManager")
			if manager:
				if manager.is_open:
					manager.close_stall()
				else:
					manager.open_stall()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("open_furnace"):
		if furnace_node and furnace_node.has_method("toggle"):
			furnace_node.toggle()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("open_inventory"):
		if inventory_node and inventory_node.has_method("toggle"):
			inventory_node.toggle()
		get_viewport().set_input_as_handled()
	
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_QUOTELEFT:
			if dev_console_node and dev_console_node.has_method("toggle"):
				dev_console_node.toggle()
			get_viewport().set_input_as_handled()
