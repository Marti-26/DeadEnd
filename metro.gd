@tool
class_name Metro
extends Node3D

signal llego
signal se_fue

enum Estado { FUERA, LLEGANDO, DETENIDO, SALIENDO }


class PuertaMovil:
	var nodo: Node3D
	var cerrado_x: float
	var abierto_x: float

	func _init(p_nodo: Node3D, p_cerrado_x: float, p_abierto_x: float) -> void:
		nodo = p_nodo
		cerrado_x = p_cerrado_x
		abierto_x = p_abierto_x


class MaterialesMetro:
	var rojo_ext: StandardMaterial3D
	var rojo_oscuro: StandardMaterial3D
	var franja: StandardMaterial3D
	var lila: StandardMaterial3D
	var ciruela: StandardMaterial3D
	var cielo: StandardMaterial3D
	var piso: ShaderMaterial
	var morado: ShaderMaterial
	var laton: StandardMaterial3D
	var rosa: StandardMaterial3D
	var aro: StandardMaterial3D
	var oscuro: StandardMaterial3D
	var gris: StandardMaterial3D
	var ventana: ShaderMaterial
	var vidrio: ShaderMaterial
	var vidrio_ext: StandardMaterial3D
	var vidrio_anden: StandardMaterial3D
	var tubos: Array[ShaderMaterial] = []
	var neon_rosa: StandardMaterial3D
	var neon_morado: StandardMaterial3D
	var ambar: StandardMaterial3D
	var salida: StandardMaterial3D
	var cono: ShaderMaterial
	var faro: StandardMaterial3D
	var cola: StandardMaterial3D
	var rojo: StandardMaterial3D
	var verde: StandardMaterial3D
	var amarillo_piso: StandardMaterial3D


@export var camara_estacion: Camera3D
@export var tiempo_fuera: float = 20.0
@export var primera_llegada: float = 8.0
@export var tiempo_detenido: float = 20.0
@export var tiempo_frenado: float = 6.0
@export var distancia: float = 70.0
@export var x_parada: float = 0.0
@export var puertas_x: Array[float] = [-7.5, 0.0, 7.5]
@export var filtro_pantalla: bool = false

const LARGO: float = 24.0
const ANCHO: float = 3.0
const ALTO: float = 2.7
const ALTO_PUERTA: float = 2.1
const ANCHO_PUERTA: float = 1.4
const Z_COMPUERTA: float = -1.85

const ROJO: Color = Color(0.72, 0.09, 0.1)
const ROJO_OSCURO: Color = Color(0.45, 0.05, 0.07)
const PARED_ALTA: Color = Color(0.14, 0.15, 0.26)
const PARED_BAJA: Color = Color(0.08, 0.085, 0.14)
const CIELO: Color = Color(0.11, 0.115, 0.21)
const AZUL_LED: Color = Color(0.55, 0.6, 1.0)
const VIOLETA: Color = Color(0.5, 0.42, 1.0)
const NARANJA: Color = Color(1.0, 0.5, 0.22)
const AMARILLO: Color = Color(1.0, 0.75, 0.35)
const CROMO: Color = Color(0.62, 0.65, 0.75)
const MENTA: Color = Color(0.45, 0.85, 0.75)
const CREMA: Color = Color(0.9, 0.88, 0.85)
const NOCHE: Color = Color(0.05, 0.05, 0.09)
const COLOR_MARCADOR: Color = Color(0.6, 0.9, 1.0)
const COLOR_ENTRAR: Color = Color(1.0, 0.78, 0.35)
const ALTO_MARCADOR: float = 3.3

var estado: Estado = Estado.FUERA
var reloj: float = 0.0
var inicio: float = 0.0
var proxima: float = 0.0
var apertura: float = 0.0
var dentro: bool = false
var viajando: bool = false
var jugador: CharacterBody3D = null
var _abiertas: bool = false
var _capas_plataforma: int = 0

var tren: Node3D
var cuerpo: AnimatableBody3D
var camara_vagon: Camera3D
var lado_camara: Node3D
var techo: Node3D
var hojas: Array[PuertaMovil] = []
var formas_puerta: Array[CollisionShape3D] = []
var compuertas: Array[PuertaMovil] = []
var formas_compuerta: Array[CollisionShape3D] = []
var indicadores: Array[MeshInstance3D] = []
var _m: MaterialesMetro = MaterialesMetro.new()
var recorrido: float = 0.0
var movimiento: float = 0.0
var _x_antes: float = 0.0
var filtro: CanvasLayer
var marcador: Node3D
var _mat_marcador: StandardMaterial3D


