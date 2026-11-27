@tool
extends Node3D

signal jugador_entro(cuerpo: Node3D)
signal jugador_salio(cuerpo: Node3D)

@export var grupo: String = Grupos.FUERA_DE_ALCANCE
@export var bloquear_frente_hueco: bool = true
@export var poster_x: float = -8.15
@export var poster2_x: float = 3.97
@export var poster3_x: float = 13.95
@export var poster3_alto: float = 1.7
@export var poster_alto: float = 1.85
@export var poster_centro_y: float = 1.55
@export var poster_brillo: float = 0.18
@export var poster_luz: float = 0.9
@export_group("Visitantes")
@export var mostrar_gato: bool = true
@export var gato_pos: Vector3 = Vector3(-13.55, 0.0, -2.55)
@export var alto_gato: float = 1.85
@export var mostrar_caniche: bool = true
@export var caniche_pos: Vector3 = Vector3(-5.07, 0.5, -0.38)
@export var alto_caniche: float = 1.45
@export var luz_caniche: float = 0.9
@export var color_luz_caniche: Color = Color(1.0, 0.9, 0.95)
@export var luz_gato: float = 0.55
@export var color_luz_gato: Color = Color(0.55, 0.65, 1.0)
@export var frases_gato: Array[String] = [
	"Se tragó mi plata.",
	"Ni el paquete ni las vueltas. Nada.",
	"No le metas monedas. En serio.",
]
@export var frases_caniche: Array[String] = [
	"Aquí no se oye nada. Mejor así.",
	"Estoy esperando a alguien.",
	"Ya debería haber llegado.",
]
@export_group("")

const ANCHO: float = 30.0
const Z_FONDO: float = -4.0
const Z_FRENTE: float = 5.0
const ALTO: float = 4.6
const HUECO_X: Vector2 = Vector2(10.5, 13.5)
const HUECO_Z: Vector2 = Vector2(1.5, 4.6)

const CIAN: Color = Color(0.62, 0.88, 0.92)
const ROJO: Color = Color(0.72, 0.12, 0.16)
const AMARILLO: Color = Color(1.0, 0.84, 0.5)
const CREMA: Color = Color(0.97, 0.93, 0.92)
const NOCHE: Color = Color(0.09, 0.06, 0.12)
const LADRILLO: Shader = preload("res://zona_b/ladrillo.gdshader")
const FUENTE: FontFile = preload("res://assets/font/ShareTechMono-Regular.ttf")
const CONO_LUZ: Shader = preload("res://zona_b/cono_luz.gdshader")
const POSTER_PARED: Script = preload("res://poster_pared.gd")
const DESTELLOS: Script = preload("res://destellos.gd")
const PISO_AZUL: Color = Color(0.22, 0.25, 0.36)
const PISO_JUNTA: Color = Color(0.06, 0.07, 0.12)
const PARED_AZUL: Color = Color(0.13, 0.14, 0.25)
const PARED_JUNTA: Color = Color(0.05, 0.05, 0.11)
const TUBO_CIAN: Color = Color(0.7, 0.93, 1.0)
const TUBO_VIOLETA: Color = Color(0.62, 0.4, 1.0)
const MAQUINA_BLANCO: Color = Color(0.9, 0.95, 1.0)
const MAQUINA_CIAN: Color = Color(0.6, 0.9, 1.0)
const MAQUINA_MAGENTA: Color = Color(1.0, 0.45, 0.8)
const CUERPO_MAQUINA: Color = Color(0.3, 0.42, 0.42)
const EXPENDEDORAS: Array[PackedScene] = [
	preload("res://assets/expendedoras/expendedora_soda.tscn"),
	preload("res://assets/expendedoras/expendedora_expreso.tscn"),
	preload("res://assets/expendedoras/expendedora_pociones.tscn"),
]
const ASIENTO: Color = Color(0.22, 0.26, 0.42)

