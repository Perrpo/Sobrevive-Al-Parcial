# Ficha de Google Play — Sobrevive al Parcial

Esta ficha trae todo lo que pide Google Play Console para publicar el juego. Los archivos están en esta carpeta.

> En el repositorio no están el `.aab` ni la llave de subida (`../aab/` y `../llave/` en esta ficha): los tiene el equipo en el zip de Google Play. **La llave nunca se sube a GitHub.**

> **Firebase ya está conectado** (`https://sobrevive-al-parcial-default-rtdb.firebaseio.com`). Antes de subir a Play, generen el `.aab` desde Godot con el proyecto actualizado (sección 7), para que traiga el ranking en línea funcionando.

## 0. Datos técnicos de la app

| Dato | Valor |
|---|---|
| Archivo para subir | `../aab/SobreviveAlParcial.aab` (Android App Bundle; Google Play ya no acepta APK para apps nuevas) |
| Nombre del paquete | `com.equipo.sobrevivealparcial` (**no se puede cambiar** después de la primera subida) |
| Versión | código **1**, nombre **1.0** |
| SDK mínimo | 24 (Android 7.0) |
| SDK objetivo | **36 (Android 16)**: es lo que exige Google Play desde el 31 de agosto de 2026 |
| Arquitecturas | arm64-v8a (64 bits, obligatoria) y armeabi-v7a (celulares viejos) |
| Firma | El .aab va firmado con la **llave de subida** (`../llave/`). Google guarda la llave final de la app (firma de apps de Play) |
| Permisos | `INTERNET` (solo para el ranking en línea) |
| Orientación | Horizontal |
| Internet | Solo para el ranking en línea con Firebase. El resto del juego funciona sin conexión |

> Cada vez que suban una versión nueva, hay que subir el **código de versión** en Godot (Proyecto → Exportar → "Android Google Play" → Version → Code: 2, 3, 4…). Si no, Play rechaza el archivo.

## 1. Recursos gráficos

| Recurso | Archivo | Medida | Formato exigido | ¿Obligatorio? |
|---|---|---|---|---|
| Ícono de la app | `icono-512x512.png` | **512 × 512 px** | PNG de 32 bits, máx. 1 MB. Cuadrado completo: Play le redondea las esquinas | Sí |
| Gráfico destacado | `grafico-destacado-1024x500.png` | **1024 × 500 px** | PNG de 24 bits o JPG, sin transparencia, máx. 15 MB | Sí |
| Capturas de teléfono | `capturas/*.png` (8) | **1920 × 1080 px** (16:9, horizontal) | PNG o JPG sin transparencia. Mín. 2, máx. 8. Cada lado entre 320 y 3840 px; el lado largo no puede pasar de 2 veces el corto | Sí (mín. 2) |
| Capturas de tablet de 7" y 10" | las mismas de `capturas/` | 1920 × 1080 px | Mismas reglas | Opcional, pero sirven las mismas porque el juego es horizontal |
| Video | Enlace de YouTube | — | Video público o no listado, sin anuncios | Opcional: pueden subir a YouTube uno de los videos de la entrega del juego |

Revisamos todos los archivos con un script: medidas, bits de color, transparencia y peso. Google Play los vuelve a validar al subirlos.

Para los juegos, Google recomienda subir **al menos 4 capturas horizontales de 1080p**. Así el juego puede salir en las recomendaciones. Estas 8 cumplen.

## 2. Textos de la ficha (Presencia en Play Store → Ficha principal)

**Nombre de la app** (máx. 30 caracteres, este tiene 20):
```
Sobrevive al Parcial
```

**Descripción breve** (máx. 80 caracteres, esta tiene 75):
```
Recupera tus apuntes sin que te pillen y llega al parcial de las 8:00 a. m.
```