func _ready() -> void:
	_construir()
	if Engine.is_editor_hint():
		return
	jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	proxima = primera_llegada
	tren.position.x = x_parada + distancia
	_x_antes = tren.position.x
	if filtro_pantalla:
		_filtro()
	_crear_marcador()

	_actualizar_vista()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	reloj += delta
	var t: float = reloj - inicio
	match estado:
		Estado.FUERA:
			if reloj >= proxima:
				_cambiar(Estado.LLEGANDO)
		Estado.LLEGANDO:
			var s: float = minf(t / tiempo_frenado, 1.0)
			tren.position.x = x_parada + distancia * pow(1.0 - s, 2.0)
			if s >= 1.0:
				_cambiar(Estado.DETENIDO)
		Estado.DETENIDO:
			if t >= tiempo_detenido:
				_cambiar(Estado.SALIENDO)
		Estado.SALIENDO:
			var s: float = minf(t / tiempo_frenado, 1.0)
			tren.position.x = x_parada - distancia * s * s
			if s >= 1.0:
				_cambiar(Estado.FUERA)
				proxima = reloj + tiempo_fuera
				var salto: float = (x_parada + distancia) - tren.position.x
				tren.position.x += salto
				_x_antes += salto
				if viajando and jugador:
					jugador.global_position.x += salto

	t = reloj - inicio
	var abrir: bool = estado == Estado.DETENIDO and t > 0.6 and t < tiempo_detenido - 1.6
	if _abiertas and not abrir:
		_al_cerrar()
	_abiertas = abrir
	apertura = move_toward(apertura, 1.0 if abrir else 0.0, delta / 0.9)
	_mover_puertas()

	var dx: float = tren.position.x - _x_antes
	var v: float = absf(dx) / maxf(delta, 0.0001)
	_x_antes = tren.position.x
	if viajando and jugador:
		jugador.global_position.x += dx
	if estado == Estado.FUERA and viajando:
		v = 14.0
	recorrido += v * delta
	movimiento = lerpf(movimiento, clampf(v / 10.0, 0.0, 1.0), 1.0 - exp(-4.0 * delta))
	_m.ventana.set_shader_parameter("recorrido", recorrido)
	_m.ventana.set_shader_parameter("movimiento", movimiento)
	_m.ventana.set_shader_parameter("tren_x", tren.global_position.x)
	if filtro:
		var rect: ColorRect = filtro.get_child(0) as ColorRect
		var mat_filtro: ShaderMaterial = rect.material as ShaderMaterial
		mat_filtro.set_shader_parameter("movimiento", movimiento)

	_actualizar_marcador()
	if dentro and jugador:
		var l: Vector3 = tren.to_local(jugador.global_position)
		var mitad: float = LARGO / 2.0 - 3.3
		var meta: float = clampf(l.x, -mitad, mitad)
		camara_vagon.position.x = lerpf(camara_vagon.position.x, meta, 1.0 - exp(-5.0 * delta))


func _cambiar(nuevo: Estado) -> void:
	estado = nuevo
	inicio = reloj
	print("metro -> ", Estado.keys()[estado], " a los ", snappedf(reloj, 0.1), " s")
	if estado == Estado.DETENIDO:
		if viajando:
			viajando = false
			jugador.platform_floor_layers = _capas_plataforma
			print("la gata llega en el metro")
		llego.emit()
	elif estado == Estado.FUERA:
		se_fue.emit()
	_actualizar_vista()


func _al_cerrar() -> void:
	if jugador == null:
		return
	var l: Vector3 = tren.to_local(jugador.global_position)
	if absf(l.x) < LARGO / 2.0 and l.z < -1.25 and l.z > -2.3:
		if l.z > -1.55:
			jugador.global_position = tren.to_global(Vector3(l.x, l.y, -0.9))
		else:
			jugador.global_position.z = global_position.z + Z_COMPUERTA - 0.45
		l = tren.to_local(jugador.global_position)
	if absf(l.x) < LARGO / 2.0 - 0.1 and absf(l.z) < ANCHO / 2.0 - 0.05:
		viajando = true
		_capas_plataforma = jugador.platform_floor_layers
		jugador.platform_floor_layers = 0
		if not dentro:
			_entrar_vista()
		print("la gata se va en el metro")


func _al_entrar(cuerpo_entra: Node3D) -> void:
	if cuerpo_entra.is_in_group("jugador"):
		_entrar_vista()


func _al_salir(cuerpo_sale: Node3D) -> void:
	if cuerpo_sale.is_in_group("jugador") and not viajando:
		dentro = false
		jugador.remove_from_group("fuera_de_alcance")
		if camara_estacion:
			camara_estacion.make_current()
		_actualizar_vista()


func _entrar_vista() -> void:
	dentro = true
	jugador.add_to_group("fuera_de_alcance")
	var l: Vector3 = tren.to_local(jugador.global_position)
	camara_vagon.position.x = clampf(l.x, -LARGO / 2.0 + 3.3, LARGO / 2.0 - 3.3)
	camara_vagon.make_current()
	_actualizar_vista()


func _actualizar_vista() -> void:
	lado_camara.visible = not dentro
	techo.visible = true
	if filtro:
		filtro.visible = dentro


