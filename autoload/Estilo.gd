extends Node
## Interfaz personalizada (requisito 6): estilo "cuaderno de estudiante".
## Papel cuadriculado, tinta azul oscura, resaltador amarillo y notas en esfero rojo.
##
## Aquí se arma el Theme de Godot que usan todos los botones, textos y paneles,
## y unas funciones para crear los elementos de las pantallas con el mismo estilo.

const PAPEL := Color("#F2F6FB")
const CUADRICULA := Color(0.25, 0.47, 0.77, 0.13)
const MARGEN_ROJO := Color(0.84, 0.2, 0.23, 0.35)
const TINTA := Color("#182742")
const TINTA_SUAVE := Color("#4A5A78")
const ESFERO := Color("#D7333A")
const RESALTADOR := Color("#FFE14D")
const PANTALLA := Color("#10182B")
const PANTALLA_TEXTO := Color("#EAF0FF")
const BLANCO := Color("#FFFFFF")
const VERDE := Color("#2E9E5B")

var fuente_titulo: FontFile
var fuente_texto: FontFile
var fuente_negrita: FontFile
var fuente_mano: FontFile
var tema: Theme


func _ready() -> void:
	fuente_titulo = load("res://fuentes/BagelFatOne.woff2")
	fuente_texto = load("res://fuentes/Figtree-Regular.woff2")
	fuente_negrita = load("res://fuentes/Figtree-Bold.woff2")
	fuente_mano = load("res://fuentes/Kalam-Bold.woff2")
	tema = _crear_tema()
	get_tree().root.theme = tema


func _caja(fondo: Color, borde: Color, grosor: int, radio: int, sombra: int = 0) -> StyleBoxFlat:
	var c := StyleBoxFlat.new()
	c.bg_color = fondo
	c.border_color = borde
	c.set_border_width_all(grosor)
	c.set_corner_radius_all(radio)
	c.content_margin_left = 22
	c.content_margin_right = 22
	c.content_margin_top = 10
	c.content_margin_bottom = 12
	if sombra > 0:
		c.shadow_color = Color(TINTA, 0.9)
		c.shadow_size = 0
		c.shadow_offset = Vector2(sombra, sombra)
	return c


func _crear_tema() -> Theme:
	var t := Theme.new()
	t.default_font = fuente_texto
	t.default_font_size = 22

	# Botones tipo "sticker": borde de tinta y sombra dura.
	t.set_stylebox("normal", "Button", _caja(BLANCO, TINTA, 3, 14, 5))
	t.set_stylebox("hover", "Button", _caja(RESALTADOR, TINTA, 3, 14, 5))
	var presionado := _caja(RESALTADOR, TINTA, 3, 14, 1)
	t.set_stylebox("pressed", "Button", presionado)
	t.set_stylebox("focus", "Button", _caja(Color(0, 0, 0, 0), ESFERO, 3, 14))
	t.set_stylebox("disabled", "Button", _caja(Color("#E3E8F0"), Color(TINTA, 0.35), 3, 14))
	t.set_font("font", "Button", fuente_negrita)
	t.set_font_size("font_size", "Button", 24)
	for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(estado, "Button", TINTA)
	t.set_color("font_disabled_color", "Button", Color(TINTA, 0.4))

	t.set_color("font_color", "Label", TINTA)

	# Paneles = hojas o tarjetas.
	var tarjeta := _caja(BLANCO, Color(TINTA, 0.18), 2, 16)
	tarjeta.content_margin_left = 24
	tarjeta.content_margin_right = 24
	tarjeta.content_margin_top = 20
	tarjeta.content_margin_bottom = 20
	t.set_stylebox("panel", "PanelContainer", tarjeta)

	# Campos de texto.
	t.set_stylebox("normal", "LineEdit", _caja(BLANCO, TINTA, 3, 12))
	t.set_stylebox("focus", "LineEdit", _caja(Color(0, 0, 0, 0), ESFERO, 3, 12))
	t.set_color("font_color", "LineEdit", TINTA)
	t.set_color("caret_color", "LineEdit", ESFERO)
	t.set_color("selection_color", "LineEdit", Color(RESALTADOR, 0.7))
	t.set_font_size("font_size", "LineEdit", 24)

	# Barras de volumen: un resaltador sobre el papel.
	var riel := StyleBoxFlat.new()
	riel.bg_color = Color(TINTA, 0.15)
	riel.set_corner_radius_all(6)
	riel.content_margin_top = 6
	riel.content_margin_bottom = 6
	var lleno := StyleBoxFlat.new()
	lleno.bg_color = RESALTADOR
	lleno.border_color = TINTA
	lleno.set_border_width_all(2)
	lleno.set_corner_radius_all(6)
	t.set_stylebox("slider", "HSlider", riel)
	t.set_stylebox("grabber_area", "HSlider", lleno)
	t.set_stylebox("grabber_area_highlight", "HSlider", lleno)
	t.set_icon("grabber", "HSlider", _circulo(28, ESFERO))
	t.set_icon("grabber_highlight", "HSlider", _circulo(32, ESFERO))

	t.set_color("font_color", "CheckButton", TINTA)
	t.set_color("font_hover_color", "CheckButton", TINTA)
	t.set_color("font_pressed_color", "CheckButton", TINTA)
	t.set_color("font_hover_pressed_color", "CheckButton", TINTA)
	t.set_stylebox("normal", "CheckButton", StyleBoxEmpty.new())
	t.set_stylebox("hover", "CheckButton", StyleBoxEmpty.new())
	t.set_stylebox("pressed", "CheckButton", StyleBoxEmpty.new())
	t.set_stylebox("focus", "CheckButton", StyleBoxEmpty.new())
	return t


