# Feature Specification: Producto final DSJRetro

**Feature Branch**: `001-producto-final`

**Created**: 2026-11-25

**Status**: Draft

**Input**: User description: "Completar DSJRetro (fútbol arcade 2v2, base actual: partido P1+P2 vs 2 CPU, kits Melgar/Alianza/Cristal/Cienciano) tomando como referencia nicolasbize/soccer-course. Menú, selección de equipo, Single Player con un solo manager de acciones, PvP local con dos managers, IA rival con árboles de decisión, dificultad por nivel, campeonato de 3 niveles con 8 equipos, 4 equipos peruanos nuevos con diseño aprobado, plantillas por equipo, HUD dinámico y audio de menú/torneo."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Menú principal (HU-08, Priority: P1)

Al iniciar el juego el jugador ve un menú con "Un jugador", "PvP local" y "Salir", navegable con
teclado.

**Why this priority**: Punto de entrada a todos los modos; sin él no existe flujo de producto.

**Independent Test**: Iniciar el juego, navegar las 3 opciones y verificar que cada una lleva a su
destino (selección de equipo o cierre).

**Acceptance Scenarios**:

1. **Given** el juego recién iniciado, **When** carga, **Then** se muestra el menú con la primera opción resaltada.
2. **Given** el menú, **When** P1 pulsa arriba/abajo, **Then** el resaltado cambia de opción.
3. **Given** "Un jugador" resaltado, **When** P1 confirma, **Then** se abre la selección de equipo en modo un jugador.
4. **Given** "Salir" resaltado, **When** P1 confirma, **Then** el juego se cierra.

---

### User Story 2 - Selección de equipo (HU-08, Priority: P1)

El jugador elige su club entre 8 equipos peruanos viendo bandera y nombre. En PvP, P1 y P2 eligen
cada uno su equipo y no pueden elegir el mismo.

**Why this priority**: Define quién juega; requisito de cualquier partido o campeonato.

**Independent Test**: Entrar desde el menú, recorrer los 8 equipos, confirmar y verificar que el
partido arranca con los equipos elegidos.

**Acceptance Scenarios**:

1. **Given** la pantalla de selección, **When** P1 navega, **Then** ve bandera y nombre de cada uno de los 8 clubes.
2. **Given** modo PvP, **When** P1 ya eligió Melgar, **Then** P2 no puede confirmar Melgar.
3. **Given** ambos equipos confirmados, **When** se pulsa confirmar, **Then** comienza el partido (PvP) o el campeonato (un jugador).
4. **Given** la selección, **When** se pulsa volver, **Then** regresa al menú.

---

### User Story 3 - Single Player con un manager de acciones (HU-12, Priority: P1)

En un jugador solo existe un control humano (P1). P1 controla a un jugador de campo de su equipo a
la vez; el control pasa automáticamente al jugador de campo más cercano al balón cuando su equipo
no lo tiene. Sus compañeros (incluido el arquero) y todo el equipo rival son controlados por la CPU.

**Why this priority**: Es el modo principal y base del campeonato.

**Independent Test**: Jugar un partido en un jugador: solo las teclas de P1 tienen efecto, las de
P2 no mueven a nadie, y el control cambia de jugador al perder el balón.

**Acceptance Scenarios**:

1. **Given** partido en un jugador, **When** se pulsan teclas de P2, **Then** ningún jugador responde.
2. **Given** el rival tiene el balón, **When** un compañero queda más cerca del balón que el jugador controlado, **Then** el control pasa a ese compañero y se indica visualmente.
3. **Given** P1 tiene el balón, **When** pasa a su compañero, **Then** el control pasa al receptor.
4. **Given** el partido, **When** transcurre, **Then** los dos rivales actúan sin intervención humana.

---

### User Story 4 - PvP local con dos managers (HU-13, Priority: P1)

