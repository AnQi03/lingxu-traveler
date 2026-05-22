extends CanvasLayer

@onready var time_label: Label = $HUD_Background/TopBar/TimeLabel
@onready var stone_label: Label = $HUD_Background/TopBar/StoneLabel
@onready var hud_bg: ColorRect = $HUD_Background

var period_label: Label = null
var pause_label: Label = null
var season_label: Label = null
var current_period: String = ""

var period_colors = {
	"morning": Color(0, 0, 0, 0.35),
	"afternoon": Color(0, 0, 0, 0.30),
	"evening": Color(0.15, 0.08, 0.02, 0.50),
	"night": Color(0.05, 0.02, 0.10, 0.65)
}


func _ready() -> void:
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
	
	_update_display()


func _process(_delta: float) -> void:
	_update_display()


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
	var text = "灵石：%d" % stones
	if mids > 0:
		text += " + %d中品" % mids
	if highs > 0:
		text += " + %d上品" % highs
	stone_label.text = text
