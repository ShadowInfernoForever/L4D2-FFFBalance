# 🎮 Lista de Modos de Juego – FFForever Balance

### Este documento detalla todos los modos disponibles dentro del proyecto **FFForever-Balance**, organizados por categorías principales.  
### Cada modo modifica el comportamiento del juego, su dificultad, los infectados, los supervivientes y las mecánicas generales.

---

## Cooperative 4 - (Para Campañas CO-OP con un máximo de 4 jugadores)

> ### Vanilla
El Left 4 Dead 2 clásico, pero con parches, mejoras de calidad de vida (QoL) y pequeños ajustes que no rompen la esencia original.  
**Recomiendo elegir este modo cuando quieres resetear todos los valores del server a un valor de fábrica (default).**
### *Cambios:*
- Agarrar del suelo un arma del mismo **tipo**, reponerá tu munición de el arma que tengas equipada.
- Ahora los supervivientes al morir dejarán su arma secundaria en el piso.
- Al ganar una ronda en versus, los jugadores pueden moverse libremente.
- Las granadas fueron reworkeadas en **TODOS** los modos de juego, funcionando similar a CS:GO.
- Se pueden agarrar objetos estando incapacitado.
- El tank al moverse ya no generá sacudidas en la cámara de los jugadores.
- Los props como (fuegos artificiales, tanques de propano, oxígeno y latas de gasolina) ya no tendrán colisión, para evitar que al desplazarse se muevan de lugar.
- El Director spawneará mobs enfrente del jugador más adelantado, siempre.
- El juego anunciará quién fue el que reventó una lata de gasolina (de forma sútil, nada de mensajes en el chat ni hint texts, lo más vanilla posible).
- El jockey ya no puede capear si no es con su habilidad.
- Recoger un arma/item/utilidad ya no te cambiará a esta automaticamente.
- Se removieron las sombras, tanto para mayor fps, y para no tener un "wallhack" y ver infectados atravez de paredes gracias a sus sombras.
- Las escaleras se comportan como CS, es decir, se puede disparar estando parado en una escalera.
- Los espectadores se quedarán como espectadores después de un cambio de niveles.
- Estar parado en un superviviente siendo infectado, o viceversa, ya no generará temblores en la pantalla, tampoco hará que estos se deslizen.
- Las armas tendrán skins RNG, (todas las que añadieron en Last Stand).
- Hay un Sistema Anti-Trampas (Lilac Anti Cheat)
- Los snipers de cerrojo tienen balas trazadoras (re-utiliza la trazadora de las incendiarias).

---

> ### Casual
Modo pensado para una experiencia relajada, de paso añade armas balanceadas así todos los jugadores
pueden disfrutar de cualquier arma, sin importar tierlist de mejor-peor.
Siguen habiendo diferencias obvias entre TIER 0, TIER 1 y TIER 2.

**Recomendado para jugar con amigos de forma despreocupada.**
### *Cambios:*
- El Jockey tiene 250hp, una velocidad de 275 (hammer/units) pero ya no se puede resistir a su movimiento.
- Los Commons tienen una reducción de daño del 25%, recibiendo el 75% del impacto.
- Commons configurados para combate más consistente (sin peleas entre ellos, ni tampoco descansan en el piso, "**siempre estarán caminando**").
- Los supervivientes tienen los godframes de dificultad normal contra los commons. (Esto aplica a todas las dificultades excepto fácil).
- Daño de los commons a supervivientes reducido (2dmg en normal; 5dmg en hard; 11dmg en experto).
- Hordas configuradas manualmente, el director spawneará hordas si los supervivientes van bien en la partida, de lo contrario, si no se mueven, se detendrán las hordas.
- La bilis ahora puede potar a tus compañeros y a ti mismo.
- Las cajas de fuegos artificiales ahora tiraran fuegos artificiales al cielo y atraerán a los commons.
- En caso de fallar un final, ya no se deberá repetirlo indefinidamente hasta completarlo, si no que se terminará la partida contando como un final fallido.
- Uso de "configuración casual de armas"
- Hay un 50% de chance de que los snipers T2 (hunting rifle y military sniper), se remplacen por sus contrapartes T1 (scout y awp) respectivamente.

---

> ###  Equinix Balance

