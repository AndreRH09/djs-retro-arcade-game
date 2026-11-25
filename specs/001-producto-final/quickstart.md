# Quickstart: validación del producto final

## Prerrequisitos
- Godot 4.7.2 (`GODOT_EXE` o en PATH). Proyecto importado: `godot --headless --path . --import`.

## Check headless (todas las HU)
```bash
godot --headless --path . --quit-after 300 2>&1 | grep "SCRIPT ERROR"   # esperado: vacío
godot --headless --path . --script res://tests/tournament_check.gd       # esperado: "OK"
godot --headless --path . --script res://tests/decision_tree_check.gd    # esperado: "OK"
```

## Escenarios manuales
| HU | Pasos | Esperado |
|---|---|---|
| HU-01 | Abrir juego, ↑↓, K en cada opción | menú → selección / cierre |
| HU-02 | Un jugador → recorrer 8 clubes; PvP → intentar mismo club | banderas+nombres; PvP bloquea duplicado |
| HU-03 | Partido SP, pulsar WASD/F/G | nadie responde; control cambia al más cercano al perder balón |
| HU-04 | Partido PvP | cada jugador mueve solo su equipo |
| HU-05 | Partido SP, observar CPU 2 min | presiona, cubre, intercepta, pasa, dispara |
| HU-06 | Forzar nivel 1 y 3 (`GameSession.level`) | CPU nivel 3 reacciona y apunta mejor |
| HU-07 | Jugar campeonato completo (o forzar resultados) | llaves avanzan; derrota elimina; final → campeón |
| HU-08..11 | Ver `docs/kits-liga1-preview.png`; partido con cada club nuevo | diseño aprobado en Notion; kit correcto en animaciones |
| HU-12 | Iniciar partido | nombres de plantilla visibles; diferencias de velocidad |
| HU-13 | Cristal vs Cienciano | marcador con sus banderas y nombres |
| HU-14 | Navegar menú y llaves | música y sfx de navegación |
