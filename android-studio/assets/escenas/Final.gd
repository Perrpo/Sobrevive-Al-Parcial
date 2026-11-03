extends Control
## El final del juego: animación del parcial en el Salón 304 a las 8:00 a. m.
## La Xaca Rana (el profe) reparte el parcial, el estudiante lo presenta, se lo entrega
## y la Xaca Rana lo califica. La nota sale de cómo se jugó (Partida.calcular_nota()).
## Igual que la historia del inicio, es una línea de tiempo de eventos en _process.

const ESCENA_SIGUIENTE := "res://escenas/Puntaje.tscn"

var _tiempo := 0.0
var _i_evento := 0
var _eventos: Array = []
var _terminado := false
var _nota := 0.0

var _camara: Camera3D
var _estudiante: Node3D
var _profe: Node3D
var _hoja: Node3D
var _lapiz: Node3D
var _reloj: Label3D
var _croac: Label3D
var _escribiendo := false

var _subtitulo: PanelContainer
var _texto_subtitulo: Label
var _globo: PanelContainer
var _texto_globo: Label


func _ready() -> void:
	_nota = Partida.calcular_nota()
	var vista := SubViewportContainer.new()
	vista.stretch = true
	vista.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vista)
	var viewport := SubViewport.new()
	viewport.msaa_3d = Viewport.MSAA_4X
	vista.add_child(viewport)
	var mundo := Node3D.new()
	viewport.add_child(mundo)
	_crear_salon(mundo)
	_camara = Camera3D.new()
	_camara.fov = 50
	mundo.add_child(_camara)
	_crear_interfaz()

	_eventos = [
		[0.0, _toma_salon],
		[0.3, func():
			Audio.efecto("timbre")
			_decir("8:00 a. m. · Salón 304. Llegaste justo a tiempo.")],
		[3.6, _repartir],
		[7.4, _escribir],
		[11.6, _entregar],
		[14.4, _revisar],
		[17.4, _calificar],
		[24.5, _terminar],
	]
	Audio.musica("menu")


func _process(delta: float) -> void:
	if _terminado:
		return
	_tiempo += delta
	while _i_evento < _eventos.size() and _tiempo >= _eventos[_i_evento][0]:
		var evento: Callable = _eventos[_i_evento][1]
		_i_evento += 1
		evento.call()
	if _escribiendo:
		# El lápiz va y viene sobre la hoja.
		_lapiz.position.x = _hoja.position.x + sin(_tiempo * 14.0) * 0.08
		_lapiz.position.z = _hoja.position.z + fmod(_tiempo * 0.12, 0.25) - 0.12


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("pausa"):
		_terminar()


# ---------- El salón ----------

