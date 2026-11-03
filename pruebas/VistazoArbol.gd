extends Node
## Herramienta de desarrollo: imprime el árbol de nodos de un nivel (para la presentación).
func _ready() -> void:
	Partida.nueva_partida(1)
	var juego: Juego = load("res://escenas/Juego.tscn").instantiate()
	get_tree().root.add_child.call_deferred(juego)
	await get_tree().create_timer(0.5).timeout
	_imprimir(juego, 0)
	var tipos := {}
	for n in juego.find_children("*", "", true, false):
		tipos[n.get_class()] = tipos.get(n.get_class(), 0) + 1
	print("TOTAL ", juego.find_children("*", "", true, false).size(), " ", tipos)
	get_tree().quit()

func _imprimir(n: Node, nivel: int) -> void:
	if nivel > 2:
		return
	var hijos := n.get_children()
	print("  ".repeat(nivel), n.name, " (", n.get_class(), ") hijos=", hijos.size())
	var vistos := {}
	for h in hijos:
		var k := h.get_class()
		vistos[k] = vistos.get(k, 0) + 1
		if vistos[k] <= 2:
			_imprimir(h, nivel + 1)
