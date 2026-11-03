extends Node
## Persistencia de datos entre vistas (requisito 7 del enunciado).
##
## Guarda en un archivo del computador (user://partida.cfg) todo lo que debe
## recordarse aunque se cierre el juego: nombre, volumen, niveles desbloqueados,
## mejores puntajes, tabla de récords y easter eggs encontrados.
## También lleva el estado de la partida en curso (vidas, puntaje, apuntes),
## que pasa de una escena a otra porque este nodo vive durante todo el juego (autoload).

## Se emite cuando se juntan las 3 Xaca Ranas en una partida (lo escucha el menú).
signal huevos_completos

const RUTA := "user://partida.cfg"
const MAX_RECORDS := 10
const VIDAS_INICIALES := 3
const VIDAS_MAXIMAS := 4
## Cantidad de niveles. Después del último viene la animación del parcial (escenas/Final).
const NIVELES := 5
## Las 3 Xaca Ranas escondidas (easter eggs), una en cada uno de los niveles 1, 2 y 3.
const HUEVOS_TOTALES := 3
const RANAS := ["rana_biblioteca", "rana_bulevar", "rana_ingenieria"]
## Poder de la Xaca Rana: cuántas veces se puede usar por nivel y cuánto dura.
const USOS_PODER := 2
const DURACION_PODER := 8.0

# --- Datos guardados en disco ---
var nombre := "Estudiante"
var volumen_musica := 0.6
var volumen_efectos := 0.9
var pantalla_completa := false
## Si es true, al presentar el parcial la nota se sube al ranking en línea (Firebase).
var ranking_en_linea := true
## Joystick del celular: centro como fracción de la pantalla (-1 = posición por defecto) y tamaño.
var joystick_centro := Vector2(-1, -1)
var joystick_escala := 1.0
var nivel_desbloqueado := 1
var mejores := {}          # {"1": {"puntaje": 3200, "tiempo": 95}, ...}
var records: Array = []    # [{"nombre", "puntaje", "nota", "fecha"}, ...]
var huevos := {}           # ranas encontradas alguna vez: {"rana_biblioteca": true, ...}

# --- Partida en curso (solo en memoria) ---
var modo_profe := false
var nivel_actual := 1
var vidas := VIDAS_INICIALES
var puntaje := 0
var apuntes_juntados := 0
var ranas_partida := {}    # ranas encontradas en ESTA partida (dan el poder)
var tiempo_sobrante := 0.0 # suma de los segundos que sobraron en cada nivel
var tiempo_total := 0.0    # suma del tiempo que daba cada nivel
var resultado := {}        # el último resultado, lo muestra la pantalla de Puntaje


func _ready() -> void:
	cargar()
	aplicar_pantalla()


func cargar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA) != OK:
		return  # primera vez que se abre el juego: se quedan los valores por defecto
	nombre = cfg.get_value("jugador", "nombre", nombre)
	volumen_musica = cfg.get_value("ajustes", "volumen_musica", volumen_musica)
	volumen_efectos = cfg.get_value("ajustes", "volumen_efectos", volumen_efectos)
	pantalla_completa = cfg.get_value("ajustes", "pantalla_completa", pantalla_completa)
	ranking_en_linea = cfg.get_value("ajustes", "ranking_en_linea", ranking_en_linea)
	joystick_centro = cfg.get_value("controles", "joystick_centro", joystick_centro)
	joystick_escala = cfg.get_value("controles", "joystick_escala", joystick_escala)
	nivel_desbloqueado = cfg.get_value("progreso", "nivel_desbloqueado", nivel_desbloqueado)
	mejores = cfg.get_value("progreso", "mejores", mejores)
	records = cfg.get_value("progreso", "records", records)
	huevos = cfg.get_value("progreso", "huevos", huevos)
	# Las versiones viejas guardaban otros secretos: solo cuentan las ranas.
	for id in huevos.keys():
		if not id in RANAS:
			huevos.erase(id)


func guardar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("jugador", "nombre", nombre)
	cfg.set_value("ajustes", "volumen_musica", volumen_musica)
	cfg.set_value("ajustes", "volumen_efectos", volumen_efectos)
	cfg.set_value("ajustes", "pantalla_completa", pantalla_completa)
	cfg.set_value("ajustes", "ranking_en_linea", ranking_en_linea)
	cfg.set_value("controles", "joystick_centro", joystick_centro)
	cfg.set_value("controles", "joystick_escala", joystick_escala)
	cfg.set_value("progreso", "nivel_desbloqueado", nivel_desbloqueado)
	cfg.set_value("progreso", "mejores", mejores)
	cfg.set_value("progreso", "records", records)
	cfg.set_value("progreso", "huevos", huevos)
	cfg.save(RUTA)