func _crear_salon(mundo: Node3D) -> void:
	var entorno := WorldEnvironment.new()
	entorno.environment = Environment.new()
	entorno.environment.background_mode = Environment.BG_COLOR
	entorno.environment.background_color = Color("#BFD9EE")
	entorno.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.environment.ambient_light_color = Color("#FFF4E0")
	entorno.environment.ambient_light_energy = 0.5
	entorno.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	mundo.add_child(entorno)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, -35, 0)
	sol.light_energy = 0.7
	sol.shadow_enabled = true
	mundo.add_child(sol)

	mundo.add_child(Constructor.caja(Vector3(12, 0.1, 12), Color("#C9CDD3"), Vector3(0, -0.05, 1)))
	mundo.add_child(Constructor.caja(Vector3(12, 4, 0.2), Color("#E9E6E0"), Vector3(0, 2, -3.2)))
	mundo.add_child(Constructor.caja(Vector3(0.2, 4, 12), Color("#E2DED5"), Vector3(-5, 2, 1)))
	# Ventanas a la derecha con la mañana.
	mundo.add_child(Constructor.caja(Vector3(0.2, 4, 12), Color("#E2DED5"), Vector3(5, 2, 1)))
	for z in [-1.5, 1.5, 4.5]:
		mundo.add_child(Constructor.caja(Vector3(0.05, 1.4, 1.8), Color("#CFE6FA"), Vector3(4.88, 2.0, z), 0.6))
	# Tablero.
	mundo.add_child(Constructor.caja(Vector3(4.2, 1.7, 0.06), Color("#2F4F3A"), Vector3(-0.6, 2.0, -3.06)))
	var tablero := Label3D.new()
	tablero.text = "PARCIAL FINAL\nAplicaciones Móviles"
	tablero.font = Estilo.fuente_mano
	tablero.font_size = 64
	tablero.pixel_size = 0.006
	tablero.modulate = Color("#F4F4EC")
	tablero.position = Vector3(-0.6, 2.05, -3.02)
	mundo.add_child(tablero)
	# Reloj de pared.
	mundo.add_child(Constructor.cilindro(0.32, 0.32, 0.05, Color("#FFFFFF"), Vector3(2.6, 2.9, -3.08)))
	_reloj = Label3D.new()
	_reloj.text = "8:00"
	_reloj.font = Estilo.fuente_negrita
	_reloj.font_size = 48
	_reloj.pixel_size = 0.006
	_reloj.modulate = Estilo.TINTA
	_reloj.position = Vector3(2.6, 2.9, -3.0)
	mundo.add_child(_reloj)

	# Escritorio y la Xaca Rana.
	var escritorio := Constructor.mesa(Color("#8C6A48"))
	escritorio.position = Vector3(1.2, 0, -1.9)
	mundo.add_child(escritorio)
	_profe = Constructor.profe_rana()
	_profe.position = Vector3(1.6, 0, -2.6)
	mundo.add_child(_profe)
	_croac = Label3D.new()
	_croac.text = "¡Croac!"
	_croac.font = Estilo.fuente_titulo
	_croac.font_size = 64
	_croac.pixel_size = 0.005
	_croac.modulate = Color("#6BE38F")
	_croac.outline_size = 14
	_croac.outline_modulate = Estilo.PANTALLA
	_croac.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_croac.position = Vector3(1.0, 2.9, -2.4)
	_croac.visible = false
	mundo.add_child(_croac)

	# Pupitres con compañeros; el del medio de adelante es el del jugador.
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	for fila in 3:
		for col in 4:
			var pos := Vector3(-3.0 + col * 2.0, 0, 0.4 + fila * 1.9)
			var pupitre := Constructor.pupitre()
			pupitre.position = pos
			pupitre.rotation.y = PI
			mundo.add_child(pupitre)
			if fila == 0 and col == 1:
				continue  # aquí se sienta el jugador
			var companero := Constructor.estudiante(Estudiante.CAMISAS[rng.randi() % Estudiante.CAMISAS.size()], Color("#182742"))
			companero.position = pos + Vector3(0, -0.3, 0.55)
			companero.rotation.y = PI
			mundo.add_child(companero)
	_estudiante = Constructor.estudiante()
	_estudiante.position = Vector3(-1.0, -0.3, 0.95)
	_estudiante.rotation.y = PI
	mundo.add_child(_estudiante)
	_hoja = Constructor.caja(Vector3(0.32, 0.01, 0.42), Color("#FFFFFF"))
	_hoja.position = Vector3(-1.0, 0.86, 0.4)
	_hoja.visible = false
	mundo.add_child(_hoja)
	_lapiz = Constructor.cilindro(0.015, 0.015, 0.18, Color("#FFD24D"))
	_lapiz.rotation.x = 0.9
	_lapiz.position = _hoja.position + Vector3(0, 0.08, 0)
	_lapiz.visible = false
	mundo.add_child(_lapiz)


# ---------- Interfaz ----------

