extends CanvasLayer

var is_open: bool = false
var furnace_panel: Panel = null
var selected_item_idx: int = -1
var item_grid: GridContainer = null
var result_label: Label = null
var tier_names = ["凡品", "灵品", "宝品", "仙品"]
var element_icons = ["金", "木", "水", "火", "土"]

# 熔炼策略
enum SmeltStrategy { SAFE = 0, NORMAL = 1, RISKY = 2 }
const STRATEGY_NAMES = ["稳扎稳打", "标准熔炼", "孤注一掷"]
const STRATEGY_COSTS = [8, 10, 12]      # 灵识消耗
const STRATEGY_LUCK_MOD = [0.15, 0.0, -0.20]   # 成功率修正
const STRATEGY_UPGRADE_MOD = [-0.20, 0.0, 0.30] # 升品率修正
var strategy_panel: Panel = null    # 策略选择面板
var pending_item_id: String = ""    # 待熔炼灵材的base_id


func _ready():
	set_process_mode(PROCESS_MODE_WHEN_PAUSED)
	_build_ui()
	if is_instance_valid(furnace_panel):
		furnace_panel.visible = false


func _build_ui():
	furnace_panel = Panel.new()
	furnace_panel.visible = false
	add_child(furnace_panel)
	
	furnace_panel.position = Vector2(150, 50)
	furnace_panel.size = Vector2(900, 580)
	
	var bg = ColorRect.new()
	bg.color = Color(0.10, 0.06, 0.04, 0.97)  # 暖暗底，比集市更深 — 熔炉氛围
	bg.size = furnace_panel.size
	bg.mouse_filter = 0
	furnace_panel.add_child(bg)
	
	# 像素面板边框纹理
	var border_tex = load("res://assets/img/ui/ui/panel_border.png")
	if border_tex:
		var border = TextureRect.new()
		border.texture = border_tex
		border.size = furnace_panel.size
		border.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		border.stretch_mode = TextureRect.STRETCH_SCALE
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		furnace_panel.add_child(border)
		furnace_panel.move_child(border, 1)
	
	var title_bar = HBoxContainer.new()
	title_bar.position = Vector2(0, 0)
	title_bar.size = Vector2(900, 36)
	furnace_panel.add_child(title_bar)
	
	var title = Label.new()
	title.text = "  🔥 天道熔炉"
	title.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
	title.add_theme_font_size_override("font_size", 22)
	title_bar.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = "  关闭 [ESC]  "
	close_btn.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(_on_close)
	title_bar.add_child(close_btn)
	
	var info = Label.new()
	info.text = "  选择灵材投入熔炉（每天最多5次）  |  今日已熔炼: %d/5" % PlayerData.daily_refine_count
	info.name = "refine_info"
	info.position = Vector2(15, 40)
	info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info.add_theme_font_size_override("font_size", 13)
	furnace_panel.add_child(info)
	
	var left_label = Label.new()
	left_label.text = "  背包中的灵材"
	left_label.position = Vector2(15, 65)
	left_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	left_label.add_theme_font_size_override("font_size", 15)
	furnace_panel.add_child(left_label)
	
	var left_scroll = ScrollContainer.new()
	left_scroll.position = Vector2(15, 88)
	left_scroll.size = Vector2(420, 320)
	furnace_panel.add_child(left_scroll)
	
	item_grid = GridContainer.new()
	item_grid.columns = 1
	item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_grid.add_theme_constant_override("v_separation", 4)
	left_scroll.add_child(item_grid)
	
	var right_label = Label.new()
	right_label.text = "  熔炼操作"
	right_label.position = Vector2(460, 65)
	right_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
	right_label.add_theme_font_size_override("font_size", 15)
	furnace_panel.add_child(right_label)
	
	var select_frame = ColorRect.new()
	select_frame.name = "select_frame"
	select_frame.position = Vector2(465, 90)
	select_frame.size = Vector2(400, 80)
	select_frame.color = Color(0.12, 0.08, 0.18, 0.8)
	furnace_panel.add_child(select_frame)
	
	var select_name = Label.new()
	select_name.name = "select_name"
	select_name.text = "未选择灵材"
	select_name.position = Vector2(475, 95)
	select_name.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	select_name.add_theme_font_size_override("font_size", 14)
	furnace_panel.add_child(select_name)
	
	var select_desc = Label.new()
	select_desc.name = "select_desc"
	select_desc.text = "点击左侧背包中的灵材选择"
	select_desc.position = Vector2(475, 118)
	select_desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	select_desc.add_theme_font_size_override("font_size", 12)
	furnace_panel.add_child(select_desc)
	
	var smelt_btn = Button.new()
	smelt_btn.name = "smelt_btn"
	smelt_btn.text = "🔥 开始熔炼"
	smelt_btn.position = Vector2(610, 200)
	smelt_btn.size = Vector2(160, 50)
	smelt_btn.disabled = true
	smelt_btn.pressed.connect(_do_smelt)
	furnace_panel.add_child(smelt_btn)
	
	var upgrade_btn = Button.new()
	upgrade_btn.name = "upgrade_btn"
	upgrade_btn.text = "⬆ 升级熔炉"
	upgrade_btn.position = Vector2(465, 200)
	upgrade_btn.size = Vector2(140, 50)
	upgrade_btn.pressed.connect(_do_upgrade)
	furnace_panel.add_child(upgrade_btn)
	
	var slice_btn = Button.new()
	slice_btn.name = "slice_btn"
	slice_btn.text = "🔪 切片加工"
	slice_btn.position = Vector2(610, 135)
	slice_btn.size = Vector2(140, 50)
	slice_btn.disabled = true
	slice_btn.pressed.connect(_do_slice)
	furnace_panel.add_child(slice_btn)
	
	var tier_label = Label.new()
	tier_label.name = "tier_label"
	tier_label.position = Vector2(465, 260)
	tier_label.size = Vector2(400, 25)
	tier_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	tier_label.add_theme_font_size_override("font_size", 12)
	furnace_panel.add_child(tier_label)
	
	var result_bg = ColorRect.new()
	result_bg.name = "result_bg"
	result_bg.position = Vector2(465, 280)
	result_bg.size = Vector2(400, 120)
	result_bg.color = Color(0.08, 0.05, 0.12, 0.6)
	furnace_panel.add_child(result_bg)
	
	result_label = Label.new()
	result_label.name = "result_label"
	result_label.position = Vector2(475, 290)
	result_label.size = Vector2(380, 100)
	result_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	result_label.add_theme_font_size_override("font_size", 13)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	furnace_panel.add_child(result_label)
	
	var history_label = Label.new()
	history_label.text = "  今日熔炼记录"
	history_label.position = Vector2(15, 420)
	history_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	history_label.add_theme_font_size_override("font_size", 14)
	furnace_panel.add_child(history_label)
	
	var history_scroll = ScrollContainer.new()
	history_scroll.position = Vector2(15, 445)
	history_scroll.size = Vector2(870, 120)
	furnace_panel.add_child(history_scroll)
	
	var history_box = VBoxContainer.new()
	history_box.name = "history_box"
	history_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_scroll.add_child(history_box)
	
	# ---- 策略选择面板（默认隐藏） ----
	strategy_panel = Panel.new()
	strategy_panel.visible = false
	strategy_panel.position = Vector2(200, 100)
	strategy_panel.size = Vector2(520, 280)
	furnace_panel.add_child(strategy_panel)
	
	var s_bg = ColorRect.new()
	s_bg.color = Color(0.08, 0.04, 0.12, 0.97)
	s_bg.size = strategy_panel.size
	s_bg.mouse_filter = 0
	strategy_panel.add_child(s_bg)
	
	var s_title = Label.new()
	s_title.text = "⚡ 选择熔炼策略"
	s_title.position = Vector2(0, 5)
	s_title.size = Vector2(520, 30)
	s_title.add_theme_color_override("font_color", Color(1, 0.7, 0.2))
	s_title.add_theme_font_size_override("font_size", 20)
	s_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	strategy_panel.add_child(s_title)
	
	var s_info = Label.new()
	s_info.name = "strategy_info"
	s_info.position = Vector2(30, 40)
	s_info.size = Vector2(460, 30)
	s_info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	s_info.add_theme_font_size_override("font_size", 13)
	s_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	strategy_panel.add_child(s_info)
	
	# 三个策略按钮
	var strategies = [
		{"name": "🛡 稳扎稳打", "desc": "成功率+15% | 升品率-20% | 灵识-8\n稳妥的选择，适合练手和保本", "color": Color(0.3, 0.8, 0.3)},
		{"name": "⚖ 标准熔炼", "desc": "默认概率 | 灵识-10\n不疾不徐，随天道流转", "color": Color(0.7, 0.7, 0.7)},
		{"name": "🔥 孤注一掷", "desc": "成功率-20% | 升品率+30% | 灵识-12\n高风险高回报，赌徒之选", "color": Color(1, 0.4, 0.2)},
	]
	
	for i in range(3):
		var s = strategies[i]
		var y = 80 + i * 60
		
		var btn = Button.new()
		btn.text = s.name
		btn.position = Vector2(40, y)
		btn.size = Vector2(140, 50)
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(_on_strategy_picked.bind(i))
		strategy_panel.add_child(btn)
		
		var desc = Label.new()
		desc.text = s.desc
		desc.position = Vector2(195, y)
		desc.size = Vector2(290, 50)
		desc.add_theme_color_override("font_color", s.color)
		desc.add_theme_font_size_override("font_size", 12)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		strategy_panel.add_child(desc)


