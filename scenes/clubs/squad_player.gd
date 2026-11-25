class_name SquadPlayer
extends Resource
## Jugador de una plantilla. Los nombres son ficticios.

enum Role {GOALIE, DEFENSE, MIDFIELD, OFFENSE}

@export var player_name := ""
@export var role := Role.MIDFIELD
@export_range(0, 2) var skin_row := 0
@export_range(100.0, 140.0, 1.0) var speed := 120.0
## Multiplica la fuerza del disparo.
@export_range(0.8, 1.2, 0.01) var power := 1.0
