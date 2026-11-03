# Ranking en línea con Firebase (bonus de multijugador)

Cuando alguien presenta el parcial, su nota se sube a una base de datos de Firebase. En **Puntajes → En línea** todos ven el mismo **Top 10**, jueguen en PC o en celular. Es un multijugador por turnos: cada uno juega en su dispositivo y compiten por el primer puesto.

## Cómo funciona

| Pieza | Archivo | Qué hace |
|---|---|---|
| Conexión | `autoload/Nube.gd` | Habla con Firebase por su API REST con `HTTPRequest`. No necesita plugins y funciona igual en Windows y Android |
| Subir la nota | `autoload/Partida.gd` → `registrar_resultado()` | Al presentar el parcial llama a `Nube.enviar_nota(nombre, nota, puntaje, ranas)` |
| Ver el Top 10 | `escenas/Puntaje.gd` | Pestañas "En este celular" y "En línea". Tu nota sale resaltada |
| Apagarlo | `escenas/Ajustes.gd` | Interruptor "Subir mi nota al ranking en línea" |
| Seguridad | `firebase/database.rules.json` | Solo deja leer el ranking y agregar notas válidas: no se pueden editar ni borrar las de otros |
| Pruebas | `herramientas/nube_de_prueba.py` | Un servidor que imita a Firebase en el mismo PC, con las mismas reglas |

Las peticiones que se mandan:

```
POST https://<proyecto>-default-rtdb.firebaseio.com/puntajes.json
     {"nombre": "Ana", "nota": 4.6, "puntaje": 15200, "ranas": 3,
      "plataforma": "Android", "momento": {".sv": "timestamp"}}
  -> {"name": "-Nx1a2b3c"}        (la clave nueva)

GET  https://<proyecto>-default-rtdb.firebaseio.com/puntajes.json?orderBy="puntaje"&limitToLast=10
  -> los 10 puntajes más altos
```

`{".sv": "timestamp"}` hace que Firebase ponga la hora de su servidor, así nadie puede falsificar la fecha.

## La base de datos del equipo

Ya está creada y conectada:

- Proyecto de Firebase: **sobrevive-al-parcial**, en el plan gratuito Spark.
- Base de datos: **https://sobrevive-al-parcial-default-rtdb.firebaseio.com**, ya puesta en `autoload/Nube.gd`.
- Ver las notas: en la consola de Firebase, en **Realtime Database → Datos**, o abriendo en el navegador `https://sobrevive-al-parcial-default-rtdb.firebaseio.com/puntajes.json`.

La prueba automática (`--recorrido`) nunca sube notas a esta base: usa el servidor de prueba o se queda sin ranking.

## Cómo se creó (por si hay que repetirlo)

1. Entrar a **console.firebase.google.com** con una cuenta de Google → **Crear un proyecto** → nombre `sobrevive-al-parcial`. Google Analytics no hace falta.
2. En el menú: **Compilación → Realtime Database → Crear base de datos**.
   - Ubicación: **Estados Unidos (us-central1)**.
   - Elegir **Comenzar en modo bloqueado**.
3. Pestaña **Reglas**: borrar lo que hay, pegar el contenido de `firebase/database.rules.json` y darle **Publicar**.
4. Pestaña **Datos**: copiar la dirección de arriba, que se ve como `https://sobrevive-al-parcial-default-rtdb.firebaseio.com`.
5. En Godot, abrir `autoload/Nube.gd` y pegarla en `URL_BASE`:
   ```gdscript
   const URL_BASE := "https://sobrevive-al-parcial-default-rtdb.firebaseio.com"
   ```
6. Jugar con F5 hasta presentar el parcial, y abrir Puntajes → En línea. En la consola de Firebase, en **Datos**, aparece la nota debajo de `puntajes`.
7. Volver a exportar para Windows y Android. Android ya tiene activado el permiso de **Internet** en los dos perfiles.

El plan gratuito (Spark) de Firebase alcanza de sobra: 1 GB guardado y 10 GB de descarga al mes.

## Probarlo sin internet

```bash
python3 herramientas/nube_de_prueba.py 8765
godot --path . -- --recorrido --nube=http://127.0.0.1:8765
```

La prueba automática presenta el parcial y revisa dos cosas: que la nota llegue al servidor, y que el Top 10 en línea muestre a varios jugadores. El servidor de prueba ya trae 3 notas de otros jugadores.

## Límites (para contarlo en la presentación)

- No hay inicio de sesión: cualquiera con el juego puede subir una nota. Las reglas impiden borrar o cambiar las notas de otros y rechazan datos raros, como notas mayores a 5 o más de 3 ranas. Pero no pueden comprobar que la partida fue real. Si se quiere más seguridad, el siguiente paso es Firebase Authentication anónima.
- No es multijugador en tiempo real (dos jugadores en el mismo mapa): es un ranking compartido.
