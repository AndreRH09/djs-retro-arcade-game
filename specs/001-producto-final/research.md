# Research: Producto final DSJRetro

## R1. Manager de acciones (SP = 1, PvP = 2)
- **Decision**: `TeamController` (Node) por equipo humano con `scheme: Player.ControlScheme` y lista de jugadores de campo del equipo (excluye GOALIE). Cada physics frame: si el equipo no tiene posesión, elige el jugador de campo más cercano al balón (histéresis 8 px para evitar parpadeo) y le asigna `scheme`; el resto pasa a `CPU`. Al pase propio, cambia al receptor. Jugadores en `RECOVERING` no reciben control.
- **Rationale**: `player.gd` ya decide CPU/humano leyendo `control_scheme` cada frame; cambiar el enum en runtime + `reset_cpu_controllers()` basta. `KeyUtils` ya separa esquemas P1/P2.
- **Alternatives**: control fijo por jugador (actual, P1 y P2 en mismo equipo) — no cumple FR-003/004; input global con evento → más código sin beneficio.

## R2. IA por árbol de decisión
- **Decision**: `CpuBrain` (componente por jugador CPU) evalúa cada `CpuDifficulty.decision_interval` un árbol de `DecisionNode` (Resource: `condition` enum, `threshold`, `yes`, `no`) cuyas hojas `DecisionAction` (enum: CHASE_BALL, PRESS, COVER_GOAL, PATROL, DRIBBLE, PASS, SHOOT) habilitan el componente existente (`cpu_ball_interceptor`, `cpu_ball_defense`, `cpu_patrol`, `cpu_ball_attack`). Variación: umbrales con ruido ±`target_error` del perfil.
- **Rationale**: reutiliza toda la lógica de movimiento ya probada; el árbol solo decide. Recurso `.tres` editable en Inspector y testeable con assert sin escena.
- **Alternatives**: Behavior Tree con plugin (Beehave/LimboAI) — dependencia nueva, viola V; FSM del tutorial (`ai_behavior_field.gd`) — no es árbol de decisión pedido.
- **Condiciones mínimas**: TEAM_HAS_BALL, I_HAVE_BALL, BALL_FREE, DIST_TO_BALL, DIST_TO_GOAL, MATE_CLOSER_TO_BALL, OPPONENT_NEAR, MATE_OPEN.

## R3. Dificultad por nivel
- **Decision**: nivel 1/2/3 → `easy.tres`/`normal.tres`/`hard.tres` existentes (`CpuDifficulty`: `decision_interval`, `prediction_time`, `target_error`). `GameSession.level` selecciona el perfil al montar el partido.
- **Rationale**: perfiles ya existen y ya afectan reacción/anticipación/precisión.
- **Alternatives**: escalar valores por fórmula — menos ajustable a mano.

## R4. Campeonato
- **Decision**: `Tournament` (RefCounted) con 8 ids de club barajados, rondas QUARTERS/SEMIS/FINAL/DONE, `record_player_result(won)`, resuelve cruces CPU con aleatorio ponderado por suma de potencia/velocidad de plantilla (resultado 3–x). Vive en `GameSession`.
- **Rationale**: estructura equivalente a `tournament.gd` del tutorial, reescrita y testeable.
- **Alternatives**: simular partido CPU vs CPU real — lento, no aporta.

## R5. Pantallas
- **Decision**: `get_tree().change_scene_to_file()` entre `main_menu`, `team_selection`, `bracket`, `match`. Estado compartido en `GameSession`.
- **Rationale**: 4 pantallas; un screen-factory como el tutorial sobra (V).

## R6. Clubes y kits nuevos
- **Decision**: `ClubData` (.tres): `id`, `display_name`, `short_name`, `flag`, `team_row`, `shirt_pattern`, `squad: Array[SquadPlayer]`, `design_status` (PROPOSED/APPROVED). Paleta → 8×17: fila 13 Universitario, 14 Sport Huancayo, 15 ADT, 16 Cusco FC. Shader `hint_range(0, 16)`. Preview regenerado en `docs/kits-liga1-preview.png`. Selección filtra `design_status == APPROVED`.
- **Rationale**: mismo pipeline que kits 9–12 (Principio II).
- **Colores propuestos (a aprobar)**: Universitario camiseta crema `f2e6c8`/`cbbd98`, pantalón y medias granate `7a1f2b`/`531420`; Sport Huancayo naranja `f07a1a`/`b85810`, pantalón naranja, medias blancas; ADT camiseta celeste/blanca franjas (patrón 2), pantalón blanco, medias celestes; Cusco FC camiseta dorada `e0b02a`/`a8801a`, pantalón y medias negro `2a2a2e`/`121214`.

## R7. Plantillas
- **Decision**: 6 `SquadPlayer` por club (nombre ficticio, `role`, `skin_row` 0–2, `speed` 100–140, `power` 0.8–1.2 multiplicador de disparo). Aplicados en `MatchController` al montar el partido.
- **Alternatives**: JSON como el tutorial — `.tres` tipado editable en Inspector es más simple aquí.

## R9. Formato 6v6 y formación
- **Decision**: 6 jugadores por equipo (1 GOALIE + 2 DEFENSE + 2 MIDFIELD + 1 OFFENSE), roles como el enum `Role` del tutorial. `MatchController` instancia `scenes/characters/player.tscn` por cada `SquadPlayer` en vez de nodos fijos en `match.tscn`. `Formation` (Resource) da posición de saque y zona (Rect2 relativo a la mitad propia) por rol; espejada para el equipo visitante. Fuera de su acción, el `CpuBrain` devuelve al jugador a su zona (reutiliza `cpu_patrol`, cuya ruta pasa a ser la zona del rol).
- **Rationale**: escala la base sin duplicar escenas; zonas evitan que 10 jugadores CPU persigan el balón a la vez.
- **Riesgo**: cancha actual pensada para 2v2 — validar en T046 que 12 jugadores caben sin amontonarse; si no, ampliar `movement_bounds`/cancha y la cámara `match_camera.gd` ya sigue el balón.
- **Alternatives**: posiciones libres sin zonas — CPU se amontona en el balón.

## R10. Arquero
- **Decision**: componente `CpuGoalie` en el jugador con rol GOALIE: se mueve sobre la línea del arco siguiendo la proyección del balón (`scenes/ball/ball_prediction.gd`), se lanza (estado DIVING, animación existente o nueva) si un disparo cruza su alcance; probabilidad de atajada y tiempo de reacción vienen de `CpuDifficulty`. Con el balón: espera 0.5 s y pasa al compañero libre más cercano o despeja. Protegido de entradas dentro del área.
- **Rationale**: mismo patrón de componentes CPU; dificultad por nivel sin código extra.
- **Alternatives**: arquero como behavior separado tipo tutorial (`ai_behavior_goalie.gd`) — equivalente, pero ya tenemos patrón de componentes.

## R8. Audio
- **Decision**: añadir pistas menú y torneo a `MusicPlayer` y sfx `ui_navigate` a `SoundPlayer`. Fuente: assets del curso (licencia en `THIRD_PARTY_NOTICES.md`) o propios.
