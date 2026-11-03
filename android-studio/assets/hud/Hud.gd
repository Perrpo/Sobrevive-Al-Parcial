class_name Hud
extends CanvasLayer
## Lo que se ve encima del juego: vidas, apuntes, reloj, avisos, pausa y resultados.
## En el celular también muestra un joystick y botones táctiles.
## No toma decisiones del juego: solo avisa con señales y el nivel (Juego.gd) responde.

signal pidio_continuar
signal pidio_reiniciar
signal pidio_menu
signal pidio_siguiente
signal pidio_puntajes
signal pidio_poder

var _corazones: Corazones
var _apuntes: Label
var _tiempo: Label
var _nivel: Label
var _aviso: PanelContainer
var _aviso_texto: Label
var _destello: ColorRect
var _capa_modal: Control
var _tinto: Label
var joystick: Joystick
var boton_correr: BotonTactil
var boton_rana: BotonTactil
var _poder: Label
## true mientras se está moviendo/cambiando de tamaño el joystick (desde la pausa).
var ajustando_joystick := false
var _capa_ajuste: Control

const TAM_JOYSTICK := 220.0

var _tiempo_alarma := false
var _tween_aviso: Tween
var _raiz: Control


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_raiz = Control.new()
	_raiz.theme = Estilo.tema
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)

	_destello = ColorRect.new()
	_destello.color = Color(Estilo.ESFERO, 0.0)
	_destello.set_anchors_preset(Control.PRESET_FULL_RECT)
	_destello.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_destello)

	# Barra superior oscura, como el tablero del salón.
	var barra := PanelContainer.new()
	var estilo_barra := StyleBoxFlat.new()
	estilo_barra.bg_color = Color(Estilo.PANTALLA, 0.82)
	estilo_barra.set_corner_radius_all(18)
	estilo_barra.content_margin_left = 22
	estilo_barra.content_margin_right = 22
	estilo_barra.content_margin_top = 10
	estilo_barra.content_margin_bottom = 10
	barra.add_theme_stylebox_override("panel", estilo_barra)
	barra.set_anchors_preset(Control.PRESET_TOP_WIDE)
	barra.offset_left = 24
	barra.offset_right = -24
	barra.offset_top = 16
	_raiz.add_child(barra)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 28)
	barra.add_child(fila)

	_corazones = Corazones.new()
	_corazones.custom_minimum_size = Vector2(150, 34)
	fila.add_child(_corazones)
	_apuntes = Estilo.texto("Apuntes 0/0", 24, Estilo.PANTALLA_TEXTO, true)
	fila.add_child(_apuntes)
	_tinto = Estilo.texto("", 22, Color("#E0A458"), true)
	fila.add_child(_tinto)
	_poder = Estilo.texto("", 22, Color("#6BE38F"), true)
	fila.add_child(_poder)
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(hueco)
	_nivel = Estilo.texto("", 22, Color(Estilo.PANTALLA_TEXTO, 0.75))
	fila.add_child(_nivel)
	_tiempo = Estilo.texto("Quedan 0:00", 26, Estilo.RESALTADOR, true)
	_tiempo.custom_minimum_size.x = 230
	_tiempo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fila.add_child(_tiempo)
	if not Controles.es_tactil():
		# Botón de pausa para el mouse (en el celular hay uno grande aparte).
		var pausa := Button.new()
		pausa.text = "II"
		pausa.tooltip_text = "Pausa (Esc)"
		pausa.custom_minimum_size = Vector2(52, 40)
		pausa.focus_mode = Control.FOCUS_NONE
		pausa.add_theme_font_size_override("font_size", 18)
		pausa.name = "BotonPausa"
		pausa.pressed.connect(_pedir_pausa)
		fila.add_child(pausa)

	# Aviso tipo "post-it" que baja desde arriba.
	_aviso = PanelContainer.new()
	var estilo_aviso := StyleBoxFlat.new()
	estilo_aviso.bg_color = Estilo.RESALTADOR
	estilo_aviso.border_color = Estilo.TINTA
	estilo_aviso.set_border_width_all(3)
	estilo_aviso.set_corner_radius_all(6)
	estilo_aviso.shadow_color = Color(0, 0, 0, 0.35)
	estilo_aviso.shadow_offset = Vector2(5, 6)
	estilo_aviso.content_margin_left = 26
	estilo_aviso.content_margin_right = 26
	estilo_aviso.content_margin_top = 10
	estilo_aviso.content_margin_bottom = 12
	_aviso.add_theme_stylebox_override("panel", estilo_aviso)
	_aviso_texto = Estilo.nota("", 30, Estilo.TINTA)
	_aviso_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso_texto.autowrap_mode = TextServer.AUTOWRAP_OFF
	_aviso.add_child(_aviso_texto)
	_aviso.visible = false
	_raiz.add_child(_aviso)

	if Controles.es_tactil():
		_crear_controles_tactiles()


