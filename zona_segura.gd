@tool
extends Node3D

const ANCHO: float = 30.0
const Z_FONDO: float = -4.0
const Z_FRENTE: float = 5.0
const ALTO: float = 4.6
const HUECO_X: Vector2 = Vector2(10.5, 13.5)
const HUECO_Z: Vector2 = Vector2(1.5, 4.6)

const CIAN: Color = Color(0.62, 0.88, 0.92)
const ROSA: Color = Color(1.0, 0.55, 0.78)
const NARANJA: Color = Color(1.0, 0.55, 0.28)
const ROJO: Color = Color(0.72, 0.12, 0.16)
const VERDE_AGUA: Color = Color(0.2, 0.33, 0.35)
const AMARILLO: Color = Color(1.0, 0.84, 0.5)
const CREMA: Color = Color(0.97, 0.93, 0.92)
const NOCHE: Color = Color(0.09, 0.06, 0.12)
const MALVA: Color = Color(0.56, 0.36, 0.5)
const MALVA_OSCURO: Color = Color(0.3, 0.18, 0.28)
const LAVANDA: Color = Color(0.46, 0.46, 0.6)
const LAVANDA_OSCURO: Color = Color(0.27, 0.26, 0.37)
const LUZ_ROSA: Color = Color(1.0, 0.68, 0.85)
const LADRILLO: Shader = preload("res://zona_b/ladrillo.gdshader")

var choques: StaticBody3D
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	for h: Node in get_children():
		if h.name == "Sala":
			remove_child(h)
			h.free()
	_rng.seed = 1984
	var sala: Node3D = Node3D.new()
	sala.name = "Sala"
	add_child(sala)
	choques = StaticBody3D.new()
	choques.name = "Choques"
	sala.add_child(choques)
	_piso(sala)
	_paredes(sala)
	_bajada(sala)
	_baranda(sala)
	var colores_izq: Array[Color] = [VERDE_AGUA, VERDE_AGUA, ROJO]
	var colores_der: Array[Color] = [ROJO, VERDE_AGUA]
	_maquinas(sala, -12.6, colores_izq)
	_maquinas(sala, 5.6, colores_der)
	_sillas(sala, Vector3(-6.0, 0, -0.4), 4)
	_sillas(sala, Vector3(1.5, 0, 1.4), 4)
	_pilar(sala, Vector3(-2.2, 0, -1.6), ROJO)
	_pilar(sala, Vector3(9.0, 0, -1.6), CIAN)
	_carteles(sala)
	_mural(sala)
	_viga_luz(sala)
	_detalles(sala)


func _piso(p: Node3D) -> void:
	var m: ShaderMaterial = _ladrillo(LAVANDA, LAVANDA_OSCURO, Vector2(0.9, 0.6), true, 0.2)
	var x0: float = -ANCHO / 2.0
	var x1: float = ANCHO / 2.0
	var prof: float = Z_FRENTE - Z_FONDO
	_bloque(p, Vector3(HUECO_X.x - x0, 1.0, prof), Vector3((x0 + HUECO_X.x) / 2.0, -0.5, (Z_FONDO + Z_FRENTE) / 2.0), m)
	_bloque(p, Vector3(x1 - HUECO_X.y, 1.0, prof), Vector3((HUECO_X.y + x1) / 2.0, -0.5, (Z_FONDO + Z_FRENTE) / 2.0), m)
	var w: float = HUECO_X.y - HUECO_X.x
	var cx: float = (HUECO_X.x + HUECO_X.y) / 2.0
	_bloque(p, Vector3(w, 1.0, HUECO_Z.x - Z_FONDO), Vector3(cx, -0.5, (Z_FONDO + HUECO_Z.x) / 2.0), m)
	_bloque(p, Vector3(w, 1.0, Z_FRENTE - HUECO_Z.y), Vector3(cx, -0.5, (HUECO_Z.y + Z_FRENTE) / 2.0), m)
	var franja: StandardMaterial3D = _mat(AMARILLO, Color(1, 0.7, 0.2), 0.4)
	_caja(p, Vector3(ANCHO - 0.4, 0.01, 0.3), Vector3(0, 0.006, Z_FRENTE - 0.5), franja)


