extends Control
## Selección de nivel. Muestra los 5 niveles como tarjetas, con candado si todavía
## no se han desbloqueado y el mejor puntaje de cada uno.


func _ready() -> void:
	add_child(Estilo.fondo_cuaderno())

	var columna := VBoxContainer.new()
	columna.set_anchors_preset(Control.PRESET_FULL_RECT)
	columna.offset_left = 140
	columna.offset_right = -60
	columna.offset_top = 50
	columna.offset_bottom = -40
	columna.add_theme_constant_override("separation", 18)
	add_child(columna)

	columna.add_child(Estilo.etiqueta("La tarde antes y la mañana del parcial (8:00 a. m.)"))
	columna.add_child(Estilo.titulo("Elige *nivel*", 64))

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columna.add_child(fila)

	var tarjetas: Array = []
	var primero: Button
	for n in range(1, Partida.NIVELES + 1):
		var t := _tarjeta(n)
		fila.add_child(t)
		tarjetas.append(t)
		var b: Button = t.get_meta("boton")
		if primero == null and not b.disabled:
			primero = b
	Estilo.entrar_en_cascada(tarjetas, 0.08)

	var volver := Estilo.boton("Volver", func(): Transicion.ir("res://escenas/Home.tscn"), 200)
	columna.add_child(volver)
	if primero:
		primero.grab_focus()


func _tarjeta(n: int) -> PanelContainer:
	var abierto := n <= Partida.nivel_desbloqueado
	var tarjeta := Estilo.tarjeta()
	tarjeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var c := VBoxContainer.new()
	c.add_theme_constant_override("separation", 8)
	tarjeta.add_child(c)

	var d := DatosNiveles.nivel(n)
	var nombre: String = d["nombre"]
	var detalle: String = d["descripcion"]

	c.add_child(Estilo.etiqueta("Nivel %d · %s" % [n, d["hora"]], Estilo.ESFERO if abierto else Estilo.TINTA_SUAVE))
	var titulo := Estilo.parrafo(nombre, 24, Estilo.TINTA if abierto else Estilo.TINTA_SUAVE)
	titulo.add_theme_font_override("font", Estilo.fuente_negrita)
	c.add_child(titulo)
	var texto := Estilo.parrafo(detalle if abierto else "Bloqueado: pasa el nivel anterior.", 15, Estilo.TINTA_SUAVE)
	texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.add_child(texto)

	var mejor: Dictionary = Partida.mejores.get(str(n), {})
	if not mejor.is_empty():
		c.add_child(Estilo.nota("Mejor: %d pts" % mejor["puntaje"], 20))

	var b := Estilo.boton("Jugar" if abierto else "Bloqueado", func(): _jugar(n))
	b.disabled = not abierto
	c.add_child(b)
	tarjeta.set_meta("boton", b)
	if not abierto:
		tarjeta.modulate = Color(1, 1, 1, 0.75)
	return tarjeta


func _jugar(n: int) -> void:
	Partida.nueva_partida(n)
	Transicion.ir("res://escenas/Juego.tscn")
