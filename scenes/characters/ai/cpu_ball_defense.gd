class_name CpuBallDefense
extends Node
## Defensa del partido: uno marca al portador rival y otro protege la portería.
## Decide el movimiento y cuándo iniciar una entrada; el contacto está separado.

enum State {IDLE, MARKING, COVERING}

@export var enabled := false
@export var ball: SoccerBall
@export var movement: CpuMovement
@export var defended_goal: Node2D
@export_group("Posición defensiva")
## Distancia entre el marcador y el rival, por el lado de nuestra portería.
@export_range(4.0, 64.0, 1.0, "suffix:px") var marking_distance := 18.0
## El segundo defensor se coloca más atrás para cubrir el camino a portería.
@export_range(24.0, 200.0, 1.0, "suffix:px") var covering_distance := 90.0
## Otro defensor debe estar claramente más cerca antes de intercambiar papeles.
@export_range(0.0, 100.0, 1.0, "suffix:px") var handoff_margin := 28.0
@export_range(4.0, 64.0, 1.0, "suffix:px") var slow_distance := 24.0

var state := State.IDLE
var destination := Vector2.ZERO
var carrier: Player
var marker: Player

var _time_until_observation := 0.0
var _has_observation := false
var _observed_position := Vector2.ZERO
var _target_offset := Vector2.ZERO
var _active_difficulty: CpuDifficulty
var _random := RandomNumberGenerator.new()
var _tackle_reaction_time := 0.0


## La defensa sustituye la patrulla solo mientras un rival lleva el balón.
## Al quedar libre, Player vuelve a usar la intercepción de su trayectoria.
func update(position: Vector2, speed: float, delta: float, bounds: Rect2 = Rect2()) -> bool:
	var player := get_parent() as Player
	if not _can_defend(player) or ball.goal_team >= 0:
		reset()
		return false
	var opponent := ball.carrier as Player
	if ball.state != SoccerBall.State.CARRIED or not is_instance_valid(opponent) or opponent.team_id == player.team_id:
		reset()
		return false
	if not position.is_finite() or not opponent.global_position.is_finite() or not is_finite(speed) or speed <= 0.0:
		reset()
		return false
	if not is_finite(delta) or delta < 0.0:
		return state != State.IDLE

	_assign_marker(player, opponent)
	var profile := movement.difficulty if movement.difficulty != null else CpuMovement.DEFAULT_DIFFICULTY
	if _active_difficulty != profile:
		_active_difficulty = profile
		_has_observation = false
	_time_until_observation -= delta
	if not _has_observation or _time_until_observation <= 0.0:
		_observe_carrier(position, speed, bounds)
		_time_until_observation = maxf(profile.decision_interval, 0.02)
	_consider_tackle(player, delta, profile)
	return state != State.IDLE


func get_velocity(position: Vector2, speed: float, delta: float, bounds: Rect2 = Rect2()) -> Vector2:
	if state == State.IDLE or not _can_defend(get_parent() as Player):
		return Vector2.ZERO
	if not is_instance_valid(carrier) or ball.carrier != carrier or ball.goal_team >= 0:
		return Vector2.ZERO
	if not position.is_finite() or not destination.is_finite() or not is_finite(speed) or not is_finite(delta):
		return Vector2.ZERO
	# SEEK acerca al destino defensivo; ARRIVE frena al ocupar esa posición.
	# El nivel cambia reacción y anticipación, sin aumentar la velocidad base.
	return movement.get_arrival_velocity(position, destination, speed, delta, bounds, 0.0, maxf(slow_distance, 4.0))


func reset() -> void:
	state = State.IDLE
	destination = Vector2.ZERO
	carrier = null
	marker = null
	_time_until_observation = 0.0
	_has_observation = false
	_observed_position = Vector2.ZERO
	_target_offset = Vector2.ZERO
	_active_difficulty = null
	_tackle_reaction_time = 0.0


