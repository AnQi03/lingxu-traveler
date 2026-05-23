extends Node2D

var stall_scene: Node = null
var market_node: Node = null
var dev_console_node: Node = null
var furnace_node: Node = null
var inventory_node: Node = null
var journal_node: Node = null
var day_summary_node: Node = null
var scene_bg: Control = null
var atmosphere_label: Label = null
var player: Player = null

## 交互点 {name, pos, radius, action}
var interact_points: Array = []


func _ready():
	set_process_mode(PROCESS_MODE_ALWAYS)
	
	print("灵墟旅商 loaded!")
	print("初始灵石: %d" % PlayerData.spirit_stones)
	
	_create_market()
	_create_dev_console()
	_create_furnace()
	_create_inventory()
	_create_journal()
	
	var stall = preload("res://scenes/StallScene.tscn")
	if stall:
		stall_scene = stall.instantiate()
		add_child(stall_scene)
	
	_create_scene_background()
	_create_player()
	_setup_camera()
	_create_interact_points()
	
	DayCycle.start()
	DayCycle.night_falling.connect(_on_night_falling)
	DayCycle.period_changed.connect(_on_period_changed)
	DayCycle.monthly_report.connect(_on_monthly_report)
	
	# 首次启动 → 开场叙事
	if not PlayerData.has_seen_opening:
		call_deferred("_show_opening")
	
	print("WASD 移动  |  E 场景交互/背包  |  Tab 背包  |  空格 摆摊  |  ESC 关闭面板")

func _process(delta):
	_process_interact_hint(delta)


func _show_opening():
	var opening = load("res://scripts/Opening.gd")
	if opening:
		var layer = CanvasLayer.new()
		layer.name = "OpeningScene"
		layer.layer = 30  # 最高层
		layer.set_script(opening)
		add_child(layer)
		get_tree().paused = true  # 开场时暂停游戏

func _create_scene_background():
	scene_bg = TextureRect.new()
	scene_bg.name = "SceneBackground"
	scene_bg.size = Vector2(1152, 648)
	scene_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene_bg.stretch_mode = TextureRect.STRETCH_SCALE
	scene_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scene_bg)
	move_child(scene_bg, 0)
	
	var overlay = ColorRect.new()
	overlay.name = "SceneOverlay"
	overlay.size = Vector2(1152, 648)
	overlay.color = Color(0, 0, 0, 0.35)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_bg.add_child(overlay)
	
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
	var is_night = t >= 19.0 or t < 5.0
	var tex_path = "res://assets/img/bg/market_scene_night.png" if is_night else "res://assets/img/bg/market_scene_day.png"
	var tex = load(tex_path)
	if tex:
		scene_bg.texture = tex
	
	var overlay = scene_bg.find_child("SceneOverlay", false, false)
	if overlay:
		if t >= 19.0 and t < 21.0:
			overlay.color = Color(0.05, 0.05, 0.15, 0.45)
		elif t >= 21.0 or t < 5.0:
			overlay.color = Color(0.02, 0.02, 0.08, 0.55)
		else:
			overlay.color = Color(0, 0, 0, 0.30)
	
	var atm_text = ""
	if t >= 5.0 and t < 7.0:
		atm_text = "晨雾未散，灵墟集市灯火渐明……"
	elif t >= 7.0 and t < 12.0:
		atm_text = "灵墟集市热闹非凡，讨价还价此起彼伏。"
	elif t >= 12.0 and t < 18.0:
		atm_text = "午后阳光慵懒，老顾客们慢悠悠地挑着灵材。"
	elif t >= 18.0 and t < 19.0:
		atm_text = "夕照染金天空，集市收摊的吆喝声渐起。"
	elif t >= 19.0 and t < 21.0:
		atm_text = "夜幕低垂，远处炉火噼啪、修士夜话。"
	else:
		atm_text = "夜深。灵墟沉入寂静，天道脉动在黑暗中流淌。"
	
	atmosphere_label.text = atm_text
	atmosphere_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))


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


func _create_journal():
	var layer = CanvasLayer.new()
	layer.name = "Journal"
	layer.layer = 5
	layer.set_process_mode(PROCESS_MODE_WHEN_PAUSED)
	add_child(layer)
	var script = load("res://scripts/MaterialJournal.gd")
	if script:
		layer.set_script(script)
	journal_node = layer

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