func _paredes(p: Node3D) -> void:
	var m: ShaderMaterial = _ladrillo(MALVA, MALVA_OSCURO, Vector2(0.5, 0.25), false, 0.08)
	_bloque(p, Vector3(ANCHO + 0.8, ALTO, 0.4), Vector3(0, ALTO / 2.0, Z_FONDO - 0.2), m)
	var signos: Array[int] = [-1, 1]
	for s: int in signos:
		_bloque(p, Vector3(0.4, ALTO, Z_FRENTE - Z_FONDO + 0.4), Vector3(s * (ANCHO / 2.0 + 0.2), ALTO / 2.0, (Z_FONDO + Z_FRENTE) / 2.0), m)
	var zocalo: StandardMaterial3D = _mat(MALVA_OSCURO)
	_caja(p, Vector3(ANCHO, 0.3, 0.05), Vector3(0, 0.15, Z_FONDO + 0.02), zocalo)
	var cornisa: StandardMaterial3D = _mat(NOCHE, LUZ_ROSA, 0.5)
	_caja(p, Vector3(ANCHO, 0.06, 0.08), Vector3(0, 3.3, Z_FONDO + 0.04), cornisa)


func _bajada(p: Node3D) -> void:
	var cx: float = (HUECO_X.x + HUECO_X.y) / 2.0
	var w: float = HUECO_X.y - HUECO_X.x
	var paso: float = (HUECO_Z.y - HUECO_Z.x) / 8.0
	var gris: StandardMaterial3D = _mat(LAVANDA_OSCURO)
	var borde: StandardMaterial3D = _mat(AMARILLO, Color(1, 0.7, 0.2), 0.8)
	for i: int in 8:
		var y: float = -0.25 - i * 0.25
		var z: float = HUECO_Z.x + paso * (i + 0.5)
		_caja(p, Vector3(w, 0.25, paso), Vector3(cx, y - 0.125, z), gris)
		_caja(p, Vector3(w, 0.02, 0.05), Vector3(cx, y + 0.005, HUECO_Z.x + paso * i + 0.03), borde)
	_forma(Vector3(w, 0.2, HUECO_Z.y - HUECO_Z.x), Vector3(cx, -0.4, (HUECO_Z.x + HUECO_Z.y) / 2.0))
	var oscuro: StandardMaterial3D = _mat(Color(0.01, 0.01, 0.02))
	_caja(p, Vector3(w, 0.05, HUECO_Z.y - HUECO_Z.x), Vector3(cx, -2.3, (HUECO_Z.x + HUECO_Z.y) / 2.0), oscuro)
	var bordes_x: Array[float] = [HUECO_X.x - 0.05, HUECO_X.y + 0.05]
	for x: float in bordes_x:
		_caja(p, Vector3(0.1, 2.3, HUECO_Z.y - HUECO_Z.x), Vector3(x, -1.15, (HUECO_Z.x + HUECO_Z.y) / 2.0), _mat(MALVA_OSCURO))
	var flecha: MeshInstance3D = MeshInstance3D.new()
	var pm: PrismMesh = PrismMesh.new()
	pm.size = Vector3(0.6, 0.5, 0.08)
	flecha.mesh = pm
	flecha.material_override = _mat(LUZ_ROSA, LUZ_ROSA, 2.5)
	flecha.position = Vector3(cx, 1.9, HUECO_Z.x - 0.1)
	flecha.rotation.z = PI
	p.add_child(flecha)
	var letrero: Label3D = Label3D.new()
	letrero.text = "ANDÉN"
	letrero.font_size = 64
	letrero.pixel_size = 0.006
	letrero.modulate = CREMA
	letrero.outline_size = 10
	letrero.outline_modulate = NOCHE
	letrero.position = Vector3(cx, 2.4, HUECO_Z.x - 0.1)
	p.add_child(letrero)
	var postes_x: Array[float] = [HUECO_X.x, HUECO_X.y]
	for x: float in postes_x:
		_cilindro(p, 0.05, 2.6, Vector3(x, 1.3, HUECO_Z.x - 0.1), _mat(Color(0.7, 0.75, 0.8), Color.BLACK, 0.0, 0.8, 0.3))
	_caja(p, Vector3(w, 0.06, 0.06), Vector3(cx, 2.6, HUECO_Z.x - 0.1), _mat(Color(0.7, 0.75, 0.8), Color.BLACK, 0.0, 0.8, 0.3))


