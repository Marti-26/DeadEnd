extends Node

var polvo_en_luces: bool = true
var zumbido_tubos: bool = true
var temperatura_zonas: bool = true
var criaturas_cambian_luz: bool = true
var aura_estres: bool = true
var aberracion_estres: bool = true
var grano_pelicula: bool = true

var radio_criatura_luz: float = 6.0
var intensidad_grano: float = 0.035
var aberracion_max: float = 1.0

const ZUMBIDO: Script = preload("res://ambiente/zumbido.gd")

const CODIGO_PANTALLA: String = """
shader_type canvas_item;
uniform sampler2D pantalla : hint_screen_texture, filter_linear;
uniform float aberracion = 0.0;
uniform float grano = 0.0;
void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 dir = uv - 0.5;
	float borde = dot(dir, dir) * 4.0;
	vec2 corrimiento = dir * aberracion * borde * 0.018;
	vec3 color;
	color.r = texture(pantalla, uv + corrimiento).r;
	color.g = texture(pantalla, uv).g;
	color.b = texture(pantalla, uv - corrimiento).b;
	vec2 celda = floor(FRAGCOORD.xy / 2.0);
	float n = fract(sin(dot(celda + fract(TIME * 7.13) * vec2(91.3, 47.7), vec2(12.9898, 78.233))) * 43758.5453);
	color += (n - 0.5) * grano;
	COLOR = vec4(color, 1.0);
}
"""

var _escena: Node = null
var _luces: Array[Light3D] = []
var _color_base: Dictionary = {}
var _energia_base: Dictionary = {}
var _con_script: Dictionary = {}
var _modificadas: Dictionary = {}
var _aura: OmniLight3D = null
var _aura_energia: float = 1.0
var _aura_alcance: float = 3.0
var _capa: CanvasLayer = null
var _material_pantalla: ShaderMaterial = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	process_priority = 1000
	_rng.randomize()
	_crear_capa_pantalla()


func _process(delta: float) -> void:
	var actual: Node = get_tree().current_scene
	if actual != _escena:
		_escena = actual
		_limpiar_estado()
		if _escena != null:
			_preparar.call_deferred(_escena)
	_actualizar_luces_criaturas()
	_actualizar_aura(delta)
	_actualizar_pantalla()


func _limpiar_estado() -> void:
	_luces.clear()
	_color_base.clear()
	_energia_base.clear()
	_con_script.clear()
	_modificadas.clear()
	_aura = null


func _preparar(escena: Node) -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if escena != _escena or not is_instance_valid(escena):
		return
	_recolectar_luces(escena)
	var ruta: String = escena.scene_file_path
	var primer_piso: bool = ruta.ends_with("zona_b.tscn")
	var segundo_piso: bool = ruta.ends_with("segundo_piso.tscn")
	if temperatura_zonas:
		_ajustar_temperatura(escena, primer_piso, segundo_piso)
	if polvo_en_luces:
		_poner_polvo()
	if zumbido_tubos:
		_poner_zumbidos()


func _es_de_personaje(n: Node) -> bool:
	if n.name.begins_with("LuzAura"):
		return true
	var p: Node = n.get_parent()
	while p != null:
		if p.is_in_group(Grupos.JUGADOR) or p is CriaturaBase or p is CharacterBody3D:
			return true
		p = p.get_parent()
	return false


func _dentro_de(n: Node, nombre: String) -> bool:
	var p: Node = n.get_parent()
	while p != null:
		if p.name == nombre:
			return true
		p = p.get_parent()
	return false


func _recolectar_luces(raiz: Node) -> void:
	for n: Node in raiz.find_children("*", "Light3D", true, false):
		var luz: Light3D = n as Light3D
		if luz is DirectionalLight3D or _es_de_personaje(luz):
			continue
		_luces.append(luz)
		_color_base[luz] = luz.light_color
		_energia_base[luz] = luz.light_energy
		_con_script[luz] = luz.get_script() != null


func _ajustar_temperatura(escena: Node, primer_piso: bool, segundo_piso: bool) -> void:
	var entornos: Array[Node] = escena.find_children("*", "WorldEnvironment", true, false)
	if entornos.is_empty():
		return
	var mundo: WorldEnvironment = entornos[0] as WorldEnvironment
	if mundo.environment == null:
		return
	var entorno: Environment = mundo.environment.duplicate() as Environment
	if primer_piso:
		entorno.ambient_light_color = entorno.ambient_light_color.lerp(Color(0.02, 0.09, 0.07), 0.45)
		entorno.fog_light_color = entorno.fog_light_color.lerp(Color(0.03, 0.13, 0.1), 0.4)
	elif segundo_piso:
		entorno.ambient_light_color = entorno.ambient_light_color.lerp(Color(0.13, 0.08, 0.2), 0.4)
		entorno.fog_light_color = entorno.fog_light_color.lerp(Color(0.12, 0.07, 0.18), 0.4)
	else:
		return
	mundo.environment = entorno