func is_any_panel_open() -> bool:
	if day_summary_node and is_instance_valid(day_summary_node) and day_summary_node.get("is_showing"):
		return true
	if market_node and market_node.get("is_open"):
		return true
	if furnace_node and furnace_node.get("is_open"):
		return true
	if inventory_node and inventory_node.get("is_open"):
		return true
	if journal_node and journal_node.get("is_open"):
		return true
	return false


func force_close_stall():
	if stall_scene:
		var manager = stall_scene.get_node("StallManager")
		if manager and manager.is_open:
			manager.close_stall()


func get_stall_income() -> int:
	if stall_scene:
		var manager = stall_scene.get_node("StallManager")
		if manager:
			return manager.daily_income
	return 0


func _on_monthly_report(day: int) -> void:
	var month = day / 30
	var total = PlayerData.total_earned
	var stones = PlayerData.spirit_stones + PlayerData.mid_spirit_stones * 100
	var msg = "📊 第%d个月 · 管家简报\\n累计营收: %d灵石 | 当前余额: %d灵石" % [month, total, stones]
	if PlayerData.ren_xin >= 10:
		msg += "\\n\\n💬 老管家：'少爷，生意越来越稳了。老奴替您高兴。'"
	elif PlayerData.shang_dao >= 15:
		msg += "\\n\\n💬 老管家：'少爷的商道眼光愈发老练了。'"
	elif PlayerData.tian_dao >= 10:
		msg += "\\n\\n💬 老管家：'老奴听说您在熔炼上也有进展……果然不是寻常人。'"
	else:
		msg += "\\n\\n💬 老管家：'慢慢来，日子还长。'"
	
	if hud_node:
		hud_node.show_toast(msg, Color(0.7, 0.8, 1.0), 6.0)


func _on_night_falling():
	SoundManager.sfx_day_transition()
	force_close_stall()
	
	# 年度评定日 → 用 YearEnd 替代 DaySummary
	if PlayerData.game_day == PlayerData.ASSESSMENT_DAY and not PlayerData.year_assessed:
		var year_end = load("res://scripts/YearEnd.gd")
		if year_end:
			var layer = CanvasLayer.new()
			layer.name = "YearEnd"
			layer.layer = 25
			layer.set_script(year_end)
			add_child(layer)
			return
	
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


func _create_player():
	player = Player.new()
	player.name = "Player"
	player.position = Vector2(576, 324)
	add_child(player)
	
	var sprite = Sprite2D.new()
	sprite.name = "PlayerSprite"
	var tex = load("res://assets/img/characters/player_front.png")
	if tex:
		sprite.texture = tex
		sprite.scale = Vector2(0.18, 0.18)  # 素白仙袍角色稍大
	player.add_child(sprite)
	
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 12
	shape.shape = circle
	player.add_child(shape)

func _setup_camera():
	var cam = Camera2D.new()
	cam.name = "GameCamera"
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 5.0
	cam.zoom = Vector2(1.0, 1.0)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 1152
	cam.limit_bottom = 648
	add_child(cam)
	cam.make_current()
	cam.reparent(player)


func _create_interact_points():
	interact_points = [
		{"name": "集市", "pos": Vector2(150, 324), "radius": 100, "action": "market"},
		{"name": "摊位", "pos": Vector2(576, 420), "radius": 100, "action": "stall"},
		{"name": "熔炉", "pos": Vector2(950, 324), "radius": 100, "action": "furnace"},
	]
	
	# 建筑精灵（场景装饰）
	_spawn_building(Vector2(120, 280), "res://assets/img/buildings/market_shop.png", 0.15)
	_spawn_building(Vector2(540, 370), "res://assets/img/buildings/stall_stand.png", 0.13)
	_spawn_building(Vector2(910, 280), "res://assets/img/buildings/furnace_forge.png", 0.14)
	
	# 装饰NPC（让场景有生气）
	_spawn_npc(Vector2(80, 260), "res://assets/img/characters/npc_elder.png", 0.12)
	_spawn_npc(Vector2(1050, 380), "res://assets/img/characters/npc_girl.png", 0.12)
	
	var hint = Label.new()
	hint.name = "InteractHint"
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.visible = false
	add_child(hint)

func _spawn_building(pos: Vector2, tex_path: String, scale: float):
	var spr = Sprite2D.new()
	spr.position = pos
	var tex = load(tex_path)
	if tex:
		spr.texture = tex
		spr.scale = Vector2(scale, scale)
		spr.z_index = -1
	add_child(spr)

