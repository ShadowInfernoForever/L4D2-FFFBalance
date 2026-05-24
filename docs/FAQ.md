# ¿Por qué no me puedo unir a partidas públicas?
- Esto puede deberse por el parametro -insecure, debes de borrarlo para que puedas unirte a partidas de valve denuevo.
- Recuerda que este **MOD** no funcionará si no tienes -insecure de parámetro de lanzamiento.
- ℹ️ Un tip, puedes tachar el comando si se te vuelve muy tedioso borrar el -insecure entero, por ejemplo, -/insecure -.insecure

# ¿Dónde puedo editar el tickrate del servidor?

- [AQUÍ](https://github.com/ShadowInfernoForever/L4D2-FFFBalance/blob/192094c15277b585f035ec3ade3a4a98750c10a9/cfg/sourcemod/l4d2_tickrate_enabler.cfg#L16)  
  Pero recuerda que en servidores locales, el máximo tickrate posible es **100**.  
  En servidores dedicados es posible usar valores mayores (por ejemplo **128**).  
  También recuerda que debes editar los valores de red adecuados; abajo te dejo en qué CFG están estos valores.

- [LISTENSERVER.cfg](https://github.com/ShadowInfernoForever/L4D2-FFFBalance/blob/master/cfg/FF_listenserver_english.cfg)

## Valores para calcular

```text
sv_minrate               = tickrate × 1000
sv_maxrate               = tickrate × 1000
sv_minupdaterate         = tickrate
sv_maxupdaterate         = tickrate
sv_mincmdrate            = tickrate
sv_maxcmdrate            = tickrate
net_splitpacket_maxrate  = (tickrate ÷ 2) × 1000 
```

# ¿Dónde puedo editar la configuración de este mod?
- 👉 [**AQUÍ**](https://github.com/ShadowInfernoForever/L4D2-FFFBalance/tree/d1ffa330174676e991c6e3294b48e74591187ad2/cfg)
- Recuerda que las carpetas, **Competitive**, **Cooperative4**, **Cooperative8** son las carpetas dónde están situados los modos de juegos, son las configuraciones que se cargan cuando seleccionas un modo de juego atravez de !match

- La carpeta friendlyfire_weaponbalance, son las configuraciones de balance de armas, recuerda que también son afectadas por el modo de juego, además algunos modos de juego cambian el comportamiento de el director sobre las armas.
- Por Ejemplo: 
- l4d2_addweaponrule sniper_military sniper_awp 50 50
- Crea una regla que hace que la sniper_military (sniper militar), sea remplazado por el sniper_awp (la AWP de CS:S), con un 50% de chance, y con un porcentaje de remplazo del 50% de todas las armas del mapa

# ¿Dónde puedo editar la configuración de este mod?

* 👉 [**AQUÍ**](https://github.com/ShadowInfernoForever/L4D2-FFFBalance/tree/d1ffa330174676e991c6e3294b48e74591187ad2/cfg)

* Recuerda que las carpetas **Competitive**, **Cooperative4** y **Cooperative8** contienen las configuraciones de cada modo de juego. Estas configuraciones se cargan automáticamente cuando seleccionas un modo mediante `!match`.

Ejemplo sacado del modo [**ClassicCasual.cfg**](https://github.com/ShadowInfernoForever/L4D2-FFFBalance/blob/d1ffa330174676e991c6e3294b48e74591187ad2/cfg/cooperative4/ClassicCasual.cfg#L94-L96):
```text
l4d2_addweaponrule pumpshotgun sniper_scout 50
l4d2_addweaponrule shotgun_chrome sniper_scout 50
```
- Estas reglas hacen que la ```pumpshotgun``` y la ```shotgun_chrome``` tengan un 50% de probabilidad de ser reemplazadas por la sniper_scout (Scout de CS).
- También puedes agregar otro 50 para hacer que remplaze % porcentaje de armas del mapa, por ejemplo:

```text
l4d2_addweaponrule sniper_military sniper_awp 50 50
```
- Esta regla hace que la sniper_military (sniper militar) sea reemplazada por la sniper_awp (AWP de CS:S) con un **50% de probabilidad**. Además, afecta al **50% de las armas** de ese tipo presentes en el mapa

## **friendlyfire_weaponbalance**
Contiene las configuraciones relacionadas al balance de armas. Ten en cuenta que estas también pueden verse afectadas por el modo de juego seleccionado. Además, algunos modos modifican el comportamiento del Director respecto a las armas.

### Ejemplo:
```text
//# AWP
sm_weapon sniper_awp damage 500
sm_weapon sniper_military headshotmult 0.5
sm_weapon sniper_awp tier 1
```
Aqui el ```AWP``` saca ```500dmg``` al cuerpo, y saca ```1000dmg``` a la cabeza, debido a la siguiente fórmula:
```text
daño base x daño por headshot vanilla x headshotmult
500 x 4 x 0.5 = 1000dmg
```

## **friendlyfiremodes** 
Son los modos de fuego amigo que hay, es decir, podemos votar el porcentaje de FF en la misma partida.
### Ejemplo:
- **brutalfriendlyfire.cfg** => creas un cfg custom para reventar a tus aliados, porque es divertido :D
- Adentro pones por ej:
```text
//# Molotovs Damage
sm_cvar inferno_friendly_fire_duration 6.0
sm_cvar survivor_burn_factor_easy 100.0
sm_cvar survivor_burn_factor_normal 100.0
sm_cvar survivor_burn_factor_hard 100.0
sm_cvar survivor_burn_factor_expert 100.0

//# Friendly Fire between allies
sm_cvar survivor_friendly_fire_factor_easy 100.0
sm_cvar survivor_friendly_fire_factor_normal 100.0
sm_cvar survivor_friendly_fire_factor_hard 100.0
sm_cvar survivor_friendly_fire_factor_expert 100.0
sm_cvar z_friendly_fire_forgiveness 0 //# forgive friendly fire
```

