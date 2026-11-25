# Data Model: Producto final DSJRetro

## ClubData (Resource, `scenes/clubs/club_data.gd`)
| Campo | Tipo | Regla |
|---|---|---|
| id | StringName | único (`melgar`, `alianza`, `cristal`, `cienciano`, `universitario`, `huancayo`, `adt`, `cusco`) |
| display_name | String | ≤ 12 chars, mayúsculas en marcador |
| short_name | String | ≤ 9 chars para HUD y avisos |
| flag | Texture2D | 22×14 |
| team_row | int | 9–16, única por club |
| shirt_pattern | int | 0 liso, 1 mitades, 2 franjas |
| squad | Array[SquadPlayer] | exactamente 6: 1 GOALIE, 2 DEFENSE, 2 MIDFIELD, 1 OFFENSE |
| design_status | enum | PROPOSED → APPROVED (solo APPROVED seleccionable) |

## SquadPlayer (Resource)
| Campo | Tipo | Regla |
|---|---|---|
| player_name | String | ficticio, ≤ 10 chars |
| role | enum | GOALIE, DEFENSE, MIDFIELD, OFFENSE |
| skin_row | int | 0–2 |
| speed | float | 100–140 |
| power | float | 0.8–1.2 |

## GameSession (autoload)
| Campo | Tipo | Nota |
|---|---|---|
| mode | enum SINGLE, PVP | |
| home_club / away_club | ClubData | home = P1 |
| level | int 1–3 | solo SINGLE |
| tournament | Tournament | null en PVP |

## Tournament (RefCounted)
- `clubs: Array[StringName]` (8), `round: enum QUARTERS, SEMIS, FINAL, DONE`, `matches: Array[Array]` pares por ronda, `winners`.
- Transiciones: QUARTERS → SEMIS → FINAL → DONE si el jugador gana; cualquier derrota → `eliminated = true`.
- `level == round + 1`.

## CpuDifficulty (existente)
`decision_interval`, `prediction_time`, `target_error`; instancias `easy/normal/hard.tres` = nivel 1/2/3.

## DecisionNode / DecisionAction (Resource)
- DecisionNode: `condition` (enum R2), `threshold: float`, `yes: Resource`, `no: Resource`.
- DecisionAction: `action` (enum CHASE_BALL, PRESS, COVER_GOAL, PATROL, DRIBBLE, PASS, SHOOT).
- Validación: todo camino termina en DecisionAction (check en `tests/decision_tree_check.gd`).

## TeamController (Node)
`scheme: Player.ControlScheme` (P1|P2), `players: Array[Player]` (solo jugadores de campo, sin GOALIE), `controlled: Player`.
Invariante: exactamente un jugador del equipo con `scheme`, el resto CPU; el GOALIE nunca recibe `scheme`.

## Formation (Resource)
| Campo | Tipo | Regla |
|---|---|---|
| slots | Array[Dictionary] | 6 entradas `{role, kickoff_position: Vector2, zone: Rect2}` relativas a la mitad propia |
| Regla | | equipo visitante usa posiciones espejadas en X; cantidad por rol = composición de `ClubData.squad` |