Dos personas en el mismo teclado: P1 controla un equipo completo y P2 el otro. No hay rival CPU;
dentro de cada equipo los jugadores no controlados y el arquero los maneja la CPU como apoyo, y el
control cambia al jugador de campo más cercano al balón igual que en un jugador.

**Why this priority**: Modo frente a frente pedido explícitamente; reutiliza el control de HU-12.

**Independent Test**: Partido PvP donde P1 solo afecta a su equipo y P2 solo al suyo.

**Acceptance Scenarios**:

1. **Given** partido PvP, **When** P1 se mueve, **Then** solo se mueve un jugador del equipo de P1.
2. **Given** partido PvP, **When** P2 dispara, **Then** dispara el jugador controlado del equipo de P2.
3. **Given** un gol en PvP, **When** se reanuda, **Then** ambos jugadores conservan su equipo y controles.
4. **Given** partido PvP terminado, **When** se pulsa R, **Then** se juega de nuevo con los mismos equipos.

---

### User Story 5 - IA rival por árbol de decisión (HU-14, Priority: P2)

Los jugadores CPU deciden qué hacer (presionar, interceptar, cubrir, atacar, pasar, disparar)
según la situación del partido (quién tiene el balón, distancia al balón y al arco, posición del
compañero), con decisiones variadas y no repetitivas.

**Why this priority**: Requisito central del modo un jugador; necesita el flujo P1 ya funcionando.

**Independent Test**: Partido CPU vs CPU en escena de prueba: los jugadores cambian de
comportamiento según la situación y el registro de decisiones muestra varias ramas usadas.

**Acceptance Scenarios**:

1. **Given** el rival humano tiene el balón, **When** la CPU decide, **Then** el jugador CPU más cercano presiona y el resto mantiene la posición de su rol (defensa, medio, delantero).
2. **Given** la CPU tiene el balón cerca del arco rival, **When** decide, **Then** intenta disparar.
3. **Given** la CPU tiene el balón y un marcador cerca, **When** su compañero está libre, **Then** puede pasar.
4. **Given** el balón suelto, **When** la CPU decide, **Then** el jugador CPU más cercano va por él.

---

### User Story 6 - Dificultad por nivel (HU-09, Priority: P2)

La IA rival es más rápida en reaccionar, anticipa mejor y es más precisa en cada nivel del
campeonato: nivel 1 fácil, nivel 2 normal, nivel 3 difícil.

**Why this priority**: Da progresión al campeonato; depende de HU-14.

**Independent Test**: Jugar un partido forzando cada nivel y comparar el tiempo de reacción y la
precisión de la CPU.

**Acceptance Scenarios**:

1. **Given** nivel 1, **When** la CPU recupera un balón, **Then** reacciona más lento que en nivel 3.
2. **Given** nivel 3, **When** la CPU dispara, **Then** su precisión es mayor que en nivel 1.
3. **Given** el paso de nivel, **When** empieza el siguiente partido, **Then** se aplica la dificultad del nuevo nivel.

---

### User Story 7 - Campeonato de 3 niveles (HU-09, Priority: P2)

En un jugador, el equipo elegido entra a un torneo de llaves de 8 clubes: cuartos (nivel 1),
semifinal (nivel 2) y final (nivel 3). Una pantalla de llaves muestra los cruces; los partidos
entre equipos CPU se resuelven automáticamente. Perder elimina; ganar la final corona campeón.

**Why this priority**: Objetivo de producto del modo un jugador; depende de HU-08, HU-12 y HU-09.

**Independent Test**: Completar un torneo (o forzar resultados) y verificar avance, eliminación y
pantalla de campeón.

**Acceptance Scenarios**:

1. **Given** equipo elegido, **When** empieza el campeonato, **Then** la llave muestra 4 cruces con los 8 clubes y el del jugador incluido.
2. **Given** el jugador gana en cuartos, **When** vuelve a la llave, **Then** los otros cruces tienen ganador y avanza a semifinal.
3. **Given** el jugador pierde, **When** termina el partido, **Then** se muestra eliminación y opción de volver al menú.
4. **Given** el jugador gana la final, **When** termina, **Then** se muestra pantalla de campeón con música de victoria.

