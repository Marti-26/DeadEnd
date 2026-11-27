class_name FondoMenu
extends Node3D

signal estado_cambiado(dead_end: bool)

@export var entorno: WorldEnvironment
@export var ambiente_normal: Color = Color(0.30, 0.20, 0.14)
@export var ambiente_dead_end: Color = Color(0.04, 0.16, 0.08)
@export var energia_normal: float = 0.35
@export var energia_dead_end: float = 0.25

const ANIMACION: String = "DeadEnd_Menu"
const INICIO_DEAD_END: float = 6.233
const FIN_DEAD_END: float = 14.267
const ENERGIAS: Dictionary = {
	"CeilLamp_F": 1.6,
	"CeilLamp_N": 0.9,
	"FloorGlow": 0.8,
	"WindowSpill": 1.6,
	"Sun": 0.3,
}
const ALCANCES: Dictionary = {
	"CeilLamp": 4.5,
	"FloorGlow": 1.8,
	"WindowSpill": 4.0,
}

var _anim: AnimationPlayer
var _lampara: Light3D
var _energia_base: float = 1.0
var _dead_end: bool = false


func _ready() -> void:
	_anim = find_child("AnimationPlayer", true, false) as AnimationPlayer
	_lampara = find_child("CeilLamp_F2", true, false) as Light3D
	var camara: Camera3D = find_child("MenuCam", true, false) as Camera3D
	if camara != null:
		camara.make_current()
	if entorno != null and entorno.environment != null:
		entorno.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	if _anim == null:
		push_warning("fondo_menu: no se encontró el AnimationPlayer dentro de deadend_menu.glb")
		_normalizar_luces(null)
		return
	var nombre: String = ANIMACION
	if not _anim.has_animation(nombre):
		nombre = String(_anim.get_animation_list()[0])
	var animacion: Animation = _anim.get_animation(nombre)
	animacion.loop_mode = Animation.LOOP_LINEAR
	_normalizar_luces(animacion)
	_anim.play(nombre)
	_anim.seek(0.0, true)
	if _lampara != null:
		_energia_base = maxf(_lampara.light_energy, 0.001)


func _process(_delta: float) -> void:
	var d: bool = es_dead_end()
	if d != _dead_end:
		_dead_end = d
		estado_cambiado.emit(d)
	if entorno != null and entorno.environment != null:
		entorno.environment.ambient_light_color = ambiente_dead_end if d else ambiente_normal
		entorno.environment.ambient_light_energy = energia_dead_end if d else energia_normal


func tiempo() -> float:
	if _anim == null or not _anim.is_playing():
		return 0.0
	return _anim.current_animation_position


func es_dead_end() -> bool:
	var t: float = tiempo()
	return t >= INICIO_DEAD_END and t < FIN_DEAD_END


func intensidad_luz() -> float:
	if _lampara == null:
		return 1.0
	return _lampara.light_energy / _energia_base


func _normalizar_luces(animacion: Animation) -> void:
	var raiz: Node = null
	if _anim != null:
		raiz = _anim.get_node_or_null(_anim.root_node)
	for nodo: Node in find_children("*", "Light3D", true, false):
		var luz: Light3D = nodo as Light3D
		var base: float = luz.light_energy
		var pista: int = -1
		if animacion != null and raiz != null:
			pista = _pista_energia(animacion, raiz, luz)
			if pista >= 0:
				base = _valor_inicial(animacion, pista)
		if base > 0.0001:
			var factor: float = _energia_objetivo(String(luz.name)) / base
			luz.light_energy = base * factor
			if pista >= 0:
				_escalar_pista(animacion, pista, factor)
		var alcance: float = _alcance(String(luz.name))
		if luz is OmniLight3D:
			(luz as OmniLight3D).omni_range = alcance
			(luz as OmniLight3D).omni_attenuation = 1.2
		elif luz is SpotLight3D:
			(luz as SpotLight3D).spot_range = alcance
			(luz as SpotLight3D).spot_attenuation = 1.2


func _pista_energia(animacion: Animation, raiz: Node, luz: Light3D) -> int:
	for i: int in animacion.get_track_count():
		var ruta: NodePath = animacion.track_get_path(i)
		var propiedad: String = String(ruta.get_concatenated_subnames())
		if not (propiedad.contains("energy") or propiedad.contains("intensity")):
			continue
		if raiz.get_node_or_null(NodePath(String(ruta.get_concatenated_names()))) == luz:
			return i
	return -1


func _valor_inicial(animacion: Animation, pista: int) -> float:
	if animacion.track_get_type(pista) == Animation.TYPE_BEZIER:
		return animacion.bezier_track_interpolate(pista, 0.0)
	return float(animacion.value_track_interpolate(pista, 0.0))


func _escalar_pista(animacion: Animation, pista: int, factor: float) -> void:
	var bezier: bool = animacion.track_get_type(pista) == Animation.TYPE_BEZIER
	for k: int in animacion.track_get_key_count(pista):
		if bezier:
			animacion.bezier_track_set_key_value(pista, k, animacion.bezier_track_get_key_value(pista, k) * factor)
		else:
			animacion.track_set_key_value(pista, k, float(animacion.track_get_key_value(pista, k)) * factor)


func _energia_objetivo(nombre: String) -> float:
	for prefijo: String in ENERGIAS:
		if nombre.begins_with(prefijo):
			return float(ENERGIAS[prefijo])
	return 1.0


func _alcance(nombre: String) -> float:
	for prefijo: String in ALCANCES:
		if nombre.begins_with(prefijo):
			return float(ALCANCES[prefijo])
	return 4.0
