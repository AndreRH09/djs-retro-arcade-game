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
		# Diferido: el nuevo humano no debe leer en este mismo frame el pase que pidió el cambio.
		player.swap_requested.connect(_on_swap_requested, CONNECT_DEFERRED)
	if is_instance_valid(ball):
		_ball_processing = ball.is_physics_processing()
		ball.goal_scored.connect(_on_goal_scored)
		ball.goal_openings.clear()
		for goal in goals:
			if is_instance_valid(goal):
				ball.goal_openings.append(goal.get_definition())
	assign_controls()
	apply_session()
	start_match()


## Un manager humano por equipo controlado: SINGLE = P1 en el equipo 0; PVP = P1 en el 0 y P2 en el 1.
## El resto queda en CPU con su IA cableada hacia la portería rival.
func assign_controls() -> void:
	var humans := {0: Player.ControlScheme.P1}
	if GameSession.mode == GameSession.Mode.PVP:
		humans[1] = Player.ControlScheme.P2
	for player in players:
		if not is_instance_valid(player):
			continue
		var scheme: Player.ControlScheme = humans.get(player.team_id, Player.ControlScheme.CPU)
		# ponytail: control fijo al primer jugador del equipo; cambio al más cercano llega con TeamController (T013).
		humans.erase(player.team_id)
		player.set_control(scheme)
		# Todos quedan cableados: el control cambia de jugador durante el partido.
		_wire_cpu(player)


## Pasa el control del solicitante al compañero CPU más cercano al balón, si está más cerca que él.
func _on_swap_requested(requester: Player) -> void:
	if state != State.PLAYING or not is_instance_valid(ball) or not is_instance_valid(requester):
		return
	if requester.control_scheme == Player.ControlScheme.CPU:
		return
	# ponytail: aún no hay arquero; excluir role GOALIE cuando llegue HU-23.
	var closest := requester
	for player in players:
		if is_instance_valid(player) and player.team_id == requester.team_id 				and player.control_scheme == Player.ControlScheme.CPU 				and player.global_position.distance_squared_to(ball.global_position) 				< closest.global_position.distance_squared_to(ball.global_position):
			closest = player
	if closest != requester:
		var scheme := requester.control_scheme
		requester.set_control(Player.ControlScheme.CPU)
		closest.set_control(scheme)


## Completa solo las referencias que la escena no trae (el equipo 0 nació humano).
func _wire_cpu(player: Player) -> void:
	var attacked: SoccerGoal
	var defended: SoccerGoal
	for goal in goals:
		if is_instance_valid(goal):
			if goal.scoring_team == player.team_id:
				attacked = goal
			else:
				defended = goal
	if player.cpu_attack.attack_target == null:
		player.cpu_attack.attack_target = attacked
	player.cpu_attack.enabled = true
	player.cpu_interceptor.ball = ball
	player.cpu_interceptor.enabled = true
	if player.cpu_patrol.route == null:
		player.cpu_patrol.route = _mirrored_route(player.team_id)
		player.cpu_patrol.enabled = player.cpu_patrol.route != null
	if player.cpu_defense == null:
		var defense := CpuBallDefense.new()
		defense.name = "CpuBallDefense"
		defense.ball = ball
		defense.movement = player.cpu_movement
		defense.defended_goal = defended
		defense.enabled = true
		player.add_child(defense)
		player.cpu_defense = defense


var _mirror_route: CpuPatrolRoute

## Ruta de patrulla del rival reflejada en el centro de la cancha, solo para el equipo sin ruta propia.
## Un compañero sin ruta en un equipo que ya la tiene conserva su comportamiento de escena.
func _mirrored_route(team: int) -> CpuPatrolRoute:
	var source: CpuPatrolRoute
	for player in players:
		if is_instance_valid(player) and player.cpu_patrol.route != null and player.cpu_patrol.route != _mirror_route:
			if player.team_id == team:
				return null
			source = player.cpu_patrol.route
	if is_instance_valid(_mirror_route):
		return _mirror_route
	if source == null:
		return null
	var mirror_x := func(point: Vector2) -> Vector2: return Vector2(2.0 * kickoff_position.x - point.x, point.y)
	var parent := source.get_parent() as Node2D
	_mirror_route = CpuPatrolRoute.new()
	_mirror_route.show_route = false
	_mirror_route.position = parent.to_local(mirror_x.call(source.global_position))
	for point in source.get_waypoint_positions():
		var marker := Marker2D.new()
		marker.position = parent.to_local(mirror_x.call(point)) - _mirror_route.position
		_mirror_route.add_child(marker)
	# La escena sigue armando sus hijos durante _ready; se agrega al terminar.
	parent.add_child.call_deferred(_mirror_route)
	return _mirror_route


## Viste a cada equipo con el kit de su club (fila de paleta y patrón) y la piel de su plantilla.
## Los colores y patrones viven en la paleta y el shader; aquí solo se eligen fila y patrón.
func apply_session() -> void:
	var next_in_team := {}
	for player in players:
		if not is_instance_valid(player) or not is_instance_valid(player.player_sprite):
			continue
		var club := GameSession.club_for_team(player.team_id)
		var material := player.player_sprite.material as ShaderMaterial
		if club == null or material == null:
			continue
		# La escena comparte un material por equipo; cada jugador necesita el suyo por la piel.
		material = material.duplicate() as ShaderMaterial
		material.set_shader_parameter("team_row", club.team_row)
		material.set_shader_parameter("shirt_pattern", club.shirt_pattern)
		var field := club.squad.filter(func(p: SquadPlayer) -> bool:
			return p.role != SquadPlayer.Role.GOALIE)
		if not field.is_empty():
			var index: int = next_in_team.get(player.team_id, 0)
			material.set_shader_parameter("skin_row", (field[index % field.size()] as SquadPlayer).skin_row)
			next_in_team[player.team_id] = index + 1
		player.player_sprite.material = material


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
		# El humano del equipo saca; sin humano, el más cercano.
		if player.control_scheme != Player.ControlScheme.CPU:
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
