extends SceneTree
## Check headless de los datos de clubes: plantilla 1-2-2-1, filas de paleta e ids únicos.
## Uso: godot --headless --path . --script res://tests/clubs_check.gd

const CLUBS_DIR := "res://scenes/clubs/"
const EXPECTED_ROLES := [0, 1, 1, 2, 2, 3]  # GOALIE, 2 DEFENSE, 2 MIDFIELD, OFFENSE


func _init() -> void:
	var errors: Array[String] = []
	var ids := {}
	var rows := {}
	for file in ResourceLoader.list_directory(CLUBS_DIR):
		if not file.ends_with(".tres"):
			continue
		var club := load(CLUBS_DIR + file) as ClubData
		if club == null:
			errors.append("%s no es ClubData" % file)
			continue
		if ids.has(club.id) or rows.has(club.team_row):
			errors.append("%s repite id o team_row" % file)
		ids[club.id] = true
		rows[club.team_row] = true
		if club.flag == null or club.short_name.is_empty() or club.short_name.length() > 9:
			errors.append("%s sin bandera o short_name inválido" % file)
		var roles := club.squad.map(func(p: SquadPlayer) -> int: return p.role)
		roles.sort()
		if roles != EXPECTED_ROLES:
			errors.append("%s plantilla %s, se espera 1-2-2-1" % [file, roles])
	if ids.size() < 4:
		errors.append("solo %d clubes" % ids.size())
	for error in errors:
		push_error(error)
	print("OK %d clubes" % ids.size() if errors.is_empty() else "FALLO")
	quit(0 if errors.is_empty() else 1)