func _process(_delta: float) -> void:
	# Centra el aviso horizontalmente.
	if _aviso.visible:
		_aviso.position.x = (get_viewport().get_visible_rect().size.x - _aviso.size.x) / 2.0


# ---------- Datos en pantalla ----------

func poner_vidas(vidas: int) -> void:
	_corazones.vidas = vidas
	_corazones.queue_redraw()


func poner_apuntes(tomados: int, total: int) -> void:
	_apuntes.text = "Apuntes %d/%d" % [tomados, total]
	_apuntes.pivot_offset = _apuntes.size / 2
	var t := create_tween()
	t.tween_property(_apuntes, "scale", Vector2.ONE * 1.25, 0.08)
	t.tween_property(_apuntes, "scale", Vector2.ONE, 0.18)


func poner_tiempo(segundos: float) -> void:
	var s := maxi(0, ceili(segundos))
	_tiempo.text = "Quedan %d:%02d" % [s / 60, s % 60]
	var alarma := s <= 30
	if alarma != _tiempo_alarma:
		_tiempo_alarma = alarma
		_tiempo.add_theme_color_override("font_color", Color("#FF6B72") if alarma else Estilo.RESALTADOR)
	if alarma:
		_tiempo.modulate.a = 0.65 + 0.35 * absf(sin(Time.get_ticks_msec() / 180.0))


## Poder de la Xaca Rana: [param usos] que quedan (-1 = no tiene el poder)
## y [param segundos] que le quedan como rana (0 = no está convertido).
func poner_poder(usos: int, segundos: float) -> void:
	if usos < 0:
		_poder.text = ""
	elif segundos > 0.0:
		_poder.text = "Rana %d s" % ceili(segundos)
	else:
		_poder.text = "Rana ×%d [R]" % usos if not Controles.es_tactil() else "Rana ×%d" % usos
	if boton_rana:
		boton_rana.visible = usos >= 0
		boton_rana.texto = "RANA ×%d" % usos if segundos <= 0.0 else "%d s" % ceili(segundos)
		boton_rana.queue_redraw()


func poner_nivel(texto: String) -> void:
	_nivel.text = texto


func poner_tinto(segundos: float) -> void:
	_tinto.text = "Tinto %.0f s" % segundos if segundos > 0.0 else ""


