extends Node2D
## Entrada del partido. El controlador mantiene marcador, pausas y saques.

@export var controller: MatchController


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(controller) or event.is_echo():
		return
	if event.is_action_pressed("reset_training"):
		controller.start_match()
		get_viewport().set_input_as_handled()
