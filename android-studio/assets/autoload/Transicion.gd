extends CanvasLayer
## Cambia de escena con una animación: una hoja de cuaderno baja, se cambia la escena
## por debajo y la hoja vuelve a subir.

var _hoja: ColorRect
var _ocupado := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hoja = ColorRect.new()
	_hoja.color = Estilo.PANTALLA
	_hoja.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hoja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hoja.visible = false
	add_child(_hoja)


func ir(ruta: String) -> void:
	if _ocupado:
		return
	_ocupado = true
	get_tree().paused = false
	var alto := get_viewport().get_visible_rect().size.y
	_hoja.visible = true
	_hoja.mouse_filter = Control.MOUSE_FILTER_STOP
	_hoja.position.y = -alto
	var t := create_tween()
	t.tween_property(_hoja, "position:y", 0.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await t.finished
	get_tree().change_scene_to_file(ruta)
	await get_tree().process_frame
	await get_tree().process_frame
	var t2 := create_tween()
	t2.tween_property(_hoja, "position:y", alto, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await t2.finished
	_hoja.visible = false
	_hoja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ocupado = false
