class_name CpuBallAttack
extends Node
## Decide qué hacer después de recuperar el balón. No mueve el balón directamente:
## CpuMovement conduce con Seek + Arrive y BallInteraction ejecuta cada golpeo.

enum State {IDLE, DRIBBLING, PASSING, SHOOTING, WAITING}

@export var enabled := false
@export var movement: CpuMovement
@export var interaction: PlayerBallInteraction
## Punto hacia el que ataca el equipo; por ahora representa el centro de la portería.
@export var attack_target: Node2D
@export_group("Conducción y decisiones")
@export_range(0.1, 1.0, 0.05) var dribble_speed_ratio := 0.75
@export_range(0.0, 3.0, 0.05, "suffix:s") var minimum_possession_time := 0.6
@export_range(0.02, 1.0, 0.02, "suffix:s") var decision_interval := 0.2
@export_group("Disparo y pase")
@export_range(10.0, 400.0, 5.0, "suffix:px") var shot_range := 150.0
@export_range(0.0, 1.0, 0.05) var shot_charge_ratio := 0.5
@export_range(0.0, 200.0, 5.0, "suffix:px") var minimum_pass_progress := 40.0
@export_range(0.0, 40.0, 1.0, "suffix:px") var opponent_clearance := 12.0
@export_group("Después de soltar el balón")
@export_range(0.0, 5.0, 0.1, "suffix:s") var pass_recovery_delay := 2.0
@export_range(0.0, 3.0, 0.1, "suffix:s") var shot_recovery_delay := 0.6

var state := State.IDLE
var destination := Vector2.ZERO
var selected_receiver: Player

var _observed_interaction: PlayerBallInteraction
var _possession_time := 0.0
var _time_until_decision := 0.0
var _recovery_time_left := 0.0
var _waiting_receiver: Player
var _waiting_ball: SoccerBall
var _waiting_for_pass := false


## True significa que la conducción/acción sustituye a la patrulla e intercepción.
## Se llama antes de BallInteraction.update_action para iniciar la animación ese tick.
func update(position: Vector2, speed: float, delta: float, bounds: Rect2 = Rect2()) -> bool:
	var player := get_parent() as Player
	if not enabled or not is_instance_valid(player) or player.control_scheme != Player.ControlScheme.CPU:
		reset()
		return false
	if not is_instance_valid(interaction) or not interaction.enabled or not is_instance_valid(interaction.ball):
		reset()
		return false
	_observe_interaction()
	if is_finite(delta) and delta >= 0.0:
		_recovery_time_left = maxf(_recovery_time_left - delta, 0.0)
	_update_recovery()
	if not interaction.has_ball():
		_clear_possession()
		return false
	if not is_instance_valid(movement) or not is_instance_valid(attack_target):
		_clear_possession()
		return false
	if not position.is_finite() or not attack_target.global_position.is_finite() or not is_finite(speed) or not is_finite(delta) or delta < 0.0:
		_clear_possession()
		return false

	_clear_recovery()
	destination = attack_target.global_position
	if bounds.has_area():
		destination = destination.clamp(bounds.position, bounds.end)
	# La acción compartida conserva el balón hasta terminar la animación de golpeo.
	if interaction.action_state != PlayerBallInteraction.ActionState.IDLE:
		return true
	state = State.DRIBBLING
	selected_receiver = null
	_possession_time += delta
	_time_until_decision -= delta
	if _possession_time < maxf(minimum_possession_time, 0.0) or _time_until_decision > 0.0:
		return true
	_time_until_decision = maxf(decision_interval, 0.02)
	_choose_action(player, position)
	return true


func get_velocity(position: Vector2, speed: float, delta: float, bounds: Rect2 = Rect2()) -> Vector2:
	if not enabled or state != State.DRIBBLING or not is_instance_valid(movement) or not is_instance_valid(interaction):
		return Vector2.ZERO
	if not interaction.has_ball() or interaction.action_state != PlayerBallInteraction.ActionState.IDLE:
		return Vector2.ZERO
	if not position.is_finite() or not destination.is_finite() or not is_finite(speed) or not is_finite(delta):
		return Vector2.ZERO
	# SEEK orienta hacia el ataque; ARRIVE frena en el destino y respeta los límites.
	return movement.get_arrival_velocity(position, destination, maxf(speed, 0.0) * clampf(dribble_speed_ratio, 0.0, 1.0), delta, bounds, 0.0, 12.0)


