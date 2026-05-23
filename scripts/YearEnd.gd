extends CanvasLayer
# 年度评定 — 第120天触发，灵墟商会评定你的摊位

var panel: Panel = null
var bg_clicked: bool = false


func _ready():
	set_process_mode(PROCESS_MODE_ALWAYS)
	_build_ui()


func _build_ui():
	panel = Panel.new()
	panel.position = Vector2(300, 90)
	panel.size = Vector2(1128, 795)
	add_child(panel)
	
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.14, 0.98)
	bg.size = panel.size
	bg.mouse_filter = 0
	bg.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and not bg_clicked:
			bg_clicked = true
			_dismiss()
	)
	panel.add_child(bg)
	
	var result = PlayerData.calculate_assessment()
	
	# 标题
	var title = Label.new()
	title.text = "🏛️ 灵墟商会 · 年度评定"
	title.position = Vector2(0, 22)
	title.size = Vector2(1128, 60)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	title.add_theme_font_size_override("font_size", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	
	# 评级
	var rating = Label.new()
	rating.text = result.rating_text
	rating.position = Vector2(0, 90)
	rating.size = Vector2(1128, 75)
	rating.add_theme_color_override("font_color", result.rating_color)
	rating.add_theme_font_size_override("font_size", 30)
	rating.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(rating)
	
	# 分数
	var score_label = Label.new()
	score_label.text = "得分：%d / %d" % [result.score, result.max_score]
	score_label.position = Vector2(0, 165)
	score_label.size = Vector2(1128, 38)
	score_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	score_label.add_theme_font_size_override("font_size", 16)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(score_label)
	
	# 分隔线
	var sep = HSeparator.new()
	sep.position = Vector2(90, 218)
	sep.size = Vector2(948, 3)
	panel.add_child(sep)
	
	# 各项得分
	var parts_label = Label.new()
	parts_label.text = "\n".join(result.parts)
	parts_label.position = Vector2(120, 232)
	parts_label.size = Vector2(888, 150)
	parts_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	parts_label.add_theme_font_size_override("font_size", 13)
	panel.add_child(parts_label)
	
	# 分隔线2
	var sep2 = HSeparator.new()
	sep2.position = Vector2(90, 390)
	sep2.size = Vector2(948, 3)
	panel.add_child(sep2)
	
	# 叙事文字
	var narrative = Label.new()
	narrative.text = result.narrative
	narrative.position = Vector2(90, 405)
	narrative.size = Vector2(948, 75)
	narrative.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
	narrative.add_theme_font_size_override("font_size", 15)
	narrative.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	narrative.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(narrative)
	
	# 管家来信
	var butler = Label.new()
	butler.text = _get_butler_assessment(result.rating)
	butler.position = Vector2(90, 495)
	butler.size = Vector2(948, 90)
	butler.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
	butler.add_theme_font_size_override("font_size", 13)
	butler.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(butler)
	
	# 统计
	var stats = Label.new()
	stats.text = _get_stats()
	stats.position = Vector2(90, 600)
	stats.size = Vector2(948, 90)
	stats.add_theme_color_override("font_color", Color(0.5, 0.6, 0.8))
	stats.add_theme_font_size_override("font_size", 12)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(stats)
	
	var hint = Label.new()
	hint.text = "评定结束。你可以继续在灵墟经营下去。\n（点击任意位置继续）"
	hint.position = Vector2(0, 712)
	hint.size = Vector2(1128, 60)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	hint.add_theme_font_size_override("font_size", 13)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(hint)
	
	# 入场动画
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)
	var tw = create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.5)
	tw.parallel().tween_property(panel, "scale", Vector2(1.0, 1.0), 0.5)


func _get_butler_assessment(rating: int) -> String:
	match rating:
		5: return "📜 管家：「少爷！不——该叫您灵墟传奇了。老仆……老仆不知道该说什么。只是想起一年前那个雨夜，你手里只有150颗灵石。」"
		4: return "📜 管家：「杰出商贾！老爷在天之灵也会欣慰的。老仆这就去给您温一壶酒。」"
		3: return "📜 管家：「稳健经营，不骄不躁。这正是老爷最欣赏的作风。明年，会更好。」"
		2: return "📜 管家：「少爷，路还长。老仆相信您——灵墟不会辜负努力的人。」"
		_: return "📜 管家：「初来乍到难免磕绊。老仆还记得您第一天来灵墟的样子。再来一年，一定会不一样的。」"


func _get_stats() -> String:
	var days = PlayerData.game_day - 1
	var earned = PlayerData.total_earned
	var stones = PlayerData.get_total_stones()
	var frags = PlayerData.lingxu_fragments
	var tier = PlayerData.furnace_tier
	var regulars = PlayerData.get_known_customer_names().size()
	
	return "经营 %d 天 | 累计收入 %d 灵石 | 当前 %d 灵石 | 碎片 🔮×%d | 熔炉 Lv.%d | 常客 %d 人" % [days, earned, stones, frags, tier, regulars]


func _dismiss():
	PlayerData.save_game()
	queue_free()
