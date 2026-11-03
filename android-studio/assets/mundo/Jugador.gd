class_name Jugador
extends CharacterBody3D
## El estudiante que maneja el jugador.
## Se mueve con W A S D o flechas (o el joystick en el celular) y corre con Shift.
## Correr hace ruido: los vigilantes cercanos vienen a ver qué pasó.
## Con un tinto corre más rápido y sin hacer ruido durante unos segundos.
## Con el poder de la Xaca Rana se vuelve rana: rápido, silencioso, los vigilantes no lo
## reconocen y salta por encima de los obstáculos bajos (capa de colisión 3).

signal hizo_ruido(posicion: Vector3)
signal cambio_de_forma(es_rana: bool)

## Capas de colisión: 1 = paredes y cosas altas, 3 (valor 4) = obstáculos bajos (mesas, jardineras, carros).
const CAPA_MUNDO := 1
const CAPA_BAJOS := 4

const VELOCIDAD := 4.4
const VELOCIDAD_CORRER := 7.2
const VELOCIDAD_TINTO := 8.4
const DURACION_TINTO := 6.0
const VELOCIDAD_RANA := 7.0

var modelo: Node3D
var modelo_rana: Node3D
var controles_activos := false
var tinto_restante := 0.0
var es_rana := false
var rana_restante := 0.0
## Los controles táctiles escriben aquí (ver Hud.gd).
var direccion_tactil := Vector2.ZERO
var correr_tactil := false

var _paso := 0.0
var _siguiente_pisada := PI
var _espera_ruido := 0.0
var _parpadeo := 0.0
var _capsula: CapsuleShape3D


func _ready() -> void:
	collision_layer = 2
	collision_mask = CAPA_MUNDO | CAPA_BAJOS
	var forma := CollisionShape3D.new()
	_capsula = CapsuleShape3D.new()
	_capsula.radius = 0.38
	_capsula.height = 1.7
	forma.shape = _capsula
	forma.position.y = 0.85
	add_child(forma)
	modelo = Constructor.estudiante()
	add_child(modelo)
	modelo_rana = Constructor.rana()
	modelo_rana.scale = Vector3.ONE * 1.8
	modelo_rana.visible = false
	add_child(modelo_rana)


func _physics_process(delta: float) -> void:
	var entrada := Input.get_vector("mover_izq", "mover_der", "mover_arriba", "mover_abajo")
	if direccion_tactil.length() > 0.15:
		entrada = direccion_tactil
	if not controles_activos:
		entrada = Vector2.ZERO
	var moviendose := entrada.length() > 0.1
	var corre := moviendose and (Input.is_action_pressed("correr") or correr_tactil)

	var rapidez := VELOCIDAD
	if es_rana:
		rana_restante -= delta
		rapidez = VELOCIDAD_RANA
		if rana_restante <= 0.0 and _puede_volver():
			volver_a_estudiante()
	elif tinto_restante > 0.0:
		tinto_restante -= delta
		rapidez = VELOCIDAD_TINTO
	elif corre:
		rapidez = VELOCIDAD_CORRER

	var direccion := Vector3(entrada.x, 0.0, entrada.y).limit_length(1.0)
	velocity = direccion * rapidez
	move_and_slide()
	position.y = 0.0

	_animar(delta, direccion, rapidez, moviendose)

	# Correr sin tinto hace ruido.
	_espera_ruido -= delta
	if corre and tinto_restante <= 0.0 and not es_rana and _espera_ruido <= 0.0:
		_espera_ruido = 0.35
		hizo_ruido.emit(global_position)


func _animar(delta: float, direccion: Vector3, rapidez: float, moviendose: bool) -> void:
	if es_rana:
		_animar_rana(delta, direccion, moviendose)
		return
	var pierna_i: Node3D = modelo.get_node("PiernaI")
	var pierna_d: Node3D = modelo.get_node("PiernaD")
	var cuerpo: Node3D = modelo.get_node("Cuerpo")
	if moviendose:
		modelo.rotation.y = lerp_angle(modelo.rotation.y, atan2(direccion.x, direccion.z), minf(1.0, delta * 12.0))
		_paso += delta * rapidez * 2.4
		pierna_i.position.z = sin(_paso) * 0.16
		pierna_d.position.z = -sin(_paso) * 0.16
		cuerpo.position.y = 0.78 + absf(sin(_paso)) * 0.06
		if _paso >= _siguiente_pisada:
			_siguiente_pisada += PI
			Audio.efecto("paso", randf_range(0.9, 1.15), -8.0 if rapidez <= VELOCIDAD else -2.0)
	else:
		pierna_i.position.z = lerpf(pierna_i.position.z, 0.0, delta * 10.0)
		pierna_d.position.z = lerpf(pierna_d.position.z, 0.0, delta * 10.0)
		cuerpo.position.y = 0.78 + sin(Time.get_ticks_msec() / 400.0) * 0.015  # respira

	_actualizar_parpadeo(delta, modelo)


## Parpadea mientras es invulnerable (después de que lo pillan).
func _actualizar_parpadeo(delta: float, visible_ahora: Node3D) -> void:
	if _parpadeo > 0.0:
		_parpadeo -= delta
		visible_ahora.visible = int(_parpadeo * 12.0) % 2 == 0
	else:
		visible_ahora.visible = true


## La rana avanza a saltitos.
func _animar_rana(delta: float, direccion: Vector3, moviendose: bool) -> void:
	if moviendose:
		modelo_rana.rotation.y = lerp_angle(modelo_rana.rotation.y, atan2(direccion.x, direccion.z), minf(1.0, delta * 12.0))
		_paso += delta * 9.0
		var salto := absf(sin(_paso))
		modelo_rana.position.y = salto * 0.9  # alto, para que se vea que pasa por encima
		if _paso >= _siguiente_pisada:
			_siguiente_pisada += PI
			Audio.efecto("paso", 1.6, -12.0)
	else:
		modelo_rana.position.y = lerpf(modelo_rana.position.y, 0.0, delta * 10.0)
	_actualizar_parpadeo(delta, modelo_rana)


func convertir_en_rana(segundos: float) -> void:
	es_rana = true
	rana_restante = segundos
	collision_mask = CAPA_MUNDO  # ya no choca con los obstáculos bajos: los salta
	_cambiar_modelo(modelo, modelo_rana)
	Audio.efecto("rana")
	cambio_de_forma.emit(true)


func volver_a_estudiante() -> void:
	es_rana = false
	rana_restante = 0.0
	collision_mask = CAPA_MUNDO | CAPA_BAJOS
	_cambiar_modelo(modelo_rana, modelo)
	cambio_de_forma.emit(false)


## Animación de "puf": el modelo viejo se encoge y el nuevo crece con rebote.
func _cambiar_modelo(viejo: Node3D, nuevo: Node3D) -> void:
	var escala_nuevo := nuevo.scale
	viejo.visible = false
	nuevo.visible = true
	nuevo.scale = escala_nuevo * 0.1
	var t := nuevo.create_tween()
	t.tween_property(nuevo, "scale", escala_nuevo, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## No puede volver a ser estudiante si está encima de una mesa o jardinera (quedaría atrapado).
func _puede_volver() -> bool:
	var consulta := PhysicsShapeQueryParameters3D.new()
	consulta.shape = _capsula
	consulta.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.85, 0))
	consulta.collision_mask = CAPA_BAJOS
	return get_world_3d().direct_space_state.intersect_shape(consulta, 1).is_empty()


func tomar_tinto() -> void:
	tinto_restante = DURACION_TINTO


func parpadear(segundos: float) -> void:
	_parpadeo = segundos
