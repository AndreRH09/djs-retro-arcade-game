class_name Player
extends CharacterBody2D

const DURATION_TACKLE := 0.2

enum ControlScheme {CPU, P1, P2}
enum State {MOVING, TACKLING}

@export var control_scheme: ControlScheme
@export var speed: float = 120.0
## Global coordinates for the player's center. An empty rectangle disables limits.
@export var movement_bounds: Rect2

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var player_sprite: Sprite2D = %playerSprite
@onready var cpu_movement: CpuMovement = %CpuMovement

var heading := Vector2.RIGHT
var state := State.MOVING
var _tackle_time_left := 0.0


func _physics_process(delta: float) -> void:
	if state == State.TACKLING:
		_tackle_time_left = maxf(_tackle_time_left - delta, 0.0)
		if _tackle_time_left <= 0.0:
			state = State.MOVING

	if state == State.MOVING:
		update_movement(delta)
		if control_scheme != ControlScheme.CPU:
			if velocity.x != 0.0 and KeyUtils.is_action_just_pressed(
				control_scheme, KeyUtils.Action.SHOOT
			):
				start_tackle()

	# FÍSICA: aplicar la velocidad calculada y resolver colisiones.
	move_and_slide()
	keep_inside_movement_bounds()
	set_heading()
	flip_sprite()
	set_movement_animation()


func update_movement(delta: float) -> void:
	if control_scheme == ControlScheme.CPU:
		# IA: obtener la velocidad combinando Seek, Arrive y la anticipación del perfil.
		velocity = cpu_movement.get_velocity(global_position, speed, delta, movement_bounds)
	else:
		velocity = KeyUtils.get_input_vector(control_scheme) * speed


func start_tackle() -> void:
	state = State.TACKLING
	_tackle_time_left = DURATION_TACKLE


func keep_inside_movement_bounds() -> void:
	if not movement_bounds.has_area():
		return

	var limited_position := global_position.clamp(movement_bounds.position, movement_bounds.end)
	if limited_position.x != global_position.x:
		velocity.x = 0.0
	if limited_position.y != global_position.y:
		velocity.y = 0.0
	global_position = limited_position


func set_movement_animation() -> void:
	if state == State.TACKLING:
		animation_player.play("tackle")
	elif velocity.length_squared() > 0.0:
		animation_player.play("running")
	else:
		animation_player.play("idle")


func set_heading() -> void:
	if velocity.x > 0.0:
		heading = Vector2.RIGHT
	elif velocity.x < 0.0:
		heading = Vector2.LEFT


func flip_sprite() -> void:
	player_sprite.flip_h = heading == Vector2.LEFT
