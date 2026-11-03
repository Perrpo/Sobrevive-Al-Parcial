class_name Estudiante
extends AnimatableBody3D
## Estudiante de la cafetería que va y viene entre dos puntos.
## Es un obstáculo que se mueve: empuja al jugador y le estorba el paso.

const CAMISAS := [Color("#C0504D"), Color("#70AD47"), Color("#E0A458"), Color("#9B6BD1"), Color("#4BACC6")]

var velocidad := 1.6
var _camino := PackedVector3Array()
var _i := 0
var _adelante := true
var _modelo: Node3D
var _paso := 0.0


func iniciar(camino: PackedVector3Array, color: int) -> void:
	_camino = camino
	global_position = camino[0]
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	var forma := CollisionShape3D.new()
	var cilindro := CylinderShape3D.new()
	cilindro.radius = 0.4
	cilindro.height = 1.8
	forma.shape = cilindro
	forma.position.y = 0.9
	add_child(forma)
	_modelo = Constructor.estudiante(CAMISAS[color % CAMISAS.size()], Color("#182742"))
	add_child(_modelo)
	velocidad = 1.4 + (color % 3) * 0.25


func _physics_process(delta: float) -> void:
	if _camino.size() < 2:
		return
	var objetivo := _camino[_i]
	var diferencia := objetivo - global_position
	diferencia.y = 0.0
	var paso := velocidad * delta
	if diferencia.length() <= paso:
		global_position = objetivo
		if _adelante:
			_i += 1
			if _i >= _camino.size():
				_i = _camino.size() - 2
				_adelante = false
		else:
			_i -= 1
			if _i < 0:
				_i = 1
				_adelante = true
	else:
		global_position += diferencia.normalized() * paso
		_modelo.rotation.y = lerp_angle(_modelo.rotation.y, atan2(diferencia.x, diferencia.z), minf(1.0, delta * 10.0))
		_paso += delta * velocidad * 3.0
		(_modelo.get_node("PiernaI") as Node3D).position.z = sin(_paso) * 0.14
		(_modelo.get_node("PiernaD") as Node3D).position.z = -sin(_paso) * 0.14
