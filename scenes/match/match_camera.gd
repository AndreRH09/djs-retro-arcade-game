extends Camera2D
## Cámara de partido: conserva el tamaño original de los sprites y sigue la jugada.
## La cámara de entrenamiento permanece en su propio archivo.

@export var ball: SoccerBall
@export var field_rect := Rect2(0, 0, 850, 360)
@export_range(0.5, 2.0, 0.05) var match_zoom := 1.0
@export_range(1.0, 20.0) var smoothing_speed := 10.0
## Espacio reservado al marcador inferior, en píxeles del viewport.
@export_range(0.0, 32.0) var bottom_inset := 16.0

var _follow_position := Vector2.ZERO


func _ready() -> void:
	# El seguimiento se interpola aquí; no acumular el suavizado del Camera2D.
	position_smoothing_enabled = false
	_follow_position = global_position
	_follow_play(1.0)


func _physics_process(delta: float) -> void:
	_follow_play(1.0 - exp(-smoothing_speed * delta))


func _follow_play(weight: float) -> void:
	if not is_instance_valid(ball) or not field_rect.has_area():
		return
	var screen_size := get_viewport_rect().size
	# Mantener escala 1:1. Solo una ventana más grande que el campo exige acercarse.
	var minimum_zoom := maxf(screen_size.x / field_rect.size.x, screen_size.y / field_rect.size.y)
	zoom = Vector2.ONE * maxf(match_zoom, minimum_zoom)
	var half_view := screen_size / (2.0 * zoom)
	var hud_height := bottom_inset / zoom.y

	# Incluir tanto el balón elevado como su sombra permite leer la trayectoria.
	var minimum := ball.global_position - Vector2(3, ball.height + 3)
	var maximum := ball.global_position + Vector2(3, 3)
	if is_instance_valid(ball.carrier):
		minimum = minimum.min(ball.carrier.global_position - Vector2(12, 32))
		maximum = maximum.max(ball.carrier.global_position + Vector2(12, 4))
	var target := (minimum + maximum) * 0.5 + Vector2(0, hud_height * 0.5)
	_follow_position = _follow_position.lerp(target, weight)

	# Un saque o una prueba puede recolocar el balón de golpe. Mantenerlo visible
	# durante ese salto sin alejar la cámara para mostrar a todos los jugadores.
	var margin := Vector2(12, 8) / zoom
	var minimum_center := maximum - half_view + margin + Vector2(0, hud_height)
	var maximum_center := minimum + half_view - margin
	for axis in [0, 1]:
		if minimum_center[axis] <= maximum_center[axis]:
			_follow_position[axis] = clampf(_follow_position[axis], minimum_center[axis], maximum_center[axis])
		else:
			_follow_position[axis] = target[axis]
		# Los límites son los del dibujo completo del campo; nunca mostrar negro.
		_follow_position[axis] = clampf(
			_follow_position[axis],
			field_rect.position[axis] + half_view[axis],
			field_rect.end[axis] - half_view[axis]
		)
	# Desplazamiento en píxeles enteros para mantener nítidos los sprites pixel art.
	global_position = (_follow_position * zoom).round() / zoom
