class_name Juego
extends Node3D
## Un nivel del juego. Lee el mapa de texto de DatosNiveles y arma el mundo 3D:
## paredes, estantes, mesas, apuntes, puertas, vigilantes y estudiantes.
##
## Reglas:
##  - Hay que juntar todos los apuntes (A) para que se abra la SALIDA (S).
##  - Si un vigilante te ve, pierdes una vida y vuelves al inicio.
##  - Si se acaba el tiempo o las vidas, pierdes.
##  - Puntaje del nivel = 1000 + segundos sobrantes × 5 + vidas × 150.
##  - En los niveles 1, 2 y 3 hay una Xaca Rana escondida (+1 vida). Con las 3, en los
##    niveles 4 y 5 se puede usar el poder de la rana (tecla R): ver Jugador.gd.

const ESCENA_JUEGO := "res://escenas/Juego.tscn"
const ESCENA_FINAL := "res://escenas/Final.tscn"
## Capa de colisión de los obstáculos bajos (mesas, jardineras, carros, bancas):
## tapan la vista de los vigilantes y el estudiante choca con ellos, pero la rana los salta.
const CAPA_BAJOS := 4
const ALTO_PARED := 2.2
const INVULNERABLE := 2.5
const CAMARA := Vector3(0, 13, 6)
const CAMARA_OSCURO := Vector3(0, 11, 5)

enum Estado { INTRO, JUGANDO, GANADO, PERDIDO }

var numero := 1
var datos: Dictionary
var estado := Estado.INTRO
var tiempo_restante := 0.0
var apuntes_total := 0
var apuntes_tomados := 0

var jugador: Jugador
var hud: Hud
var guardias: Array[Guardia] = []

var _mundo: Node3D
var _camara: Camera3D
var _astar := AStarGrid2D.new()
var _columnas := 0
var _filas := 0
var _inicio := Vector3.ZERO
var _invulnerable := 0.0
var _puertas: Array[Node3D] = []
var _salida: Node3D
var _salida_abierta := false
var _vidas_al_empezar := 0
var _apuntes_al_empezar := 0
var _ultimo_motivo := ""
var _usos_poder := 0
var _poder_activo_antes := false


func _ready() -> void:
	# Este nodo sigue funcionando en pausa (para quitarla); el mundo sí se congela.
	process_mode = Node.PROCESS_MODE_ALWAYS
	numero = clampi(Partida.nivel_actual, 1, Partida.NIVELES)
	datos = DatosNiveles.nivel(numero)
	tiempo_restante = datos["tiempo"]
	_vidas_al_empezar = Partida.vidas
	_apuntes_al_empezar = Partida.apuntes_juntados

	_mundo = Node3D.new()
	_mundo.name = "Mundo"
	_mundo.process_mode = Node.PROCESS_MODE_DISABLED  # quieto mientras se lee la presentación
	add_child(_mundo)

	_crear_ambiente()
	_construir_mapa()
	_crear_personajes()
	_crear_camara()

	hud = Hud.new()
	add_child(hud)
	hud.poner_vidas(Partida.vidas)
	hud.poner_apuntes(0, apuntes_total)
	hud.poner_tiempo(tiempo_restante)
	hud.poner_nivel("Nivel %d · %s" % [numero, datos["nombre"]])
	hud.pidio_continuar.connect(_continuar)
	hud.pidio_reiniciar.connect(_reiniciar)
	hud.pidio_menu.connect(_ir_al_menu)
	hud.pidio_siguiente.connect(_siguiente)
	hud.pidio_puntajes.connect(_ver_puntajes)
	hud.pidio_poder.connect(_usar_poder)
	Partida.huevos_completos.connect(_al_ganar_poder)
	if Partida.tiene_poder_rana():
		_usos_poder = Partida.USOS_PODER
		hud.poner_poder(_usos_poder, 0.0)
	hud.presentar_nivel(numero, datos, apuntes_total, _texto_ranas())

	Audio.musica("juego")
	Audio.efecto("timbre", 1.0, -6.0)


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_seguir_con_camara(delta)
	if estado != Estado.JUGANDO:
		return
	if hud.joystick:
		jugador.direccion_tactil = hud.joystick.direccion
		jugador.correr_tactil = hud.boton_correr.presionado
	if jugador.es_rana:
		hud.poner_poder(_usos_poder, maxf(jugador.rana_restante, 0.1))
	elif Partida.tiene_poder_rana() and _poder_activo_antes:
		hud.poner_poder(_usos_poder, 0.0)
	_poder_activo_antes = jugador.es_rana
	tiempo_restante -= delta
	hud.poner_tiempo(tiempo_restante)
	hud.poner_tinto(jugador.tinto_restante)
	_invulnerable = maxf(0.0, _invulnerable - delta)
	if tiempo_restante <= 0.0:
		_perder("tiempo")


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("rana") and not get_tree().paused:
		_usar_poder()
		get_viewport().set_input_as_handled()
		return
	if not evento.is_action_pressed("pausa"):
		return
	if hud.ajustando_joystick:
		get_viewport().set_input_as_handled()
		return  # primero hay que darle "Listo" al ajuste del joystick
	if estado == Estado.JUGANDO and not get_tree().paused:
		get_tree().paused = true
		hud.mostrar_pausa()
	elif get_tree().paused:
		_continuar()
	get_viewport().set_input_as_handled()


