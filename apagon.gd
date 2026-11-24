extends CanvasLayer

@export var duracion_luces: float = 1.6
@export var espera_aura: float = 0.6
@export var volumen_minimo: float = -32.0

const CODIGO: String = """
shader_type canvas_item;
uniform vec2 centro = vec2(0.0);
uniform float radio = 5000.0;
uniform float oscuridad = 0.0;
void fragment() {
	vec2 px = SCREEN_UV / SCREEN_PIXEL_SIZE;
	float d = distance(px, centro);
	float fuera = smoothstep(radio * 0.55, radio, d);
	COLOR = vec4(0.004, 0.004, 0.012, max(oscuridad * fuera, step(radio, 1.0) * oscuridad));
}
"""

var _velo: ColorRect = null
var _material: ShaderMaterial = null
var _jugador: Node3D = null
var _volumen_original: float = 0.0
var _bus: int = -1
var _siguiendo: bool = false


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	var sombreado: Shader = Shader.new()
	sombreado.code = CODIGO
	_material = ShaderMaterial.new()
	_material.shader = sombreado
	_velo = ColorRect.new()
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_velo.material = _material
	_velo.visible = false
	add_child(_velo)
	_bus = AudioServer.get_bus_index("Juego")
	if _bus < 0:
		_bus = 0


func _process(_delta: float) -> void:
	if not _siguiendo or _jugador == null or not is_instance_valid(_jugador):
		return
	var camara: Camera3D = get_viewport().get_camera_3d()
	if camara == null:
		return
	var punto: Vector3 = _jugador.global_position + Vector3(0.0, 1.0, 0.0)
	if camara.is_position_behind(punto):
		return
	_material.set_shader_parameter("centro", camara.unproject_position(punto))


func apagar() -> void:
	var tamano: Vector2 = get_viewport().get_visible_rect().size
	var radio_total: float = tamano.length()
	_jugador = get_tree().get_first_node_in_group(Grupos.JUGADOR) as Node3D
	_material.set_shader_parameter("centro", tamano * 0.5)
	_material.set_shader_parameter("radio", radio_total)
	_material.set_shader_parameter("oscuridad", 0.0)
	_velo.visible = true
	_siguiendo = true
	_congelar_jugador()
	_volumen_original = AudioServer.get_bus_volume_db(_bus)
	var sonido: Tween = create_tween()
	sonido.tween_method(_poner_volumen, _volumen_original, volumen_minimo, duracion_luces + espera_aura)
	var aura: Light3D = _apagar_luces()
	var velo: Tween = create_tween().set_parallel(true)
	velo.tween_method(_poner_oscuridad, 0.0, 0.88, duracion_luces).set_trans(Tween.TRANS_SINE)
	velo.tween_method(_poner_radio, radio_total, minf(tamano.y * 0.32, 300.0), duracion_luces).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await velo.finished
	await get_tree().create_timer(espera_aura).timeout
	if aura != null and is_instance_valid(aura):
		_parpadear(aura, 0.0)
	var cierre: Tween = create_tween().set_parallel(true)
	cierre.tween_method(_poner_radio, minf(tamano.y * 0.32, 300.0), 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	cierre.tween_method(_poner_oscuridad, 0.88, 1.0, 0.4)
	await cierre.finished
	_siguiendo = false
	await get_tree().create_timer(0.6).timeout


func encender() -> void:
	var anterior: Node = get_tree().current_scene
	var espera: float = 0.0
	while get_tree().current_scene == anterior and espera < 3.0:
		await get_tree().process_frame
		espera += get_process_delta_time()
	await get_tree().process_frame
	await get_tree().process_frame
	_material.set_shader_parameter("radio", 5000.0)
	var luz: Tween = create_tween()
	luz.tween_method(_poner_oscuridad, 1.0, 0.45, 0.06)
	luz.tween_method(_poner_oscuridad, 0.45, 1.0, 0.09)
	luz.tween_interval(0.12)
	luz.tween_method(_poner_oscuridad, 1.0, 0.25, 0.06)
	luz.tween_method(_poner_oscuridad, 0.25, 0.92, 0.1)
	luz.tween_interval(0.08)
	luz.tween_method(_poner_oscuridad, 0.92, 0.0, 1.1).set_trans(Tween.TRANS_SINE)
	var sonido: Tween = create_tween()
	sonido.tween_method(_poner_volumen, volumen_minimo, _volumen_original, 1.4)
	await luz.finished
	_velo.visible = false


func _congelar_jugador() -> void:
	if _jugador == null:
		return
	_jugador.set_physics_process(false)
	_jugador.set_process_unhandled_input(false)
	_jugador.set_process_input(false)
	if _jugador is CharacterBody3D:
		(_jugador as CharacterBody3D).velocity = Vector3.ZERO


func _apagar_luces() -> Light3D:
	var escena: Node = get_tree().current_scene
	if escena == null:
		return null
	var aura: Light3D = null
	var luces: Array[Light3D] = []
	for n: Node in escena.find_children("*", "Light3D", true, false):
		var luz: Light3D = n as Light3D
		if luz is DirectionalLight3D or not luz.is_visible_in_tree():
			continue
		if luz.name == "LuzAura_Bombillo":
			aura = luz
			continue
		if _jugador != null and _jugador.is_ancestor_of(luz):
			luz.visible = false
			continue
		luces.append(luz)
	var origen: Vector3 = _jugador.global_position if _jugador != null else Vector3.ZERO
	luces.sort_custom(func(a: Light3D, b: Light3D) -> bool: return a.global_position.distance_squared_to(origen) > b.global_position.distance_squared_to(origen))
	var total: int = luces.size()
	for i: int in total:
		var retraso: float = duracion_luces * float(i) / float(maxi(total, 1))
		_parpadear(luces[i], retraso)
	return aura


func _parpadear(luz: Light3D, retraso: float) -> void:
	var t: Tween = create_tween()
	t.tween_interval(retraso)
	t.tween_callback(_cambiar.bind(luz, false))
	t.tween_interval(0.05)
	t.tween_callback(_cambiar.bind(luz, true))
	t.tween_interval(0.06)
	t.tween_callback(_cambiar.bind(luz, false))
	if luz is LuzParpadeante:
		t.tween_callback(_apagar_tubo.bind(luz))


func _apagar_tubo(luz: Light3D) -> void:
	if is_instance_valid(luz):
		(luz as LuzParpadeante).energia_base = 0.0


func _cambiar(luz: Light3D, prendida: bool) -> void:
	if is_instance_valid(luz):
		luz.visible = prendida


func _poner_oscuridad(valor: float) -> void:
	_material.set_shader_parameter("oscuridad", valor)


func _poner_radio(valor: float) -> void:
	_material.set_shader_parameter("radio", valor)


func _poner_volumen(valor: float) -> void:
	AudioServer.set_bus_volume_db(_bus, valor)
