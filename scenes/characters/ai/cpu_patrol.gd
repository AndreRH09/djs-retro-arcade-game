class_name CpuPatrol
extends Node
## Decide QUÉ hacer. CpuMovement calcula la velocidad y Player aplica la física.

enum State {PATROLLING, PRESSING, RETURNING}

@export var enabled: bool = false
@export var movement: CpuMovement
@export var route: CpuPatrolRoute

@export_group("Patrulla")
## Fracción de la velocidad del jugador al recorrer la ruta.
@export_range(0.1, 1.0, 0.05) var patrol_speed_ratio: float = 0.6
@export_range(1.0, 16.0, 0.5, "suffix:px") var waypoint_tolerance: float = 4.0
@export_range(2.0, 64.0, 1.0, "suffix:px") var waypoint_slow_distance: float = 16.0
## Si otro jugador bloquea el paso, prueba el siguiente punto de la ruta.
@export_range(0.2, 5.0, 0.1, "suffix:s") var blocked_waypoint_timeout: float = 1.0

@export_group("Presión")
## Distancia CPU-objetivo necesaria para salir a presionar.
@export_range(1.0, 300.0, 1.0, "suffix:px") var detection_radius: float = 40.0
## Debe ser mayor que Detection Radius para evitar cambios continuos de estado.
@export_range(2.0, 400.0, 1.0, "suffix:px") var release_radius: float = 64.0
## Distancia máxima desde el centro de la ruta durante la presión.
@export_range(1.0, 400.0, 1.0, "suffix:px") var zone_radius: float = 85.0
## Al agotarse este tiempo, regresa aunque el objetivo siga cerca.
@export_range(0.1, 20.0, 0.1, "suffix:s") var max_press_time: float = 4.0
## Tiempo sin iniciar otra presión, contado desde la llegada a la ruta.
@export_range(0.0, 10.0, 0.1, "suffix:s") var reengage_delay: float = 1.5

var state: State = State.PATROLLING
var waypoint_index := 0
var destination := Vector2.ZERO

var _active_route: CpuPatrolRoute
var _initialized := false
var _decision_left := 0.0
var _cooldown_left := 0.0
var _press_elapsed := 0.0
var _tracked_waypoint := -1
var _best_waypoint_distance := INF
var _stalled_elapsed := 0.0


func get_velocity(
	position: Vector2, speed: float, delta: float, bounds: Rect2 = Rect2()
) -> Vector2:
	if not is_instance_valid(movement):
		return Vector2.ZERO
	if not enabled:
		if _initialized:
			reset()
		return movement.get_velocity(position, speed, delta, bounds)
	if not is_instance_valid(route):
		reset()
		return Vector2.ZERO

	var points := route.get_waypoint_positions()
	# Llegada y dirección usan el MISMO punto limitado a la cancha.
	if bounds.has_area():
		for index in range(points.size()):
			points[index] = points[index].clamp(bounds.position, bounds.end)
	if points.is_empty():
		reset()
		return Vector2.ZERO
	if delta <= 0.0 or speed <= 0.0:
		return Vector2.ZERO
	if not _initialized or route != _active_route:
		reset()
		_initialized = true
		_active_route = route
		waypoint_index = _nearest_waypoint(position, points)
	elif waypoint_index >= points.size():
		waypoint_index = _nearest_waypoint(position, points)

	_update_state(position, points, delta)
	if state == State.PRESSING:
		return _get_pressure_velocity(position, speed, delta, bounds)
	return _get_waypoint_velocity(position, speed, delta, bounds, points)


