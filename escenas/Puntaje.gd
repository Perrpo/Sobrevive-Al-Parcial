extends Control
## Puntajes: muestra el resultado de la última partida (con la nota en un sello),
## la tabla de los 10 mejores récords y el mejor puntaje de cada nivel.
## La tabla tiene dos pestañas: los récords de este celular (Partida, en disco)
## y el Top 10 en línea de todos los jugadores (Nube, con Firebase).

var _titulo_tabla: Label
var _filas: VBoxContainer
var _en_linea := false


func _ready() -> void:
	add_child(Estilo.fondo_cuaderno())
	Audio.musica("menu")

	var raiz := HBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 140
	raiz.offset_right = -60
	raiz.offset_top = 46
	raiz.offset_bottom = -36
	raiz.add_theme_constant_override("separation", 36)
	add_child(raiz)

	# Columna izquierda: último resultado.
	var izq := VBoxContainer.new()
	izq.custom_minimum_size.x = 420
	izq.add_theme_constant_override("separation", 12)
	raiz.add_child(izq)
	izq.add_child(Estilo.etiqueta("Tu resultado"))
	var r := Partida.resultado
	if r.is_empty():
		izq.add_child(Estilo.titulo("*Puntajes*", 64))
		var vacio := Estilo.nota("Todavía no has terminado una partida en esta sesión.", 26)
		vacio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		izq.add_child(vacio)
	else:
		_mostrar_resultado(izq, r)

	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 12)
	var otra := Estilo.boton("Jugar otra vez", func():
		Partida.nueva_partida(1)
		Transicion.ir("res://escenas/Juego.tscn"), 220)
	botones.add_child(otra)
	botones.add_child(Estilo.boton("Menú", func(): Transicion.ir("res://escenas/Home.tscn"), 140))
	var hueco := Control.new()
	hueco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	izq.add_child(hueco)
	izq.add_child(_mejores_por_nivel())
	izq.add_child(botones)
	otra.grab_focus()

	# Columna derecha: tabla de récords.
	var der := Estilo.tarjeta()
	der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	raiz.add_child(der)
	var tabla := VBoxContainer.new()
	tabla.add_theme_constant_override("separation", 6)
	der.add_child(tabla)
	_titulo_tabla = Estilo.texto("", 30, Estilo.TINTA, true)
	tabla.add_child(_titulo_tabla)
	var pestanas := HBoxContainer.new()
	pestanas.add_theme_constant_override("separation", 10)
	pestanas.add_child(Estilo.boton("En este celular", _mostrar_locales, 200))
	var en_linea := Estilo.boton("En línea", _mostrar_en_linea, 150)
	en_linea.name = "EnLinea"
	pestanas.add_child(en_linea)
	tabla.add_child(pestanas)
	_filas = VBoxContainer.new()
	_filas.add_theme_constant_override("separation", 6)
	tabla.add_child(_filas)

	Nube.ranking_recibido.connect(_al_recibir_ranking)
	Nube.fallo.connect(_al_fallar_nube)
	# Si la nota terminó de subir después de abrir esta pantalla, se recarga el ranking.
	Nube.nota_enviada.connect(_al_enviar_nota)
	_mostrar_locales()


func _limpiar_filas() -> void:
	for hijo in _filas.get_children():
		hijo.queue_free()


func _mostrar_locales() -> void:
	_en_linea = false
	_titulo_tabla.text = "Top 10 del salón"
	_limpiar_filas()
	if Partida.records.is_empty():
		_filas.add_child(Estilo.nota("Nadie ha presentado el parcial todavía.", 24, Estilo.TINTA_SUAVE))
	var posicion := Partida.posicion_en_records(int(Partida.resultado.get("puntaje", -1)))
	var filas: Array = []
	for i in Partida.records.size():
		var fila := _fila_record(i + 1, Partida.records[i], i + 1 == posicion)
		_filas.add_child(fila)
		filas.append(fila)
	Estilo.entrar_en_cascada(filas, 0.05)


func _mostrar_en_linea() -> void:
	_en_linea = true
	_titulo_tabla.text = "Top 10 en línea"
	_limpiar_filas()
	if not Nube.activa():
		_filas.add_child(Estilo.nota("El ranking en línea no está configurado (ver FIREBASE.md).", 22, Estilo.TINTA_SUAVE))
		return
	_filas.add_child(Estilo.nota("Cargando…", 24, Estilo.TINTA_SUAVE))
	Nube.pedir_ranking()


func _al_recibir_ranking(lista: Array) -> void:
	if not _en_linea:
		return
	_limpiar_filas()
	if lista.is_empty():
		_filas.add_child(Estilo.nota("Todavía nadie ha subido su nota.", 24, Estilo.TINTA_SUAVE))
	var filas: Array = []
	for i in lista.size():
		var dato: Dictionary = lista[i]
		var fecha := Time.get_datetime_dict_from_unix_time(int(float(dato.get("momento", 0)) / 1000.0))
		var rec := {
			"nombre": dato.get("nombre", "?"),
			"nota": dato.get("nota", 0.0),
			"puntaje": int(dato.get("puntaje", 0)),
			"fecha": "%02d/%02d/%d" % [fecha.day, fecha.month, fecha.year],
		}
		var fila := _fila_record(i + 1, rec, dato.get("id", "") == Nube.ultimo_id)
		_filas.add_child(fila)
		filas.append(fila)
	Estilo.entrar_en_cascada(filas, 0.05)


