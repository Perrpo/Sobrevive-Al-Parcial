extends Control
## La historia (lore) que se ve al empezar una partida nueva. Es una animación de ~30 s:
##   1. La tarde antes del parcial: el estudiante se queda dormido estudiando.
##   2. Suena la alarma a las 5:00 p. m.
##   3. Una ventisca abre la ventana y se lleva todos los apuntes.
##   4. Mapa de la universidad: los apuntes quedaron regados en 5 lugares.
##   5. En el salón, la Xaca Rana (el profe) advierte sobre el parcial y las 3 ranas.
##
## Funciona como una línea de tiempo: en _process se avanza un reloj y cuando
## llega la hora de cada evento se llama su función (que arranca tweens y textos).
## Se puede saltar con el botón "Saltar" o con Esc.

const ESCENA_SIGUIENTE := "res://escenas/Juego.tscn"
const SALON := Vector3(40, 0, 0)  # el salón está lejos del cuarto, en el mismo mundo 3D

var _tiempo := 0.0
var _i_evento := 0
var _eventos: Array = []
var _terminado := false

var _camara: Camera3D
var _estudiante: Node3D
var _zzz: Label3D
var _reloj: Label3D
var _hojas: Array[Node3D] = []
var _postigos: Array[Node3D] = []
var _cortinas: Array[Node3D] = []
var _rana: Node3D
var _croac: Label3D

var _subtitulo: PanelContainer
var _texto_subtitulo: Label
var _globo: PanelContainer
var _texto_globo: Label
var _mapa: MapaHistoria
var _cierre: ColorRect


