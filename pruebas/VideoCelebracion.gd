extends Node
## Herramienta de desarrollo: entra al nivel 3 con 2 ranas y toma la tercera, para grabar la transformación.
func _ready() -> void:
	Partida.nueva_partida(3)
	Partida.ranas_partida = {"rana_biblioteca": true, "rana_bulevar": true}
	var juego: Juego = load("res://escenas/Juego.tscn").instantiate()
	get_tree().root.add_child.call_deferred(juego)
	await get_tree().create_timer(0.8).timeout
	juego._continuar()
	juego._invulnerable = 999.0
	juego.jugador.global_position = juego.celda_a_mundo(Vector2i(12, 9))
	await get_tree().create_timer(1.2).timeout
	juego.jugador.global_position = juego.celda_a_mundo(Vector2i(12, 8))