func _mover_puertas() -> void:
	var a: float = apertura
	a = a * a * (3.0 - 2.0 * a)
	for h: PuertaMovil in hojas:
		h.nodo.position.x = lerpf(h.cerrado_x, h.abierto_x, a)
	for c: PuertaMovil in compuertas:
		c.nodo.position.x = lerpf(c.cerrado_x, c.abierto_x, a)
	var cerradas: bool = apertura < 0.9
	for f: CollisionShape3D in formas_puerta:
		f.disabled = not cerradas
	for f: CollisionShape3D in formas_compuerta:
		f.disabled = not cerradas
	var m: StandardMaterial3D = _m.verde if apertura > 0.5 else _m.rojo
	for i: MeshInstance3D in indicadores:
		i.material_override = m


func _construir() -> void:
	for h: Node in get_children():
		if h.name == "Tren" or h.name == "Compuertas":
			remove_child(h)
			h.free()
	hojas.clear()
	formas_puerta.clear()
	compuertas.clear()
	formas_compuerta.clear()
	indicadores.clear()
	_materiales()

	tren = _nodo(self, "Tren")
	tren.position.x = x_parada
	cuerpo = AnimatableBody3D.new()
	cuerpo.name = "Cuerpo"
	cuerpo.sync_to_physics = false
	tren.add_child(cuerpo)

	var interior: Node3D = _nodo(tren, "Interior")
	var lado_anden: Node3D = _nodo(tren, "LadoAnden")
	lado_camara = _nodo(tren, "LadoCamara")
	techo = _nodo(tren, "Techo")
	var bajo: Node3D = _nodo(tren, "Bajos")
	var frentes: Node3D = _nodo(tren, "Frentes")

	_piso(interior)
	_lado(lado_anden, -1, true)
	_lado(lado_camara, 1, false)
	_asientos(interior, -1)
	_asientos(lado_camara, 1)
	_barras_y_agarraderas(interior)
	_techo(techo)
	_frentes(frentes)
	_bajos(bajo)
	_carteles(interior)
	_luces(interior)
	_compuertas()

	camara_vagon = Camera3D.new()
	camara_vagon.name = "CamaraVagon"
	camara_vagon.projection = Camera3D.PROJECTION_ORTHOGONAL
	camara_vagon.size = 3.6
	camara_vagon.far = 40.0
	camara_vagon.position = Vector3(0, 1.35, 7.0)
	tren.add_child(camara_vagon)

	var zona: Area3D = Area3D.new()
	zona.name = "ZonaInterior"
	zona.collision_layer = 0
	tren.add_child(zona)
	var fz: CollisionShape3D = CollisionShape3D.new()
	var bz: BoxShape3D = BoxShape3D.new()
	bz.size = Vector3(LARGO - 0.4, 2.4, ANCHO - 0.4)
	fz.shape = bz
	fz.position = Vector3(0, 1.25, 0)
	zona.add_child(fz)
	if not Engine.is_editor_hint():
		zona.body_entered.connect(_al_entrar)
		zona.body_exited.connect(_al_salir)
	_mover_puertas()


func _materiales() -> void:
	_m.rojo_ext = _mat(ROJO, Color.BLACK, 0.0, 0.35, 0.4)
	_m.rojo_oscuro = _mat(ROJO_OSCURO, Color.BLACK, 0.0, 0.3, 0.5)
	_m.franja = _mat(CREMA, CREMA, 0.4, 0.0, 0.5)
	_m.lila = _mat(PARED_ALTA, Color.BLACK, 0.0, 0.2, 0.5)
	_m.ciruela = _mat(PARED_BAJA, Color.BLACK, 0.0, 0.2, 0.6)
	_m.cielo = _mat(CIELO, Color.BLACK, 0.0, 0.1, 0.6)
	_m.piso = _shader("piso_vagon")
	_m.morado = _shader("tela_asiento")
	_m.laton = _mat(CROMO, Color.BLACK, 0.0, 0.9, 0.25)
	_m.rosa = _mat(AZUL_LED, AZUL_LED, 0.8, 0.0, 0.4)
	_m.aro = _mat(Color(0.16, 0.17, 0.25), Color.BLACK, 0.0, 0.3, 0.5)
	_m.oscuro = _mat(Color(0.04, 0.04, 0.07))
	_m.gris = _mat(Color(0.22, 0.22, 0.25), Color.BLACK, 0.0, 0.5, 0.6)
	_m.ventana = _shader("ventana_vagon")
	_m.vidrio = _m.ventana
	_m.vidrio_ext = _mat(Color(0.03, 0.035, 0.07), Color(0.12, 0.14, 0.3), 0.35, 0.7, 0.08)
	_m.vidrio_anden = _vidrio(Color(0.35, 0.75, 0.7, 0.3))
	_m.tubos.clear()
	for i: int in 3:
		var tubo: ShaderMaterial = _shader("tubo_led")
		tubo.set_shader_parameter("semilla", float(i) * 3.7 + 1.0)
		_m.tubos.append(tubo)
	_m.neon_rosa = _mat(NARANJA, NARANJA, 2.5)
	_m.neon_morado = _mat(VIOLETA, VIOLETA, 2.0)
	_m.ambar = _mat(NARANJA, Color(1, 0.45, 0.2), 3.0)
	_m.salida = _mat(Color(0.9, 0.1, 0.1), Color(1, 0.12, 0.08), 3.5)
	_m.cono = ShaderMaterial.new()
	_m.cono.shader = load("res://zona_b/cono_luz.gdshader") as Shader
	_m.cono.set_shader_parameter("color", Color(0.45, 0.5, 1.0))
	_m.cono.set_shader_parameter("intensidad", 0.16)
	_m.cono.set_shader_parameter("altura", 2.4)
	_m.faro = _mat(CREMA, Color(1, 0.92, 0.7), 6.0)
	_m.cola = _mat(Color(0.9, 0.1, 0.1), Color(1, 0.1, 0.08), 5.0)
	_m.rojo = _mat(Color(0.9, 0.1, 0.1), Color(1, 0.12, 0.08), 4.0)
	_m.verde = _mat(MENTA, MENTA, 4.0)
	_m.amarillo_piso = _mat(AMARILLO, Color(1, 0.6, 0.25), 0.5)


