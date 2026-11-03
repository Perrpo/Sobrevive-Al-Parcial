extends Node
## Define las teclas del juego al arrancar.
## Se hace por código (y no en project.godot) para que sea fácil de leer y cambiar.

const TECLAS := {
	"mover_arriba": [KEY_W, KEY_UP],
	"mover_abajo": [KEY_S, KEY_DOWN],
	"mover_izq": [KEY_A, KEY_LEFT],
	"mover_der": [KEY_D, KEY_RIGHT],
	"correr": [KEY_SHIFT],
	"pausa": [KEY_ESCAPE, KEY_P],
	"rana": [KEY_R],  # poder de la Xaca Rana
}


func _ready() -> void:
	for accion in TECLAS:
		if not InputMap.has_action(accion):
			InputMap.add_action(accion, 0.2)
		for tecla in TECLAS[accion]:
			var evento := InputEventKey.new()
			evento.physical_keycode = tecla
			InputMap.action_add_event(accion, evento)


## true si el juego corre en un celular o tablet (para mostrar los controles táctiles).
## En el PC se puede probar con: godot --path . -- --tactil
func es_tactil() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") \
		or "--tactil" in OS.get_cmdline_user_args()