func _baranda(p: Node3D) -> void:
	var vidrio: StandardMaterial3D = _vidrio(Color(0.45, 0.85, 0.95, 0.18))
	var metal: StandardMaterial3D = _mat(Color(0.7, 0.75, 0.8), Color.BLACK, 0.0, 0.8, 0.3)
	var izq: float = -ANCHO / 2.0
	var tramos: Array[Vector2] = [Vector2(izq, HUECO_X.x), Vector2(HUECO_X.y, ANCHO / 2.0)]
	for t: Vector2 in tramos:
		var lx: float = t.y - t.x
		var cx: float = (t.x + t.y) / 2.0
		_caja(p, Vector3(lx, 0.9, 0.04), Vector3(cx, 0.5, Z_FRENTE - 0.1), vidrio)
		_caja(p, Vector3(lx, 0.06, 0.08), Vector3(cx, 0.98, Z_FRENTE - 0.1), metal)
		_forma(Vector3(lx, 2.0, 0.2), Vector3(cx, 1.0, Z_FRENTE - 0.1))
	_forma(Vector3(HUECO_X.y - HUECO_X.x, 2.0, 0.2), Vector3((HUECO_X.x + HUECO_X.y) / 2.0, 1.0, Z_FRENTE + 0.1))
	var lados_hueco: Array[float] = [HUECO_X.x - 0.05, HUECO_X.y + 0.05]
	for x: float in lados_hueco:
		var zc: float = (HUECO_Z.x + HUECO_Z.y) / 2.0
		var lz: float = HUECO_Z.y - HUECO_Z.x
		_caja(p, Vector3(0.04, 0.9, lz), Vector3(x, 0.5, zc), vidrio)
		_caja(p, Vector3(0.08, 0.06, lz), Vector3(x, 0.98, zc), metal)
		_forma(Vector3(0.2, 2.0, lz), Vector3(x, 1.0, zc))


func _maquinas(p: Node3D, x0: float, colores: Array[Color]) -> void:
	var x: float = x0
	for c: Color in colores:
		_maquina(p, Vector3(x, 0, Z_FONDO + 0.45), c)
		x += 1.35
	var l: OmniLight3D = OmniLight3D.new()
	l.light_color = LUZ_ROSA
	l.light_energy = 2.0
	l.omni_range = 5.5
	l.omni_attenuation = 1.3
	l.position = Vector3(x0 + (colores.size() - 1) * 0.675, 2.4, Z_FONDO + 1.6)
	p.add_child(l)


func _maquina(p: Node3D, pos: Vector3, color: Color) -> void:
	var cuerpo: StandardMaterial3D = _mat(color, Color.BLACK, 0.0, 0.2, 0.45)
	_caja(p, Vector3(1.2, 2.1, 0.8), pos + Vector3(0, 1.05, 0), cuerpo)
	_forma(Vector3(1.2, 2.1, 0.8), pos + Vector3(0, 1.05, 0))
	_caja(p, Vector3(0.92, 1.0, 0.02), pos + Vector3(-0.08, 1.4, 0.41), _mat(CREMA, Color(0.88, 0.96, 1.0), 1.3))
	var colores: Array[Color] = [ROSA, CIAN, AMARILLO, NARANJA, Color(0.5, 1.0, 0.6), Color(0.7, 0.5, 1.0), CREMA]
	for fila: int in 3:
		_caja(p, Vector3(0.9, 0.02, 0.05), pos + Vector3(-0.08, 1.05 + fila * 0.31, 0.43), _mat(Color(0.5, 0.55, 0.6)))
		for i: int in 6:
			var c: Color = colores[_rng.randi() % colores.size()]
			var lata: MeshInstance3D = _cilindro(p, 0.045, 0.16, pos + Vector3(-0.45 + i * 0.148, 1.15 + fila * 0.31, 0.44), _mat(c, c, 0.35))
			lata.scale = Vector3(1, 1, 0.5)
	var colores_cartel: Array[Color] = [NARANJA, ROSA, AMARILLO]
	var cartel: Color = colores_cartel[_rng.randi() % 3]
	_caja(p, Vector3(1.0, 0.24, 0.03), pos + Vector3(0, 2.2, 0.42), _mat(cartel, cartel, 1.4))
	_caja(p, Vector3(0.32, 0.18, 0.02), pos + Vector3(-0.35, 0.72, 0.41), _mat(NARANJA, NARANJA, 1.5))
	_caja(p, Vector3(0.6, 0.16, 0.04), pos + Vector3(-0.08, 0.32, 0.42), _mat(NOCHE))
	_caja(p, Vector3(0.09, 0.7, 0.02), pos + Vector3(0.49, 1.35, 0.41), _mat(Color(0.1, 0.12, 0.15)))
	for k: int in 6:
		_esfera(p, 0.018, pos + Vector3(0.49, 1.1 + k * 0.1, 0.425), _mat(ROJO, Color(1, 0.2, 0.2), 2.0))
	_esfera(p, 0.04, pos + Vector3(0.45, 2.0, 0.42), _mat(ROJO, Color(1, 0.15, 0.1), 3.0))