func _tramos() -> Array[Vector2]:
	var r: Array[Vector2] = []
	var x: float = -LARGO / 2.0
	var lista: Array[float] = puertas_x.duplicate()
	lista.sort()
	for px: float in lista:
		r.append(Vector2(x, px - ANCHO_PUERTA / 2.0))
		x = px + ANCHO_PUERTA / 2.0
	r.append(Vector2(x, LARGO / 2.0))
	return r


func _piso(p: Node3D) -> void:
	_caja(p, Vector3(LARGO - 0.1, 0.02, ANCHO - 0.1), Vector3(0, -0.005, 0), _m.piso)
	_forma(Vector3(LARGO, 0.3, ANCHO), Vector3(0, -0.15, 0))
	for px: float in puertas_x:
		_caja(p, Vector3(ANCHO_PUERTA, 0.01, 0.14), Vector3(px, 0.01, -ANCHO / 2.0 + 0.12), _m.amarillo_piso)


func _lado(p: Node3D, s: int, reales: bool) -> void:
	var z: float = s * ANCHO / 2.0
	for t: Vector2 in _tramos():
		var lx: float = t.y - t.x
		var cx: float = (t.x + t.y) / 2.0
		_caja(p, Vector3(lx, 1.3, 0.04), Vector3(cx, 0.3, z + s * 0.03), _m.rojo_ext)
		_caja(p, Vector3(lx, 0.8, 0.04), Vector3(cx, 2.45, z + s * 0.03), _m.rojo_ext)
		_caja(p, Vector3(lx, 0.06, 0.05), Vector3(cx, 0.82, z + s * 0.04), _m.franja)
		_caja(p, Vector3(lx, 0.95, 0.04), Vector3(cx, 0.475, z - s * 0.03), _m.ciruela)
		_caja(p, Vector3(lx, 0.65, 0.04), Vector3(cx, 2.375, z - s * 0.03), _m.lila)
		_caja(p, Vector3(lx, 0.035, 0.05), Vector3(cx, 0.96, z - s * 0.04), _m.rosa)
		var n: int = maxi(1, roundi(lx / 1.9))
		var pilar: float = 0.16
		var vw: float = (lx - (n + 1) * pilar) / n
		for i: int in n + 1:
			var px: float = t.x + pilar / 2.0 + i * (vw + pilar)
			_caja(p, Vector3(pilar, 1.1, 0.1), Vector3(px, 1.5, z), _m.rojo_oscuro if reales else _m.rojo_ext)
		for i: int in n:
			var vx: float = t.x + pilar + vw / 2.0 + i * (vw + pilar)
			_caja(p, Vector3(vw, 1.1, 0.02), Vector3(vx, 1.5, z), _m.vidrio if reales else _m.vidrio_ext)
		_forma(Vector3(lx, ALTO, 0.12), Vector3(cx, ALTO / 2.0, z))
	var lados_puerta: Array[int] = [-1, 1]
	for px: float in puertas_x:
		_caja(p, Vector3(ANCHO_PUERTA, 0.75, 0.04), Vector3(px, 2.475, z + s * 0.03), _m.rojo_ext)
		_caja(p, Vector3(ANCHO_PUERTA, 0.6, 0.04), Vector3(px, 2.4, z - s * 0.03), _m.lila)
		_caja(p, Vector3(ANCHO_PUERTA, 0.35, 0.04), Vector3(px, -0.175, z + s * 0.03), _m.rojo_ext)
		for lado: int in lados_puerta:
			var hoja: Node3D = _hoja(p, Vector3(px + lado * ANCHO_PUERTA / 4.0, ALTO_PUERTA / 2.0, z))
			if reales:
				hojas.append(PuertaMovil.new(hoja, px + lado * ANCHO_PUERTA / 4.0, px + lado * (ANCHO_PUERTA * 0.75 + 0.05)))
		if reales:
			var f: CollisionShape3D = _forma(Vector3(ANCHO_PUERTA, ALTO_PUERTA, 0.12), Vector3(px, ALTO_PUERTA / 2.0, z))
			formas_puerta.append(f)
			for k: int in lados_puerta:
				var ind: MeshInstance3D = _caja(p, Vector3(0.22, 0.07, 0.03), Vector3(px, 2.2, z + k * 0.07), _m.rojo)
				indicadores.append(ind)
			_mapa_ruta(p, px, z - s * 0.06)
			_caja(p, Vector3(0.12, 0.2, 0.03), Vector3(px + 0.85, 1.35, z - s * 0.06), _m.oscuro)
			_caja(p, Vector3(0.05, 0.05, 0.02), Vector3(px + 0.85, 1.4, z - s * 0.08), _m.verde)
			_caja(p, Vector3(0.14, 0.1, 0.04), Vector3(px - 0.88, 1.6, z - s * 0.06), _m.ambar)
		else:
			_forma(Vector3(ANCHO_PUERTA, ALTO_PUERTA, 0.12), Vector3(px, ALTO_PUERTA / 2.0, z))


