class_name MatchAudio
extends Node
## Conecta los eventos del partido con los sonidos. No modifica la jugabilidad:
## solo escucha las señales del balón y del controlador del partido.

@export var ball: SoccerBall
@export var controller: MatchController


func _ready() -> void:
	if is_instance_valid(ball):
		ball.kicked.connect(_on_ball_kicked)
	if is_instance_valid(controller):
		controller.state_changed.connect(_on_match_state_changed)


func _on_ball_kicked(kind: String) -> void:
	match kind:
		"pass":
			SoundPlayer.play(SoundPlayer.Sound.PASS)
		"shot":
			SoundPlayer.play(SoundPlayer.Sound.SHOT)


func _on_match_state_changed(new_state: MatchController.State) -> void:
	match new_state:
		MatchController.State.PLAYING, MatchController.State.GOAL, MatchController.State.FINISHED:
			# Pitazo al iniciar el juego tras el saque, al anotarse un gol y al terminar.
			SoundPlayer.play(SoundPlayer.Sound.WHISTLE)
