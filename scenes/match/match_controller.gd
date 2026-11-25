class_name MatchController
extends Node
## Reglas del primer partido: marcador, pausa de gol, saque y final.
## No decide movimientos ni golpeos; congela la simulación durante los reinicios.

signal score_changed(scores: Array[int])
signal state_changed(new_state: State)

enum State {KICKOFF, PLAYING, GOAL, FINISHED}

@export var ball: SoccerBall
@export var players: Array[Player] = []
@export var goals: Array[SoccerGoal] = []
@export var kickoff_position := Vector2(425.0, 193.0)
@export_enum("Jugadores:0", "CPU:1") var kickoff_team: int = 0
## Cero permite jugar sin límite; el valor inicial es primero en marcar tres goles.
@export_range(0, 20, 1) var goals_to_win := 3
@export_range(0.0, 5.0, 0.1, "suffix:s") var goal_pause := 2.0
@export_range(0.0, 5.0, 0.1, "suffix:s") var kickoff_pause := 1.0

var scores: Array[int] = [0, 0]
var state := State.KICKOFF
var last_scoring_team := -1
var winner_team := -1
var time_left := 0.0

var _spawn_positions: Dictionary = {}
var _spawn_headings: Dictionary = {}
var _player_processing: Dictionary = {}
var _ball_processing := true
var _initial_kickoff_team := 0


func _ready() -> void:
	_initial_kickoff_team = clampi(kickoff_team, 0, 1)
	for player in players:
		if not is_instance_valid(player):
			continue
		_spawn_positions[player] = player.global_position
		_spawn_headings[player] = player.heading
		_player_processing[player] = player.is_physics_processing()
	if is_instance_valid(ball):
		_ball_processing = ball.is_physics_processing()
		ball.goal_scored.connect(_on_goal_scored)
		ball.goal_openings.clear()
		for goal in goals:
			if is_instance_valid(goal):
				ball.goal_openings.append(goal.get_definition())
	start_match()


func _physics_process(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0 or state not in [State.KICKOFF, State.GOAL]:
		return
	time_left = maxf(time_left - delta, 0.0)
	if time_left > 0.000001:
		return
	if state == State.KICKOFF:
		_resume_play()
	elif winner_team >= 0:
		_change_state(State.FINISHED)
	else:
		_prepare_kickoff(1 - last_scoring_team)


## R puede llamar este método en cualquier momento, incluso durante un gol o tiro.
## El contador pertenece a este nodo: no quedan timers anteriores que se disparen.
func start_match() -> void:
	scores = [0, 0]
	last_scoring_team = -1
	winner_team = -1
	time_left = 0.0
	score_changed.emit(scores.duplicate())
	_prepare_kickoff(_initial_kickoff_team)


func _on_goal_scored(scoring_team: int) -> void:
	# Tanto el balón como el partido protegen contra un segundo gol del mismo cruce.
	if state != State.PLAYING or scoring_team < 0 or scoring_team > 1:
		return
	last_scoring_team = scoring_team
	scores[scoring_team] += 1
	if goals_to_win > 0 and scores[scoring_team] >= goals_to_win:
		winner_team = scoring_team
	_freeze_play()
	time_left = maxf(goal_pause, 0.0)
	_change_state(State.GOAL)
	score_changed.emit(scores.duplicate())
	if time_left <= 0.0:
		if winner_team >= 0:
			_change_state(State.FINISHED)
		else:
			_prepare_kickoff(1 - scoring_team)


func _prepare_kickoff(team: int) -> void:
	_freeze_play()
	kickoff_team = clampi(team, 0, 1)
	for player in players:
		if is_instance_valid(player) and _spawn_positions.has(player):
			player.reset_for_restart(_spawn_positions[player], _spawn_headings[player])
	if is_instance_valid(ball):
		ball.reset_to(kickoff_position)
		var taker := _find_kickoff_taker()
		if is_instance_valid(taker):
			var direction := Vector2.RIGHT if kickoff_team == 0 else Vector2.LEFT
			# La posición del jugador compensa el desplazamiento del balón a sus pies.
			taker.reset_for_restart(kickoff_position - Vector2(direction.x * 10.0, 4.0), direction)
			ball.try_collect(taker)
	time_left = maxf(kickoff_pause, 0.0)
	_change_state(State.KICKOFF)
	if time_left <= 0.0:
		_resume_play()


func _find_kickoff_taker() -> Player:
	var taker: Player
	var nearest_distance := INF
	for player in players:
		if not is_instance_valid(player) or player.team_id != kickoff_team:
			continue
		if not is_instance_valid(player.ball_interaction) or not player.ball_interaction.enabled or player.ball_interaction.ball != ball:
			continue
		# El primer jugador humano inicia el partido; los demás saques usan cercanía.
		if kickoff_team == 0 and player.control_scheme == Player.ControlScheme.P1:
			return player
		var distance := player.global_position.distance_squared_to(kickoff_position)
		if distance < nearest_distance:
			nearest_distance = distance
			taker = player
	return taker


func _freeze_play() -> void:
	for player in players:
		if is_instance_valid(player):
			player.set_physics_process(false)
			# Cancela carga, golpeo, tackle, planes de IA y tiempos de recuperación.
			player.reset_for_restart(player.global_position, player.heading)
	if is_instance_valid(ball):
		ball.set_physics_process(false)
		ball.velocity = Vector2.ZERO
		ball.height_velocity = 0.0


func _resume_play() -> void:
	time_left = 0.0
	for player in players:
		if is_instance_valid(player):
			player.set_physics_process(bool(_player_processing.get(player, true)))
	if is_instance_valid(ball):
		ball.set_physics_process(_ball_processing)
	_change_state(State.PLAYING)


func _change_state(next_state: State) -> void:
	state = next_state
	state_changed.emit(state)
