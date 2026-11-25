extends Node2D
## Selección de equipo (HU-08).
## Un jugador: P1 elige (flechas + K) y el rival se sortea entre los demás clubes.
## PvP: P1 (flechas + K) y P2 (WASD + F) eligen a la vez y no pueden repetir club.
## L / G deshace la elección; Esc vuelve al menú.

const MATCH := "res://scenes/match/match.tscn"
const MENU := "res://scenes/screens/main_menu.tscn"
const COLUMNS := 4
const CELL := Vector2(56, 40)
const GRID_TOP := 40.0
const FRAME := preload("res://assets/art/ui/flags/flag-selection.png")
const INK := Color("dedede")
const YELLOW := Color("e8ef00")
const PANEL := Color(0.09, 0.09, 0.11, 0.85)
## Mismos colores que los marcadores 1P / 2P del partido.
const PLAYER_COLORS: Array[Color] = [Color("e03c3c"), Color("3c64e0")]
const CONFIRMED := Color.WHITE

var _clubs: Array[ClubData] = []
var _cursor: Array[int] = [0, 1]
var _confirmed: Array[bool] = [false, false]


func _ready() -> void:
	# Se muestran también los diseños propuestos, marcados, para poder revisarlos jugando.
	_clubs = GameSession.get_clubs(false)
	_cursor[1] = mini(1, _clubs.size() - 1)


func _player_count() -> int:
	return 2 if GameSession.mode == GameSession.Mode.PVP else 1


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or _clubs.is_empty():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file(MENU)
		return
	for i in _player_count():
		if _handle_player(i, event):
			# Confirmar el último club cambia de escena y saca este nodo del árbol.
			if is_inside_tree():
				get_viewport().set_input_as_handled()
				queue_redraw()
			return


func _handle_player(i: int, event: InputEvent) -> bool:
	var prefix := "p%d_" % (i + 1)
	if _confirmed[i]:
		if event.is_action_pressed(prefix + "shoot"):
			_confirmed[i] = false
			SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
			return true
		return false
	var step := 0
	if event.is_action_pressed(prefix + "left"):
		step = -1
	elif event.is_action_pressed(prefix + "right"):
		step = 1
	elif event.is_action_pressed(prefix + "up"):
		step = -COLUMNS
	elif event.is_action_pressed(prefix + "down"):
		step = COLUMNS
	if step != 0:
		_cursor[i] = wrapi(_cursor[i] + step, 0, _clubs.size())
		SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
		return true
	if event.is_action_pressed(prefix + "pass") or (i == 0 and event.is_action_pressed("ui_accept")):
		_confirm(i)
		return true
	return false


func _confirm(i: int) -> void:
	var other := 1 - i
	# Un club ya confirmado por el rival queda bloqueado.
	if _player_count() == 2 and _confirmed[other] and _cursor[other] == _cursor[i]:
		SoundPlayer.play(SoundPlayer.Sound.HURT)
		return
	_confirmed[i] = true
	SoundPlayer.play(SoundPlayer.Sound.UI_SELECT)
	if _confirmed[0] and (_player_count() == 1 or _confirmed[1]):
		_start_match()


func _start_match() -> void:
	GameSession.home_club = _clubs[_cursor[0]]
	if _player_count() == 2:
		GameSession.away_club = _clubs[_cursor[1]]
	else:
		# ponytail: rival sorteado hasta que exista la llave del campeonato (HU-09, T030).
		var rivals := _clubs.filter(func(club: ClubData) -> bool: return club != GameSession.home_club)
		GameSession.away_club = rivals.pick_random() if not rivals.is_empty() else GameSession.home_club
	get_tree().change_scene_to_file(MATCH)


func _cell_origin(index: int) -> Vector2:
	var columns := mini(COLUMNS, _clubs.size())
	var left := floorf((get_viewport_rect().size.x - columns * CELL.x) / 2.0)
	return Vector2(left + (index % COLUMNS) * CELL.x, GRID_TOP + (index / COLUMNS) * CELL.y)


func _draw() -> void:
	var center := get_viewport_rect().size.x / 2.0
	PixelText.draw_centered(self, "ELIGE TU EQUIPO", Vector2(center, 26), 8, YELLOW)
	for index in _clubs.size():
		var flag_pos := _cell_origin(index) + Vector2(6, 4)
		draw_texture_rect(_clubs[index].flag, Rect2(flag_pos, Vector2(44, 28)), false)
		if _clubs[index].design_status != ClubData.DesignStatus.APPROVED:
			PixelText.draw_centered(self, "PROPUESTO", flag_pos + Vector2(22, 34), 4, INK)
		for i in _player_count():
			if _cursor[i] == index:
				var color := CONFIRMED if _confirmed[i] else PLAYER_COLORS[i]
				draw_texture(FRAME, flag_pos - Vector2(2, 2), color)
				PixelText.draw_centered(self, "%dP" % (i + 1), flag_pos + Vector2(8 + i * 28, -4), 4, color)
	draw_rect(Rect2(10, 128, 260, 46), PANEL)
	for i in _player_count():
		var x := center if _player_count() == 1 else 75.0 + i * 130.0
		var club := _clubs[_cursor[i]]
		var state := " LISTO" if _confirmed[i] else ""
		PixelText.draw_centered(self, "%dP %s%s" % [i + 1, club.display_name, state], Vector2(x, 144), 6,
			PLAYER_COLORS[i].lightened(0.3))
		var keys := "K ELIGE  L CAMBIA" if i == 0 else "F ELIGE  G CAMBIA"
		PixelText.draw_centered(self, keys, Vector2(x, 158), 4, INK)
	PixelText.draw_centered(self, "ESC VOLVER", Vector2(center, 170), 4, INK)
