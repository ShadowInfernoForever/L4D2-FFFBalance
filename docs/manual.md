# 📘 Manual de Uso – FFForever Balance

# 🎮 Inicio Rápido
Cuando un jugador entra a la partida puede **jugar inmediatamente** sin configurar nada.  
Sin embargo, si desea cambiar el modo de juego o cargar uno de los modos personalizados, puede usar los **comandos de chat** o los **comandos de consola**.
Abajo se explica más a detalle todos los comandos que se pueden usar tanto el administrador como los jugadores.

## 1. Selección de Modo de Juego

#### 💬 Comandos para seleccionar, configurar o cargar las modalidades de juego del servidor:

* `!match / sm_match`
* `!mode / sm_mode`
* `!modo / sm_modo`
* `!load / sm_load`
* `!cargar / sm_cargar`
* `!currentmode / sm_currentmode`
* `!modoactual / sm_modoactual`

---

## 2. Votar el modo de Friendly Fire

#### 💬 Comandos para iniciar votaciones o consultar el estado del fuego amigo en el servidor:

* `!ff / sm_ff`
* `!fa / sm_fa`
* `!friendlyfire / sm_friendlyfire`
* `!friendlyfirevote / sm_friendlyfirevote`
* `!voteff / sm_voteff`
* `!votefriendlyfire / sm_votefriendlyfire`
* `!fuegoamigo / sm_fuegoamigo`
* `!ffcurrent / sm_ffcurrent`
* `!currentff / sm_currentff`
* `!actualff / sm_actualff`
* `!ffactual / sm_ffactual`
  
---

## 3. Guía de Camino y Objetivos (Path To Goal)
Si te pierdes en el mapa, puedes solicitar al servidor que dibuje un camino (láser) que te indicará la ruta hacia el objetivo o refugio.
#### 💬 Comandos de chat o en la consola, respectivamente:
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

---

## 4. Gestión de jugadores (Player Management)

#### 💬 Comandos de chat o en la consola, respectivamente:

* `!undodamage / sm_undodamage` - sm_undodamage <player> o @all, devuelve la vida que un superviviente perdio por daños de fuego amigo.
* `!fixbots / sm_fixbots` - Spawnea los supervivientes faltantes como bots, depende del cvar `survivor_limit`.
* `!swapteams / sm_swapteams` - Cambia a todos los jugadores de equipo entre sí (de infectados a supervivientes y viceversa).
* `!swapto / sm_swapto` - Cambia a un jugador (o varios) a un equipo específico. Uso: `!swapto [force] <numerodeteam> <player1> [player2]...` (1 = Espectadores; 2 = Supervivientes; 3 = Infectados). 
* `!swap / sm_swap` - Intercambia a los jugadores listados al equipo contrario. Uso: `!swap <player1> [player2]...`
> **Nota:** Estos Comandos son solo para administradores, requieren de **`ADMFLAG_GENERIC`**

#### Pasarse al equipo de Espectadores

* `!spectate / sm_spectate`
* `!spec / sm_spec`
* `!s / sm_s`
* `!afk / sm_afk`
* `!espectador / sm_espectador`

#### Pasarse al equipo de Supervivientes

* `!jugar / sm_jugar`
* `!join / sm_join`
* `!survivor / sm_survivor`
* `!superviviente / sm_superviviente`
* `!supervivientes / sm_supervivientes`
* `!humano / sm_humano`

#### Pasarse al equipo de Infectados

* `!infected / sm_infected`
* `!infectado / sm_infectado`
* `!zombie / sm_zombie`

#### Votaciones de Equipos

* `!teamscramble / !scramble / !voteteamscramble / !votescramble / !mezclar / !mezclarequipos` (Comandos equivalentes: `sm_teamscramble`, `sm_scramble`, etc.) - Inicia una votación para mezclar los equipos aleatoriamente.
* `!voteswap / sm_voteswap` - Inicia una votación para intercambiar los equipos (pasar los supervivientes a infectados y viceversa).

---

## 5. Comandos de usuarios (FF Command Utilities)

