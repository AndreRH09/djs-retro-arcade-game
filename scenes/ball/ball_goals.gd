class_name BallGoals
extends RefCounted
## Barrido geométrico de porterías. No conoce nodos ni modifica el marcador.
## Una portería cuenta cuando TODO el balón cruza la línea hacia fuera.

const EPSILON := 0.00001


static func fits(opening: Dictionary, ground_y: float, height: float) -> bool:
	var radius := maxf(opening.get("radius", 3.0), 0.0)
	return ground_y >= opening["min_y"] + radius - EPSILON \
		and ground_y <= opening["max_y"] - radius + EPSILON \
		and height + radius <= opening["height"] + EPSILON


static func advance(snapshot: Dictionary, settings: Dictionary, delta: float, friction: float, gravity: float, stop_at_bounce: bool = false) -> Dictionary:
	var position: Vector2 = snapshot["position"]
	var velocity: Vector2 = snapshot["velocity"]
	var remaining := maxf(delta, 0.0)
	var elapsed := 0.0
	var travelled := 0.0
	var restitution := clampf(settings.get("bounce", 0.8), 0.0, 1.0)
	var bounds: Rect2 = settings["bounds"]
	var openings: Array = settings.get("goal_openings", [])
	var entered_side := 0
	if position.x < bounds.position.x:
		entered_side = -1
	elif position.x > bounds.end.x:
		entered_side = 1
	var bounced := false
	while remaining > BallMotion.TIME_EPSILON and velocity.length() > EPSILON:
		# Cada choque cambia la velocidad: integrar de nuevo el tiempo restante evita
		# que un frame largo recorra la distancia anterior a la pérdida de energía.
		var speed := velocity.length()
		var direction := velocity / speed
		var step := BallTrajectory.ground_step(velocity, friction, remaining)
		var available: float = (step["displacement"] as Vector2).length()
		var side := -1 if direction.x < 0.0 else 1
		var opening := _opening_for(openings, side)
		var line_x := bounds.position.x if side < 0 else bounds.end.x
		var event := "wall"
		var plane_x := line_x
		# Dentro de la boca, esperar a que el radio trasero cruce la línea.
		if entered_side == side and not opening.is_empty():
			plane_x = opening["line_x"] + side * maxf(opening.get("radius", 3.0), 0.0)
			event = "goal"
		elif entered_side != 0 and entered_side != side:
			plane_x = bounds.position.x if entered_side < 0 else bounds.end.x
			event = "return"
		var x_distance := INF
		if absf(direction.x) > EPSILON:
			x_distance = (plane_x - position.x) / direction.x
			# Un balón colocado detrás de la línea completa no marca por salir más.
			if x_distance < -EPSILON:
				x_distance = INF
			else:
				x_distance = maxf(x_distance, 0.0)
			if event == "goal" and x_distance <= EPSILON and travelled <= EPSILON:
				# Estar ya colocado sobre la línea completa no constituye un cruce.
				x_distance = INF
		var y_min := bounds.position.y
		var y_max := bounds.end.y
		var mouth := _opening_for(openings, entered_side)
		if entered_side != 0 and not mouth.is_empty() and fits(mouth, position.y, 0.0):
			y_min = mouth["min_y"] + maxf(mouth.get("radius", 3.0), 0.0)
			y_max = mouth["max_y"] - maxf(mouth.get("radius", 3.0), 0.0)
		var y_distance := INF
		if absf(direction.y) > EPSILON:
			y_distance = maxf(((y_min if direction.y < 0.0 else y_max) - position.y) / direction.y, 0.0)
		var distance := minf(available, minf(x_distance, y_distance))
		position += direction * distance
		travelled += distance
		var event_reached := minf(x_distance, y_distance) <= distance + EPSILON
		var used_time := minf(time_for_distance(distance, speed, friction), remaining) if event_reached else remaining
		elapsed += used_time
		remaining = maxf(remaining - used_time, 0.0)
		var next_speed := maxf(speed - maxf(friction, 0.0) * used_time, 0.0)
		var ball_height: float = snapshot["height"] + snapshot["height_velocity"] * elapsed - 0.5 * gravity * elapsed * elapsed
		var contact := false
		if x_distance <= distance + EPSILON:
			if event == "goal" and fits(opening, position.y, maxf(ball_height, 0.0)):
				return {"position": position, "velocity": Vector2.ZERO, "distance": travelled, "time": elapsed, "goal_team": opening["scoring_team"], "bounced": bounced}
			elif event == "return":
				entered_side = 0
			elif event == "wall" and not opening.is_empty() and fits(opening, position.y, maxf(ball_height, 0.0)):
				entered_side = side
			else:
				# Poste o larguero: conservar el rebote del límite del campo.
				position.x = line_x
				direction.x *= -1.0
				entered_side = 0
				contact = true
		if y_distance <= distance + EPSILON:
			direction.y *= -1.0
			contact = true
		if contact:
			next_speed *= restitution
			bounced = true
		velocity = direction * next_speed
		if contact and stop_at_bounce:
			return {"position": position, "velocity": velocity, "distance": travelled, "time": elapsed, "goal_team": -1, "bounced": true}
	return {"position": position, "velocity": velocity, "distance": travelled, "time": delta, "goal_team": -1, "bounced": bounced}


static func time_for_distance(distance: float, speed: float, friction: float) -> float:
	if speed <= EPSILON:
		return 0.0
	var final_speed := sqrt(maxf(speed * speed - 2.0 * maxf(friction, 0.0) * distance, 0.0))
	return 2.0 * distance / (speed + final_speed)


static func carried_crossing(start: Vector2, destination: Vector2, start_height: float, end_height: float, openings: Array) -> Dictionary:
	var earliest: Dictionary = {}
	for opening: Dictionary in openings:
		var side: int = opening["side"]
		var plane: float = opening["line_x"] + side * maxf(opening.get("radius", 3.0), 0.0)
		var travel := (destination.x - start.x) * side
		if travel <= EPSILON or (start.x - plane) * side >= 0.0 or (destination.x - plane) * side < 0.0:
			continue
		var fraction := (plane - start.x) / (destination.x - start.x)
		var position := start.lerp(destination, fraction)
		var crossing_height := lerpf(start_height, end_height, fraction)
		if fits(opening, position.y, crossing_height) and (earliest.is_empty() or fraction < earliest["fraction"]):
			earliest = {"position": position, "height": crossing_height, "goal_team": opening["scoring_team"], "fraction": fraction}
	return earliest


static func clamp_carried(destination: Vector2, height: float, bounds: Rect2, openings: Array) -> Vector2:
	if not bounds.has_area():
		return destination
	var clamped := destination.clamp(bounds.position, bounds.end)
	for opening: Dictionary in openings:
		if fits(opening, destination.y, height) and (destination.x - opening["line_x"]) * opening["side"] >= 0.0:
			var outside_x: float = opening["line_x"] + opening["side"] * maxf(opening.get("depth", 24.0), opening.get("radius", 3.0))
			clamped.x = clampf(destination.x, minf(opening["line_x"], outside_x), maxf(opening["line_x"], outside_x))
	return clamped


static func _opening_for(openings: Array, side: int) -> Dictionary:
	for opening: Dictionary in openings:
		if opening["side"] == side:
			return opening
	return {}