func toggle():
	if is_open:
		close()
	else:
		open()


func open():
	if not is_instance_valid(furnace_panel):
		_build_ui()
	if not is_instance_valid(furnace_panel):
		return
	
	is_open = true
	furnace_panel.visible = true
	if is_instance_valid(strategy_panel):
		strategy_panel.visible = false
	furnace_panel.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(furnace_panel, "modulate:a", 1.0, 0.2)
	_refresh_tier()
	_refresh_items()
	_refresh_history()
	get_tree().paused = true


func close():
	is_open = false
	if is_instance_valid(furnace_panel):
		var tw = create_tween()
		tw.tween_property(furnace_panel, "modulate:a", 0.0, 0.15)
		furnace_panel.visible = false
	get_tree().paused = false


func _on_close():
	close()


func _get_base_id(item_id: String) -> String:
	if "_t" in item_id:
		return item_id.split("_t")[0]
	return item_id


func _refresh_items():
	for child in item_grid.get_children():
		child.queue_free()
	
	selected_item_idx = -1
	var btn = find_child("smelt_btn", true, false)
	if btn:
		btn.disabled = true
	var sbtn = find_child("slice_btn", true, false)
	if sbtn:
		sbtn.disabled = true
	var name_label = find_child("select_name", true, false)
	if name_label:
		name_label.text = "未选择灵材"
	var desc_label = find_child("select_desc", true, false)
	if desc_label:
		desc_label.text = "点击左侧背包中的灵材选择"
	
	var info = find_child("refine_info", true, false)
	if info:
		info.text = "  选择灵材投入熔炉（每天最多5次）  |  今日已熔炼: %d/%d" % [PlayerData.daily_refine_count, PlayerData.MAX_DAILY_REFINE]
	
	if PlayerData.inventory.is_empty():
		var empty_label = Label.new()
		empty_label.text = "   背包为空，先去集市进货吧"
		empty_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		item_grid.add_child(empty_label)
		return
	
	for i in range(PlayerData.inventory.size()):
		var item = PlayerData.inventory[i]
		var tier_str = tier_names[item.tier] if item.tier < tier_names.size() else "?"
		var elem_str = element_icons[item.element] if item.element >= 0 and item.element < element_icons.size() else "?"
		
		var card = Panel.new()
		card.custom_minimum_size = Vector2(400, 36)
		
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_child(hbox)
		
		var label = Label.new()
		label.text = "[%s][%s] %s ×%d" % [tier_str, elem_str, item.name, item.get("count", 1)]
		label.add_theme_color_override("font_color", Color.WHITE)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 13)
		hbox.add_child(label)
		
		var idx = i
		card.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_select_item(idx)
		)
		
		item_grid.add_child(card)


