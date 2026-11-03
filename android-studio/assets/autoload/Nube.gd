extends Node
## Ranking en línea con Firebase Realtime Database (bonus de multijugador).
## Cada jugador que presenta el parcial sube su nota, y todos ven el mismo Top 10.
##
## Usa la API REST de Firebase con HTTPRequest: no necesita plugins y funciona igual
## en Windows y en Android. Los pasos para crear la base de datos están en FIREBASE.md.

signal nota_enviada
signal ranking_recibido(lista: Array)
signal fallo(texto: String)

## Dirección de la base de datos. La da la consola de Firebase, en Realtime Database.
## Ejemplo: "https://sobrevive-al-parcial-default-rtdb.firebaseio.com"
## Si está vacía, el juego funciona igual pero sin ranking en línea.
const URL_BASE := "https://sobrevive-al-parcial-default-rtdb.firebaseio.com"
const TOP := 10

var ultimo_id := ""  # la clave que Firebase le dio a la última nota subida desde este celular
var _url := URL_BASE


func _ready() -> void:
	# Las pruebas automáticas nunca suben notas al ranking real: usan un servidor
	# de mentiras en el mismo computador (--nube=...) o quedan sin ranking.
	var args := OS.get_cmdline_user_args()
	if "--recorrido" in args:
		_url = ""
	for a in args:
		if a.begins_with("--nube="):
			_url = a.trim_prefix("--nube=")
	_url = _url.trim_suffix("/")  # por si la pegan con / al final


func activa() -> bool:
	return _url != ""


## Sube una nota a /puntajes. Firebase le pone la hora del servidor con {".sv": "timestamp"}.
func enviar_nota(nombre: String, nota: float, puntaje: int, ranas: int) -> void:
	if not activa():
		return
	var datos := {
		"nombre": nombre.left(14),
		"nota": nota,
		"puntaje": puntaje,
		"ranas": ranas,
		"plataforma": OS.get_name(),
		"momento": {".sv": "timestamp"},
	}
	var pedido := _nuevo_pedido()
	pedido.request_completed.connect(func(resultado: int, codigo: int, _encabezados: PackedStringArray, cuerpo: PackedByteArray):
		pedido.queue_free()
		if resultado != HTTPRequest.RESULT_SUCCESS or codigo != 200:
			fallo.emit("No se pudo subir la nota (código %d)." % codigo)
			return
		# Firebase responde {"name": "-Nx1a2b3c"}: la clave del registro nuevo.
		var respuesta = JSON.parse_string(cuerpo.get_string_from_utf8())
		if respuesta is Dictionary:
			ultimo_id = str(respuesta.get("name", ""))
		nota_enviada.emit())
	pedido.request(_url + "/puntajes.json", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(datos))


## Pide el Top 10 por puntaje. Firebase devuelve los 10 más altos, pero en desorden,
## así que aquí se ordenan de mayor a menor.
func pedir_ranking() -> void:
	if not activa():
		fallo.emit("El ranking en línea no está configurado.")
		return
	var pedido := _nuevo_pedido()
	pedido.request_completed.connect(func(resultado: int, codigo: int, _encabezados: PackedStringArray, cuerpo: PackedByteArray):
		pedido.queue_free()
		if resultado != HTTPRequest.RESULT_SUCCESS or codigo != 200:
			fallo.emit("Sin conexión con el ranking en línea.")
			return
		var datos = JSON.parse_string(cuerpo.get_string_from_utf8())
		var lista: Array = []
		if datos is Dictionary:
			for clave in datos:
				var fila = datos[clave]
				if fila is Dictionary and fila.has("puntaje"):
					fila["id"] = clave
					lista.append(fila)
		lista.sort_custom(func(a, b): return float(a["puntaje"]) > float(b["puntaje"]))
		ranking_recibido.emit(lista.slice(0, TOP)))
	# orderBy y limitToLast son filtros de la API REST; las comillas van codificadas (%22).
	pedido.request(_url + "/puntajes.json?orderBy=%22puntaje%22&limitToLast=" + str(TOP))


func _nuevo_pedido() -> HTTPRequest:
	var pedido := HTTPRequest.new()
	pedido.timeout = 10.0
	add_child(pedido)
	return pedido