func _update_state(position: Vector2, points: Array[Vector2], delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_decision_left -= delta
	if state == State.PRESSING:
		_press_elapsed += delta
		# Estos límites se revisan cada paso para no abandonar la zona de defensa.
		if (
			not _has_target()
			or _press_elapsed >= maxf(max_press_time, 0.1)
			or position.distance_to(route.global_position) >= zone_radius
		):
			_start_return(position, points)
		elif _decision_left <= 0.0:
			_restart_decision_timer()
			if _should_release(position):
				_start_return(position, points)
	elif state == State.PATROLLING and _cooldown_left <= 0.0 and _decision_left <= 0.0:
		_restart_decision_timer()
		if _can_press(position):
			_change_state(State.PRESSING)
			_press_elapsed = 0.0


func _get_pressure_velocity(
	position: Vector2, speed: float, delta: float, bounds: Rect2
) -> Vector2:
	# SEEK / PURSUIT + ARRIVE: reutiliza la reacción y precisión Easy/Normal/Hard.
	destination = movement.target.global_position
	var velocity := movement.get_velocity(position, speed, delta, bounds)
	# Limita incluso un paso largo o una predicción que apunte fuera de la zona.
	var next_position := position + velocity * delta
	var offset := next_position - route.global_position
	if offset.length() > zone_radius:
		next_position = route.global_position + offset.limit_length(zone_radius)
	return (next_position - position) / delta


func _get_waypoint_velocity(
	position: Vector2, speed: float, delta: float, bounds: Rect2, points: Array[Vector2]
) -> Vector2:
	destination = points[waypoint_index]
	var distance := position.distance_to(destination)
	if distance <= maxf(waypoint_tolerance, CpuMovement.ARRIVAL_TOLERANCE):
		if state == State.RETURNING:
			_finish_return()
		# PATH FOLLOWING: al llegar, continúa con el siguiente waypoint en bucle.
		_advance_waypoint(points)
	elif _waypoint_is_blocked(distance, delta):
		# Una colisión no debe dejar a la CPU intentando regresar para siempre.
		if points.size() == 1 and state == State.RETURNING:
			_finish_return()
		_advance_waypoint(points)

	# SEEK + ARRIVE: puntos exactos, sin el error de puntería usado al presionar.
	var travel_speed := speed
	if state == State.PATROLLING:
		travel_speed *= clampf(patrol_speed_ratio, 0.1, 1.0)
	return movement.get_arrival_velocity(
		position, destination, travel_speed, delta, bounds, 0.0, waypoint_slow_distance
	)


func _has_target() -> bool:
	return is_instance_valid(movement.target) and movement.target != get_parent()


func _can_press(position: Vector2) -> bool:
	return (
		_has_target()
		and position.distance_to(movement.target.global_position) <= detection_radius
		and position.distance_to(route.global_position) < zone_radius
		and movement.target.global_position.distance_to(route.global_position) <= zone_radius
	)


func _should_release(position: Vector2) -> bool:
	# HISTÉRESIS: salir exige más distancia que entrar; evita alternar en el borde.
	var release_distance := maxf(release_radius, detection_radius + 1.0)
	return (
		position.distance_to(movement.target.global_position) > release_distance
		or movement.target.global_position.distance_to(route.global_position) > zone_radius
	)


func _restart_decision_timer() -> void:
	var profile := movement.difficulty if movement.difficulty != null else CpuMovement.DEFAULT_DIFFICULTY
	_decision_left = maxf(profile.decision_interval, 0.02)


func _start_return(position: Vector2, points: Array[Vector2]) -> void:
	# REGRESO: elige el waypoint más cercano e ignora al rival hasta alcanzarlo.
	_change_state(State.RETURNING)
	waypoint_index = _nearest_waypoint(position, points)


func _finish_return() -> void:
	_change_state(State.PATROLLING)
	_cooldown_left = maxf(reengage_delay, 0.0)


func _advance_waypoint(points: Array[Vector2]) -> void:
	waypoint_index = (waypoint_index + 1) % points.size()
	destination = points[waypoint_index]
	_tracked_waypoint = -1


func _waypoint_is_blocked(distance: float, delta: float) -> bool:
	if _tracked_waypoint != waypoint_index or distance < _best_waypoint_distance - 0.5:
		_tracked_waypoint = waypoint_index
		_best_waypoint_distance = distance
		_stalled_elapsed = 0.0
	else:
		_stalled_elapsed += delta
	return _stalled_elapsed >= maxf(blocked_waypoint_timeout, 0.2)


func _nearest_waypoint(position: Vector2, points: Array[Vector2]) -> int:
	var nearest := 0
	for index in range(1, points.size()):
		if position.distance_squared_to(points[index]) < position.distance_squared_to(points[nearest]):
			nearest = index
	return nearest


func _change_state(next_state: State) -> void:
	state = next_state
	_tracked_waypoint = -1
	# Evita reutilizar una observación anterior al volver a presionar.
	movement.reset()


func reset() -> void:
	state = State.PATROLLING
	waypoint_index = 0
	destination = Vector2.ZERO
	_active_route = null
	_initialized = false
	_decision_left = 0.0
	_cooldown_left = 0.0
	_press_elapsed = 0.0
	_tracked_waypoint = -1
	_best_waypoint_distance = INF
	_stalled_elapsed = 0.0
	if is_instance_valid(movement):
		movement.reset()