func _poner_polvo() -> void:
	var puestos: int = 0
	for luz: Light3D in _luces:
		if puestos >= 14:
			break
		if luz.global_position.y < 2.2 or _dentro_de(luz, "Metro"):
			continue
		var polvo: CPUParticles3D = CPUParticles3D.new()
		polvo.name = "Polvo"
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		mat.vertex_color_use_as_albedo = true
		var punto: QuadMesh = QuadMesh.new()
		punto.size = Vector2(0.018, 0.018)
		punto.material = mat
		polvo.mesh = punto
		polvo.amount = 26
		polvo.lifetime = 7.0
		polvo.preprocess = 7.0
		polvo.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		polvo.emission_box_extents = Vector3(1.1, 1.0, 0.8)
		polvo.direction = Vector3(0.2, -0.1, 0.0)
		polvo.spread = 180.0
		polvo.gravity = Vector3(0.0, -0.006, 0.0)
		polvo.initial_velocity_min = 0.01
		polvo.initial_velocity_max = 0.05
		polvo.scale_amount_min = 0.6
		polvo.scale_amount_max = 1.4
		var c: Color = luz.light_color
		var rampa: Gradient = Gradient.new()
		rampa.set_color(0, Color(c.r, c.g, c.b, 0.0))
		rampa.set_color(1, Color(c.r, c.g, c.b, 0.0))
		rampa.add_point(0.3, Color(c.r, c.g, c.b, 0.55))
		rampa.add_point(0.75, Color(c.r, c.g, c.b, 0.35))
		polvo.color_ramp = rampa
		polvo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		luz.get_parent().add_child(polvo)
		polvo.global_position = luz.global_position + Vector3(0.0, -1.2, 0.0)
		puestos += 1


func _poner_zumbidos() -> void:
	for luz: Light3D in _luces:
		if luz is LuzParpadeante:
			var zumbido: AudioStreamPlayer3D = ZUMBIDO.new() as AudioStreamPlayer3D
			zumbido.name = "Zumbido"
			luz.add_child(zumbido)


func _criaturas() -> Array[Node3D]:
	var lista: Array[Node3D] = []
	for n: Node in get_tree().get_nodes_in_group(Grupos.DISPARADORES):
		if n is CriaturaBase:
			lista.append(n as Node3D)
	return lista


func _actualizar_luces_criaturas() -> void:
	if _luces.is_empty():
		return
	var criaturas: Array[Node3D] = []
	if criaturas_cambian_luz:
		criaturas = _criaturas()
	for luz: Light3D in _luces:
		if not is_instance_valid(luz):
			continue
		var cercania: float = 0.0
		for c: Node3D in criaturas:
			var d: float = luz.global_position.distance_to(c.global_position)
			cercania = maxf(cercania, 1.0 - d / radio_criatura_luz)
		var base_color: Color = _color_base[luz]
		var base_energia: float = _energia_base[luz]
		if cercania <= 0.0:
			if _modificadas.has(luz):
				_modificadas.erase(luz)
				luz.light_color = base_color
				if not _con_script[luz]:
					luz.light_energy = base_energia
			continue
		_modificadas[luz] = true
		luz.light_color = base_color.lerp(Color(1.0, 0.12, 0.1), cercania * 0.65)
		var temblor: float = 1.0 - cercania * 0.6 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.031 + float(luz.get_instance_id() % 97)))
		if _rng.randf() < cercania * 0.08:
			temblor *= 0.15
		if _con_script[luz]:
			luz.light_energy *= temblor
		else:
			luz.light_energy = base_energia * temblor


func _actualizar_aura(delta: float) -> void:
	if not aura_estres:
		return
	if _aura == null or not is_instance_valid(_aura):
		var jugador: Node = get_tree().get_first_node_in_group(Grupos.JUGADOR)
		if jugador == null:
			return
		var hallados: Array[Node] = jugador.find_children("LuzAura_Bombillo", "OmniLight3D", true, false)
		if hallados.is_empty():
			return
		_aura = hallados[0] as OmniLight3D
		_aura_energia = _aura.light_energy
		_aura_alcance = _aura.omni_range
	var k: float = clampf((Partida.estres - 50.0) / 50.0, 0.0, 1.0)
	var temblor: float = 1.0 + (_rng.randf() - 0.5) * 0.5 * k
	_aura.light_energy = _aura_energia * (1.0 - 0.45 * k) * temblor
	_aura.omni_range = _aura_alcance * (1.0 - 0.35 * k)


func _crear_capa_pantalla() -> void:
	_capa = CanvasLayer.new()
	_capa.name = "EfectoPantalla"
	_capa.layer = 0
	add_child(_capa)
	var rect: ColorRect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sombreado: Shader = Shader.new()
	sombreado.code = CODIGO_PANTALLA
	_material_pantalla = ShaderMaterial.new()
	_material_pantalla.shader = sombreado
	rect.material = _material_pantalla
	_capa.add_child(rect)


func _actualizar_pantalla() -> void:
	if _material_pantalla == null:
		return
	var aberracion: float = 0.0
	if aberracion_estres and get_tree().get_first_node_in_group(Grupos.JUGADOR) != null:
		aberracion = smoothstep(70.0, 100.0, Partida.estres) * aberracion_max
	var grano: float = intensidad_grano if grano_pelicula else 0.0
	_capa.visible = aberracion > 0.001 or grano > 0.0
	_material_pantalla.set_shader_parameter("aberracion", aberracion)
	_material_pantalla.set_shader_parameter("grano", grano)
