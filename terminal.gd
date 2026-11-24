class_name Terminal
extends StaticBody3D

@export_range(1, 2) var numero_terminal: int = 1
@export var recarga_hasta: float = 60.0
@export var pantalla: MeshInstance3D
@export var pared_soporte: StaticBody3D

var activada: bool = false
var material_pantalla: ShaderMaterial

@onready var mensaje := get_node_or_null("Activado") as Label3D
@onready var jugador := get_tree().get_first_node_in_group(Grupos.JUGADOR) as Personaje
@onready var interaccion := jugador.get_node_or_null("Interactuar") as Interactuar if jugador != null else null


func _ready() -> void:
	if pantalla == null:
		pantalla = get_node_or_null("Pantalla") as MeshInstance3D
	if pantalla != null:
		material_pantalla = pantalla.material_override as ShaderMaterial
	set_physics_process(material_pantalla != null)

	var ya_activada := Partida.terminal_1_activada if numero_terminal == 1 else Partida.terminal_2_activada
	if ya_activada:
		_mostrar_activado()


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(jugador):
		return

	var cerca: bool = interaccion != null and interaccion.distancia_a(self) <= interaccion.alcance
	var progreso := interaccion.progreso if interaccion != null and interaccion.actual == self else -1.0
	material_pantalla.set_shader_parameter("mostrar_circulo", cerca or _recibe_linterna())
	material_pantalla.set_shader_parameter("progreso", progreso)


func _recibe_linterna() -> bool:
	var foco := jugador.linterna as SpotLight3D
	if foco == null or not foco.is_visible_in_tree() or pantalla.to_local(foco.global_position).z <= 0.0:
		return false

	var hacia_pantalla := pantalla.global_position - foco.global_position
	if hacia_pantalla.length_squared() > foco.spot_range * foco.spot_range:
		return false
	if (-foco.global_basis.z).dot(hacia_pantalla.normalized()) < cos(deg_to_rad(foco.spot_angle)):
		return false

	var rayo := PhysicsRayQueryParameters3D.create(foco.global_position, pantalla.global_position)
	rayo.exclude = [jugador.get_rid(), get_rid()]
	var impacto := get_world_3d().direct_space_state.intersect_ray(rayo)
	return impacto.is_empty() or impacto.get("collider") == pared_soporte


func usar() -> void:
	if activada:
		return

	var pj: Personaje = get_tree().get_first_node_in_group(Grupos.JUGADOR) as Personaje
	if pj == null:
		var objetivo_bat: Node = get_tree().get_first_node_in_group(Grupos.BATERIA)
		if objetivo_bat != null and "bateria" in objetivo_bat:
			pj = objetivo_bat as Personaje

	if pj != null:
		if pj.bateria < recarga_hasta:
			pj.bateria = recarga_hasta
			print("terminal: batería al ", recarga_hasta, " %")
		Partida.guardar_estado_personaje(pj)

	Partida.activar_terminal(numero_terminal)
	_mostrar_activado()


func _mostrar_activado() -> void:
	activada = true
	remove_from_group(Grupos.INTERACTIVOS)
	if material_pantalla != null:
		material_pantalla.set_shader_parameter("mostrar_circulo", false)
	elif pantalla != null:
		var material_anterior := pantalla.get_active_material(0) as StandardMaterial3D
		if material_anterior != null:
			var material_apagado := material_anterior.duplicate() as StandardMaterial3D
			material_apagado.emission_enabled = false
			material_apagado.albedo_color = Color(0.25, 0.27, 0.28)
			pantalla.material_override = material_apagado
	if mensaje != null:
		mensaje.show()
	set_physics_process(false)
