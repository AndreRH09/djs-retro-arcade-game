# DSJRetro Constitution

## Core Principles

### I. Componentes Godot
Las escenas MUST componerse de nodos-componente con una sola responsabilidad (patrón existente
`scenes/characters/ai/cpu_*.gd`, `scenes/characters/ball/player_ball_*.gd`). Todo GDScript MUST
usar tipado estático. Una nueva capacidad se agrega como componente o recurso, no inflando
`player.gd` ni `match_controller.gd`.

### II. Kits por paleta + shader
Las equipaciones MUST resolverse con filas de `assets/art/palettes/teams-color-palette.png` y
`scenes/match/player_palette.gdshader`. Prohibido duplicar sprites por equipo. Todo diseño de
equipo (kit, bandera, plantilla) MUST tener preview aprobada antes de integrarse a `main`.

### III. Referencia, no copia
`nicolasbize/soccer-course` es referente de mecánicas y flujo. El código MUST reimplementarse con
la estructura de este proyecto; assets o fragmentos reutilizados MUST acreditarse en
`THIRD_PARTY_NOTICES.md`.

### IV. Verificable por historia
Cada historia de usuario MUST poder probarse sola: una escena jugable que la demuestra y una
ejecución headless de Godot 4.7 sin `SCRIPT ERROR`. Lógica no trivial (torneo, árbol de decisión)
MUST dejar un check ejecutable mínimo.

### V. Simplicidad
YAGNI: mínimo código que cumpla la historia, sin abstracciones especulativas ni dependencias
nuevas cuando Godot ya lo resuelve. Textos de UI MUST estar en español.

## Restricciones técnicas
- Godot 4.7, renderer GL Compatibility, viewport 280×180 pixel art con escalado entero.
- Controles teclado: P1 flechas/K (pase)/L (tiro); P2 WASD/F (pase)/G (tiro); R reinicia; F1 ayuda.
- Modos: Single Player activa un solo manager de entrada humano; PvP activa dos.

## Flujo de desarrollo
- Una rama por feature; specs en `specs/<NNN-feature>/` (spec, plan, tasks, backlog).
- PR a `main` solo con verificación headless limpia y revisión de diff.
- Backlog de HU sincronizado con el tablero de Notion del proyecto.

## Governance
Esta constitución prevalece sobre otras prácticas. Enmiendas MUST documentarse con Sync Impact
Report y versión semántica (MAJOR: redefinir/eliminar principio; MINOR: principio o sección nueva;
PATCH: redacción). Cada PR y cada `plan.md` MUST verificar cumplimiento (Constitution Check);
toda complejidad extra MUST justificarse en el plan.

**Version**: 1.0.0 | **Ratified**: 2026-11-25 | **Last Amended**: 2026-11-25
