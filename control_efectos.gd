class_name ControlEfectos
extends Node

@export var objetivo: GeometryInstance3D       # la pantalla de la terminal
@export var grupo := "terminales"
@export var tecla := KEY_G                      # solo para probar (F es la linterna)
@export var radio := 0.5                        # m: solo su propia terminal
@export var dura_flash := 0.5                   # s
@export var dura_dissolve := 3.0                # s de a = 0 a a = 1
@export var tope := 0.5                         # se detiene a la mitad
@export var color_gastada := Color("#0E1626")

var mat: ShaderMaterial
var flash := 0.0
var avance := 0.0
var disolviendo := false


func _ready() -> void:
	mat = objetivo.material_override.duplicate()   # cada terminal con su copia
	objetivo.material_override = mat
	for d in get_tree().get_nodes_in_group(grupo):
		d.evento.connect(_on_evento)


func _process(delta: float) -> void:
	if Input.is_physical_key_pressed(tecla):
		golpe()
	flash = decaer(flash, 0.0, k_para(dura_flash), delta)
	mat.set_shader_parameter("flash", flash)
	if disolviendo:
		avance = avance_en(avance, delta, dura_dissolve)
		mat.set_shader_parameter("avance", avance_visible(avance))
		if avance >= tope:
			disolviendo = false
			mat.set_shader_parameter("ancho_borde", 0.0)
			mat.set_shader_parameter("color_base", color_gastada)


func _on_evento(posicion: Vector3) -> void:
	if objetivo.global_position.distance_to(posicion) <= radio:
		golpe()
		await get_tree().create_timer(dura_flash).timeout
		disolver()


func golpe() -> void:
	flash = 1.0


func disolver() -> void:
	disolviendo = true


static func mezclar(base: Color, color_flash: Color, t: float) -> Color:
	return base + (color_flash - base) * t


static func decaer(actual: float, base: float, k: float, dt: float) -> float:
	return actual + (base - actual) * (1.0 - exp(-k * dt))


static func k_para(duracion: float) -> float:
	return 3.0 / duracion


static func avance_en(actual: float, dt: float, duracion: float) -> float:
	return minf(1.0, actual + dt / duracion)


static func avance_visible(a: float) -> float:
	return lerpf(0.2, 0.8, a)   # el tramo donde sí se nota
