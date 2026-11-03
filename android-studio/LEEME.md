# Proyecto de Android Studio

Esta carpeta es el juego listo para abrir en **Android Studio**. Godot lo generó con
**Proyecto → Exportar → Android** y trae adentro la última versión del juego (carpeta `assets/`).

## Cómo correrlo

1. Android Studio → **File → Open** → elegir **esta carpeta** (`android-studio`), no la raíz del repositorio.
2. Esperar a que termine el *Gradle Sync*. La primera vez descarga la librería de Godot
   (`org.godotengine:godot:4.5.1.stable`, unos 100 MB) desde Maven Central.
3. Si pide instalar **Android 16 (API 36)**, aceptar.
4. Conectar el celular (con depuración USB) o abrir un emulador → botón **Run ▶**.

## Por qué no está la librería de Godot aquí

Godot deja los archivos `libs/debug/godot-lib.template_debug.aar` (106 MB) y
`libs/release/godot-lib.template_release.aar` (96 MB), pero GitHub no acepta archivos de más de
100 MB. Por eso `build.gradle` usa la carpeta `libs/` si existe, y si no, descarga la misma
librería de Maven Central.

## Si cambian el juego

El código del juego se cambia en Godot, no aquí. Después:

1. En Godot: **Proyecto → Exportar → Android → Exportar proyecto**. Eso actualiza `android/build/`.
2. Copiar las carpetas `assets/` y `assetPackInstallTime/` de `android/build/` a esta carpeta,
   reemplazando las que hay.

**No editen los archivos de `assets/` en Android Studio.** Godot guarda el tamaño de cada archivo
en un índice (`assets.sparsepck`); si uno cambia, el juego se daña.

## Qué se cambió frente a la plantilla de Godot

| Archivo | Cambio |
|---|---|
| `config.gradle` | `compileSdk` y `targetSdk` en **36** (Android 16), lo que exige Google Play desde agosto de 2026 |
| `gradle.properties` | Paquete, versión y SDK 36 para cuando se compila desde Android Studio |
| `settings.gradle` | El proyecto se llama `SobreviveAlParcial` |
| `build.gradle` | Usa la librería de Godot de Maven Central si no está `libs/`, y copia bien el `.aab` al exportar |
