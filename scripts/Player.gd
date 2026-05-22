extends CharacterBody2D
class_name Player

@export var move_speed: float = 120.0

var facing_direction: Vector2 = Vector2.DOWN
var can_move: bool = true
var current_interactable: Node = null


func _ready():
	add_to_group("player")


func _physics_process(_delta):
	if not can_move:
		return
	
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_dir * move_speed
	move_and_slide()
	
	if input_dir != Vector2.ZERO:
		facing_direction = input_dir


func set_can_move(enable: bool):
	can_move = enable
	if not enable:
		velocity = Vector2.ZERO


func try_interact():
	if current_interactable and current_interactable.has_method("on_interact"):
		current_interactable.on_interact()
