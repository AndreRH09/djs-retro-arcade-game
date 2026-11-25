# Implementation Plan: Producto final DSJRetro

**Branch**: `001-producto-final` | **Date**: 2026-11-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-producto-final/spec.md`

## Summary

Convertir el partido 2v2 actual en un juego completo: menú → selección → (campeonato de 3 niveles
| PvP amistoso) → partido. Un autoload `GameSession` guarda modo, clubes y nivel. Cada equipo humano
recibe un `TeamController` (manager de acciones) que asigna `Player.ControlScheme` P1/P2 al jugador
más cercano al balón y CPU al resto: Single Player instancia 1, PvP instancia 2. La IA pasa a un
`CpuBrain` que evalúa un árbol de decisión (recursos) y activa los componentes CPU existentes. Los
clubes son recursos `ClubData`; la paleta crece a 17 filas para 4 clubes nuevos. El flujo de
pantallas y llaves se inspira en `nicolasbize/soccer-course` sin copiar código.

## Technical Context

**Language/Version**: GDScript tipado, Godot 4.7.2

**Primary Dependencies**: Ninguna externa; motor Godot (GL Compatibility)

**Storage**: Recursos `.tres` en el proyecto (clubes, plantillas, árboles, dificultad); sin guardado persistente

**Testing**: Ejecución headless `godot --headless --path . --quit-after N` sin `SCRIPT ERROR`; scripts de check con `assert` vía `--script` para torneo y árbol; prueba manual por HU (quickstart)

**Target Platform**: Windows desktop (teclado), `Jugar.cmd`

**Project Type**: Juego 2D de escritorio

**Performance Goals**: 60 fps estable; evaluación del árbol cada `decision_interval` (0.1–0.4 s), no por frame

**Constraints**: Viewport 280×180, pixel art, escalado entero; teclado compartido P1/P2; UI en español

**Scale/Scope**: 4 pantallas nuevas (menú, selección, llaves, resultado), 8 clubes × 2 jugadores, 3 perfiles de dificultad, 14 HU

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Cumple | Cómo |
|---|---|---|
| I. Componentes Godot | ✅ | `TeamController`, `CpuBrain` son nodos-componente; `player.gd` solo gana un método `set_control()` |
| II. Kits por paleta + shader | ✅ | Filas 13–16 en paleta; sin sprites nuevos; aprobación de preview antes de merge (HU-08..11) |
| III. Referencia, no copia | ✅ | Llaves y pantallas reimplementadas; créditos ya en `THIRD_PARTY_NOTICES.md` (ampliar si se usa música `menu.mp3`/`tournament.mp3`) |
| IV. Verificable por historia | ✅ | Cada HU tiene escena/check en quickstart; `tournament_check.gd` y `decision_tree_check.gd` con assert |
| V. Simplicidad | ✅ | Cambio de escena con `change_scene_to_file`; sin state machine genérica de pantallas ni factories |

Post-diseño: sin violaciones. Complexity Tracking vacío.

## Project Structure

### Documentation (this feature)

```text
specs/001-producto-final/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── ui-flow.md        # pantallas, transiciones y controles
├── backlog.md            # HU para Notion
└── tasks.md              # /speckit-tasks
```

### Source Code (repository root)

```text
scenes/
├── session/
│   └── game_session.gd            # autoload: modo, clubes, nivel, torneo
├── clubs/
│   ├── club_data.gd               # Resource
│   ├── squad_player.gd            # Resource
│   └── *.tres                     # 8 clubes
├── screens/
│   ├── main_menu.tscn/.gd         # HU-01
│   ├── team_selection.tscn/.gd    # HU-02
│   └── bracket.tscn/.gd           # HU-07
├── match/
│   ├── team_controller.gd         # HU-03/04 manager de acciones
│   ├── match_controller.gd        # (mod) aplica GameSession
│   └── match_hud.gd               # (mod) HU-13
├── characters/ai/
│   ├── cpu_brain.gd               # HU-05 evalúa árbol
│   ├── decision_node.gd           # Resource condición
│   ├── decision_action.gd         # Resource hoja
│   └── trees/default_tree.tres
└── tournament/
    └── tournament.gd              # HU-07 RefCounted
tests/
├── tournament_check.gd
└── decision_tree_check.gd
assets/art/palettes/teams-color-palette.png   # 8×17
assets/art/ui/flags/flag-{universitario,huancayo,adt,cusco}.png
```

**Structure Decision**: proyecto Godot único; código nuevo en carpetas por dominio bajo `scenes/`,
siguiendo la organización actual (`scenes/match`, `scenes/characters/ai`). `tests/` solo contiene
scripts de check headless.

## Complexity Tracking

Sin violaciones.
