@tool
extends Node3D

@export var textura: Texture2D:
	set(valor):
		textura = valor
		_reconstruir()
@export var alto: float = 1.3:
	set(valor):
		alto = valor
		_reconstruir()
@export var brillo: float = 0.05:
	set(valor):
		brillo = valor
		_reconstruir()
@export var luz: float = 0.4:
	set(valor):
		luz = valor
		_reconstruir()
@export var color_luz: Color = Color(0.62, 1.0, 0.82):
	set(valor):
		color_luz = valor
		_reconstruir()
@export var tinte: Color = Color(0.62, 0.86, 0.74):
	set(valor):
		tinte = valor
		_reconstruir()
@export_range(0.0, 1.0) var saturacion: float = 0.55:
	set(valor):
		saturacion = valor
		_reconstruir()

const FUENTE: FontFile = preload("res://assets/font/ShareTechMono-Regular.ttf")
const DESTELLOS: Script = preload("res://destellos.gd")
const CODIGO_SOMBREADO: String = """
shader_type spatial;
uniform sampler2D textura : source_color, filter_linear_mipmap_anisotropic;
uniform vec4 tinte : source_color = vec4(1.0);
uniform float saturacion = 1.0;
uniform float brillo = 0.1;
void fragment() {
	vec4 c = texture(textura, UV);
	float gris = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 color = mix(vec3(gris), c.rgb, saturacion) * tinte.rgb;
	ALBEDO = color;
	EMISSION = color * brillo;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
"""

static var _sombreado: Shader = null

var _borde: Node3D = null
var _capa: CanvasLayer = null


func _ready() -> void:
	_reconstruir()


func _reconstruir() -> void:
	if not is_inside_tree():
		return
	for h: Node in get_children():
		if h.name == "Contenido":
			remove_child(h)
			h.free()
	if textura == null:
		return
	var contenido: Node3D = Node3D.new()
	contenido.name = "Contenido"
	add_child(contenido)
	var proporcion: float = float(textura.get_width()) / float(textura.get_height())
	var tam: Vector2 = Vector2(alto * proporcion, alto)
	if _sombreado == null:
		_sombreado = Shader.new()
		_sombreado.code = CODIGO_SOMBREADO
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = _sombreado
	mat.set_shader_parameter("textura", textura)
	mat.set_shader_parameter("tinte", tinte)
	mat.set_shader_parameter("saturacion", saturacion)
	mat.set_shader_parameter("brillo", brillo)
	var lamina: QuadMesh = QuadMesh.new()
	lamina.size = tam
	var poster: MeshInstance3D = MeshInstance3D.new()
	poster.name = "Lamina"
	poster.mesh = lamina
	poster.material_override = mat
	poster.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	contenido.add_child(poster)
	var foco: SpotLight3D = SpotLight3D.new()
	foco.name = "Luz"
	foco.light_color = color_luz
	foco.light_energy = luz
	foco.light_specular = 0.0
	foco.spot_range = 3.0
	foco.spot_angle = 32.0
	foco.spot_attenuation = 0.8
	foco.spot_angle_attenuation = 1.4
	foco.shadow_enabled = false
	contenido.add_child(foco)
	foco.transform = Transform3D(Basis(), Vector3(0, tam.y * 0.5 + 0.35, 1.05)).looking_at(Vector3.ZERO, Vector3.UP)
	_borde = Node3D.new()
	_borde.name = "Borde"
	_borde.visible = false
	contenido.add_child(_borde)
	var azul: StandardMaterial3D = StandardMaterial3D.new()
	azul.albedo_color = Color(0.3, 0.65, 1.0)
	azul.emission_enabled = true
	azul.emission = Color(0.3, 0.65, 1.0)
	azul.emission_energy_multiplier = 2.5
	var g: float = 0.025
	var ancho_b: float = tam.x + 0.06
	var alto_b: float = tam.y + 0.06
	_linea(azul, Vector3(ancho_b + g, g, 0.01), Vector3(0, alto_b * 0.5, 0.01))
	_linea(azul, Vector3(ancho_b + g, g, 0.01), Vector3(0, -alto_b * 0.5, 0.01))
	_linea(azul, Vector3(g, alto_b + g, 0.01), Vector3(-ancho_b * 0.5, 0, 0.01))
	_linea(azul, Vector3(g, alto_b + g, 0.01), Vector3(ancho_b * 0.5, 0, 0.01))
	var destellos: MeshInstance3D = DESTELLOS.new() as MeshInstance3D
	destellos.name = "Brillo"
	destellos.set("tamano", tam)
	destellos.set("textura", textura)
	destellos.position = Vector3(0, 0, 0.006)
	contenido.add_child(destellos)
	if Engine.is_editor_hint():
		return
	var area: Area3D = Area3D.new()
	area.name = "Clic"
	area.collision_layer = 524288
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = false
	var forma: CollisionShape3D = CollisionShape3D.new()
	var caja: BoxShape3D = BoxShape3D.new()
	caja.size = Vector3(tam.x, tam.y, 0.2)
	forma.shape = caja
	area.add_child(forma)
	area.position = Vector3(0, 0, 0.4)
	contenido.add_child(area)
	get_viewport().physics_object_picking = true
	area.mouse_entered.connect(_al_entrar)
	area.mouse_exited.connect(_al_salir)
	area.input_event.connect(_al_clic)


