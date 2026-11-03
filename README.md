# Sobrevive al Parcial

Juego 3D para PC (y Android) hecho en **Godot 4.5** con **GDScript**.
Entrega final de Aplicaciones Móviles.

La tarde antes del parcial final (mañana a las 8:00 a. m.) una ventisca se lleva todos tus
apuntes y los riega por la universidad. Tienes que recuperarlos sin que te pillen los vigilantes
y llegar al Salón 304, donde te espera la Xaca Rana: el profe.

| Nivel | Lugar | Tiempo | Qué tiene de nuevo |
|---|---|---|---|
| 1 | Biblioteca, 6:00 p. m. | 3:00 | 1 bibliotecaria con linterna, estantes para esconderse, Xaca Rana escondida |
| 2 | Bulevar, 7:30 p. m. | 2:30 | De noche bajo las lámparas, mesas llenas, gente caminando, jardineras, tintos, Xaca Rana |
| 3 | Bloque de Ingeniería, 10:00 p. m. | 2:30 | Casi sin luz, 3 vigilantes, puertas que se abren con 4 apuntes, Xaca Rana tras una puerta |
| 4 | Parqueadero, 7:00 a. m. | 2:30 | Al otro día: carros, garita y 3 porteros. Aquí ya sirve el poder de la rana |
| 5 | Pasillo del Salón 304, 7:50 a. m. | 1:40 | Casilleros y bancas; la Xaca Rana profe vigila el pasillo |
| Final | Salón 304, 8:00 a. m. | — | Animación: presentas el parcial y la Xaca Rana te pone la nota |

## Controles

| Acción | PC | Celular |
|---|---|---|
| Moverse | W A S D o flechas | Joystick (abajo a la izquierda) |
| Correr (hace ruido) | Shift | Botón CORRER |
| Pausa | Esc, P o el botón II de arriba | Botón II |
| Poder de la Xaca Rana | R | Botón verde RANA (aparece cuando tienes el poder) |

En la pausa del celular está **Ajustar joystick**: se arrastra con el dedo a donde quede cómodo
y se cambia el tamaño con una barra. Queda guardado (`Partida.joystick_centro` y `joystick_escala`).
Desde la pausa también se puede **ir al menú**.

## Cómo se cumple cada punto del enunciado

| # | Requisito | Dónde está |
|---|---|---|
| 1 | Cambio de equipo | Créditos (`escenas/Creditos.gd`, constante `EQUIPO`) |
| 2 | Juego viable | 5 niveles + final animado, se termina en unos 15 minutos |
| 3 | Repositorio | Esta carpeta (ver "Subir al repositorio") |
| 4 | Wireframe en grises | Se entrega aparte (manual y en Figma) |
| 5 | Mínimo 5 secciones | Splash, Home, Juego, Puntaje y Créditos, más Niveles, Ajustes, Historia y Final |
| 6 | Interfaz personalizada | Estilo "cuaderno": papel cuadriculado, tinta, resaltador y esfero rojo (`autoload/Estilo.gd`) |
| 7 | Persistencia entre vistas | `autoload/Partida.gd`: guarda en `user://partida.cfg` y lleva vidas y puntaje de una escena a otra |
| 8 | Animaciones y sonidos | 3 animaciones (historia, transformación en rana, parcial final), tweens en todas las pantallas, personajes animados, 14 efectos y 2 músicas |
| 9 | Motor de juego | Godot 4.5 |
| 10 | Uso de IA justificado | Sección "Uso de inteligencia artificial" de este README |
| 11 | Bonus: easter eggs | 3 Xaca Ranas escondidas que dan un poder (ver abajo) |
| 12 | Bonus: multijugador con Firebase | Ranking en línea: cada nota del parcial se sube a Firebase Realtime Database y todos ven el mismo Top 10 (ver `FIREBASE.md`) |

Niveles, vidas **y** tiempo: hay 5 niveles, 3 vidas (máximo 4) y un reloj por nivel.

