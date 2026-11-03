extends Node
## Sonidos y música (requisito 8). Todos los sonidos están en res://sonidos y se
## generaron por código (herramientas/sonidos.py), así que no tienen derechos de autor.
##
## Hay dos buses de audio, "Musica" y "Efectos", para que el volumen de cada uno
## se pueda ajustar por separado desde Ajustes.

const SONIDOS := {
	"timbre": "res://sonidos/timbre.wav",
	"paso": "res://sonidos/paso.wav",
	"apunte": "res://sonidos/apunte.wav",
	"vida": "res://sonidos/vida.wav",
	"shh": "res://sonidos/shh.wav",
	"silbato": "res://sonidos/silbato.wav",
	"tinto": "res://sonidos/tinto.wav",
	"puerta": "res://sonidos/puerta.wav",
	"rana": "res://sonidos/rana.wav",
	"clic": "res://sonidos/clic.wav",
	"acierto": "res://sonidos/acierto.wav",
	"error": "res://sonidos/error.wav",
	"victoria": "res://sonidos/victoria.wav",
	"derrota": "res://sonidos/derrota.wav",
}
const MUSICAS := {
	"menu": "res://sonidos/musica_menu.wav",
	"juego": "res://sonidos/musica_juego.wav",
}
const CANALES_EFECTOS := 10

var _musica: AudioStreamPlayer
var _musica_actual := ""
var _canales: Array[AudioStreamPlayer] = []
var _cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # suena aunque el juego esté en pausa
	_crear_bus("Musica")
	_crear_bus("Efectos")
	_musica = AudioStreamPlayer.new()
	_musica.bus = "Musica"
	add_child(_musica)
	for i in CANALES_EFECTOS:
		var canal := AudioStreamPlayer.new()
		canal.bus = "Efectos"
		add_child(canal)
		_canales.append(canal)
	aplicar_volumen()


func _crear_bus(nombre: String) -> void:
	if AudioServer.get_bus_index(nombre) != -1:
		return
	AudioServer.add_bus()
	var indice := AudioServer.bus_count - 1
	AudioServer.set_bus_name(indice, nombre)
	AudioServer.set_bus_send(indice, "Master")


func aplicar_volumen() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Musica"), linear_to_db(maxf(Partida.volumen_musica, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Efectos"), linear_to_db(maxf(Partida.volumen_efectos, 0.0001)))


func _cargar(ruta: String) -> AudioStream:
	if not _cache.has(ruta):
		_cache[ruta] = load(ruta)
	return _cache[ruta]


## Reproduce un efecto. [param tono] cambia lo agudo (1.0 = normal) para que no suene repetido.
func efecto(nombre: String, tono: float = 1.0, volumen_db: float = 0.0) -> void:
	if not SONIDOS.has(nombre):
		return
	for canal in _canales:
		if not canal.playing:
			canal.stream = _cargar(SONIDOS[nombre])
			canal.pitch_scale = tono
			canal.volume_db = volumen_db
			canal.play()
			return


## Cambia la música de fondo con un fundido. La pista se repite sola.
func musica(nombre: String) -> void:
	if nombre == _musica_actual or not MUSICAS.has(nombre):
		return
	_musica_actual = nombre
	var pista := _cargar(MUSICAS[nombre])
	if pista is AudioStreamWAV:
		var wav := pista as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
	_musica.stream = pista
	_musica.volume_db = -30.0
	_musica.play()
	create_tween().tween_property(_musica, "volume_db", 0.0, 0.8)


func parar_musica() -> void:
	_musica_actual = ""
	var t := create_tween()
	t.tween_property(_musica, "volume_db", -40.0, 0.5)
	t.tween_callback(_musica.stop)