func _crear_interfaz() -> void:
	_subtitulo = PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(Estilo.PANTALLA, 0.85)
	estilo.set_corner_radius_all(14)
	estilo.content_margin_left = 28
	estilo.content_margin_right = 28
	estilo.content_margin_top = 14
	estilo.content_margin_bottom = 16
	_subtitulo.add_theme_stylebox_override("panel", estilo)
	_subtitulo.anchor_left = 0.1
	_subtitulo.anchor_right = 0.9
	_subtitulo.anchor_top = 1.0
	_subtitulo.anchor_bottom = 1.0
	_subtitulo.offset_top = -120
	_subtitulo.offset_bottom = -36
	_subtitulo.modulate.a = 0.0
	add_child(_subtitulo)
	_texto_subtitulo = Estilo.nota("", 32, Estilo.PANTALLA_TEXTO)
	_texto_subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto_subtitulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_texto_subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitulo.add_child(_texto_subtitulo)

	_globo = PanelContainer.new()
	var estilo_globo := StyleBoxFlat.new()
	estilo_globo.bg_color = Estilo.PAPEL
	estilo_globo.border_color = Estilo.TINTA
	estilo_globo.set_border_width_all(3)
	estilo_globo.set_corner_radius_all(18)
	estilo_globo.content_margin_left = 26
	estilo_globo.content_margin_right = 26
	estilo_globo.content_margin_top = 14
	estilo_globo.content_margin_bottom = 16
	_globo.add_theme_stylebox_override("panel", estilo_globo)
	_globo.anchor_left = 0.25
	_globo.anchor_right = 0.75
	_globo.offset_top = 30
	_globo.visible = false
	add_child(_globo)
	var columna := VBoxContainer.new()
	_globo.add_child(columna)
	columna.add_child(Estilo.etiqueta("La Xaca Rana (el profe)"))
	_texto_globo = Estilo.nota("", 30, Estilo.TINTA)
	_texto_globo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(_texto_globo)

	var saltar := Estilo.boton("Saltar  »", _terminar, 150)
	saltar.anchor_left = 1.0
	saltar.anchor_right = 1.0
	saltar.offset_left = -190
	saltar.offset_right = -40
	saltar.offset_top = 30
	saltar.offset_bottom = 88
	saltar.name = "Saltar"
	add_child(saltar)


func _decir(texto: String) -> void:
	_texto_subtitulo.text = texto
	_texto_subtitulo.visible_ratio = 0.0
	var t := create_tween()
	t.tween_property(_subtitulo, "modulate:a", 1.0, 0.2)
	t.parallel().tween_property(_texto_subtitulo, "visible_ratio", 1.0, texto.length() * 0.035)


func _hablar(texto: String) -> void:
	_globo.visible = true
	_texto_globo.text = texto
	_texto_globo.visible_ratio = 0.0
	create_tween().tween_property(_texto_globo, "visible_ratio", 1.0, texto.length() * 0.035)


