class_name ClubData
extends Resource
## Club jugable: identidad, kit (fila de paleta + patrón) y plantilla.

enum DesignStatus {PROPOSED, APPROVED}

@export var id: StringName
@export var display_name := ""
## Nombre para marcador y avisos.
@export var short_name := ""
@export var flag: Texture2D
## Fila en teams-color-palette.png (ver player_palette.gdshader).
@export_range(9, 16) var team_row := 9
## 0 liso, 1 mitades, 2 franjas.
@export_range(0, 2) var shirt_pattern := 0
@export var squad: Array[SquadPlayer] = []
## Solo los clubes aprobados aparecen en selección y llaves.
@export var design_status := DesignStatus.PROPOSED
