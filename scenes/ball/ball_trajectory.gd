class_name BallTrajectory
extends RefCounted
## Cálculos del pase raso: desaceleración constante hasta detenerse en el destino.


static func ground_pass_speed(distance: float, friction: float) -> float:
	# v² = 2 · a · d: la fricción consume la velocidad al recorrer esa distancia.
	return sqrt(2.0 * maxf(friction, 0.0) * maxf(distance, 0.0))


static func ground_step(velocity: Vector2, friction: float, delta: float) -> Dictionary:
	var speed := velocity.length()
	var duration := maxf(delta, 0.0)
	var deceleration := maxf(friction, 0.0)
	if speed <= 0.0 or duration <= 0.0:
		return {"displacement": Vector2.ZERO, "velocity": velocity}
	if deceleration <= 0.0:
		return {"displacement": velocity * duration, "velocity": velocity}

	# Integrar solo hasta el instante de reposo evita pasarse del destino a pocos FPS.
	var moving_time := minf(duration, speed / deceleration)
	var direction := velocity / speed
	var distance := speed * moving_time - 0.5 * deceleration * moving_time * moving_time
	return {
		"displacement": direction * distance,
		"velocity": direction * maxf(speed - deceleration * moving_time, 0.0),
	}