func _select_item(idx: int):
	selected_item_idx = idx
	var item = PlayerData.inventory[idx]
	
	var name_label = find_child("select_name", true, false)
	if name_label:
		var tier_str = tier_names[item.tier] if item.tier < tier_names.size() else "?"
		var elem_str = element_icons[item.element] if item.element >= 0 and item.element < element_icons.size() else "?"
		name_label.text = "[%s][%s] %s ×%d" % [tier_str, elem_str, item.name, item.get("count", 1)]
	
	var desc_label = find_child("select_desc", true, false)
	if desc_label:
		desc_label.text = "品阶: %s  |  五行: %s  |  来源于: %s" % [tier_names[item.tier] if item.tier < tier_names.size() else "?", element_icons[item.element] if item.element >= 0 and item.element < element_icons.size() else "?", item.get("origin", "未知")]
	
	var btn = find_child("smelt_btn", true, false)
	if btn:
		btn.disabled = false
	
	var sbtn = find_child("slice_btn", true, false)
	if sbtn:
		if PlayerData.is_slicing_unlocked():
			sbtn.text = "🔪 切片加工"
			sbtn.disabled = false
		else:
			sbtn.text = "🔒 Day10解锁"
			sbtn.disabled = true


func _do_smelt():
	if selected_item_idx < 0 or selected_item_idx >= PlayerData.inventory.size():
		return
	
	if PlayerData.daily_refine_count >= PlayerData.MAX_DAILY_REFINE:
		if is_instance_valid(result_label):
			result_label.text = "今日熔炼次数已用完！明日再来。"
			result_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		return
	
	var item = PlayerData.inventory[selected_item_idx]
	pending_item_id = _get_base_id(item.id)
	
	# 灵识检查移到策略选择后（不同策略消耗不同）
	var min_cost = STRATEGY_COSTS[0]
	if PlayerData.ling_shi < min_cost:
		if is_instance_valid(result_label):
			result_label.text = "灵识不足！至少需要%d灵识。今天休息吧。" % min_cost
			result_label.add_theme_color_override("font_color", Color(1, 0.5, 0.2))
		return
	
	# 显示策略面板
	if is_instance_valid(strategy_panel):
		var info = strategy_panel.find_child("strategy_info", true, false)
		if info:
			var tier_str = tier_names[item.tier] if item.tier < tier_names.size() else "?"
			info.text = "正在熔炼：[%s] %s  |  当前天道：%d  |  灵识：%d" % [tier_str, item.name, PlayerData.tian_dao, PlayerData.ling_shi]
		strategy_panel.visible = true