func avisar(texto: String, segundos: float = 2.4) -> void:
	_aviso_texto.text = texto
	_aviso.visible = true
	_aviso.reset_size()
	_aviso.position.y = -120
	_aviso.rotation_degrees = randf_range(-2.0, 2.0)
	if _tween_aviso:
		_tween_aviso.kill()
	var t := create_tween()
	_tween_aviso = t
	t.tween_property(_aviso, "position:y", 96.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(segundos)
	t.tween_property(_aviso, "position:y", -140.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_callback(func(): _aviso.visible = false)


func destello() -> void:
	_destello.color.a = 0.45
	create_tween().tween_property(_destello, "color:a", 0.0, 0.45)


# ---------- Ventanas (presentación del nivel, pausa, resultados) ----------

func _abrir_modal(oscuro: float = 0.6) -> VBoxContainer:
	cerrar_modal()
	if _tween_aviso:
		_tween_aviso.kill()
	_aviso.visible = false
	_capa_modal = Control.new()
	_capa_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(_capa_modal)
	var velo := ColorRect.new()
	velo.color = Color(Estilo.PANTALLA, oscuro)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capa_modal.add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capa_modal.add_child(centro)
	var hoja := PanelContainer.new()
	var estilo_hoja := StyleBoxFlat.new()
	estilo_hoja.bg_color = Estilo.PAPEL
	estilo_hoja.border_color = Estilo.TINTA
	estilo_hoja.set_border_width_all(3)
	estilo_hoja.set_corner_radius_all(14)
	estilo_hoja.shadow_color = Color(0, 0, 0, 0.45)
	estilo_hoja.shadow_offset = Vector2(8, 10)
	estilo_hoja.content_margin_left = 48
	estilo_hoja.content_margin_right = 48
	estilo_hoja.content_margin_top = 34
	estilo_hoja.content_margin_bottom = 34
	hoja.add_theme_stylebox_override("panel", estilo_hoja)
	hoja.custom_minimum_size.x = 560
	centro.add_child(hoja)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 14)
	hoja.add_child(columna)
	# Animación de entrada: la hoja cae girando un poco.
	hoja.pivot_offset = Vector2(280, 200)
	hoja.rotation_degrees = -6.0
	hoja.scale = Vector2.ONE * 0.85
	hoja.modulate.a = 0.0
	var t := create_tween().set_parallel()
	t.tween_property(hoja, "rotation_degrees", -1.5, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(hoja, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(hoja, "modulate:a", 1.0, 0.2)
	return columna


func cerrar_modal() -> void:
	if _capa_modal:
		_capa_modal.queue_free()
		_capa_modal = null


func _fila_botones(columna: VBoxContainer) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 16)
	columna.add_child(fila)
	return fila


func presentar_nivel(numero: int, datos: Dictionary, total_apuntes: int, extra: String = "") -> void:
	var c := _abrir_modal(0.45)
	c.add_child(Estilo.etiqueta("Nivel %d · %s" % [numero, datos["hora"]]))
	c.add_child(Estilo.titulo(datos["nombre"], 64))
	var descripcion := Estilo.parrafo(datos["descripcion"], 22, Estilo.TINTA_SUAVE)
	descripcion.custom_minimum_size.x = 520
	c.add_child(descripcion)
	var meta := "Junta los %d apuntes y sal antes de que se acabe el tiempo." % total_apuntes
	var nota_meta := Estilo.nota(meta, 26)
	nota_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c.add_child(nota_meta)
	if extra != "":
		var texto_extra := Estilo.parrafo(extra, 20, Estilo.VERDE)
		texto_extra.add_theme_font_override("font", Estilo.fuente_negrita)
		c.add_child(texto_extra)
	var teclas := "Joystick para moverte · botón CORRER · II para pausar" if Controles.es_tactil() else "W A S D para moverte · Shift para correr · Esc o II para pausar"
	c.add_child(Estilo.parrafo(teclas, 18, Estilo.TINTA_SUAVE))
	var b := Estilo.boton("¡A estudiar!", func(): pidio_continuar.emit(), 260)
	_fila_botones(c).add_child(b)
	b.grab_focus()


func mostrar_pausa() -> void:
	var c := _abrir_modal()
	c.add_child(Estilo.titulo("Pausa", 64))
	c.add_child(Estilo.nota("El vigilante también se tomó un tinto.", 26))
	var fila := _fila_botones(c)
	var seguir := Estilo.boton("Continuar", func(): pidio_continuar.emit(), 200)
	seguir.name = "Continuar"
	fila.add_child(seguir)
	fila.add_child(Estilo.boton("Reiniciar nivel", func(): pidio_reiniciar.emit(), 220))
	var menu := Estilo.boton("Ir al menú", func(): pidio_menu.emit(), 180)
	menu.name = "IrAlMenu"
	fila.add_child(menu)
	if joystick:
		var ajustar := Estilo.boton("Ajustar joystick", _ajustar_joystick, 300)
		ajustar.name = "AjustarJoystick"
		_fila_botones(c).add_child(ajustar)
	seguir.grab_focus()


func _pedir_pausa() -> void:
	var e := InputEventAction.new()
	e.action = "pausa"
	e.pressed = true
	Input.parse_input_event(e)


# ---------- Ajustar el joystick (desde la pausa, en el celular) ----------

## Pone el joystick donde lo dejó el jugador y del tamaño que escogió.
func aplicar_joystick() -> void:
	if joystick == null:
		return
	var pantalla := get_viewport().get_visible_rect().size
	var tam := TAM_JOYSTICK * Partida.joystick_escala
	var centro := Vector2(40 + TAM_JOYSTICK / 2.0, pantalla.y - 40 - TAM_JOYSTICK / 2.0)
	if Partida.joystick_centro.x >= 0.0:
		centro = Partida.joystick_centro * pantalla
	joystick.size = Vector2(tam, tam)
	joystick.position = (centro - joystick.size / 2.0).clamp(Vector2.ZERO, pantalla - joystick.size)
	joystick.queue_redraw()


func _guardar_posicion_joystick() -> void:
	var pantalla := get_viewport().get_visible_rect().size
	Partida.joystick_centro = (joystick.position + joystick.size / 2.0) / pantalla


func _ajustar_joystick() -> void:
	cerrar_modal()
	ajustando_joystick = true
	joystick.ajustando = true
	joystick.queue_redraw()
	_capa_ajuste = Control.new()
	_capa_ajuste.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capa_ajuste.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_capa_ajuste)
	var velo := ColorRect.new()
	velo.color = Color(Estilo.PANTALLA, 0.55)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa_ajuste.add_child(velo)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_top = 90
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_capa_ajuste.add_child(panel)
	var c := VBoxContainer.new()
	c.add_theme_constant_override("separation", 10)
	panel.add_child(c)
	c.add_child(Estilo.titulo("Ajustar *joystick*", 40))
	c.add_child(Estilo.nota("Arrástralo con el dedo a donde te quede cómodo.", 22))
	var fila_tam := HBoxContainer.new()
	fila_tam.add_theme_constant_override("separation", 14)
	fila_tam.add_child(Estilo.texto("Tamaño", 22, Estilo.TINTA, true))
	var barra := HSlider.new()
	barra.name = "Tamano"
	barra.min_value = 0.6
	barra.max_value = 1.6
	barra.step = 0.05
	barra.value = Partida.joystick_escala
	barra.custom_minimum_size = Vector2(300, 32)
	barra.value_changed.connect(func(v: float):
		# Cambia de tamaño sin moverse de donde está.
		_guardar_posicion_joystick()
		Partida.joystick_escala = v
		aplicar_joystick())
	fila_tam.add_child(barra)
	c.add_child(fila_tam)
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 12)
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	var restablecer := Estilo.boton("Restablecer", func():
		Partida.joystick_centro = Vector2(-1, -1)
		Partida.joystick_escala = 1.0
		barra.set_value_no_signal(1.0)
		aplicar_joystick(), 200)
	botones.add_child(restablecer)
	var listo := Estilo.boton("Listo", _terminar_ajuste, 160)
	listo.name = "Listo"
	botones.add_child(listo)
	c.add_child(botones)
	# El joystick queda encima de todo para poder arrastrarlo.
	_raiz.move_child(joystick, -1)


