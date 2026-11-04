extends StaticBody3D

@export var recarga_hasta = 60.0
@export var pantalla: MeshInstance3D


func usar():
	var jugador = get_tree().get_first_node_in_group("bateria")
	if jugador == null:
		return
	jugador.bateria = maxf(jugador.bateria, recarga_hasta)
	print("batería: ", jugador.bateria, " %")
	remove_from_group("interactivos")
	if pantalla:
		var m = pantalla.get_active_material(0).duplicate()
		m.emission_enabled = false
		m.albedo_color = Color(0.25, 0.27, 0.28)
		pantalla.material_override = m
