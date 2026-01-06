### 1. Descarga [L4D2-FFFBalance](https://github.com/ShadowInfernoForever/L4D2-FFFBalance/archive/refs/heads/master.zip)

---

### 2. Copia las carpetas **Addons** y **CFG** (El resto de archivos puedes removerlos si deseas).

![FFF Balance](img/selectthose2.png "FF Balance")

---

### 3. Pégalas en la ruta:  
- **TuDisco:\SteamLibrary\steamapps\common\Left 4 Dead 2\left4dead2**

- Si te pregunta si deseas reemplazar un archivo, acepta.  
  *(Solo se reemplazará **listenserver.cfg**, no te preocupes.)*

![FFF Balance](img/pastehere.png "FF Balance")

---

### 4. **(OPCIONAL)** 
- Añádete a ti o a otras personas como administradores del servidor.

- Dirígete a la ruta:
  **TuDisco:\SteamLibrary\steamapps\common\Left 4 Dead 2\left4dead2\addons\sourcemod\configs**

- Busca el archivo **admins_simple.ini**, ábrelo y desplázate hasta el final del archivo.

![Admins Simple](img/admins_simple.png "FF Balance")

- Obtén tu **STEAMID** desde cualquiera de estos sitios:

  - [steamid.xyz](https://steamid.xyz/)
  - [steamid.io](https://steamid.io/)
  - [steamid.pro](https://steamid.pro/)

- Agrega una línea como esta al final del archivo y remplazalo con tu **SteamID**:
-  No olvides el "99:z", es para darte el permiso máximo, puedes leér arriba en **admins_simple.ini** sobre como funciona la jerarquia de rangos.

```ini
"TUSTEAMID"    "99:z"
```

- Debería de quedarte algo como esto, si te quedo así, entonces guardalo y listo!

![FFF Balance](img/admins_simple2.png "FF Balance")

---

### 5. Paso
- Ve a tu **Biblioteca de Steam** y busca **Left 4 Dead 2**.  
- Haz clic derecho en el juego y selecciona **Propiedades**.

![FFF Balance](img/rightclickl4d2.png "FF Balance")

---

### 6. Paso
- En la sección **GENERAL**, agrega el parámetro **-insecure**.  
- *(El parámetro **-console** es recomendado, pero no obligatorio.)*

- Si no sabes qué es la consola, te recomiendo ver un video; puede ayudarte muchísimo.

![FFF Balance](img/addparameter.png "FF Balance")

---

### 7. Paso
- Entra al juego y ve a **Extras > Addons**.  
- Marca o desmarca **8 Player Lobby** según prefieras jugar con 4 o 8 jugadores (**PERO OJO**), revisa los **[modos de juego](modes.md)** para saber que modos son compatibles con 8 jugadores, porque no todos lo serán.

![FFF Balance](img/checkoruncheck.png "FF Balance")

---

### 8. Paso 
- ¡Hostea un servidor local y disfruta!  
- No olvides revisar el:

👉 **[Manual de uso](manual.md)**
- Para saber como funciona el sistema de votación integrado.