var choques: StaticBody3D
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _indice_maquina: int = 0
var _capa_poster: CanvasLayer = null


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
	var luces_izq: Array[Color] = [MAQUINA_BLANCO, MAQUINA_MAGENTA, MAQUINA_CIAN]
	var luces_der: Array[Color] = [MAQUINA_MAGENTA, MAQUINA_BLANCO]
	_indice_maquina = 0
	_maquinas(sala, -12.6, luces_izq)
	_maquinas(sala, 5.6, luces_der)
	_sillas(sala, Vector3(-6.0, 0, -0.4), 4)
	_sillas(sala, Vector3(1.5, 0, 1.4), 4)
	if mostrar_gato:
		_visitante(sala, "Gato", ["res://assets/npcs y posters/gato_2_idle_frente_1 (1).png", "res://assets/npcs y posters/gato_2_idle_frente_1 (2).png"], gato_pos, alto_gato, 25.0, 644.0, color_luz_gato, luz_gato, "GATO", frases_gato)
	if mostrar_caniche:
		_visitante(sala, "Caniche", ["res://assets/npcs y posters/caniche_idle_frente_1.png", "res://assets/npcs y posters/caniche_idle_frente_2.png"], caniche_pos, alto_caniche, 24.0, 688.0, color_luz_caniche, luz_caniche, "CANICHE", frases_caniche)
	_pilar(sala, Vector3(-2.2, 0, -1.6), ROJO)
	_pilar(sala, Vector3(9.0, 0, -1.6), CIAN)
	_viga_luz(sala)
	_detalles(sala)
	_poster(sala, "res://assets/npcs y posters/RATINI1.jpg.jpeg", poster_x, "Poster")
	_poster(sala, "res://assets/npcs y posters/felidae1.png", poster2_x, "Poster2")
	var kitsuny: Node3D = POSTER_PARED.new() as Node3D
	kitsuny.name = "Poster3"
	kitsuny.position = Vector3(poster3_x, poster_centro_y, Z_FONDO + 0.04)
	kitsuny.set("alto", poster3_alto)
	kitsuny.set("brillo", poster_brillo)
	kitsuny.set("luz", poster_luz)
	kitsuny.set("color_luz", Color(1.0, 0.86, 0.95))
	kitsuny.set("tinte", Color.WHITE)
	kitsuny.set("saturacion", 1.0)
	kitsuny.set("textura", load("res://assets/npcs y posters/poster_kitsuny.png"))
	sala.add_child(kitsuny)
	if not Engine.is_editor_hint():
		var area: Area3D = get_node_or_null("AreaZonaSegura") as Area3D
		if area == null:
			area = Area3D.new()
			area.name = "AreaZonaSegura"
			area.collision_layer = 0
			area.collision_mask = 1
			var forma: CollisionShape3D = CollisionShape3D.new()
			var caja: BoxShape3D = BoxShape3D.new()
			caja.size = Vector3(ANCHO, 5.0, Z_FRENTE - Z_FONDO + 0.6)
			forma.shape = caja
			forma.position = Vector3(0, 2.3, (Z_FONDO + Z_FRENTE) / 2.0 + 0.3)
			area.add_child(forma)
			add_child(area)
		if area != null:
			if not area.body_entered.is_connected(_on_area_zona_segura_body_entered):
				area.body_entered.connect(_on_area_zona_segura_body_entered)
			if not area.body_exited.is_connected(_on_area_zona_segura_body_exited):
				area.body_exited.connect(_on_area_zona_segura_body_exited)


