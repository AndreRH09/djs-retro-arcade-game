extends Node2D
## Ayuda opcional del partido. F1 abre y pausa; F1 o Esc vuelve al juego.

@export var pixel_font: FontFile = preload("res://assets/fonts/Pixeled.ttf")

const PANEL_SIZE := Vector2(264, 156)
const BACKGROUND := Color("252525")
const INK := Color("dedede")
const YELLOW := Color("e8ef00")

var help_open := false
var _was_paused := false
var _font: Font


func _ready() -> void:
	# La ayuda debe recibir el cierre aunque el resto del partido esté pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sharp_font := pixel_font.duplicate() as FontFile
	sharp_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	sharp_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	sharp_font.oversampling = 1.0
	_font = sharp_font
	visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo:
			if key.physical_keycode == KEY_F1 or key.keycode == KEY_F1:
				toggle_help()
				get_viewport().set_input_as_handled()
				return
			if help_open and (key.physical_keycode == KEY_ESCAPE or key.keycode == KEY_ESCAPE):
				close_help()
				get_viewport().set_input_as_handled()
				return
	# R no debe reiniciar el partido mientras se leen los controles.
	if help_open:
		get_viewport().set_input_as_handled()


func toggle_help() -> void:
	if help_open:
		close_help()
		return
	_was_paused = get_tree().paused
	help_open = true
	visible = true
	get_tree().paused = true
	queue_redraw()


func close_help() -> void:
	if not help_open:
		return
	help_open = false
	visible = false
	get_tree().paused = _was_paused


func _exit_tree() -> void:
	# Si se cambia de escena con la ayuda abierta, no dejar una pausa pendiente.
	if help_open:
		get_tree().paused = _was_paused


func _draw() -> void:
	if not help_open or _font == null:
		return
	var viewport_size := get_viewport_rect().size
	var origin := ((viewport_size - PANEL_SIZE) * 0.5).floor()
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(origin, PANEL_SIZE), BACKGROUND)
	draw_rect(Rect2(origin, PANEL_SIZE), INK, false, 1.0)
	_center_text("CONTROLES - PAUSA", origin + Vector2(132, 17), 7, YELLOW)
	_line("P1: FLECHAS PARA MOVERSE", origin, 36, YELLOW)
	_line("K: PASAR (APUNTA HACIA P2)", origin, 48)
	_line("L: MANTENER Y SOLTAR PARA DISPARAR", origin, 60)
	_line("P2: WASD PARA MOVERSE", origin, 80, YELLOW)
	_line("F: PASAR (APUNTA HACIA P1)", origin, 92)
	_line("G: MANTENER Y SOLTAR PARA DISPARAR", origin, 104)
	_line("SIN BALON: MUEVETE + L/G PARA ROBAR", origin, 120)
	_line("ATACA A LA DERECHA. R: NUEVO PARTIDO", origin, 132)
	_center_text("F1 O ESC PARA VOLVER", origin + Vector2(132, 147), 5, YELLOW)


func _line(text: String, origin: Vector2, y: float, color: Color = INK) -> void:
	draw_string(_font, origin + Vector2(10, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, color)


func _center_text(text: String, point: Vector2, size: int, color: Color) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(_font, (point - Vector2(width / 2.0, 0)).floor(), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