func _sillas(p: Node3D, pos: Vector3, n: int) -> void:
	var asiento: StandardMaterial3D = _mat(NARANJA, Color.BLACK, 0.0, 0.1, 0.4)
	var metal: StandardMaterial3D = _mat(Color(0.6, 0.65, 0.7), Color.BLACK, 0.0, 0.8, 0.35)
	var paso: float = 0.62
	var largo: float = paso * n
	for i: int in n:
		var x: float = pos.x + paso * (i + 0.5) - largo / 2.0
		_caja(p, Vector3(0.54, 0.08, 0.48), Vector3(x, 0.46, pos.z), asiento)
		_caja(p, Vector3(0.54, 0.5, 0.07), Vector3(x, 0.75, pos.z - 0.24), asiento)
	_caja(p, Vector3(largo, 0.05, 0.08), Vector3(pos.x, 0.38, pos.z), metal)
	var signos: Array[int] = [-1, 1]
	for s: int in signos:
		_caja(p, Vector3(0.05, 0.38, 0.4), Vector3(pos.x + s * (largo / 2.0 - 0.1), 0.19, pos.z), metal)
	_forma(Vector3(largo, 1.0, 0.55), Vector3(pos.x, 0.5, pos.z - 0.03))
	var sombra: StandardMaterial3D = _mat(Color(0.02, 0.03, 0.05))
	_caja(p, Vector3(largo + 0.3, 0.004, 0.8), Vector3(pos.x, 0.003, pos.z), sombra)


func _pilar(p: Node3D, pos: Vector3, acento: Color) -> void:
	var m: StandardMaterial3D = _mat(Color(0.48, 0.38, 0.5), Color.BLACK, 0.0, 0.1, 0.5)
	_bloque(p, Vector3(0.8, ALTO, 0.8), pos + Vector3(0, ALTO / 2.0, 0), m)
	_caja(p, Vector3(0.36, 1.8, 0.03), pos + Vector3(0, 2.0, 0.41), _mat(CREMA, Color(1.0, 0.92, 0.95), 1.6))
	_caja(p, Vector3(0.36, 0.12, 0.035), pos + Vector3(0, 1.2, 0.415), _mat(acento, acento, 2.0))
	for k: int in 5:
		_caja(p, Vector3(0.22, 0.03, 0.035), pos + Vector3(0, 2.6 - k * 0.22, 0.415), _mat(NOCHE))