func borrar_progreso() -> void:
	nivel_desbloqueado = 1
	mejores = {}
	records = []
	huevos = {}
	modo_profe = false
	guardar()


func aplicar_pantalla() -> void:
	if Controles.es_tactil():
		return
	var modo := DisplayServer.WINDOW_MODE_FULLSCREEN if pantalla_completa else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(modo)


## Empieza una partida nueva desde el nivel indicado.
func nueva_partida(desde_nivel: int = 1) -> void:
	nivel_actual = desde_nivel
	vidas = VIDAS_INICIALES
	puntaje = 0
	apuntes_juntados = 0
	ranas_partida = {}
	tiempo_sobrante = 0.0
	tiempo_total = 0.0
	resultado = {}


## Se llama al pasar un nivel: suma puntos, guarda el récord del nivel y desbloquea el siguiente.
func terminar_nivel(nivel: int, puntos: int, tiempo_usado: float, tiempo_nivel: float = 0.0) -> void:
	puntaje += puntos
	tiempo_total += tiempo_nivel
	tiempo_sobrante += maxf(0.0, tiempo_nivel - tiempo_usado)
	var clave := str(nivel)
	if not mejores.has(clave) or puntos > int(mejores[clave]["puntaje"]):
		mejores[clave] = {"puntaje": puntos, "tiempo": int(tiempo_usado)}
	nivel_desbloqueado = maxi(nivel_desbloqueado, nivel + 1)
	guardar()


## Nota del parcial final (de 3.0 a 5.0): sale de cómo se jugó.
##   3.0 por llegar + 0.25 por cada vida que quede + 0.2 por cada Xaca Rana de esta partida
##   + hasta 0.4 según el tiempo que sobró. Máximo 5.0.
func calcular_nota() -> float:
	var nota := 3.0
	nota += 0.25 * mini(vidas, VIDAS_MAXIMAS)
	nota += 0.2 * ranas_partida.size()
	if tiempo_total > 0.0:
		nota += 0.4 * clampf(tiempo_sobrante / tiempo_total * 2.0, 0.0, 1.0)
	return minf(5.0, snappedf(nota, 0.1))


## Se llama al final (parcial presentado o partida perdida). Queda en la tabla de récords.
func registrar_resultado(gano: bool, motivo: String, nota: float) -> void:
	var total := puntaje + int(round(nota * 1000.0))
	resultado = {
		"gano": gano,
		"motivo": motivo,
		"nota": nota,
		"puntaje": total,
		"nivel": nivel_actual,
		"vidas": vidas,
	}
	if total > 0:
		var fecha := Time.get_date_dict_from_system()
		records.append({
			"nombre": nombre,
			"puntaje": total,
			"nota": nota,
			"fecha": "%02d/%02d/%d" % [fecha.day, fecha.month, fecha.year],
		})
		records.sort_custom(func(a, b): return int(a["puntaje"]) > int(b["puntaje"]))
		records = records.slice(0, MAX_RECORDS)
	guardar()
	# Solo las notas del parcial van al ranking en línea, no las partidas perdidas.
	if gano and ranking_en_linea:
		Nube.enviar_nota(nombre, nota, total, ranas_partida.size())


## true si alguna vez encontró las 3 ranas (para los créditos y la rana dorada del menú).
func tiene_todos_los_huevos() -> bool:
	return huevos.size() >= HUEVOS_TOTALES


## true si en ESTA partida ya juntó las 3 ranas: puede usar el poder de la Xaca Rana.
func tiene_poder_rana() -> bool:
	return ranas_partida.size() >= HUEVOS_TOTALES


## Se llama al tocar una Xaca Rana. Devuelve true si es nueva en esta partida.
## Con la tercera sale la animación de la transformación (CelebracionRana).
func encontrar_rana(id: String) -> bool:
	if ranas_partida.has(id):
		return false
	ranas_partida[id] = true
	huevos[id] = true
	guardar()
	if tiene_poder_rana():
		huevos_completos.emit()
		get_tree().root.add_child.call_deferred(CelebracionRana.new())
	return true


func posicion_en_records(puntos: int) -> int:
	for i in records.size():
		if int(records[i]["puntaje"]) == puntos:
			return i + 1
	return -1
