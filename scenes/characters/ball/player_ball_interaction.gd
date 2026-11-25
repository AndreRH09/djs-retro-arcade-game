class_name PlayerBallInteraction
extends Node
## Acciones con balón: posesión, carga del tiro y selección del receptor del pase.
## Player conserva la física y las animaciones; SoccerBall mueve el balón.

signal action_released(kind: String, receiver: Player)

enum ActionState {IDLE, CHARGING, KICKING}
enum Kick {SHOT, PASS}

@export var enabled: bool = true
@export var ball: SoccerBall
@export_group("Disparo")
@export_range(50.0, 600.0, 10.0, "suffix:px/s") var shot_power: float = 200.0
@export_range(0.1, 3.0, 0.1, "suffix:s") var max_charge_time: float = 1.0
@export_range(0.05, 0.5, 0.01, "suffix:s") var kick_duration: float = 0.15
@export_group("Pase")
@export_range(30.0, 600.0, 10.0, "suffix:px") var pass_range: float = 300.0
@export_range(5.0, 90.0, 1.0, "suffix:deg") var pass_half_angle: float = 70.0
## Posición futura estimada del receptor: posición + velocidad * este tiempo.
@export_range(0.0, 2.0, 0.1, "suffix:s") var pass_prediction_time: float = 1.0
@export_range(20.0, 300.0, 10.0, "suffix:px") var free_pass_distance: float = 120.0

@onready var player: Player = get_parent() as Player

var action_state: ActionState = ActionState.IDLE
var aim_direction := Vector2.RIGHT
var _charge_time := 0.0
var _kick_time_left := 0.0
var _kick: Kick = Kick.SHOT
var _shot_velocity := Vector2.ZERO
var _automatic_charge := false
var _requested_charge_time := 0.0
var _explicit_pass := false
var _requested_receiver: Player


func has_ball() -> bool:
	return enabled and is_instance_valid(ball) and ball.state == SoccerBall.State.CARRIED and ball.carrier == player


## La CPU elige el receptor; este componente comparte el golpeo con el teclado.
## Un pase solicitado a un compañero concreto nunca se redirige silenciosamente.
func request_pass(receiver: Player) -> bool:
	if not _can_start_action() or not is_valid_receiver(receiver):
		return false

	_explicit_pass = true
	_requested_receiver = receiver
	_set_aim(receiver.global_position - player.global_position)
	_begin_kick(Kick.PASS)
	return true


## La carga automática tarda el mismo tiempo y da la misma potencia que la humana.
func request_shot(direction: Vector2, charge_ratio: float = 0.5) -> bool:
	if not _can_start_action() or not direction.is_finite() or direction.is_zero_approx():
		return false
	if not is_finite(charge_ratio):
		return false

	_set_aim(direction)
	_automatic_charge = true
	_requested_charge_time = clampf(charge_ratio, 0.0, 1.0) * maxf(max_charge_time, 0.1)
	_charge_time = 0.0
	action_state = ActionState.CHARGING
	return true


func _can_start_action() -> bool:
	return has_ball() and action_state == ActionState.IDLE and player.state == Player.State.MOVING


## Devuelve true mientras una acción obliga al jugador a quedarse quieto.
func update_action(delta: float) -> bool:
	if not enabled:
		reset()
		return false
	if not has_ball():
		reset()
		if player.control_scheme != Player.ControlScheme.CPU:
			_update_aim()
		return false
	if not is_finite(delta) or delta < 0.0:
		return action_state != ActionState.IDLE

	if action_state == ActionState.KICKING:
		_kick_time_left -= delta
		if _kick_time_left <= 0.0:
			_release_ball()
		return true

	# Las órdenes automáticas conservan su dirección; solo el teclado humano la lee.
	if player.control_scheme != Player.ControlScheme.CPU and not _automatic_charge:
		_update_aim()
	if action_state == ActionState.CHARGING:
		_advance_charge(delta)
		return true

	if player.control_scheme == Player.ControlScheme.CPU:
		return false
	return _read_human_action()


func _advance_charge(delta: float) -> void:
	var charge_limit := _requested_charge_time if _automatic_charge else maxf(max_charge_time, 0.1)
	_charge_time = minf(_charge_time + delta, charge_limit)
	# Consultar si sigue pulsada también detecta un toque entre dos pasos de física.
	var release := _charge_time >= _requested_charge_time
	if not _automatic_charge:
		release = not KeyUtils.is_action_pressed(player.control_scheme, KeyUtils.Action.SHOOT)
	if release:
		# La carga aumenta gradualmente la potencia hasta el doble.
		var bonus := pow(get_charge_ratio(), 2.0)
		_shot_velocity = aim_direction * shot_power * (1.0 + bonus)
		_begin_kick(Kick.SHOT)


