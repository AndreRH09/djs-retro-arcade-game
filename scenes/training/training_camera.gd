extends Camera2D
## Encuadra a los jugadores y al balón para poder seguir pases y tiros largos.

@export var ball: SoccerBall
@export var interceptor: CpuBallInterceptor
## Referencias que deben seguir visibles, como las porterías del partido.
@export var framing_points: Array[Node2D] = []
@export var field_rect := Rect2(0, 0, 850, 360)
@export var padding := Vector2(45, 20)
@export_range(1.0, 20.0) var smoothing_speed: float = 10.0


func _ready() -> void:
	_fit_frame(1.0)


func _physics_process(delta: float) -> void:
	_fit_frame(1.0 - exp(-smoothing_speed * delta))


func _fit_frame(weight: float) -> void:
	if not is_instance_valid(ball):
		return
	var minimum := ball.global_position - Vector2(0, ball.height)
	var maximum := ball.global_position
	for point in framing_points:
		if is_instance_valid(point):
			minimum = minimum.min(point.global_position)
			maximum = maximum.max(point.global_position)
	for player in get_tree().get_nodes_in_group("players"):
		minimum = minimum.min(player.global_position - Vector2(0, 32))
		maximum = maximum.max(player.global_position)
		var actor := player as Player
		if actor != null and actor.cpu_attack.enabled:
			var attack := actor.cpu_attack
			if is_instance_valid(attack.attack_target) and attack.state != CpuBallAttack.State.IDLE:
				minimum = minimum.min(attack.attack_target.global_position - Vector2(0, 26))
				maximum = maximum.max(attack.attack_target.global_position + Vector2(0, 16))
	# Incluir los puntos previstos permite observar la anticipación antes de la caída.
	if is_instance_valid(interceptor) and interceptor.enabled and ball.state != SoccerBall.State.CARRIED:
		var landing: Dictionary = interceptor.prediction.get("landing", {})
		if not landing.is_empty():
			minimum = minimum.min(landing["position"] - Vector2(0, 20))
			maximum = maximum.max(landing["position"] + Vector2(0, 20))
		if interceptor.state in [CpuBallInterceptor.State.INTERCEPTING, CpuBallInterceptor.State.RECOVERING]:
			minimum = minimum.min(interceptor.destination - Vector2(0, 20))
			maximum = maximum.max(interceptor.destination + Vector2(0, 20))
	var screen_size := get_viewport_rect().size
	# Reservar espacio para los controles y el estado evita tapar a los jugadores.
	var top_inset := 22.0
	var bottom_inset := 13.0
	var usable_size := screen_size - Vector2(0, top_inset + bottom_inset)
	var content_size := maximum - minimum + padding * 2.0
	var frame_zoom := clampf(minf(usable_size.x / content_size.x, usable_size.y / content_size.y), 0.3, 1.0)
	zoom = zoom.lerp(Vector2.ONE * frame_zoom, weight)
	var desired_position := (minimum + maximum) * 0.5
	desired_position.y -= (top_inset - bottom_inset) / (2.0 * zoom.y)
	var half_view := screen_size / (2.0 * zoom)
	for axis in [0, 1]:
		if field_rect.size[axis] <= half_view[axis] * 2.0:
			desired_position[axis] = field_rect.get_center()[axis]
		else:
			var minimum_edge := field_rect.position[axis] + half_view[axis]
			var maximum_edge := field_rect.end[axis] - half_view[axis]
			if axis == 1:
				minimum_edge -= top_inset / zoom.y
				maximum_edge += bottom_inset / zoom.y
			desired_position[axis] = clampf(
				desired_position[axis], minimum_edge, maximum_edge
			)
	global_position = global_position.lerp(desired_position, weight)
