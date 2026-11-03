extends Control
## Pantalla de inicio (Splash): logo animado, timbre y una barra de "carga"
## con frases de estudiante. Se puede saltar con un clic o una tecla.

const FRASES := [
	"Buscando los apuntes de un compañero...",
	"Calentando el tinto...",
	"Esquivando al vigilante...",
	"Repasando a última hora...",
	"Rezando por un 3.0...",
]
const DURACION := 2.8

var _barra: BarraCarga
var _frase: Label
var _tiempo := 0.0
var _saliendo := false


func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Estilo.PANTALLA
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var columna := VBoxContainer.new()
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 18)
	centro.add_child(columna)

	var logo := TextureRect.new()
	logo.texture = load("res://icon.svg")
	logo.custom_minimum_size = Vector2(150, 150)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var caja_logo := CenterContainer.new()
	caja_logo.add_child(logo)
	columna.add_child(caja_logo)

	var nombre := Estilo.titulo("Sobrevive al *Parcial*", 76, Estilo.PANTALLA_TEXTO)
	var caja_nombre := CenterContainer.new()
	caja_nombre.add_child(nombre)
	columna.add_child(caja_nombre)

	_barra = BarraCarga.new()
	_barra.custom_minimum_size = Vector2(460, 18)
	var caja_barra := CenterContainer.new()
	caja_barra.add_child(_barra)
	columna.add_child(caja_barra)

	_frase = Estilo.nota(FRASES[0], 26, Estilo.RESALTADOR)
	_frase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(_frase)

	# Animación: el logo cae con rebote y el título aparece.
	logo.pivot_offset = Vector2(75, 75)
	logo.scale = Vector2.ZERO
	logo.rotation_degrees = -25
	var t := create_tween().set_parallel()
	t.tween_property(logo, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.tween_property(logo, "rotation_degrees", 0.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	nombre.modulate.a = 0.0
	t.tween_property(nombre, "modulate:a", 1.0, 0.5).set_delay(0.35)

	Audio.efecto("timbre")


func _process(delta: float) -> void:
	_tiempo += delta
	var avance := clampf(_tiempo / DURACION, 0.0, 1.0)
	_barra.avance = avance
	_barra.queue_redraw()
	_frase.text = FRASES[mini(int(avance * FRASES.size()), FRASES.size() - 1)]
	if avance >= 1.0:
		_salir()


func _unhandled_input(evento: InputEvent) -> void:
	if (evento is InputEventKey or evento is InputEventMouseButton or evento is InputEventScreenTouch) and evento.is_pressed():
		_salir()


func _salir() -> void:
	if _saliendo:
		return
	_saliendo = true
	Transicion.ir("res://escenas/Home.tscn")


class BarraCarga extends Control:
	var avance := 0.0

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(Estilo.PANTALLA_TEXTO, 0.12))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * avance, size.y)), Estilo.RESALTADOR)
		draw_rect(r, Color(Estilo.PANTALLA_TEXTO, 0.6), false, 2.0)
