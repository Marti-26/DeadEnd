@tool
extends Node3D

@export var tamano: Vector2 = Vector2(0.9, 0.5):
	set(valor):
		tamano = valor
		_actualizar_malla()
@export_range(0.0, 1.0) var opacidad: float = 0.45:
	set(valor):
		opacidad = valor
		_actualizar_material()
@export_range(0.0, 1.0) var suavidad: float = 0.55:
	set(valor):
		suavidad = valor
		_actualizar_material()
@export var separacion_piso: float = 0.02
@export var distancia_desvanecer: float = 1.5

const CODIGO: String = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float opacidad = 0.45;
uniform float suavidad = 0.55;
void fragment() {
	float d = length(UV * 2.0 - 1.0);
	ALBEDO = vec3(0.0);
	ALPHA = opacidad * (1.0 - smoothstep(1.0 - suavidad, 1.0, d));
}
"""

static var _sombreado: Shader = null

var _malla: MeshInstance3D = null
var _material: ShaderMaterial = null
var _cuerpo: Node3D = null
var _desvanecer: float = 1.0
var altura_visual_piso: float = NAN


func _ready() -> void:
	if _sombreado == null:
		_sombreado = Shader.new()
		_sombreado.code = CODIGO
	_material = ShaderMaterial.new()
	_material.shader = _sombreado
	_malla = MeshInstance3D.new()
	_malla.name = "Mancha"
	_malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_malla.material_override = _material
	_malla.top_level = true
	add_child(_malla)
	_actualizar_malla()
	_actualizar_material()
	var n: Node = get_parent()
	while n != null:
		if n is CollisionObject3D:
			_cuerpo = n as Node3D
			break
		n = n.get_parent()
	if _cuerpo == null:
		_cuerpo = self


func _actualizar_malla() -> void:
	if _malla == null:
		return
	var plano: PlaneMesh = PlaneMesh.new()
	plano.size = tamano
	_malla.mesh = plano


func _actualizar_material() -> void:
	if _material == null:
		return
	_material.set_shader_parameter("opacidad", opacidad * _desvanecer)
	_material.set_shader_parameter("suavidad", suavidad)


func _physics_process(_delta: float) -> void:
	if _malla == null or _cuerpo == null:
		return
	var origen: Vector3 = _cuerpo.global_position
	var visible_sombra: bool = _cuerpo.is_visible_in_tree() and not _cuerpo.is_in_group(Grupos.ESCONDIDOS)
	_malla.visible = visible_sombra
	if not visible_sombra:
		return
	var piso_y: float = origen.y
	var espacio: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if not is_nan(altura_visual_piso):
		piso_y = altura_visual_piso
	elif espacio != null and not Engine.is_editor_hint():
		var consulta: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origen + Vector3.UP * 0.3, origen + Vector3.DOWN * (distancia_desvanecer + 0.5), 1)
		if _cuerpo is CollisionObject3D:
			consulta.exclude = [(_cuerpo as CollisionObject3D).get_rid()]
		var golpe: Dictionary = espacio.intersect_ray(consulta)
		if not golpe.is_empty():
			piso_y = (golpe["position"] as Vector3).y
	var altura: float = maxf(origen.y - piso_y, 0.0) if is_nan(altura_visual_piso) else 0.0
	var nuevo: float = clampf(1.0 - altura / maxf(distancia_desvanecer, 0.01), 0.0, 1.0)
	if not is_equal_approx(nuevo, _desvanecer):
		_desvanecer = nuevo
		_actualizar_material()
	var escala: float = lerpf(0.6, 1.0, _desvanecer)
	_malla.global_transform = Transform3D(Basis().scaled(Vector3(escala, 1.0, escala)), Vector3(origen.x, piso_y + separacion_piso, origen.z))
