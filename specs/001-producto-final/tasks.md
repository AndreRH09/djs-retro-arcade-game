---
description: "Task list: Producto final DSJRetro"
---

# Tasks: Producto final DSJRetro

**Input**: Design documents from `specs/001-producto-final/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/ui-flow.md, quickstart.md

**Tests**: no se pidió TDD. Solo los checks headless que exige la constitución (Principio IV) para lógica no trivial (torneo, árbol de decisión).

**Organization**: una fase por historia. `USn` = historia n del spec; su HU de Notion va en el encabezado de cada fase (US1–US2 = HU-08, US3 = HU-12, US4 = HU-13, US5 = HU-14, US6–US7 = HU-09, US8–US11 = HU-15..HU-18, US12 = HU-19, US13 = HU-20, US14 = HU-21, US15 = HU-22, US16 = HU-23).

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup

- [ ] T001 Crear carpetas `scenes/session/`, `scenes/clubs/`, `scenes/screens/`, `scenes/tournament/`, `tests/` según plan.md
- [ ] T002 [P] Menús usan las acciones nativas `ui_accept`/`ui_cancel`/`ui_up`/`ui_down` de Godot más `KeyUtils` PASS (K/F) para confirmar; sin cambios en `project.godot` (se implementa junto a T009)

---

## Phase 2: Foundational (bloquea todas las historias)

- [x] T003 [P] Crear Resource `SquadPlayer` en `scenes/clubs/squad_player.gd` (data-model.md `SquadPlayer.player_name`, `SquadPlayer.role`, `SquadPlayer.skin_row`, `SquadPlayer.speed`, `SquadPlayer.power`)
- [x] T004 [P] Crear Resource `ClubData` en `scenes/clubs/club_data.gd` (data-model.md `ClubData.id`, `ClubData.display_name`, `ClubData.short_name`, `ClubData.flag`, `ClubData.team_row`, `ClubData.shirt_pattern`, `ClubData.squad`, `ClubData.design_status`)
- [x] T005 Crear `scenes/clubs/{melgar,alianza,cristal,cienciano}.tres` con filas 9–12, patrones actuales, banderas existentes, `design_status = APPROVED` y 6 SquadPlayer ficticios cada uno (data-model.md `ClubData.squad`: 1 GOALIE, 2 DEFENSE, 2 MIDFIELD, 1 OFFENSE)
- [x] T006 Crear autoload `GameSession` en `scenes/session/game_session.gd` (data-model.md `GameSession.mode`, `GameSession.home_club`, `GameSession.away_club`, `GameSession.level`, `GameSession.tournament`) con `get_clubs()` que carga `scenes/clubs/*.tres`; registrar en `project.godot`
- [x] T007 Agregar `Player.set_control(scheme)` en `scenes/characters/player.gd` que cambia `control_scheme` y llama `reset_cpu_controllers()`
- [x] T008 `MatchController.apply_session()` en `scenes/match/match_controller.gd`: aplica `team_row`, `shirt_pattern` y skin de cada club al material de `playerSprite`; default Melgar vs Alianza si `GameSession` vacío (la escena sigue jugable sola)

**Checkpoint**: `match.tscn` corre headless sin `SCRIPT ERROR` con clubes desde `GameSession`.

---

## Phase 3: US1 - Menú principal (P1) 🎯 MVP

**Goal**: pantalla de entrada con 3 opciones. **Independent Test**: quickstart HU-08.

- [x] T009 [US1] Crear `scenes/screens/main_menu.tscn` + `main_menu.gd`: opciones Un jugador / PvP local / Salir, navegación ↑↓ y confirmar; fija `GameSession.mode` y cambia a `team_selection.tscn`
- [x] T010 [US1] Cambiar `run/main_scene` a `res://scenes/screens/main_menu.tscn` en `project.godot`

---

## Phase 4: US2 - Selección de equipo (P1)

**Goal**: elegir club(es). **Independent Test**: quickstart HU-08.

- [x] T011 [US2] Crear `scenes/screens/team_selection.tscn` + `team_selection.gd`: carrusel de clubes con `ClubData.design_status == APPROVED` (data-model.md `ClubData.design_status`), muestra bandera y `display_name`
- [ ] T012 [US2] PvP en `team_selection.gd`: P2 elige con A/D/F, bloquear club ya confirmado por el otro jugador (si confirman el mismo club en el mismo frame gana el primero en procesarse, P1), Esc vuelve al menú; al confirmar setea `GameSession.home_club/away_club` y va a `bracket.tscn` (SINGLE) o `match.tscn` (PVP) — HECHO salvo la llave: en SINGLE hoy va directo al partido con rival sorteado hasta T030

---

## Phase 5: US3 - Single Player, un manager de acciones (P1)

**Goal**: solo P1 controla, cambio al más cercano. **Independent Test**: quickstart HU-12.

- [ ] T013 [US3] Crear `TeamController` en `scenes/match/team_controller.gd` (data-model.md `TeamController.scheme`, `TeamController.players`, `TeamController.controlled`): cada physics frame, sin posesión → jugador de campo más cercano al balón (nunca GOALIE) con histéresis 8 px; nunca jugador en `RECOVERING`; resto `CPU` vía `Player.set_control`
- [ ] T014 [US3] Cambiar control al receptor tras pase propio: escuchar señal de liberación de `scenes/characters/ball/player_ball_interaction.gd` en `team_controller.gd`
- [ ] T015 [US3] `MatchController` instancia 1 `TeamController(P1)` para equipo 0 en SINGLE y deja equipo 1 en CPU en `scenes/match/match_controller.gd`; quitar asignación fija P1/P2 de `scenes/match/match.tscn`
- [ ] T016 [US3] Indicador del jugador controlado con color P1/P2 sigue al jugador activo en `scenes/match/match_player_indicator.gd`

---

## Phase 6: US4 - PvP local, dos managers (P1)

**Goal**: P1 vs P2. **Independent Test**: quickstart HU-13.

- [ ] T017 [US4] En PVP instanciar `TeamController(P1)` equipo 0 y `TeamController(P2)` equipo 1 en `scenes/match/match_controller.gd`
- [ ] T018 [US4] Esc durante partido PvP vuelve al menú; R revancha con mismos clubes en `scenes/match/match_session.gd`

---

## Phase 7: US13 - HUD dinámico (P1)

**Goal**: marcador con clubes reales. **Independent Test**: quickstart HU-20.

- [x] T019 [US13] `scenes/match/match_hud.gd` lee `flag` y `short_name` de `GameSession.home_club/away_club` (data-model.md `ClubData.flag`, `ClubData.short_name`) en vez de constantes MELGAR/ALIANZA; dibujar bandera a tamaño nativo 22×14 o recortada a la barra (fix visual pendiente de PR #1)

**Checkpoint MVP (Sprint 1)**: menú → selección → partido SP o PvP con HUD correcto.

---

## Phase 8: US5 - IA por árbol de decisión (P2)

**Goal**: CPU decide por árbol. **Independent Test**: quickstart HU-14 + check.

- [ ] T020 [P] [US5] Crear Resources `DecisionNode` y `DecisionAction` en `scenes/characters/ai/decision_node.gd` y `decision_action.gd` (data-model.md `DecisionNode.condition`, `DecisionNode.threshold`, `DecisionNode.yes`, `DecisionNode.no`, `DecisionAction.action`)
- [ ] T021 [US5] Crear `CpuBrain` en `scenes/characters/ai/cpu_brain.gd`: evalúa condiciones de research.md R2 cada `CpuDifficulty.decision_interval`, activa/desactiva `cpu_ball_interceptor`, `cpu_ball_defense`, `cpu_patrol`, `cpu_ball_attack` según la hoja; registra última acción para debug
- [ ] T022 [US5] Crear árbol `scenes/characters/ai/trees/default_tree.tres` (posesión → distancia al arco → compañero libre → disparo/pase/conducción; sin posesión → más cercano persigue, otro cubre)
- [ ] T023 [US5] Integrar `CpuBrain` en `scenes/characters/player.gd` y `scenes/characters/player.tscn` reemplazando la llamada directa a `cpu_attack.update` cuando el jugador es CPU
- [ ] T024 [US5] Check headless `tests/decision_tree_check.gd`: todo camino termina en `DecisionAction`; casos fijos (tengo balón cerca del arco → SHOOT; balón libre y soy el más cercano → CHASE_BALL); además corre un partido CPU vs CPU headless de 2 min y verifica ≥4 tipos de `DecisionAction` distintos registrados por `CpuBrain` (SC-004); imprime "OK"

---

## Phase 9: US6 - Dificultad por nivel (P2)

**Goal**: nivel 1/2/3 = easy/normal/hard. **Independent Test**: quickstart HU-09.

- [ ] T025 [US6] `MatchController.apply_session()` asigna `easy/normal/hard.tres` a `CpuMovement.difficulty` de jugadores CPU según `GameSession.level` (data-model.md `GameSession.level`) en `scenes/match/match_controller.gd`
- [ ] T026 [US6] `CpuBrain` aplica ruido ±`target_error` a umbrales del árbol en `scenes/characters/ai/cpu_brain.gd`
- [ ] T027 [US6] Ajustar valores de `scenes/characters/ai/{easy,normal,hard}.tres` jugando 3 partidos por nivel hasta cumplir SC-005

---

## Phase 9A: US15 - Partido 6v6 con formación (P2)

**Goal**: 12 jugadores en cancha por rol. **Independent Test**: quickstart HU-22.

- [ ] T046 [US15] Prueba de escala: instanciar 6 `player.tscn` por lado en `scenes/match/match.tscn`; ajustar tamaño de cancha / `movement_bounds` y `scenes/match/match_camera.gd` si 12 jugadores no caben (research.md R9)
- [ ] T047 [P] [US15] Crear Resource `Formation` en `scenes/match/formation.gd` y `scenes/match/formation_default.tres` 1-2-2-1 (data-model.md `Formation.slots`)
- [ ] T048 [US15] `MatchController` instancia jugadores desde `ClubData.squad` (data-model.md `ClubData.squad`, `SquadPlayer.role`) y los coloca con `Formation` espejada para el visitante en `scenes/match/match_controller.gd`; `_prepare_kickoff` restablece la formación
- [ ] T049 [US15] `CpuBrain` regresa a cada jugador a la zona de su rol cuando no persigue el balón (ruta de `cpu_patrol` = zona) en `scenes/characters/ai/cpu_brain.gd`
- [ ] T050 [US15] Medir fps con 12 jugadores en partido completo (SC-010); si cae, subir `decision_interval` de CPU lejanas al balón

---

## Phase 9B: US16 - Arquero (P2)

**Goal**: arquero CPU que ataja y saca. **Independent Test**: quickstart HU-23.

- [ ] T051 [US16] Crear `CpuGoalie` en `scenes/characters/ai/cpu_goalie.gd`: sigue proyección del balón sobre la línea (`scenes/ball/ball_prediction.gd`), se lanza ante disparo a su alcance con probabilidad/reacción de `CpuDifficulty`, con balón espera 0.5 s y pasa o despeja (research.md R10)
- [ ] T052 [US16] Estado/animación de estirada en `scenes/characters/player.gd` y `scenes/characters/player.tscn`; protección contra entradas dentro del área en `scenes/characters/ball/player_ball_tackle.gd`
- [ ] T053 [US16] Activar `CpuGoalie` (y nunca `TeamController`) en jugadores con `SquadPlayer.role == GOALIE` desde `scenes/match/match_controller.gd`
- [ ] T054 [US16] Ajustar tasa de atajada por nivel con 20 disparos de prueba por nivel hasta cumplir SC-011

---

## Phase 10: US7 - Campeonato 3 niveles (P2)

**Goal**: llaves de 8. **Independent Test**: quickstart HU-09 + check. Depende de US2, US3, US6, US15, US16 y de US8–US11 aprobados (8 clubes).

- [ ] T028 [US7] Crear `Tournament` (RefCounted) en `scenes/tournament/tournament.gd` (data-model.md `Tournament.clubs`, `Tournament.round`, `Tournament.matches`, `Tournament.winners`): barajar, cruces, `record_player_result(won)`, resolver CPU vs CPU ponderado por plantilla, `eliminated`, `champion`
- [ ] T029 [US7] Check headless `tests/tournament_check.gd`: 8 clubes → 4/2/1 cruces; ganar 3 veces → campeón = jugador; perder → eliminado; siempre hay ganador; imprime "OK"
- [ ] T030 [US7] Crear `scenes/screens/bracket.tscn` + `bracket.gd`: dibuja cruces con banderas, resalta jugador, K continúa al partido; muestra campeón/eliminado y vuelve al menú
- [ ] T031 [US7] Al terminar partido en SINGLE, `scenes/match/match_controller.gd` llama `GameSession.tournament.record_player_result()`, sube `GameSession.level` y vuelve a `bracket.tscn`; R reinicia solo el partido

---

## Phase 11: US8–US11 - Diseño de 4 clubes nuevos (P2, en paralelo)

**Goal**: kits, banderas y plantillas aprobadas. **Independent Test**: quickstart HU-15..18.
Un club en `PROPOSED` puede mergearse a `main` pero queda oculto en selección y llaves hasta `APPROVED` (FR-012, constitución II; data-model.md `ClubData.design_status`).

- [ ] T032 Ampliar `assets/art/palettes/teams-color-palette.png` a 8×17 (filas 13–16 vacías) y `hint_range(0, 16)` en `scenes/match/player_palette.gdshader`
- [ ] T033 [P] [US8] Universitario: fila 13 con colores de research.md R6, `assets/art/ui/flags/flag-universitario.png` 22×14, `scenes/clubs/universitario.tres` `design_status = PROPOSED`
- [ ] T034 [P] [US9] Sport Huancayo: fila 14, `flag-huancayo.png`, `scenes/clubs/huancayo.tres` PROPOSED
- [ ] T035 [P] [US10] ADT: fila 15 (patrón 2 franjas), `flag-adt.png`, `scenes/clubs/adt.tres` PROPOSED
- [ ] T036 [P] [US11] Cusco FC: fila 16, `flag-cusco.png`, `scenes/clubs/cusco.tres` PROPOSED
- [ ] T037 Regenerar `docs/kits-liga1-preview.png` con los 8 kits y banderas; subir a la HU de Notion para aprobación
- [ ] T038 Tras aprobación en Notion, poner `design_status = APPROVED` en cada `.tres` de `scenes/clubs/` (ajustar colores si "Con cambios")

---

## Phase 12: US12 - Plantillas por equipo (P3)

- [ ] T039 [US12] `MatchController.apply_session()` aplica `SquadPlayer.speed`, `SquadPlayer.power`, `SquadPlayer.skin_row` y `display_name` a cada jugador (data-model.md `SquadPlayer.*`) en `scenes/match/match_controller.gd`; `power` multiplica fuerza de disparo en `scenes/characters/ball/player_ball_interaction.gd`
- [ ] T040 [US12] Mostrar nombres de ambos equipos en el aviso de saque inicial en `scenes/match/match_hud.gd`

---

## Phase 13: US14 - Audio menú y torneo (P3)

- [ ] T041 [P] [US14] Agregar pistas `menu` y `tournament` a `scenes/audio/music_player.gd` y assets en `assets/music/`; créditos en `THIRD_PARTY_NOTICES.md`
- [ ] T042 [US14] Agregar sfx `ui_navigate` a `scenes/audio/sound_player.gd` y llamarlo en `main_menu.gd`, `team_selection.gd`, `bracket.gd`

---

## Phase 14: Polish

- [ ] T043 [P] Actualizar `README.md` (modos, campeonato, clubes, controles de menú)
- [ ] T044 Ejecutar quickstart completo y check headless; corregir errores
- [ ] T045 [P] Eliminar escena de práctica obsoleta si ya no se usa (`scenes/main.tscn`, `scenes/training/`) solo si ninguna HU la referencia

---

## Dependencies & Execution Order

- Setup → Foundational → historias.
- US1 → US2 → (US3, US13 en paralelo) → US4 (usa `TeamController` de US3).
- US5 → US6 → US15 → US16 → US7. US7 también requiere US8–US11 aprobados.
- T046–T054 se numeraron al final (añadidos al pasar a 6v6) pero se ejecutan antes de US7 (Phase 10).
- US8–US11 independientes entre sí y del código (diseño), arrancan tras T032.
- US12 tras Foundational; US14 tras US1/US7.

## Sprints sugeridos

| Sprint | Historias | Tasks |
|---|---|---|
| 1 | US1, US2, US3, US4, US13 | T001–T019 |
| 2 | US5, US6, US15, US16 | T020–T027, T046–T054 |
| Diseño (paralelo S1–S2) | US8–US11 | T032–T038 |
| 3 | US7, US12, US14 + Polish | T028–T031, T039–T045 |

## Parallel Examples

- Foundational: T003 ∥ T004.
- Diseño: T033 ∥ T034 ∥ T035 ∥ T036.
- US5: T020 en paralelo a US6 T027 (ajuste de perfiles).

## Implementation Strategy

MVP = Sprint 1 (menú, selección, SP y PvP con HUD). Cada sprint termina con check headless limpio y
PR a `main`.
