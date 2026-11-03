class_name DatosNiveles
## Los 3 niveles del juego, dibujados como mapas de texto.
## Cada carácter es una celda de 2 x 2 metros:
##
##   #  pared               .  piso libre
##   E  estante de libros   M  mesa
##   B  kiosko del tinto     P  inicio del jugador
##   C  columna (bulevar)    J  jardinera con plantas (bulevar)
##   A  apunte (hay que juntarlos todos)
##   S  salida (se abre al tener todos los apuntes; va en el borde)
##   T  tinto (velocidad por unos segundos)
##   D  puerta con código (se abre al tener cierto número de apuntes)
##   R  una Xaca Rana (easter egg: +1 vida; con las 3 se gana el poder de la rana)
##   K  carro parqueado (parqueadero)  G  garita del portero
##   L  casilleros (pasillo)           N  banca (pasillo)
##
## Los vigilantes recorren su "ruta" (celdas col, fila) en bucle.
## Los estudiantes del bulevar van y vienen entre dos celdas.

const CELDA := 2.0


static func nivel(n: int) -> Dictionary:
	match n:
		1: return BIBLIOTECA
		2: return BULEVAR
		3: return INGENIERIA
		4: return PARQUEADERO
		_: return PASILLO


static var BIBLIOTECA := {
	"nombre": "Biblioteca",
	"hora": "6:00 p. m.",
	"tiempo": 180,
	"descripcion": "Silencio total. La bibliotecaria patrulla entre los estantes con su linterna. Dicen que una Xaca Rana se esconde entre los libros.",
	"estilo": "biblioteca",
	"rana": "rana_biblioteca",
	"oscuro": false,
	"piso": Color("#36446E"),
	"pared": Color("#1C2540"),
	"ambiente": Color("#B4C4FF"),
	"mapa": PackedStringArray([
		"######################",
		"#P..#..........#....A#",
		"#...#.EEEE.EEE.#.EEE.#",
		"#...#..........#.....#",
		"#...#.EEEE.EEE.......#",
		"#......A.............#",
		"#.EEE.......MM..EEEE.#",
		"#...........MM.......#",
		"#.EEE..R.........A...#",
		"#.......EEEE.EEEE....#",
		"#.A..................#",
		"#.EEEE.MM...MM..EEEE.#",
		"#.........A..........S",
		"######################",
	]),
	"guardias": [
		{"tipo": "bibliotecaria", "velocidad": 2.3, "ruta": [Vector2i(5, 5), Vector2i(17, 5), Vector2i(17, 10), Vector2i(5, 10)]},
	],
	"estudiantes": [],
	"puerta_requiere": 0,
}


static var BULEVAR := {
	"nombre": "Bulevar",
	"hora": "7:30 p. m.",
	"tiempo": 150,
	"descripcion": "De noche, bajo las lámparas del bulevar: mesas llenas de gente estudiando. Escóndete detrás de las jardineras y las columnas. En el kiosko venden tinto.",
	"estilo": "bulevar",
	"rana": "rana_bulevar",
	# De noche: casi sin sol, la luz sale de los tubos fluorescentes del techo.
	"luz_ambiente": 0.4,
	"luz_sol": 0.08,
	"cielo": Color("#121A33"),
	"oscuro": false,
	"piso": Color("#6A6D72"),
	"pared": Color("#3F5B3A"),
	"ambiente": Color("#A9B9EC"),
	"mapa": PackedStringArray([
		"########################",
		"#P......J.......J......#",
		"#..A.......A...........#",
		"#....C....C....C....C..#",
		"#..MM..MM...MM...MM....#",
		"#..MM..MM...MM...MM..A.#",
		"#......................#",
		"#JJ...T....JJ....A..JJR#",
		"#......................#",
		"#..MM...MM...MM...MM...#",
		"#..MM...MM...MM...MM...#",
		"#....C....C....C....C..#",
		"#.A....................#",
		"#.BBB.....J...A...J.T..#",
		"#..........A...........S",
		"########################",
	]),
	"guardias": [
		{"tipo": "vigilante", "velocidad": 2.6, "ruta": [Vector2i(1, 6), Vector2i(22, 6), Vector2i(22, 8), Vector2i(1, 8)]},
		{"tipo": "aseo", "velocidad": 1.8, "ruta": [Vector2i(5, 12), Vector2i(21, 12), Vector2i(21, 14), Vector2i(5, 14)]},
	],
	"estudiantes": [
		[Vector2i(1, 2), Vector2i(22, 2)],
		[Vector2i(6, 1), Vector2i(6, 14)],
		[Vector2i(16, 3), Vector2i(16, 14)],
		[Vector2i(1, 10), Vector2i(11, 10)],
		[Vector2i(12, 13), Vector2i(22, 13)],
	],
	"puerta_requiere": 0,
}


