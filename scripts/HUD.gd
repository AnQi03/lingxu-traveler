# ============================================================
# HUD脚本 - 显示灵石/时间/操作提示
# ============================================================
extends CanvasLayer

@onready var time_label: Label = $HUD_Background/TopBar/TimeLabel
@onready var stone_label: Label = $HUD_Background/TopBar/StoneLabel


func _ready() -> void:
	_update_display()


func _process(_delta: float) -> void:
	_update_display()


func _update_display() -> void:
	if not is_inside_tree():
		return
	
	# 更新时间
	time_label.text = PlayerData.get_time_label()
	
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