func _circulo(tam: int, color: Color) -> ImageTexture:
	var img := Image.create(tam, tam, false, Image.FORMAT_RGBA8)
	var c := tam / 2.0
	for x in tam:
		for y in tam:
			var d := Vector2(x + 0.5 - c, y + 0.5 - c).length()
			if d <= c - 1:
				img.set_pixel(x, y, color if d < c - 4 else TINTA)
	return ImageTexture.create_from_image(img)


# ---------- Piezas para armar pantallas ----------

## Título grande con la fuente gorda. Las palabras entre * salen en rojo: "Sobrevive al *Parcial*".
func titulo(contenido: String, tam: int = 64, color: Color = TINTA) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_OFF
	r.add_theme_font_override("normal_font", fuente_titulo)
	r.add_theme_font_size_override("normal_font_size", tam)
	r.add_theme_color_override("default_color", color)
	var partes := contenido.split("*")
	var bb := ""
	for i in partes.size():
		bb += ("[color=#%s]%s[/color]" % [ESFERO.to_html(false), partes[i]]) if i % 2 == 1 else partes[i]
	r.text = bb
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func texto(contenido: String, tam: int = 22, color: Color = TINTA, negrita: bool = false) -> Label:
	var l := Label.new()
	l.text = contenido
	l.add_theme_font_override("font", fuente_negrita if negrita else fuente_texto)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l


## Igual que texto(), pero el texto largo pasa a la siguiente línea (para usar en columnas).
func parrafo(contenido: String, tam: int = 22, color: Color = TINTA) -> Label:
	var l := texto(contenido, tam, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## Nota escrita a mano en esfero rojo.
func nota(contenido: String, tam: int = 28, color: Color = ESFERO) -> Label:
	var l := texto(contenido, tam, color)
	l.add_theme_font_override("font", fuente_mano)
	return l


func etiqueta(contenido: String, color: Color = ESFERO) -> Label:
	var l := texto(contenido.to_upper(), 16, color, true)
	return l


func boton(contenido: String, al_tocar: Callable, ancho: int = 0) -> Button:
	var b := Button.new()
	b.text = contenido
	if ancho > 0:
		b.custom_minimum_size.x = ancho
	b.custom_minimum_size.y = 58
	b.pressed.connect(func():
		Audio.efecto("clic")
		al_tocar.call())
	b.mouse_entered.connect(func(): _rebote(b, 1.04))
	b.mouse_exited.connect(func(): _rebote(b, 1.0))
	b.focus_entered.connect(func(): _rebote(b, 1.04))
	b.focus_exited.connect(func(): _rebote(b, 1.0))
	b.resized.connect(func(): b.pivot_offset = b.size / 2)
	return b


func _rebote(c: Control, escala: float) -> void:
	c.pivot_offset = c.size / 2
	var t := c.create_tween()
	t.tween_property(c, "scale", Vector2.ONE * escala, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func tarjeta() -> PanelContainer:
	return PanelContainer.new()


## Hace aparecer elementos uno tras otro, subiendo un poco (animación de entrada).
func entrar_en_cascada(controles: Array, retraso: float = 0.06) -> void:
	for i in controles.size():
		var c: Control = controles[i]
		c.modulate.a = 0.0
		var t := c.create_tween()
		t.tween_interval(i * retraso)
		t.tween_property(c, "modulate:a", 1.0, 0.25)


## Fondo de hoja de cuaderno para las pantallas de menú.
func fondo_cuaderno() -> Control:
	var f := FondoCuaderno.new()
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return f


class FondoCuaderno extends Control:
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Estilo.PAPEL)
		var paso := 32.0
		var x := 0.0
		while x < size.x:
			draw_line(Vector2(x, 0), Vector2(x, size.y), Estilo.CUADRICULA, 1.0)
			x += paso
		var y := 0.0
		while y < size.y:
			draw_line(Vector2(0, y), Vector2(size.x, y), Estilo.CUADRICULA, 1.0)
			y += paso
		draw_line(Vector2(96, 0), Vector2(96, size.y), Estilo.MARGEN_ROJO, 2.0)

	func _notification(que: int) -> void:
		if que == NOTIFICATION_RESIZED:
			queue_redraw()
