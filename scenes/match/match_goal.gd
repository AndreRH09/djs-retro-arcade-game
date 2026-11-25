@tool
class_name SoccerGoal
extends Node2D
## Portería configurable. El balón comprueba el cruce de esta línea en su física;
## este nodo describe la abertura y coloca el arte original de red y postes.

const GoalArt := preload("res://scenes/match/match_goal_art.gd")

@export_enum("Izquierda:-1", "Derecha:1") var side: int = -1:
	set(value):
		side = -1 if value < 0 else 1
		_refresh_art()
## Equipo que SUMA un gol al entrar aquí: 0 = jugadores, 1 = CPU.
@export_enum("Jugadores:0", "CPU:1") var scoring_team: int = 1
@export_range(16.0, 160.0, 1.0, "suffix:px") var goal_width := 64.0:
	set(value):
		goal_width = value
		_refresh_art()
@export_range(8.0, 80.0, 1.0, "suffix:px") var height := 40.0:
	set(value):
		height = value
		_refresh_art()
@export_range(8.0, 60.0, 1.0, "suffix:px") var depth := 24.0:
	set(value):
		depth = value
		_refresh_art()
## Margen del balón: debe cruzar ENTERO la línea y caber entre los postes.
@export_range(0.0, 8.0, 0.5, "suffix:px") var radius := 3.0

var _far_frame: Polygon2D
var _near_frame: Polygon2D


func _ready() -> void:
	y_sort_enabled = true
	_refresh_art()


func _refresh_art() -> void:
	if not is_inside_tree():
		return
	if is_instance_valid(_far_frame):
		_far_frame.free()
	if is_instance_valid(_near_frame):
		_near_frame.free()
	_far_frame = GoalArt.create_frame(true, side, goal_width, height, depth)
	_near_frame = GoalArt.create_frame(false, side, goal_width, height, depth)
	add_child(_far_frame)
	add_child(_near_frame)


func get_definition() -> Dictionary:
	return {
		"side": side,
		"line_x": global_position.x,
		"min_y": global_position.y - goal_width * 0.5,
		"max_y": global_position.y + goal_width * 0.5,
		"height": height,
		"depth": depth,
		"scoring_team": scoring_team,
		"radius": radius,
	}