func _piso(p: Node3D) -> void:
	var m: ShaderMaterial = _ladrillo(PISO_AZUL, PISO_JUNTA, Vector2(0.9, 0.6), true, 0.2)
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
	var m: ShaderMaterial = _ladrillo(PARED_AZUL, PARED_JUNTA, Vector2(0.5, 0.25), false, 0.08)
	_bloque(p, Vector3(ANCHO + 0.8, ALTO, 0.4), Vector3(0, ALTO / 2.0, Z_FONDO - 0.2), m)
	var signos: Array[int] = [-1, 1]
	for s: int in signos:
		_bloque(p, Vector3(0.4, ALTO, Z_FRENTE - Z_FONDO + 0.4), Vector3(s * (ANCHO / 2.0 + 0.2), ALTO / 2.0, (Z_FONDO + Z_FRENTE) / 2.0), m)
	var zocalo: StandardMaterial3D = _mat(PARED_JUNTA)
	_caja(p, Vector3(ANCHO, 0.3, 0.05), Vector3(0, 0.15, Z_FONDO + 0.02), zocalo)
	var cornisa: StandardMaterial3D = _mat(NOCHE, TUBO_VIOLETA, 0.6)
	_caja(p, Vector3(ANCHO, 0.06, 0.08), Vector3(0, 3.3, Z_FONDO + 0.04), cornisa)


func _bajada(p: Node3D) -> void:
	var cx: float = (HUECO_X.x + HUECO_X.y) / 2.0
	var w: float = HUECO_X.y - HUECO_X.x
	var paso: float = (HUECO_Z.y - HUECO_Z.x) / 8.0
	var gris: StandardMaterial3D = _mat(PISO_JUNTA)
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
		_caja(p, Vector3(0.1, 2.3, HUECO_Z.y - HUECO_Z.x), Vector3(x, -1.15, (HUECO_Z.x + HUECO_Z.y) / 2.0), _mat(PARED_JUNTA))
	var flecha: MeshInstance3D = MeshInstance3D.new()
	var pm: PrismMesh = PrismMesh.new()
	pm.size = Vector3(0.6, 0.5, 0.08)
	flecha.mesh = pm
	flecha.material_override = _mat(TUBO_CIAN, TUBO_CIAN, 2.0)
	flecha.position = Vector3(cx, 1.9, HUECO_Z.x - 0.1)
	flecha.rotation.z = PI
	p.add_child(flecha)
	var letrero: Label3D = Label3D.new()
	letrero.text = "ANDÉN"
	letrero.font_size = 64
	letrero.pixel_size = 0.006
	letrero.font = FUENTE
	letrero.modulate = Color(1.2, 1.8, 2.0)
	letrero.outline_size = 10
	letrero.outline_modulate = Color(0.0, 0.12, 0.18)
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
	if bloquear_frente_hueco:
		_forma(Vector3(HUECO_X.y - HUECO_X.x, 2.0, 0.2), Vector3((HUECO_X.x + HUECO_X.y) / 2.0, 1.0, Z_FRENTE + 0.1))
	var lados_hueco: Array[float] = [HUECO_X.x - 0.05, HUECO_X.y + 0.05]
	for x: float in lados_hueco:
		var zc: float = (HUECO_Z.x + HUECO_Z.y) / 2.0
		var lz: float = HUECO_Z.y - HUECO_Z.x
		_caja(p, Vector3(0.04, 0.9, lz), Vector3(x, 0.5, zc), vidrio)
		_caja(p, Vector3(0.08, 0.06, lz), Vector3(x, 0.98, zc), metal)
		_forma(Vector3(0.2, 2.0, lz), Vector3(x, 1.0, zc))


func _maquinas(p: Node3D, x0: float, luces: Array[Color]) -> void:
	var x: float = x0
	for luz: Color in luces:
		_maquina(p, Vector3(x, 0, Z_FONDO + 0.45), luz)
		x += 1.35