# ---------- Construcción del nivel ----------

## Centro de una celda del mapa en el mundo 3D.
func celda_a_mundo(celda: Vector2i) -> Vector3:
	return Vector3(celda.x * DatosNiveles.CELDA, 0.0, celda.y * DatosNiveles.CELDA)


func mundo_a_celda(pos: Vector3) -> Vector2i:
	return Vector2i(roundi(pos.x / DatosNiveles.CELDA), roundi(pos.z / DatosNiveles.CELDA))


func _crear_ambiente() -> void:
	var oscuro: bool = datos["oscuro"]
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = datos.get("cielo", Estilo.PANTALLA)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = datos["ambiente"]
	entorno.ambient_light_energy = datos.get("luz_ambiente", 0.45 if oscuro else 1.0)
	entorno.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var mundo_entorno := WorldEnvironment.new()
	mundo_entorno.environment = entorno
	add_child(mundo_entorno)

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-72, 20, 0)
	sol.light_energy = datos.get("luz_sol", 0.18 if oscuro else 0.8)
	sol.light_color = Color("#8FA3FF") if oscuro else Color("#FFF4E0")
	sol.shadow_enabled = true
	sol.shadow_opacity = 0.6
	sol.directional_shadow_max_distance = 40.0
	add_child(sol)


func _construir_mapa() -> void:
	var mapa: PackedStringArray = datos["mapa"]
	_filas = mapa.size()
	_columnas = mapa[0].length()
	var rng := RandomNumberGenerator.new()
	rng.seed = numero * 1234  # mismos libros cada vez que se juega el nivel

	_astar.region = Rect2i(0, 0, _columnas, _filas)
	_astar.cell_size = Vector2.ONE
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()

	_crear_piso()
	if _es_exterior():
		_decorar_exterior(rng)

	for f in _filas:
		var fila := mapa[f]
		var c := 0
		while c < _columnas:
			var letra := fila[c]
			# Paredes, estantes y barras seguidas se unen en una sola pieza (menos objetos = más rápido).
			if letra in ["#", "E", "B", "G", "L"]:
				var largo := 1
				while c + largo < _columnas and fila[c + largo] == letra:
					largo += 1
				_crear_bloque(letra, Vector2i(c, f), largo, rng)
				for k in largo:
					_astar.set_point_solid(Vector2i(c + k, f), true)
				c += largo
				continue
			var pos := celda_a_mundo(Vector2i(c, f))
			match letra:
				"M":
					_astar.set_point_solid(Vector2i(c, f), true)
					if _es_bulevar():
						_crear_solido(Constructor.mesa_bulevar(rng), pos, Vector3(1.5, 1.0, 1.9), CAPA_BAJOS)
					else:
						_crear_solido(Constructor.mesa(), pos, Vector3(1.9, 1.0, 1.5), CAPA_BAJOS)
				"C":
					_astar.set_point_solid(Vector2i(c, f), true)
					_crear_solido(Constructor.columna(rng), pos, Vector3(0.45, 3.6, 0.45))
				"J":
					_astar.set_point_solid(Vector2i(c, f), true)
					_crear_solido(Constructor.jardinera(rng), pos, Vector3(1.8, 1.6, 1.8), CAPA_BAJOS)
				"K":
					_astar.set_point_solid(Vector2i(c, f), true)
					_crear_solido(Constructor.carro(rng), pos, Vector3(1.6, 1.3, 1.9), CAPA_BAJOS)
				"N":
					_astar.set_point_solid(Vector2i(c, f), true)
					_crear_solido(Constructor.banca(), pos, Vector3(1.9, 1.0, 0.7), CAPA_BAJOS)
				"P":
					_inicio = pos
				"A":
					apuntes_total += 1
					_crear_objeto(Constructor.apunte(), pos, _tomar_apunte, true)
				"T":
					_crear_objeto(Constructor.tinto(), pos, _tomar_tinto, false)
				"R":
					# Si ya la encontró en esta partida (y está repitiendo el nivel), no aparece.
					if not Partida.ranas_partida.has(datos.get("rana", "")):
						_crear_objeto(Constructor.rana(), pos, _tomar_rana, false)
				"D":
					_astar.set_point_solid(Vector2i(c, f), true)
					_crear_puerta(Vector2i(c, f), mapa)
				"S":
					_astar.set_point_solid(Vector2i(c, f), true)
					_crear_salida(Vector2i(c, f), mapa)
			c += 1