func _hoja(p: Node3D, pos: Vector3) -> Node3D:
	var h: Node3D = _nodo(p, "Hoja")
	h.position = pos
	var w: float = ANCHO_PUERTA / 2.0
	_caja(h, Vector3(w, ALTO_PUERTA, 0.05), Vector3.ZERO, _m.rojo_ext)
	_caja(h, Vector3(w - 0.24, 0.75, 0.07), Vector3(0, 0.35, 0), _m.vidrio_ext)
	_caja(h, Vector3(w - 0.1, 0.04, 0.07), Vector3(0, -0.2, 0), _m.franja)
	return h


func _mapa_ruta(p: Node3D, x: float, z: float) -> void:
	var y: float = 2.45
	_caja(p, Vector3(1.2, 0.2, 0.02), Vector3(x, y, z), _m.oscuro)
	_caja(p, Vector3(1.0, 0.02, 0.01), Vector3(x, y, z - signf(z) * 0.015), _m.ambar)
	var colores: Array[Material] = [_m.neon_morado, _m.neon_morado, _m.neon_rosa, _m.verde, _m.neon_morado, _m.neon_morado]
	for i: int in 6:
		var e: MeshInstance3D = _esfera(p, 0.025, Vector3(x - 0.5 + i * 0.2, y, z - signf(z) * 0.02), colores[i])
		if i == 3:
			e.scale = Vector3.ONE * 1.6


func _asientos(p: Node3D, s: int) -> void:
	var z: float = s * 1.18
	for t: Vector2 in _tramos():
		var x0: float = t.x + 0.25
		var x1: float = t.y - 0.25
		var lx: float = x1 - x0
		if lx < 1.0:
			continue
		var cx: float = (x0 + x1) / 2.0
		_caja(p, Vector3(lx, 0.36, 0.42), Vector3(cx, 0.18, z), _m.ciruela)
		_caja(p, Vector3(lx - 0.1, 0.16, 0.01), Vector3(cx, 0.18, z - s * 0.215), _m.oscuro)
		var n: int = maxi(1, int(lx / 0.55))
		var w: float = lx / n
		for i: int in n:
			var sx: float = x0 + w * (i + 0.5)
			_caja(p, Vector3(w - 0.04, 0.09, 0.44), Vector3(sx, 0.405, z), _m.morado)
			_caja(p, Vector3(w - 0.04, 0.46, 0.07), Vector3(sx, 0.73, s * 1.41), _m.morado)
		var extremos_x: Array[float] = [x0 - 0.04, x1 + 0.04]
		for ex: float in extremos_x:
			_caja(p, Vector3(0.03, 0.75, 0.5), Vector3(ex, 0.75, z), _m.vidrio)
			_cilindro(p, 0.025, ALTO, Vector3(ex, ALTO / 2.0, s * 0.9), _m.laton)
		_forma(Vector3(lx, 0.5, 0.5), Vector3(cx, 0.25, z))


func _barras_y_agarraderas(p: Node3D) -> void:
	var mm_correa: MultiMesh = MultiMesh.new()
	var mm_aro: MultiMesh = MultiMesh.new()
	var correa: BoxMesh = BoxMesh.new()
	correa.size = Vector3(0.03, 0.26, 0.02)
	var aro: TorusMesh = TorusMesh.new()
	aro.inner_radius = 0.055
	aro.outer_radius = 0.085
	var posiciones: Array[Vector3] = []
	var barras_z: Array[float] = [-0.62, 0.62]
	for zb: float in barras_z:
		var barra: MeshInstance3D = _cilindro(p, 0.022, LARGO - 0.4, Vector3(0, 2.32, zb), _m.laton)
		barra.rotation.z = PI / 2.0
		var x: float = -LARGO / 2.0 + 0.7
		while x < LARGO / 2.0 - 0.5:
			posiciones.append(Vector3(x, 0, zb))
			x += 0.6
	var mms: Array[MultiMesh] = [mm_correa, mm_aro]
	for mm: MultiMesh in mms:
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = posiciones.size()
	mm_correa.mesh = correa
	mm_aro.mesh = aro
	for i: int in posiciones.size():
		var q: Vector3 = posiciones[i]
		mm_correa.set_instance_transform(i, Transform3D(Basis(), q + Vector3(0, 2.18, 0)))
		mm_aro.set_instance_transform(i, Transform3D(Basis(Vector3.RIGHT, PI / 2.0), q + Vector3(0, 1.98, 0)))
	var mi1: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mi1.multimesh = mm_correa
	mi1.material_override = _m.oscuro
	p.add_child(mi1)
	var mi2: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mi2.multimesh = mm_aro
	mi2.material_override = _m.aro
	p.add_child(mi2)
	var lados: Array[int] = [-1, 1]
	for px: float in puertas_x:
		for lado: int in lados:
			_cilindro(p, 0.025, ALTO, Vector3(px + lado * 0.85, ALTO / 2.0, -0.95), _m.laton)
		_cilindro(p, 0.03, ALTO, Vector3(px, ALTO / 2.0, 0.15), _m.laton)


