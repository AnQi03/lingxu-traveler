extends Node2D

var stall_scene: Node = null


func _ready():
	print("灵墟旅商 loaded!")
	print("初始灵石: %d" % PlayerData.spirit_stones)
	print("时间: %s" % PlayerData.get_time_label())
	
	# 创建集市节点
	_create_market()
	
	# 加载摆摊场景
	var stall = preload("res://scenes/StallScene.tscn")
	if stall:
		stall_scene = stall.instantiate()
		add_child(stall_scene)
	else:
		print("警告：StallScene.tscn 未找到")
	
	print("按 M 打开集市  |  按 S 开张收摊  |  按 F 熔炉")


func _create_market():
	# 用代码创建集市UI，完全避免.tscn引用问题
	var market_layer = CanvasLayer.new()
	market_layer.name = "Market"
	market_layer.layer = 3
	add_child(market_layer)
	
	var script = load("res://scripts/Market.gd")
	if script:
		market_layer.set_script(script)


func _input(event):
	if event.is_action_pressed("stall_action"):
		if stall_scene:
			var manager = stall_scene.get_node("StallManager")
			if manager:
				if manager.is_open:
					manager.close_stall()
				else:
					manager.open_stall()
		get_viewport().set_input_as_handled()