func _linea(mat: StandardMaterial3D, tam: Vector3, pos: Vector3) -> void:
	var malla: BoxMesh = BoxMesh.new()
	malla.size = tam
	var m: MeshInstance3D = MeshInstance3D.new()
	m.mesh = malla
	m.material_override = mat
	m.position = pos
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_borde.add_child(m)


func _al_entrar() -> void:
	if _capa != null:
		return
	_borde.visible = true
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _al_salir() -> void:
	_borde.visible = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _al_clic(_camara: Node, evento: InputEvent, _punto: Vector3, _normal: Vector3, _forma: int) -> void:
	if evento is InputEventMouseButton:
		var boton: InputEventMouseButton = evento as InputEventMouseButton
		if boton.pressed and boton.button_index == MOUSE_BUTTON_LEFT:
			_al_salir()
			_abrir()


func _unhandled_input(evento: InputEvent) -> void:
	if _capa != null and evento.is_action_pressed("ui_cancel"):
		_cerrar()
		get_viewport().set_input_as_handled()


func _abrir() -> void:
	if _capa != null or textura == null:
		return
	_capa = CanvasLayer.new()
	_capa.layer = 10
	add_child(_capa)
	var pantalla: Vector2 = get_viewport().get_visible_rect().size
	var oscuro: ColorRect = ColorRect.new()
	oscuro.color = Color(0.0, 0.0, 0.02, 0.75)
	oscuro.size = pantalla
	oscuro.mouse_filter = Control.MOUSE_FILTER_STOP
	oscuro.gui_input.connect(_al_tocar_afuera)
	_capa.add_child(oscuro)
	var proporcion: float = float(textura.get_width()) / float(textura.get_height())
	var alto_img: float = pantalla.y * 0.9
	var ancho_img: float = alto_img * proporcion
	if ancho_img > pantalla.x * 0.9:
		ancho_img = pantalla.x * 0.9
		alto_img = ancho_img / proporcion
	var imagen: TextureRect = TextureRect.new()
	imagen.texture = textura
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_SCALE
	imagen.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	imagen.size = Vector2(ancho_img, alto_img)
	imagen.position = (pantalla - imagen.size) * 0.5
	imagen.pivot_offset = imagen.size * 0.5
	imagen.mouse_filter = Control.MOUSE_FILTER_STOP
	_capa.add_child(imagen)
	var x: Button = Button.new()
	x.text = "X"
	x.focus_mode = Control.FOCUS_NONE
	x.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	x.add_theme_font_override("font", FUENTE)
	x.add_theme_font_size_override("font_size", 26)
	x.size = Vector2(46.0, 46.0)
	x.position = Vector2(imagen.position.x + ancho_img + 10.0, imagen.position.y)
	if x.position.x + x.size.x > pantalla.x:
		x.position.x = imagen.position.x + ancho_img - x.size.x - 8.0
	x.pressed.connect(_cerrar)
	_capa.add_child(x)
	oscuro.modulate.a = 0.0
	imagen.modulate.a = 0.0
	imagen.scale = Vector2(0.85, 0.85)
	var t: Tween = _capa.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(oscuro, "modulate:a", 1.0, 0.2)
	t.tween_property(imagen, "modulate:a", 1.0, 0.2)
	t.tween_property(imagen, "scale", Vector2.ONE, 0.25)


func _al_tocar_afuera(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and (evento as InputEventMouseButton).pressed:
		_cerrar()


func _cerrar() -> void:
	if _capa == null:
		return
	var capa: CanvasLayer = _capa
	_capa = null
	var t: Tween = capa.create_tween().set_parallel(true)
	for hijo: Node in capa.get_children():
		t.tween_property(hijo, "modulate:a", 0.0, 0.15)
	t.chain().tween_callback(capa.queue_free)
