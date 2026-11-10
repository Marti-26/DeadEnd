extends Marker3D


func _ready():
	if Partida.llegada != name:
		return
	await get_tree().process_frame
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return
	jugador.global_position = global_position
	jugador.velocity = Vector3.ZERO
	var camara = get_viewport().get_camera_3d()
	if camara and camara.has_method("saltar"):
		camara.saltar()
