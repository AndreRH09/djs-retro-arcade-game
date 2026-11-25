# Quickstart: validación del producto final

## Prerrequisitos
- Godot 4.7.2 (`GODOT_EXE` o en PATH). Proyecto importado: `godot --headless --path . --import`.

## Check headless (todas las HU)
```bash
godot --headless --path . --quit-after 300 2>&1 | grep "SCRIPT ERROR"   # esperado: vacío
godot --headless --path . --script res://tests/tournament_check.gd       # esperado: "OK"
godot --headless --path . --script res://tests/decision_tree_check.gd    # esperado: "OK"
godot --headless --path . res://tests/flow_check.tscn 2>&1 | grep -E "OK flujo|FALLO|SCRIPT ERROR"   # esperado: solo "OK flujo"
godot --headless --path . --script res://tests/clubs_check.gd             # esperado: "OK N clubes"
```

## Escenarios manuales
| HU | Pasos | Esperado |
|---|---|---|
| HU-08 | Abrir juego, ↑↓, K en cada opción | menú → selección / cierre |
| HU-08 | Un jugador → recorrer 8 clubes; PvP → intentar mismo club | banderas+nombres; PvP bloquea duplicado |
| HU-12 | Partido SP, pulsar WASD/F/G | nadie responde; control cambia al más cercano al perder balón |
| HU-13 | Partido PvP | cada jugador mueve solo su equipo |
| HU-14 | Partido SP, observar CPU 2 min | presiona, cubre, intercepta, pasa, dispara |
| HU-09 | Forzar nivel 1 y 3 (`GameSession.level`) | CPU nivel 3 reacciona y apunta mejor |
| HU-09 | Jugar campeonato completo (o forzar resultados) | llaves avanzan; derrota elimina; final → campeón |
| HU-15..18 | Ver `docs/kits-liga1-preview.png`; partido con cada club nuevo | diseño aprobado en Notion; kit correcto en animaciones |
| HU-19 | Iniciar partido | nombres de plantilla visibles; diferencias de velocidad |
| HU-20 | Cristal vs Cienciano | marcador con sus banderas y nombres |
| HU-21 | Navegar menú y llaves | música y sfx de navegación |
| HU-22 | Partido completo; anotar un gol | 6 por lado en formación; todos vuelven a su posición en el saque; fluido |
| HU-23 | 20 disparos al arco por nivel | ataja 20–40% (N1) / 40–60% (N3); saca el balón tras atrapar; ningún control humano lo toma |