func _terminar_ajuste() -> void:
	ajustando_joystick = false
	joystick.ajustando = false
	joystick.queue_redraw()
	_guardar_posicion_joystick()
	Partida.guardar()
	if _capa_ajuste:
		_capa_ajuste.queue_free()
		_capa_ajuste = null
	mostrar_pausa()


func mostrar_victoria(numero: int, detalle: Array, puntos: int, es_ultimo: bool) -> void:
	var c := _abrir_modal()
	c.add_child(Estilo.etiqueta("Nivel %d superado" % numero, Estilo.VERDE))
	c.add_child(Estilo.titulo("¡Lo *lograste*!", 60))
	for linea in detalle:
		var fila := HBoxContainer.new()
		var izq := Estilo.texto(linea[0], 22, Estilo.TINTA_SUAVE)
		izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(izq)
		fila.add_child(Estilo.texto(linea[1], 22, Estilo.TINTA, true))
		c.add_child(fila)
	var total := Estilo.titulo("0", 56)
	c.add_child(total)
	# Animación: el puntaje cuenta hasta el total.
	var t := create_tween()
	t.tween_method(func(v: int): total.text = "[color=#%s]+%d[/color] puntos" % [Estilo.ESFERO.to_html(false), v], 0, puntos, 1.0)
	var texto_boton := "¡Al parcial!" if es_ultimo else "Siguiente nivel"
	var b := Estilo.boton(texto_boton, func(): pidio_siguiente.emit(), 260)
	_fila_botones(c).add_child(b)
	b.grab_focus()


