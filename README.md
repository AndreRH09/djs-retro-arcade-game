# dsjRetro
godot engine retro game dev project

## Movimiento de la CPU

Al ejecutar `scenes/main.tscn`, `player` es la CPU y sigue a `player3` (P1)
con dificultad **Normal**. P1 usa las flechas y L para el tackle; P2 usa WASD
y G. El tackle conserva su duración de 0,2 s y requiere movimiento horizontal.

### Organización

- `scenes/characters/player.gd`: controles humanos, movimiento físico, límites,
  orientación, tackle y animaciones compartidas.
- `scenes/characters/ai/cpu_movement.gd`: seguimiento del objetivo, observaciones
  periódicas, anticipación y frenado al llegar (Seek + Arrive).
- `scenes/characters/ai/cpu_difficulty.gd`: definición de los ajustes de dificultad.
- `scenes/characters/ai/easy.tres`, `normal.tres`, `hard.tres`: perfiles editables
  desde el Inspector, sin cambiar el algoritmo.