extends Area2D
class_name InteractZone

@export var prompt_text: String = "按 E 交互"
@export var action_name: String = ""

var player_in_range: bool = false
var prompt_label: Label = null


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	prompt_label = Label.new()
	prompt_label.text = prompt_text
	prompt_label.add_theme_font_size_override("font_size", 13)
	prompt_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.visible = false
	add_child(prompt_label)
	prompt_label.position = Vector2(-60, -30)
	prompt_label.size = Vector2(180, 30)


func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true
		var p = body as Player
		if p:
			p.current_interactable = self


func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false
		var p = body as Player
		if p and p.current_interactable == self:
			p.current_interactable = null


func on_interact():
	# 子类或连接方重写
	pass
