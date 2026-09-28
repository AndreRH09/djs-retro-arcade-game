class_name CpuMovement
extends Node
## Combina Seek + Arrive y agrega Pursuit cuando el perfil permite anticipación.

const DEFAULT_DIFFICULTY: CpuDifficulty = preload("res://scenes/characters/ai/normal.tres")
const ARRIVAL_TOLERANCE := 0.5

@export var target: Node2D
@export var difficulty: CpuDifficulty = DEFAULT_DIFFICULTY
## Distance from the destination at which the CPU stops.
@export_range(1.0, 64.0, 0.5, "suffix:px") var stop_distance: float = 16.0
## Distance at which arrival starts reducing the movement speed.
@export_range(2.0, 128.0, 0.5, "suffix:px") var slow_distance: float = 48.0

var _observed_target: Node2D
var _active_difficulty: CpuDifficulty
var _time_until_observation := 0.0
var _observation_elapsed := 0.0
var _has_observation := false
var _observed_position := Vector2.ZERO
var _destination := Vector2.ZERO
var _target_offset := Vector2.ZERO
var _random := RandomNumberGenerator.new()


func get_velocity(
	position: Vector2, speed: float, delta: float, bounds: Rect2 = Rect2()
) -> Vector2:
	if not is_instance_valid(target) or target == get_parent():
		reset()
		return Vector2.ZERO
	if delta <= 0.0 or speed <= 0.0:
		return Vector2.ZERO

	var profile := difficulty if difficulty != null else DEFAULT_DIFFICULTY
	if target != _observed_target or profile != _active_difficulty:
		reset()
		_observed_target = target
		_active_difficulty = profile

	# DIFICULTAD: regula cuándo observar al objetivo, no la velocidad del personaje.
	_time_until_observation -= delta
	_observation_elapsed += delta
	if not _has_observation or _time_until_observation <= 0.0:
		observe_target(position, speed, profile, bounds)
		_time_until_observation = maxf(profile.decision_interval, 0.02)
		_observation_elapsed = 0.0

	# Entre observaciones se sigue el último destino calculado.
	var destination := _destination
	if bounds.has_area():
		destination = destination.clamp(bounds.position, bounds.end)
	
	# SEEK: calcular la dirección desde la CPU hacia el destino.
	var displacement := destination - position
	var distance := displacement.length()
	
	# ARRIVE: detenerse al alcanzar la distancia de parada.
	var remaining_distance := distance - stop_distance
	if remaining_distance <= ARRIVAL_TOLERANCE:
		return Vector2.ZERO

	# ARRIVE: reducir la velocidad progresivamente al acercarse.
	var slowing_range := maxf(slow_distance - stop_distance, 1.0)
	var arrival_speed := speed * clampf(remaining_distance / slowing_range, 0.0, 1.0)
	
	# Evitar sobrepasar la distancia de parada en un paso de física largo.
	arrival_speed = minf(arrival_speed, remaining_distance / delta)
	
	# SEEK + ARRIVE: dirección normalizada multiplicada por la velocidad de llegada.
	return displacement / distance * arrival_speed


func observe_target(position: Vector2, speed: float, profile: CpuDifficulty, bounds: Rect2) -> void:
	var target_position := target.global_position
	var target_velocity := Vector2.ZERO
	if target is CharacterBody2D:
		target_velocity = (target as CharacterBody2D).velocity
	elif target is RigidBody2D:
		target_velocity = (target as RigidBody2D).linear_velocity
	elif _has_observation and _observation_elapsed > 0.0:
		target_velocity = (target_position - _observed_position) / _observation_elapsed

	# PRECISIÓN: añadir error según el nivel y conservarlo si el objetivo está quieto.
	if not _has_observation or not target_position.is_equal_approx(_observed_position):
		var angle := _random.randf_range(-PI, PI)
		var radius := sqrt(_random.randf()) * maxf(profile.target_error, 0.0)
		_target_offset = Vector2.from_angle(angle) * radius

	# PURSUIT: estimar un destino futuro usando la velocidad observada del objetivo.
	# La anticipación disminuye cerca del objetivo; en easy vale 0 (Seek directo).
	var distance := maxf(position.distance_to(target_position) - stop_distance, 0.0)
	var prediction := minf(maxf(profile.prediction_time, 0.0), distance / speed)
	_destination = target_position + target_velocity * prediction + _target_offset
	
	# LÍMITES: mantener el destino previsto dentro de la zona de movimiento.
	if bounds.has_area():
		_destination = _destination.clamp(bounds.position, bounds.end)
	_observed_position = target_position
	_has_observation = true


func reset() -> void:
	_observed_target = null
	_active_difficulty = null
	_time_until_observation = 0.0
	_observation_elapsed = 0.0
	_has_observation = false
	_target_offset = Vector2.ZERO