func _on_strategy_picked(strategy: int):
	strategy_panel.visible = false
	
	var cost = STRATEGY_COSTS[strategy]
	if not PlayerData.spend_ling_shi(cost):
		if is_instance_valid(result_label):
			result_label.text = "灵识耗尽！今天你已经太累了，休息吧。"
			result_label.add_theme_color_override("font_color", Color(1, 0.5, 0.2))
		return
	
	if selected_item_idx < 0 or selected_item_idx >= PlayerData.inventory.size():
		return
	
	var item = PlayerData.inventory[selected_item_idx]
	if not PlayerData.remove_item(item.id, 1):
		return
	
	_do_smelt_with_strategy(item, strategy)


func _do_smelt_with_strategy(item: Dictionary, strategy: int):
	var base_id = _get_base_id(item.id)
	var feat_name = STRATEGY_NAMES[strategy]
	
	# 根据熔炉等级动态概率
	var luck_table = PlayerData.get_furnace_luck(PlayerData.furnace_tier).duplicate()
	
	# 天道加成
	var tian_bonus = float(PlayerData.tian_dao) / 10.0 * 0.02
	
	# 连胜加成
	var streak_bonus = 0.0
	if PlayerData.smelt_streak >= 5:
		streak_bonus = 0.15
	elif PlayerData.smelt_streak >= 3:
		streak_bonus = 0.10
	elif PlayerData.smelt_streak >= 2:
		streak_bonus = 0.05
	
	# 策略修正
	var luck_mod = STRATEGY_LUCK_MOD[strategy]
	var upgrade_mod = STRATEGY_UPGRADE_MOD[strategy]
	
	luck_table[0] += tian_bonus + streak_bonus + luck_mod
	luck_table[1] += tian_bonus + streak_bonus + luck_mod
	luck_table[2] += tian_bonus + streak_bonus + luck_mod
	
	var base_luck = luck_table[0]
	var base_fail = 0.25
	var base_destroy = 0.1
	
	match item.tier:
		0:
			base_luck = luck_table[0]
			base_fail = 0.25
			base_destroy = 0.08
		1:
			base_luck = luck_table[1]
			base_fail = 0.30
			base_destroy = 0.12
		2:
			base_luck = luck_table[2]
			base_fail = 0.35
			base_destroy = 0.25
		_:
			base_luck = 0.0
			base_fail = 0.40
			base_destroy = 0.30
	
	# 应用升品率修正
	base_luck = clamp(base_luck + upgrade_mod, 0.02, 0.95)
	var base_same = clamp(1.0 - base_luck - base_fail - base_destroy, 0.0, 1.0)
	
	var roll = randf()
	var result_text = "[%s] " % feat_name
	var result_color = Color(0.6, 0.6, 0.6)
	
	if roll < base_destroy:
		result_text += "💀 熔炼失败！灵材化为灰烬……\n🔮 但天道留下了灵墟碎片（+3）"
		result_color = Color(0.5, 0.2, 0.2)
		PlayerData.daily_refine_count += 1
		PlayerData.tian_dao += 1
		PlayerData.add_fragments(3)
		PlayerData.smelt_streak = 0
		SoundManager.sfx_smelt_destroy()

	elif roll < base_destroy + base_fail:
		var nt = max(0, item.tier - 1)
		var new_id = base_id + "_t" + str(nt) if nt > 0 else base_id
		PlayerData.add_item({
			"id": new_id, "name": item.name, "tier": nt,
			"element": item.element, "price": max(1, item.price / 3), "count": 1
		})
		result_text += "⚠️ 品阶下降：[%s] → [%s]\n🔮 残留了一丝灵墟碎片（+1）" % [tier_names[item.tier], tier_names[nt]]
		result_color = Color(0.7, 0.5, 0.2)
		PlayerData.daily_refine_count += 1
		PlayerData.tian_dao += 1
		PlayerData.add_fragments(1)
		PlayerData.smelt_streak = 0
		SoundManager.sfx_smelt_normal()

	elif roll < base_destroy + base_fail + base_same:
		var keep_tier = max(0, item.tier)
		var keep_id = base_id + "_t" + str(keep_tier) if keep_tier > 0 else base_id
		PlayerData.add_item({
			"id": keep_id, "name": item.name, "tier": keep_tier,
			"element": item.element, "price": item.get("base_price", item.price), "count": 1
		})
		result_text += "  品阶不变：[%s]" % tier_names[item.tier]
		result_color = Color(0.6, 0.6, 0.6)
		PlayerData.daily_refine_count += 1
		PlayerData.smelt_streak = 0
		SoundManager.sfx_smelt_normal()

	else:
		var nt = min(3, item.tier + 1)
		var new_id = base_id + "_t" + str(nt)
		PlayerData.add_item({
			"id": new_id, "name": item.name, "tier": nt,
			"element": item.element, "price": item.price * 3, "count": 1
		})
		result_text += "✨ 升品成功！[%s] → [%s]！" % [tier_names[item.tier], tier_names[nt]]
		result_color = Color(1, 0.8, 0.3)
		PlayerData.daily_refine_count += 1
		PlayerData.tian_dao += 1
		PlayerData.smelt_streak += 1
		SoundManager.sfx_smelt_success()
		if PlayerData.smelt_streak >= 5:
			result_text += " 🔥天道眷顾！连升%d次！" % PlayerData.smelt_streak
		elif PlayerData.smelt_streak >= 3:
			result_text += " ✨如有神助！连升%d次！" % PlayerData.smelt_streak
		elif PlayerData.smelt_streak >= 2:
			result_text += " 🔥手感正热！连升%d次！" % PlayerData.smelt_streak
	
	if is_instance_valid(result_label):
		result_label.text = result_text
		result_label.add_theme_color_override("font_color", result_color)
	
	_refresh_items()
	_refresh_history()
	
	if PlayerData.daily_refine_count >= PlayerData.MAX_DAILY_REFINE:
		if is_instance_valid(result_label):
			result_label.text = "⚠️ 今日熔炼次数已用完！\n" + result_label.text
	
	# 天道初体验
	if not PlayerData.tian_voice_heard and PlayerData.tian_dao >= 1:
		PlayerData.tian_voice_heard = true
		var hud = PlayerData.get_meta("hud")
		if hud and hud.has_method("show_toast"):
			hud.show_toast("💫 天道：「炉火在跳动…我能感觉到。这灵材在呼应你。」", Color(0.7, 0.45, 0.85), 6.0)


