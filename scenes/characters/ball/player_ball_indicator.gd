extends Node2D
## Identifica a P1/P2 y muestra dirección y carga sin mezclarlo con sus acciones.

@onready var player: Player = get_parent() as Player


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(player):
		return
	if player.control_scheme == Player.ControlScheme.CPU:
		_draw_charge(player.ball_interaction, Color(1.0, 0.85, 0.45))
		return
	var label := "P1" if player.control_scheme == Player.ControlScheme.P1 else "P2"
	var color := Color(0.5, 0.85, 1.0) if label == "P1" else Color(1.0, 0.9, 0.4)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var origin := Vector2(-width / 2.0, -34.0)
	draw_string_outline(font, origin, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 2, Color.BLACK)
	draw_string(font, origin, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
	var interaction := player.ball_interaction
	if not interaction.has_ball():
		return
	var tip := interaction.aim_direction * 20.0
	var normal := interaction.aim_direction.orthogonal() * 3.0
	draw_line(interaction.aim_direction * 12.0, tip, color, 1.0)
	draw_line(tip, tip - interaction.aim_direction * 4.0 + normal, color, 1.0)
	draw_line(tip, tip - interaction.aim_direction * 4.0 - normal, color, 1.0)
	_draw_charge(interaction, color)


func _draw_charge(interaction: PlayerBallInteraction, color: Color) -> void:
	if interaction.has_ball() and interaction.action_state == PlayerBallInteraction.ActionState.CHARGING:
		draw_rect(Rect2(-12, -45, 24, 4), Color(0.05, 0.1, 0.05))
		draw_rect(Rect2(-11, -44, 22 * interaction.get_charge_ratio(), 2), color)