Balancea supervivientes, infectados, armas y mecánicas para una dificultad alta.
### *Cambios:*
- Los supervivientes revividos desde una incapacitación con "100 HP o menos" se levantarán en estado B/W (Blanco y Negro). Además, la cantidad de "vida temporal" otorgada al ser revividos es "dinámica", y depende de la vida que tenían durante la incapacitación. está basado en el mod [Revised Revival [VScript]](https://steamcommunity.com/sharedfiles/filedetails/?id=3452710213&searchtext=Revised+Incap)
- Eliminado el glow de ítems a larga distancia.
- El Jockey tiene 250hp, una velocidad de 275 (hammer/units) pero ya no se puede resistir a su movimiento.
- Dinámicas de pounce, shove y stagger ajustadas a valores de "Versus".
- Velocidad del tank a 220 (hammer/units)
- El tank cuando es prendido fuego, ganará velocidad (como en L4D1)
- Los Commons tienen una reducción de daño del 25%, recibiendo el 75% del impacto.
- Commons configurados para combate más consistente (sin peleas entre ellos, ni tampoco descansan en el piso, siempre estarán caminando).
- Los supervivientes tienen los godframes de dificultad normal contra los commons. (Esto aplica a todas las dificultades excepto fácil).
- Daño de los commons a supervivientes reducido (2dmg en normal; 5dmg en hard; 11dmg en experto).
- Hordas configuradas manualmente, el director spawneará hordas si los supervivientes van bien en la partida, de lo contrario, si no se mueven, se detendrán las hordas.
- Uso de "configuración competitiva de armas" (Zonemod Híbrido).
- Los supervivientes solo tendrán 4 empujones.
- El stagger de los especiales ahora es de 1.5s.

---

> ### HardMode (HM)

Un modo pensado para replicar la presión de **VERSUS** pero ahora en campaña, elevando la dificultad sin recurrir a trucos artificiales (como subirle la vida a los enemigos).
Obliga al jugador a perfeccionar tracking, posicionamiento y aim.
Una preparación sólida para el modo **VERSUS**.
### *Cambios:*
- Eliminado el glow de ítems a larga distancia.
- Respawn de Special Infected fijado a 15s
- Los Special Infected spawnean de forma coordinada y en grupo.
- Comportamiento y AI de infectados especiales ajustado para simular "Versus".
- Límite de Special Infected activos establecido en **4**.
- El Jockey tiene 250hp, una velocidad de 275 (hammer/units) pero ya no se puede resistir a su movimiento.
- Dinámicas de pounce, shove y stagger ajustadas a valores de "Versus".
- Velocidad del tank a 220 (hammer/units)
- Los Commons tienen una reducción de daño del 0%, recibiendo el 100% del impacto.
- Commons configurados para combate más consistente (sin peleas entre ellos, ni tampoco descansan en el piso, siempre estarán caminando).
- Los supervivientes tienen los godframes de dificultad normal contra los commons. (Esto aplica a todas las dificultades excepto fácil).
- Daño de los commons a supervivientes reducido (2dmg en normal; 5dmg en hard; 11dmg en experto).
- Curación pasiva con las pills y adrenalina en lugar de vida instantanea.
- Uso de "configuración competitiva de armas" (Zonemod Híbrido).


---

> ### Follow The Guardian (FTG)
Modo escolta:  
Debes proteger a un VIP hasta el final del mapa.  
- Todos los jugadores tienen menos vida  
- Cada golpe recibido por el VIP se divide entre todos los jugadores

---

> ### VersusCoop
Modo híbrido:  
4 supervivientes (**BOTS**) vs 4 **jugadores** de infectados especiales.  
Es un "versus" *cooperativo*.

---

> ### OneDown
No hay incapacitaciones, cuando la vida llega a 0 el superviviente muere.

---

> ### 1HP + One Down
Los jugadores tienen **solo 1 punto de salud**.  
Tampoco existen las incapacitaciones.

---

## Cooperative 8 - (Para Campañas CO-OP con un máximo de 8 jugadores)

> ### Quantum
Es un modo caótico, no esperes mucho balance.
Está hecho para divertirse.

---

> ### QuantumLite
Similar a Quantum, pero intentando conservar lo más posible el estilo **Vanilla + Casual**.
Según el **"Lite"**, es el 8 jugadores pero más liviano, es decir, muchos menos plugins que se alejan a lo vanilla y casual, (también para que corra mejor).

---

> ### Follow The Guardian (FTG 8)
Versión para 8 jugadores del modo FTG.
Más caos, más enemigos, mismo objetivo: **proteger al VIP**.

---

> ### Quantum TankRush
Tank Run para 8 jugadores.
Más caos, más tanks, más acción.

---

> ### VersusCoop 8
Versión extendida del modo VersusCoop.  
8 supervivientes (**BOTS**) vs 8 **jugadores** de infectados especiales.

---

## Competitive / Versus - (Diseñado para partidas Enfrentamiento VERSUS)

> ### 1 vs 1
Un superviviente vs un infectado.  
Modo ideal para practicar mecánicas.  
**Base: ZONEMOD T1.**

---

> ### 2 vs 2
Dos supervivientes vs dos infectados.  
**Base: ZONEMOD T1.**

---

> ### 3 vs 3
Tres supervivientes vs tres infectados.  
**Base: ZONEMOD T1.**

---

> ### Equinix Balance
Balancea supervivientes, infectados y armas t1 y t2, para una experiencia "Justa".
Pero tampoco lo llena de tantos factores como Zonemod, sería más un versus "vanilla" glorificado.

---

> ### Zonemod T1
Versión competitiva Hibrida de Zonemod.  
Diseñada para hacer el juego más equilibrado e interesante.
Solo Permite armas tier 0 y tier 1

---

> ### Zonemod T2
Mismo enfoque que T1, pero con **armas T2 nerfeadas** para balance competitivo.

---

> ### DeathMatch (DM)
Superviviente vs superviviente.
El jugador que consiga más **frags**(kills) ganará la partida

---

> ### Team DeathMatch (TDM)
Similar al DeathMatch, pero con **captura de puntos de control** para obtener puntos.

---

> ### TankRush (Competitivo)
4 supervivientes vs **4 tanks controlados por jugadores**.  
Todos los valores están ajustados para uso competitivo y balanceado.

---
