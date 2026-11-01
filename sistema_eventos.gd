class_name SistemaEventos
extends Node

@export var luz_evento: OmniLight3D
@export var pico_destello := 6.0
@export var k_destello := 0.6

@export var luz_variable: Light3D
@export var color_bajo := Color(0.36, 0.62, 0.72)
@export var color_alto := Color(0.784, 0.243, 0.243)
@export var k_variable := 4.0

var variable := 0.0


func _ready() -> void:
	for d in get_tree().get_nodes_in_group("disparadores"):
		d.evento.connect(_on_evento)
	luz_evento.light_energy = 0.0


func _process(delta: float) -> void:
	luz_evento.light_energy = decaer(luz_evento.light_energy, 0.0, k_destello, delta)
	if luz_variable != null:
		if Input.is_key_pressed(KEY_UP):
			variable = minf(1.0, variable + delta * 0.5)
		elif Input.is_key_pressed(KEY_DOWN):
			variable = maxf(0.0, variable - delta * 0.5)
		variable = clampf(variable, 0.0, 1.0)
		luz_variable.light_color = color_bajo.lerp(color_alto, variable)
		var deseada := 1.0 + 3.0 * variable
		luz_variable.light_energy = decaer(luz_variable.light_energy, deseada, k_variable, delta)


func _on_evento(posicion: Vector3) -> void:
	luz_evento.global_position = posicion + Vector3.UP * 1.5
	luz_evento.light_energy = pico_destello


static func decaer(actual: float, base: float, k: float, dt: float) -> float:
	var alpha := 1.0 - exp(-k * dt)
	return actual + (base - actual) * alpha