func _consider_tackle(player: Player, delta: float, profile: CpuDifficulty) -> void:
	var tackle := player.ball_tackle
	if state != State.MARKING or not is_instance_valid(tackle) or not tackle.can_start():
		_tackle_reaction_time = 0.0
		return
	if player.global_position.distance_to(ball.global_position) > tackle.approach_distance:
		_tackle_reaction_time = 0.0
		return
	# Easy espera más antes de entrar; Hard reacciona antes. Todos deben acercarse.
	_tackle_reaction_time += delta
	if _tackle_reaction_time < maxf(profile.decision_interval, 0.12):
		return
	_tackle_reaction_time = 0.0
	player.start_tackle(ball.global_position - player.global_position)


func _can_defend(player: Player) -> bool:
	return (
		enabled and is_instance_valid(player) and is_instance_valid(ball)
		and is_instance_valid(movement) and is_instance_valid(defended_goal)
		and defended_goal.global_position.is_finite()
		and player.control_scheme == Player.ControlScheme.CPU
		and player.is_physics_processing() and is_finite(player.speed) and player.speed > 0.0
		and player.state in [Player.State.MOVING, Player.State.TACKLING]
		and is_instance_valid(player.ball_interaction) and player.ball_interaction.enabled
		and player.ball_interaction.ball == ball and player.global_position.is_finite()
	)


func _assign_marker(player: Player, opponent: Player) -> void:
	var defenders: Array[CpuBallDefense] = []
	var nearest: Player
	var nearest_distance := INF
	var incumbent: Player
	var switch_margin := 0.0
	for node in get_tree().get_nodes_in_group("players"):
		var other := node as Player
		if other == null or other.team_id != player.team_id:
			continue
		var defense := other.get_node_or_null("CpuBallDefense") as CpuBallDefense
		if defense == null or defense.ball != ball or not defense._can_defend(other):
			continue
		defenders.append(defense)
		switch_margin = maxf(switch_margin, maxf(defense.handoff_margin, 0.0))
		var distance := other.global_position.distance_to(opponent.global_position)
		if distance < nearest_distance or (is_equal_approx(distance, nearest_distance) and other.get_instance_id() < nearest.get_instance_id()):
			nearest = other
			nearest_distance = distance

	# Reusar el marcador anterior evita que ambos alternen al estar casi empatados.
	for defense in defenders:
		if defense.carrier != opponent or not is_instance_valid(defense.marker):
			continue
		for candidate in defenders:
			if candidate.get_parent() == defense.marker:
				incumbent = defense.marker
				break
		if incumbent != null:
			break
	if incumbent != null and incumbent.global_position.distance_to(opponent.global_position) <= nearest_distance + switch_margin:
		nearest = incumbent

	# Compartir la elección en el mismo tick garantiza un único marcador por equipo.
	for defense in defenders:
		if defense.carrier != opponent or defense.marker != nearest:
			defense._time_until_observation = 0.0
			defense._has_observation = false
		defense.carrier = opponent
		defense.marker = nearest
		defense.state = State.MARKING if defense.get_parent() == nearest else State.COVERING


func _observe_carrier(position: Vector2, speed: float, bounds: Rect2) -> void:
	var profile := movement.difficulty if movement.difficulty != null else CpuMovement.DEFAULT_DIFFICULTY
	var observed := carrier.global_position
	# Mantener el error cuando el rival está quieto evita un temblor permanente.
	if not _has_observation or not observed.is_equal_approx(_observed_position):
		_target_offset = Vector2.from_angle(_random.randf_range(-PI, PI)) * sqrt(_random.randf()) * maxf(profile.target_error, 0.0)
	# PURSUIT anticipa al portador: Easy usa Seek directo; Normal/Hard se adelantan.
	var prediction := minf(maxf(profile.prediction_time, 0.0), position.distance_to(observed) / speed)
	var carrier_velocity := carrier.velocity if carrier.velocity.is_finite() else Vector2.ZERO
	var predicted := observed + carrier_velocity * prediction
	var goal_offset := defended_goal.global_position - predicted
	var separation := maxf(marking_distance, 0.0)
	if state == State.COVERING:
		separation = maxf(covering_distance, marking_distance)
	# No sobrepasar la portería cuando el atacante llega cerca de la línea de gol.
	separation = minf(separation, goal_offset.length() * 0.65)
	destination = predicted + goal_offset.normalized() * separation + _target_offset
	if bounds.has_area():
		destination = destination.clamp(bounds.position, bounds.end)
	_observed_position = observed
	_has_observation = true
