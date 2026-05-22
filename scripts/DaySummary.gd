extends CanvasLayer

const DISPLAY_DURATION: float = 4.0

var summary_panel: Panel = null
var timer: float = 0.0
var is_showing: bool = false


func _ready():
	set_process_mode(PROCESS_MODE_ALWAYS)
	_build_ui()
	if is_instance_valid(summary_panel):
		summary_panel.visible = false


func _build_ui():
	summary_panel = Panel.new()
	summary_panel.visible = false
	add_child(summary_panel)
	
	summary_panel.position = Vector2(340, 200)
	summary_panel.size = Vector2(600, 280)
	
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.18, 0.95)
	bg.size = summary_panel.size
	bg.mouse_filter = 0
	summary_panel.add_child(bg)
	
	var title = Label.new()
	title.text = "🌙 营业结束"
	title.position = Vector2(0, 0)
	title.size = Vector2(600, 50)
	title.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary_panel.add_child(title)
	
	var info_label = Label.new()
	info_label.name = "info_label"
	info_label.position = Vector2(30, 60)
	info_label.size = Vector2(540, 180)
	info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_panel.add_child(info_label)
	
	var hint = Label.new()
	hint.name = "hint_label"
	hint.text = "（片刻后将进入新的一天……）"
	hint.position = Vector2(0, 245)
	hint.size = Vector2(600, 30)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	hint.add_theme_font_size_override("font_size", 12)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_panel.add_child(hint)


func _process(delta):
	if summary_panel.visible:
		timer -= delta
		if timer <= 0.0:
			_dismiss()


func show_summary():
	if not is_instance_valid(summary_panel):
		_build_ui()
	
	summary_panel.visible = true
	is_showing = true
	timer = DISPLAY_DURATION
	
	var info = find_child("info_label", true, false)
	if info:
		var day = PlayerData.game_day
		var players = PlayerData.spirit_stones
		var inv_count = 0
		var total_items = 0
		for item in PlayerData.inventory:
			inv_count += 1
			total_items += item.get("count", 1)
		
		info.text = "第%d天营业结束\n\n当前灵石：%d 下品\n库存：%d 种（%d 件）\n熔炼次数：%d/5" % [
			day - 1, players, inv_count, total_items, PlayerData.daily_refine_count
		]


func _dismiss():
	is_showing = false
	summary_panel.visible = false
	queue_free()
