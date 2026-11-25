class_name Player
extends CharacterBody2D

const DURATION_TACKLE := 0.2

enum ControlScheme {CPU, P1, P2}
enum State {MOVING, TACKLING, RECOVERING}

@export var control_scheme: ControlScheme
## El equipo decide quién puede recibir un pase, independientemente del control.
@export var team_id: int = 0
@export var display_name: String = "CPU"
@export var speed: float = 120.0
## Global coordinates for the player's center. An empty rectangle disables limits.
@export var movement_bounds: Rect2

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var player_sprite: Sprite2D = %playerSprite
@onready var cpu_movement: CpuMovement = %CpuMovement
@onready var cpu_patrol: CpuPatrol = %CpuPatrol
@onready var cpu_interceptor: CpuBallInterceptor = %CpuBallInterceptor
@onready var cpu_attack: CpuBallAttack = %CpuBallAttack
## Solo la escena de partido añade este controlador; la práctica conserva su IA.
@onready var cpu_defense: CpuBallDefense = get_node_or_null("CpuBallDefense") as CpuBallDefense
@onready var ball_interaction: PlayerBallInteraction = %BallInteraction
## Solo el partido añade entradas con contacto; la práctica mantiene su control.
@onready var ball_tackle: PlayerBallTackle = get_node_or_null("PlayerBallTackle") as PlayerBallTackle

var heading := Vector2.RIGHT
var state := State.MOVING
var _tackle_time_left := 0.0
var _recovery_time_left := 0.0
var _ball_controlled_movement := false


func _ready() -> void:
	add_to_group("players")
	add_to_group("ball_receivers")


func _physics_process(delta: float) -> void:
	if is_instance_valid(ball_tackle):
		ball_tackle.update(delta)
	if state == State.RECOVERING:
		_recovery_time_left = maxf(_recovery_time_left - delta, 0.0)
		velocity = Vector2.ZERO
		if _recovery_time_left <= 0.0:
			state = State.MOVING
	if state == State.TACKLING:
		_tackle_time_left = maxf(_tackle_time_left - delta, 0.0)
		if _tackle_time_left <= 0.0:
			state = State.MOVING

	if state == State.MOVING:
		if control_scheme == ControlScheme.CPU:
			if has_ball() and is_instance_valid(cpu_defense):
				cpu_defense.reset()
			cpu_attack.update(global_position, speed, delta, movement_bounds)
		if ball_interaction.update_action(delta):
			velocity = Vector2.ZERO
		else:
			update_movement(delta)
		if control_scheme != ControlScheme.CPU and not has_ball():
			if velocity.x != 0.0 and KeyUtils.is_action_just_pressed(
				control_scheme, KeyUtils.Action.SHOOT
			):
				start_tackle()

	# FÍSICA: aplicar la velocidad calculada y resolver colisiones.
	var previous_position := global_position
	move_and_slide()
	keep_inside_movement_bounds()
	if is_instance_valid(ball_tackle):
		ball_tackle.after_movement(previous_position)
	ball_interaction.after_movement(delta)
	set_heading()
	flip_sprite()
	set_movement_animation()


func update_movement(delta: float) -> void:
	if control_scheme == ControlScheme.CPU:
		# MARCAJE: perseguir al portador rival y cubrir nuestra portería.
		# Un balón libre desactiva la defensa y conserva la intercepción predictiva.
		if is_instance_valid(cpu_defense) and cpu_defense.update(global_position, speed, delta, movement_bounds):
			cpu_interceptor.reset()
			# Una entrada ya fijó su dirección y velocidad; no reemplazarla por Arrive.
			if state != State.TACKLING:
				velocity = cpu_defense.get_velocity(global_position, speed, delta, movement_bounds)
			_ball_controlled_movement = true
			return
		# INTERCEPCIÓN: tiene prioridad mientras hay un balón libre alcanzable.
		var controls_ball := false
		if has_ball() or CpuBallAssignment.is_assigned(self):
			controls_ball = cpu_interceptor.update(global_position, speed, delta, movement_bounds)
		else:
			cpu_interceptor.reset()
		controls_ball = controls_ball or (has_ball() and cpu_attack.enabled and cpu_attack.state != CpuBallAttack.State.IDLE)
		if controls_ball:
			if has_ball() and cpu_attack.enabled and cpu_attack.state != CpuBallAttack.State.IDLE:
				velocity = cpu_attack.get_velocity(global_position, speed, delta, movement_bounds)
			else:
				velocity = cpu_interceptor.get_velocity(global_position, speed, delta, movement_bounds)
		else:
			if _ball_controlled_movement:
				# Reanudar desde el waypoint cercano, sin conservar una presión antigua.
				cpu_patrol.reset()
			velocity = cpu_patrol.get_velocity(global_position, speed, delta, movement_bounds)
		_ball_controlled_movement = controls_ball
	else:
		velocity = KeyUtils.get_input_vector(control_scheme) * speed


func start_tackle(direction: Vector2 = Vector2.ZERO) -> bool:
	if is_instance_valid(ball_tackle):
		var tackle_direction := velocity if direction.is_zero_approx() else direction
		if not ball_tackle.begin(tackle_direction):
			return false
	state = State.TACKLING
	_tackle_time_left = ball_tackle.duration if is_instance_valid(ball_tackle) else DURATION_TACKLE
	return true


func recover_from_tackle(duration: float) -> void:
	state = State.RECOVERING
	_recovery_time_left = maxf(duration, 0.0)
	_tackle_time_left = 0.0
	velocity = Vector2.ZERO
	ball_interaction.reset()
	reset_cpu_controllers()


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
	elif ball_interaction.action_state == PlayerBallInteraction.ActionState.CHARGING:
		animation_player.play("prep_kick")
	elif ball_interaction.action_state == PlayerBallInteraction.ActionState.KICKING:
		animation_player.play("kick")
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


func has_ball() -> bool:
	return ball_interaction.has_ball()


func reset_cpu_controllers() -> void:
	cpu_patrol.reset()
	cpu_interceptor.reset()
	cpu_attack.reset()
	if is_instance_valid(cpu_defense):
		cpu_defense.reset()
	_ball_controlled_movement = false


func reset_for_restart(spawn_position: Vector2, facing: Vector2) -> void:
	# Un saque cancela también una carga o entrada que estuviera a medio ejecutar.
	global_position = spawn_position
	velocity = Vector2.ZERO
	state = State.MOVING
	_tackle_time_left = 0.0
	_recovery_time_left = 0.0
	if is_instance_valid(ball_tackle):
		ball_tackle.reset()
	heading = facing
	ball_interaction.reset()
	ball_interaction.aim_direction = facing
	reset_cpu_controllers()
	flip_sprite()
	animation_player.play("idle")