func _es_bulevar() -> bool:
	return datos.get("estilo", "") == "bulevar"


## Niveles al aire libre: borde con plantas, pasto y árboles alrededor.
func _es_exterior() -> bool:
	return datos.get("estilo", "") in ["bulevar", "parqueadero"]


## Piso con una textura hecha por código: baldosas, o adoquines largos en el bulevar.
func _crear_piso() -> void:
	var color: Color = datos["piso"]
	var img: Image
	var escala := Vector3(_columnas, _filas, 1)
	if _es_bulevar():
		img = _textura_adoquines(color)
		escala = Vector3(_columnas / 2.0, _filas / 2.0, 1)  # la textura cubre 2 × 2 celdas
	elif datos.get("estilo", "") == "parqueadero":
		img = _textura_asfalto(color)
	else:
		img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(color)
		for i in 64:
			for borde in [0, 1]:
				img.set_pixel(i, borde, color.darkened(0.25))
				img.set_pixel(borde, i, color.darkened(0.25))
	img.generate_mipmaps()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.uv1_scale = escala
	mat.roughness = 0.9
	var piso := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(_columnas, _filas) * DatosNiveles.CELDA
	piso.mesh = plano
	piso.material_override = mat
	piso.position = Vector3((_columnas - 1) * DatosNiveles.CELDA / 2.0, 0.0, (_filas - 1) * DatosNiveles.CELDA / 2.0)
	_mundo.add_child(piso)


func _crear_bloque(letra: String, celda: Vector2i, largo: int, rng: RandomNumberGenerator) -> void:
	var ancho := largo * DatosNiveles.CELDA
	var centro := celda_a_mundo(celda) + Vector3((largo - 1) * DatosNiveles.CELDA / 2.0, 0, 0)
	match letra:
		"#" when _es_exterior():
			# Afuera no hay paredes: el borde es un muro bajo con plantas.
			var borde := _crear_solido(Constructor.seto(ancho, rng), centro, Vector3(ancho, ALTO_PARED, DatosNiveles.CELDA))
			borde.name = "Seto"
		"B" when _es_bulevar():
			_crear_solido(Constructor.kiosko(ancho - 0.2), centro, Vector3(ancho, 1.2, 1.45), CAPA_BAJOS)
		"G":
			_crear_solido(Constructor.garita(ancho), centro, Vector3(ancho - 0.4, 2.4, 1.6))
		"L":
			_crear_solido(Constructor.casilleros(ancho, rng), centro, Vector3(ancho, 2.0, 1.0))
		"#":
			var cuerpo := _crear_solido(Node3D.new(), centro, Vector3(ancho, ALTO_PARED, DatosNiveles.CELDA))
			cuerpo.add_child(Constructor.caja(Vector3(ancho, ALTO_PARED, DatosNiveles.CELDA), datos["pared"], Vector3(0, ALTO_PARED / 2.0, 0)))
			# Borde de arriba más claro para que se lea la forma desde la cámara.
			cuerpo.add_child(Constructor.caja(Vector3(ancho + 0.02, 0.06, DatosNiveles.CELDA + 0.02), Color(datos["pared"]).lightened(0.35), Vector3(0, ALTO_PARED, 0)))
		"E":
			_crear_solido(Constructor.estante(ancho - 0.3, rng), centro, Vector3(ancho - 0.3, 2.6, 1.1))
		"B":
			var barra := _crear_solido(Node3D.new(), centro, Vector3(ancho, 1.1, 1.6))
			barra.add_child(Constructor.caja(Vector3(ancho, 1.0, 1.4), Color("#8A5A3B"), Vector3(0, 0.5, 0)))
			barra.add_child(Constructor.caja(Vector3(ancho, 0.1, 1.6), Color("#D9C7A7"), Vector3(0, 1.05, 0)))


