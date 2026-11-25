@tool
extends RefCounted
## Adapta el arte del tutorial a la boca física sin cambiar los PNG originales.
## Se conservan dos capas: el poste lejano y la red con el poste cercano.

const TOP_TEXTURE := preload("res://assets/art/backgrounds/goal-top.png")
const BOTTOM_TEXTURE := preload("res://assets/art/backgrounds/goal-bottom.png")


static func create_frame(upper: bool, side: int, width: float, height: float, depth: float) -> Polygon2D:
	var frame := Polygon2D.new()
	frame.name = "FarFrame" if upper else "NearFrameAndNet"
	frame.texture = TOP_TEXTURE if upper else BOTTOM_TEXTURE
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# El origen se coloca en el pie del poste, como el origen de un jugador.
	# World y la portería ordenan por Y: el balón pasa entre ambas capas.
	frame.position.y = -width * 0.5 if upper else width * 0.5
	var rows := PackedFloat32Array([0.0, 1.0, 56.0, 59.0]) if upper \
		else PackedFloat32Array([0.0, 1.0, 58.0, 122.0, 125.0])
	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()
	var faces: Array[PackedInt32Array] = []
	for row in rows:
		for column in [0.0, 46.0]:
			var source := Vector2(column, row)
			uvs.append(source)
			vertices.append(source_to_goal(source, upper, side, width, height, depth) - frame.position)
	for index in range(rows.size() - 1):
		var first := index * 2
		faces.append(PackedInt32Array([first, first + 1, first + 3]))
		faces.append(PackedInt32Array([first, first + 3, first + 2]))
	frame.polygon = vertices
	frame.uv = uvs
	frame.polygons = faces
	return frame


static func source_to_goal(source: Vector2, upper: bool, side: int, width: float, height: float, depth: float) -> Vector2:
	var front_x: float
	var back_x: float
	var ground_y: float
	if upper:
		# PNG superior: poste en x=43, desde y=1 hasta su pie en y=56.
		front_x = 43.0
		back_x = 17.0
		ground_y = -width * 0.5 + (source.y - 56.0) / 55.0 * height
	elif source.y <= 58.0:
		# Techo/red: el dibujo original tiene perspectiva. Esta banda alinea
		# sus dos extremos con la línea que realmente comprueba el balón.
		var along_goal := (source.y - 1.0) / 57.0
		front_x = lerpf(43.0, 35.0, along_goal)
		back_x = lerpf(17.0, 11.0, along_goal)
		ground_y = -width * 0.5 - height + along_goal * width
	else:
		# Cara cercana: poste de y=58 a y=122; el fondo se inclina en el PNG.
		var down_post := (source.y - 58.0) / 64.0
		front_x = 35.0
		back_x = lerpf(11.0, 2.0, down_post)
		ground_y = width * 0.5 - height + down_post * height
	var outside_x := (source.x - front_x) / (front_x - back_x) * depth * -float(side)
	return Vector2(outside_x, ground_y)
