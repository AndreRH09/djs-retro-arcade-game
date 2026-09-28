extends Node
## Run with: godot --headless --path . tests/cpu_movement_test.tscn

const PROFILES := [
	preload("res://scenes/characters/ai/easy.tres"),
	preload("res://scenes/characters/ai/normal.tres"),
	preload("res://scenes/characters/ai/hard.tres"),
]

var _failures := 0
var _checks := 0


func _ready() -> void:
	run.call_deferred()


func run() -> void:
	test_arrival()
	test_reaction_and_prediction()
	test_visible_direction_changes()
	test_target_lifecycle_and_bounds()
	await test_scene_and_human_controls()
	print("CPU movement: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)


func test_arrival() -> void:
	var target := Node2D.new()
	add_child(target)
	target.position = Vector2(200.0, 100.0)
	for profile in PROFILES:
		for frequency in [30, 60, 120]:
			var controller := CpuMovement.new()
			controller.target = target
			controller.difficulty = profile
			var position := Vector2.ZERO
			var delta: float = 1.0 / frequency
			var respects_speed := true
			for tick in range(frequency * 6):
				var velocity := controller.get_velocity(position, 120.0, delta)
				respects_speed = respects_speed and velocity.length() <= 120.001
				position += velocity * delta
			check(respects_speed, "CPU exceeded player speed")
			var distance := position.distance_to(target.position)
			check(distance >= 16.0 - profile.target_error - 0.01, "CPU overshot arrival")
			check(distance <= 16.5 + profile.target_error, "CPU failed to approach target")
			var stays_still := true
			for tick in range(frequency * 2):
				stays_still = controller.get_velocity(position, 120.0, delta).is_zero_approx() and stays_still
			check(stays_still, "CPU jitters after arriving at a stationary target")
			controller.free()
	target.free()


func test_reaction_and_prediction() -> void:
	var target := CharacterBody2D.new()
	add_child(target)
	var reaction_times: Array[float] = []
	for profile in PROFILES:
		var controller := CpuMovement.new()
		controller.target = target
		controller.difficulty = profile.duplicate()
		controller.difficulty.target_error = 0.0
		target.position = Vector2(200.0, 0.0)
		target.velocity = Vector2(0.0, 120.0)
		var velocity := controller.get_velocity(Vector2.ZERO, 120.0, 0.01)
		var expected := Vector2(200.0, 120.0 * profile.prediction_time).normalized()
		check(velocity.normalized().is_equal_approx(expected), "Incorrect prediction for " + profile.resource_name)

		target.position = Vector2(-200.0, 0.0)
		target.velocity = Vector2.ZERO
		check(controller.get_velocity(Vector2.ZERO, 120.0, 0.01).x > 0.0, "CPU reacted before its next observation")
		var elapsed := 0.01
		while elapsed < profile.decision_interval + 0.1:
			elapsed += 0.01
			if controller.get_velocity(Vector2.ZERO, 120.0, 0.01).x < 0.0:
				break
		check(absf(elapsed - profile.decision_interval) <= 0.011, "Incorrect reaction interval")
		reaction_times.append(elapsed)
		controller.free()
	check(reaction_times[0] > reaction_times[1] and reaction_times[1] > reaction_times[2], "Difficulty must improve reaction time")
	target.free()


func test_visible_direction_changes() -> void:
	# Same target and speed: only the difficulty changes. A reversal should leave
	# easy heading the wrong way visibly longer than normal and hard.
	var target := CharacterBody2D.new()
	add_child(target)
	var controllers: Array[CpuMovement] = []
	var positions: Array[Vector2] = []
	for profile in PROFILES:
		var controller := CpuMovement.new()
		controller.target = target
		controller.difficulty = profile
		controllers.append(controller)
		positions.append(Vector2.ZERO)
		target.position = Vector2(200.0, 0.0)
		controller.get_velocity(Vector2.ZERO, 120.0, 0.01)
	target.position = Vector2(-200.0, 0.0)
	var velocities: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	for tick in range(40):
		for index in range(controllers.size()):
			velocities[index] = controllers[index].get_velocity(positions[index], 120.0, 0.01)
			positions[index] += velocities[index] * 0.01
		if tick == 9:
			check(velocities[0].x > 0.0 and velocities[1].x > 0.0, "Easy and normal should still follow the old observation at 0.1 s")
			check(velocities[2].x < 0.0, "Hard should react to a reversal within 0.1 s")
	check(velocities[0].x > 0.0, "Easy should visibly keep its old course at 0.4 s")
	check(velocities[1].x < 0.0 and velocities[2].x < 0.0, "Normal and hard should correct before 0.4 s")
	check(positions[0].x - positions[1].x > 25.0, "Easy and normal trajectories should visibly separate")
	check(positions[1].x - positions[2].x > 30.0, "Normal and hard trajectories should visibly separate")
	for controller in controllers:
		controller.free()
	target.free()


func test_target_lifecycle_and_bounds() -> void:
	var controller := CpuMovement.new()
	check(controller.get_velocity(Vector2.ZERO, 120.0, 0.1).is_zero_approx(), "Missing target must stop movement")
	var target := Node2D.new()
	add_child(target)
	target.position = Vector2(300.0, 50.0)
	controller.target = target
	controller.difficulty = CpuDifficulty.new()
	controller.difficulty.target_error = 0.0
	var position := Vector2(50.0, 50.0)
	var velocity := controller.get_velocity(position, 120.0, 2.0, Rect2(0, 0, 100, 100))
	position += velocity * 2.0
	check(position.is_equal_approx(Vector2(84.0, 50.0)), "Clamped destination and long step must preserve arrival distance")
	target.free()
	check(controller.get_velocity(position, 120.0, 0.1).is_zero_approx(), "Freed target must stop movement")
	var replacement := Node2D.new()
	add_child(replacement)
	replacement.position = Vector2(-100.0, 50.0)
	controller.target = replacement
	check(controller.get_velocity(position, 120.0, 0.01).x < 0.0, "Replacement target must clear old observations")
	controller.difficulty = null
	check(controller.get_velocity(position, 120.0, 0.01).is_finite(), "Missing difficulty must use the normal profile")
	controller.free()
	replacement.free()


func test_scene_and_human_controls() -> void:
	var world := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(world)
	var cpu := world.get_node("player") as Player
	var p1 := world.get_node("player3") as Player
	var p2 := world.get_node("player2") as Player
	check(cpu.cpu_movement.target == p1, "Scene CPU must follow P1")
	check(cpu.cpu_movement.difficulty.resource_name == "Normal", "Scene must start at normal difficulty")
	check(cpu.speed == 120.0 and p1.speed == 120.0 and p2.speed == 120.0, "Base player speed must remain 120 px/s")
	var initial_distance := cpu.position.distance_to(p1.position)
	for tick in range(180):
		await get_tree().physics_frame
	check(cpu.position.distance_to(p1.position) < initial_distance - 30.0, "Scene CPU failed to approach P1")
	check(cpu.animation_player.current_animation == "idle", "CPU must play idle after arrival")

	var start_position := p1.position
	Input.action_press("p1_right")
	Input.action_press("p1_down")
	for tick in range(3):
		await get_tree().physics_frame
	check(p1.position.x > start_position.x and p1.position.y > start_position.y, "P1 diagonal controls failed")
	check(is_equal_approx(p1.velocity.length(), p1.speed), "Diagonal input must not increase speed")
	check(p1.animation_player.current_animation == "running", "Human movement must play running")
	Input.action_release("p1_down")
	Input.action_press("p1_shoot")
	for tick in range(2):
		await get_tree().physics_frame
	check(p1.state == Player.State.TACKLING, "P1 tackle failed")
	check(p1.animation_player.current_animation == "tackle", "Tackle animation failed")
	Input.action_release("p1_shoot")
	Input.action_release("p1_right")
	for tick in range(20):
		await get_tree().physics_frame
	check(p1.state == Player.State.MOVING and p1.velocity.is_zero_approx(), "Tackle must end and restore movement input")

	Input.action_press("p2_left")
	for tick in range(3):
		await get_tree().physics_frame
	check(p2.velocity.x < 0.0 and p2.player_sprite.flip_h, "P2 movement and orientation failed")
	Input.action_release("p2_left")
	for corner in [p2.movement_bounds.position, p2.movement_bounds.end]:
		p2.position = corner
		var action := "p2_left" if corner == p2.movement_bounds.position else "p2_right"
		Input.action_press(action)
		for tick in range(3):
			await get_tree().physics_frame
		check(p2.position.is_equal_approx(corner), "Player escaped movement bounds")
		Input.action_release(action)
	world.free()
