@tool
class_name CpuPatrolRoute
extends Node2D
## Ruta fija en el mundo. Los Marker2D hijos se recorren en el orden del árbol.
## La posición de este nodo es el centro de la zona de presión.

@export var show_route: bool = true


func get_waypoint_positions() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for child in get_children():
		if child is Marker2D:
			points.append(child.global_position)
	return points


func _process(_delta: float) -> void:
	# También actualiza la guía al arrastrar los marcadores en el editor.
	queue_redraw()


func _draw() -> void:
	if not show_route:
		return
	var points := get_waypoint_positions()
	var color := Color(0.45, 0.95, 1.0, 0.65)
	for index in range(points.size()):
		var point := to_local(points[index])
		if points.size() > 1:
			var next := to_local(points[(index + 1) % points.size()])
			draw_line(point, next, Color(color, 0.3), 1.0)
		draw_circle(point, 2.0, color)
		draw_string(ThemeDB.fallback_font, point + Vector2(4, -3), str(index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