---

### User Story 8-11 - Diseño de 4 equipos nuevos (HU-15 a HU-18, Priority: P2)

Se agregan Universitario (crema/granate), Sport Huancayo (naranja), ADT (celeste/blanco) y Cusco
FC (dorado/negro). Cada uno tiene kit (camiseta, pantalón, medias, patrón), bandera para marcador
y llaves, y representación de sus jugadores. Cada diseño se presenta como vista previa y solo se
integra tras aprobación.

Una historia por club: HU-15 Universitario, HU-16 Sport Huancayo, HU-17 ADT, HU-18 Cusco FC.

**Why this priority**: Necesarios para completar 8 equipos del campeonato; diseño en paralelo.

**Independent Test**: Vista previa del kit y bandera aprobada; partido de prueba vistiendo al club
sin afectar los 4 kits existentes.

**Acceptance Scenarios**:

1. **Given** la propuesta de kit, **When** se revisa la vista previa, **Then** el diseño queda Aprobado o Con cambios.
2. **Given** kit aprobado, **When** un equipo lo viste en partido, **Then** se ve con sus colores en todas las animaciones.
3. **Given** los 8 kits, **When** se enfrentan dos clubes cualesquiera, **Then** se distinguen entre sí a simple vista.

---

### User Story 12 - Plantillas por equipo (HU-19, Priority: P3)

Cada club tiene plantilla de 6 jugadores (1 arquero + 5 de campo) con nombre, rol, tono de piel,
velocidad y potencia. Se muestran al iniciar cada partido del campeonato y afectan el juego.

**Why this priority**: Profundidad y representación; no bloquea el flujo jugable.

**Independent Test**: Iniciar partido con dos clubes y verificar nombres y diferencias de
velocidad/potencia según plantilla.

**Acceptance Scenarios**:

1. **Given** un partido, **When** inicia, **Then** se muestran los nombres de los jugadores de ambos equipos.
2. **Given** un jugador con más velocidad, **When** corre, **Then** es perceptiblemente más rápido.

---

### User Story 13 - HUD dinámico (HU-20, Priority: P1)

El marcador muestra nombre y bandera de los equipos que realmente juegan, no valores fijos.

**Why this priority**: Requisito directo de HU-08; hoy el marcador siempre dice MELGAR/ALIANZA.

**Independent Test**: Elegir dos clubes distintos y verificar nombres y banderas en marcador y
avisos de gol.

**Acceptance Scenarios**:

1. **Given** Cristal vs Cienciano, **When** inicia, **Then** el marcador muestra sus banderas y nombres.
2. **Given** un gol, **When** aparece el aviso, **Then** nombra al club que anotó.

---

### User Story 14 - Audio de menú y torneo (HU-21, Priority: P3)

Música propia en menú y pantalla de llaves; sonido al navegar y confirmar opciones.

**Why this priority**: Pulido; no bloquea funcionalidad.

**Independent Test**: Navegar menú y llaves verificando música y sonidos.

**Acceptance Scenarios**:

1. **Given** el menú, **When** se navega, **Then** suena el efecto de navegación.
2. **Given** cambio de menú a partido, **When** empieza, **Then** la música cambia a la de juego sin superponerse.

---

### User Story 15 - Partido 6v6 con formación (HU-22, Priority: P2)

Cada partido enfrenta 6 contra 6: 1 arquero y 5 de campo por equipo (defensas, medios,
delanteros). Cada jugador ocupa la zona de su rol, la cámara sigue el balón y en cada saque todos
vuelven a su formación.

**Why this priority**: Formato oficial de los partidos del campeonato; requisito de HU-09.

**Independent Test**: Partido de prueba: 12 jugadores en cancha, cada uno vuelve a su posición de
formación tras un gol y se mueve dentro de su zona.

**Acceptance Scenarios**:

1. **Given** inicio de partido, **When** se hace el saque, **Then** hay 6 jugadores por equipo en posición de formación.
2. **Given** un gol, **When** se reanuda, **Then** todos vuelven a su posición de formación.
3. **Given** el balón en campo rival, **When** juega la CPU, **Then** los defensas no abandonan su mitad salvo para recuperar.
4. **Given** 12 jugadores en pantalla, **When** se juega, **Then** el juego se mantiene fluido.

---

### User Story 16 - Arquero (HU-23, Priority: P2)

Cada equipo tiene un arquero controlado siempre por la CPU que se mueve sobre su línea, se lanza a
atajar disparos al arco y, al atrapar el balón, lo despeja o lo pasa a un compañero.

**Why this priority**: Parte del formato 6v6; sin arquero los goles son triviales.

**Independent Test**: Escena de disparos contra el arco: el arquero ataja una parte de los tiros y
saca el balón tras atraparlo.

**Acceptance Scenarios**:

1. **Given** un disparo hacia el arco, **When** está a su alcance, **Then** el arquero se lanza y puede atajar.
2. **Given** el arquero con el balón, **When** pasa un momento breve, **Then** pasa a un compañero o despeja.
3. **Given** el nivel 3, **When** se compara con el nivel 1, **Then** el arquero rival ataja con más frecuencia.
4. **Given** cualquier modo, **When** se juega, **Then** ningún control humano toma al arquero.

---

### Edge Cases

- Arquero atrapa el balón mientras un rival lo presiona: el rival no puede quitárselo dentro del área.
- Balón queda detenido dentro del área chica: el arquero sale a recogerlo.

- Ambos jugadores en PvP pulsan confirmar a la vez sobre el mismo club: gana quien confirmó primero; el otro debe elegir otro.
- El jugador controlado está derribado (recuperándose de entrada) cuando debería cambiar el control: el cambio espera o pasa al compañero disponible.
- Ambos jugadores de un equipo a igual distancia del balón: se mantiene el control actual (sin parpadeo).
- Partido CPU vs CPU en la llave: siempre produce un ganador.
- Reinicio (R) durante el campeonato: reinicia solo el partido actual, no el torneo.
- Diseño rechazado: el club no aparece en selección hasta su aprobación; el campeonato requiere 8 clubes aprobados.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El juego MUST abrir en un menú con opciones Un jugador, PvP local y Salir, navegable con teclado de P1.
- **FR-002**: La selección MUST mostrar 8 clubes con bandera y nombre; en PvP MUST impedir que ambos jugadores elijan el mismo club.
- **FR-003**: En un jugador MUST existir exactamente un control humano activo (P1); entradas de P2 MUST ignorarse.
- **FR-004**: En PvP MUST existir dos controles humanos, cada uno limitado a su equipo.
- **FR-005**: Cada control humano MUST manejar un jugador a la vez y cambiar al jugador de su equipo más cercano al balón cuando el equipo no tiene posesión, o al receptor de un pase.
- **FR-006**: El jugador controlado MUST indicarse visualmente con el color de su control (P1/P2).
- **FR-007**: Los jugadores CPU MUST elegir acción según estado del partido mediante reglas de decisión jerárquicas (posesión, distancias, posición del compañero).
- **FR-008**: La IA MUST tener 3 perfiles de dificultad que varían tiempo de reacción, anticipación y precisión.
- **FR-009**: El campeonato MUST tener 8 clubes en llaves de cuartos, semifinal y final, usando el perfil de dificultad 1, 2 y 3 respectivamente.
- **FR-010**: Partidos de la llave sin el jugador MUST resolverse automáticamente con un ganador.
- **FR-011**: Perder un partido del campeonato MUST eliminar al jugador; ganar la final MUST mostrar pantalla de campeón.
- **FR-012**: Cada club MUST tener kit, bandera y plantilla; los 4 clubes nuevos MUST tener estado de aprobación de diseño antes de estar disponibles.
- **FR-013**: Los 8 kits MUST distinguirse entre sí en cualquier cruce.
- **FR-014**: El marcador y avisos MUST mostrar nombre y bandera de los clubes en juego.
- **FR-015**: La plantilla MUST definir por jugador nombre, piel, velocidad y potencia, y velocidad/potencia MUST afectar el juego.
- **FR-016**: Menú y llaves MUST tener música propia; navegación y confirmación MUST tener sonido.
- **FR-017**: Un partido MUST terminar cuando un equipo llega a 3 goles (sin empates).
- **FR-018**: Toda UI MUST estar en español.
- **FR-019**: Cada partido MUST ser 6v6: 1 arquero y 5 jugadores de campo por equipo, ubicados por rol en una formación fija que se restablece en cada saque.
- **FR-020**: El arquero MUST ser controlado siempre por la CPU, atajar disparos a su alcance y reiniciar el juego (pase o despeje) tras atrapar el balón.
- **FR-021**: El cambio de control humano MUST considerar solo jugadores de campo.