func _maquina(p: Node3D, pos: Vector3, luz: Color) -> void:
	# Modelos nuevos (assets/expendedoras): se alternan soda, expreso y pociones.
	var escena: PackedScene = EXPENDEDORAS[_indice_maquina % EXPENDEDORAS.size()]
	_indice_maquina += 1
	var maquina: Node3D = escena.instantiate() as Node3D
	maquina.name = "Expendedora%d" % _indice_maquina
	maquina.position = pos
	p.add_child(maquina)
	_forma(Vector3(1.1, 2.0, 0.7), pos + Vector3(0, 1.0, 0))
	# La luz propia del modelo se mezcla un poco con el color de la sala para que combine.
	var l: OmniLight3D = maquina.get_node_or_null("Luz") as OmniLight3D
	if l != null:
		l.light_color = l.light_color.lerp(luz, 0.3)


func _sillas(p: Node3D, pos: Vector3, n: int) -> void:
	var asiento: StandardMaterial3D = _mat(ASIENTO, Color.BLACK, 0.0, 0.2, 0.35)
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


func _visitante(p: Node3D, nombre: String, rutas: Array[String], pies: Vector3, alto: float, arriba: float, abajo: float, color_luz: Color, energia_luz: float, nombre_dialogo: String, frases: Array[String]) -> void:
	var marcos: SpriteFrames = SpriteFrames.new()
	marcos.set_animation_speed("default", 1.6)
	marcos.set_animation_loop("default", true)
	var alto_imagen: float = 0.0
	for ruta: String in rutas:
		var textura: Texture2D = load(ruta) as Texture2D
		if textura == null:
			return
		alto_imagen = float(textura.get_height())
		marcos.add_frame("default", textura)
	var tamano_pixel: float = alto / (abajo - arriba)
	var sprite: AnimatedSprite3D = AnimatedSprite3D.new()
	sprite.name = nombre
	sprite.sprite_frames = marcos
	sprite.pixel_size = tamano_pixel
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.shaded = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.position = pies + Vector3(0, (abajo - alto_imagen * 0.5) * tamano_pixel, 0)
	if not Engine.is_editor_hint():
		var guion: Script = load("res://npc_pasajero.gd") as Script
		if guion != null:
			sprite.set_script(guion)
			sprite.set("nombre_dialogo", nombre_dialogo)
			sprite.set("frases", frases)
			sprite.set("solo_dentro_vagon", false)
	p.add_child(sprite)
	sprite.play("default")
	sprite.frame = _rng.randi() % 2
	var luz: OmniLight3D = OmniLight3D.new()
	luz.name = "LuzAura_" + nombre
	luz.light_color = color_luz
	luz.light_energy = energia_luz
	luz.light_specular = 0.0
	luz.omni_range = alto * 1.1
	luz.omni_attenuation = 1.6
	luz.shadow_enabled = false
	luz.position = pies + Vector3(0, alto * 0.6, 0.7)
	p.add_child(luz)
	if pies.y < 0.1:
		var sombra: Node3D = Node3D.new()
		sombra.name = "Sombra_" + nombre
		sombra.set_script(load("res://sombra_pies.gd"))
		sombra.set("tamano", Vector2(alto * 0.46, alto * 0.24))
		sombra.position = pies
		p.add_child(sombra)


func _pilar(p: Node3D, pos: Vector3, acento: Color) -> void:
	var m: StandardMaterial3D = _mat(Color(0.2, 0.22, 0.34), Color.BLACK, 0.0, 0.1, 0.5)
	_bloque(p, Vector3(0.8, ALTO, 0.8), pos + Vector3(0, ALTO / 2.0, 0), m)
	_caja(p, Vector3(0.36, 1.8, 0.03), pos + Vector3(0, 2.0, 0.41), _mat(CREMA, Color(1.0, 0.92, 0.95), 1.6))
	_caja(p, Vector3(0.36, 0.12, 0.035), pos + Vector3(0, 1.2, 0.415), _mat(acento, acento, 2.0))
	for k: int in 5:
		_caja(p, Vector3(0.22, 0.03, 0.035), pos + Vector3(0, 2.6 - k * 0.22, 0.415), _mat(NOCHE))