### Easter eggs: las 3 Xaca Ranas

La Xaca Rana es la rana del profe (`Constructor.cabeza_rana()` la dibuja igual a su imagen:
toda verde, ojos saltones con la pupila negra hacia afuera y una sonrisa ancha).
En los niveles 1, 2 y 3 hay una Xaca Rana escondida (entre los estantes, junto a las jardineras
del bulevar y detrás de una puerta en ingeniería). Cada una da **+1 vida**. Al juntar las 3 en la
misma partida sale la animación de la transformación (`escenas/CelebracionRana.gd`) y se gana el
**poder de la Xaca Rana** para lo que queda del juego (niveles 3, 4 y 5):

- Con **R** (en el celular, el botón verde RANA) te vuelves rana por 8 segundos, 2 veces por nivel.
- Los vigilantes no te reconocen y no haces ruido.
- Saltas por encima de mesas, jardineras, carros y bancas (`Jugador.gd`, capas de colisión).
- Si se acaba el tiempo encima de un obstáculo, sigues siendo rana hasta bajarte.

Las ranas también suben la nota del parcial. Créditos muestra cuántas has encontrado.

Extra: en el menú, el código Konami (↑ ↑ ↓ ↓ ← → ← → B A), o tocar 5 veces el sello "5.0" en el
celular, activa el **modo profe**: los vigilantes se vuelven profesores con corbata.

## Estructura del proyecto

```
autoload/          Nodos globales que viven todo el juego (se cargan solos al abrirlo)
  Estilo.gd        Colores, letras y Theme del juego; funciones para crear botones y textos
  Controles.gd     Teclas del juego (InputMap) y detección de celular
  Partida.gd       Datos guardados en disco + estado de la partida en curso
  Audio.gd         Música y efectos, con volumen separado para cada uno
  Transicion.gd    Animación al cambiar de pantalla
  Nube.gd          Ranking en línea con Firebase (ver FIREBASE.md)
escenas/           Una escena por pantalla (.tscn) con su script (.gd)
  Splash, Home, Niveles, Ajustes, Puntaje, Creditos
  Historia         Animación de la historia al empezar una partida (se puede saltar)
  CelebracionRana  Animación de la transformación al juntar las 3 Xaca Ranas
  Final            Animación del parcial: la Xaca Rana califica
  Juego.tscn       Escena del nivel (usa mundo/Juego.gd)
mundo/
  Juego.gd         Arma el nivel a partir del mapa de texto y maneja las reglas
  Jugador.gd       Movimiento, correr, ruido y animación del estudiante
  Guardia.gd       Vigilantes: patrulla, visión y oído
  Estudiante.gd    Estudiantes que caminan en el bulevar (obstáculos que se mueven)
  Constructor.gd   Crea los modelos 3D con cajas, cilindros y esferas
niveles/Datos.gd   Los 5 mapas dibujados con letras
hud/Hud.gd         Vidas, apuntes, reloj, avisos, ventanas y controles táctiles
sonidos/           WAV generados por código
fuentes/           Tipografías (licencia OFL, ver LICENCIAS.txt)
pruebas/Recorrido.gd   Prueba automática (solo se activa con --recorrido)
herramientas/      Scripts de Python: generar sonidos, revisar mapas y un Firebase de prueba
firebase/          Reglas de seguridad de la base de datos (no van dentro del juego)
icono/             Íconos del celular (normal, adaptable y monocromático)
android-studio/    Proyecto de Android Studio con el juego ya exportado (se abre con File → Open)
```

## Cómo funciona por dentro

**Mapas de texto → mundo 3D.** Cada nivel es una lista de textos en `niveles/Datos.gd`,
donde cada letra es una celda de 2 × 2 metros (`#` pared, `E` estante, `A` apunte, `S` salida...).
`Juego.gd` recorre el mapa y crea cada objeto. Las paredes seguidas de una misma fila se unen
en un solo bloque para tener menos objetos y que el juego corra mejor.

