extends Node

const ZONA_SEGURA_SCRIPT: String = "res://zona_segura.gd"

var _zona: Node3D = null
var _base_escalera: Vector3 = Vector3.ZERO
var _hay_escalera: bool = false
var _jugador: Node3D = null


func _ready() -> void:
	await get_tree().process_frame
	var escena: Node = get_tree().current_scene
	if escena == null:
		return
	for n: Node in escena.find_children("*", "Node3D", true, false):
		var guion: Script = n.get_script() as Script
		if guion != null and guion.resource_path == ZONA_SEGURA_SCRIPT:
			_zona = n as Node3D
			break
	if _zona == null:
		return
	var subida: Node3D = escena.get_node_or_null("Escalera/SubidaSegundoPiso") as Node3D
	if subida != null and _zona.global_position.y > 2.0:
		_hay_escalera = true
		_base_escalera = Vector3(subida.global_position.x, 0.0, -3.0)


func destino_actual() -> Variant:
	if _zona == null or not is_instance_valid(_zona):
		return null
	if _jugador == null or not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group(Grupos.JUGADOR) as Node3D
		if _jugador == null:
			return null
	if _jugador.is_in_group(Grupos.ZONA_SEGURA):
		return null
	if _hay_escalera and _jugador.global_position.y < 2.0:
		return _base_escalera
	return _zona.global_position + Vector3(0.0, 0.0, 2.0)