func _read_human_action() -> bool:
	if KeyUtils.is_action_just_pressed(player.control_scheme, KeyUtils.Action.SHOOT):
		action_state = ActionState.CHARGING
		_charge_time = 0.0
		return true
	if KeyUtils.is_action_just_pressed(player.control_scheme, KeyUtils.Action.PASS):
		_begin_kick(Kick.PASS)
		return true
	return false


func _update_aim() -> void:
	var input_direction := KeyUtils.get_input_vector(player.control_scheme)
	_set_aim(input_direction)


func _set_aim(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	aim_direction = direction.normalized()
	# La dirección de disparo es 2D; heading orienta el sprite ANTES del golpeo.
	if aim_direction.x != 0.0:
		player.heading = Vector2.RIGHT if aim_direction.x > 0.0 else Vector2.LEFT


func _begin_kick(kind: Kick) -> void:
	_kick = kind
	_kick_time_left = maxf(kick_duration, 0.05)
	action_state = ActionState.KICKING


func _release_ball() -> void:
	# Se vuelve a validar la posesión al terminar la animación de golpeo.
	if not has_ball():
		reset()
		return

	var receiver: Player
	var kind := "shot" if _kick == Kick.SHOT else "pass"
	if _kick == Kick.SHOT:
		ball.shoot(_shot_velocity)
	else:
		if _explicit_pass:
			# Un receptor eliminado, alejado o cambiado de equipo cancela el pase.
			if not is_instance_valid(_requested_receiver) or not is_valid_receiver(_requested_receiver):
				reset()
				return
			receiver = _requested_receiver
		else:
			receiver = find_pass_receiver()
		var destination := ball.global_position + aim_direction * free_pass_distance
		if receiver != null:
			# LEAD TARGETING: apuntar a la posición futura estimada del compañero.
			destination = receiver.global_position + receiver.velocity * pass_prediction_time
		ball.pass_to(destination)
	var released := is_instance_valid(ball) and ball.carrier != player
	reset()
	if released:
		action_released.emit(kind, receiver if is_instance_valid(receiver) else null)


## Se llama DESPUÉS de move_and_slide para que el balón siga la posición real.
func after_movement(delta: float) -> void:
	if not enabled or not is_instance_valid(ball):
		return
	# El cerebro puede controlar al portador antes de actualizar el interceptor.
	# Seguir los pies no depende del estado anterior de la búsqueda del balón.
	if has_ball():
		ball.follow_carrier(delta)
		return
	if player.control_scheme == Player.ControlScheme.CPU:
		var interceptor := player.cpu_interceptor
		if not is_instance_valid(interceptor) or not interceptor.enabled or interceptor.ball != ball:
			return
		if interceptor.state not in [CpuBallInterceptor.State.INTERCEPTING, CpuBallInterceptor.State.RECOVERING, CpuBallInterceptor.State.HOLDING]:
			return
	if player.state == Player.State.MOVING and action_state == ActionState.IDLE:
		ball.try_collect(player)
	if has_ball():
		ball.follow_carrier(delta)


## El equipo y el balón compartido determinan los receptores, sea humano o CPU.
func is_valid_receiver(receiver: Player) -> bool:
	if not enabled or not is_instance_valid(ball) or not is_instance_valid(receiver) or receiver == player:
		return false
	if receiver.is_queued_for_deletion() or receiver.team_id != player.team_id:
		return false
	var interaction := receiver.ball_interaction
	if not is_instance_valid(interaction) or not interaction.enabled or interaction.ball != ball:
		return false
	if receiver.control_scheme == Player.ControlScheme.CPU:
		var interceptor := receiver.cpu_interceptor
		if not is_instance_valid(interceptor) or not interceptor.enabled or interceptor.ball != ball:
			return false
	var distance := player.global_position.distance_squared_to(receiver.global_position)
	return distance > 0.01 and distance <= pass_range * pass_range


func find_pass_receiver() -> Player:
	if not enabled or not is_instance_valid(ball):
		return null
	var receiver: Player
	var nearest_distance := pass_range * pass_range
	var minimum_alignment := cos(deg_to_rad(pass_half_angle))
	for candidate in get_tree().get_nodes_in_group("ball_receivers"):
		var other := candidate as Player
		if not is_valid_receiver(other):
			continue
		var offset := other.global_position - player.global_position
		var distance := offset.length_squared()
		if distance <= 0.01 or distance > nearest_distance:
			continue
		if aim_direction.dot(offset.normalized()) < minimum_alignment:
			continue
		nearest_distance = distance
		receiver = other
	return receiver


func get_charge_ratio() -> float:
	return clampf(_charge_time / maxf(max_charge_time, 0.1), 0.0, 1.0)


func reset() -> void:
	action_state = ActionState.IDLE
	_charge_time = 0.0
	_kick_time_left = 0.0
	_shot_velocity = Vector2.ZERO
	_automatic_charge = false
	_requested_charge_time = 0.0
	_explicit_pass = false
	_requested_receiver = null
