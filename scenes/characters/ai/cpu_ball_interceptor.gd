class_name CpuBallInterceptor
extends Node
## Decide dónde puede recoger la CPU un balón libre usando su trayectoria futura.
## BallPrediction calcula la física; CpuMovement se encarga de Seek + Arrive.

enum State {IDLE, INTERCEPTING, RECOVERING, HOLDING}

const PICKUP_MARGIN := 0.75
const MAX_SLOW_DISTANCE := 4.0

@export var enabled := false
@export var ball: SoccerBall
@export var movement: CpuMovement
@export_range(0.1, 12.0, 0.1, "suffix:s") var prediction_horizon := 8.0
@export_range(0.01, 0.25, 0.01, "suffix:s") var sample_interval := 0.05
@export_range(0.02, 1.0, 0.01, "suffix:s") var replan_interval := 0.15

var state := State.IDLE
var destination := Vector2.ZERO
var prediction: Dictionary = {}
var intercept_time := 0.0

var _observed_ball: SoccerBall
var _time_until_plan := 0.0
var _slow_distance := 1.0


## Devuelve true cuando la intercepción sustituye temporalmente a la patrulla.
func update(position: Vector2, speed: float, delta: float, bounds: Rect2 = Rect2()) -> bool:
	var actor := get_parent() as Node2D
	if not enabled or not is_instance_valid(ball) or not is_instance_valid(actor):
		reset()
		return false
	_observe_ball()
	if ball.carrier == actor:
		state = State.HOLDING
		destination = position
		prediction = {}
		intercept_time = 0.0
		return true
	if is_instance_valid(ball.carrier) or ball.state == SoccerBall.State.CARRIED:
		_clear_plan()
		return false
	if not is_instance_valid(movement) or not position.is_finite() or not is_finite(speed) or speed <= 0.0:
		_clear_plan()
		return false
	if not is_finite(delta) or delta < 0.0:
		return state == State.INTERCEPTING or state == State.RECOVERING

	_time_until_plan -= delta
	intercept_time = maxf(intercept_time - delta, 0.0)
	if _time_until_plan <= 0.0:
		prediction = BallPrediction.predict(ball, maxf(prediction_horizon, 0.1), maxf(sample_interval, 0.01))
		_slow_distance = clampf(ball.pickup_radius * 0.5, 1.0, MAX_SLOW_DISTANCE)
		_select_destination(position, speed, bounds)
		_time_until_plan = maxf(replan_interval, 0.02)
	return state == State.INTERCEPTING or state == State.RECOVERING


func get_velocity(position: Vector2, speed: float, delta: float, bounds: Rect2 = Rect2()) -> Vector2:
	if state != State.INTERCEPTING and state != State.RECOVERING:
		return Vector2.ZERO
	if not enabled or not is_instance_valid(movement) or not is_instance_valid(ball):
		return Vector2.ZERO
	if not position.is_finite() or not is_finite(speed) or not is_finite(delta):
		return Vector2.ZERO
	# SEEK apunta al futuro punto de encuentro. ARRIVE frena solo en los últimos
	# píxeles: la parada habitual de 16 px impediría recoger un balón de radio 14.
	return movement.get_arrival_velocity(position, destination, speed, delta, bounds, 0.0, _slow_distance)


func reset() -> void:
	if is_instance_valid(_observed_ball):
		_observed_ball.kicked.disconnect(_on_ball_kicked)
		_observed_ball.possession_changed.disconnect(_on_possession_changed)
	_observed_ball = null
	_clear_plan()


func _observe_ball() -> void:
	if _observed_ball == ball:
		return
	reset()
	_observed_ball = ball
	_observed_ball.kicked.connect(_on_ball_kicked)
	_observed_ball.possession_changed.connect(_on_possession_changed)


func _clear_plan() -> void:
	state = State.IDLE
	destination = Vector2.ZERO
	prediction = {}
	intercept_time = 0.0
	_time_until_plan = 0.0


func _on_ball_kicked(_kind: String) -> void:
	_clear_plan()


func _on_possession_changed(_carrier: Node2D) -> void:
	_clear_plan()


func _select_destination(position: Vector2, speed: float, bounds: Rect2) -> void:
	state = State.IDLE
	intercept_time = 0.0
	var samples: Array = prediction.get("samples", [])
	for entry in samples:
		var sample: Dictionary = entry
		if not sample.get("collectible", false):
			continue
		var candidate := _reachable_destination(sample["position"], bounds)
		if candidate.is_empty():
			continue
		var travel_time := _travel_time(position.distance_to(candidate["position"]), candidate["radius"], speed)
		if travel_time <= float(sample["time"]) + 0.000001:
			destination = candidate["position"]
			intercept_time = sample["time"]
			state = State.INTERCEPTING
			return

	# Si el balón termina quieto, la oportunidad permanece aunque llegar lleve
	# más tiempo que el horizonte. Un balón aún en vuelo no permite esa suposición.
	if samples.is_empty():
		return
	var last: Dictionary = samples.back()
	var last_velocity: Vector2 = last["velocity"]
	if not last.get("collectible", false) or not last_velocity.is_zero_approx() or float(last["height"]) > 0.001:
		return
	if absf(float(last.get("height_velocity", 0.0))) >= BallMotion.REST_BOUNCE_SPEED:
		return
	var final_candidate := _reachable_destination(last["position"], bounds)
	if final_candidate.is_empty():
		return
	destination = final_candidate["position"]
	intercept_time = _travel_time(position.distance_to(destination), final_candidate["radius"], speed)
	state = State.RECOVERING


func _reachable_destination(ball_position: Vector2, bounds: Rect2) -> Dictionary:
	var point := ball_position.clamp(bounds.position, bounds.end) if bounds.has_area() else ball_position
	var radius := maxf(ball.pickup_radius - minf(PICKUP_MARGIN, ball.pickup_radius * 0.1), 0.0)
	var outside := point.distance_to(ball_position)
	if outside >= radius:
		return {}
	# Si el balón queda fuera del área del jugador, solo se admite cuando puede
	# recogerlo desde dentro. La proyección reduce el radio de llegada disponible.
	var available_radius := radius - outside
	if available_radius <= CpuMovement.ARRIVAL_TOLERANCE:
		return {}
	return {"position": point, "radius": available_radius}


func _travel_time(distance: float, radius: float, speed: float) -> float:
	if distance <= radius:
		return 0.0
	if speed <= 0.0:
		return INF
	if radius >= _slow_distance:
		return (distance - radius) / speed
	# Integrar el frenado de Arrive evita prometer una llegada demasiado rápida
	# cuando el radio disponible junto al límite es menor que la zona de frenado.
	var cruise := maxf(distance - _slow_distance, 0.0) / speed
	var slowing := _slow_distance / speed * log(minf(distance, _slow_distance) / radius)
	return cruise + slowing
