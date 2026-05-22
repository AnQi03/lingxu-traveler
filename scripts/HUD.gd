extends CanvasLayer

@onready var time_label: Label = $HUD_Background/TopBar/TimeLabel
@onready var stone_label: Label = $HUD_Background/TopBar/StoneLabel

var period_label: Label = null


func _ready() -> void:
	# 创建时段标签（代码生成，避免改.tscn）
	period_label = Label.new()
	period_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	period_label.add_theme_font_size_override("font_size", 14)
	period_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	period_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	$HUD_Background/TopBar.add_child(period_label)
	# 放在 TimeLabel 和 StoneLabel 之间
	$HUD_Background/TopBar.move_child(period_label, 1)
	
	_update_display()


func _process(_delta: float) -> void:
	_update_display()


func _update_display() -> void:
	if not is_inside_tree():
		return
	
	# 更新时间
	time_label.text = PlayerData.get_time_label()
	
	# 更新时段
	if period_label:
		period_label.text = DayCycle.get_period_label(PlayerData.time_of_day)
	
	# 更新灵石
	var stones = PlayerData.spirit_stones
	var mids = PlayerData.mid_spirit_stones
	var highs = PlayerData.high_spirit_stones
	var text = "灵石：%d" % stones
	if mids > 0:
		text += " + %d中品" % mids
	if highs > 0:
		text += " + %d上品" % highs
	stone_label.text = text
