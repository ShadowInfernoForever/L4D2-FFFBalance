# ¿Por qué no me puedo unir a partidas públicas?
- Esto puede deberse por el parametro -insecure, debes de borrarlo para que puedas unirte a partidas de valve denuevo.
Un tip, puedes tachar el comando si se te vuelve muy pesado borrar el -insecure entero, por ejemplo, -/insecure -.insecure

# ¿Dónde puedo editar el tickrate del servidor?

- [Aquí](https://github.com/ShadowInfernoForever/L4D2-FFFBalance/blob/192094c15277b585f035ec3ade3a4a98750c10a9/cfg/sourcemod/l4d2_tickrate_enabler.cfg#L16)  
  Pero recuerda que en servidores locales, el máximo tickrate posible es **100**.  
  En servidores dedicados es posible usar valores mayores (por ejemplo **128**).  
  También recuerda que debes editar los valores de red adecuados; abajo te dejo en qué CFG están estos valores.

- [LISTENSERVER](https://github.com/ShadowInfernoForever/L4D2-FFFBalance/blob/master/cfg/FF_listenserver_english.cfg)

## Valores para calcular

```text
sv_minrate               = tickrate × 1000
sv_maxrate               = tickrate × 1000
sv_minupdaterate         = tickrate
sv_maxupdaterate         = tickrate
sv_mincmdrate            = tickrate
sv_maxcmdrate            = tickrate
net_splitpacket_maxrate  = (tickrate ÷ 2) × 1000
