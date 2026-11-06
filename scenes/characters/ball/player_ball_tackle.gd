class_name PlayerBallTackle
extends Node
## Entrada corta: deslizarse, tocar el balón de un rival y recuperar el equilibrio.
## La CPU decide cuándo entrar; este contacto físico es igual para CPU, P1 y P2.

@export var enabled := false
@export var ball: SoccerBall
@export_group("Entrada")
@export_range(16.0, 48.0, 1.0, "suffix:px") var approach_distance := 36.0
@export_range(6.0, 20.0, 1.0, "suffix:px") var contact_distance := 15.0
@export_range(0.1, 0.6, 0.01, "suffix:s") var duration := 0.32
@export_range(0.0, 0.2, 0.01, "suffix:s") var contact_delay := 0.08
@export_range(0.2, 3.0, 0.05, "suffix:s") var cooldown := 1.1
@export_range(0.0, 600.0, 10.0) var slide_friction := 250.0
@export_range(0.0, 1.0, 0.05, "suffix:s") var recovery_duration := 0.35

@onready var player: Player = get_parent() as Player

var _cooldown_left := 0.0
var _elapsed := 0.0
var _direction := Vector2.ZERO
var _resolved := false


func can_start() -> bool:
	return (
		enabled and is_instance_valid(player) and player.is_physics_processing()
		and is_instance_valid(ball) and ball.is_physics_processing() and ball.goal_team < 0
		and player.state == Player.State.MOVING and not player.has_ball()
		and player.ball_interaction.enabled and player.ball_interaction.ball == ball
		and player.ball_interaction.action_state == PlayerBallInteraction.ActionState.IDLE
		and player.speed > 0.0 and _cooldown_left <= 0.0
	)


func begin(direction: Vector2) -> bool:
	if not can_start() or not direction.is_finite() or direction.is_zero_approx():
		return false
	_direction = direction.normalized()
	_cooldown_left = maxf(cooldown, duration)
	_elapsed = 0.0
	_resolved = false
	player.velocity = _direction * player.speed
	SoundPlayer.play(SoundPlayer.Sound.TACKLING)
	return true


func update(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if player.state == Player.State.TACKLING:
		_elapsed += delta
		# Como en el tutorial: la entrada pierde velocidad por fricción del césped.
		player.velocity = player.velocity.move_toward(Vector2.ZERO, maxf(slide_friction, 0.0) * delta)


func after_movement(previous_position: Vector2) -> void:
	if not enabled or _resolved or player.state != Player.State.TACKLING or _elapsed < contact_delay:
		return
	if not is_instance_valid(ball) or not ball.is_physics_processing() or ball.goal_team >= 0:
		return
	var opponent := ball.carrier as Player
	if not is_instance_valid(opponent) or opponent == player or opponent.team_id == player.team_id:
		return
	if not opponent.is_physics_processing() or not opponent.ball_interaction.enabled:
		return
	if opponent.ball_interaction.ball != ball or ball.state != SoccerBall.State.CARRIED or ball.height > ball.pickup_height:
		return
	# Contacto frontal con el balón a los pies. El segmento evita saltárselo a 30 Hz.
	var closest := Geometry2D.get_closest_point_to_segment(ball.global_position, previous_position, player.global_position)
	var offset := ball.global_position - previous_position
	if closest.distance_to(ball.global_position) > contact_distance or offset.dot(_direction) < -2.0:
		return
	_resolved = true
	if not ball.try_steal(player, opponent):
		return
	# La transferencia puede marcar gol al llevar el balón a los pies y reiniciar
	# el partido mediante una señal síncrona. No modificar ese nuevo saque.
	if ball.goal_team >= 0 or ball.carrier != player or not ball.is_physics_processing():
		return
	if player.state != Player.State.TACKLING or not player.is_physics_processing():
		return
	# Se cancela cualquier carga/pase del rival y se le da una recuperación breve.
	opponent.recover_from_tackle(recovery_duration)
	player.ball_interaction.reset()
	player.reset_cpu_controllers()


func reset() -> void:
	_cooldown_left = 0.0
	_elapsed = 0.0
	_direction = Vector2.ZERO
	_resolved = false
