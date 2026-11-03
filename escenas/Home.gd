extends Control
## Menú principal (Home). A la derecha hay una vista 3D del estudiante y el vigilante.
##
## Easter egg: el código Konami (↑ ↑ ↓ ↓ ← → ← → B A) activa el "modo profe":
## los vigilantes se vuelven profesores con corbata. En el celular se activa
## tocando 5 veces el sello "5.0".

const KONAMI := [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A]

var _konami := 0
var _toques_sello := 0
var _sello: Sello
var _aviso: Label
var _estudiante: Node3D
var _vigilante: Node3D
var _tiempo := 0.0
var _escena_3d: Node3D


func _ready() -> void:
	add_child(Estilo.fondo_cuaderno())
	_crear_vista_3d()  # va antes que los botones para quedar detrás

	var columna := VBoxContainer.new()
	columna.position = Vector2(140, 44)
	columna.add_theme_constant_override("separation", 10)
	add_child(columna)

	var animados: Array = []
	var sub := Estilo.etiqueta("Juego final · Aplicaciones Móviles")
	columna.add_child(sub)
	animados.append(sub)
	var nombre := VBoxContainer.new()
	nombre.add_theme_constant_override("separation", -34)
	nombre.add_child(Estilo.titulo("Sobrevive al", 84))
	nombre.add_child(Estilo.titulo("*Parcial*", 84))
	columna.add_child(nombre)
	animados.append(nombre)
	var saludo := Estilo.nota("Hola, %s. Junta los apuntes y llega al parcial." % Partida.nombre, 24)
	saludo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	saludo.custom_minimum_size.x = 440
	columna.add_child(saludo)
	animados.append(saludo)

	var botones := VBoxContainer.new()
	botones.add_theme_constant_override("separation", 12)
	botones.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	columna.add_child(botones)
	var espacio := Control.new()
	espacio.custom_minimum_size.y = 6
	botones.add_child(espacio)

	var jugar := Estilo.boton("Jugar", _jugar, 320)
	botones.add_child(jugar)
	var fila1 := HBoxContainer.new()
	fila1.add_theme_constant_override("separation", 12)
	fila1.add_child(Estilo.boton("Niveles", func(): Transicion.ir("res://escenas/Niveles.tscn"), 154))
	fila1.add_child(Estilo.boton("Puntajes", func(): Transicion.ir("res://escenas/Puntaje.tscn"), 154))
	botones.add_child(fila1)
	var fila2 := HBoxContainer.new()
	fila2.add_theme_constant_override("separation", 12)
	fila2.add_child(Estilo.boton("Ajustes", func(): Transicion.ir("res://escenas/Ajustes.tscn"), 154))
	fila2.add_child(Estilo.boton("Créditos", func(): Transicion.ir("res://escenas/Creditos.tscn"), 154))
	botones.add_child(fila2)
	if not Controles.es_tactil():
		botones.add_child(Estilo.boton("Salir", func(): get_tree().quit(), 320))
	animados.append_array([jugar, fila1, fila2])
	Estilo.entrar_en_cascada(animados, 0.08)
	jugar.grab_focus()

	_sello = Sello.new()
	_sello.custom_minimum_size = Vector2(130, 130)
	_sello.size = Vector2(130, 130)
	_sello.anchor_left = 1.0
	_sello.anchor_right = 1.0
	_sello.offset_left = -190
	_sello.offset_right = -60
	_sello.offset_top = 40
	_sello.offset_bottom = 170
	_sello.gui_input.connect(_tocar_sello)
	add_child(_sello)

	_aviso = Estilo.nota("", 28, Estilo.VERDE)
	_aviso.anchor_left = 1.0
	_aviso.anchor_right = 1.0
	_aviso.anchor_top = 1.0
	_aviso.anchor_bottom = 1.0
	_aviso.offset_left = -560
	_aviso.offset_right = -40
	_aviso.offset_top = -70
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_aviso)
	_mostrar_modo_profe(false)

	Audio.musica("menu")


func _process(delta: float) -> void:
	_tiempo += delta
	if _estudiante:
		_estudiante.rotation.y = sin(_tiempo * 0.8) * 0.6 + 0.3
		_estudiante.position.y = absf(sin(_tiempo * 3.0)) * 0.08
	if _vigilante:
		_vigilante.rotation.y = -0.6 + sin(_tiempo * 0.5) * 0.5


## Si alguna vez encontró las 3 Xaca Ranas, la rana dorada salta al lado del estudiante.
func _poner_rana_dorada() -> void:
	if _escena_3d.has_node("RanaDorada"):
		return
	var rana := Constructor.rana(true)
	rana.name = "RanaDorada"
	rana.scale = Vector3.ONE * 1.3
	rana.position = Vector3(0.9, 0, 0.9)
	_escena_3d.add_child(rana)
	var t := rana.create_tween().set_loops()
	t.tween_property(rana, "position:y", 0.35, 0.22).set_ease(Tween.EASE_OUT)
	t.tween_property(rana, "position:y", 0.0, 0.22).set_ease(Tween.EASE_IN)
	t.tween_interval(1.2)


func _jugar() -> void:
	Partida.nueva_partida(1)
	Transicion.ir("res://escenas/Historia.tscn")  # primero la historia, luego el nivel 1


