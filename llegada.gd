class_name Llegada
extends Marker3D


func _ready() -> void:
	if Partida == null or Partida.llegada != name:
		return
	await get_tree().process_frame
	var jugador: Node = get_tree().get_first_node_in_group(Grupos.JUGADOR)
	if jugador == null:
		return
	var pj: CharacterBody3D = jugador as CharacterBody3D
	if pj != null:
		pj.global_position = global_position
		pj.velocity = Vector3.ZERO
	var camara: Camera3D = get_viewport().get_camera_3d()
	if camara != null and camara.has_method("saltar"):
		camara.call("saltar")
