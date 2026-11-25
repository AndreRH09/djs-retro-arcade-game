# Contract: flujo de pantallas y controles

```text
main_menu ──Un jugador──▶ team_selection(SINGLE) ──▶ bracket ──▶ match ──▶ bracket ... ──▶ campeón / eliminado ──▶ main_menu
          ──PvP local───▶ team_selection(PVP)    ──▶ match ──R──▶ match (revancha) / Esc ──▶ main_menu
          ──Salir───────▶ quit
```

| Pantalla | Entrada | Salida |
|---|---|---|
| main_menu | P1 ↑↓, confirmar K | team_selection / quit |
| team_selection | P1 ←→ K (y P2 A/D F en PvP), Esc volver | bracket (SINGLE) / match (PVP) |
| bracket | K continuar | match o resultado final |
| match | controles actuales; R reinicia partido; F1 ayuda; Esc menú (PvP) | bracket (SINGLE al terminar) |

Controles de juego (sin cambio): P1 flechas / K pase / L tiro-entrada; P2 WASD / F pase / G tiro-entrada.
