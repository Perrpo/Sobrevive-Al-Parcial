extends Control
## Ajustes: nombre del jugador, volumen de música y efectos, pantalla completa
## y borrar el progreso. Todo se guarda en disco (Partida.guardar()).

var _nombre: LineEdit
var _borrar: Button
var _confirmando := false


func _ready() -> void:
	add_child(Estilo.fondo_cuaderno())

	var columna := VBoxContainer.new()
	columna.position = Vector2(140, 50)
	columna.add_theme_constant_override("separation", 16)
	add_child(columna)
	columna.add_child(Estilo.etiqueta("Configuración"))
	columna.add_child(Estilo.titulo("Ajustes", 64))

	var tarjeta := Estilo.tarjeta()
	tarjeta.custom_minimum_size.x = 640
	columna.add_child(tarjeta)
	var campos := VBoxContainer.new()
	campos.add_theme_constant_override("separation", 16)
	tarjeta.add_child(campos)

	_nombre = LineEdit.new()
	_nombre.text = Partida.nombre
	_nombre.max_length = 14
	_nombre.placeholder_text = "Tu nombre"
	_nombre.custom_minimum_size.x = 300
	_nombre.text_changed.connect(func(t: String): Partida.nombre = t.strip_edges() if t.strip_edges() != "" else "Estudiante")
	campos.add_child(_fila("Nombre (sale en los récords)", _nombre))

	campos.add_child(_fila("Música", _barra(Partida.volumen_musica, func(v: float):
		Partida.volumen_musica = v
		Audio.aplicar_volumen())))
	campos.add_child(_fila("Efectos", _barra(Partida.volumen_efectos, func(v: float):
		Partida.volumen_efectos = v
		Audio.aplicar_volumen()
		Audio.efecto("apunte"))))

	if not Controles.es_tactil():
		var completa := CheckButton.new()
		completa.button_pressed = Partida.pantalla_completa
		completa.toggled.connect(func(activo: bool):
			Partida.pantalla_completa = activo
			Partida.aplicar_pantalla())
		campos.add_child(_fila("Pantalla completa", completa))

	var en_linea := CheckButton.new()
	en_linea.button_pressed = Partida.ranking_en_linea
	en_linea.toggled.connect(func(activo: bool): Partida.ranking_en_linea = activo)
	campos.add_child(_fila("Subir mi nota al ranking en línea", en_linea))

	_borrar = Estilo.boton("Borrar progreso", _pedir_borrar, 300)
	campos.add_child(_fila("Niveles, récords y secretos", _borrar))

	var controles := "Controles: W A S D o flechas para moverte · Shift para correr (hace ruido) · Esc para pausar"
	if Controles.es_tactil():
		controles = "Controles: joystick para moverte · botón CORRER (hace ruido) · II para pausar"
	var ayuda := Estilo.parrafo(controles, 18, Estilo.TINTA_SUAVE)
	ayuda.custom_minimum_size.x = 640
	columna.add_child(ayuda)

	var volver := Estilo.boton("Guardar y volver", _volver, 280)
	columna.add_child(volver)
	Estilo.entrar_en_cascada([tarjeta, volver], 0.1)
	volver.grab_focus()


func _fila(texto: String, control: Control) -> HBoxContainer:
	var fila := HBoxContainer.new()
	var etiqueta := Estilo.texto(texto, 22, Estilo.TINTA, true)
	etiqueta.custom_minimum_size.x = 300
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_OFF
	fila.add_child(etiqueta)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(control)
	return fila


func _barra(valor: float, al_cambiar: Callable) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = valor
	s.custom_minimum_size = Vector2(280, 32)
	s.value_changed.connect(al_cambiar)
	return s


## Borrar pide confirmación: hay que tocar dos veces.
func _pedir_borrar() -> void:
	if not _confirmando:
		_confirmando = true
		_borrar.text = "¿Seguro? Toca otra vez"
		_borrar.add_theme_color_override("font_color", Estilo.ESFERO)
		return
	Partida.borrar_progreso()
	_confirmando = false
	_borrar.text = "Progreso borrado"
	_borrar.disabled = true
	Audio.efecto("error")


func _volver() -> void:
	Partida.guardar()
	Transicion.ir("res://escenas/Home.tscn")