func _spawn_npc(pos: Vector2, tex_path: String, scale: float):
	var spr = Sprite2D.new()
	spr.position = pos
	var tex = load(tex_path)
	if tex:
		spr.texture = tex
		spr.scale = Vector2(scale, scale)
		spr.z_index = 0
	add_child(spr)

func _get_nearest_interact() -> Dictionary:
	if not player:
		return {}
	var best = {}
	var best_dist = 9999.0
	for pt in interact_points:
		var d = player.position.distance_to(pt.pos)
		if d < pt.radius and d < best_dist:
			best = pt
			best_dist = d
	return best

func _process_interact_hint(_delta):
	var hint = find_child("InteractHint", false, false)
	if not hint or not player:
		return
	var nearest = _get_nearest_interact()
	if nearest.is_empty():
		hint.visible = false
	else:
		hint.text = "🏷 按 E — %s" % nearest.name
		hint.position = player.position + Vector2(-60, -50)
		hint.size = Vector2(120, 30)
		hint.visible = true

func _do_interact(action: String):
	match action:
		"market":
			if market_node and market_node.has_method("toggle"):
				market_node.toggle()
		"stall":
			if stall_scene:
				var mgr = stall_scene.get_node("StallManager")
				if mgr:
					if mgr.is_open: mgr.close_stall()
					elif DayCycle.can_stall(PlayerData.time_of_day): mgr.open_stall()
		"furnace":
			if not PlayerData.is_furnace_unlocked():
				var hud = PlayerData.get_meta("hud")
				if hud and hud.has_method("show_toast"):
					hud.show_toast("🔥 熔炉 Day5解锁", Color(1, 0.6, 0.2), 3.0)
			elif furnace_node and furnace_node.has_method("toggle"):
				furnace_node.toggle()


func _input(event):
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		# F5/F9/~ 全局快捷键，任何状态下都可用
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
		
		# 结算面板打开时，屏蔽所有其他按键
		if day_summary_node and is_instance_valid(day_summary_node) and day_summary_node.get("is_showing"):
			get_viewport().set_input_as_handled()
			return
		
		# ESC：关闭当前打开的面板
		if event.keycode == KEY_ESCAPE:
			if furnace_node and furnace_node.get("is_open"):
				furnace_node.toggle()
			elif market_node and market_node.get("is_open"):
				market_node.toggle()
			elif inventory_node and inventory_node.get("is_open"):
				inventory_node.toggle()
			get_viewport().set_input_as_handled()
			return
		
		# 有任何面板打开时：E 关闭当前面板，Tab 关闭背包
		if is_any_panel_open():
			if event.keycode == KEY_E:
				# E = 万能关闭键：关闭任何打开的交互面板
				if furnace_node and furnace_node.get("is_open"):
					furnace_node.toggle()
				elif market_node and market_node.get("is_open"):
					market_node.toggle()
				elif inventory_node and inventory_node.get("is_open"):
					inventory_node.toggle()
				get_viewport().set_input_as_handled()
				return
			if event.keycode == KEY_J and journal_node and journal_node.get("is_open"):
				journal_node.toggle()
				get_viewport().set_input_as_handled()
				return
			if (event.keycode == KEY_TAB) and inventory_node and inventory_node.get("is_open"):
				inventory_node.toggle()
				get_viewport().set_input_as_handled()
				return
			# 其他键：面板开着时屏蔽
			get_viewport().set_input_as_handled()
			return
		
		# 无面板打开：正常按键映射
		match event.keycode:
			KEY_E:
				var nearest = _get_nearest_interact()
				if nearest.is_empty():
					# 附近无交互物 → 打开背包
					if inventory_node and inventory_node.has_method("toggle"):
						inventory_node.toggle()
				else:
					_do_interact(nearest.action)
				get_viewport().set_input_as_handled()
			KEY_TAB:
				if inventory_node and inventory_node.has_method("toggle"):
					inventory_node.toggle()
				get_viewport().set_input_as_handled()
			KEY_J:
				if journal_node and journal_node.has_method("toggle"):
					journal_node.toggle()
				get_viewport().set_input_as_handled()
			KEY_SPACE:
				if stall_scene:
					var manager = stall_scene.get_node("StallManager")
					if manager:
						if not DayCycle.can_stall(PlayerData.time_of_day) and not manager.is_open:
							return
						if manager.is_open:
							manager.close_stall()
						else:
							manager.open_stall()
				get_viewport().set_input_as_handled()
