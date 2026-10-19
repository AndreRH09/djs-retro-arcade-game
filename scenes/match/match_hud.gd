extends Node2D
## Presentación retro del partido. Las reglas y los goles pertenecen al controlador.

@export var ball: SoccerBall
@export var controller: MatchController
@export_group("Aspecto del marcador")
@export var pixel_font: FontFile = preload("res://assets/fonts/Pixeled.ttf")
@export var human_flag: Texture2D = preload("res://assets/art/ui/flags/flag-usa.png")
@export var cpu_flag: Texture2D = preload("res://assets/art/ui/flags/flag-france.png")

const INK := Color("dedede")
const YELLOW := Color("e8ef00")
const BACKGROUND := Color("252525")
const BAR_SIZE := Vector2(200, 12)
const FONT_SIZE := 5

var _font: Font


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Una copia local evita alterar la fuente usada por otras escenas.
	var sharp_font := pixel_font.duplicate() as FontFile
	sharp_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	sharp_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	sharp_font.oversampling = 1.0
	_font = sharp_font


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(controller) or _font == null:
		return
	var size := get_viewport_rect().size
	var origin := Vector2(floorf((size.x - BAR_SIZE.x) / 2.0), size.y - BAR_SIZE.y)

	# Mismo orden de la referencia: nombre, bandera, resultado, bandera y estado.
	draw_rect(Rect2(origin, BAR_SIZE), BACKGROUND)
	_draw_fitted_text(_carrier_name(), origin + Vector2(4, 10), 56, INK)
	_draw_flag(human_flag, origin + Vector2(64, 0))
	_center_text("%d - %d" % [controller.scores[0], controller.scores[1]], origin + Vector2(100, 10), FONT_SIZE, YELLOW)
	_draw_flag(cpu_flag, origin + Vector2(115, 0))
	_center_text(_status_text(), origin + Vector2(168, 10), FONT_SIZE, YELLOW)
	_draw_notice(size)


func _carrier_name() -> String:
	if is_instance_valid(ball) and ball.carrier is Player:
		var player := ball.carrier as Player
		match player.control_scheme:
			Player.ControlScheme.P1:
				return "P1"
			Player.ControlScheme.P2:
				return "P2"
		return player.display_name.to_upper()
	return "BALON LIBRE"


func _status_text() -> String:
	match controller.state:
		MatchController.State.KICKOFF:
			return "SAQUE"
		MatchController.State.GOAL:
			return "GOL!"
		MatchController.State.FINISHED:
			return "FINAL"
	return "A %d" % controller.goals_to_win if controller.goals_to_win > 0 else "LIBRE"


func _draw_notice(size: Vector2) -> void:
	var title := ""
	var detail := ""
	match controller.state:
		MatchController.State.KICKOFF:
			title = "SAQUE " + _team_name(controller.kickoff_team)
			detail = "EMPIEZA EN %d" % maxi(1, ceili(controller.time_left))
		MatchController.State.GOAL:
			title = "GOL DE " + _team_name(controller.last_scoring_team)
			detail = "PREPARANDO SAQUE" if controller.winner_team < 0 else "PARTIDO TERMINADO"
		MatchController.State.FINISHED:
			title = "GANAN " + _team_name(controller.winner_team)
			detail = "R PARA JUGAR DE NUEVO"
	if title.is_empty():
		return
	var origin := (size * 0.5 - Vector2(76, 16)).floor()
	draw_rect(Rect2(origin, Vector2(152, 30)), BACKGROUND)
	_center_text(title, origin + Vector2(76, 13), 7, YELLOW)
	_center_text(detail, origin + Vector2(76, 25), 4, INK)


func _team_name(team: int) -> String:
	return "HUMANOS" if team == 0 else "CPU"


func _draw_flag(flag: Texture2D, point: Vector2) -> void:
	if flag != null:
		draw_texture_rect(flag, Rect2(point, Vector2(21, 12)), false)


func _center_text(text: String, point: Vector2, font_size: int, color: Color) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(_font, (point - Vector2(width / 2.0, 0)).floor(), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_fitted_text(text: String, point: Vector2, max_width: float, color: Color) -> void:
	# Los nombres personalizados no deben invadir la bandera ni el resultado.
	while text.length() > 1 and _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x > max_width:
		text = text.left(-1)
	draw_string(_font, point.floor(), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
