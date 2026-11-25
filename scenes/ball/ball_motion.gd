class_name BallMotion
extends RefCounted
## Física pura compartida por SoccerBall y BallPrediction.
## Solo transforma copias de valores; no accede a nodos ni emite señales.

const TIME_EPSILON := 0.000001
const REST_BOUNCE_SPEED := 24.0


static func advance(snapshot: Dictionary, settings: Dictionary, delta: float) -> Dictionary:
	var next := snapshot.duplicate()
	var result := {"snapshot": next, "impacts": [], "distance": 0.0}
	if next.get("goal_team", -1) >= 0:
		return result
	var remaining := maxf(delta, 0.0)
	var elapsed := 0.0
	if next["shot_active"]:
		# El disparo arcade conserva altura y velocidad durante el impulso restante.
		var shot_step := minf(remaining, maxf(next["shot_time_left"], 0.0))
		var used_step := _move_planar(next, settings, shot_step, 0.0, result, 0.0, true)
		if next.get("goal_team", -1) >= 0:
			return result
		remaining -= used_step
		elapsed += used_step
		next["shot_time_left"] = maxf(next["shot_time_left"] - used_step, 0.0)
		# v0.2.4: un disparo pierde el impulso al chocar y empieza a caer.
		if result.get("wall_bounced", false) or next["shot_time_left"] <= TIME_EPSILON:
			next["shot_active"] = false
			next["shot_time_left"] = 0.0
	if not next["shot_active"]:
		_advance_free(next, settings, remaining, elapsed, result)
	return result


static func _advance_free(next: Dictionary, settings: Dictionary, remaining: float, elapsed: float, result: Dictionary) -> void:
	var gravity := maxf(settings["gravity"], 0.0)
	# Resolver cada impacto evita depender de la frecuencia de actualización.
	while remaining > TIME_EPSILON:
		if next["height"] <= 0.0 and absf(next["height_velocity"]) < REST_BOUNCE_SPEED:
			next["height"] = 0.0
			next["height_velocity"] = 0.0
			_move_planar(next, settings, remaining, settings["ground_friction"], result)
			if next.get("goal_team", -1) >= 0:
				result["goal_time"] += elapsed
			return
		var impact_time := time_to_ground(next["height"], next["height_velocity"], gravity)
		var step := minf(remaining, impact_time)
		var used_step := _move_planar(next, settings, step, settings["air_friction"], result, gravity)
		if next.get("goal_team", -1) >= 0:
			next["height"] += next["height_velocity"] * used_step - 0.5 * gravity * used_step * used_step
			next["height_velocity"] = 0.0
			result["goal_time"] += elapsed
			return
		next["height"] += next["height_velocity"] * step - 0.5 * gravity * step * step
		next["height_velocity"] -= gravity * step
		remaining -= step
		elapsed += step
		if impact_time > step:
			return
		next["height"] = 0.0
		var restitution := clampf(settings["bounce"], 0.0, 1.0)
		next["height_velocity"] = absf(next["height_velocity"]) * restitution
		# REBOTE: como en v0.2.4, cada contacto disipa también velocidad horizontal.
		# Resolverlo aquí mantiene la predicción de la CPU igual al balón visible.
		next["velocity"] *= restitution
		# Tiempo exacto dentro del paso, no redondeado al intervalo del pronóstico.
		result["impacts"].append({"position": next["position"], "time": elapsed})


static func time_to_ground(height: float, height_velocity: float, gravity: float) -> float:
	if gravity <= 0.0:
		return maxf(height, 0.0) / -height_velocity if height_velocity < 0.0 else INF
	return maxf((height_velocity + sqrt(height_velocity * height_velocity + 2.0 * gravity * maxf(height, 0.0))) / gravity, 0.0)


static func _move_planar(next: Dictionary, settings: Dictionary, delta: float, friction: float, result: Dictionary, gravity: float = 0.0, stop_at_bounce: bool = false) -> float:
	var configured_bounds: Rect2 = settings["bounds"]
	if configured_bounds.has_area():
		var movement := BallGoals.advance(next, settings, delta, friction, gravity, stop_at_bounce)
		next["position"] = movement["position"]
		next["velocity"] = movement["velocity"]
		next["goal_team"] = movement["goal_team"]
		result["distance"] += movement["distance"]
		result["wall_bounced"] = result.get("wall_bounced", false) or movement["bounced"]
		if next["goal_team"] >= 0:
			next["shot_active"] = false
			next["shot_time_left"] = 0.0
			result["goal_time"] = movement["time"]
		return movement["time"]
	var step := BallTrajectory.ground_step(next["velocity"], friction, delta)
	var displacement: Vector2 = step["displacement"]
	var position: Vector2 = next["position"] + displacement
	var velocity: Vector2 = step["velocity"]
	result["distance"] += displacement.length()
	next["position"] = position
	next["velocity"] = velocity
	return delta
