extends Marker2D
## Referencia visible para el tiro de práctica. La posición se edita en la escena.


func _draw() -> void:
	var color := Color(1.0, 0.9, 0.55)
	draw_arc(Vector2.ZERO, 12, 0, TAU, 32, color, 2.0)
	draw_line(Vector2(-16, 0), Vector2(16, 0), color)
	draw_line(Vector2(0, -16), Vector2(0, 16), color)
	var font := ThemeDB.fallback_font
	var text := "OBJETIVO TIRO"
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	var origin := Vector2(-width * 0.5, -22)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 2, Color.BLACK)
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)
