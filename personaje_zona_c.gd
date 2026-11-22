extends "res://personaje.gd"

const SombraPies = preload("res://sombra_pies.gd")

@export var escaleras: Node3D

@onready var altura_base_sprite: float = sprite.position.y
@onready var sombra: SombraPies = sprite.get_node("Sombra")
var peldanos: Array[MeshInstance3D] = []

func _ready() -> void:
	super._ready()
	add_to_group(Grupos.ZONA_SEGURA)
	Partida.estres = 0.0
	sonido_latidos.stop()
	sonido_respiracion.stop()
	if escaleras != null:
		for nodo in escaleras.get_children():
			if nodo is MeshInstance3D and nodo.name.begins_with("Escalon") and nodo.mesh is BoxMesh:
				peldanos.append(nodo)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	var superficie := _altura_del_peldano()
	sombra.altura_visual_piso = superficie
	var ajuste := 0.0 if is_nan(superficie) else superficie - global_position.y
	sprite.position.y = move_toward(sprite.position.y, altura_base_sprite + ajuste, 5.0 * delta)

func _altura_del_peldano() -> float:
	if not is_on_floor():
		return NAN
	for peldano in peldanos:
		var punto := peldano.to_local(global_position)
		var semitamanio: Vector3 = peldano.mesh.size * 0.5
		if punto.x >= -semitamanio.x and punto.x < semitamanio.x and absf(punto.z) <= semitamanio.z:
			return peldano.to_global(Vector3.UP * semitamanio.y).y
	return NAN

func _process(delta: float) -> void:
	Partida.estres = 0.0
	_consumir_bateria(delta)
	_actualizar_linterna()
	_actualizar_bombillo()
