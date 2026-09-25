class_name Player
extends CharacterBody2D

const DURATION_TACKLE := 200

enum ControlScheme {CPU,P1,P2}
enum State {MOVING, TACKLING}

@export var control_scheme : ControlScheme
@export var speed : float
@onready var animation_player : AnimationPlayer = %AnimationPlayer
@onready var player_sprite : Sprite2D = %playerSprite

var heading := Vector2.RIGHT
var state := State.MOVING
var time_start_tackle := Time.get_ticks_msec()

func _process(_delta: float) -> void:
	
	if control_scheme != ControlScheme.CPU:
		if state == State.MOVING:
			handle_human_movement()
			if velocity.x !=0 and KeyUtils.is_action_just_pressed(control_scheme, KeyUtils.Action.SHOOT):
				state = State.TACKLING
				time_start_tackle = Time.get_ticks_msec()
			set_movement_animation()
		elif state == State.TACKLING:
			animation_player.play("tackle")
			if Time.get_ticks_msec() - time_start_tackle > DURATION_TACKLE:
				state = State.MOVING
			
	set_heading()
	flip_sprite()
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
	