func _viga_luz(p: Node3D) -> void:
	_caja(p, Vector3(ANCHO - 1.0, 0.14, 0.35), Vector3(0, 3.7, Z_FONDO + 1.4), _mat(NOCHE))
	_caja(p, Vector3(ANCHO - 1.2, 0.04, 0.25), Vector3(0, 3.62, Z_FONDO + 1.4), _mat(TUBO_VIOLETA, TUBO_VIOLETA, 1.2))
	var xs: Array[float] = [-12.0, -6.0, 0.0, 6.0, 12.0]
	for i: int in xs.size():
		_tubo(p, xs[i], TUBO_CIAN if i % 2 == 0 else TUBO_VIOLETA)
	var centros_luz: Array[float] = [-6.0, 1.5]
	for xc: float in centros_luz:
		var c: OmniLight3D = OmniLight3D.new()
		c.light_color = TUBO_VIOLETA
		c.light_energy = 0.5
		c.light_specular = 0.0
		c.omni_range = 4.5
		c.omni_attenuation = 2.0
		c.position = Vector3(xc, 2.6, 1.0)
		p.add_child(c)


func _tubo(p: Node3D, x: float, color: Color) -> void:
	var carcasa: MeshInstance3D = _caja(p, Vector3(1.9, 0.14, 0.22), Vector3(x, 3.0, Z_FONDO + 0.2), _mat(Color(0.07, 0.08, 0.1), Color.BLACK, 0.0, 0.0, 0.6))
	carcasa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tubo: MeshInstance3D = _caja(p, Vector3(1.75, 0.07, 0.09), Vector3(x, 2.92, Z_FONDO + 0.32), _mat(color, color, 5.0, 0.0, 0.5))
	tubo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cono: MeshInstance3D = MeshInstance3D.new()
	var malla: CylinderMesh = CylinderMesh.new()
	malla.top_radius = 0.45
	malla.bottom_radius = 1.5
	malla.height = 2.9
	malla.radial_segments = 24
	malla.cap_top = false
	malla.cap_bottom = false
	cono.mesh = malla
	var mc: ShaderMaterial = ShaderMaterial.new()
	mc.shader = CONO_LUZ
	mc.set_shader_parameter("color", color)
	mc.set_shader_parameter("intensidad", 0.22)
	mc.set_shader_parameter("altura", 2.9)
	cono.material_override = mc
	cono.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cono.position = Vector3(x, 1.45, Z_FONDO + 0.55)
	p.add_child(cono)
	var l: OmniLight3D = OmniLight3D.new()
	l.light_color = color
	l.light_energy = 1.6
	l.light_specular = 0.35
	l.omni_range = 5.5
	l.omni_attenuation = 2.0
	l.position = Vector3(x, 2.75, Z_FONDO + 0.85)
	p.add_child(l)


