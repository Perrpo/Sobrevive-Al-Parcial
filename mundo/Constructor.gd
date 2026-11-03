class_name Constructor
## Arma los objetos 3D del juego con figuras simples (cajas, cilindros, esferas).
## Así no hace falta comprar ni descargar modelos: todo se ve "low-poly" y es liviano.

static var _materiales := {}

const COLORES_LIBROS := [Color("#D7333A"), Color("#4078C4"), Color("#FFE14D"), Color("#70AD47"), Color("#E0A458"), Color("#9B6BD1")]


## Material con caché: si ya existe uno igual, se reutiliza (ahorra memoria).
static func material(color: Color, brillo: float = 0.0) -> StandardMaterial3D:
	var clave := "%s_%s" % [color.to_html(), brillo]
	if not _materiales.has(clave):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.85
		if brillo > 0.0:
			m.emission_enabled = true
			m.emission = color
			m.emission_energy_multiplier = brillo
		_materiales[clave] = m
	return _materiales[clave]


static func caja(tam: Vector3, color: Color, pos: Vector3 = Vector3.ZERO, brillo: float = 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = tam
	m.mesh = malla
	m.material_override = material(color, brillo)
	m.position = pos
	return m


static func cilindro(radio_arriba: float, radio_abajo: float, alto: float, color: Color, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var malla := CylinderMesh.new()
	malla.top_radius = radio_arriba
	malla.bottom_radius = radio_abajo
	malla.height = alto
	malla.radial_segments = 16
	m.mesh = malla
	m.material_override = material(color)
	m.position = pos
	return m


static func esfera(radio: float, color: Color, pos: Vector3 = Vector3.ZERO, brillo: float = 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var malla := SphereMesh.new()
	malla.radius = radio
	malla.height = radio * 2.0
	malla.radial_segments = 18
	malla.rings = 10
	m.mesh = malla
	m.material_override = material(color, brillo)
	m.position = pos
	return m


## Estudiante (el jugador). Las piernas se llaman PiernaI/PiernaD para animarlas al caminar.
static func estudiante(camisa: Color = Color("#3E6FB8"), morral: Color = Color("#D7333A")) -> Node3D:
	var n := Node3D.new()
	n.name = "Estudiante"
	var cuerpo := cilindro(0.34, 0.4, 0.95, camisa, Vector3(0, 0.78, 0))
	cuerpo.name = "Cuerpo"
	n.add_child(cuerpo)
	var cabeza := esfera(0.32, Color("#F2C9A0"), Vector3(0, 1.56, 0))
	cabeza.name = "Cabeza"
	n.add_child(cabeza)
	n.add_child(esfera(0.34, Color("#2B1D14"), Vector3(0, 1.66, -0.04)))  # pelo
	n.add_child(caja(Vector3(0.52, 0.58, 0.28), morral, Vector3(0, 0.88, -0.4)))
	n.add_child(caja(Vector3(0.08, 0.08, 0.04), Color("#182742"), Vector3(-0.11, 1.58, 0.29)))  # ojos
	n.add_child(caja(Vector3(0.08, 0.08, 0.04), Color("#182742"), Vector3(0.11, 1.58, 0.29)))
	for lado in [-1, 1]:
		var pierna := caja(Vector3(0.18, 0.34, 0.2), Color("#182742"), Vector3(0.15 * lado, 0.17, 0))
		pierna.name = "PiernaI" if lado < 0 else "PiernaD"
		n.add_child(pierna)
	return n


## Vigilante, bibliotecaria, señor del aseo o (en "modo profe") un profesor.
static func vigilante(tipo: String, modo_profe: bool = false) -> Node3D:
	if tipo == "xaca_rana":
		return profe_rana()
	var n := Node3D.new()
	n.name = "Vigilante"
	var ropa := Color("#2F3B52")
	match tipo:
		"bibliotecaria": ropa = Color("#5A2D5F")
		"aseo": ropa = Color("#2E7D6B")
	if modo_profe:
		ropa = Color("#6B5B45")
	n.add_child(cilindro(0.4, 0.48, 1.2, ropa, Vector3(0, 0.85, 0)))
	n.add_child(esfera(0.34, Color("#E8B98F"), Vector3(0, 1.76, 0)))
	n.add_child(caja(Vector3(0.48, 0.07, 0.05), Color("#111111"), Vector3(0, 1.8, 0.31)))  # gafas o ceño
	if modo_profe:
		n.add_child(caja(Vector3(0.12, 0.6, 0.05), Color("#D7333A"), Vector3(0, 1.0, 0.43)))  # corbata
		n.add_child(caja(Vector3(0.5, 0.36, 0.06), Color("#F2F6FB"), Vector3(0.45, 1.0, 0.2)))  # hoja de examen
	else:
		match tipo:
			"bibliotecaria":
				n.add_child(esfera(0.22, Color("#8A8A8A"), Vector3(0, 2.02, -0.24)))  # moño
			"aseo":
				n.add_child(cilindro(0.03, 0.03, 1.5, Color("#9C6B30"), Vector3(0.5, 0.9, 0.25)))  # trapero
				n.add_child(caja(Vector3(0.36, 0.1, 0.2), Color("#DADADA"), Vector3(0.5, 0.15, 0.25)))
			_:
				n.add_child(cilindro(0.36, 0.36, 0.12, Color("#1C2436"), Vector3(0, 2.02, 0)))  # gorra
				n.add_child(caja(Vector3(0.4, 0.04, 0.24), Color("#1C2436"), Vector3(0, 1.98, 0.22)))
	# Linterna en la mano.
	n.add_child(cilindro(0.07, 0.07, 0.3, Color("#333333"), Vector3(-0.42, 1.05, 0.3)))
	return n


## Hoja de apuntes que brilla. Si es "dorada" es el examen filtrado (easter egg).
static func apunte(dorado: bool = false) -> Node3D:
	var n := Node3D.new()
	var color_hoja := Color("#FFD24D") if dorado else Color("#FFFFFF")
	var hoja := caja(Vector3(0.5, 0.66, 0.03), color_hoja, Vector3.ZERO, 0.6 if dorado else 0.35)
	n.add_child(hoja)
	for i in 4:
		n.add_child(caja(Vector3(0.36, 0.025, 0.035), Color("#4078C4"), Vector3(0, 0.18 - i * 0.12, 0.0)))
	var luz := OmniLight3D.new()
	luz.light_color = Color("#FFE14D")
	luz.light_energy = 0.9
	luz.omni_range = 3.0
	n.add_child(luz)
	return n


## Estante de biblioteca con libros de colores. Ocupa [param largo] metros de ancho.
static func estante(largo: float, rng: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	n.add_child(caja(Vector3(largo, 2.6, 0.9), Color("#6B4428"), Vector3(0, 1.3, 0)))
	for fila in 3:
		var x := -largo / 2.0 + 0.2
		while x < largo / 2.0 - 0.2:
			var grosor := rng.randf_range(0.14, 0.26)
			var alto := rng.randf_range(0.45, 0.66)
			var color: Color = COLORES_LIBROS[rng.randi() % COLORES_LIBROS.size()]
			for cara in [-1, 1]:
				n.add_child(caja(Vector3(grosor, alto, 0.2), color, Vector3(x + grosor / 2.0, 0.32 + fila * 0.82 + alto / 2.0, 0.42 * cara)))
			x += grosor + 0.02
	return n


static func mesa(color: Color = Color("#B88B5C")) -> Node3D:
	var n := Node3D.new()
	n.add_child(caja(Vector3(1.9, 0.12, 1.5), color, Vector3(0, 0.85, 0)))
	for p in [Vector2(-0.8, -0.6), Vector2(0.8, -0.6), Vector2(-0.8, 0.6), Vector2(0.8, 0.6)]:
		n.add_child(caja(Vector3(0.1, 0.85, 0.1), color.darkened(0.3), Vector3(p.x, 0.42, p.y)))
	return n


static func pupitre() -> Node3D:
	var n := Node3D.new()
	n.add_child(caja(Vector3(1.2, 0.1, 0.8), Color("#C8B48C"), Vector3(0, 0.8, 0)))
	n.add_child(caja(Vector3(0.08, 0.8, 0.08), Color("#555555"), Vector3(-0.5, 0.4, 0)))
	n.add_child(caja(Vector3(0.08, 0.8, 0.08), Color("#555555"), Vector3(0.5, 0.4, 0)))
	n.add_child(caja(Vector3(0.5, 0.06, 0.5), Color("#4078C4"), Vector3(0, 0.5, 0.6)))
	return n


static func tinto() -> Node3D:
	var n := Node3D.new()
	n.add_child(cilindro(0.16, 0.12, 0.3, Color("#FFFFFF"), Vector3(0, 0.15, 0)))
	n.add_child(cilindro(0.15, 0.15, 0.02, Color("#5A3417"), Vector3(0, 0.3, 0)))
	var luz := OmniLight3D.new()
	luz.light_color = Color("#E0A458")
	luz.light_energy = 0.7
	luz.omni_range = 2.2
	luz.position.y = 0.5
	n.add_child(luz)
	return n


## Cabeza de la Xaca Rana, igual al dibujo del profe: toda verde, ancha, con los ojos
## saltones a los lados (con borde oscuro y la pupila negra mirando hacia afuera),
## dos puntitos de nariz y una sonrisa ancha. Mide 1 m de ancho y mira hacia +z.
static func cabeza_rana(color: Color = Color("#37BB62")) -> Node3D:
	var n := Node3D.new()
	var oscuro := color.darkened(0.65)
	var craneo := esfera(0.5, color)
	craneo.scale = Vector3(1.0, 0.56, 0.82)
	n.add_child(craneo)
	var papada := esfera(0.5, color.darkened(0.06), Vector3(0, -0.07, 0.03))
	papada.scale = Vector3(0.94, 0.36, 0.76)
	n.add_child(papada)
	for lado in [-1, 1]:
		var centro := Vector3(0.35 * lado, 0.22, 0.05)
		n.add_child(esfera(0.23, color, centro))
		# Hacia dónde mira el ojo: afuera y un poco al frente.
		var mira := Vector3(0.5 * lado, 0.05, 0.86).normalized()
		var anillo := MeshInstance3D.new()
		var toro := TorusMesh.new()
		toro.inner_radius = 0.185
		toro.outer_radius = 0.215
		toro.rings = 24
		anillo.mesh = toro
		anillo.material_override = material(oscuro)
		anillo.position = centro + mira * 0.125
		anillo.basis = Basis(Quaternion(Vector3.UP, mira))
		n.add_child(anillo)
		var pupila := esfera(0.12, Color("#0E1A12"), centro + mira * 0.205)
		pupila.basis = Basis(Quaternion(Vector3.FORWARD, -mira)).scaled(Vector3(0.6, 1.0, 0.4))
		n.add_child(pupila)
	for lado in [-1, 1]:
		n.add_child(esfera(0.022, oscuro, Vector3(0.07 * lado, 0.07, 0.4)))  # nariz
	# Sonrisa: muchas bolitas oscuras pegadas forman una línea sobre el frente de la cara.
	for k in 41:
		var a := lerpf(-1.1, 1.1, k / 40.0)
		n.add_child(esfera(0.02, oscuro, Vector3(0.465 * sin(a), -0.1 + 0.04 * (1.0 - cos(a)), 0.385 * cos(a))))
	return n


## La Xaca Rana (easter egg): la cabeza del dibujo del profe. La dorada, con corona,
## es la de la animación de la transformación.
static func rana(dorada: bool = false) -> Node3D:
	var n := Node3D.new()
	var cabeza := cabeza_rana(Color("#E8B83A") if dorada else Color("#37BB62"))
	cabeza.position.y = 0.3
	cabeza.scale = Vector3.ONE * 0.6
	n.add_child(cabeza)
	if dorada:
		var oro := Color("#FFD24D")
		n.add_child(cilindro(0.15, 0.15, 0.08, oro, Vector3(0, 0.5, -0.02)))
		for i in 5:
			var a := TAU * i / 5.0
			n.add_child(caja(Vector3(0.05, 0.12, 0.05), oro, Vector3(cos(a) * 0.13, 0.58, sin(a) * 0.13 - 0.02), 0.4))
	return n


## Cono de luz en el piso que muestra hacia dónde mira un vigilante.
static func cono_vision(alcance: float, angulo: float, color: Color) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pasos := 18
	for i in pasos:
		var a1 := -angulo + 2.0 * angulo * i / pasos
		var a2 := -angulo + 2.0 * angulo * (i + 1) / pasos
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(Vector3(sin(a2), 0, cos(a2)) * alcance)
		st.add_vertex(Vector3(sin(a1), 0, cos(a1)) * alcance)
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color, 0.22)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position.y = 0.04
	return m


# ---------- Bulevar (basado en las fotos del bulevar de la universidad) ----------

const VERDES_PLANTA := [Color("#2F6B3A"), Color("#3E8A45"), Color("#24502C"), Color("#5A9A4A")]


## Hoja grande tipo "costilla de Adán": una esfera aplastada y estirada.
static func hoja(largo: float, color: Color) -> MeshInstance3D:
	var h := esfera(0.5, color)
	h.scale = Vector3(0.55, 0.08, largo)
	return h


## Mata de hojas grandes que salen del centro hacia arriba y hacia afuera.
static func planta(rng: RandomNumberGenerator, alto: float = 1.2) -> Node3D:
	var n := Node3D.new()
	var cantidad := rng.randi_range(6, 9)
	for i in cantidad:
		var pivote := Node3D.new()
		pivote.rotation = Vector3(-rng.randf_range(0.5, 1.0), TAU * i / cantidad + rng.randf_range(-0.3, 0.3), 0)
		var h := hoja(rng.randf_range(0.8, 1.2) * alto, VERDES_PLANTA[rng.randi() % VERDES_PLANTA.size()])
		h.position = Vector3(0, 0, h.scale.z * 0.45)
		pivote.add_child(h)
		n.add_child(pivote)
	return n


## Columna negra delgada que sostiene el techo del bulevar.
static func columna(rng: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	n.add_child(caja(Vector3(0.32, 3.0, 0.32), Color("#17191C"), Vector3(0, 1.5, 0)))
	if rng.randf() < 0.5:
		# Letrero amarillo colgado de la columna, como los de las fotos.
		n.add_child(caja(Vector3(0.5, 0.75, 0.04), Color("#F2B233"), Vector3(0, 2.3, 0.19), 0.15))
	return n


## Jardinera de concreto con plantas: sirve para esconderse (tapa la vista de los vigilantes).
static func jardinera(rng: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	n.add_child(caja(Vector3(1.8, 0.55, 1.8), Color("#A9A69C"), Vector3(0, 0.275, 0)))
	n.add_child(caja(Vector3(1.6, 0.05, 1.6), Color("#4A3A2A"), Vector3(0, 0.56, 0)))
	for p in [Vector3(-0.4, 0.55, -0.4), Vector3(0.45, 0.55, 0.3), Vector3(-0.2, 0.55, 0.45)]:
		var mata := planta(rng, 1.1)
		mata.position = p
		n.add_child(mata)
	return n


## Silla plástica (verde limón o café) mirando hacia +z.
static func silla(color: Color) -> Node3D:
	var n := Node3D.new()
	n.add_child(caja(Vector3(0.46, 0.06, 0.44), color, Vector3(0, 0.46, 0)))
	n.add_child(caja(Vector3(0.46, 0.46, 0.05), color, Vector3(0, 0.72, -0.21)))
	for p in [Vector2(-0.19, -0.18), Vector2(0.19, -0.18), Vector2(-0.19, 0.18), Vector2(0.19, 0.18)]:
		n.add_child(caja(Vector3(0.04, 0.46, 0.04), color.darkened(0.15), Vector3(p.x, 0.23, p.y)))
	return n


## Mesa de acero del bulevar con sillas alrededor y, a veces, alguien sentado estudiando.
static func mesa_bulevar(rng: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	n.add_child(caja(Vector3(1.4, 0.05, 0.95), Color("#9EA5AD"), Vector3(0, 0.76, 0)))
	for p in [Vector2(-0.62, -0.4), Vector2(0.62, -0.4), Vector2(-0.62, 0.4), Vector2(0.62, 0.4)]:
		n.add_child(caja(Vector3(0.05, 0.74, 0.05), Color("#8E949B"), Vector3(p.x, 0.37, p.y)))
	var lados := [[Vector3(-0.35, 0, -0.8), 0.0], [Vector3(0.35, 0, -0.8), 0.0], [Vector3(-0.35, 0, 0.8), PI], [Vector3(0.35, 0, 0.8), PI]]
	for lado in lados:
		if rng.randf() < 0.25:
			continue  # una silla corrida o que se llevaron
		var color: Color = Color("#A6C935") if rng.randf() < 0.6 else Color("#6B4632")
		var s := silla(color)
		s.position = lado[0]
		s.rotation.y = lado[1] + rng.randf_range(-0.25, 0.25)
		n.add_child(s)
		if rng.randf() < 0.3:
			var persona := estudiante(Estudiante.CAMISAS[rng.randi() % Estudiante.CAMISAS.size()], Color("#182742"))
			persona.position = lado[0] + Vector3(0, -0.28, 0)
			persona.rotation.y = lado[1]
			n.add_child(persona)
	if rng.randf() < 0.4:
		n.add_child(caja(Vector3(0.34, 0.02, 0.24), Color("#2B3A55"), Vector3(rng.randf_range(-0.4, 0.4), 0.8, 0.1)))  # portátil
	return n


## Kiosko donde venden tinto.
static func kiosko(largo: float) -> Node3D:
	var n := Node3D.new()
	n.add_child(caja(Vector3(largo, 1.05, 1.3), Color("#EDEBE6"), Vector3(0, 0.525, 0)))
	n.add_child(caja(Vector3(largo + 0.1, 0.08, 1.45), Color("#B88B5C"), Vector3(0, 1.09, 0)))
	n.add_child(caja(Vector3(0.5, 0.5, 0.4), Color("#2B2B2B"), Vector3(-largo / 2 + 0.6, 1.38, -0.2)))  # cafetera
	for i in 3:
		n.add_child(cilindro(0.07, 0.05, 0.14, Color("#FFFFFF"), Vector3(0.2 + i * 0.25, 1.2, 0.3)))
	var letrero := Label3D.new()
	letrero.text = "TINTO"
	letrero.font = Estilo.fuente_titulo
	letrero.font_size = 72
	letrero.modulate = Color("#5A3417")
	letrero.outline_size = 12
	letrero.outline_modulate = Color("#FFE14D")
	letrero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	letrero.position.y = 2.1
	n.add_child(letrero)
	return n


## Borde del bulevar: muro bajo de concreto con plantas encima (en vez de una pared).
static func seto(largo: float, rng: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	n.add_child(caja(Vector3(largo, 0.5, 2.0), Color("#9D9A90"), Vector3(0, 0.25, 0)))
	var x := -largo / 2.0 + 0.6
	while x < largo / 2.0 - 0.3:
		var mata := planta(rng, rng.randf_range(1.0, 1.5))
		mata.position = Vector3(x, 0.5, rng.randf_range(-0.4, 0.4))
		n.add_child(mata)
		x += rng.randf_range(0.9, 1.4)
	return n


## Árbol grande con tronco con musgo, como el de la foto.
static func arbol(rng: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	n.add_child(cilindro(0.45, 0.7, 4.5, Color("#5E5B3E"), Vector3(0, 2.25, 0)))
	n.add_child(cilindro(0.5, 0.75, 1.2, Color("#4D6B35"), Vector3(0, 0.6, 0)))  # musgo
	for i in 6:
		var copa := esfera(rng.randf_range(1.4, 2.0), VERDES_PLANTA[rng.randi() % VERDES_PLANTA.size()])
		copa.position = Vector3(rng.randf_range(-1.6, 1.6), rng.randf_range(4.6, 5.8), rng.randf_range(-1.6, 1.6))
		n.add_child(copa)
	return n


## Tubo de luz fluorescente del techo.
static func lampara() -> MeshInstance3D:
	var m := caja(Vector3(1.5, 0.06, 0.14), Color("#F4F8FF"), Vector3.ZERO, 1.6)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m



# ---------- La Xaca Rana profe ----------

## El profe: cuerpo con saco y corbata, y la cabeza de la Xaca Rana.
static func profe_rana() -> Node3D:
	var n := Node3D.new()
	n.name = "XacaRana"
	n.add_child(cilindro(0.42, 0.5, 1.2, Color("#5B4A3A"), Vector3(0, 0.85, 0)))  # saco
	n.add_child(caja(Vector3(0.3, 0.7, 0.05), Color("#F2F6FB"), Vector3(0, 1.1, 0.42)))  # camisa
	n.add_child(caja(Vector3(0.12, 0.62, 0.05), Color("#D7333A"), Vector3(0, 1.08, 0.46)))  # corbata
	var cabeza := cabeza_rana()
	cabeza.position = Vector3(0, 1.88, 0.02)
	cabeza.scale = Vector3.ONE * 1.3
	n.add_child(cabeza)
	# Una hoja de examen en la mano.
	n.add_child(caja(Vector3(0.42, 0.56, 0.03), Color("#FFFFFF"), Vector3(0.55, 1.05, 0.25)))
	return n


# ---------- Parqueadero ----------

const COLORES_CARRO := [Color("#C0392B"), Color("#2C6FB7"), Color("#E8E6E0"), Color("#2B2B2B"), Color("#8E9AA6"), Color("#E0A458")]


## Carro parqueado (mirando hacia +z). Bajito: la rana salta por encima.
static func carro(rng: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	var color: Color = COLORES_CARRO[rng.randi() % COLORES_CARRO.size()]
	n.add_child(caja(Vector3(1.45, 0.55, 1.85), color, Vector3(0, 0.45, 0)))
	n.add_child(caja(Vector3(1.25, 0.45, 1.0), color.lightened(0.1), Vector3(0, 0.95, -0.1)))
	n.add_child(caja(Vector3(1.27, 0.32, 0.9), Color("#24364F"), Vector3(0, 0.98, -0.1)))  # vidrios
	for x in [-0.72, 0.72]:
		for z in [-0.6, 0.6]:
			var rueda := cilindro(0.22, 0.22, 0.16, Color("#151515"), Vector3(x, 0.22, z))
			rueda.rotation.z = PI / 2
			n.add_child(rueda)
	n.add_child(caja(Vector3(0.3, 0.1, 0.03), Color("#FFF6C8"), Vector3(-0.45, 0.55, 0.93), 0.4))  # luces
	n.add_child(caja(Vector3(0.3, 0.1, 0.03), Color("#FFF6C8"), Vector3(0.45, 0.55, 0.93), 0.4))
	n.rotation.y = PI if rng.randf() < 0.5 else 0.0
	return n


## Garita del portero, con ventanas y una talanquera.
static func garita(largo: float) -> Node3D:
	var n := Node3D.new()
	n.add_child(caja(Vector3(largo - 0.4, 2.3, 1.6), Color("#E9E6E0"), Vector3(0, 1.15, 0)))
	n.add_child(caja(Vector3(largo - 0.3, 0.12, 1.8), Color("#2E7D6B"), Vector3(0, 2.36, 0)))
	n.add_child(caja(Vector3(largo - 0.8, 0.6, 0.04), Color("#24364F"), Vector3(0, 1.4, 0.81)))
	n.add_child(caja(Vector3(2.6, 0.1, 0.1), Color("#D7333A"), Vector3(largo / 2.0 + 1.1, 1.0, 0.6)))  # talanquera
	n.add_child(caja(Vector3(0.6, 0.12, 0.12), Color("#F2F6FB"), Vector3(largo / 2.0 + 0.6, 1.0, 0.6)))
	return n


# ---------- Pasillo del salón ----------

## Fila de casilleros metálicos (altos: tapan la vista).
static func casilleros(largo: float, rng: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	var color := Color("#3E6FB8") if rng.randf() < 0.5 else Color("#7A8794")
	n.add_child(caja(Vector3(largo, 2.0, 0.7), color, Vector3(0, 1.0, -0.4)))
	var x := -largo / 2.0 + 0.3
	while x < largo / 2.0:
		n.add_child(caja(Vector3(0.03, 1.9, 0.02), color.darkened(0.35), Vector3(x, 1.0, -0.04)))
		n.add_child(caja(Vector3(0.12, 0.04, 0.03), Color("#C9CDD3"), Vector3(x + 0.15, 1.1, -0.03)))
		x += 0.45
	return n


## Banca del pasillo (bajita).
static func banca() -> Node3D:
	var n := Node3D.new()
	n.add_child(caja(Vector3(1.8, 0.08, 0.5), Color("#B88B5C"), Vector3(0, 0.45, 0)))
	for x in [-0.75, 0.75]:
		n.add_child(caja(Vector3(0.08, 0.45, 0.45), Color("#555555"), Vector3(x, 0.22, 0)))
	return n