## Adoquines grises largos con algunas franjas claras, como el piso del bulevar.
func _textura_adoquines(color: Color) -> Image:
	var tam := 256
	var img := Image.create(tam, tam, false, Image.FORMAT_RGBA8)
	img.fill(color.darkened(0.35))  # junta entre adoquines
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var alto_fila := 8
	for fila in tam / alto_fila:
		var x := -rng.randi_range(0, 40)
		var y := fila * alto_fila
		while x < tam:
			var largo := rng.randi_range(22, 46)
			var tono := color.darkened(rng.randf_range(0.0, 0.3)) if rng.randf() < 0.6 else color.lightened(rng.randf_range(0.0, 0.15))
			if rng.randf() < 0.06:
				tono = Color("#CFCDC6")  # franjas claras
			img.fill_rect(Rect2i(maxi(x, 0) + 1, y + 1, mini(largo, tam - maxi(x, 0)) - 2, alto_fila - 2), tono)
			x += largo
	return img


## Asfalto gris con una línea blanca de parqueo en el borde de cada celda.
func _textura_asfalto(color: Color) -> Image:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for x in 64:
		for y in 64:
			img.set_pixel(x, y, color.lightened(rng.randf_range(-0.06, 0.06)))
	img.fill_rect(Rect2i(0, 0, 3, 64), Color("#E6E4DE"))
	return img


func _decorar_exterior(rng: RandomNumberGenerator) -> void:
	var ancho := _columnas * DatosNiveles.CELDA
	var largo := _filas * DatosNiveles.CELDA
	# Pasto alrededor, para que no se vea el vacío.
	var pasto := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(ancho + 60, largo + 60)
	pasto.mesh = plano
	pasto.material_override = Constructor.material(Color("#5C7A45"))
	pasto.position = Vector3(ancho / 2.0 - 1, -0.03, largo / 2.0 - 1)
	_mundo.add_child(pasto)
	# Edificio blanco al fondo (norte).
	var edificio := Constructor.caja(Vector3(ancho + 10, 7, 4), Color("#E9E6E0"), Vector3(ancho / 2.0 - 1, 3.5, -4.5))
	_mundo.add_child(edificio)
	_mundo.add_child(Constructor.caja(Vector3(ancho + 10, 1.2, 0.1), Color("#2E3A4A"), Vector3(ancho / 2.0 - 1, 4.6, -2.45)))
	# Árboles grandes a los lados (no al sur, para que no tapen la cámara).
	for z in range(2, int(largo), 7):
		for x in [-8.0, ancho + 6.0]:
			var a := Constructor.arbol(rng)
			a.position = Vector3(x + rng.randf_range(-1, 1), 0, z + rng.randf_range(-1, 1))
			_mundo.add_child(a)
	if not _es_bulevar():
		return
	# Tubos de luz del techo en filas, como en las fotos.
	for f in range(1, _filas - 1, 2):
		for c in range(1, _columnas - 1, 2):
			var tubo := Constructor.lampara()
			tubo.position = celda_a_mundo(Vector2i(c, f)) + Vector3(DatosNiveles.CELDA / 2.0, 3.8, DatosNiveles.CELDA / 2.0)
			_mundo.add_child(tubo)


