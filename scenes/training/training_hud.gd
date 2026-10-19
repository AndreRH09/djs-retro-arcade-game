extends Node2D
## Instrucciones fijas en pantalla; independientes de la cámara y de la física.

@export var ball: SoccerBall


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var size := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	var ink := Color(0.95, 0.98, 0.9)
	var background := Color(0.04, 0.11, 0.08, 0.88)
	draw_rect(Rect2(0, 0, size.x, 22), background)
	draw_string(font, Vector2(6, 9), "P1: flechas · K pase · L tiro", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, ink)
	draw_string(font, Vector2(6, 19), "P2: WASD · F pase · G tiro", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, ink)
	draw_string(font, Vector2(size.x - 50, 9), "R reinicia", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, ink)
	var status := "BALON LIBRE · Acércate para controlarlo"
	var world := get_parent().get_parent()
	if not world.last_cpu_action.is_empty():
		status = world.last_cpu_action
	if is_instance_valid(ball):
		if ball.state == SoccerBall.State.SHOT:
			if world.last_cpu_action.is_empty():
				status = "Naranja: caída · Verde: objetivo de la CPU"
		elif is_instance_valid(ball.carrier):
			var carrier := ball.carrier as Player
			if carrier != null:
				if carrier.control_scheme == Player.ControlScheme.CPU:
					var labels := ["CON BALON", "CONDUCE", "PREPARA PASE", "PREPARA TIRO", "ESPERA"]
					status = carrier.display_name + " " + labels[carrier.cpu_attack.state] + " · R reinicia"
				else:
					var carrier_name := "P1" if carrier.control_scheme == Player.ControlScheme.P1 else "P2"
					status = carrier_name + " CON BALON · K/F pase · Mantén L/G para cargar"
					if carrier.ball_interaction.action_state == PlayerBallInteraction.ActionState.CHARGING:
						status = "CARGA %d%% · Apunta con dirección y suelta tiro" % int(carrier.ball_interaction.get_charge_ratio() * 100)
	draw_rect(Rect2(0, size.y - 13, size.x, 13), background)
	draw_string(font, Vector2(6, size.y - 4), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, ink)
