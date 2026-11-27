extends Node3D
## Fondo animado del menú principal (vagón de DeadEnd).
## Uso: instancia deadend_menu.glb en la escena del menú y asígnale este script.
## Los botones van aparte, en una CanvasLayer por encima.

## Se emite cuando el vagón entra o sale del modo DEAD END (luces verdes).
## Sirve, por ejemplo, para que los botones también cambien de color.
signal estado_cambiado(dead_end: bool)

@export var entorno: WorldEnvironment
@export var ambiente_normal := Color(0.30, 0.20, 0.14)
@export var ambiente_dead_end := Color(0.04, 0.16, 0.08)
@export var energia_normal := 0.35
@export var energia_dead_end := 0.25

const ANIMACION := "DeadEnd_Menu"
const INICIO_DEAD_END := 6.233  # segundos (fotograma 188 de Blender)
const FIN_DEAD_END := 14.267    # segundos (fotograma 429 de Blender)

var _anim: AnimationPlayer
var _dead_end := false


func _ready() -> void:
	_anim = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim == null:
		push_warning("fondo_menu: no se encontró el AnimationPlayer dentro de deadend_menu.glb")
		return
	var nombre: String = ANIMACION
	if not _anim.has_animation(nombre):
		nombre = String(_anim.get_animation_list()[0])
	_anim.get_animation(nombre).loop_mode = Animation.LOOP_LINEAR
	_anim.play(nombre)

	var camara := find_child("MenuCam", true, false) as Camera3D
	if camara:
		camara.make_current()

	if entorno and entorno.environment:
		entorno.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR


func _process(_delta: float) -> void:
	if _anim == null or not _anim.is_playing():
		return
	var t := _anim.current_animation_position
	var d := t >= INICIO_DEAD_END and t < FIN_DEAD_END
	if d != _dead_end:
		_dead_end = d
		estado_cambiado.emit(d)
	if entorno and entorno.environment:
		entorno.environment.ambient_light_color = ambiente_dead_end if d else ambiente_normal
		entorno.environment.ambient_light_energy = energia_dead_end if d else energia_normal


## true mientras el vagón está en modo DEAD END.
func es_dead_end() -> bool:
	return _dead_end
