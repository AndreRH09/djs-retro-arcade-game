# Backlog: Producto final DSJRetro

Fuente para el tablero de Notion (table view). Estado inicial: **Planificado**.
Estimación en puntos (Fibonacci). Detalle en [spec.md](spec.md) y [tasks.md](tasks.md).

| ID | Título | Tipo | Prioridad | Sprint | Estado | Pts | Depende de | Tasks | Criterios de aceptación |
|---|---|---|---|---|---|---|---|---|---|
| HU-01 | Menú principal | HU | Alta (P1) | Sprint 1 | Planificado | 2 | — | T001, T002, T009, T010 | Menú con Un jugador / PvP local / Salir; navegación ↑↓; cada opción lleva a su destino |
| HU-02 | Selección de equipo | HU | Alta (P1) | Sprint 1 | Planificado | 5 | HU-01 | T003–T006, T011, T012 | 8 clubes con bandera y nombre; PvP impide club repetido; Esc vuelve |
| HU-03 | Single Player: un manager de acciones | HU | Alta (P1) | Sprint 1 | Planificado | 5 | HU-02 | T007, T008, T013–T016 | Solo P1 responde; control pasa al más cercano al balón y al receptor del pase; rival 100% CPU |
| HU-04 | PvP local: dos managers de acciones | HU | Alta (P1) | Sprint 1 | Planificado | 3 | HU-03 | T017, T018 | P1 y P2 controlan cada uno solo su equipo; R revancha; Esc menú |
| HU-13 | HUD dinámico | HU | Alta (P1) | Sprint 1 | Planificado | 2 | HU-02 | T019 | Marcador y avisos muestran bandera y nombre de los clubes en juego |
| HU-05 | IA rival por árbol de decisión | HU | Media (P2) | Sprint 2 | Planificado | 8 | HU-03 | T020–T024 | CPU presiona, cubre, intercepta, pasa y dispara según la situación; check del árbol OK |
| HU-06 | Dificultad por nivel | HU | Media (P2) | Sprint 2 | Planificado | 3 | HU-05 | T025–T027 | Nivel 1/2/3 = fácil/normal/difícil; victoria de prueba ≥70% en N1 → ≤40% en N3 |
| HU-15 | Partido 6v6 con formación | HU | Media (P2) | Sprint 2 | Planificado | 8 | HU-03, HU-05 | T046–T050 | 6 por lado (1 GK, 2 DEF, 2 MED, 1 DEL); formación en cada saque; zonas por rol; juego fluido con 12 jugadores |
| HU-16 | Arquero | HU | Media (P2) | Sprint 2 | Planificado | 5 | HU-15, HU-06 | T051–T054 | Arquero CPU sigue el balón, se lanza y ataja según nivel; saca tras atrapar; nunca lo controla un humano |
| HU-08 | Diseño Universitario (crema/granate) | Diseño | Media (P2) | Diseño | Planificado | 2 | T032 | T033, T037, T038 | Preview de kit + bandera aprobada; kit correcto en todas las animaciones |
| HU-09 | Diseño Sport Huancayo (naranja) | Diseño | Media (P2) | Diseño | Planificado | 2 | T032 | T034, T037, T038 | Preview aprobada; se distingue de los otros 7 clubes |
| HU-10 | Diseño ADT (celeste/blanco franjas) | Diseño | Media (P2) | Diseño | Planificado | 2 | T032 | T035, T037, T038 | Preview aprobada; se distingue de Cristal y Alianza |
| HU-11 | Diseño Cusco FC (dorado/negro) | Diseño | Media (P2) | Diseño | Planificado | 2 | T032 | T036, T037, T038 | Preview aprobada; se distingue de Melgar |
| HU-07 | Campeonato de 3 niveles (6v6 con arquero) | HU | Media (P2) | Sprint 3 | Planificado | 8 | HU-02, HU-03, HU-06, HU-15, HU-16, HU-08..11 | T028–T031 | Llaves de 8 (cuartos→semis→final); cruces CPU se resuelven solos; derrota elimina; final → campeón |
| HU-12 | Plantillas por equipo (6 jugadores con rol) | HU | Baja (P3) | Sprint 3 | Planificado | 3 | HU-02, HU-15 | T039, T040 | 6 nombres con rol visibles al inicio; velocidad/potencia afectan el juego |
| HU-14 | Audio de menú y torneo | HU | Baja (P3) | Sprint 3 | Planificado | 2 | HU-01, HU-07 | T041, T042 | Música de menú y llaves; sfx al navegar; sin superposición |

**Total**: 16 ítems (12 HU + 4 Diseño) · 62 pts · Sprint 1 = 17 pts · Sprint 2 = 24 pts · Diseño = 8 pts · Sprint 3 = 13 pts.

## Mapeo a Notion
Mapear a las columnas que ya existen en el tablero; crear solo las que falten: ID, Título (title),
Tipo (select), Prioridad (select), Sprint (select), Estado (status), Pts (number), Depende de (texto),
Criterios de aceptación (texto). El cuerpo de cada página lleva la historia y los escenarios Given/When/Then de spec.md.