**Modelos 3D sin descargar nada.** `Constructor.gd` arma personajes, estantes, mesas y tintos
juntando figuras básicas (BoxMesh, CylinderMesh, SphereMesh). Los materiales se guardan en caché
para no repetirlos.

**Cómo caminan los vigilantes.** Usan `AStarGrid2D`, el buscador de caminos de Godot.
`Juego.gd` marca las celdas con paredes, estantes y mesas como "sólidas", y la función
`camino(desde, hasta)` devuelve los puntos por donde ir sin chocar. Cuando se abren las puertas
del nivel 3, esas celdas pasan a ser libres.

**Cómo te ve un vigilante.** En `Guardia.gd`, función `_revisar_vision()`, se hacen 3 pruebas:
1. Distancia: estás a menos de 8 metros.
2. Ángulo: estás dentro del cono de la linterna (unos 29° a cada lado de hacia donde mira).
3. Línea de vista: se lanza un rayo de física desde sus ojos hasta ti. Si choca con una pared,
   un estante o un estudiante (capa de colisión 1), no te ve.

El cono amarillo en el piso es exactamente esa zona.

**Cómo te oye.** Si corres sin tinto, `Jugador.gd` emite la señal `hizo_ruido` cada 0.35 s.
Los vigilantes a menos de 10 m van a revisar ese punto (aparece un "?") y luego vuelven a su ruta.

**Capas de colisión.** Capa 1 = paredes, estantes, puertas, casilleros y estudiantes.
Capa 2 = jugador. Capa 3 = obstáculos bajos (mesas, jardineras, carros, bancas).
El estudiante choca con las capas 1 y 3; convertido en rana solo con la 1, por eso salta los
obstáculos bajos. La vista de los vigilantes se tapa con las capas 1 y 3.
Los objetos que se recogen (`Area3D`) solo detectan la capa 2.