**Descripción completa** (máx. 4000 caracteres, esta tiene 1651):
```
Te quedaste dormido la tarde antes del parcial final, entró una ventisca por la ventana y se llevó todos tus apuntes. Tienes hasta las 8:00 a. m. para recuperarlos por toda la universidad… sin que te pillen.

📚 5 NIVELES, DE LA TARDE A LA MAÑANA
• Biblioteca, 6:00 p. m.: estantes, silencio y una bibliotecaria con linterna.
• Bulevar, 7:30 p. m.: mesas, kioscos y estudiantes que estorban.
• Bloque de Ingeniería, 10:00 p. m.: pasillos oscuros y puertas con código.
• Parqueadero, 7:00 a. m.: escóndete entre los carros del vigilante.
• Pasillo del Salón 304, 7:50 a. m.: 100 segundos y el profe vigilando.

👀 SIGILO DE VERDAD
Cada vigilante ve en un cono delante de él y oye cuando corres. Escóndete detrás de estantes, carros y jardineras. Si te ven, pierdes una vida y vuelves a la entrada.

🐸 LAS 3 XACA RANAS
El profe escondió 3 ranas por la U. Encuéntralas todas y te convierten en rana: más rápida, salta por encima de mesas y carros, y los vigilantes no te reconocen.

📝 EL PARCIAL FINAL
Al llegar al salón presentas el parcial. Tu nota sale de las vidas que te quedaron, las ranas que encontraste y el tiempo que te sobró. ¿Sacarás 5.0?

🏆 RANKING EN LÍNEA
Tu nota del parcial se sube al Top 10 en línea para que compitas con jugadores de todas partes, en celular o PC. Si no quieres aparecer, lo apagas en Ajustes.

🎮 PENSADO PARA EL CELULAR
Joystick en pantalla que puedes mover y agrandar desde la pausa, botón para correr y botón RANA. Tu progreso y tus récords se guardan solos.

✔ Gratis, sin anuncios y sin compras
✔ Se juega sin internet (solo el ranking en línea la necesita)

Hecho en Godot por estudiantes de Aplicaciones Móviles.
```

## 3. Configuración de la tienda (Presencia en Play Store → Configuración de la tienda)

| Campo | Valor |
|---|---|
| Tipo de app | **Juego** |
| Categoría | **Arcade** (otra opción razonable: Casual) |
| Etiquetas | Elijan hasta 5 de la lista que ofrece Play, por ejemplo: *Un jugador*, *Estilizado*, *Casual*, *Competitivo* |
| Correo electrónico | **Obligatorio**: el correo del equipo |
| Teléfono y sitio web | Opcionales |
| Precio | **Gratis**. Ojo: una app gratis no se puede volver de pago después |
| Países | Colombia, o todos los países |

## 4. Contenido de la app (Política → Contenido de la app)

| Sección | Qué responder |
|---|---|
| Política de privacidad | **Obligatoria**. Publiquen `politica-de-privacidad.html` en una página pública (GitHub Pages o Google Sites), cambien el correo de contacto del final y peguen la URL. No puede ser un PDF ni una página privada. Ya menciona Firebase y el ranking en línea |
| Anuncios | **No**, la app no contiene anuncios |
| Acceso a la app | **Toda la funcionalidad está disponible sin acceso especial** (no hay inicio de sesión) |
| Clasificación de contenido | Cuestionario IARC. Categoría: **Juego**. Violencia, miedo, sexo, lenguaje vulgar, drogas, alcohol, tabaco, apuestas: **No** a todo. La única "persecución" es que un vigilante te ve y vuelves a la entrada, sin golpes. ¿Los usuarios interactúan o comparten contenido? **Sí, solo de forma limitada**: el nombre que cada jugador escribe sale en el ranking en línea. No hay chat ni mensajes. ¿Comparte la ubicación? **No**. ¿Compras digitales? **No**. Resultado esperado: **Para todos** (PEGI 3 / ESRB E) |
| Público objetivo | **13 a 15, 16 a 17 y 18 o más**. No marquen menores de 13: eso activa la política de Familias, con muchos más requisitos. ¿Atrae a niños sin querer? **No**: el tema es la universidad |
| Seguridad de los datos | ¿Recopila datos? **Sí**. ¿Comparte datos con terceros? **No**: Firebase trabaja para ustedes como proveedor, y Google no lo cuenta como "compartir". ¿Están cifrados en tránsito? **Sí** (HTTPS). ¿Se pueden borrar? **Sí**, escribiendo al correo de contacto. Tipos de datos: **Información personal → Nombre** (el apodo del ranking) y **Actividad en la app → Otras acciones** (nota, puntaje y ranas). Para los dos: recopilación **opcional** (se apaga en Ajustes), uso **Funcionalidad de la app**, sin anuncios ni análisis. El progreso y los récords del celular no cuentan porque nunca salen del dispositivo |
| ID de publicidad | **No** usa el ID de publicidad |
| App gubernamental | No |
| Funciones financieras | La app **no** ofrece funciones financieras |
| Salud | La app **no** tiene funciones de salud |
| App de noticias | No |

