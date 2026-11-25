extends Node
## Check headless del flujo de pantallas simulando teclas (con autoloads, a diferencia de --script).
## Uso: godot --headless --path . res://tests/flow_check.tscn   → imprime "OK flujo" o "FALLO ..."

const MENU := "res://scenes/screens/main_menu.tscn"

var _errors: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var tree := get_tree()
	# Sin escena actual, cambiar de escena no libera este nodo de prueba.
	tree.current_scene = null
	tree.change_scene_to_file(MENU)
	await _frames(3)
	_expect_scene("MainMenu")

	# Un jugador: confirmar en el menú y elegir el primer club.
	await _press("p1_pass")
	_expect_scene("TeamSelection")
	await _press("p1_pass")
	_expect_scene("World")
	_expect(GameSession.home_club.id == &"melgar", "SP: P1 debería jugar con Melgar")
	_expect(GameSession.away_club != GameSession.home_club, "SP: el rival debe ser otro club")

	# Esc vuelve al menú.
	await _press("ui_cancel")
	_expect_scene("MainMenu")

	# PvP: P2 no puede confirmar el club que P1 ya eligió.
	await _press("p1_down")
	await _press("p1_pass")
	_expect_scene("TeamSelection")
	await _press("p1_pass")
	await _press("p2_left")
	await _press("p2_pass")
	_expect_scene("TeamSelection")
	await _press("p2_right")
	await _press("p2_pass")
	_expect_scene("World")
	_expect(GameSession.mode == GameSession.Mode.PVP, "PvP: modo incorrecto")
	_expect(GameSession.home_club.id == &"melgar" and GameSession.away_club.id == &"alianza",
		"PvP: se esperaba Melgar vs Alianza")

	for error in _errors:
		push_error(error)
	print("OK flujo" if _errors.is_empty() else "FALLO %d" % _errors.size())
	tree.quit(0 if _errors.is_empty() else 1)


func _press(action: StringName) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
		await _frames(2)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _expect_scene(scene_name: String) -> void:
	var current := get_tree().current_scene
	_expect(current != null and current.name == scene_name,
		"se esperaba %s, hay %s" % [scene_name, current.name if current else "nada"])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