## Evita que el pasador compita inmediatamente con su compañero por su propio pase.
func allows_interception() -> bool:
	_update_recovery()
	return _recovery_time_left <= 0.0


func reset() -> void:
	if is_instance_valid(_observed_interaction) and _observed_interaction.action_released.is_connected(_on_action_released):
		_observed_interaction.action_released.disconnect(_on_action_released)
	_observed_interaction = null
	_clear_recovery()
	_clear_possession()


func _observe_interaction() -> void:
	if interaction == _observed_interaction:
		return
	reset()
	_observed_interaction = interaction
	_observed_interaction.action_released.connect(_on_action_released)


func _choose_action(player: Player, position: Vector2) -> void:
	var target_position := attack_target.global_position
	var shot_direction := target_position - interaction.ball.global_position
	# Primero se busca un disparo cercano y con la línea de tiro libre.
	if position.distance_to(target_position) <= maxf(shot_range, 0.0) and not shot_direction.is_zero_approx():
		if _has_clear_lane(player, interaction.ball.global_position, target_position):
			if interaction.request_shot(shot_direction, clampf(shot_charge_ratio, 0.0, 1.0)):
				state = State.SHOOTING
				return
	# Un compañero adelantado permite progresar. Los rivales nunca son receptores.
	var receiver := _find_forward_receiver(player, position, target_position)
	if is_instance_valid(receiver) and interaction.request_pass(receiver):
		selected_receiver = receiver
		state = State.PASSING


func _find_forward_receiver(player: Player, position: Vector2, target_position: Vector2) -> Player:
	var receiver: Player
	var forward := (target_position - position).normalized()
	var best_progress := maxf(minimum_pass_progress, 0.0)
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("ball_receivers"):
		var other := node as Player
		if not interaction.is_valid_receiver(other):
			continue
		var offset := other.global_position - position
		var progress := offset.dot(forward)
		# Excluir pases laterales/atrás y jugadores que ya hayan sobrepasado el objetivo.
		if progress < best_progress or other.global_position.distance_to(target_position) >= position.distance_to(target_position):
			continue
		var predicted_position := other.global_position + other.velocity * interaction.pass_prediction_time
		if not predicted_position.is_finite():
			continue
		var ball_bounds := interaction.ball.movement_bounds
		if ball_bounds.has_area():
			predicted_position = predicted_position.clamp(ball_bounds.position, ball_bounds.end)
		if not _has_clear_lane(player, interaction.ball.global_position, predicted_position):
			continue
		var distance := offset.length_squared()
		if progress > best_progress or distance < best_distance:
			receiver = other
			best_progress = progress
			best_distance = distance
	return receiver


func _has_clear_lane(player: Player, start: Vector2, end: Vector2) -> bool:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.01:
		return false
	for node in get_tree().get_nodes_in_group("players"):
		var other := node as Player
		if other == null or other == player or other.team_id == player.team_id:
			continue
		if not is_instance_valid(other.ball_interaction) or other.ball_interaction.ball != interaction.ball:
			continue
		var along := (other.global_position - start).dot(segment) / length_squared
		if along < 0.0 or along > 1.0:
			continue
		var closest := start + segment * along
		if closest.distance_to(other.global_position) <= maxf(opponent_clearance, 0.0):
			return false
	return true


func _on_action_released(kind: String, receiver: Player) -> void:
	_waiting_for_pass = kind == "pass"
	_waiting_receiver = receiver if _waiting_for_pass else null
	_waiting_ball = interaction.ball if is_instance_valid(interaction) else null
	_recovery_time_left = maxf(pass_recovery_delay if _waiting_for_pass else shot_recovery_delay, 0.0)
	_clear_possession()


func _update_recovery() -> void:
	if _recovery_time_left <= 0.0:
		_clear_recovery()
		return
	if not is_instance_valid(_waiting_ball) or is_instance_valid(_waiting_ball.carrier):
		_clear_recovery()
		return
	if _waiting_for_pass and (not is_instance_valid(_waiting_receiver) or not is_instance_valid(interaction) or not interaction.is_valid_receiver(_waiting_receiver)):
		_clear_recovery()


func _clear_recovery() -> void:
	_recovery_time_left = 0.0
	_waiting_receiver = null
	_waiting_ball = null
	_waiting_for_pass = false
	if state == State.WAITING:
		state = State.IDLE


func _clear_possession() -> void:
	_possession_time = 0.0
	_time_until_decision = 0.0
	selected_receiver = null
	destination = Vector2.ZERO
	state = State.WAITING if _recovery_time_left > 0.0 else State.IDLE
