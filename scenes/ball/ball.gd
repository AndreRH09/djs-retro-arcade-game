class_name SoccerBall
extends Node2D
## Balón del prototipo: conducción, disparo bajo y pase raso con fricción.
## La posición del nodo representa el suelo; height solo eleva el sprite.

signal possession_changed(new_carrier: Node2D)
signal kicked(kind: String)
signal goal_scored(scoring_team: int)

enum State {FREE, CARRIED, SHOT}

@export var movement_bounds := Rect2(78.0, 52.0, 694.0, 282.0)
@export_range(0.0, 1000.0, 1.0) var ground_friction := 250.0
@export_range(0.0, 1000.0, 1.0) var air_friction := 35.0
@export_range(0.0, 2000.0, 1.0) var gravity := 600.0
@export_range(0.0, 0.95, 0.01) var bounce := 0.8
@export_range(1.0, 64.0, 1.0) var pickup_radius := 14.0
@export_range(0.0, 64.0, 1.0) var pickup_height := 8.0
@export_range(0.0, 2.0, 0.01) var pickup_delay := 0.25
@export_range(0.0, 3.0, 0.05) var shot_duration := 1.0
## v0.2.4 mantiene el disparo a 5 px sobre el césped y luego lo deja caer.
@export_range(0.0, 100.0, 1.0) var shot_height := 5.0
@export_range(1.0, 64.0, 1.0) var steal_reach := 24.0
## Una recuperación no puede devolverse al rival en el mismo choque.
@export_range(0.0, 2.0, 0.05) var steal_protection_duration := 0.6

var carrier: Node2D
var velocity := Vector2.ZERO
var height := 0.0
var height_velocity := 0.0
var state := State.FREE
## Vacío en entrenamiento. MatchController configura las dos bocas de portería.
var goal_openings: Array[Dictionary] = []
var goal_team := -1

var _last_carrier: Node2D
var _pickup_time_left := 0.0
var _shot_time_left := 0.0
var _roll_distance := 0.0
var _last_follow_position := Vector2.ZERO
var _steal_protection_left := 0.0
var _possession_revision := 0

@onready var _ball_sprite: Sprite2D = get_node_or_null("BallSprite")
@onready var _shadow_sprite: Sprite2D = get_node_or_null("ShadowSprite")


func _physics_process(delta: float) -> void:
	if delta <= 0.0 or goal_team >= 0:
		return
	_pickup_time_left = maxf(_pickup_time_left - delta, 0.0)
	_steal_protection_left = maxf(_steal_protection_left - delta, 0.0)
	if state == State.CARRIED:
		if is_instance_valid(carrier):
			follow_carrier(delta)
		else:
			_release_carrier()
			state = State.FREE
			possession_changed.emit(null)
	else:
		# La simulación real y el pronóstico usan exactamente las mismas reglas.
		var result := BallMotion.advance(get_motion_snapshot(), get_motion_settings(), delta)
		var next: Dictionary = result["snapshot"]
		global_position = next["position"]
		velocity = next["velocity"]
		height = next["height"]
		height_velocity = next["height_velocity"]
		_shot_time_left = next["shot_time_left"]
		state = State.SHOT if next["shot_active"] else State.FREE
		_roll_distance += result["distance"]
		if next.get("goal_team", -1) >= 0:
			_finish_goal(next["goal_team"])
	_update_visuals()


func try_collect(player: Node2D) -> bool:
	if goal_team >= 0 or not is_instance_valid(player) or player == self:
		return false
	if state != State.FREE or height > pickup_height:
		return false
	# Solo el último portador espera; el compañero puede recibir el pase de inmediato.
	if _pickup_time_left > 0.0 and is_instance_valid(_last_carrier) and player == _last_carrier:
		return false
	if global_position.distance_to(player.global_position) > pickup_radius:
		return false
	_take_possession(player)
	return true


func try_steal(new_carrier: Node2D, expected_carrier: Node2D) -> bool:
	# TRANSFERENCIA ATÓMICA: solo el rival que sigue llevando el balón puede perderlo.
	# El componente de entrada comprueba la dirección y el contacto antes de llamar.
	if goal_team >= 0 or state != State.CARRIED or _steal_protection_left > 0.0:
		return false
	if not is_instance_valid(carrier) or carrier != expected_carrier:
		return false
	if not new_carrier is Player or not carrier is Player or new_carrier == carrier:
		return false
	if (new_carrier as Player).team_id == (carrier as Player).team_id:
		return false
	if new_carrier.global_position.distance_to(global_position) > steal_reach:
		return false
	_last_carrier = carrier
	_pickup_time_left = maxf(pickup_delay, 0.0)
	_steal_protection_left = maxf(steal_protection_duration, 0.0)
	_take_possession(new_carrier)
	return true


func _take_possession(player: Node2D) -> void:
	_possession_revision += 1
	var revision := _possession_revision
	carrier = player
	state = State.CARRIED
	velocity = Vector2.ZERO
	height = 0.0
	height_velocity = 0.0
	_last_follow_position = player.global_position
	follow_carrier(0.0)
	# Un gol puede reiniciar el saque durante follow_carrier; no repetir la señal
	# de esa nueva posesión al volver a esta llamada anterior.
	if goal_team < 0 and _possession_revision == revision:
		possession_changed.emit(carrier)


