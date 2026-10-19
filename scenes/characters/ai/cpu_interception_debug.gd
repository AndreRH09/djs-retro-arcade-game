extends Node2D
## Guías del pronóstico. Ocultar este nodo no cambia la simulación ni la IA.

@export var interceptor: CpuBallInterceptor
@export var show_trajectory: bool = true

const LANDING_COLOR := Color(1.0, 0.72, 0.25)
const INTERCEPT_COLOR := Color(0.5, 1.0, 0.8)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(interceptor) or not interceptor.enabled:
		return
	var ball := interceptor.ball
	if not is_instance_valid(ball) or ball.state == SoccerBall.State.CARRIED:
		return
	var prediction := interceptor.prediction
	if prediction.is_empty():
		return
	if show_trajectory:
		_draw_trajectory(prediction)
	var landing: Dictionary = prediction.get("landing", {})
	if not landing.is_empty():
		var point := to_local(landing["position"])
		draw_arc(point, 6, 0, TAU, 24, LANDING_COLOR, 1.0)
		draw_line(point - Vector2(9, 0), point + Vector2(9, 0), LANDING_COLOR)
		draw_line(point - Vector2(0, 9), point + Vector2(0, 9), LANDING_COLOR)
		_draw_label(point + Vector2(0, 18), "CAIDA", LANDING_COLOR)
	if interceptor.state in [CpuBallInterceptor.State.INTERCEPTING, CpuBallInterceptor.State.RECOVERING]:
		var point := to_local(interceptor.destination)
		draw_rect(Rect2(point - Vector2(4, 4), Vector2(8, 8)), INTERCEPT_COLOR, false)
		var cpu := interceptor.get_parent() as Node2D
		if cpu != null:
			draw_dashed_line(to_local(cpu.global_position), point, INTERCEPT_COLOR, 1.0, 4.0)
		_draw_label(point - Vector2(0, 12), "OBJETIVO CPU", INTERCEPT_COLOR)


func _draw_trajectory(prediction: Dictionary) -> void:
	var samples: Array = prediction.get("samples", [])
	var until := interceptor.intercept_time
	var landing: Dictionary = prediction.get("landing", {})
	if not landing.is_empty():
		until = maxf(until, landing["time"])
	# La línea representa la proyección sobre el césped; el balón conserva su altura.
	for index in range(1, samples.size()):
		if float(samples[index - 1]["time"]) > until:
			break
		var start := to_local(samples[index - 1]["position"])
		var finish := to_local(samples[index]["position"])
		if start.distance_squared_to(finish) > 0.01:
			draw_line(start, finish, Color(0.95, 0.98, 0.9, 0.5), 1.0)


func _draw_label(point: Vector2, text: String, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var origin := point - Vector2(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x / 2.0, 0)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 2, Color(0.04, 0.12, 0.04))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