## Escena 3D pequeña dentro del menú (un SubViewport con su propio mundo).
func _crear_vista_3d() -> void:
	var contenedor := SubViewportContainer.new()
	contenedor.stretch = true
	contenedor.anchor_left = 0.5
	contenedor.anchor_right = 1.0
	contenedor.anchor_top = 0.18
	contenedor.anchor_bottom = 1.0
	contenedor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(contenedor)
	var vista := SubViewport.new()
	vista.transparent_bg = true
	vista.own_world_3d = true
	vista.msaa_3d = Viewport.MSAA_4X
	contenedor.add_child(vista)

	var escena := Node3D.new()
	vista.add_child(escena)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-45, 35, 0)
	luz.light_energy = 1.2
	escena.add_child(luz)
	var entorno := WorldEnvironment.new()
	entorno.environment = Environment.new()
	entorno.environment.background_mode = Environment.BG_CLEAR_COLOR
	entorno.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.environment.ambient_light_color = Color("#C9D6FF")
	entorno.environment.ambient_light_energy = 0.8
	escena.add_child(entorno)

	var piso := Constructor.cilindro(1.9, 1.9, 0.12, Color("#C9D6EA"), Vector3(-0.6, -0.06, -0.5))
	escena.add_child(piso)
	_estudiante = Constructor.estudiante()
	escena.add_child(_estudiante)
	_vigilante = Constructor.vigilante("vigilante", Partida.modo_profe)
	_vigilante.position = Vector3(-1.9, 0, -1.6)
	escena.add_child(_vigilante)
	var cono := Constructor.cono_vision(3.2, 0.45, Color("#FFE14D"))
	_vigilante.add_child(cono)
	var hoja := Constructor.apunte()
	hoja.position = Vector3(1.3, 1.5, 0.4)
	hoja.rotation_degrees = Vector3(0, -20, 12)
	escena.add_child(hoja)
	var t := hoja.create_tween().set_loops()
	t.tween_property(hoja, "position:y", 1.8, 1.0).set_trans(Tween.TRANS_SINE)
	t.tween_property(hoja, "position:y", 1.5, 1.0).set_trans(Tween.TRANS_SINE)
	_escena_3d = escena
	if Partida.tiene_todos_los_huevos():
		_poner_rana_dorada()
	Partida.huevos_completos.connect(_poner_rana_dorada)

	var camara := Camera3D.new()
	camara.fov = 38
	camara.position = Vector3(0.6, 3.0, 7.4)
	escena.add_child(camara)
	camara.look_at(Vector3(-0.2, 1.0, 0), Vector3.UP)


# ---------- Easter egg: modo profe ----------

func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo:
		if evento.keycode == KONAMI[_konami]:
			_konami += 1
			if _konami == KONAMI.size():
				_konami = 0
				_alternar_modo_profe()
		else:
			_konami = 1 if evento.keycode == KONAMI[0] else 0


func _tocar_sello(evento: InputEvent) -> void:
	if (evento is InputEventMouseButton or evento is InputEventScreenTouch) and evento.pressed:
		_toques_sello += 1
		Audio.efecto("clic", 1.0 + _toques_sello * 0.1)
		_sello.sacudir()
		if _toques_sello >= 5:
			_toques_sello = 0
			_alternar_modo_profe()


func _alternar_modo_profe() -> void:
	Partida.modo_profe = not Partida.modo_profe
	Audio.efecto("rana")
	var nuevo := false  # el modo profe es un truco visual: no cuenta como Xaca Rana
	# Se reemplaza el vigilante del menú para que se note el cambio.
	var padre := _vigilante.get_parent()
	var pos := _vigilante.position
	var cono := _vigilante.get_child(_vigilante.get_child_count() - 1)
	_vigilante.remove_child(cono)
	_vigilante.queue_free()
	_vigilante = Constructor.vigilante("vigilante", Partida.modo_profe)
	_vigilante.position = pos
	_vigilante.add_child(cono)
	padre.add_child(_vigilante)
	_mostrar_modo_profe(nuevo)


func _mostrar_modo_profe(nuevo: bool) -> void:
	if Partida.modo_profe:
		_aviso.text = "Modo profe activado: ¡los vigilantes ahora son profes!" + ("  (secreto)" if nuevo else "")
	else:
		_aviso.text = ""


class Sello extends Control:
	## Sello rojo de "5.0" como el de una nota en el cuaderno.
	func _ready() -> void:
		pivot_offset = size / 2
		rotation_degrees = -12
		mouse_filter = Control.MOUSE_FILTER_STOP

	func sacudir() -> void:
		var t := create_tween()
		t.tween_property(self, "scale", Vector2.ONE * 1.15, 0.06)
		t.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)

	func _draw() -> void:
		var c := size / 2
		var r := minf(size.x, size.y) / 2 - 4
		draw_arc(c, r, 0, TAU, 64, Estilo.ESFERO, 5.0, true)
		draw_arc(c, r - 9, 0, TAU, 64, Estilo.ESFERO, 2.0, true)
		var fuente := Estilo.fuente_titulo
		var texto := "5.0"
		var tam := 50
		var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		draw_string(fuente, Vector2(c.x - ancho / 2, c.y + tam * 0.36), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Estilo.ESFERO)