func _refresh_history():
	var history_box = find_child("history_box", true, false)
	if not history_box:
		return
	
	for child in history_box.get_children():
		child.queue_free()
	
	var help = Label.new()
	help.text = "  每次熔炼消耗1件灵材。升品有概率，已熔炼 %d/%d 次。" % [PlayerData.daily_refine_count, PlayerData.MAX_DAILY_REFINE]
	help.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	help.add_theme_font_size_override("font_size", 12)
	history_box.add_child(help)


func _do_upgrade():
	var cost = PlayerData.get_furnace_upgrade_cost()
	if cost < 0:
		_show_result("熔炉已达最高等级！", Color(1, 0.8, 0.3))
		return
	
	if PlayerData.get_total_stones() < cost:
		_show_result("灵石不足！升级需要 %d 灵石（当前 %d）。" % [cost, PlayerData.get_total_stones()], Color(1, 0.3, 0.3))
		return
	
	var success = PlayerData.upgrade_furnace()
	if not success:
		_show_result("升级失败！", Color(1, 0.3, 0.3))
		return
	
	_show_result("✨ 熔炉升级成功！当前等级 Lv.%d" % PlayerData.furnace_tier, Color(1, 0.8, 0.3))
	_refresh_tier()
	_refresh_items()


func _refresh_tier():
	var tier_label = find_child("tier_label", true, false)
	if tier_label:
		var t = PlayerData.furnace_tier
		var luck = PlayerData.get_furnace_luck(t)
		var next_cost = PlayerData.get_furnace_upgrade_cost()
		var cost_text = "升级需要 %d灵石" % next_cost if next_cost > 0 else "已满级"
		tier_label.text = "  熔炉 Lv.%d | 凡→灵 %.0f%% | 灵→宝 %.0f%% | %s" % [t, luck[0]*100, luck[1]*100, cost_text]
	
	var upgrade_btn = find_child("upgrade_btn", true, false)
	if upgrade_btn:
		var next_cost = PlayerData.get_furnace_upgrade_cost()
		if next_cost < 0:
			upgrade_btn.text = "已满级"
			upgrade_btn.disabled = true
		else:
			upgrade_btn.text = "⬆ 升级 (%d灵石)" % next_cost
			upgrade_btn.disabled = false


