extends Node
## Estado compartido entre pantallas: modo, clubes elegidos y nivel del campeonato.

enum Mode {SINGLE, PVP}

const CLUBS_DIR := "res://scenes/clubs/"
## Mientras no exista la selección de equipo, el partido usa el cruce original.
const DEFAULT_HOME := &"melgar"
const DEFAULT_AWAY := &"alianza"

var mode := Mode.SINGLE
var home_club: ClubData
var away_club: ClubData
var level := 1

var _clubs: Array[ClubData] = []


func _ready() -> void:
	# list_directory resuelve los .remap de una exportación; DirAccess no.
	for file in ResourceLoader.list_directory(CLUBS_DIR):
		if file.ends_with(".tres"):
			var club := load(CLUBS_DIR + file) as ClubData
			if club != null:
				_clubs.append(club)
	home_club = get_club(DEFAULT_HOME)
	away_club = get_club(DEFAULT_AWAY)


func get_clubs(only_approved := true) -> Array[ClubData]:
	if not only_approved:
		return _clubs.duplicate()
	return _clubs.filter(func(club: ClubData) -> bool:
		return club.design_status == ClubData.DesignStatus.APPROVED)


func get_club(club_id: StringName) -> ClubData:
	for club in _clubs:
		if club.id == club_id:
			return club
	return null


func club_for_team(team: int) -> ClubData:
	return home_club if team == 0 else away_club
