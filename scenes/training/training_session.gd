extends Node2D
## Práctica con balón: R restablece las posiciones iniciales y el balón.

@export var ball: SoccerBall
var _spawn_positions: Dictionary = {}
var _ball_spawn := Vector2.ZERO
var last_cpu_action := ""


func _ready() -> void:
	for child in get_children():
		if child is Player:
			_spawn_positions[child] = child.global_position
	if is_instance_valid(ball):
		_ball_spawn = ball.global_position
	for player: Player in _spawn_positions:
		if player.control_scheme == Player.ControlScheme.CPU:
			player.ball_interaction.action_released.connect(_on_cpu_action.bind(player))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_training"):
		reset_practice()
		get_viewport().set_input_as_handled()


func reset_practice() -> void:
	last_cpu_action = ""
	for player: Player in _spawn_positions:
		if not is_instance_valid(player):
			continue
		player.global_position = _spawn_positions[player]
		player.velocity = Vector2.ZERO
		player.state = Player.State.MOVING
		player.heading = Vector2.RIGHT
		player.ball_interaction.reset()
		player.ball_interaction.aim_direction = Vector2.RIGHT
		player.reset_cpu_controllers()
	if is_instance_valid(ball):
		ball.reset_to(_ball_spawn)


func _on_cpu_action(kind: String, receiver: Player, player: Player) -> void:
	if kind == "pass" and is_instance_valid(receiver):
		last_cpu_action = "%s paso a %s" % [player.display_name, receiver.display_name]
	elif kind == "shot":
		last_cpu_action = "%s disparo al objetivo" % player.display_name
