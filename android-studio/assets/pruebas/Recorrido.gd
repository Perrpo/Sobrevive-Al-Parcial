extends Node
## Prueba automática: recorre todas las pantallas, juega los 5 niveles y el final,
## y toma capturas. Solo se activa si el juego se abre con:
##   godot --path . -- --recorrido --capturas=/ruta/a/carpeta
## Con --nube=http://127.0.0.1:8765 también prueba el ranking en línea (ver herramientas/nube_de_prueba.py).
## En el juego normal este nodo no hace nada.

var _carpeta := "user://capturas"
var _errores: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	if not "--recorrido" in args:
		return
	for a in args:
		if a.begins_with("--capturas="):
			_carpeta = a.trim_prefix("--capturas=")
	DirAccess.make_dir_recursive_absolute(_carpeta)
	_recorrer.call_deferred()


func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos, true, false, true).timeout


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(_carpeta.path_join(nombre + ".png"))
	print("[recorrido] captura ", nombre)


func _revisar(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("[recorrido] OK  ", mensaje)
	else:
		print("[recorrido] FALLA ", mensaje)
		_errores.append(mensaje)


func _escena() -> Node:
	return get_tree().current_scene


func _ir(ruta: String, espera: float = 1.2) -> void:
	await _sin_transicion()
	Transicion.ir(ruta)
	await _esperar(espera)
	await _sin_transicion()


## Espera a que termine la animación de cambio de pantalla.
func _sin_transicion() -> void:
	while Transicion._ocupado:
		await get_tree().process_frame
	await _esperar(0.2)


func _tocar(indice: int, pos: Vector2, presionado: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = indice
	e.position = pos
	e.pressed = presionado
	Input.parse_input_event(e)


## Dedo 0 en el joystick y dedo 1 en CORRER al mismo tiempo.
func _probar_multitouch(juego: Juego) -> void:
	var centro := juego.hud.joystick.get_global_rect().get_center()
	var antes := juego.jugador.global_position
	_tocar(0, centro, true)
	var arrastre := InputEventScreenDrag.new()
	arrastre.index = 0
	arrastre.position = centro + Vector2(90, 0)
	arrastre.relative = Vector2(90, 0)
	Input.parse_input_event(arrastre)
	_tocar(1, juego.hud.boton_correr.get_global_rect().get_center(), true)
	await _esperar(0.5)
	_revisar(juego.jugador.correr_tactil, "CORRER responde con un segundo dedo")
	await _foto("10b_tactil_corriendo")
	_tocar(1, juego.hud.boton_correr.get_global_rect().get_center(), false)
	_tocar(0, centro, false)
	await _esperar(0.2)
	_revisar(juego.jugador.global_position.x > antes.x + 1.0, "el joystick mueve al jugador")
	_revisar(not juego.jugador.correr_tactil, "CORRER se suelta")


## Pausa con el botón del HUD (o la tecla), foto, y Continuar.
func _probar_pausa(juego: Juego) -> void:
	var boton := juego.hud.find_child("BotonPausa", true, false)
	if boton:
		boton.pressed.emit()
	else:
		_presionar("pausa")
	await _esperar(0.5)
	_revisar(get_tree().paused and juego.hud._capa_modal != null, "el botón II pausa el juego")
	await _foto("07b_pausa")
	juego.hud._capa_modal.find_child("Continuar", true, false).pressed.emit()
	await _esperar(0.3)
	_revisar(not get_tree().paused, "Continuar quita la pausa")


## En la pausa del celular: mover el joystick y cambiarle el tamaño.
func _probar_ajuste_joystick(juego: Juego) -> void:
	var hud := juego.hud
	var antes := hud.joystick.get_global_rect().get_center()
	_presionar("pausa")
	await _esperar(0.4)
	hud._capa_modal.find_child("AjustarJoystick", true, false).pressed.emit()
	await _esperar(0.3)
	_revisar(hud.ajustando_joystick and get_tree().paused, "Ajustar joystick abre el modo de ajuste")
	_tocar(3, antes, true)
	var arrastre := InputEventScreenDrag.new()
	arrastre.index = 3
	arrastre.position = antes + Vector2(380, -120)
	arrastre.relative = Vector2(380, -120)
	Input.parse_input_event(arrastre)
	_tocar(3, antes + Vector2(380, -120), false)
	await _esperar(0.2)
	(hud.find_child("Tamano", true, false) as HSlider).value = 1.4
	await _esperar(0.3)
	await _foto("10c_ajustar_joystick")
	var despues := hud.joystick.get_global_rect().get_center()
	_revisar(despues.distance_to(antes + Vector2(380, -120)) < 3.0, "el joystick se movió a donde se arrastró")
	_revisar(is_equal_approx(hud.joystick.size.x, hud.TAM_JOYSTICK * 1.4), "el joystick cambió de tamaño (%.0f px)" % hud.joystick.size.x)
	hud.find_child("Listo", true, false).pressed.emit()
	await _esperar(0.4)
	var cfg := ConfigFile.new()
	cfg.load(Partida.RUTA)
	_revisar(not hud.ajustando_joystick and hud._capa_modal != null and is_equal_approx(cfg.get_value("controles", "joystick_escala", 0.0), 1.4),
		"Listo guarda el ajuste y vuelve a la pausa")
	hud._capa_modal.find_child("Continuar", true, false).pressed.emit()
	await _esperar(0.3)
	await _foto("10d_joystick_nuevo")
	# Se deja como estaba para el resto de la prueba.
	Partida.joystick_centro = Vector2(-1, -1)
	Partida.joystick_escala = 1.0
	hud.aplicar_joystick()


func _presionar(accion: String) -> void:
	var e := InputEventAction.new()
	e.action = accion
	e.pressed = true
	Input.parse_input_event(e)


func _siguiente_nivel(numero: int) -> Juego:
	await _esperar(1.6)
	await _sin_transicion()
	var juego: Juego = _escena()
	_revisar(juego.numero == numero, "llega al nivel %d" % numero)
	juego._continuar()
	juego._invulnerable = 99.0
	await _esperar(1.2)
	return juego


func _tomar_rana(juego: Juego, celda: Vector2i, cuantas: int) -> void:
	var vidas := Partida.vidas
	juego.jugador.global_position = juego.celda_a_mundo(celda)
	await _esperar(0.5)
	_revisar(Partida.ranas_partida.size() == cuantas and Partida.vidas == mini(vidas + 1, Partida.VIDAS_MAXIMAS),
		"Xaca Rana %d: +1 vida (vidas=%d)" % [cuantas, Partida.vidas])


func _buscar_celebracion() -> CelebracionRana:
	for n in get_tree().root.get_children():
		if n is CelebracionRana and not n.is_queued_for_deletion():
			return n
	for n in _escena().get_children():
		if n is CelebracionRana and not n.is_queued_for_deletion():
			return n
	return null


func _recorrer() -> void:
	Partida.borrar_progreso()
	Partida.nombre = "Prueba"
	await _esperar(0.9)
	await _foto("01_splash")
	await _esperar(3.0)
	await _sin_transicion()
	_revisar(_escena().name == "Home", "el splash lleva al menú")
	await _foto("02_home")

	await _ir("res://escenas/Niveles.tscn")
	await _foto("03_niveles")
	await _ir("res://escenas/Ajustes.tscn")
	await _foto("04_ajustes")
	await _ir("res://escenas/Creditos.tscn", 3.0)
	await _foto("05_creditos")

	# ----- Historia (animación del inicio) -----
	await _ir("res://escenas/Home.tscn")
	_escena()._jugar()  # botón Jugar del menú
	await _esperar(0.8)
	await _sin_transicion()
	_revisar(_escena().name == "Historia", "Jugar abre la historia")
	var historia := _escena()
	for t in [[2.5, "h1_cuarto"], [5.5, "h2_dormido"], [7.6, "h3_alarma"], [10.3, "h4_ventisca"], [11.6, "h5_hojas"], [16.0, "h6_mapa"], [20.5, "h7_mapa_completo"], [24.5, "h8_salon"], [27.8, "h9_ranas"], [29.2, "h10_croac"], [33.6, "h11_titulo"]]:
		while is_instance_valid(historia) and historia._tiempo < t[0]:
			await get_tree().process_frame
		await _foto(t[1])
	await _esperar(2.5)
	await _sin_transicion()
	_revisar(_escena() is Juego, "la historia termina en el nivel 1")
	# Saltar la historia también lleva al nivel 1.
	await _ir("res://escenas/Historia.tscn", 1.0)
	_escena().get_node("Saltar").pressed.emit()
	await _esperar(0.8)
	await _sin_transicion()
	_revisar(_escena() is Juego, "Saltar lleva al nivel 1")

	# ----- Nivel 1: se prueba que el vigilante ve al jugador -----
	Partida.nueva_partida(1)
	await _ir("res://escenas/Juego.tscn", 1.5)
	await _foto("06_nivel1_intro")
	var juego: Juego = _escena()
	juego._continuar()
	Input.action_press("mover_der")
	await _esperar(0.8)
	Input.action_release("mover_der")
	await _esperar(0.6)
	await _foto("07_nivel1_jugando")
	await _probar_pausa(juego)
	var g: Guardia = juego.guardias[0]
	juego._invulnerable = 0.0
	var frente := g._vista.global_transform.basis.z
	frente.y = 0
	juego.jugador.global_position = g.global_position + frente.normalized() * 3.0
	await _esperar(0.4)
	_revisar(Partida.vidas == Partida.VIDAS_INICIALES - 1, "el vigilante pilla al jugador (vidas=%d)" % Partida.vidas)
	await _foto("08_nivel1_pillado")
	# Se toma un apunte de verdad caminando encima.
	var apunte_pos := juego.celda_a_mundo(Vector2i(7, 5))
	juego._invulnerable = 99.0
	juego.jugador.global_position = apunte_pos
	await _esperar(0.4)
	_revisar(juego.apuntes_tomados == 1, "recoger un apunte (tomados=%d)" % juego.apuntes_tomados)
	await _tomar_rana(juego, Vector2i(7, 8), 1)
	juego.atajo_ganar()
	await _esperar(1.6)
	await _foto("09_nivel1_victoria")
	_revisar(Partida.nivel_desbloqueado == 2, "pasar el nivel 1 desbloquea el 2")
	juego._siguiente()

	# ----- Nivel 2: Bulevar de noche -----
	juego = await _siguiente_nivel(2)
	await _foto("10_nivel2_jugando")
	if Controles.es_tactil():
		await _probar_multitouch(juego)
		await _probar_ajuste_joystick(juego)
	await _tomar_rana(juego, Vector2i(22, 7), 2)
	juego.atajo_ganar()
	await _esperar(0.5)
	juego._siguiente()

	# ----- Nivel 3: la tercera rana trae la transformación -----
	juego = await _siguiente_nivel(3)
	await _foto("11_nivel3_jugando")
	juego.jugador.global_position = juego.celda_a_mundo(Vector2i(12, 8))  # rana detrás de la puerta
	await _esperar(1.0)
	var celebracion := _buscar_celebracion()
	_revisar(celebracion != null and get_tree().paused, "la 3.ª rana muestra la transformación y pausa")
	await _foto("12_transformacion")
	await _esperar(4.6)
	await _foto("13_transformacion_completa")
	# Esc solo cierra cuando ya apareció el botón "¡Croac!": se espera a que esté activo.
	var espera_boton := 0.0
	while celebracion != null and is_instance_valid(celebracion) and celebracion._boton.disabled and espera_boton < 4.0:
		await _esperar(0.1)
		espera_boton += 0.1
	var esc := InputEventAction.new()
	esc.action = "pausa"
	esc.pressed = true
	Input.parse_input_event(esc)
	await _esperar(0.5)
	_revisar(_buscar_celebracion() == null and not get_tree().paused and juego.estado == Juego.Estado.JUGANDO,
		"Esc cierra la transformación y el juego sigue")
	_revisar(Partida.tiene_poder_rana() and juego._usos_poder == Partida.USOS_PODER, "el poder sirve desde ya")
	juego.atajo_ganar()
	await _esperar(0.5)
	juego._siguiente()

	# ----- Nivel 4: Parqueadero, con el poder de la rana -----
	juego = await _siguiente_nivel(4)
	await _foto("14_nivel4_parqueadero")
	var vidas_antes := Partida.vidas
	if Controles.es_tactil():
		# En el celular no hay tecla R: se toca el botón verde RANA.
		_revisar(juego.hud.boton_rana.visible, "el botón RANA aparece en el celular")
		var centro_rana := juego.hud.boton_rana.get_global_rect().get_center()
		_tocar(2, centro_rana, true)
		_tocar(2, centro_rana, false)
	else:
		_presionar("rana")
	await _esperar(0.4)
	_revisar(juego.jugador.es_rana and juego.jugador.collision_mask == 1, "R convierte en rana (salta los obstáculos bajos)")
	await _foto("15_rana")
	# Encima de un carro no puede volver a ser estudiante (quedaría atrapado).
	juego.jugador.global_position = juego.celda_a_mundo(Vector2i(3, 2))
	juego.jugador.rana_restante = 0.1
	await _esperar(0.5)
	_revisar(juego.jugador.es_rana, "sobre un carro sigue siendo rana hasta bajarse")
	juego.jugador.global_position = juego.celda_a_mundo(Vector2i(1, 1))
	await _esperar(0.4)
	_revisar(not juego.jugador.es_rana and juego.jugador.collision_mask == 5, "al bajarse vuelve a ser estudiante")
	# Siendo rana, el vigilante no lo reconoce.
	_presionar("rana")
	await _esperar(0.3)
	juego._invulnerable = 0.0
	var g4: Guardia = juego.guardias[0]
	var frente4 := g4._vista.global_transform.basis.z
	frente4.y = 0
	juego.jugador.global_position = g4.global_position + frente4.normalized() * 2.5
	await _esperar(0.5)
	_revisar(Partida.vidas == vidas_antes, "al vigilante no le importa una rana (vidas=%d)" % Partida.vidas)
	juego.jugador.volver_a_estudiante()
	juego._invulnerable = 99.0
	_presionar("rana")
	await _esperar(0.3)
	_revisar(not juego.jugador.es_rana and juego._usos_poder == 0, "solo 2 usos por nivel")
	juego.atajo_ganar()
	await _esperar(0.5)
	juego._siguiente()

	# ----- Nivel 5: Pasillo del Salón 304, con la Xaca Rana profe -----
	juego = await _siguiente_nivel(5)
	juego.jugador.global_position = juego.celda_a_mundo(Vector2i(10, 3))
	await _esperar(1.2)
	await _foto("16_nivel5_pasillo")
	juego.atajo_ganar()
	await _esperar(1.6)
	await _foto("17_nivel5_victoria")
	juego._siguiente()

	# ----- Final: animación del parcial -----
	await _esperar(0.8)
	await _sin_transicion()
	var final := _escena()
	_revisar(final.name == "Final", "el nivel 5 lleva a la animación del parcial")
	for t in [[2.0, "f1_salon"], [5.0, "f2_reparte"], [9.0, "f3_escribe"], [13.0, "f4_entrega"], [16.0, "f5_revisa"], [19.5, "f6_nota"]]:
		while is_instance_valid(final) and final._tiempo < t[0]:
			await get_tree().process_frame
		await _foto(t[1])
	# El parcial termina a los 24,5 s y pasa a Puntaje: se espera a la escena, no un tiempo fijo.
	var espera_final := 0.0
	while _escena().name != "Puntaje" and espera_final < 15.0:
		await _esperar(0.25)
		espera_final += 0.25
	await _sin_transicion()
	_revisar(_escena().name == "Puntaje", "el parcial lleva a Puntaje")
	var nota: float = Partida.resultado.get("nota", 0.0)
	_revisar(Partida.resultado.get("motivo") == "parcial" and nota >= 3.0 and nota <= 5.0, "nota del parcial = %.1f" % nota)
	await _foto("18_puntaje")

	# ----- Ranking en línea (Firebase): solo si se abrió con --nube=... -----
	if Nube.activa():
		var puntajes := _escena()
		var espera := 0.0
		while Nube.ultimo_id == "" and espera < 6.0:
			await _esperar(0.25)
			espera += 0.25
		_revisar(Nube.ultimo_id != "", "la nota se subió al ranking en línea")
		puntajes.find_child("EnLinea", true, false).pressed.emit()
		await _esperar(2.0)
		_revisar(puntajes._filas.get_child_count() >= 2, "el Top 10 en línea muestra a varios jugadores")
		await _foto("18b_ranking_en_linea")
	await _ir("res://escenas/Home.tscn")
	_revisar(_escena()._escena_3d.has_node("RanaDorada"), "con las 3 ranas aparece la rana dorada en el menú")

	# ----- Pausa -> Ir al menú -----
	Partida.nueva_partida(1)
	await _ir("res://escenas/Juego.tscn", 1.5)
	juego = _escena()
	juego._continuar()
	await _esperar(0.3)
	_presionar("pausa")
	await _esperar(0.4)
	juego.hud._capa_modal.find_child("IrAlMenu", true, false).pressed.emit()
	await _esperar(0.8)
	await _sin_transicion()
	_revisar(_escena().name == "Home" and not get_tree().paused, "desde la pausa se puede ir al menú")

	# ----- Derrota por tiempo -----
	Partida.nueva_partida(1)
	await _ir("res://escenas/Juego.tscn", 1.5)
	juego = _escena()
	juego._continuar()
	juego.tiempo_restante = 0.3
	await _esperar(1.0)
	await _foto("16_derrota")
	_revisar(juego.estado == Juego.Estado.PERDIDO, "perder por tiempo")

	# ----- Persistencia -----
	var cfg := ConfigFile.new()
	_revisar(cfg.load(Partida.RUTA) == OK and cfg.get_value("progreso", "nivel_desbloqueado", 0) == 6, "progreso guardado en disco")

	print("[recorrido] TERMINADO con %d fallas" % _errores.size())
	get_tree().quit(1 if _errores.size() > 0 else 0)
