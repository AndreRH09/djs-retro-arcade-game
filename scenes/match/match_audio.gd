class_name MatchAudio
extends Node
## Conecta los eventos del partido con los sonidos. No modifica la jugabilidad:
## solo escucha las señales del balón.

@export var ball: SoccerBall


func _ready() -> void:
	if is_instance_valid(ball):
		ball.kicked.connect(_on_ball_kicked)


func _on_ball_kicked(kind: String) -> void:
	match kind:
		"pass":
			SoundPlayer.play(SoundPlayer.Sound.PASS)
		"shot":
			SoundPlayer.play(SoundPlayer.Sound.SHOT)
