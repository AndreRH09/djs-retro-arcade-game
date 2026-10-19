# DSJRetro

Juego de fútbol arcade 2 contra 2, desarrollado con Godot 4.7. P1 y P2 juegan contra dos CPU. Gana el primer equipo que marque tres goles.

## Ejecutar

Abre `project.godot` en Godot 4.7 y pulsa **F5**. La escena principal es `scenes/match/match.tscn`.

En Windows puedes usar `Jugar.cmd`: busca Godot en `GODOT_EXE`, en el PATH o como `Godot.exe` junto al proyecto.

## Controles

| Acción | P1 | P2 |
| --- | --- | --- |
| Moverse y apuntar | Flechas | WASD |
| Pasar | K | F |
| Cargar y disparar | Mantener L y soltar | Mantener G y soltar |
| Robar sin balón | Moverse horizontalmente + L | Moverse horizontalmente + G |

**F1** abre la ayuda y pausa el partido. **F1** o **Esc** cierran la ayuda. **R** empieza un partido nuevo.

## Organización

- `scenes/match/`: partido, goles, marcador, cámara y ayuda.
- `scenes/characters/ai/`: movimiento, dificultad, patrulla, defensa, intercepción y ataque de la CPU.
- `scenes/characters/ball/`: conducción, pases, disparos y entradas.
- `scenes/ball/`: posesión, física y predicción del balón.
- `scenes/main.tscn`: cancha base y práctica de waypoints.

Los perfiles `easy.tres`, `normal.tres` y `hard.tres` ajustan la reacción, anticipación y precisión desde el Inspector de `CpuMovement`.

Referencia: [Soccer Course de Nicolas Bize](https://github.com/nicolasbize/soccer-course/releases/tag/v0.2.4). Créditos y licencia en [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