func _carteles(p: Node3D) -> void:
	var fondos: Array[Color] = [ROSA, CIAN, AMARILLO, NARANJA, Color(0.7, 0.55, 0.85), CREMA]
	var tinta: Array[Color] = [NOCHE, ROJO, CREMA, Color(0.25, 0.35, 0.55)]
	var xs: Array[float] = [-14.2, -8.0, -6.6, -4.4, -0.8, 0.6, 3.6, 8.0, 14.45]
	var tipo: int = 0
	for x: float in xs:
		var fondo: Color = fondos[_rng.randi() % fondos.size()]
		var c: Color = tinta[_rng.randi() % tinta.size()]
		var y: float = 1.9 + _rng.randf_range(-0.15, 0.25)
		var base: Vector3 = Vector3(x, y, Z_FONDO + 0.02)
		_caja(p, Vector3(0.8, 1.1, 0.02), base, _mat(fondo, fondo, 0.25))
		var zf: float = Z_FONDO + 0.04
		match tipo % 4:
			0:
				var sol: MeshInstance3D = _cilindro(p, 0.22, 0.01, Vector3(x, y + 0.2, zf), _mat(c, c, 0.4))
				sol.rotation.x = PI / 2.0
				for k: int in 3:
					_caja(p, Vector3(0.6, 0.05, 0.01), Vector3(x, y - 0.18 - k * 0.1, zf), _mat(c, c, 0.4))
			1:
				var gm: StandardMaterial3D = _mat(NOCHE)
				var cuerpo: MeshInstance3D = _esfera(p, 0.16, Vector3(x + 0.05, y - 0.15, zf), gm)
				cuerpo.scale = Vector3(1.5, 0.75, 0.1)
				_esfera(p, 0.1, Vector3(x - 0.18, y - 0.06, zf), gm).scale = Vector3(1, 1, 0.1)
				var orejas_x: Array[float] = [-0.23, -0.13]
				for ox: float in orejas_x:
					var oreja: MeshInstance3D = MeshInstance3D.new()
					var pm: PrismMesh = PrismMesh.new()
					pm.size = Vector3(0.07, 0.08, 0.01)
					oreja.mesh = pm
					oreja.material_override = gm
					oreja.position = Vector3(x + ox, y + 0.08, zf)
					p.add_child(oreja)
				_caja(p, Vector3(0.6, 0.06, 0.01), Vector3(x, y + 0.35, zf), _mat(c, c, 0.4))
			2:
				var cuad_colores: Array[Color] = [ROSA, CIAN, AMARILLO, ROJO]
				for k: int in 4:
					var col: Color = cuad_colores[k]
					_caja(p, Vector3(0.28, 0.28, 0.01), Vector3(x - 0.15 + (k % 2) * 0.3, y + 0.15 - floorf(k / 2.0) * 0.3, zf), _mat(col, col, 0.4))
			3:
				_caja(p, Vector3(0.12, 0.6, 0.01), Vector3(x - 0.2, y, zf), _mat(c, c, 0.4))
				_caja(p, Vector3(0.4, 0.08, 0.01), Vector3(x + 0.1, y + 0.2, zf), _mat(c, c, 0.4))
				_caja(p, Vector3(0.3, 0.08, 0.01), Vector3(x + 0.05, y, zf), _mat(c, c, 0.4))
		tipo += 1


func _mural(p: Node3D) -> void:
	var x: float = 12.0
	var z: float = Z_FONDO + 0.03
	_caja(p, Vector3(3.6, 2.4, 0.01), Vector3(x, 1.7, z), _mat(Color(0.92, 0.82, 0.86), Color(0.7, 0.6, 0.66), 0.25))
	var r1: MeshInstance3D = _cilindro(p, 1.0, 0.01, Vector3(x - 0.9, 1.2, z + 0.01), _mat(ROJO, ROJO, 0.5))
	r1.rotation.x = PI / 2.0
	var r2: MeshInstance3D = _cilindro(p, 0.7, 0.01, Vector3(x + 0.8, 2.1, z + 0.015), _mat(Color(0.25, 0.4, 0.6), Color(0.3, 0.45, 0.65), 0.35))
	r2.rotation.x = PI / 2.0
	_caja(p, Vector3(1.4, 0.12, 0.01), Vector3(x + 0.6, 0.9, z + 0.02), _mat(NOCHE))


func _viga_luz(p: Node3D) -> void:
	_caja(p, Vector3(ANCHO - 1.0, 0.14, 0.35), Vector3(0, 3.7, Z_FONDO + 1.4), _mat(NOCHE))
	_caja(p, Vector3(ANCHO - 1.2, 0.04, 0.25), Vector3(0, 3.62, Z_FONDO + 1.4), _mat(LUZ_ROSA, LUZ_ROSA, 2.2))
	var x: float = -ANCHO / 2.0 + 3.0
	while x < ANCHO / 2.0:
		var l: OmniLight3D = OmniLight3D.new()
		l.light_color = LUZ_ROSA
		l.light_energy = 1.4
		l.omni_range = 6.0
		l.omni_attenuation = 1.2
		l.position = Vector3(x, 3.3, Z_FONDO + 1.8)
		p.add_child(l)
		x += 6.0
	var centros_luz: Array[float] = [-6.0, 1.5]
	for xc: float in centros_luz:
		var c: OmniLight3D = OmniLight3D.new()
		c.light_color = Color(0.75, 0.6, 0.95)
		c.light_energy = 1.0
		c.omni_range = 4.5
		c.position = Vector3(xc, 2.6, 1.0)
		p.add_child(c)