func _al_enviar_nota() -> void:
	if _en_linea:
		Nube.pedir_ranking()


func _al_fallar_nube(texto: String) -> void:
	if not _en_linea:
		return
	_limpiar_filas()
	_filas.add_child(Estilo.nota(texto, 22, Estilo.ESFERO))


func _mostrar_resultado(c: VBoxContainer, r: Dictionary) -> void:
	var gano: bool = r["gano"]
	var titulo := "¡*Pasaste*!" if gano and r["nota"] >= 3.0 else ("*Perdiste* el parcial" if gano else "No llegaste al *parcial*")
	c.add_child(Estilo.titulo(titulo, 52))

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 20)
	c.add_child(fila)
	var sello := SelloNota.new()
	sello.custom_minimum_size = Vector2(150, 150)
	sello.nota = r["nota"] if gano else 0.0
	sello.aprobo = gano and r["nota"] >= 3.0
	fila.add_child(sello)
	var datos := VBoxContainer.new()
	fila.add_child(datos)
	var total := Estilo.titulo("0", 56)
	datos.add_child(total)
	datos.add_child(Estilo.texto("puntos", 20, Estilo.TINTA_SUAVE))
	var motivos := {"parcial": "Presentaste el parcial", "tiempo": "Se acabó el tiempo", "vidas": "Te quedaste sin vidas"}
	datos.add_child(Estilo.nota(motivos.get(r["motivo"], ""), 24))

	# Animaciones: el sello cae y el puntaje cuenta.
	sello.pivot_offset = Vector2(75, 75)
	sello.scale = Vector2.ONE * 2.5
	sello.modulate.a = 0.0
	var t := create_tween().set_parallel()
	t.tween_property(sello, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.3)
	t.tween_property(sello, "modulate:a", 1.0, 0.2).set_delay(0.3)
	t.tween_callback(func(): Audio.efecto("acierto" if sello.aprobo else "error")).set_delay(0.6)
	t.tween_method(func(v: int): total.text = str(v), 0, int(r["puntaje"]), 1.2)

	var pos := Partida.posicion_en_records(int(r["puntaje"]))
	if pos > 0:
		c.add_child(Estilo.texto("Quedaste de #%d en la tabla" % pos, 20, Estilo.VERDE, true))


func _mejores_por_nivel() -> VBoxContainer:
	var c := VBoxContainer.new()
	c.add_child(Estilo.texto("Mejor por nivel", 20, Estilo.TINTA, true))
	for n in range(1, Partida.NIVELES + 1):
		var mejor: Dictionary = Partida.mejores.get(str(n), {})
		var texto := "—" if mejor.is_empty() else "%d pts en %d s" % [mejor["puntaje"], mejor["tiempo"]]
		c.add_child(Estilo.texto("%s: %s" % [DatosNiveles.nivel(n)["nombre"], texto], 18, Estilo.TINTA_SUAVE))
	return c


func _fila_record(pos: int, rec: Dictionary, resaltar: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(Estilo.RESALTADOR, 0.75) if resaltar else Color(0, 0, 0, 0)
	fondo.set_corner_radius_all(6)
	fondo.content_margin_left = 8
	fondo.content_margin_right = 8
	fondo.content_margin_top = 2
	fondo.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", fondo)
	var fila := HBoxContainer.new()
	panel.add_child(fila)
	var numero := Estilo.texto("%d." % pos, 20, Estilo.ESFERO, true)
	numero.custom_minimum_size.x = 40
	fila.add_child(numero)
	var quien := Estilo.texto(str(rec["nombre"]), 20, Estilo.TINTA)
	quien.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quien.autowrap_mode = TextServer.AUTOWRAP_OFF
	fila.add_child(quien)
	var nota := Estilo.nota("%.1f" % float(rec["nota"]), 22, Estilo.VERDE if float(rec["nota"]) >= 3.0 else Estilo.ESFERO)
	nota.custom_minimum_size.x = 60
	fila.add_child(nota)
	var puntos := Estilo.texto(str(rec["puntaje"]), 20, Estilo.TINTA, true)
	puntos.custom_minimum_size.x = 90
	puntos.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fila.add_child(puntos)
	var fecha := Estilo.texto(str(rec["fecha"]), 16, Estilo.TINTA_SUAVE)
	fecha.custom_minimum_size.x = 120
	fecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fila.add_child(fecha)
	return panel


class SelloNota extends Control:
	## La nota escrita con esfero dentro de un círculo, como la que pone el profe.
	var nota := 0.0
	var aprobo := false

	func _draw() -> void:
		var color := Estilo.VERDE if aprobo else Estilo.ESFERO
		var c := size / 2
		var r := minf(size.x, size.y) / 2 - 4
		draw_arc(c, r, 0, TAU, 64, color, 5.0, true)
		var texto := "%.1f" % nota
		var tam := 56
		var ancho := Estilo.fuente_mano.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		draw_string(Estilo.fuente_mano, Vector2(c.x - ancho / 2, c.y + tam * 0.33), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, color)