#### 💬 Comandos de utilidad e información:
* `!ping / sm_ping` - Muestra estadísticas de red detalladas del jugador (Ping real, Ping del Scoreboard, Paquetes, Loss y Choke).
* `!lerp / sm_lerp` - Muestra el Lerp actual y exacto del jugador en milisegundos.
* `!lerps / sm_lerps` - Muestra el Lerp de todos los jugadores conectados en el servidor.
* `!progreso / sm_progreso` - Muestra el mapa actual, el capítulo y el porcentaje de avance/distancia completado por el equipo de supervivientes.
* `!slots / !jugadores / sm_slots / sm_jugadores` - Muestra la cantidad de jugadores conectados en relación con los espacios (slots) máximos del servidor.
* `!balance / sm_balance` - Muestra en el chat el enlace al repositorio de FFBalance :D!
* `!kill / sm_kill` - Suicida al jugador instantáneamente (si está vivo) y publica un mensaje aleatorio y divertido en el chat sobre su muerte.
* `!mvote / sm_mvote` - Inicia una votación personalizada del tipo Sí/No con el texto ingresado. Uso: `!mvote <mensaje>`.

---

## 6. ABM (Advanced Bot Management)
> **(Solo en 8 Jugadores, en modalidad Quantum e QuantumLite)**
>
> **Nota de administración:** Los comandos que empiezan con **`!abm`** requieren de permisos de administrador genéricos **(`ADMFLAG_GENERIC`).** Los comandos al final de la lista son públicos para todos los jugadores.

#### 💬 Comandos de utilidad e información:

#### Menú y Gestión Base (Solo Admins)

* `!abm / !abm-menu / sm_abm / sm_abm-menu` - Abre el menú principal de ABM en pantalla de forma interactiva.
* `!abm-reset / sm_abm-reset` - Reinicia por completo el sistema y la configuración de ABM. *(Usar solo en caso de emergencia)*.
* `!abm-info / sm_abm-info` - Imprime información interna y datos de diagnóstico del plugin directamente en la consola.

#### Manipulación de Equipos y Jugadores (Solo Admins)

* `!abm-join / sm_abm-join` - Mueve a un jugador o bot a un equipo específico. Uso: `<TEAM>` o `<ID> <TEAM>`.
* `!abm-takeover / sm_abm-takeover` - Fuerza a un jugador a tomar el control de un bot. Uso: `<ID>` o `<ID_Jugador> <ID_Bot>`.
* `!abm-respawn / sm_abm-respawn` - Revive instantáneamente a un jugador o bot específico. Uso: `<ID>` o `[ID]`.
* `!abm-teleport / sm_abm-teleport` - Teletransporta a un jugador/bot hacia la ubicación exacta de otro. Uso: `<ID_Origen> <ID_Destino>`.
* `!abm-cycle / sm_abm-cycle` - Fuerza la rotación o el ciclo de bots entre los equipos. Uso: `<TEAM>` o `<ID> <TEAM>`.

#### Customización e Inventario (Solo Admins)

* `!abm-model / sm_abm-model` - Asigna un modelo de personaje (skin) específico a un jugador o bot. Uso: `<MODELO>` o `<MODELO> <ID>`.
* `!abm-strip / sm_abm-strip` - Despoja a un jugador de sus armas o limpia un espacio de inventario en particular. Uso: `<ID> [SLOT]`.

#### Control de Spawn de Bots (Solo Admins)

* `!abm-mk / sm_abm-mk` - Crea o añade una cantidad determinada de bots a un equipo. Uso: `<N -N o> <TEAM>`.
* `!abm-rm / sm_abm-rm` - Remueve o elimina bots de un equipo de forma manual. Uso: `<TEAM>` o `<N -N o> <TEAM>`.

---

#### Atajos Públicos (Para cualquier jugador en el servidor)

* `!takeover / sm_takeover` - Permite a un jugador común tomar el control de un bot vivo (útil si está muerto o en espectador). Uso: `<ID>` o `<ID1> <ID2>`.
* `!join / sm_join` - Comando rápido y directo para que cualquier usuario intente unirse a un equipo. Uso: `<TEAM>` o `<ID> <TEAM>`.

## 📄 Notas
- La gran mayoria de comandos son accesibles para los jugadores, a menos que el administrador configure lo contrario, algunos solo son accesibles para administradores por obvias razones.
- Si un jugador no vota o no usa comandos, simplemente juega sin ningún modo cargado, con los plugins complementarios.

- Si Deseas Jugar de 8 jugadores en una sala coop, recuerda primero activar el mod de lobby de 8 jugadores, porqué si no, ningún jugador extra aparte de los 4 se podrán unir!
