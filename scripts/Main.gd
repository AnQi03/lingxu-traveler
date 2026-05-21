# ============================================================
# 灵墟旅商 - 主场景脚本
# 初始化所有子系统，管理游戏流程
# ============================================================
extends Node2D

var stall_scene: CanvasLayer


func _ready() -> void:
	print("灵墟旅商 loaded!")
	print("初始灵石: %d" % PlayerData.spirit_stones)
	print("时间: %s" % PlayerData.get_time_label())
	
	# 加载摆摊场景
	var stall = preload("res://scenes/StallScene.tscn")
	stall_scene = stall.instantiate()
	add_child(stall_scene)
	
	# 显示欢迎提示
	print("按 M 打开集市进货")
	print("按 S 开张/收摊")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_market"):
		# 集市已经由Market节点处理
		pass
	elif event.is_action_pressed("stall_action"):
		# 按S开张/收摊
		_toggle_stall()
		get_viewport().set_input_as_handled()


func _toggle_stall() -> void:
	if not stall_scene or not stall_scene.has_method("toggle_stall"):
		return
	
	# 通过StallManager控制
	var manager = stall_scene.get_node("StallManager")
	if manager:
		if manager.is_open:
			manager.close_stall()
		else:
			manager.open_stall()


func _on_market_bought_item(item_data: Dictionary) -> void:
	print("购买了: %s" % item_data.name)