## 5. Publicar paso a paso

1. **Cuenta de desarrollador.** Se crea en play.google.com/console: pago único de **25 USD** y verificación de identidad. Si es personal, Google pide nombre legal, dirección y un documento.
2. **Crear app.** Nombre "Sobrevive al Parcial", idioma predeterminado **español (Latinoamérica) – es-419**, tipo **Juego**, **Gratis**. Aceptar las declaraciones.
3. **Llenar las secciones** 2, 3 y 4 de esta ficha.
4. **Prueba interna** (Pruebas → Prueba interna → Crear versión):
   - Aceptar la **firma de apps de Play**: Google genera la llave final y ustedes solo usan la de subida.
   - Subir `SobreviveAlParcial.aab`.
   - Agregar los correos de los testers, por ejemplo los del equipo.
   - Sirve para instalarlo de una vez desde Play.
5. **Prueba cerrada.** Si la cuenta es **personal y se creó después del 13 de noviembre de 2023**, Google exige una prueba cerrada con **al menos 12 testers durante 14 días seguidos** antes de dejar publicar en producción. Conviene arrancarla apenas puedan: 4 testers por integrante. Los testers deben aceptar la invitación con el enlace que da Play Console y dejar el juego instalado.
6. **Producción.** Después de los 14 días aparece "Solicitar acceso a producción". Google hace unas preguntas sobre la prueba. Cuando lo aprueben, se crea la versión de producción con el mismo .aab, o uno nuevo con código de versión más alto, y se envía a revisión. La revisión suele tardar de unas horas a unos días.

## 6. La llave de subida (MUY IMPORTANTE)

- Está en `../llave/llave-de-subida.jks`. Su contraseña está en `../llave/CLAVE.txt`. El alias es `subida`.
- Con esta llave se firma **cada** versión nueva. Guárdenla en un lugar seguro (Drive del equipo, dos copias). **No la suban a GitHub** ni la manden por grupos abiertos.
- Si se pierde, la app no se pierde porque Google tiene la llave final. Pero hay que pedir un cambio de llave en Play Console (Configuración → Integridad de la app), y eso tarda.

## 7. Cómo generar un .aab nuevo (después de cambiar el juego)

1. En Godot: **Editor → Configuración del editor → Exportar → Android**. En **Release Keystore** poner la ruta de `llave-de-subida.jks`, el usuario `subida` y la contraseña de `CLAVE.txt`. Esto se hace una sola vez y queda en su PC, no en el proyecto.
2. Subir el código de versión en el preset **"Android Google Play"**.
3. **Proyecto → Exportar → "Android Google Play" → Exportar proyecto**. **Quitar** la casilla "Exportar con depuración" y guardarlo como `SobreviveAlParcial.aab`.

Si Godot termina pero el .aab no aparece donde lo guardaron, búsquenlo en `android/build/build/outputs/bundle/standardRelease/`.
