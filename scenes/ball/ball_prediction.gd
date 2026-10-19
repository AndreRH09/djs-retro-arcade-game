class_name BallPrediction
extends RefCounted
## Pronóstico del recorrido y de la primera caída futura de un balón libre.
## La CPU puede consultar las muestras bajas para elegir dónde interceptarlo.

const MAX_HORIZON := 12.0
const MIN_SAMPLE_INTERVAL := 1.0 / 120.0
const MAX_SAMPLE_INTERVAL := 0.25


static func predict(ball: SoccerBall, horizon: float = 8.0, sample_interval: float = 0.05) -> Dictionary:
	var samples: Array[Dictionary] = []
	var landing: Dictionary = {}
	var prediction := {"samples": samples, "landing": landing}
	if not is_instance_valid(ball) or ball.state == SoccerBall.State.CARRIED:
		return prediction
	var duration := clampf(horizon, 0.0, MAX_HORIZON) if is_finite(horizon) else 8.0
	var interval := clampf(sample_interval, MIN_SAMPLE_INTERVAL, MAX_SAMPLE_INTERVAL) if is_finite(sample_interval) else 0.05
	var snapshot := ball.get_motion_snapshot()
	var settings := ball.get_motion_settings()
	var elapsed := 0.0
	samples.append(_make_sample(snapshot, elapsed, ball.pickup_height))
	if snapshot.get("goal_team", -1) >= 0:
		return prediction
	while elapsed < duration - BallMotion.TIME_EPSILON:
		var step := minf(interval, duration - elapsed)
		var result := BallMotion.advance(snapshot, settings, step)
		if landing.is_empty() and not result["impacts"].is_empty():
			var impact: Dictionary = result["impacts"][0]
			landing["position"] = impact["position"]
			landing["time"] = elapsed + impact["time"]
		snapshot = result["snapshot"]
		elapsed += result.get("goal_time", step)
		samples.append(_make_sample(snapshot, elapsed, ball.pickup_height))
		if snapshot.get("goal_team", -1) >= 0:
			break
	return prediction


static func _make_sample(snapshot: Dictionary, time: float, pickup_height: float) -> Dictionary:
	return {
		"time": time,
		"position": snapshot["position"],
		"velocity": snapshot["velocity"],
		"height": snapshot["height"],
		"height_velocity": snapshot["height_velocity"],
		"collectible": snapshot.get("goal_team", -1) < 0 and not snapshot["shot_active"] and snapshot["height"] <= pickup_height,
		"goal_team": snapshot.get("goal_team", -1),
	}
