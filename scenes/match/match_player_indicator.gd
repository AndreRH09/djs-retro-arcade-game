extends Node2D
## Indicadores del partido con las etiquetas pixel art originales del proyecto.
## Este componente solo presenta el control y la carga; no modifica la IA.

const CPU_LABEL := preload("res://assets/art/props/cpu.png")
const P1_LABEL := preload("res://assets/art/props/1p.png")
const P2_LABEL := preload("res://assets/art/props/2p.png")

@export var show_human_labels := true
@export var show_aim := true
@onready var player: Player = get_parent() as Player


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(player):
		return
	var interaction := player.ball_interaction
	if not is_instance_valid(interaction):
		return
	var carries_ball := interaction.has_ball()
	var is_human := player.control_scheme != Player.ControlScheme.CPU
	if carries_ball or (is_human and show_human_labels):
		# Las texturas miden 15 x 11: se dibujan a su tamaño original y sin filtro.
		var label: Texture2D = CPU_LABEL
		if player.control_scheme == Player.ControlScheme.P1:
			label = P1_LABEL
		elif player.control_scheme == Player.ControlScheme.P2:
			label = P2_LABEL
		draw_texture(label, Vector2(-7, -40))
	if not carries_ball:
		return
	var color := Color("f4ef39")
	if is_human and show_aim:
		var direction := interaction.aim_direction
		var tip := direction * 20.0
		var normal := direction.orthogonal() * 3.0
		draw_line(direction * 12.0, tip, color, 1.0)
		draw_line(tip, tip - direction * 4.0 + normal, color, 1.0)
		draw_line(tip, tip - direction * 4.0 - normal, color, 1.0)
	if interaction.action_state == PlayerBallInteraction.ActionState.CHARGING:
		draw_rect(Rect2(-12, -46, 24, 4), Color("202020"))
		draw_rect(Rect2(-11, -45, 22 * interaction.get_charge_ratio(), 2), color)