static var INGENIERIA := {
	"nombre": "Bloque de Ingeniería",
	"hora": "10:00 p. m.",
	"tiempo": 150,
	"descripcion": "De noche y casi sin luz. Tres vigilantes y puertas que se abren con el código de los apuntes.",
	"estilo": "ingenieria",
	"rana": "rana_ingenieria",
	"oscuro": true,
	"piso": Color("#2A3148"),
	"pared": Color("#161B2C"),
	"ambiente": Color("#3A4A7A"),
	"mapa": PackedStringArray([
		"##########################",
		"#P....#.......#..........#",
		"#.....#...A...#....A.....#",
		"#.....#.......#..........#",
		"#.....###.#####.....######",
		"#........................#",
		"#####.###D######.#####D###",
		"#A......#.......#....#...#",
		"#.......#...R...#....#.A.#",
		"#...A...#.......#....#...#",
		"#.......#...A...#....#...#",
		"#####.###########.####...#",
		"#.......................##",
		"#....A.......#######.....#",
		"#............#...A.......S",
		"##########################",
	]),
	"guardias": [
		{"tipo": "vigilante", "velocidad": 2.6, "ruta": [Vector2i(1, 5), Vector2i(24, 5)]},
		{"tipo": "vigilante", "velocidad": 2.4, "ruta": [Vector2i(1, 12), Vector2i(23, 12), Vector2i(23, 14), Vector2i(1, 14)]},
		{"tipo": "vigilante", "velocidad": 2.0, "ruta": [Vector2i(17, 7), Vector2i(20, 7), Vector2i(20, 10), Vector2i(17, 10)]},
	],
	"estudiantes": [],
	"puerta_requiere": 4,
}


static var PARQUEADERO := {
	"nombre": "Parqueadero",
	"hora": "7:00 a. m.",
	"tiempo": 150,
	"descripcion": "Al otro día, temprano. Se te quedó el carnet y los porteros no dejan entrar. El viento dejó apuntes entre los carros.",
	"estilo": "parqueadero",
	"oscuro": false,
	"piso": Color("#4A4D52"),
	"pared": Color("#3F5B3A"),
	"ambiente": Color("#FFE6C7"),
	"luz_ambiente": 0.75,
	"luz_sol": 0.9,
	"cielo": Color("#BFD9EE"),
	"mapa": PackedStringArray([
		"########################",
		"#P.....................#",
		"#..KK.KK.KK.KK.KK.KK...#",
		"#..........A...........#",
		"#..KK.KK.KK.KK.KK.KK...#",
		"#J.........J...........#",
		"#......A...........A...#",
		"#..KK.KK.KK.KK.KK.KK...#",
		"#.....................J#",
		"#..KK.KK.KK.KK.KK.KK...#",
		"#A...........A.........#",
		"#....J.....GG......J..A#",
		"#......................S",
		"########################",
	]),
	"guardias": [
		{"tipo": "vigilante", "velocidad": 2.6, "ruta": [Vector2i(1, 3), Vector2i(22, 3)]},
		{"tipo": "vigilante", "velocidad": 2.3, "ruta": [Vector2i(22, 6), Vector2i(1, 6), Vector2i(1, 8), Vector2i(21, 8)]},
		{"tipo": "vigilante", "velocidad": 2.0, "ruta": [Vector2i(13, 12), Vector2i(21, 12)]},
	],
	"estudiantes": [
		[Vector2i(1, 1), Vector2i(22, 1)],
		[Vector2i(2, 10), Vector2i(22, 10)],
	],
	"puerta_requiere": 0,
}


static var PASILLO := {
	"nombre": "Pasillo del Salón 304",
	"hora": "7:50 a. m.",
	"tiempo": 100,
	"descripcion": "¡El parcial es en 10 minutos! Las últimas hojas quedaron en el pasillo. La Xaca Rana profe ya está esperando afuera del salón.",
	"estilo": "pasillo",
	"oscuro": false,
	"piso": Color("#565C64"),
	"pared": Color("#6E6252"),
	"ambiente": Color("#FFF1DC"),
	"luz_ambiente": 0.5,
	"luz_sol": 0.5,
	"salida": "SALÓN 304",
	"mapa": PackedStringArray([
		"######################",
		"#P.L.LL..LL..LL.LL.L.#",
		"#....................#",
		"#.NN....A.....NN.....#",
		"#....................#",
		"#####.#####..#####.###",
		"#A.......#....#....A.#",
		"#...NN...#.A..#..NN..#",
		"#........#....#......S",
		"######################",
	]),
	"guardias": [
		{"tipo": "xaca_rana", "velocidad": 2.2, "ruta": [Vector2i(1, 2), Vector2i(20, 2), Vector2i(20, 4), Vector2i(1, 4)]},
		{"tipo": "vigilante", "velocidad": 2.0, "ruta": [Vector2i(15, 6), Vector2i(20, 6), Vector2i(20, 8), Vector2i(15, 8)]},
	],
	"estudiantes": [],
	"puerta_requiere": 0,
}