func _techo(p: Node3D) -> void:
	_caja(p, Vector3(LARGO + 0.2, 0.18, ANCHO + 0.1), Vector3(0, 2.94, 0), _m.rojo_oscuro)
	_caja(p, Vector3(LARGO - 0.1, 0.03, ANCHO - 0.1), Vector3(0, ALTO - 0.01, 0), _m.cielo)
	var unidades_x: Array[float] = [-6.0, 6.0]
	for x: float in unidades_x:
		_caja(p, Vector3(3.0, 0.3, 1.6), Vector3(x, 3.18, 0), _m.gris)
		for k: int in 4:
			_caja(p, Vector3(0.05, 0.02, 1.4), Vector3(x - 1.1 + k * 0.7, 3.34, 0), _m.oscuro)
	var i: int = 0
	var tubos_z: Array[float] = [-0.8, 0.8]
	for zt: float in tubos_z:
		var x: float = -LARGO / 2.0 + 1.3
		while x < LARGO / 2.0 - 1.0:
			_caja(p, Vector3(1.7, 0.05, 0.18), Vector3(x, ALTO - 0.04, zt), _m.oscuro)
			_caja(p, Vector3(1.6, 0.05, 0.1), Vector3(x, ALTO - 0.085, zt), _m.tubos[i % 3])
			x += 2.0
			i += 1
	_caja(p, Vector3(LARGO - 0.4, 0.02, 0.02), Vector3(0, 2.07, -1.42), _m.neon_morado)
	var rejillas_x: Array[float] = [-9.0, -3.0, 3.0, 9.0]
	for vx: float in rejillas_x:
		for k: int in 5:
			_caja(p, Vector3(0.6, 0.015, 0.03), Vector3(vx, ALTO - 0.03, -0.75 + k * 0.06), _m.oscuro)


func _frentes(p: Node3D) -> void:
	var signos: Array[int] = [-1, 1]
	var luces_z: Array[float] = [-1.0, 1.0]
	for s: int in signos:
		var x: float = s * LARGO / 2.0
		_caja(p, Vector3(0.08, 3.2, ANCHO), Vector3(x + s * 0.04, 1.25, 0), _m.rojo_ext)
		_caja(p, Vector3(0.04, ALTO, ANCHO - 0.1), Vector3(x - s * 0.03, ALTO / 2.0, 0), _m.lila)
		_forma(Vector3(0.12, ALTO, ANCHO), Vector3(x, ALTO / 2.0, 0))
		_caja(p, Vector3(0.03, 0.9, ANCHO - 0.7), Vector3(x + s * 0.09, 1.75, 0), _m.vidrio_ext)
		_caja(p, Vector3(0.03, 0.22, 1.4), Vector3(x + s * 0.09, 2.5, 0), _m.ambar)
		_caja(p, Vector3(0.04, 0.06, ANCHO), Vector3(x + s * 0.1, 0.9, 0), _m.franja)
		for zl: float in luces_z:
			_esfera(p, 0.1, Vector3(x + s * 0.1, 0.45, zl), _m.faro if s < 0 else _m.cola)
		_caja(p, Vector3(0.03, 2.0, 0.8), Vector3(x - s * 0.06, 1.0, 0), _m.ciruela)
		_caja(p, Vector3(0.035, 0.6, 0.45), Vector3(x - s * 0.065, 1.45, 0), _m.vidrio_ext)
		_cilindro(p, 0.08, 0.45, Vector3(x - s * 0.2, 0.3, 1.1), _mat(Color(0.85, 0.1, 0.1), Color.BLACK, 0.0, 0.3, 0.4))
	var faro: OmniLight3D = OmniLight3D.new()
	faro.light_color = Color(1, 0.92, 0.75)
	faro.light_energy = 2.0
	faro.omni_range = 7.0
	faro.position = Vector3(-LARGO / 2.0 - 1.5, 0.6, 0)
	p.add_child(faro)


