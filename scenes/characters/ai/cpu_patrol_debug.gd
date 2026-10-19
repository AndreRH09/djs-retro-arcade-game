extends Node2D
## Ayuda visual independiente: ocultar este nodo no cambia el comportamiento.

@export var patrol: CpuPatrol
@export var interceptor: CpuBallInterceptor
@export var attack: CpuBallAttack


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var text := ""
	var color := Color.CYAN
	var player := get_parent() as Player
	var prefix := player.display_name if player != null else "CPU"
	if is_instance_valid(attack) and attack.enabled and attack.state != CpuBallAttack.State.IDLE:
		var labels := ["", "CONDUCE", "PASA", "DISPARA", "ESPERA"]
		text = prefix + " " + labels[attack.state]
		color = Color(1.0, 0.85, 0.45)
	elif is_instance_valid(interceptor) and interceptor.enabled and interceptor.state != CpuBallInterceptor.State.IDLE:
		var labels := ["", "INTERCEPTA", "RECUPERA", "CON BALON"]
		text = prefix + " " + labels[interceptor.state]
		color = Color(0.5, 1.0, 0.8)
	elif is_instance_valid(patrol) and patrol.enabled:
		var labels := ["PATRULLA", "PRESION", "REGRESO"]
		var colors := [Color.CYAN, Color.SALMON, Color.GOLD]
		text = prefix + " " + labels[patrol.state]
		color = colors[patrol.state]
	else:
		return
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var origin := Vector2(-width / 2.0, -34.0)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 2, Color(0.05, 0.12, 0.05))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
	draw_arc(Vector2.ZERO, 5.0, 0.0, TAU, 16, color, 1.0)
