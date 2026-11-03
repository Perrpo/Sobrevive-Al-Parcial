class_name Guardia
extends Node3D
## Vigilante (o bibliotecaria, o señor del aseo) que patrulla una ruta.
##
## Visión: ve al jugador si está dentro de su cono de linterna (distancia y ángulo)
## y no hay una pared o estante en medio (se comprueba con un rayo de física).
## Oído: si el jugador corre cerca, va a investigar ese punto y luego vuelve a su ruta.
## Para moverse sin atravesar estantes usa el buscador de caminos del nivel (AStarGrid2D).

signal vio_al_jugador(guardia: Guardia)

const ALCANCE := 8.0
const APERTURA := 0.5  # radianes a cada lado (unos 29°)
const OIDO := 10.0

var tipo := "vigilante"
var velocidad := 2.4
var ruta: Array[Vector3] = []
var jugador: Node3D
var juego: Node  # el nivel, para pedirle caminos

var _modelo: Node3D
var _vista: Node3D
var _alerta: Label3D
var _camino := PackedVector3Array()
var _i_camino := 0
var _i_ruta := 0
var _investigando := false
var _espera := 0.0
var _tiempo := 0.0


func iniciar(p_tipo: String, p_velocidad: float, p_ruta: Array[Vector3], p_jugador: Node3D, p_juego: Node, modo_profe: bool) -> void:
	tipo = p_tipo
	velocidad = p_velocidad
	ruta = p_ruta
	jugador = p_jugador
	juego = p_juego
	global_position = ruta[0]

	_modelo = Constructor.vigilante(tipo, modo_profe)
	add_child(_modelo)

	# "Vista": el cono de luz en el piso y la linterna giran juntos.
	_vista = Node3D.new()
	add_child(_vista)
	_vista.add_child(Constructor.cono_vision(ALCANCE, APERTURA, Color("#FFE14D")))
	var linterna := SpotLight3D.new()
	linterna.light_color = Color("#FFE7A0")
	linterna.light_energy = 2.2
	linterna.spot_range = ALCANCE + 2.0
	linterna.spot_angle = rad_to_deg(APERTURA) + 4.0
	linterna.shadow_enabled = false
	linterna.transform = Transform3D(Basis.looking_at(Vector3(0, -1.2, 4).normalized(), Vector3.UP), Vector3(0, 1.4, 0.3))
	_vista.add_child(linterna)

	_alerta = Label3D.new()
	_alerta.text = "?"
	_alerta.font = Estilo.fuente_titulo
	_alerta.font_size = 160
	_alerta.modulate = Color("#FFE14D")
	_alerta.outline_size = 24
	_alerta.outline_modulate = Color("#10182B")
	_alerta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_alerta.position.y = 2.7
	_alerta.visible = false
	add_child(_alerta)

	if ruta.size() > 1:
		_i_ruta = 1
		_camino = juego.camino(global_position, ruta[_i_ruta])


func _physics_process(delta: float) -> void:
	if jugador == null:
		return
	_tiempo += delta
	# Mueve la linterna de lado a lado, como buscando.
	_vista.rotation.y = sin(_tiempo * 1.6) * 0.35
	_modelo.position.y = absf(sin(_tiempo * 6.0)) * 0.04

	if _espera > 0.0:
		_espera -= delta
		_vista.rotation.y = sin(_tiempo * 3.0) * 0.7  # mira para todos lados
	else:
		_caminar(delta)
	_revisar_vision()


func _caminar(delta: float) -> void:
	if _i_camino >= _camino.size():
		_siguiente_destino()
		return
	var objetivo := _camino[_i_camino]
	var diferencia := objetivo - global_position
	diferencia.y = 0.0
	var paso := velocidad * (1.5 if _investigando else 1.0) * delta
	if diferencia.length() <= paso:
		global_position = Vector3(objetivo.x, 0.0, objetivo.z)
		_i_camino += 1
	else:
		global_position += diferencia.normalized() * paso
		rotation.y = lerp_angle(rotation.y, atan2(diferencia.x, diferencia.z), minf(1.0, delta * 8.0))


func _siguiente_destino() -> void:
	if _investigando:
		_investigando = false
		_alerta.visible = false
		_espera = 1.6
		_camino = juego.camino(global_position, ruta[_i_ruta])
	else:
		if ruta.size() <= 1:
			_espera = 2.0
			return
		_i_ruta = (_i_ruta + 1) % ruta.size()
		_camino = juego.camino(global_position, ruta[_i_ruta])
	_i_camino = 0


func _revisar_vision() -> void:
	var hacia := jugador.global_position - global_position
	hacia.y = 0.0
	var distancia := hacia.length()
	if distancia > ALCANCE:
		return
	var adelante := _vista.global_transform.basis.z
	adelante.y = 0.0
	if distancia > 1.2 and adelante.angle_to(hacia) > APERTURA:
		return
	# ¿Hay algo en medio? El rayo choca con el mundo: paredes, estantes y puertas (capa 1)
	# y obstáculos bajos como jardineras y carros (capa 3, valor 4).
	var consulta := PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 1.3, 0), jugador.global_position + Vector3(0, 1.0, 0), 1 | 4)
	if get_world_3d().direct_space_state.intersect_ray(consulta).is_empty():
		vio_al_jugador.emit(self)


## El jugador hizo ruido en [param posicion]: si está cerca, va a ver.
func escuchar(posicion: Vector3) -> void:
	if global_position.distance_to(posicion) > OIDO or _investigando:
		return
	_investigando = true
	_espera = 0.4
	_alerta.visible = true
	_alerta.scale = Vector3.ONE * 0.2
	create_tween().tween_property(_alerta, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_camino = juego.camino(global_position, posicion)
	_i_camino = 0


## Después de pillar al jugador se queda quieto un momento.
func aturdir(segundos: float) -> void:
	_espera = segundos
	_investigando = false
	_alerta.visible = false
