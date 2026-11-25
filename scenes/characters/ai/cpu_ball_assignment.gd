class_name CpuBallAssignment
extends RefCounted
## Coordinación mínima: un recuperador por equipo, elegido por cercanía al balón.
## El pasador deja espacio al receptor durante el tiempo de espera de su acción.


static func is_assigned(player: Player) -> bool:
	var interceptor := player.cpu_interceptor
	if not interceptor.enabled or not is_instance_valid(interceptor.ball):
		return false
	var ball := interceptor.ball
	if ball.state == SoccerBall.State.CARRIED:
		return ball.carrier == player
	if not _can_recover(player, ball):
		return false
	var nearest := player
	var nearest_distance := player.global_position.distance_squared_to(ball.global_position)
	for node in player.get_tree().get_nodes_in_group("players"):
		var other := node as Player
		if other == null or other == player or other.team_id != player.team_id:
			continue
		if other.control_scheme != Player.ControlScheme.CPU or not other.is_physics_processing():
			continue
		if not _can_recover(other, ball):
			continue
		var distance := other.global_position.distance_squared_to(ball.global_position)
		if distance < nearest_distance or (is_equal_approx(distance, nearest_distance) and other.get_instance_id() < nearest.get_instance_id()):
			nearest = other
			nearest_distance = distance
	return nearest == player


static func _can_recover(player: Player, ball: SoccerBall) -> bool:
	if player.speed <= 0.0 or not player.ball_interaction.enabled or player.ball_interaction.ball != ball:
		return false
	if not player.cpu_interceptor.enabled or player.cpu_interceptor.ball != ball:
		return false
	if not is_instance_valid(player.cpu_interceptor.movement) or not player.cpu_attack.allows_interception():
		return false
	# Un balón sin desplazamiento horizontal fuera de la zona no debe bloquear
	# la recuperación de otro compañero. Si se mueve, la predicción elige el punto.
	var bounds := player.movement_bounds
	if bounds.has_area() and ball.velocity.is_zero_approx():
		var closest := ball.global_position.clamp(bounds.position, bounds.end)
		if closest.distance_to(ball.global_position) >= maxf(ball.pickup_radius - 0.75, 0.0):
			return false
	return true
