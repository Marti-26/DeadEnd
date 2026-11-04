class_name LuzParpadeante
extends OmniLight3D

@export var energia_base := 6.0
@export var amplitud := 0.6
@export var velocidad := 2.5
@export var semilla := 7
@export var tubo: GeometryInstance3D
@export var cono: GeometryInstance3D
@export var emision_max := 5.0

var ruido := FastNoiseLite.new()
var t := 0.0
var _mat_tubo: StandardMaterial3D
var _mat_cono: ShaderMaterial
var _cono_base := 1.0


func _ready() -> void:
	ruido.seed = semilla
	ruido.frequency = 1.0
	if tubo and tubo.material_override:
		_mat_tubo = tubo.material_override.duplicate()
		tubo.material_override = _mat_tubo
	if cono and cono.material_override:
		_mat_cono = cono.material_override.duplicate()
		cono.material_override = _mat_cono
		_cono_base = _mat_cono.get_shader_parameter("intensidad")


func _process(delta: float) -> void:
	t += delta
	light_energy = energia(energia_base, amplitud, ruido.get_noise_1d(t * velocidad))
	_pintar()


static func energia(base: float, amp: float, valor_ruido: float) -> float:
	return maxf(0.0, base * (1.0 + amp * valor_ruido))


func _pintar() -> void:
	var f := clampf(light_energy / maxf(0.001, energia_base * (1.0 + amplitud)), 0.0, 1.0)
	if _mat_tubo:
		_mat_tubo.emission_energy_multiplier = emision_max * f
	if _mat_cono:
		_mat_cono.set_shader_parameter("intensidad", _cono_base * f)
