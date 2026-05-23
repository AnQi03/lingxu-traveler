extends CanvasLayer
class_name MaterialJournal

var is_open: bool = false
var journal_panel: Panel
var content: VBoxContainer

func _ready():
	set_process_mode(PROCESS_MODE_WHEN_PAUSED)
	_build_ui()
	journal_panel.visible = false

func _build_ui():
	journal_panel = Panel.new()
	journal_panel.position = Vector2(120, 40)
	journal_panel.size = Vector2(1040, 600)
	journal_panel.visible = false
	add_child(journal_panel)
	
	var bg = ColorRect.new()
	bg.color = Color(0.10, 0.06, 0.04, 0.97)
	bg.size = journal_panel.size
	journal_panel.add_child(bg)
	
	var title_bar = HBoxContainer.new()
	title_bar.position = Vector2(0, 0)
	title_bar.size = Vector2(1040, 36)
	journal_panel.add_child(title_bar)
	
	var title = Label.new()
	title.text = "  📖 灵材图鉴"
	title.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	title.add_theme_font_size_override("font_size", 20)
	title_bar.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = "关闭 [ESC]"
	close_btn.pressed.connect(close)
	title_bar.add_child(close_btn)
	
	content = VBoxContainer.new()
	content.position = Vector2(20, 46)
	content.size = Vector2(1000, 540)
	content.add_theme_constant_override("separation", 8)
	journal_panel.add_child(content)

func toggle():
	if not journal_panel:
		_build_ui()
	if is_open: close()
	else: open()

func open():
	if not journal_panel:
		_build_ui()
	journal_panel.visible = true
	is_open = true
	get_tree().paused = true
	_refresh()

func close():
	journal_panel.visible = false
	is_open = false
	get_tree().paused = false

func _refresh():
	for child in content.get_children():
		child.queue_free()
	
	var counts = PlayerData.get_journal_counts()
	var tier_names = ["凡品", "灵品", "宝品", "仙品"]
	var tier_colors = [Color(0.7, 0.7, 0.7), Color(0.3, 0.8, 0.3), Color(0.3, 0.5, 1.0), Color(1, 0.6, 0.2)]
	var elem_icons = ["🟡金", "🟢木", "🔵水", "🔴火", "🟤土"]
	var elem_max = [2, 2, 2, 2, 2]  # 每种元素最多2种凡品
	
	# 总览
	var overview = Label.new()
	overview.text = "📊 总收集: %d种  |  凡品%d  灵品%d  宝品%d  仙品%d" % [
		counts.total, counts.tiers[0], counts.tiers[1], counts.tiers[2], counts.tiers[3]
	]
	overview.add_theme_color_override("font_color", Color.WHITE)
	overview.add_theme_font_size_override("font_size", 16)
	content.add_child(overview)
	
	# 五行进度
	var elem_text = "五行: "
	for i in range(5):
		elem_text += "%s%d  " % [elem_icons[i], counts.elements[i]]
	var elem_label = Label.new()
	elem_label.text = elem_text
	elem_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	content.add_child(elem_label)
	
	# 未发现提示
	if counts.total < 10:
		var hint = Label.new()
		hint.text = "💡 多去集市进货、多熔炼，发现更多灵材品种！"
		hint.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6))
		content.add_child(hint)
	
	# 品阶分布进度条
	for t in range(4):
		var bar_label = Label.new()
		var total_in_tier = [10, 5, 4, 3][t]
		var pct = float(counts.tiers[t]) / float(total_in_tier) * 100
		var bar = _make_bar(pct, 30)
		bar_label.text = "%s %s %d/%d (%.0f%%)" % [tier_names[t], bar, counts.tiers[t], total_in_tier, pct]
		bar_label.add_theme_color_override("font_color", tier_colors[t])
		content.add_child(bar_label)

func _make_bar(pct: float, width: int) -> String:
	var filled = int(float(width) * pct / 100.0)
	var result = ""
	for i in range(width):
		result += "█" if i < filled else "░"
	return result
