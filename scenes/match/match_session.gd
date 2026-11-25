extends Node2D
## Entrada del partido. El controlador mantiene marcador, pausas y saques.

@export var controller: MatchController

const MENU := "res://scenes/screens/main_menu.tscn"


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(controller) or event.is_echo():
		return
	if event.is_action_pressed("reset_training"):
		controller.start_match()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		# La ayuda (F1) consume Esc en _input cuando está abierta, así que aquí no choca.
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		get_tree().change_scene_to_file(MENU)
