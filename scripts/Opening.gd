extends CanvasLayer
# 开场叙事 — 首次启动时显示，讲清楚「你是谁、为什么在这里」

var panel: Panel = null
var page: int = 0
var pages = [
	{
		"title": "灵墟·边陲",
		"text": "灵墟。\n\n一个三不管的边陲集市。\n修仙者的余烬在这里交易，\n宗门弃徒在这里安家，\n走投无路的人在这里摆摊。\n\n你——在一个雨夜抵达了这里。",
		"color": Color(0.4, 0.6, 0.9)
	},
	{
		"title": "管家的信",
		"text": "管家把一袋灵石塞进你手里。\n「少爷…不，该叫你一声掌柜了。」\n「老爷欠下的债，利滚利，已经……」\n「但别怕。灵墟这地方——」\n「只要肯干，就不怕还不上。」\n\n你低头看了看：150颗下品灵石。\n这就是你全部的本钱。",
		"color": Color(0.9, 0.8, 0.5)
	},
	{
		"title": "明天",
		"text": "管家已经打点好了住处。\n灵墟集市明天一早开张。\n\n你握紧手里的灵石。\n\n债要还，日子要过。\n灵墟虽小——\n但谁说这里不能是新的开始？",
		"color": Color(0.5, 1.0, 0.7)
	}
]


func _ready():
	set_process_mode(PROCESS_MODE_ALWAYS)
	_build_ui()


func _build_ui():
	panel = Panel.new()
	panel.position = Vector2(180, 80)
	panel.size = Vector2(792, 460)
	add_child(panel)
	
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.06, 0.15, 0.98)
	bg.size = panel.size
	bg.mouse_filter = 0
	panel.add_child(bg)
	
	_render_page()


func _render_page():
	# 清除上一页内容
	for child in panel.get_children():
		if child is Label:
			child.queue_free()
	
	var p = pages[page]
	
	var title = Label.new()
	title.text = p.title
	title.position = Vector2(0, 30)
	title.size = Vector2(792, 40)
	title.add_theme_color_override("font_color", p.color)
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	
	var text = Label.new()
	text.text = p.text
	text.position = Vector2(50, 85)
	text.size = Vector2(692, 280)
	text.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	text.add_theme_font_size_override("font_size", 17)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(text)
	
	var hint = Label.new()
	hint.text = "（点击任意位置继续）" if page < pages.size() - 1 else "（点击开始游戏）"
	hint.position = Vector2(0, 400)
	hint.size = Vector2(792, 30)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	hint.add_theme_font_size_override("font_size", 14)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(hint)
	
	# 淡入动画
	panel.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.5)


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		page += 1
		if page >= pages.size():
			PlayerData.has_seen_opening = true
			_dismiss()
		else:
			panel.modulate.a = 0.0  # 重置透明度
			_render_page()


func _dismiss():
	get_tree().paused = false
	queue_free()