func _croar() -> void:
	Audio.efecto("rana")
	_croac.visible = true
	_croac.scale = Vector3.ONE * 0.2
	create_tween().tween_property(_croac, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var salto := _profe.create_tween().set_loops(2)
	salto.tween_property(_profe, "position:y", 0.25, 0.16).set_ease(Tween.EASE_OUT)
	salto.tween_property(_profe, "position:y", 0.0, 0.16).set_ease(Tween.EASE_IN)
	var t := create_tween()
	t.tween_interval(1.6)
	t.tween_callback(func(): _croac.visible = false)


func _mover_camara(desde: Vector3, mirar_desde: Vector3, hasta: Vector3, mirar_hasta: Vector3, segundos: float) -> void:
	var t := create_tween()
	t.tween_method(func(k: float):
		_camara.position = desde.lerp(hasta, k)
		_camara.look_at(mirar_desde.lerp(mirar_hasta, k), Vector3.UP), 0.0, 1.0, segundos).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ---------- Eventos ----------

func _toma_salon() -> void:
	_mover_camara(Vector3(-2.5, 3.2, 6.5), Vector3(0, 1.4, -2.5), Vector3(-1.6, 2.6, 4.2), Vector3(0.2, 1.4, -2.5), 3.6)


func _repartir() -> void:
	_hablar("«Tienen dos horas. Nada de copiar... ¡Croac! Pueden empezar.»")
	_croar()
	_hoja.visible = true
	_hoja.scale = Vector3.ONE * 0.1
	create_tween().tween_property(_hoja, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK)


func _escribir() -> void:
	_globo.visible = false
	_decir("Con todos tus apuntes repasados, las respuestas salen solas...")
	_lapiz.visible = true
	_escribiendo = true
	_mover_camara(_camara.position, Vector3(0.2, 1.4, -2.5), Vector3(0.1, 1.5, -0.5), Vector3(-1.0, 0.95, 0.6), 1.2)
	# El reloj de la pared avanza rápido: de 8:00 a 9:45.
	var t := create_tween()
	t.tween_method(func(m: int): _reloj.text = "%d:%02d" % [8 + m / 60, m % 60], 0, 105, 3.8)


func _entregar() -> void:
	_escribiendo = false
	_lapiz.visible = false
	_decir("¡Listo! A entregarlo.")
	_mover_camara(_camara.position, Vector3(-1.0, 0.95, 0.6), Vector3(-2.6, 2.2, 2.4), Vector3(0.6, 1.2, -1.6), 1.0)
	# Se levanta, camina al escritorio y deja la hoja.
	var t := create_tween()
	t.tween_property(_estudiante, "position:y", 0.0, 0.25)
	t.tween_property(_estudiante, "position", Vector3(0.2, 0, -0.9), 1.4).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(_hoja, "position", Vector3(0.2, 1.1, -0.65), 1.4).set_trans(Tween.TRANS_SINE)
	t.tween_property(_hoja, "position", Vector3(1.0, 0.93, -1.8), 0.5)
	t.parallel().tween_property(_hoja, "rotation:y", 0.4, 0.5)


func _revisar() -> void:
	_subtitulo.modulate.a = 0.0
	_hablar("«Mmm... a ver, a ver...»")
	_mover_camara(_camara.position, Vector3(0.6, 1.2, -1.6), Vector3(1.2, 2.1, 0.4), Vector3(1.4, 1.8, -2.5), 1.2)
	var t := create_tween().set_loops(3)
	t.tween_callback(func(): Audio.efecto("clic", 0.7))
	t.tween_property(_profe, "rotation:y", 0.15, 0.4)
	t.tween_property(_profe, "rotation:y", -0.15, 0.4)


## La nota cae como un sello sobre la pantalla, con el detalle de dónde sale.
func _calificar() -> void:
	_croar()
	_hablar("«¡Croac! Aprobado.»" if _nota >= 3.0 else "«Croac... nos vemos en la habilitación.»")
	Audio.efecto("victoria" if _nota >= 3.0 else "derrota")
	var capa := Control.new()
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(capa)
	var sello := SelloGrande.new()
	sello.nota = _nota
	sello.size = Vector2(260, 260)
	sello.position = get_viewport().get_visible_rect().size / 2.0 - Vector2(130, 170)
	sello.pivot_offset = Vector2(130, 130)
	sello.rotation_degrees = -14
	sello.scale = Vector2.ONE * 3.0
	sello.modulate.a = 0.0
	capa.add_child(sello)
	var t := create_tween().set_parallel()
	t.tween_property(sello, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(sello, "modulate:a", 1.0, 0.15)
	var vidas := mini(Partida.vidas, Partida.VIDAS_MAXIMAS)
	var porcentaje := 0 if Partida.tiempo_total <= 0.0 else roundi(Partida.tiempo_sobrante / Partida.tiempo_total * 100.0)
	_decir("%s  Vidas %d · Ranas %d/%d · Tiempo extra %d %%" % [
		"¡Pasaste!" if _nota >= 3.0 else "Te fue mal...", vidas,
		Partida.ranas_partida.size(), Partida.HUEVOS_TOTALES, porcentaje])


func _terminar() -> void:
	if _terminado:
		return
	_terminado = true
	Partida.registrar_resultado(true, "parcial", _nota)
	Transicion.ir(ESCENA_SIGUIENTE)


class SelloGrande extends Control:
	## La nota escrita en un sello circular, verde si pasó y rojo si no.
	var nota := 0.0

	func _draw() -> void:
		var color := Estilo.VERDE if nota >= 3.0 else Estilo.ESFERO
		var c := size / 2
		var r := minf(size.x, size.y) / 2 - 6
		draw_circle(c, r, Color(Estilo.PAPEL, 0.92))
		draw_arc(c, r, 0, TAU, 64, color, 10.0, true)
		draw_arc(c, r - 18, 0, TAU, 64, color, 3.0, true)
		var texto := "%.1f" % nota
		var tam := 110
		var ancho := Estilo.fuente_titulo.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		draw_string(Estilo.fuente_titulo, Vector2(c.x - ancho / 2, c.y + tam * 0.36), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, color)
