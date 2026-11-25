class_name PixelText
## Texto nítido con la fuente del proyecto, compartido por las pantallas de menú.

const FONT_PATH := "res://assets/fonts/Pixeled.ttf"

static var _font: Font


static func font() -> Font:
	if _font == null:
		# Una copia evita alterar la fuente que usan otras escenas.
		var sharp := (load(FONT_PATH) as FontFile).duplicate() as FontFile
		sharp.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		sharp.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		sharp.oversampling = 1.0
		_font = sharp
	return _font


## Dibuja `text` centrado horizontalmente en `point` (point.y es la línea base).
static func draw_centered(canvas: CanvasItem, text: String, point: Vector2, size: int, color: Color) -> void:
	var width := font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	canvas.draw_string(font(), (point - Vector2(width / 2.0, 0)).floor(), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
