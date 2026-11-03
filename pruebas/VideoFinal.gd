extends Node
## Herramienta de desarrollo: abre la animación del parcial con una partida de ejemplo.
func _ready() -> void:
	Partida.nueva_partida(5)
	Partida.vidas = 2
	Partida.ranas_partida = {"rana_biblioteca": true, "rana_bulevar": true, "rana_ingenieria": true}
	Partida.tiempo_total = 730.0
	Partida.tiempo_sobrante = 160.0
	get_tree().root.add_child.call_deferred(load("res://escenas/Final.tscn").instantiate())
