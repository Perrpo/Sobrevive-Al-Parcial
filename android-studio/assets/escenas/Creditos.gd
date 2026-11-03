extends Control
## Créditos con desplazamiento automático (como en las películas).
## También muestra cuántos easter eggs ha encontrado el jugador.

## Nombres del equipo (salen en la pantalla de Créditos).
const EQUIPO := [
	["Andrés Núñez", "Programación y diseño de niveles"],
	["Andrés Navarro", "Interfaz, sonido y wireframes"],
	["Andrey Osorio", "Pruebas y animaciones"],
]
const VELOCIDAD := 38.0

var _rollo: VBoxContainer
var _ventana: Control
var _arrastrando := false


func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Estilo.PANTALLA
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	_ventana = Control.new()
	_ventana.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ventana.clip_contents = true
	add_child(_ventana)

	_rollo = VBoxContainer.new()
	_rollo.add_theme_constant_override("separation", 10)
	_rollo.alignment = BoxContainer.ALIGNMENT_CENTER
	_ventana.add_child(_rollo)

	_titulo("Sobrevive al *Parcial*", 72)
	_linea("Juego final · Aplicaciones Móviles", 22, Estilo.RESALTADOR, true)
	_espacio(40)
	_seccion("Equipo")
	for persona in EQUIPO:
		_linea(persona[0], 30, Estilo.PANTALLA_TEXTO, true)
		_linea(persona[1], 20, Color(Estilo.PANTALLA_TEXTO, 0.6))
		_espacio(8)
	_espacio(30)
	_seccion("Hecho con")
	_linea("Godot Engine 4.5 (licencia MIT)", 22)
	_linea("GDScript · Renderizador Compatibilidad (OpenGL)", 22)
	_linea("Modelos 3D armados con figuras por código", 22)
	_linea("Ranking en línea con Firebase Realtime Database", 22)
	_espacio(30)
	_seccion("Letras")
	_linea("Bagel Fat One · Figtree · Kalam", 22)
	_linea("Google Fonts, licencia SIL Open Font License", 18, Color(Estilo.PANTALLA_TEXTO, 0.6))
	_espacio(30)
	_seccion("Sonidos y música")
	_linea("Generados por código con Python (herramientas/sonidos.py)", 22)
	_espacio(30)
	_seccion("Inteligencia artificial")
	_linea("Se usó Claude (Anthropic) como asistente de programación.", 22)
	_linea("Cada parte está explicada en el README del proyecto.", 18, Color(Estilo.PANTALLA_TEXTO, 0.6))
	_espacio(30)
	_seccion("Gracias")
	_linea("Al profe de Aplicaciones Móviles y a la Xaca Rana.", 22)
	_linea("A todos los que alguna vez estudiaron la noche antes.", 22)
	_espacio(40)
	var huevos := Partida.huevos.size()
	_seccion("Xaca Ranas encontradas")
	_titulo("%d / %d" % [huevos, Partida.HUEVOS_TOTALES], 64)
	if huevos < Partida.HUEVOS_TOTALES:
		_linea("Pista: hay una entre los libros, otra junto a las jardineras del bulevar", 18, Color(Estilo.PANTALLA_TEXTO, 0.6))
		_linea("y otra detrás de una puerta en ingeniería. Con las 3 te vuelves rana.", 18, Color(Estilo.PANTALLA_TEXTO, 0.6))
	else:
		_linea("¡Las encontraste todas! Eres digno del poder de la Xaca Rana.", 22, Estilo.RESALTADOR)
	_espacio(60)
	_titulo("Fin", 56)

	var volver := Estilo.boton("Volver", func(): Transicion.ir("res://escenas/Home.tscn"), 180)
	volver.position = Vector2(40, 30)
	add_child(volver)
	volver.grab_focus()
	if Partida.tiene_todos_los_huevos():
		var otra_vez := Estilo.boton("Ver la celebración", func(): add_child(CelebracionRana.new()), 260)
		otra_vez.position = Vector2(240, 30)
		add_child(otra_vez)

	await get_tree().process_frame
	_rollo.size.x = _ventana.size.x
	_rollo.position.y = _ventana.size.y * 0.55
	Audio.musica("menu")


func _process(delta: float) -> void:
	if _arrastrando:
		return
	_rollo.position.y -= VELOCIDAD * delta
	_rollo.size.x = _ventana.size.x
	# Cuando termina vuelve a empezar desde abajo.
	if _rollo.position.y < -_rollo.size.y:
		_rollo.position.y = _ventana.size.y


func _unhandled_input(evento: InputEvent) -> void:
	# Se puede adelantar con la rueda del mouse o arrastrando con el dedo.
	if evento is InputEventMouseButton and evento.pressed:
		if evento.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_rollo.position.y -= 60
		elif evento.button_index == MOUSE_BUTTON_WHEEL_UP:
			_rollo.position.y += 60
	elif evento is InputEventScreenDrag:
		_rollo.position.y += evento.relative.y
	elif evento is InputEventScreenTouch:
		_arrastrando = evento.pressed


func _titulo(texto: String, tam: int) -> void:
	var t := Estilo.titulo(texto, tam, Estilo.PANTALLA_TEXTO)
	var c := CenterContainer.new()
	c.add_child(t)
	_rollo.add_child(c)


func _seccion(texto: String) -> void:
	var l := Estilo.etiqueta(texto, Estilo.ESFERO.lightened(0.25))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rollo.add_child(l)


func _linea(texto: String, tam: int, color: Color = Estilo.PANTALLA_TEXTO, negrita: bool = false) -> void:
	var l := Estilo.texto(texto, tam, color, negrita)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rollo.add_child(l)


func _espacio(alto: int) -> void:
	var e := Control.new()
	e.custom_minimum_size.y = alto
	_rollo.add_child(e)