func mostrar_derrota(motivo: String) -> void:
	var c := _abrir_modal(0.7)
	var titulos := {"tiempo": "¡Sonó el *timbre*!", "vidas": "¡Te *pillaron*!"}
	var notas := {
		"tiempo": "Se acabó el tiempo antes de juntar los apuntes.",
		"vidas": "Te quedaste sin vidas. Camina despacio y no te metas en la luz.",
	}
	c.add_child(Estilo.titulo(titulos.get(motivo, "Fin"), 60))
	var explicacion := Estilo.nota(notas.get(motivo, ""), 26)
	explicacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c.add_child(explicacion)
	var fila := _fila_botones(c)
	var otra := Estilo.boton("Reintentar nivel", func(): pidio_reiniciar.emit(), 240)
	fila.add_child(otra)
	fila.add_child(Estilo.boton("Ver puntajes", func(): pidio_puntajes.emit(), 200))
	fila.add_child(Estilo.boton("Menú", func(): pidio_menu.emit(), 140))
	otra.grab_focus()


# ---------- Controles táctiles (celular) ----------

func _crear_controles_tactiles() -> void:
	joystick = Joystick.new()
	joystick.name = "Joystick"
	_raiz.add_child(joystick)
	joystick.movido.connect(_guardar_posicion_joystick)
	aplicar_joystick()
	get_viewport().size_changed.connect(aplicar_joystick)

	boton_correr = BotonTactil.new()
	boton_correr.texto = "CORRER"
	boton_correr.custom_minimum_size = Vector2(170, 170)
	boton_correr.anchor_left = 1.0
	boton_correr.anchor_right = 1.0
	boton_correr.anchor_top = 1.0
	boton_correr.anchor_bottom = 1.0
	boton_correr.offset_left = -220
	boton_correr.offset_right = -50
	boton_correr.offset_top = -230
	boton_correr.offset_bottom = -60
	_raiz.add_child(boton_correr)

	boton_rana = BotonTactil.new()
	boton_rana.texto = "RANA"
	boton_rana.color_fondo = Color("#37BB62")
	boton_rana.color_texto = Estilo.BLANCO
	boton_rana.anchor_left = 1.0
	boton_rana.anchor_right = 1.0
	boton_rana.anchor_top = 1.0
	boton_rana.anchor_bottom = 1.0
	boton_rana.offset_left = -200
	boton_rana.offset_right = -70
	boton_rana.offset_top = -330
	boton_rana.offset_bottom = -250
	boton_rana.visible = false
	boton_rana.tocado.connect(func(): pidio_poder.emit())
	_raiz.add_child(boton_rana)

	var pausa := BotonTactil.new()
	pausa.texto = "II"
	pausa.anchor_left = 1.0
	pausa.anchor_right = 1.0
	pausa.offset_left = -110
	pausa.offset_right = -36
	pausa.offset_top = 96
	pausa.offset_bottom = 160
	pausa.tocado.connect(_pedir_pausa)
	_raiz.add_child(pausa)


class Corazones extends Control:
	var vidas := 3

	func _draw() -> void:
		for i in Partida.VIDAS_MAXIMAS:
			var lleno := i < vidas
			if not lleno and i >= Partida.VIDAS_INICIALES:
				continue  # el 4.º corazón solo aparece si lo ganas (la Xaca Rana)
			_corazon(Vector2(18 + i * 36, 17), 14.0, lleno)

	func _corazon(centro: Vector2, r: float, lleno: bool) -> void:
		var puntos := PackedVector2Array()
		for i in 40:
			var t := TAU * i / 40.0
			var x := 16.0 * pow(sin(t), 3)
			var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
			puntos.append(centro + Vector2(x, y) * r / 16.0)
		if lleno:
			draw_colored_polygon(puntos, Color("#FF6B72"))
		puntos.append(puntos[0])
		draw_polyline(puntos, Color("#FF6B72") if lleno else Color(1, 1, 1, 0.35), 2.0, true)