func _show_result(text: String, color: Color):
	if is_instance_valid(result_label):
		result_label.text = text
		result_label.add_theme_color_override("font_color", color)
	_flash_result(color)

func _flash_result(flash_color: Color):
	var bg = find_child("result_bg", true, false)
	if not bg:
		return
	var orig = bg.color
	bg.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.3)
	var tw = create_tween()
	tw.tween_property(bg, "color", orig, 0.6)


func _do_slice():
	if not PlayerData.is_slicing_unlocked():
		_show_result("🔒 切片加工将在 Day 10 解锁——先熔炼试试吧！", Color(0.5, 0.5, 0.5))
		return
	
	if selected_item_idx < 0 or selected_item_idx >= PlayerData.inventory.size():
		return
	
	if not PlayerData.spend_ling_shi(3):
		_show_result("灵识耗尽！切片需要 5 灵识。", Color(1, 0.5, 0.2))
		return
	
	var item = PlayerData.inventory[selected_item_idx]
	
	if "片" in item.get("name", ""):
		_show_result("灵材片不能再切片了。", Color(1, 0.5, 0.2))
		return
	
	var success = PlayerData.remove_item(item.id, 1)
	if not success:
		return
	
	var sliced = item.duplicate()
	sliced.name = item.name + "片"
	sliced.id = item.id + "_slice"
	sliced.price = int(item.price * 1.15)
	sliced.count = 1
	PlayerData.add_item(sliced)
	
	_show_result("🔪 切片完成！%s → %s（+15%%价值）" % [item.name, sliced.name], Color(0.5, 0.9, 0.5))
	_refresh_items()
	_refresh_history()
