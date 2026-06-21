# 📘 Manual de Uso – FFForever Balance

## 🎮 Inicio Rápido
Cuando un jugador entra a la partida puede **jugar inmediatamente** sin configurar nada.  
Sin embargo, si desea cambiar el modo de juego o cargar uno de los modos personalizados, puede usar los **comandos de chat** o los **comandos de consola**.
Abajo se explica más a detalle todos los comandos que se pueden usar tanto el administrador como los jugadores.

---

## 1. Selección de Modo de Juego

### 💬 Comandos en el chat
Puedes escribir cualquiera de estos en el chat (con `!` al inicio):

- `!match`
- `!load`
- `!mode`

Versión en español:

- `!modo`
- `!cargar`

### Comandos de consola
Funcionan desde la consola de programador (sin símbolo `!`):

- `sm_match`
- `sm_load`
- `sm_mode`
- `sm_currentmode`

Versión en español:

- `sm_modo`
- `sm_cargar`
- `sm_modoactual`

---

## 2. Votar el modo de Friendly Fire

### 💬 Comandos de chat para iniciar votación
- `!ff`
- `!fa`
- `!friendlyfire`
- `!friendlyfirevote`
- `!fuegoamigo` *(ES)*
- `!voteff`
- `!votefriendlyfire`

### Comandos para ver el modo actual
Estos comandos muestran qué configuración de Friendly Fire está activa:

- `sm_ffcurrent`
- `sm_currentff`
- `sm_actualff` *(ES)*
- `sm_ffactual` *(ES)*

---

## 3. Guía de Camino y Objetivos (Path To Goal)
Si te pierdes en el mapa, puedes solicitar al servidor que dibuje un camino (láser) que te indicará la ruta hacia el objetivo o refugio.
### 💬 Comandos de chat o en la consola, respectivamente:
- En Inglés:
- `!path / sm_path` 
- `!goal / sm_goal`
- `!path_goal / sm_path_goal`
- `!lost / sm_lost`
- `!ptg / sm_ptg`  
- En Español:
- `!camino / sm_camino`
- `!objetivo / sm_objetivo`
- `!guia / sm_guia`
- `!ruta / sm_ruta`

¡Perfecto! Vamos a actualizar y organizar esa lista para que quede impecable en tu documentación. He agrupado los comandos que faltaban por su función (ir a espectadores, ir a supervivientes, ir a infectados y votaciones de mezcla/intercambio) para que sea súper fácil de leer.

Aquí tienes el texto listo para copiar y pegar:

---

## 4. Gestión de jugadores (Player Management)

### 💬 Comandos de chat o en la consola, respectivamente:

* `!fixbots / sm_fixbots` - Spawnea los supervivientes faltantes como bots, depende del cvar `survivor_limit`.
* `!swapteams / sm_swapteams` - Cambia a todos los jugadores de equipo entre sí (de infectados a supervivientes y viceversa).
* `!swapto / sm_swapto` - Cambia a un jugador (o varios) a un equipo específico. Uso: `!swapto [force] <numerodeteam> <player1> [player2]...` (1 = Espectadores; 2 = Supervivientes; 3 = Infectados). 
* `!swap / sm_swap` - Intercambia a los jugadores listados al equipo contrario. Uso: `!swap <player1> [player2]...`
> **Nota:** Estos Comandos son solo para administradores

### Pasar al equipo de Espectadores (Mismo comando)

* `!spectate / sm_spectate`
* `!spec / sm_spec`
* `!s / sm_s`
* `!afk / sm_afk`
* `!espectador / sm_espectador`

> **Nota:** Cualquiera de estas variantes te moverá inmediatamente al equipo de espectadores.

### Pasar al equipo de Supervivientes (Mismo comando)

* `!jugar / sm_jugar`
* `!join / sm_join`
* `!survivor / sm_survivor`
* `!superviviente / sm_superviviente`
* `!supervivientes / sm_supervivientes`
* `!humano / sm_humano`

### Pasar al equipo de Infectados (Mismo comando)

* `!infected / sm_infected`
* `!infectado / sm_infectado`
* `!zombie / sm_zombie`

### Votaciones de Equipos

* `!teamscramble / !scramble / !voteteamscramble / !votescramble / !mezclar / !mezclarequipos` (Comandos equivalentes: `sm_teamscramble`, `sm_scramble`, etc.) - Inicia una votación para mezclar los equipos aleatoriamente.
* `!voteswap / sm_voteswap` - Inicia una votación para intercambiar los equipos (pasar los supervivientes a infectados y viceversa).

## 📄 Notas
- La gran mayoria de comandos son accesibles para los jugadores, a menos que el administrador configure lo contrario, algunos solo son accesibles para administradores por obvias razones.
- Si un jugador no vota o no usa comandos, simplemente juega sin ningún modo cargado, con los plugins complementarios.

- Si Deseas Jugar de 8 jugadores en una sala coop, recuerda primero activar el mod de lobby de 8 jugadores, porqué si no, ningún jugador extra aparte de los 4 se podrán unir!