**Persistencia (requisito 7).** `Partida.gd` es un autoload: un nodo que no se borra al cambiar
de escena, así que las vidas, el puntaje y las ranas pasan de un nivel al siguiente y al final.
Lo que debe recordarse al cerrar el juego (nombre, volumen, niveles desbloqueados, récords,
secretos) se guarda con `ConfigFile` en `user://partida.cfg`.
En Windows queda en `%APPDATA%\Godot\app_userdata\Sobrevive al Parcial\`.

**Puntaje.** Por nivel: 1000 + segundos sobrantes × 5 + vidas × 150.
La nota del parcial (`Partida.calcular_nota()`) va de 3.0 a 5.0: 3.0 por llegar, +0.25 por cada
vida que quede, +0.2 por cada Xaca Rana y hasta +0.4 según el tiempo que sobró. Al puntaje total
se le suma nota × 1000. La tabla guarda los 10 mejores.

**Pausa.** `get_tree().paused = true` congela el mundo. El nodo del nivel, el HUD, el audio y la
transición tienen `PROCESS_MODE_ALWAYS` para seguir funcionando y poder quitar la pausa.

**Tema visual.** `Estilo.gd` crea un `Theme` por código (botones tipo sticker con sombra dura,
tarjetas blancas, barras de volumen como resaltador) y lo pone en la ventana principal.
El HUD está en un `CanvasLayer`, que no hereda el tema de la ventana, por eso `Hud.gd` se lo
asigna a mano.

**Controles táctiles.** En el celular, `Hud.gd` muestra un joystick y botones que leen cada dedo
por separado (`InputEventScreenTouch` con su `index`), así se puede mover y correr a la vez.

## Abrir y probar

1. Instalar Godot 4.5 (versión estándar, no la .NET): https://godotengine.org/download
2. En Godot: **Importar** → elegir el archivo `project.godot` de esta carpeta → **Importar y editar**.
3. Botón ▶ (arriba a la derecha) o F5 para jugar.

Para ver los controles del celular en el PC: **Depurar → Personalizar instancias de ejecución**,
en **Argumentos principales de ejecución** escribir `-- --tactil` y darle ▶ (se juega con el mouse
como si fuera el dedo; luego borrar el argumento).

**Prueba automática.** Juega todos los niveles y el final solo, toma capturas y revisa que todo
funcione (que el vigilante te pille, recoger apuntes, ganar, perder, guardar):

```
Godot_v4.5.1-stable_win64.exe --path . -- --recorrido --capturas=C:/ruta/capturas
```

(o en Godot, poner `-- --recorrido` en los argumentos de ejecución como en el punto anterior;
las capturas quedan en la carpeta de datos del juego).

Termina con `TERMINADO con 0 fallas` si todo está bien. **Ojo:** la prueba borra el progreso
y los récords guardados, para empezar siempre igual.

## Exportar

En Godot: **Proyecto → Exportar**. Ya están configurados tres perfiles:

- **Windows**: genera un solo `.exe` (el juego va adentro).
- **Android**: usa la compilación con Gradle (genera la carpeta `android/` que se abre en Android Studio) y saca un `.apk` para instalar directo en el celular.
- **Android Google Play**: igual, pero saca un `.aab` (Android App Bundle), que es lo que pide Google Play. Apunta a Android 16 (API 36) y usa los íconos de la carpeta `icono/`.

La primera vez Godot pide descargar las **plantillas de exportación** (Editor → Administrar
plantillas de exportación → Descargar). Para Android, además: Editor → Configuración del editor →
Exportar → Android → poner la ruta del SDK de Android (la misma de Android Studio) y, si hace falta,
Proyecto → Instalar plantilla de compilación de Android.

**Para verlo en Android Studio** no hace falta Godot: abran la carpeta **`android-studio/`** (File → Open)
y denle Run. Es el proyecto de Android que genera Godot, con el juego ya adentro (ver su LEEME).

Para Google Play, el `.aab` se firma con la **llave de subida** del equipo: se configura en Editor →
Configuración del editor → Exportar → Android → Release Keystore, y se exporta **sin** "Exportar con
depuración". Cada versión nueva necesita un código de versión más alto.
**La llave y su contraseña nunca se suben al repositorio.**

## Uso de inteligencia artificial

Se usó **Claude (Anthropic)** como asistente para escribir el código, los mapas y los sonidos.
Lo que hizo el equipo: escoger la idea y las reglas del juego, revisar y probar cada parte,
ajustar la dificultad y entender el código para poder explicarlo.

Por qué se justifica:
- Godot y GDScript eran nuevos para el equipo; la IA ayudó a aprender las piezas del motor
  (nodos, señales, autoloads, física, AStarGrid2D) mientras se construía el juego.
- Así hubo tiempo para pulir lo que se ve y se juega: interfaz propia, sonidos y easter eggs.

Para que todo se entienda, el código está comentado en español y la sección "Cómo funciona por
dentro" explica las partes principales. Estas son las preguntas que el equipo debe poder responder:

- ¿Qué es un autoload y por qué `Partida` es uno? (Sección "Persistencia")
- ¿Cómo se decide si un vigilante te ve? (Distancia + ángulo + rayo de física)
- ¿Cómo hace la rana para pasar por encima de las mesas? (Cambia la máscara de colisión)
- ¿Para qué sirve `AStarGrid2D`? (Buscar caminos entre celdas libres)
- ¿Qué es una señal en Godot? (`hizo_ruido`, `vio_al_jugador`, los `pidio_...` del HUD)
- ¿Por qué el HUD es un `CanvasLayer`? (Se dibuja encima de la cámara 3D y no se mueve con ella)

## Subir al repositorio

Este proyecto incluye un `.gitignore` para no subir archivos pesados o generados
(`.godot/`, `exportar/`, `android/`). Desde la carpeta del proyecto:

```
git init
git add .
git commit -m "Sobrevive al Parcial: primera versión"
git branch -M main
git remote add origin https://github.com/USUARIO/REPOSITORIO.git
git push -u origin main
```
