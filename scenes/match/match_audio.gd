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
	MusicPlayer.play_music(MusicPlayer.Music.GAMEPLAY)


func _on_ball_kicked(kind: String) -> void:
	match kind:
		"pass":
			SoundPlayer.play(SoundPlayer.Sound.PASS)
		"shot":
			SoundPlayer.play(SoundPlayer.Sound.SHOT)


func _on_match_state_changed(new_state: MatchController.State) -> void:
	match new_state:
		MatchController.State.PLAYING, MatchController.State.GOAL:
			# Pitazo al iniciar el juego tras el saque y al anotarse un gol.
			SoundPlayer.play(SoundPlayer.Sound.WHISTLE)
			MusicPlayer.play_music(MusicPlayer.Music.GAMEPLAY)
		MatchController.State.FINISHED:
			SoundPlayer.play(SoundPlayer.Sound.WHISTLE)
			MusicPlayer.play_music(MusicPlayer.Music.WIN)