class BotonTactil extends Control:
	## Botón para el celular que lee cada dedo por separado (InputEventScreenTouch),
	## así funciona aunque el otro dedo esté en el joystick.
	signal tocado
	var texto := ""
	var presionado := false
	var color_fondo := Estilo.BLANCO
	var color_texto := Estilo.TINTA
	var _dedo := -1

	func _gui_input(evento: InputEvent) -> void:
		if evento is InputEventScreenTouch:
			if evento.pressed and _dedo == -1:
				_dedo = evento.index
				presionado = true
				tocado.emit()
			elif not evento.pressed and evento.index == _dedo:
				_dedo = -1
				presionado = false
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var caja := StyleBoxFlat.new()
		caja.bg_color = Estilo.RESALTADOR if presionado else color_fondo
		caja.border_color = Estilo.TINTA
		caja.set_border_width_all(3)
		caja.set_corner_radius_all(16)
		draw_style_box(caja, r)
		var fuente := Estilo.fuente_negrita
		var tam := 24
		var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		draw_string(fuente, Vector2((size.x - ancho) / 2, size.y / 2 + tam * 0.35), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Estilo.TINTA if presionado else color_texto)


class Joystick extends Control:
	## Dirección actual, de -1 a 1 en cada eje (la lee el nivel y se la pasa al jugador).
	## Con [member ajustando] en true, arrastrarlo lo cambia de lugar en vez de mover al jugador.
	signal movido
	var direccion := Vector2.ZERO
	var ajustando := false
	var _dedo := -1
	var _punta := Vector2.ZERO

	func _gui_input(evento: InputEvent) -> void:
		if ajustando:
			_arrastrar(evento)
			return
		var radio := size.x / 2.0
		var centro := size / 2.0
		if evento is InputEventScreenTouch:
			if evento.pressed and _dedo == -1:
				_dedo = evento.index
				_mover(evento.position - centro, radio)
			elif not evento.pressed and evento.index == _dedo:
				_dedo = -1
				_mover(Vector2.ZERO, radio)
		elif evento is InputEventScreenDrag and evento.index == _dedo:
			_mover(evento.position - centro, radio)

	func _arrastrar(evento: InputEvent) -> void:
		var desplazamiento := Vector2.ZERO
		if evento is InputEventScreenDrag:
			desplazamiento = evento.relative
		elif evento is InputEventMouseMotion and evento.button_mask & MOUSE_BUTTON_MASK_LEFT \
				and evento.device != InputEvent.DEVICE_ID_EMULATION:
			# Mouse de verdad (para probarlo en el PC). El "mouse" que Godot inventa a partir
			# del dedo se ignora, si no el joystick se movería el doble.
			desplazamiento = evento.relative
		if desplazamiento == Vector2.ZERO:
			return
		var pantalla := get_viewport().get_visible_rect().size
		position = (position + desplazamiento).clamp(Vector2.ZERO, pantalla - size)
		movido.emit()
		accept_event()

	func _mover(desde_centro: Vector2, radio: float) -> void:
		_punta = desde_centro.limit_length(radio)
		direccion = _punta / radio
		queue_redraw()

	func _draw() -> void:
		var centro := size / 2.0
		draw_circle(centro, size.x / 2.0, Color(Estilo.PANTALLA, 0.45))
		draw_arc(centro, size.x / 2.0, 0, TAU, 48, Color(1, 1, 1, 0.5), 3.0, true)
		draw_circle(centro + _punta, size.x / 5.0, Color(Estilo.RESALTADOR, 0.9))
		if ajustando:
			# Marco punteado y flechas para que se note que se puede arrastrar.
			var r := Rect2(Vector2(-6, -6), size + Vector2(12, 12))
			var esquinas := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
			for i in 4:
				var a: Vector2 = esquinas[i]
				var b: Vector2 = esquinas[i + 1]
				var d := 0.0
				while d < a.distance_to(b):
					draw_line(a.move_toward(b, d), a.move_toward(b, minf(d + 10.0, a.distance_to(b))), Estilo.RESALTADOR, 3.0)
					d += 18.0
			var tam_letra := 18
			var aviso := "Arrástrame"
			var ancho := Estilo.fuente_negrita.get_string_size(aviso, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_letra).x
			draw_string(Estilo.fuente_negrita, Vector2((size.x - ancho) / 2.0, -14), aviso, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_letra, Estilo.RESALTADOR)
