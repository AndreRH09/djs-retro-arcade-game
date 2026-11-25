# Backlog: Producto final DSJRetro

Fuente para el tablero de Notion "DSJ - Juego Retro" (table view). Numeración continúa la del
tablero: HU-08 y HU-09 ya existían (se actualizan); HU-12 a HU-23 son nuevas.
Estado inicial: **Not started**. Puntos Fibonacci. Detalle en [spec.md](spec.md) y [tasks.md](tasks.md).

| ID | Título | Team | Prioridad | Sprint | Pts | Depende de | Spec | Tasks | Criterios de aceptación |
|---|---|---|---|---|---|---|---|---|---|
| HU-08 | Menú principal y selección de equipo | Design | Alta | Sprint 1 | 7 | — | US1, US2 | T001–T006, T009–T012 | Menú Un jugador / PvP local / Salir; 8 clubes con bandera y nombre; PvP impide club repetido; Esc vuelve |
| HU-12 | Single Player: un manager de acciones | Desarrollo | Alta | Sprint 1 | 5 | HU-08 | US3 | T007, T008, T013–T016 | Solo P1 responde; control pasa al jugador de campo más cercano y al receptor del pase; rival 100% CPU |
| HU-13 | PvP local: dos managers de acciones | Desarrollo | Alta | Sprint 1 | 3 | HU-12 | US4 | T017, T018 | P1 y P2 controlan cada uno solo su equipo; R revancha; Esc menú |
| HU-20 | HUD dinámico | Design | Alta | Sprint 1 | 2 | HU-08 | US13 | T019 | Marcador y avisos muestran bandera y nombre de los clubes en juego |
| HU-14 | IA rival por árbol de decisión | Desarrollo | Media | Sprint 2 | 8 | HU-12 | US5 | T020–T024 | CPU presiona, cubre, intercepta, pasa y dispara según la situación; ≥4 tipos de acción por partido; check OK |
| HU-22 | Partido 6v6 con formación | Desarrollo | Media | Sprint 2 | 8 | HU-12, HU-14 | US15 | T046–T050 | 6 por lado (1 GK, 2 DEF, 2 MED, 1 DEL); formación en cada saque; zonas por rol; fluido con 12 jugadores |
| HU-23 | Arquero | Desarrollo | Media | Sprint 2 | 5 | HU-22 | US16 | T051–T054 | Arquero CPU sigue el balón, se lanza y ataja según nivel; saca tras atrapar; nunca lo controla un humano |
| HU-15 | Diseño Universitario (crema/granate) | Design | Media | Diseño | 2 | T032 | US8 | T033, T037, T038 | Preview de kit + bandera aprobada; kit correcto en todas las animaciones |
| HU-16 | Diseño Sport Huancayo (naranja) | Design | Media | Diseño | 2 | T032 | US9 | T034, T037, T038 | Preview aprobada; se distingue de los otros 7 clubes |
| HU-17 | Diseño ADT (celeste/blanco franjas) | Design | Media | Diseño | 2 | T032 | US10 | T035, T037, T038 | Preview aprobada; se distingue de Cristal y Alianza |
| HU-18 | Diseño Cusco FC (dorado/negro) | Design | Media | Diseño | 2 | T032 | US11 | T036, T037, T038 | Preview aprobada; se distingue de Melgar |
| HU-09 | Dificultad progresiva y torneo (3 niveles, 6v6) | Desarrollo | Media | Sprint 3 | 11 | HU-08, HU-12, HU-14, HU-22, HU-23, HU-15..18 | US6, US7 | T025–T031 | Nivel 1/2/3 = fácil/normal/difícil; llaves de 8 cuartos→semis→final; cruces CPU se resuelven solos; derrota elimina; final → campeón |
| HU-19 | Plantillas por equipo (6 jugadores con rol) | Desarrollo | Baja | Sprint 3 | 3 | HU-08, HU-22 | US12 | T039, T040 | 6 nombres con rol visibles al inicio; velocidad/potencia afectan el juego |
| HU-21 | Audio de menú y torneo | Desarrollo | Baja | Sprint 3 | 2 | HU-08, HU-09 | US14 | T041, T042 | Música de menú y llaves; sfx al navegar; sin superposición |

**Total**: 14 ítems (2 actualizados + 12 nuevos) · 62 pts · Sprint 1 = 17 · Sprint 2 = 21 · Diseño = 8 · Sprint 3 = 16.
Nota: la dificultad (US6) se planifica en Sprint 2 dentro de tasks.md (T025–T027) aunque su HU-09 cierra en Sprint 3 junto al torneo.

## Mapeo a Notion
Name = "ID Título" · Status = Not started · Team = columna Team · Prioridad, Sprint, Puntos = columnas nuevas ·
AI keywords: Desarrollo → Integration (IA → Performance), Design → Visuals · Cuerpo: historia, criterios Given/When/Then y tasks.
