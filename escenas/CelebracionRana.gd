class_name CelebracionRana
extends CanvasLayer
## Animación que sale al juntar las 3 Xaca Ranas en una partida: el estudiante se
## transforma en rana y gana el poder de la Xaca Rana para el resto del juego.
## Partida.encontrar_rana() la crea sola con la tercera rana.
## Mientras se ve, el juego queda en pausa.

const MOMENTO_TRANSFORMACION := 1.6
const SECRETOS := [
	["Rana de la biblioteca", "entre los estantes"],
	["Rana del bulevar", "junto a las jardineras"],
	["Rana de ingeniería", "detrás de la puerta con código"],
]

var _pausa_anterior := false
var _boton: Button
var _rana: Node3D
var _estudiante: Node3D
var _escena_3d: Node3D
var _transformado := false
var _confeti: CPUParticles2D
var _rayos: Rayos
var _tiempo := 0.0


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pausa_anterior = get_tree().paused
	get_tree().paused = true

	var raiz := Control.new()
	raiz.theme = Estilo.tema
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(raiz)

	var velo := ColorRect.new()
	velo.color = Color(Estilo.PANTALLA, 0.0)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_child(velo)
	create_tween().tween_property(velo, "color:a", 0.88, 0.4)

	_rayos = Rayos.new()
	_rayos.anchor_right = 0.5
	_rayos.anchor_bottom = 1.0
	_rayos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(_rayos)

	_crear_rana_3d(raiz)
	_crear_confeti(raiz)

	# Columna de texto a la derecha.
	var columna := VBoxContainer.new()
	columna.anchor_left = 0.5
	columna.anchor_right = 1.0
	columna.anchor_bottom = 1.0
	columna.offset_right = -60
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 12)
	raiz.add_child(columna)
	columna.add_child(Estilo.etiqueta("¡Juntaste las 3 Xaca Ranas!", Estilo.RESALTADOR))
	var titulo := Estilo.titulo("¡Eres *rana*!", 76, Estilo.PANTALLA_TEXTO)
	columna.add_child(titulo)
	columna.add_child(Estilo.nota("La Xaca Rana te dio su poder", 28, Color("#6BE38F")))

	var lista: Array = []
	for s in SECRETOS:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 14)
		var marca := Chulo.new()
		marca.custom_minimum_size = Vector2(36, 36)
		fila.add_child(marca)
		var textos := VBoxContainer.new()
		textos.add_theme_constant_override("separation", -4)
		textos.add_child(Estilo.texto(s[0], 24, Estilo.PANTALLA_TEXTO, true))
		textos.add_child(Estilo.texto(s[1], 18, Color(Estilo.PANTALLA_TEXTO, 0.65)))
		fila.add_child(textos)
		columna.add_child(fila)
		fila.modulate.a = 0.0
		lista.append(fila)

	var tecla := "el botón RANA" if Controles.es_tactil() else "la tecla R"
	var premio := Estilo.parrafo("PODER DE LA XACA RANA: con %s te vuelves rana %d s, %d veces por nivel. Los vigilantes no te reconocen, no haces ruido y saltas por encima de mesas, jardineras y carros." % [tecla, Partida.DURACION_PODER, Partida.USOS_PODER], 20, Estilo.RESALTADOR)
	premio.custom_minimum_size.x = 480
	premio.modulate.a = 0.0
	columna.add_child(premio)

	_boton = Estilo.boton("¡Croac!", cerrar, 220)
	_boton.name = "Cerrar"
	_boton.modulate.a = 0.0
	_boton.disabled = true
	var caja_boton := HBoxContainer.new()
	caja_boton.add_child(_boton)
	columna.add_child(caja_boton)

	# Secuencia: el título rebota, cada secreto se marca con un sonido, luego el premio y el botón.
	titulo.pivot_offset = Vector2(150, 50)
	titulo.scale = Vector2.ZERO
	var t := create_tween()
	t.tween_interval(MOMENTO_TRANSFORMACION)
	t.tween_property(titulo, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.tween_callback(func(): Audio.efecto("victoria"))
	for i in lista.size():
		var fila: HBoxContainer = lista[i]
		t.tween_interval(0.35)
		t.tween_property(fila, "modulate:a", 1.0, 0.2)
		t.tween_callback(func():
			(fila.get_child(0) as Chulo).marcar()
			Audio.efecto("acierto", 1.0 + i * 0.12))
	t.tween_interval(0.3)
	t.tween_property(premio, "modulate:a", 1.0, 0.4)
	t.tween_property(_boton, "modulate:a", 1.0, 0.3)
	t.tween_callback(func():
		_boton.disabled = false
		_boton.grab_focus())


func _process(delta: float) -> void:
	_tiempo += delta
	_rayos.giro = _tiempo * 0.4
	_rayos.queue_redraw()
	if not _transformado:
		# El estudiante gira cada vez más rápido... y ¡puf!
		_estudiante.rotation.y += delta * (2.0 + _tiempo * 14.0)
		_estudiante.position.y = sin(_tiempo * 9.0) * 0.05 + _tiempo * 0.25
		if _tiempo >= MOMENTO_TRANSFORMACION:
			_transformar()
		return
	if _rana:
		# Salta y gira, como celebrando.
		var salto := absf(sin(_tiempo * 4.0))
		_rana.position.y = salto * 0.9
		_rana.scale = Vector3(1.0 + (1.0 - salto) * 0.15, 1.0 - (1.0 - salto) * 0.12, 1.0 + (1.0 - salto) * 0.15) * 2.6
		_rana.rotation.y = sin(_tiempo * 1.5) * 0.6


func _transformar() -> void:
	_transformado = true
	_estudiante.visible = false
	_rana.visible = true
	_confeti.emitting = true
	Audio.efecto("rana")
	Audio.efecto("victoria", 1.0, -4.0)
	# Nube de humo: bolitas blancas que crecen y desaparecen.
	var rng := RandomNumberGenerator.new()
	for i in 14:
		var bola := Constructor.esfera(rng.randf_range(0.25, 0.45), Color("#F4F6FF"), Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(0.6, 2.2), rng.randf_range(-0.6, 0.6)), 0.3)
		bola.scale = Vector3.ONE * 0.1
		_escena_3d.add_child(bola)
		var t := bola.create_tween()
		t.tween_property(bola, "scale", Vector3.ONE * rng.randf_range(1.2, 2.0), 0.25).set_ease(Tween.EASE_OUT)
		t.tween_property(bola, "scale", Vector3.ZERO, 0.45).set_delay(0.1)
		t.tween_callback(bola.queue_free)


