class_name Bombillo
extends Node3D

@export var color: Color = Color(0.45, 1.0, 0.55)
@export var energia: float = 1.2
@export var alcance: float = 3.2
@export var separacion: Vector3 = Vector3(0.55, 1.9, 0.2)

var _dueno: Node3D = null


func _ready() -> void:
	_dueno = get_parent() as Node3D
	top_level = true
	var luz: OmniLight3D = OmniLight3D.new()
	luz.name = "LuzAura_Criatura"
	luz.light_color = color
	luz.light_energy = energia
	luz.light_specular = 0.2
	luz.omni_range = alcance
	luz.omni_attenuation = 1.5
	luz.shadow_enabled = false
	add_child(luz)
	_seguir()


func _process(_delta: float) -> void:
	_seguir()


func _seguir() -> void:
	if _dueno == null or not is_instance_valid(_dueno):
		queue_free()
		return
	global_position = _dueno.global_position + separacion
	visible = _dueno.is_visible_in_tree()