func _detalles(p: Node3D) -> void:
	var caneca: MeshInstance3D = _cilindro(p, 0.22, 0.75, Vector3(-3.4, 0.375, -0.4), _mat(ROJO, Color.BLACK, 0.0, 0.3, 0.4))
	_forma(Vector3(0.45, 0.8, 0.45), caneca.position)
	_cilindro(p, 0.18, 0.03, Vector3(-3.4, 0.76, -0.4), _mat(Color(0.15, 0.15, 0.18)))
	var reloj: MeshInstance3D = _cilindro(p, 0.35, 0.05, Vector3(-9.8, 3.0, Z_FONDO + 0.05), _mat(CREMA, CREMA, 0.6))
	reloj.rotation.x = PI / 2.0
	var angulos: Array[float] = [0.0, 1.9]
	for a: float in angulos:
		var aguja: MeshInstance3D = _caja(p, Vector3(0.03, 0.26, 0.01), Vector3(-9.8, 3.0, Z_FONDO + 0.09), _mat(NOCHE))
		aguja.rotation.z = a
		aguja.position += Vector3(sin(-a), cos(a), 0) * 0.1
	var pilotos_x: Array[float] = [-14.6, 14.6]
	for x: float in pilotos_x:
		_esfera(p, 0.06, Vector3(x, 2.8, Z_FONDO + 0.1), _mat(ROJO, Color(1, 0.15, 0.1), 4.0))


func _ladrillo(c1: Color, c2: Color, tam: Vector2, piso: bool, manchas: float) -> ShaderMaterial:
	var m: ShaderMaterial = ShaderMaterial.new()
	m.shader = LADRILLO
	m.set_shader_parameter("color_ladrillo", c1)
	m.set_shader_parameter("color_junta", c2)
	m.set_shader_parameter("tamano", tam)
	m.set_shader_parameter("desfase", 0.0 if piso else 0.5)
	m.set_shader_parameter("junta", 0.04)
	m.set_shader_parameter("variacion", 0.08)
	m.set_shader_parameter("pixel", 0.04)
	m.set_shader_parameter("rugosidad", 0.35 if piso else 0.8)
	m.set_shader_parameter("en_piso", piso)
	m.set_shader_parameter("manchas", manchas)
	return m


func _bloque(p: Node3D, tam: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = _caja(p, tam, pos, mat)
	_forma(tam, pos)
	return mi


func _caja(padre: Node3D, tam: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var b: BoxMesh = BoxMesh.new()
	b.size = tam
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	padre.add_child(mi)
	return mi


func _cilindro(padre: Node3D, radio: float, alto: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var c: CylinderMesh = CylinderMesh.new()
	c.top_radius = radio
	c.bottom_radius = radio
	c.height = alto
	c.radial_segments = 16
	mi.mesh = c
	mi.material_override = mat
	mi.position = pos
	padre.add_child(mi)
	return mi


func _esfera(padre: Node3D, radio: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var e: SphereMesh = SphereMesh.new()
	e.radius = radio
	e.height = radio * 2.0
	e.radial_segments = 12
	e.rings = 6
	mi.mesh = e
	mi.material_override = mat
	mi.position = pos
	padre.add_child(mi)
	return mi


func _forma(tam: Vector3, pos: Vector3) -> CollisionShape3D:
	var c: CollisionShape3D = CollisionShape3D.new()
	var b: BoxShape3D = BoxShape3D.new()
	b.size = tam
	c.shape = b
	c.position = pos
	choques.add_child(c)
	return c


func _mat(color: Color, emision: Color = Color.BLACK, energia: float = 0.0, metal: float = 0.0, rugosidad: float = 0.7) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = rugosidad
	if energia > 0.0:
		m.emission_enabled = true
		m.emission = emision
		m.emission_energy_multiplier = energia
	return m


func _vidrio(color: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = _mat(color, Color.BLACK, 0.0, 0.4, 0.08)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
