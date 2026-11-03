extends Node
## Herramienta de desarrollo: abre un nivel y toma capturas en varios puntos del mapa.
## Uso: godot --path . res://pruebas/Vistazo.tscn -- --nivel=2 --capturas=/ruta
var _carpeta := "user://vistazo"
var _nivel := 2

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--capturas="): _carpeta = a.trim_prefix("--capturas=")
		if a.begins_with("--nivel="): _nivel = int(a.trim_prefix("--nivel="))
	DirAccess.make_dir_recursive_absolute(_carpeta)
	Partida.nueva_partida(_nivel)
	var juego: Juego = load("res://escenas/Juego.tscn").instantiate()
	get_tree().root.add_child.call_deferred(juego)
	await get_tree().create_timer(1.0).timeout
	juego._continuar()
	juego._invulnerable = 999.0
	var c: int = juego._columnas
	var f: int = juego._filas
	var puntos := [Vector2i(1, 1), Vector2i(c / 2, f / 2), Vector2i(c - 3, f - 3), Vector2i(3, f - 3)]
	for i in puntos.size():
		juego.jugador.global_position = juego.celda_a_mundo(puntos[i])
		await get_tree().create_timer(1.2).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_carpeta.path_join("vistazo_%d.png" % i))
	get_tree().quit()