func follow_carrier(_delta: float) -> void:
	if goal_team >= 0 or state != State.CARRIED or not is_instance_valid(carrier):
		return
	# CONDUCCIÓN: el balón acompaña los pies; el pequeño bote depende del recorrido.
	_roll_distance += carrier.global_position.distance_to(_last_follow_position)
	_last_follow_position = carrier.global_position
	var heading := Vector2.RIGHT
	var carrier_heading: Variant = carrier.get("heading")
	if carrier_heading is Vector2 and not (carrier_heading as Vector2).is_zero_approx():
		heading = carrier_heading
	var horizontal_sign := -1.0 if heading.x < 0.0 else 1.0
	var previous_position := global_position
	var previous_height := height
	var destination := carrier.global_position + Vector2(horizontal_sign * 10.0, 4.0)
	var carrier_velocity: Variant = carrier.get("velocity")
	velocity = carrier_velocity if carrier_velocity is Vector2 else Vector2.ZERO
	height = absf(sin(_roll_distance * 0.22)) * 2.0 if velocity.length_squared() > 1.0 else 0.0
	height_velocity = 0.0
	global_position = BallGoals.clamp_carried(destination, height, movement_bounds, goal_openings)
	var crossing := BallGoals.carried_crossing(previous_position, global_position, previous_height, height, goal_openings)
	if not crossing.is_empty():
		global_position = crossing["position"]
		height = crossing["height"]
		_finish_goal(crossing["goal_team"])
	_update_visuals()


func shoot(shot_velocity: Vector2) -> void:
	if goal_team >= 0 or state != State.CARRIED or not is_instance_valid(carrier):
		return
	_release_carrier()
	velocity = shot_velocity
	height = maxf(shot_height, 0.0)
	height_velocity = 0.0
	_shot_time_left = maxf(shot_duration, 0.0)
	state = State.SHOT
	possession_changed.emit(null)
	kicked.emit("shot")
	_update_visuals()


func pass_to(destination: Vector2) -> void:
	if goal_team >= 0 or state != State.CARRIED or not is_instance_valid(carrier):
		return
	# PASE RASO: calcular desde el balón, porque está por delante de los pies.
	var displacement := _clamp_to_pitch(destination) - global_position
	_release_carrier()
	velocity = displacement.normalized() * BallTrajectory.ground_pass_speed(displacement.length(), ground_friction)
	height = 0.0
	height_velocity = 0.0
	state = State.FREE
	possession_changed.emit(null)
	kicked.emit("pass")
	_update_visuals()


func reset_to(ground_position: Vector2) -> void:
	_possession_revision += 1
	var had_carrier := state == State.CARRIED
	carrier = null
	_last_carrier = null
	_pickup_time_left = 0.0
	_shot_time_left = 0.0
	_roll_distance = 0.0
	_steal_protection_left = 0.0
	velocity = Vector2.ZERO
	height = 0.0
	height_velocity = 0.0
	state = State.FREE
	goal_team = -1
	global_position = _clamp_to_pitch(ground_position)
	_update_visuals()
	if had_carrier:
		possession_changed.emit(null)


func _release_carrier() -> void:
	_possession_revision += 1
	_last_carrier = carrier if is_instance_valid(carrier) else null
	_pickup_time_left = maxf(pickup_delay, 0.0)
	carrier = null


func _finish_goal(scoring_team: int) -> void:
	if goal_team >= 0:
		return
	_possession_revision += 1
	var had_carrier := is_instance_valid(carrier)
	carrier = null
	velocity = Vector2.ZERO
	height_velocity = 0.0
	_shot_time_left = 0.0
	state = State.FREE
	goal_team = scoring_team
	if had_carrier:
		possession_changed.emit(null)
	goal_scored.emit(scoring_team)


func get_motion_snapshot() -> Dictionary:
	# Copia de valores: predecir nunca mueve el nodo ni cambia la posesión.
	return {
		"position": global_position,
		"velocity": velocity,
		"height": height,
		"height_velocity": height_velocity,
		"shot_active": state == State.SHOT,
		"shot_time_left": _shot_time_left,
		"goal_team": goal_team,
	}


func get_motion_settings() -> Dictionary:
	return {
		"bounds": movement_bounds,
		"ground_friction": ground_friction,
		"air_friction": air_friction,
		"gravity": gravity,
		"bounce": bounce,
		"goal_openings": goal_openings.duplicate(true),
	}


func _clamp_to_pitch(ground_position: Vector2) -> Vector2:
	if movement_bounds.has_area():
		return ground_position.clamp(movement_bounds.position, movement_bounds.end)
	return ground_position


func _update_visuals() -> void:
	if not is_instance_valid(_ball_sprite):
		return
	_ball_sprite.position.y = -height
	_ball_sprite.frame = int(_roll_distance / 4.0) % 4
	_ball_sprite.scale.y = 0.8 if state == State.SHOT else 1.0
	# El balón en el aire aparece por encima del jugador; la sombra sigue sobre el césped.
	_ball_sprite.z_index = 2 if height > pickup_height else 0
	if is_instance_valid(_shadow_sprite):
		_shadow_sprite.modulate.a = clampf(1.0 - height / 100.0, 0.35, 1.0)