### Key Entities

- **Club**: nombre, nombre corto para marcador, bandera, kit (colores y patrón), plantilla, estado de diseño (Propuesto/Aprobado).
- **Jugador de plantilla**: nombre, rol (arquero/defensa/medio/delantero), piel, velocidad, potencia; pertenece a un Club (6 por club).
- **Formación**: posición inicial y zona de cada rol en la cancha para cada lado.
- **Sesión de juego**: modo (Un jugador/PvP), clubes elegidos, nivel actual.
- **Campeonato**: 8 clubes, cruces por ronda, ganadores, ronda actual, campeón.
- **Perfil de dificultad**: reacción, anticipación, precisión; asociado a un nivel.
- **Manager de acciones**: control humano (P1/P2) asociado a un equipo y al jugador que maneja.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Desde el arranque, un jugador llega a jugar un partido en menos de 30 segundos y 5 pulsaciones.
- **SC-002**: En un jugador, 0 jugadores responden a teclas de P2 durante un partido completo.
- **SC-003**: En PvP, el 100% de las acciones de cada jugador afectan solo a su equipo.
- **SC-004**: En 10 partidos de prueba, la CPU usa al menos 4 tipos de acción distintos por partido.
- **SC-005**: La tasa de victoria de un jugador de prueba baja de nivel 1 a nivel 3 (p. ej. ≥70% → ≤40%).
- **SC-006**: Un campeonato completo (3 partidos) se puede terminar en menos de 20 minutos.
- **SC-007**: Los 4 diseños nuevos tienen aprobación registrada antes de su integración.
- **SC-008**: 5 de 5 evaluadores identifican correctamente los dos clubes en cualquier cruce viendo solo el campo.
- **SC-009**: 0 errores de script al cargar y jugar cada pantalla.
- **SC-010**: Con 12 jugadores en cancha el juego se mantiene fluido (sin caídas perceptibles) durante un partido completo.
- **SC-011**: En 20 disparos de prueba a nivel 1, el arquero ataja entre 20% y 40%; a nivel 3, entre 40% y 60%.

## Assumptions

- Todos los partidos (campeonato y PvP) son 6v6 con arquero, igual que la referencia del tutorial; el partido 2v2 actual es la base que se escala.
- El campeonato existe solo en modo un jugador; PvP es partido amistoso con revancha.
- Partido a 3 goles como hoy; no hay tiempo límite ni empates, por lo que no se requiere tanda de penales.
- Plantilla de 6 jugadores por club con nombres ficticios (no jugadores reales) para evitar uso de identidad real.
- Colores de clubes inspirados en los reales, con escudos propios simplificados (no logos oficiales).
- Controles de teclado actuales (P1 flechas/K/L, P2 WASD/F/G); mandos fuera de alcance.
- El tutorial nicolasbize/soccer-course es referencia de flujo (pantallas, llaves, plantillas); su código no se copia.
- Aprobación de diseño la otorga el equipo del proyecto en el tablero de Notion.
