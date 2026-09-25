class_name Player
extends CharacterBody2D

enum ControlScheme {CPU,P1,P2}
@export var control_scheme : ControlScheme
@export var speed : float
@onready var animation_player : AnimationPlayer = %AnimationPlayer
@onready var player_sprite : Sprite2D = %playerSprite

var heading := Vector2.RIGHT

func _process(_delta: float) -> void:
	
	if control_scheme != ControlScheme.CPU:
		set_movement_animation()
	set_heading()
	flip_sprite()
	handle_human_movement()
	move_and_slide()
	
func set_movement_animation() -> void:
	var direction := KeyUtils.get_input_vector(control_scheme)
	velocity = direction * speed
	
func handle_human_movement() -> void:
	if velocity.length()>0:
		animation_player.play("running")
	else:
		animation_player.play("idle")
	

func set_heading() -> void:
	if velocity.x>0:
		heading = Vector2.RIGHT
	elif velocity.x<0:
		heading = Vector2.LEFT
func flip_sprite() -> void:
	if heading == Vector2.RIGHT:
		player_sprite.flip_h = false
	elif heading == Vector2.LEFT:
		player_sprite.flip_h = true
	
