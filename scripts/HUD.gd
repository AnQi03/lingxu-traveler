extends CanvasLayer

@onready var time_label: Label = $HUD_Background/TopBar/TimeLabel
@onready var stone_label: Label = $HUD_Background/TopBar/StoneLabel
@onready var hud_bg: ColorRect = $HUD_Background

var period_label: Label = null
var pause_label: Label = null
var season_label: Label = null
var current_period: String = ""

var period_colors = {
	"morning": Color(0.06, 0.04, 0.03, 0.40),
	"afternoon": Color(0.06, 0.04, 0.02, 0.35),
	"evening": Color(0.10, 0.05, 0.04, 0.55),
	"night": Color(0.04, 0.02, 0.06, 0.70)
}

## 语义颜色体系
const COLOR_SUCCESS = Color(0.4, 0.85, 0.35)    # 青木绿 — 成交/升品
const COLOR_WARNING = Color(0.9, 0.55, 0.15)    # 烛火橙 — 灵识低/快没耐心
const COLOR_DANGER = Color(0.85, 0.25, 0.20)    # 丹砂红 — 被拒/销毁
const COLOR_INFO = Color(0.4, 0.65, 0.85)       # 灵气蓝 — 信息提示
const COLOR_RARE = Color(0.7, 0.45, 0.85)       # 仙品紫 — 稀有

var toast_label: Label = null
var toast_timer: float = 0.0
var last_stone_count: int = 0


func _ready() -> void:
	# 暖色调HUD
	time_label.add_theme_color_override("font_color", Color(0.9, 0.82, 0.65))
	stone_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	hud_bg.color = Color(0.06, 0.04, 0.03, 0.7)  # 暖暗底HUD背景
	
	period_label = Label.new()
	period_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	period_label.add_theme_font_size_override("font_size", 14)
	period_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	period_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	$HUD_Background/TopBar.add_child(period_label)
	$HUD_Background/TopBar.move_child(period_label, 1)
	
	pause_label = Label.new()
	pause_label.text = "⏸ 暂停"
	pause_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	pause_label.add_theme_font_size_override("font_size", 12)
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause_label.position = Vector2(0, 0)
	pause_label.size = Vector2(100, 20)
	pause_label.visible = false
	$HUD_Background/TopBar.add_child(pause_label)
	$HUD_Background/TopBar.move_child(pause_label, 2)
	
	season_label = Label.new()
	season_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	season_label.add_theme_font_size_override("font_size", 13)
	season_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	season_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	$HUD_Background/TopBar.add_child(season_label)
	$HUD_Background/TopBar.move_child(season_label, 3)
	
	var ling_label = Label.new()
	ling_label.name = "ling_label"
	ling_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
	ling_label.add_theme_font_size_override("font_size", 12)
	ling_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ling_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	$HUD_Background/TopBar.add_child(ling_label)
	$HUD_Background/TopBar.move_child(ling_label, 4)
	
	# 吐司通知标签
	toast_label = Label.new()
	toast_label.name = "toast_label"
	toast_label.add_theme_font_size_override("font_size", 16)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.position = Vector2(0, 0)
	toast_label.size = Vector2(1152, 40)
	toast_label.visible = false
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD_Background.add_child(toast_label)
	
	PlayerData.set_meta("hud", self)
	
	_update_display()


func _process(_delta: float) -> void:
	_update_display()
	_update_toast(_delta)

func _update_toast(delta: float):
	if not toast_label or not toast_label.visible:
		return
	toast_timer -= delta
	if toast_timer <= 0:
		toast_label.visible = false

func show_toast(text: String, color: Color = COLOR_INFO, duration: float = 3.0):
	if not toast_label:
		return
	toast_label.text = text
	toast_label.add_theme_color_override("font_color", color)
	toast_label.visible = true
	toast_timer = duration


func _update_display() -> void:
	if not is_inside_tree():
		return
	
	time_label.text = PlayerData.get_time_label()
	
	var p = DayCycle.get_period_label(PlayerData.time_of_day)
	if period_label:
		period_label.text = p
	
	var period_name = DayCycle.get_period_name(PlayerData.time_of_day)
	if period_name != current_period:
		current_period = period_name
		if period_colors.has(period_name):
			hud_bg.color = period_colors[period_name]
	
	var main = get_node("/root/Main")
	var is_paused = false
	if main and main.has_method("is_any_panel_open"):
		is_paused = main.is_any_panel_open()
	
	if pause_label:
		pause_label.visible = is_paused
	
	if season_label:
		var s_text = PlayerData.get_season_label()
		if PlayerData.is_festival_day():
			s_text += " 🎪集市大日"
		# 年度评定倒计时
		var days_left = PlayerData.ASSESSMENT_DAY - PlayerData.game_day
		if days_left <= 30 and days_left > 0 and not PlayerData.year_assessed:
			s_text += " | 🏛️ 评定还有%d天" % days_left
		season_label.text = s_text
	
	var ling_label = find_child("ling_label", true, false)
	if ling_label:
		var l = PlayerData.ling_shi
		var bar = ""
		for i in range(0, 100, 10):
			if l > i:
				bar += "█"
			else:
				bar += "░"
		ling_label.text = "灵识 [%s] %d" % [bar, l]
	
	var stones = PlayerData.spirit_stones
	var mids = PlayerData.mid_spirit_stones
	var highs = PlayerData.high_spirit_stones
	var text = "💰 %d" % stones
	if mids > 0:
		text += "  ⚪×%d" % mids
	if highs > 0:
		text += "  💎×%d" % highs
	stone_label.text = text

	# 灵墟碎片计数
	var fragments = PlayerData.lingxu_fragments
	if fragments > 0:
		stone_label.text += "  |  🔮×%d" % fragments
	
	# 灵石跳动动画
	var current = PlayerData.get_total_stones()
	if current != last_stone_count:
		if current > last_stone_count:
			stone_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
			var tw = create_tween()
			tw.tween_property(stone_label, "scale", Vector2(1.2, 1.2), 0.1)
			tw.tween_property(stone_label, "scale", Vector2(1.0, 1.0), 0.2)
			tw.tween_callback(func(): stone_label.add_theme_color_override("font_color", Color.WHITE))
		last_stone_count = current
