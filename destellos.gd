@tool
extends MeshInstance3D

@export var tamano: Vector2 = Vector2(1.0, 1.4):
	set(valor):
		tamano = valor
		_configurar()
@export var textura: Texture2D:
	set(valor):
		textura = valor
		_configurar()
@export var color_brillo: Color = Color(1.0, 0.72, 0.25):
	set(valor):
		color_brillo = valor
		_configurar()
@export_range(0.0, 1.0) var intensidad: float = 0.55:
	set(valor):
		intensidad = valor
		_configurar()
@export var ancho_brillo: float = 0.09:
	set(valor):
		ancho_brillo = valor
		_configurar()
@export var cada: float = 3.5:
	set(valor):
		cada = valor
		_configurar()
@export var duracion_cruce: float = 0.9:
	set(valor):
		duracion_cruce = valor
		_configurar()

const CODIGO: String = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled;
uniform sampler2D textura : source_color, filter_linear_mipmap;
uniform bool usar_textura = false;
uniform vec4 color : source_color = vec4(1.0, 0.72, 0.25, 1.0);
uniform float intensidad = 0.55;
uniform float ancho = 0.09;
uniform float periodo = 3.5;
uniform float duracion = 0.9;
uniform float desfase = 0.0;
void fragment() {
	float forma = usar_textura ? texture(textura, UV).a : 1.0;
	float p = mod(TIME + desfase, periodo) / duracion;
	float pos = mix(-0.25, 1.25, p);
	float diagonal = (UV.x + UV.y * 0.5) / 1.5;
	float banda = (1.0 - smoothstep(0.0, ancho, abs(diagonal - pos))) * step(p, 1.0);
	ALBEDO = color.rgb;
	ALPHA = banda * intensidad * forma;
}
"""

static var _sombreado: Shader = null

var _material: ShaderMaterial = null
var _desfase: float = -1.0


func _ready() -> void:
	_configurar()


func _configurar() -> void:
	if _sombreado == null:
		_sombreado = Shader.new()
		_sombreado.code = CODIGO
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = _sombreado
	if _desfase < 0.0:
		_desfase = randf() * maxf(cada, 0.1)
	var quad: QuadMesh = QuadMesh.new()
	quad.size = tamano
	mesh = quad
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material.set_shader_parameter("textura", textura)
	_material.set_shader_parameter("usar_textura", textura != null)
	_material.set_shader_parameter("color", color_brillo)
	_material.set_shader_parameter("intensidad", intensidad)
	_material.set_shader_parameter("ancho", ancho_brillo)
	_material.set_shader_parameter("periodo", maxf(cada, duracion_cruce + 0.1))
	_material.set_shader_parameter("duracion", maxf(duracion_cruce, 0.05))
	_material.set_shader_parameter("desfase", _desfase)