func _input(evento: InputEvent) -> void:
	# Mientras está abierta, la tecla de pausa no le llega al juego.
	if evento.is_action_pressed("pausa"):
		get_viewport().set_input_as_handled()
		if not _boton.disabled:
			cerrar()


func cerrar() -> void:
	if is_queued_for_deletion():
		return
	get_tree().paused = _pausa_anterior
	queue_free()


func _crear_rana_3d(raiz: Control) -> void:
	var contenedor := SubViewportContainer.new()
	contenedor.stretch = true
	contenedor.anchor_right = 0.5
	contenedor.anchor_bottom = 1.0
	contenedor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(contenedor)
	var vista := SubViewport.new()
	vista.transparent_bg = true
	vista.own_world_3d = true
	vista.msaa_3d = Viewport.MSAA_4X
	contenedor.add_child(vista)
	var escena := Node3D.new()
	vista.add_child(escena)
	var entorno := WorldEnvironment.new()
	entorno.environment = Environment.new()
	entorno.environment.background_mode = Environment.BG_CLEAR_COLOR
	entorno.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.environment.ambient_light_color = Color("#FFF1C4")
	entorno.environment.ambient_light_energy = 0.7
	escena.add_child(entorno)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-40, 30, 0)
	luz.light_energy = 1.3
	escena.add_child(luz)
	_escena_3d = escena
	_estudiante = Constructor.estudiante()
	_estudiante.scale = Vector3.ONE * 1.4
	escena.add_child(_estudiante)
	_rana = Constructor.rana(true)
	_rana.visible = false
	escena.add_child(_rana)
	var camara := Camera3D.new()
	camara.fov = 40
	camara.position = Vector3(0, 2.0, 7.0)
	escena.add_child(camara)
	camara.look_at(Vector3(0, 1.3, 0), Vector3.UP)


func _crear_confeti(raiz: Control) -> void:
	var confeti := CPUParticles2D.new()
	confeti.position = Vector2(get_viewport().get_visible_rect().size.x / 2.0, -20)
	confeti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	confeti.emission_rect_extents = Vector2(get_viewport().get_visible_rect().size.x / 2.0, 10)
	confeti.amount = 160
	confeti.lifetime = 4.0
	confeti.direction = Vector2.DOWN
	confeti.spread = 25
	confeti.gravity = Vector2(0, 260)
	confeti.initial_velocity_min = 80
	confeti.initial_velocity_max = 220
	confeti.angular_velocity_min = -360
	confeti.angular_velocity_max = 360
	confeti.scale_amount_min = 7
	confeti.scale_amount_max = 13
	var colores := Gradient.new()
	colores.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	colores.colors = PackedColorArray([Estilo.ESFERO, Estilo.RESALTADOR, Color("#6BE38F"), Color("#4078C4"), Estilo.BLANCO])
	colores.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	confeti.color_initial_ramp = colores
	confeti.emitting = false  # empieza con la transformación
	_confeti = confeti
	raiz.add_child(confeti)


class Rayos extends Control:
	## Rayos de luz que giran detrás de la rana.
	var giro := 0.0

	func _draw() -> void:
		var centro := size / 2.0 + Vector2(0, -20)
		var radio := size.length()
		for i in 12:
			var a := giro + TAU * i / 12.0
			var puntos := PackedVector2Array([centro, centro + Vector2.from_angle(a - 0.12) * radio, centro + Vector2.from_angle(a + 0.12) * radio])
			draw_colored_polygon(puntos, Color(Estilo.RESALTADOR, 0.13))
		draw_circle(centro, 170, Color(Estilo.RESALTADOR, 0.12))


class Chulo extends Control:
	## Círculo con un chulito (✓) dibujado a mano, que aparece con un rebote.
	var _hecho := false

	func marcar() -> void:
		_hecho = true
		pivot_offset = size / 2
		scale = Vector2.ZERO
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		queue_redraw()

	func _draw() -> void:
		var c := size / 2
		var r := minf(size.x, size.y) / 2
		if not _hecho:
			draw_arc(c, r - 2, 0, TAU, 32, Color(1, 1, 1, 0.4), 2.0, true)
			return
		draw_circle(c, r, Estilo.VERDE)
		draw_polyline(PackedVector2Array([c + Vector2(-r * 0.45, 0), c + Vector2(-r * 0.1, r * 0.35), c + Vector2(r * 0.5, -r * 0.35)]), Estilo.BLANCO, 4.0, true)