func _bajos(p: Node3D) -> void:
	_caja(p, Vector3(LARGO - 0.4, 0.3, ANCHO - 0.3), Vector3(0, -0.5, 0), _m.oscuro)
	var bogies_x: Array[float] = [-8.5, 8.5]
	var ejes_x: Array[float] = [-0.75, 0.75]
	var rieles_z: Array[float] = [-0.7, 0.7]
	for bx: float in bogies_x:
		_caja(p, Vector3(2.6, 0.25, 2.0), Vector3(bx, -0.55, 0), _m.gris)
		for dx: float in ejes_x:
			for zl: float in rieles_z:
				var r: MeshInstance3D = _cilindro(p, 0.3, 0.1, Vector3(bx + dx, -0.42, zl), _m.gris)
				r.rotation.x = PI / 2.0


func _carteles(p: Node3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2026
	var fondos: Array[Color] = [Color(0.16, 0.18, 0.34), Color(0.26, 0.28, 0.42), Color(0.55, 0.12, 0.12), Color(0.85, 0.45, 0.18), Color(0.2, 0.24, 0.5)]
	var tinta: Array[Color] = [CREMA, NOCHE, AZUL_LED, NARANJA]
	var tipo: int = 0
	var signos: Array[int] = [-1, 1]
	for s: int in signos:
		if s == 1:
			p = lado_camara
		var z: float = s * (ANCHO / 2.0 - 0.06)
		var dentro_z: int = -s
		for t: Vector2 in _tramos():
			var lx: float = t.y - t.x
			var n: int = int(lx / 1.6)
			for i: int in n:
				var cx: float = t.x + (i + 0.5) * lx / n
				var fondo: Color = fondos[rng.randi() % fondos.size()]
				var c: Color = tinta[rng.randi() % tinta.size()]
				var base: Vector3 = Vector3(cx, 2.36, z)
				_caja(p, Vector3(0.66, 0.44, 0.012), base, _mat(fondo, fondo, 0.25))
				var zf: float = base.z + dentro_z * 0.012
				match tipo % 4:
					0:
						var sol: MeshInstance3D = _cilindro(p, 0.1, 0.01, Vector3(cx - 0.15, 2.4, zf), _mat(c, c, 0.4))
						sol.rotation.x = PI / 2.0
						for k: int in 3:
							_caja(p, Vector3(0.3, 0.03, 0.01), Vector3(cx + 0.12, 2.3 + k * 0.07, zf), _mat(c, c, 0.4))
					1:
						var gm: StandardMaterial3D = _mat(NOCHE)
						var cuerpo_g: MeshInstance3D = _esfera(p, 0.1, Vector3(cx + 0.04, 2.28, zf), gm)
						cuerpo_g.scale = Vector3(1.6, 0.7, 0.15)
						_esfera(p, 0.06, Vector3(cx - 0.14, 2.31, zf), gm).scale = Vector3(1, 1, 0.2)
						var orejas_x: Array[float] = [-0.17, -0.11]
						for ox: float in orejas_x:
							var oreja: MeshInstance3D = MeshInstance3D.new()
							var pm: PrismMesh = PrismMesh.new()
							pm.size = Vector3(0.04, 0.05, 0.01)
							oreja.mesh = pm
							oreja.material_override = gm
							oreja.position = Vector3(cx + ox, 2.37, zf)
							p.add_child(oreja)
						_caja(p, Vector3(0.4, 0.04, 0.01), Vector3(cx, 2.5, zf), _mat(c, c, 0.4))
					2:
						var cuad_colores: Array[Color] = [AZUL_LED, NARANJA, VIOLETA, ROJO]
						for k: int in 4:
							var col: Color = cuad_colores[k]
							_caja(p, Vector3(0.12, 0.12, 0.01), Vector3(cx - 0.21 + k * 0.14, 2.36, zf), _mat(col, col, 0.4))
					3:
						_caja(p, Vector3(0.08, 0.28, 0.01), Vector3(cx - 0.15, 2.36, zf), _mat(c, c, 0.4))
						_caja(p, Vector3(0.3, 0.05, 0.01), Vector3(cx + 0.1, 2.44, zf), _mat(c, c, 0.4))
						_caja(p, Vector3(0.22, 0.05, 0.01), Vector3(cx + 0.06, 2.34, zf), _mat(c, c, 0.4))
				tipo += 1


func _luces(p: Node3D) -> void:
	var colores: Array[Color] = [Color(0.35, 0.4, 1.0), Color(0.5, 0.42, 1.0)]
	var i: int = 0
	var x: float = -LARGO / 2.0 + 2.0
	while x < LARGO / 2.0:
		var l: OmniLight3D = OmniLight3D.new()
		l.light_color = colores[i % 2]
		l.light_energy = 1.6
		l.omni_range = 4.5
		l.omni_attenuation = 1.3
		l.position = Vector3(x, 2.25, 0)
		p.add_child(l)
		var cono: MeshInstance3D = MeshInstance3D.new()
		var cm: CylinderMesh = CylinderMesh.new()
		cm.top_radius = 0.25
		cm.bottom_radius = 0.95
		cm.height = 2.4
		cm.cap_top = false
		cm.cap_bottom = false
		cono.mesh = cm
		cono.material_override = _m.cono
		cono.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cono.position = Vector3(x, 1.25, -0.8 if i % 2 == 0 else 0.8)
		p.add_child(cono)
		x += 4.0
		i += 1
	var calida: OmniLight3D = OmniLight3D.new()
	calida.light_color = NARANJA
	calida.light_energy = 0.9
	calida.omni_range = 3.0
	calida.position = Vector3(LARGO / 2.0 - 0.6, 1.6, -0.6)
	p.add_child(calida)
	var signos: Array[int] = [-1, 1]
	for s: int in signos:
		_caja(p, Vector3(0.03, 0.14, 0.5), Vector3(s * (LARGO / 2.0 - 0.07), 2.35, 0), _m.salida)


func _compuertas() -> void:
	var raiz: Node3D = _nodo(self, "Compuertas")
	var choque: StaticBody3D = StaticBody3D.new()
	choque.name = "Choque"
	raiz.add_child(choque)
	var lados: Array[int] = [-1, 1]
	for px: float in puertas_x:
		var cx: float = x_parada + px
		for lado: int in lados:
			var h: Node3D = _nodo(raiz, "Compuerta")
			h.position = Vector3(cx + lado * 0.45, 0, Z_COMPUERTA)
			_caja(h, Vector3(0.86, 0.8, 0.04), Vector3(0, 0.45, 0), _m.vidrio_anden)
			_caja(h, Vector3(0.86, 0.05, 0.06), Vector3(0, 0.87, 0), _m.laton)
			compuertas.append(PuertaMovil.new(h, cx + lado * 0.45, cx + lado * 1.35))
			var luz: MeshInstance3D = _esfera(raiz, 0.045, Vector3(cx + lado * 0.95, 0.9, Z_COMPUERTA), _m.rojo)
			indicadores.append(luz)
		var f: CollisionShape3D = CollisionShape3D.new()
		var b: BoxShape3D = BoxShape3D.new()
		b.size = Vector3(1.8, 2.0, 0.3)
		f.shape = b
		f.position = Vector3(cx, 1.0, Z_COMPUERTA)
		choque.add_child(f)
		formas_compuerta.append(f)


func _nodo(padre: Node3D, nombre: String) -> Node3D:
	var n: Node3D = Node3D.new()
	n.name = nombre
	padre.add_child(n)
	return n


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
	c.radial_segments = 12
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
	cuerpo.add_child(c)
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


func _crear_marcador() -> void:
	marcador = Node3D.new()
	marcador.name = "Marcador"
	marcador.top_level = true
	add_child(marcador)
	_mat_marcador = StandardMaterial3D.new()
	_mat_marcador.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_marcador.no_depth_test = true
	_mat_marcador.render_priority = 2
	_mat_marcador.albedo_color = COLOR_MARCADOR
	var aro: MeshInstance3D = MeshInstance3D.new()
	var tm: TorusMesh = TorusMesh.new()
	tm.inner_radius = 0.26
	tm.outer_radius = 0.34
	aro.mesh = tm
	aro.material_override = _mat_marcador
	marcador.add_child(aro)
	var flecha: MeshInstance3D = MeshInstance3D.new()
	var pm: PrismMesh = PrismMesh.new()
	pm.size = Vector3(0.32, 0.3, 0.06)
	flecha.mesh = pm
	flecha.material_override = _mat_marcador
	flecha.position = Vector3(0, 0.55, 0)
	flecha.rotation.z = PI
	marcador.add_child(flecha)
	marcador.visible = false


func _actualizar_marcador() -> void:
	if jugador == null or camara_estacion == null or marcador == null:
		return
	var tapa: bool = false
	if not dentro and absf(jugador.global_position.x - tren.global_position.x) < LARGO / 2.0 + 0.5:
		var z: float = jugador.global_position.z
		tapa = z > global_position.z - 5.2 and z < global_position.z - ANCHO / 2.0
	marcador.visible = tapa
	if not tapa:
		return
	var hacia_camara: Vector3 = camara_estacion.global_transform.basis.z
	var p: Vector3 = jugador.global_position + Vector3(0, 0.9, 0)
	var t: float = (ALTO_MARCADOR - p.y) / maxf(hacia_camara.y, 0.05)
	marcador.global_position = p + hacia_camara * t + Vector3(0, 0.1 * sin(reloj * 4.0), 0)
	var en_puerta: bool = false
	if apertura > 0.9:
		for px: float in puertas_x:
			if absf(jugador.global_position.x - (tren.global_position.x + px)) < ANCHO_PUERTA / 2.0 + 0.2:
				en_puerta = true
	_mat_marcador.albedo_color = COLOR_ENTRAR if en_puerta else COLOR_MARCADOR


func _shader(nombre: String) -> ShaderMaterial:
	var m: ShaderMaterial = ShaderMaterial.new()
	m.shader = load("res://metro/%s.gdshader" % nombre) as Shader
	return m


func _filtro() -> void:
	filtro = CanvasLayer.new()
	filtro.name = "FiltroVagon"
	filtro.layer = 5
	var r: ColorRect = ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.material = _shader("pantalla_vagon")
	filtro.add_child(r)
	add_child(filtro)
	filtro.visible = false


func _vidrio(color: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = _mat(color, Color.BLACK, 0.0, 0.4, 0.08)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