func _poster(p: Node3D, ruta: String, x_poster: float, nombre: String) -> void:
	var textura: Texture2D = load(ruta) as Texture2D
	if textura == null:
		return
	var proporcion: float = float(textura.get_width()) / float(textura.get_height())
	var tam: Vector2 = Vector2(poster_alto * proporcion, poster_alto)
	var centro: Vector3 = Vector3(x_poster, poster_centro_y, Z_FONDO + 0.04)
	_caja(p, Vector3(tam.x + 0.08, tam.y + 0.08, 0.02), centro - Vector3(0, 0, 0.015), _mat(NOCHE))
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_texture = textura
	mat.emission_enabled = true
	mat.emission_texture = textura
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = poster_brillo
	mat.roughness = 0.8
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var lamina: QuadMesh = QuadMesh.new()
	lamina.size = tam
	var poster: MeshInstance3D = MeshInstance3D.new()
	poster.name = nombre
	poster.mesh = lamina
	poster.material_override = mat
	poster.position = centro
	poster.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.add_child(poster)
	var luz: SpotLight3D = SpotLight3D.new()
	luz.name = "Luz" + nombre
	luz.light_color = Color(1.0, 0.86, 0.95)
	luz.light_energy = poster_luz
	luz.light_specular = 0.0
	luz.spot_range = 3.2
	luz.spot_angle = 34.0
	luz.spot_attenuation = 0.8
	luz.spot_angle_attenuation = 1.4
	luz.shadow_enabled = false
	var origen: Vector3 = Vector3(x_poster, poster_centro_y + tam.y * 0.5 + 0.35, Z_FONDO + 1.1)
	luz.transform = Transform3D(Basis(), origen).looking_at(centro, Vector3.UP)
	p.add_child(luz)
	var borde: Node3D = Node3D.new()
	borde.name = "Borde" + nombre
	borde.visible = false
	p.add_child(borde)
	var azul: StandardMaterial3D = _mat(Color(0.3, 0.65, 1.0), Color(0.3, 0.65, 1.0), 2.5)
	var g: float = 0.025
	var ancho_b: float = tam.x + 0.12
	var alto_b: float = tam.y + 0.12
	_caja(borde, Vector3(ancho_b + g, g, 0.01), centro + Vector3(0, alto_b * 0.5, 0.01), azul)
	_caja(borde, Vector3(ancho_b + g, g, 0.01), centro + Vector3(0, -alto_b * 0.5, 0.01), azul)
	_caja(borde, Vector3(g, alto_b + g, 0.01), centro + Vector3(-ancho_b * 0.5, 0, 0.01), azul)
	_caja(borde, Vector3(g, alto_b + g, 0.01), centro + Vector3(ancho_b * 0.5, 0, 0.01), azul)
	for hijo: Node in borde.get_children():
		(hijo as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var brillo: MeshInstance3D = DESTELLOS.new() as MeshInstance3D
	brillo.name = "Brillo" + nombre
	brillo.set("tamano", tam)
	brillo.position = centro + Vector3(0, 0, 0.006)
	p.add_child(brillo)
	if Engine.is_editor_hint():
		return
	var area: Area3D = Area3D.new()
	area.name = "Clic" + nombre
	area.collision_layer = 524288
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = false
	var forma: CollisionShape3D = CollisionShape3D.new()
	var caja: BoxShape3D = BoxShape3D.new()
	caja.size = Vector3(tam.x, tam.y, 0.1)
	forma.shape = caja
	area.add_child(forma)
	area.position = centro
	p.add_child(area)
	get_viewport().physics_object_picking = true
	area.mouse_entered.connect(_al_entrar_poster.bind(borde))
	area.mouse_exited.connect(_al_salir_poster.bind(borde))
	area.input_event.connect(_al_clic_poster.bind(textura, borde))


func _al_entrar_poster(borde: Node3D) -> void:
	if _capa_poster != null:
		return
	borde.visible = true
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _al_salir_poster(borde: Node3D) -> void:
	borde.visible = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _al_clic_poster(_camara: Node, evento: InputEvent, _punto: Vector3, _normal: Vector3, _indice_forma: int, textura: Texture2D, borde: Node3D) -> void:
	if evento is InputEventMouseButton:
		var boton: InputEventMouseButton = evento as InputEventMouseButton
		if boton.pressed and boton.button_index == MOUSE_BUTTON_LEFT:
			_al_salir_poster(borde)
			_abrir_poster(textura)


func _unhandled_input(evento: InputEvent) -> void:
	if _capa_poster != null and evento.is_action_pressed("ui_cancel"):
		_cerrar_poster()
		get_viewport().set_input_as_handled()


func _abrir_poster(textura: Texture2D) -> void:
	if _capa_poster != null or textura == null:
		return
	_capa_poster = CanvasLayer.new()
	_capa_poster.layer = 10
	add_child(_capa_poster)
	var pantalla: Vector2 = get_viewport().get_visible_rect().size
	var oscuro: ColorRect = ColorRect.new()
	oscuro.color = Color(0.0, 0.0, 0.02, 0.75)
	oscuro.size = pantalla
	oscuro.mouse_filter = Control.MOUSE_FILTER_STOP
	oscuro.gui_input.connect(_al_tocar_afuera_poster)
	_capa_poster.add_child(oscuro)
	var proporcion: float = float(textura.get_width()) / float(textura.get_height())
	var alto: float = pantalla.y * 0.9
	var ancho: float = alto * proporcion
	if ancho > pantalla.x * 0.9:
		ancho = pantalla.x * 0.9
		alto = ancho / proporcion
	var imagen: TextureRect = TextureRect.new()
	imagen.texture = textura
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_SCALE
	imagen.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	imagen.size = Vector2(ancho, alto)
	imagen.position = (pantalla - imagen.size) * 0.5
	imagen.pivot_offset = imagen.size * 0.5
	imagen.mouse_filter = Control.MOUSE_FILTER_STOP
	_capa_poster.add_child(imagen)
	var x: Button = Button.new()
	x.text = "X"
	x.focus_mode = Control.FOCUS_NONE
	x.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	x.add_theme_font_override("font", FUENTE)
	x.add_theme_font_size_override("font_size", 26)
	x.size = Vector2(46.0, 46.0)
	x.position = Vector2(imagen.position.x + ancho + 10.0, imagen.position.y)
	if x.position.x + x.size.x > pantalla.x:
		x.position.x = imagen.position.x + ancho - x.size.x - 8.0
	x.pressed.connect(_cerrar_poster)
	_capa_poster.add_child(x)
	oscuro.modulate.a = 0.0
	imagen.modulate.a = 0.0
	imagen.scale = Vector2(0.85, 0.85)
	var t: Tween = _capa_poster.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(oscuro, "modulate:a", 1.0, 0.2)
	t.tween_property(imagen, "modulate:a", 1.0, 0.2)
	t.tween_property(imagen, "scale", Vector2.ONE, 0.25)


func _al_tocar_afuera_poster(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and (evento as InputEventMouseButton).pressed:
		_cerrar_poster()


func _cerrar_poster() -> void:
	if _capa_poster == null:
		return
	var capa: CanvasLayer = _capa_poster
	_capa_poster = null
	var t: Tween = capa.create_tween().set_parallel(true)
	for hijo: Node in capa.get_children():
		t.tween_property(hijo, "modulate:a", 0.0, 0.15)
	t.chain().tween_callback(capa.queue_free)


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
	m.set_shader_parameter("rugosidad", 0.85)
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


func _on_area_zona_segura_body_entered(cuerpo: Node3D) -> void:
	if cuerpo.is_in_group(Grupos.JUGADOR):
		cuerpo.add_to_group(Grupos.ZONA_SEGURA)
		if grupo != "":
			cuerpo.add_to_group(grupo)
		jugador_entro.emit(cuerpo)


func _on_area_zona_segura_body_exited(cuerpo: Node3D) -> void:
	if cuerpo.is_in_group(Grupos.JUGADOR):
		cuerpo.remove_from_group(Grupos.ZONA_SEGURA)
		if grupo != "" and not _sigue_en_otra_zona(cuerpo):
			cuerpo.remove_from_group(grupo)
		jugador_salio.emit(cuerpo)


func _sigue_en_otra_zona(cuerpo: Node3D) -> bool:
	var area_propia: Area3D = get_node_or_null("AreaZonaSegura") as Area3D
	var escena: Node = get_tree().current_scene
	if escena == null:
		return false
	for nodo: Node in escena.find_children("*", "Area3D", true, false):
		var area: Area3D = nodo as Area3D
		if area != null and area != area_propia and "grupo" in area and str(area.get("grupo")) == grupo and area.overlaps_body(cuerpo):
			return true
	return false