func _ready() -> void:
	var vista := SubViewportContainer.new()
	vista.stretch = true
	vista.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vista)
	var viewport := SubViewport.new()
	viewport.msaa_3d = Viewport.MSAA_4X
	vista.add_child(viewport)
	var mundo := Node3D.new()
	viewport.add_child(mundo)
	_crear_ambiente(mundo)
	_crear_cuarto(mundo)
	_crear_salon(mundo)
	_camara = Camera3D.new()
	_camara.fov = 50
	mundo.add_child(_camara)

	_crear_interfaz()

	_eventos = [
		[0.0, _toma_cuarto],
		[0.4, func(): _decir("La tarde antes del parcial final de Aplicaciones Móviles...")],
		[3.8, func(): _decir("...te quedaste dormido encima del cuaderno.")],
		[6.8, _alarma],
		[9.4, _ventisca],
		[13.6, _toma_mapa],
		[17.6, func(): _decir("Esta noche: biblioteca, bulevar e ingeniería. Mañana temprano: parqueadero y el pasillo del salón.")],
		[21.6, _toma_salon],
		[26.6, _hablar_de_ranas],
		[28.4, _croar],
		[32.4, _titulo_final],
		[35.4, _terminar],
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
	if _zzz and _zzz.visible:
		_zzz.position.y = 1.9 + fmod(_tiempo * 0.4, 0.5)
		_zzz.modulate.a = 1.0 - fmod(_tiempo * 0.4, 0.5) * 2.0


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("pausa"):
		_terminar()


# ---------- Escenarios 3D ----------

func _crear_ambiente(mundo: Node3D) -> void:
	var entorno := WorldEnvironment.new()
	entorno.environment = Environment.new()
	entorno.environment.background_mode = Environment.BG_COLOR
	entorno.environment.background_color = Color("#0B1222")
	entorno.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.environment.ambient_light_color = Color("#A396B8")
	entorno.environment.ambient_light_energy = 0.6
	entorno.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	mundo.add_child(entorno)


## Hoja de cuaderno simple (sin luz propia, para poder tener muchas).
func _hoja_papel() -> Node3D:
	var n := Node3D.new()
	n.add_child(Constructor.caja(Vector3(0.3, 0.012, 0.4), Color("#FFFFFF")))
	for i in 4:
		n.add_child(Constructor.caja(Vector3(0.22, 0.014, 0.018), Color("#4078C4"), Vector3(0, 0.001, -0.12 + i * 0.07)))
	return n


func _crear_cuarto(mundo: Node3D) -> void:
	mundo.add_child(Constructor.caja(Vector3(9, 0.1, 9), Color("#7A5A3E"), Vector3(0, -0.05, 0)))
	_crear_ventana(mundo)
	mundo.add_child(Constructor.caja(Vector3(0.2, 4, 9), Color("#B89C84"), Vector3(-3.2, 2, 0)))
	mundo.add_child(Constructor.caja(Vector3(0.2, 4, 9), Color("#B89C84"), Vector3(4.5, 2, 1.8)))

	# Escritorio, lámpara, silla y reloj.
	var escritorio := Constructor.mesa(Color("#9C7A54"))
	escritorio.position = Vector3(0, 0, -1.6)
	mundo.add_child(escritorio)
	mundo.add_child(Constructor.cilindro(0.12, 0.14, 0.04, Color("#222222"), Vector3(0.7, 0.93, -1.95)))
	mundo.add_child(Constructor.cilindro(0.02, 0.02, 0.5, Color("#222222"), Vector3(0.7, 1.16, -1.95)))
	mundo.add_child(Constructor.cilindro(0.06, 0.2, 0.18, Color("#E0A458"), Vector3(0.6, 1.4, -1.85)))
	var luz_lampara := OmniLight3D.new()
	luz_lampara.light_color = Color("#FFC56E")
	luz_lampara.light_energy = 2.2
	luz_lampara.omni_range = 4.5
	luz_lampara.position = Vector3(0.5, 1.3, -1.7)
	luz_lampara.shadow_enabled = true
	mundo.add_child(luz_lampara)
	var silla := Constructor.silla(Color("#6B4632"))
	silla.position = Vector3(-0.1, 0, -0.45)
	silla.rotation.y = PI
	mundo.add_child(silla)
	mundo.add_child(Constructor.caja(Vector3(0.3, 0.2, 0.1), Color("#1B1B1B"), Vector3(-0.65, 1.0, -1.85)))
	_reloj = Label3D.new()
	_reloj.text = "4:59"
	_reloj.font = Estilo.fuente_negrita
	_reloj.font_size = 40
	_reloj.pixel_size = 0.003
	_reloj.modulate = Color("#7CFF9A")
	_reloj.position = Vector3(-0.65, 1.0, -1.79)
	mundo.add_child(_reloj)

	# Apuntes regados en el escritorio.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for i in 12:
		var hoja := _hoja_papel()
		hoja.position = Vector3(rng.randf_range(-0.75, 0.35), 0.92 + i * 0.004, rng.randf_range(-1.95, -1.3))
		hoja.rotation.y = rng.randf_range(-0.8, 0.8)
		mundo.add_child(hoja)
		_hojas.append(hoja)

	# El estudiante dormido sobre el escritorio.
	_estudiante = Constructor.estudiante()
	_estudiante.position = Vector3(-0.1, -0.3, -0.75)
	_estudiante.rotation = Vector3(-0.55, PI, 0)
	mundo.add_child(_estudiante)
	_zzz = Label3D.new()
	_zzz.text = "Z z z"
	_zzz.font = Estilo.fuente_mano
	_zzz.font_size = 64
	_zzz.pixel_size = 0.006
	_zzz.modulate = Estilo.PANTALLA_TEXTO
	_zzz.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_zzz.position = Vector3(0.1, 1.9, -0.9)
	mundo.add_child(_zzz)


## Pared del fondo con una ventana de verdad: hueco en la pared, marco, alféizar, dos hojas
## de vidrio que se abren hacia adentro, cortinas, y afuera el atardecer con la ciudad.
func _crear_ventana(mundo: Node3D) -> void:
	var centro := Vector3(1.4, 1.9, -2.6)
	var ancho := 1.7
	var alto := 1.4
	var pared := Color("#CDB49A")
	var izq := centro.x - ancho / 2.0
	var der := centro.x + ancho / 2.0
	var abajo := centro.y - alto / 2.0
	var arriba := centro.y + alto / 2.0
	# La pared se arma con 4 pedazos alrededor del hueco.
	mundo.add_child(Constructor.caja(Vector3(izq + 4.5, 4, 0.2), pared, Vector3((izq - 4.5) / 2.0, 2, centro.z)))
	mundo.add_child(Constructor.caja(Vector3(4.5 - der, 4, 0.2), pared, Vector3((der + 4.5) / 2.0, 2, centro.z)))
	mundo.add_child(Constructor.caja(Vector3(ancho, abajo, 0.2), pared, Vector3(centro.x, abajo / 2.0, centro.z)))
	mundo.add_child(Constructor.caja(Vector3(ancho, 4 - arriba, 0.2), pared, Vector3(centro.x, (arriba + 4) / 2.0, centro.z)))

	# Afuera: cielo de atardecer por franjas, el sol bajando y edificios de la ciudad.
	var franjas := [Color("#FFB067"), Color("#FF8F66"), Color("#EE6F7C"), Color("#A65E9E"), Color("#4E4C8E"), Color("#2E3570")]
	for k in franjas.size():
		mundo.add_child(Constructor.caja(Vector3(24, 1.3, 0.1), franjas[k], Vector3(1.4, 0.2 + k * 1.25, -10), 1.0))
	mundo.add_child(Constructor.esfera(0.8, Color("#FFE9A8"), Vector3(2.4, 1.2, -9.7), 3.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var x := -3.0
	while x < 6.5:
		var w := rng.randf_range(0.6, 1.3)
		var h := rng.randf_range(0.8, 2.6)
		mundo.add_child(Constructor.caja(Vector3(w, h, 0.6), Color("#3A2D4F"), Vector3(x, h / 2.0, -8.0)))
		for v in rng.randi_range(1, 4):
			mundo.add_child(Constructor.caja(Vector3(0.12, 0.12, 0.02), Color("#FFD27A"), Vector3(x + rng.randf_range(-w / 3, w / 3), rng.randf_range(0.3, h - 0.2), -7.69), 1.5))
		x += w + rng.randf_range(0.05, 0.3)
	mundo.add_child(Constructor.caja(Vector3(24, 0.2, 8), Color("#4A3B57"), Vector3(1.4, -0.1, -7)))

	# Marco blanco, alféizar y la cruz del medio.
	var marco := Color("#F4F1EA")
	for lado in [-1, 1]:
		mundo.add_child(Constructor.caja(Vector3(0.1, alto + 0.2, 0.3), marco, Vector3(centro.x + (ancho / 2.0 + 0.05) * lado, centro.y, centro.z + 0.05)))
	mundo.add_child(Constructor.caja(Vector3(ancho + 0.3, 0.1, 0.3), marco, Vector3(centro.x, arriba + 0.05, centro.z + 0.05)))
	mundo.add_child(Constructor.caja(Vector3(ancho + 0.5, 0.07, 0.45), marco, Vector3(centro.x, abajo - 0.03, centro.z + 0.2)))  # alféizar

	# Dos hojas de vidrio con bisagra en los lados: se abren hacia adentro con la ventisca.
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.75, 0.88, 1.0, 0.22)
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.metallic_specular = 1.0
	vidrio.roughness = 0.05
	for lado in [-1, 1]:
		var bisagra := Node3D.new()
		bisagra.position = Vector3(centro.x + ancho / 2.0 * lado, centro.y, centro.z + 0.12)
		var mitad := ancho / 2.0
		var hoja := Node3D.new()
		hoja.position = Vector3(-mitad / 2.0 * lado, 0, 0)
		bisagra.add_child(hoja)
		var cristal := Constructor.caja(Vector3(mitad - 0.06, alto - 0.06, 0.02), Color.WHITE)
		cristal.material_override = vidrio
		hoja.add_child(cristal)
		for borde in [[Vector3(mitad, 0.06, 0.05), Vector3(0, alto / 2.0 - 0.03, 0)], [Vector3(mitad, 0.06, 0.05), Vector3(0, -alto / 2.0 + 0.03, 0)],
				[Vector3(0.06, alto, 0.05), Vector3(mitad / 2.0 - 0.03, 0, 0)], [Vector3(0.06, alto, 0.05), Vector3(-mitad / 2.0 + 0.03, 0, 0)],
				[Vector3(mitad, 0.04, 0.04), Vector3.ZERO]]:
			hoja.add_child(Constructor.caja(borde[0], marco, borde[1]))
		hoja.add_child(Constructor.esfera(0.035, Color("#C9A227"), Vector3(mitad / 2.0 * lado - 0.08 * lado, -0.05, 0.04)))  # manija
		mundo.add_child(bisagra)
		_postigos.append(bisagra)

	# Cortinas con pliegues, colgadas de un tubo; se mueven con el viento.
	var tubo := Constructor.cilindro(0.025, 0.025, ancho + 1.4, Color("#5A4636"), Vector3(centro.x, arriba + 0.25, centro.z + 0.3))
	tubo.rotation.z = PI / 2
	mundo.add_child(tubo)
	for lado in [-1, 1]:
		var cortina := Node3D.new()
		cortina.position = Vector3(centro.x + (ancho / 2.0 + 0.35) * lado, arriba + 0.25, centro.z + 0.3)
		for k in 5:
			var pliegue := Constructor.caja(Vector3(0.12, 2.1, 0.05), Color("#B5473F") if k % 2 == 0 else Color("#C95A50"), Vector3((k - 2) * 0.1, -1.05, (k % 2) * 0.05))
			cortina.add_child(pliegue)
		mundo.add_child(cortina)
		_cortinas.append(cortina)

	# Luz naranja del atardecer que entra por la ventana y pinta el cuarto.
	var sol := SpotLight3D.new()
	sol.light_color = Color("#FFAE6B")
	sol.light_energy = 6.0
	sol.spot_range = 12.0
	sol.spot_angle = 28.0
	sol.shadow_enabled = true
	sol.position = Vector3(2.2, 2.8, -6.0)
	mundo.add_child(sol)
	sol.look_at(Vector3(0.2, 0.6, -0.4), Vector3.UP)


func _crear_salon(mundo: Node3D) -> void:
	var o := SALON
	mundo.add_child(Constructor.caja(Vector3(10, 0.1, 10), Color("#B9BFC7"), o + Vector3(0, -0.05, 0)))
	mundo.add_child(Constructor.caja(Vector3(10, 4, 0.2), Color("#E9E6E0"), o + Vector3(0, 2, -3.2)))
	mundo.add_child(Constructor.caja(Vector3(3.8, 1.7, 0.06), Color("#2F4F3A"), o + Vector3(0, 2.0, -3.06)))
	var tablero := Label3D.new()
	tablero.text = "PARCIAL FINAL\nmañana 8:00 a. m."
	tablero.font = Estilo.fuente_mano
	tablero.font_size = 72
	tablero.pixel_size = 0.006
	tablero.modulate = Color("#F4F4EC")
	tablero.position = o + Vector3(-0.75, 2.15, -3.02)
	mundo.add_child(tablero)

	var escritorio := Constructor.mesa(Color("#8C6A48"))
	escritorio.position = o + Vector3(0, 0, -1.6)
	mundo.add_child(escritorio)
	# El profe es la Xaca Rana.
	_rana = Constructor.profe_rana()
	_rana.position = o + Vector3(1.45, 0, -2.35)
	mundo.add_child(_rana)
	_croac = Label3D.new()
	_croac.text = "¡Croac!"
	_croac.font = Estilo.fuente_titulo
	_croac.font_size = 64
	_croac.pixel_size = 0.005
	_croac.modulate = Color("#6BE38F")
	_croac.outline_size = 14
	_croac.outline_modulate = Estilo.PANTALLA
	_croac.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_croac.position = o + Vector3(0.6, 2.75, -2.0)
	_croac.visible = false
	mundo.add_child(_croac)
	for fila in 2:
		for col in 3:
			var p := Constructor.pupitre()
			p.position = o + Vector3(-2.2 + col * 2.2, 0, 0.6 + fila * 1.8)
			p.rotation.y = PI
			mundo.add_child(p)
	var luz := OmniLight3D.new()
	luz.light_color = Color("#FFF4E0")
	luz.light_energy = 2.5
	luz.omni_range = 9
	luz.position = o + Vector3(0, 3.6, 0)
	mundo.add_child(luz)


# ---------- Interfaz encima de la animación ----------

func _crear_interfaz() -> void:
	_mapa = MapaHistoria.new()
	_mapa.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mapa.modulate.a = 0.0
	_mapa.visible = false
	add_child(_mapa)

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

	# Globo de diálogo del profe.
	_globo = PanelContainer.new()
	var estilo_globo := StyleBoxFlat.new()
	estilo_globo.bg_color = Estilo.PAPEL
	estilo_globo.border_color = Estilo.TINTA
	estilo_globo.set_border_width_all(3)
	estilo_globo.set_corner_radius_all(18)
	estilo_globo.shadow_color = Color(0, 0, 0, 0.4)
	estilo_globo.shadow_offset = Vector2(6, 7)
	estilo_globo.content_margin_left = 26
	estilo_globo.content_margin_right = 26
	estilo_globo.content_margin_top = 14
	estilo_globo.content_margin_bottom = 16
	_globo.add_theme_stylebox_override("panel", estilo_globo)
	_globo.anchor_left = 0.15
	_globo.anchor_right = 0.85
	_globo.anchor_top = 1.0
	_globo.anchor_bottom = 1.0
	_globo.offset_top = -150
	_globo.offset_bottom = -30
	_globo.visible = false
	add_child(_globo)
	var columna := VBoxContainer.new()
	_globo.add_child(columna)
	columna.add_child(Estilo.etiqueta("La Xaca Rana (el profe)"))
	_texto_globo = Estilo.nota("", 30, Estilo.TINTA)
	_texto_globo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(_texto_globo)

	_cierre = ColorRect.new()
	_cierre.color = Estilo.PANTALLA
	_cierre.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cierre.modulate.a = 0.0
	_cierre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cierre)

	var saltar := Estilo.boton("Saltar  »", _terminar, 150)
	saltar.anchor_left = 1.0
	saltar.anchor_right = 1.0
	saltar.offset_left = -190
	saltar.offset_right = -40
	saltar.offset_top = 30
	saltar.offset_bottom = 88
	saltar.name = "Saltar"
	add_child(saltar)


## Muestra un subtítulo con efecto de máquina de escribir.
func _decir(texto: String) -> void:
	_subtitulo.visible = true
	_texto_subtitulo.text = texto
	_texto_subtitulo.visible_ratio = 0.0
	var t := create_tween()
	t.tween_property(_subtitulo, "modulate:a", 1.0, 0.2)
	t.parallel().tween_property(_texto_subtitulo, "visible_ratio", 1.0, texto.length() * 0.035)


func _mover_camara(desde: Vector3, mirar_desde: Vector3, hasta: Vector3, mirar_hasta: Vector3, segundos: float) -> void:
	var t := create_tween()
	t.tween_method(func(k: float):
		_camara.position = desde.lerp(hasta, k)
		_camara.look_at(mirar_desde.lerp(mirar_hasta, k), Vector3.UP), 0.0, 1.0, segundos).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ---------- Eventos de la línea de tiempo ----------

func _toma_cuarto() -> void:
	_mover_camara(Vector3(2.8, 2.1, 1.9), Vector3(0, 1.0, -1.3), Vector3(1.7, 1.6, 0.9), Vector3(0, 1.0, -1.4), 6.6)


func _alarma() -> void:
	_zzz.visible = false
	_reloj.text = "5:00"
	_reloj.modulate = Color("#FF4D57")
	var parpadeo := _reloj.create_tween().set_loops(6)
	parpadeo.tween_property(_reloj, "visible", false, 0.15)
	parpadeo.tween_property(_reloj, "visible", true, 0.15)
	Audio.efecto("timbre")
	# Se despierta de un brinco.
	var t := create_tween()
	t.tween_property(_estudiante, "rotation:x", 0.15, 0.18).set_trans(Tween.TRANS_BACK)
	t.parallel().tween_property(_estudiante, "position:y", 0.15, 0.18)
	t.tween_property(_estudiante, "position:y", -0.3, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_estudiante, "rotation:x", 0.0, 0.25)
	_decir("¡5:00 p. m.! ¡Y el parcial es mañana a las 8:00 a. m.!")
	_mover_camara(_camara.position, Vector3(0, 1.0, -1.4), Vector3(-2.2, 1.5, -0.7), Vector3(-0.1, 1.1, -1.0), 0.6)


func _ventisca() -> void:
	Audio.efecto("puerta", 0.8)
	Audio.efecto("shh", 0.55, 3.0)
	_decir("Y justo entró una ventisca que se llevó TODOS tus apuntes...")
	for cortina in _cortinas:
		var vaiven := cortina.create_tween().set_loops(5)
		vaiven.tween_property(cortina, "rotation:x", 0.75, 0.25).set_trans(Tween.TRANS_SINE)
		vaiven.tween_property(cortina, "rotation:x", 0.2, 0.3).set_trans(Tween.TRANS_SINE)
	for i in _postigos.size():
		var lado := -1.0 if i == 0 else 1.0
		var t := _postigos[i].create_tween()
		t.tween_property(_postigos[i], "rotation:y", lado * 1.9, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_mover_camara(_camara.position, Vector3(-0.1, 1.1, -1.0), Vector3(2.4, 1.7, 1.5), Vector3(0.8, 1.5, -2.0), 1.0)
	# Cada hoja sale volando en espiral hacia la ventana y desaparece afuera.
	var rng := RandomNumberGenerator.new()
	for i in _hojas.size():
		var hoja := _hojas[i]
		var inicio := hoja.position
		var ventana := Vector3(1.4 + rng.randf_range(-0.45, 0.45), 1.9 + rng.randf_range(-0.35, 0.35), -2.6)
		var afuera := Vector3(ventana.x + rng.randf_range(-2.0, 2.0), ventana.y + rng.randf_range(0.5, 2.0), -7.0)
		var giros := rng.randf_range(2.0, 4.0)
		var t := hoja.create_tween()
		t.tween_interval(0.25 + i * 0.12)
		t.tween_method(func(k: float):
			var p := inicio.lerp(ventana, k)
			p += Vector3(sin(k * TAU * 1.3), cos(k * TAU), 0) * 0.35 * sin(k * PI)
			hoja.position = p
			hoja.rotation = Vector3(k * giros * TAU, k * giros * 2.0, k * giros * PI), 0.0, 1.0, 1.1)
		t.tween_property(hoja, "position", afuera, 0.8)
	# La cámara tiembla un poco con el viento.
	var temblor := create_tween()
	for k in 8:
		temblor.tween_property(_camara, "h_offset", rng.randf_range(-0.04, 0.04), 0.05)
	temblor.tween_property(_camara, "h_offset", 0.0, 0.05)


func _toma_mapa() -> void:
	_decir("...y los regó por toda la universidad.")
	_mapa.visible = true
	_mapa.avance = 0.0
	var t := create_tween()
	t.tween_property(_mapa, "modulate:a", 1.0, 0.4)
	t.tween_property(_mapa, "avance", 1.0, 6.5).set_trans(Tween.TRANS_SINE)


func _toma_salon() -> void:
	var t := create_tween()
	t.tween_property(_mapa, "modulate:a", 0.0, 0.3)
	t.parallel().tween_property(_subtitulo, "modulate:a", 0.0, 0.3)
	t.tween_callback(func(): _mapa.visible = false)
	_mover_camara(SALON + Vector3(0.6, 2.2, 3.2), SALON + Vector3(0, 1.4, -1.8), SALON + Vector3(0.2, 1.9, 1.9), SALON + Vector3(0, 1.5, -2.0), 7.0)
	var frase := "«El parcial es mañana a las 8:00 a. m. Sin apuntes no hay parcial... y nada de correr: los vigilantes oyen todo.»"
	_globo.visible = true
	_texto_globo.text = frase
	_texto_globo.visible_ratio = 0.0
	_globo.scale = Vector2(0.8, 0.8)
	_globo.pivot_offset = Vector2(_globo.size.x / 2, _globo.size.y)
	var tg := create_tween()
	tg.tween_property(_globo, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tg.tween_property(_texto_globo, "visible_ratio", 1.0, frase.length() * 0.035)


func _hablar_de_ranas() -> void:
	var frase := "«Ah... y escondí 3 ranas por la U. El que las encuentre tendrá mi poder.»"
	_texto_globo.text = frase
	_texto_globo.visible_ratio = 0.0
	create_tween().tween_property(_texto_globo, "visible_ratio", 1.0, frase.length() * 0.035)
	_mover_camara(_camara.position, SALON + Vector3(0, 1.5, -2.0), SALON + Vector3(1.2, 2.0, 0.2), SALON + Vector3(1.45, 1.9, -2.3), 1.2)


func _croar() -> void:
	Audio.efecto("rana")
	_croac.visible = true
	_croac.scale = Vector3.ONE * 0.2
	var t := create_tween()
	t.tween_property(_croac, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var salto := _rana.create_tween().set_loops(2)
	var base := _rana.position.y
	salto.tween_property(_rana, "position:y", base + 0.3, 0.18).set_ease(Tween.EASE_OUT)
	salto.tween_property(_rana, "position:y", base, 0.18).set_ease(Tween.EASE_IN)


func _titulo_final() -> void:
	_globo.visible = false
	var t := create_tween()
	t.tween_property(_cierre, "modulate:a", 1.0, 0.5)
	var columna := VBoxContainer.new()
	columna.set_anchors_preset(Control.PRESET_CENTER)
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 6)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	centro.add_child(columna)
	var titulo := Estilo.titulo("Sobrevive al *Parcial*", 80, Estilo.PANTALLA_TEXTO)
	var caja := CenterContainer.new()
	caja.add_child(titulo)
	columna.add_child(caja)
	var sub := Estilo.nota("Nivel 1 · Biblioteca · 6:00 p. m.", 30, Estilo.RESALTADOR)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(sub)
	columna.modulate.a = 0.0
	t.tween_property(columna, "modulate:a", 1.0, 0.5)
	Audio.efecto("timbre", 1.0, -4.0)


func _terminar() -> void:
	if _terminado:
		return
	_terminado = true
	Transicion.ir(ESCENA_SIGUIENTE)


## El mapa de la universidad dibujado en una hoja: un camino punteado rojo
## va pasando por los lugares y en cada uno caen apuntes.
class MapaHistoria extends Control:
	var avance := 0.0:
		set(v):
			avance = v
			queue_redraw()

	const LUGARES := [
		["Biblioteca", "6:00 p. m.", Vector2(0.11, 0.66)],
		["Bulevar", "7:30 p. m.", Vector2(0.3, 0.32)],
		["Bloque de Ingeniería", "10:00 p. m.", Vector2(0.49, 0.7)],
		["Parqueadero", "mañana 7:00 a. m.", Vector2(0.68, 0.34)],
		["Salón 304: ¡PARCIAL!", "8:00 a. m.", Vector2(0.86, 0.68)],
	]

	func _draw() -> void:
		var hoja := Rect2(size * Vector2(0.08, 0.08), size * Vector2(0.84, 0.66))
		draw_rect(Rect2(hoja.position + Vector2(8, 10), hoja.size), Color(0, 0, 0, 0.35))
		draw_rect(hoja, Estilo.PAPEL)
		var paso := 28.0
		var x := hoja.position.x
		while x < hoja.end.x:
			draw_line(Vector2(x, hoja.position.y), Vector2(x, hoja.end.y), Estilo.CUADRICULA, 1.0)
			x += paso
		var y := hoja.position.y
		while y < hoja.end.y:
			draw_line(Vector2(hoja.position.x, y), Vector2(hoja.end.x, y), Estilo.CUADRICULA, 1.0)
			y += paso
		draw_rect(hoja, Estilo.TINTA, false, 3.0)
		draw_string(Estilo.fuente_titulo, hoja.position + Vector2(24, 52), "Mapa de la U", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Estilo.TINTA)

		var puntos: Array[Vector2] = []
		for l in LUGARES:
			puntos.append(hoja.position + hoja.size * (l[2] as Vector2))
		# Camino punteado hasta donde vaya el avance.
		var tramos := puntos.size() - 1
		var hasta := avance * tramos
		for i in tramos:
			var a := puntos[i]
			var b := puntos[i + 1]
			var parte := clampf(hasta - i, 0.0, 1.0)
			if parte <= 0.0:
				break
			var fin := a.lerp(b, parte)
			var largo := a.distance_to(fin)
			var d := 0.0
			while d < largo:
				draw_line(a.move_toward(fin, d), a.move_toward(fin, minf(d + 10.0, largo)), Estilo.ESFERO, 4.0, true)
				d += 18.0
		# Lugares: aparecen cuando el camino llega, con apuntes que caen.
		for i in puntos.size():
			var llegada := clampf((hasta - i + 0.35) * 2.0, 0.0, 1.0)
			if i == 0:
				llegada = clampf(avance * 8.0, 0.0, 1.0)
			if llegada <= 0.0:
				continue
			var p := puntos[i]
			var color := Estilo.ESFERO if i == puntos.size() - 1 else Estilo.TINTA
			draw_circle(p, 16.0 * llegada, color)
			draw_circle(p, 7.0 * llegada, Estilo.RESALTADOR)
			var nombre: String = LUGARES[i][0]
			var hora: String = LUGARES[i][1]
			var alfa := Color(1, 1, 1, llegada)
			draw_string(Estilo.fuente_negrita, p + Vector2(-140, 46), nombre, HORIZONTAL_ALIGNMENT_CENTER, 280, 22, Estilo.TINTA * alfa)
			draw_string(Estilo.fuente_mano, p + Vector2(-140, 72), hora, HORIZONTAL_ALIGNMENT_CENTER, 280, 22, Estilo.ESFERO * alfa)
			if i < puntos.size() - 1:
				# Tres hojitas que caen girando junto al lugar.
				for k in 3:
					var caida := clampf(llegada * 1.3 - k * 0.15, 0.0, 1.0)
					var pos := p + Vector2(-34 + k * 26, -70 + 60 * caida)
					draw_set_transform(pos, (1.0 - caida) * 3.0 + k * 0.4, Vector2.ONE)
					draw_rect(Rect2(-8, -10, 16, 20), Color(1, 1, 1, caida))
					draw_rect(Rect2(-8, -10, 16, 20), Color(Estilo.TINTA, caida * 0.8), false, 1.5)
					draw_set_transform(Vector2.ZERO)
