extends Node2D

var stall_scene: Node = null


func _ready():
	print("灵墟旅商 loaded!")
	print("初始灵石: %d" % PlayerData.spirit_stones)
	print("时间: %s" % PlayerData.get_time_label())
	
	_create_market()
	
	var stall = preload("res://scenes/StallScene.tscn")
	if stall:
		stall_scene = stall.instantiate()
		add_child(stall_scene)
	
	print("按 M 打开集市  |  按 S 开张收摊  |  按 F 熔炉")


func _create_market():
	var market_layer = CanvasLayer.new()
	market_layer.name = "Market"
	market_layer.layer = 3
	market_layer.set_process_mode(PROCESS_MODE_WHEN_PAUSED)
	add_child(market_layer)
	
	var script = load("res://scripts/Market.gd")
	if script:
		market_layer.set_script(script)


func _input(event):
	if event.is_action_pressed("open_market"):
		var market = find_child("Market", true, false)
		if market and market.has_method("toggle"):
			market.toggle()
		elif market and market.has_method("open"):
			if market.get("is_open"):
				market.close()
			else:
				market.open()
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