## Cuerpo estático (choca con jugador y con la vista de los vigilantes) con un modelo encima.
func _crear_solido(modelo: Node3D, pos: Vector3, tam: Vector3, capa: int = 1) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.collision_layer = capa
	cuerpo.collision_mask = 0
	cuerpo.position = pos
	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = tam
	forma.shape = caja
	forma.position.y = tam.y / 2.0
	cuerpo.add_child(forma)
	cuerpo.add_child(modelo)
	_mundo.add_child(cuerpo)
	return cuerpo


## Objeto que se recoge al tocarlo (apunte, tinto, rana...). Gira y flota.
func _crear_objeto(modelo: Node3D, pos: Vector3, al_tomar: Callable, flota: bool) -> void:
	var zona := Area3D.new()
	zona.collision_layer = 0
	zona.collision_mask = 2  # solo el jugador
	zona.position = pos
	var forma := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.9
	forma.shape = esfera
	forma.position.y = 0.8
	zona.add_child(forma)
	modelo.position.y = 1.0 if flota else 0.0
	zona.add_child(modelo)
	_mundo.add_child(zona)
	var giro := modelo.create_tween().set_loops()
	giro.tween_property(modelo, "rotation:y", TAU, 2.4).as_relative()
	if flota:
		var flote := modelo.create_tween().set_loops()
		flote.tween_property(modelo, "position:y", 1.25, 0.9).set_trans(Tween.TRANS_SINE)
		flote.tween_property(modelo, "position:y", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	zona.body_entered.connect(func(cuerpo: Node3D):
		if cuerpo is Jugador and estado == Estado.JUGANDO:
			al_tomar.call(zona))


func _es_pasillo_vertical(celda: Vector2i, mapa: PackedStringArray) -> bool:
	# Si arriba y abajo hay piso, el paso es vertical: la puerta se pone "de lado".
	var arriba := mapa[celda.y - 1][celda.x] if celda.y > 0 else "#"
	return arriba != "#"


func _crear_puerta(celda: Vector2i, mapa: PackedStringArray) -> void:
	var pos := celda_a_mundo(celda)
	var vertical := _es_pasillo_vertical(celda, mapa)
	var tam := Vector3(DatosNiveles.CELDA, ALTO_PARED, 0.3) if vertical else Vector3(0.3, ALTO_PARED, DatosNiveles.CELDA)
	var puerta := _crear_solido(Node3D.new(), pos, tam)
	puerta.add_child(Constructor.caja(tam, Color("#8C3B2E"), Vector3(0, ALTO_PARED / 2.0, 0)))
	var aviso := Label3D.new()
	aviso.text = "Código: %d apuntes" % datos["puerta_requiere"]
	aviso.font = Estilo.fuente_negrita
	aviso.font_size = 56
	aviso.outline_size = 14
	aviso.modulate = Estilo.RESALTADOR
	aviso.outline_modulate = Estilo.PANTALLA
	aviso.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	aviso.position.y = ALTO_PARED + 0.6
	puerta.add_child(aviso)
	puerta.set_meta("celda", celda)
	_puertas.append(puerta)


func _crear_salida(celda: Vector2i, mapa: PackedStringArray) -> void:
	var pos := celda_a_mundo(celda)
	# La salida está en el borde: el pasillo viene de adentro hacia afuera.
	var vertical := celda.y == 0 or celda.y == _filas - 1
	var tam := Vector3(DatosNiveles.CELDA, ALTO_PARED, 0.4) if vertical else Vector3(0.4, ALTO_PARED, DatosNiveles.CELDA)
	_salida = _crear_solido(Node3D.new(), pos, tam)
	_salida.add_child(Constructor.caja(tam, Color("#B23A3A"), Vector3(0, ALTO_PARED / 2.0, 0)))
	var letrero := Label3D.new()
	letrero.text = datos.get("salida", "SALIDA")
	letrero.font = Estilo.fuente_titulo
	letrero.font_size = 96
	letrero.outline_size = 18
	letrero.modulate = Color("#FF6B72")
	letrero.outline_modulate = Estilo.PANTALLA
	letrero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	letrero.position.y = ALTO_PARED + 0.9
	letrero.name = "Letrero"
	_salida.add_child(letrero)

	# Zona de meta un poco hacia adentro, para que se active al llegar a la puerta.
	var meta := Area3D.new()
	meta.collision_layer = 0
	meta.collision_mask = 2
	meta.position = pos
	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(DatosNiveles.CELDA * 1.6, 2, DatosNiveles.CELDA * 1.6)
	forma.shape = caja
	forma.position.y = 1.0
	meta.add_child(forma)
	_mundo.add_child(meta)
	meta.body_entered.connect(func(cuerpo: Node3D):
		if cuerpo is Jugador and _salida_abierta and estado == Estado.JUGANDO:
			_ganar())


func _crear_personajes() -> void:
	jugador = Jugador.new()
	jugador.name = "Jugador"
	_mundo.add_child(jugador)
	jugador.global_position = _inicio

	if datos["oscuro"]:
		# En el nivel oscuro el estudiante lleva la linterna del celular.
		var luz := OmniLight3D.new()
		luz.light_color = Color("#CFE0FF")
		luz.light_energy = 1.6
		luz.omni_range = 7.0
		luz.position.y = 2.2
		jugador.add_child(luz)

	for g in datos["guardias"]:
		var ruta: Array[Vector3] = []
		for celda in g["ruta"]:
			ruta.append(celda_a_mundo(celda))
		var guardia := Guardia.new()
		_mundo.add_child(guardia)
		guardia.iniciar(g["tipo"], g["velocidad"], ruta, jugador, self, Partida.modo_profe)
		guardia.vio_al_jugador.connect(_pillado)
		jugador.hizo_ruido.connect(guardia.escuchar)
		guardias.append(guardia)

	var i := 0
	for par in datos["estudiantes"]:
		var estudiante := Estudiante.new()
		_mundo.add_child(estudiante)
		estudiante.iniciar(camino(celda_a_mundo(par[0]), celda_a_mundo(par[1])), i)
		i += 1


func _crear_camara() -> void:
	_camara = Camera3D.new()
	_camara.fov = 50.0
	add_child(_camara)
	_camara.global_position = jugador.global_position + _desfase_camara()
	_camara.look_at(jugador.global_position, Vector3.UP)


func _desfase_camara() -> Vector3:
	return CAMARA_OSCURO if datos["oscuro"] else CAMARA


func _seguir_con_camara(delta: float) -> void:
	var objetivo := jugador.global_position + _desfase_camara()
	_camara.global_position = _camara.global_position.lerp(objetivo, minf(1.0, delta * 5.0))
	_camara.look_at(_camara.global_position - _desfase_camara(), Vector3.UP)


# ---------- Buscador de caminos (lo usan vigilantes y estudiantes) ----------

## Camino por celdas libres desde [param desde] hasta [param hasta], en coordenadas del mundo.
func camino(desde: Vector3, hasta: Vector3) -> PackedVector3Array:
	var a := _celda_libre_cercana(mundo_a_celda(desde))
	var b := _celda_libre_cercana(mundo_a_celda(hasta))
	var resultado := PackedVector3Array()
	for celda in _astar.get_id_path(a, b):
		resultado.append(celda_a_mundo(celda))
	if resultado.is_empty():
		resultado.append(celda_a_mundo(b))
	return resultado


func _celda_libre_cercana(celda: Vector2i) -> Vector2i:
	celda = celda.clamp(Vector2i.ZERO, Vector2i(_columnas - 1, _filas - 1))
	if not _astar.is_point_solid(celda):
		return celda
	for radio in range(1, 4):
		for dx in range(-radio, radio + 1):
			for dy in range(-radio, radio + 1):
				var otra := celda + Vector2i(dx, dy)
				if _astar.is_in_boundsv(otra) and not _astar.is_point_solid(otra):
					return otra
	return celda


# ---------- Eventos del juego ----------

func _tomar_apunte(zona: Area3D) -> void:
	zona.queue_free()
	apuntes_tomados += 1
	Partida.apuntes_juntados += 1
	Audio.efecto("apunte", 1.0 + apuntes_tomados * 0.06)
	hud.poner_apuntes(apuntes_tomados, apuntes_total)
	var requiere: int = datos["puerta_requiere"]
	if requiere > 0 and apuntes_tomados == requiere:
		_abrir_puertas()
	if apuntes_tomados >= apuntes_total:
		_abrir_salida()
	elif apuntes_tomados != requiere:
		hud.avisar("Apunte %d de %d" % [apuntes_tomados, apuntes_total], 1.2)


func _abrir_puertas() -> void:
	if _puertas.is_empty():
		return
	Audio.efecto("puerta")
	hud.avisar("¡Código correcto! Se abrieron las puertas")
	for puerta in _puertas:
		_astar.set_point_solid(puerta.get_meta("celda"), false)
		for hijo in puerta.get_children():
			if hijo is CollisionShape3D:
				hijo.set_deferred("disabled", true)
		var t := puerta.create_tween()
		t.tween_property(puerta, "position:y", -ALTO_PARED - 0.1, 0.8).set_trans(Tween.TRANS_CUBIC)
	_puertas.clear()


func _abrir_salida() -> void:
	_salida_abierta = true
	Audio.efecto("puerta", 1.2)
	hud.avisar("¡Tienes todos los apuntes! Corre a la SALIDA", 3.0)
	for hijo in _salida.get_children():
		if hijo is CollisionShape3D:
			hijo.set_deferred("disabled", true)
		elif hijo is MeshInstance3D:
			hijo.visible = false
	var letrero: Label3D = _salida.get_node("Letrero")
	letrero.modulate = Color("#6BE38F")
	var luz := OmniLight3D.new()
	luz.light_color = Color("#6BE38F")
	luz.light_energy = 3.0
	luz.omni_range = 6.0
	luz.position.y = 1.5
	_salida.add_child(luz)
	var latido := letrero.create_tween().set_loops()
	latido.tween_property(letrero, "scale", Vector3.ONE * 1.2, 0.4)
	latido.tween_property(letrero, "scale", Vector3.ONE, 0.4)


func _tomar_tinto(zona: Area3D) -> void:
	zona.queue_free()
	jugador.tomar_tinto()
	Audio.efecto("tinto")
	hud.avisar("¡Tinto! Corres rápido y en silencio", 1.8)


func _tomar_rana(zona: Area3D) -> void:
	zona.queue_free()
	Audio.efecto("rana")
	Partida.vidas = mini(Partida.vidas + 1, Partida.VIDAS_MAXIMAS)
	hud.poner_vidas(Partida.vidas)
	Partida.encontrar_rana(datos.get("rana", "rana"))
	var cuantas := Partida.ranas_partida.size()
	if cuantas < Partida.HUEVOS_TOTALES:
		hud.avisar("¡Xaca Rana %d de %d! +1 vida" % [cuantas, Partida.HUEVOS_TOTALES], 2.6)
	else:
		hud.avisar("¡Las 3 Xaca Ranas! +1 vida y el poder de la rana", 2.6)
	# Con la tercera, Partida abre la animación de la transformación (CelebracionRana).


## Texto extra de la presentación del nivel sobre las ranas y el poder.
func _texto_ranas() -> String:
	if Partida.tiene_poder_rana():
		var como := "El botón verde RANA" if Controles.es_tactil() else "La tecla R"
		return "Poder de la Xaca Rana: %s te vuelve rana %d s, %d veces en este nivel." % [como, Partida.DURACION_PODER, Partida.USOS_PODER]
	if datos.has("rana") and not Partida.ranas_partida.has(datos["rana"]):
		return "Hay una Xaca Rana escondida en este nivel (llevas %d de %d)." % [Partida.ranas_partida.size(), Partida.HUEVOS_TOTALES]
	return ""


## Con la tercera rana el poder sirve desde ya (también en lo que queda de este nivel).
func _al_ganar_poder() -> void:
	_usos_poder = Partida.USOS_PODER
	hud.poner_poder(_usos_poder, 0.0)


## Poder de la Xaca Rana: el estudiante se vuelve rana por unos segundos.
func _usar_poder() -> void:
	if estado != Estado.JUGANDO or jugador.es_rana:
		return
	if not Partida.tiene_poder_rana():
		hud.avisar("Junta las 3 Xaca Ranas para tener este poder", 1.8)
		return
	if _usos_poder <= 0:
		hud.avisar("Ya usaste el poder de la rana en este nivel", 1.8)
		return
	_usos_poder -= 1
	jugador.convertir_en_rana(Partida.DURACION_PODER)
	hud.poner_poder(_usos_poder, Partida.DURACION_PODER)
	hud.avisar("¡Croac! Eres rana: los vigilantes no te reconocen", 1.8)


func _pillado(_guardia: Guardia) -> void:
	if estado != Estado.JUGANDO or _invulnerable > 0.0 or jugador.es_rana:
		return  # a la rana no la reconocen
	_invulnerable = INVULNERABLE
	Partida.vidas -= 1
	hud.poner_vidas(Partida.vidas)
	hud.destello()
	Audio.efecto("silbato")
	if Partida.vidas <= 0:
		_perder("vidas")
		return
	hud.avisar("¡Te pillaron! Vuelves a la entrada", 2.0)
	jugador.global_position = _inicio
	jugador.parpadear(INVULNERABLE)
	for g in guardias:
		g.aturdir(1.2)


func _ganar() -> void:
	estado = Estado.GANADO
	jugador.controles_activos = false
	Audio.efecto("victoria")
	var segundos := int(maxf(tiempo_restante, 0.0))
	var puntos := 1000 + segundos * 5 + Partida.vidas * 150
	if jugador.es_rana:
		jugador.volver_a_estudiante()
	hud.poner_poder(_usos_poder if Partida.tiene_poder_rana() else -1, 0.0)
	Partida.terminar_nivel(numero, puntos, float(datos["tiempo"]) - tiempo_restante, float(datos["tiempo"]))
	var detalle := [
		["Nivel completado", "1000"],
		["Tiempo sobrante (%d s × 5)" % segundos, str(segundos * 5)],
		["Vidas (%d × 150)" % Partida.vidas, str(Partida.vidas * 150)],
	]
	hud.mostrar_victoria(numero, detalle, puntos, numero >= Partida.NIVELES)


func _perder(motivo: String) -> void:
	estado = Estado.PERDIDO
	_ultimo_motivo = motivo
	jugador.controles_activos = false
	Audio.efecto("timbre" if motivo == "tiempo" else "derrota")
	hud.mostrar_derrota(motivo)


# ---------- Botones del HUD ----------

func _continuar() -> void:
	hud.cerrar_modal()
	if estado == Estado.INTRO:
		estado = Estado.JUGANDO
		_mundo.process_mode = Node.PROCESS_MODE_PAUSABLE
		jugador.controles_activos = true
		_invulnerable = 1.0
	get_tree().paused = false


func _reiniciar() -> void:
	# Se repite el nivel con las vidas y apuntes que se tenían al empezarlo.
	Partida.vidas = _vidas_al_empezar if estado != Estado.PERDIDO else Partida.VIDAS_INICIALES
	Partida.apuntes_juntados = _apuntes_al_empezar
	Transicion.ir(ESCENA_JUEGO)


func _siguiente() -> void:
	if numero >= Partida.NIVELES:
		Transicion.ir(ESCENA_FINAL)  # animación del parcial con la Xaca Rana
	else:
		Partida.nivel_actual = numero + 1
		Transicion.ir(ESCENA_JUEGO)


func _ir_al_menu() -> void:
	if estado == Estado.PERDIDO:
		Partida.registrar_resultado(false, _ultimo_motivo, 0.0)
	Audio.musica("menu")
	Transicion.ir("res://escenas/Home.tscn")


func _ver_puntajes() -> void:
	Partida.registrar_resultado(false, _ultimo_motivo, 0.0)
	Transicion.ir("res://escenas/Puntaje.tscn")


## Para las pruebas automáticas: junta todo y deja al jugador en la salida.
func atajo_ganar() -> void:
	while apuntes_tomados < apuntes_total:
		apuntes_tomados += 1
		Partida.apuntes_juntados += 1
	hud.poner_apuntes(apuntes_tomados, apuntes_total)
	_abrir_puertas()
	_abrir_salida()
	_ganar()
