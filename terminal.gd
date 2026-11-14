class_name Terminal
extends StaticBody3D

@export var recarga_hasta: float = 60.0
@export var pantalla: MeshInstance3D


func usar() -> void:
	var pj: Personaje = get_tree().get_first_node_in_group(Grupos.JUGADOR) as Personaje
	if pj == null:
		var objetivo_bat: Node = get_tree().get_first_node_in_group(Grupos.BATERIA)
		if objetivo_bat != null and "bateria" in objetivo_bat:
			pj = objetivo_bat as Personaje

	if pj != null:
		if pj.bateria < recarga_hasta:
			pj.bateria = recarga_hasta
			Partida.bateria = recarga_hasta
			print("terminal: batería al ", recarga_hasta, " %")
		if Partida != null:
			Partida.guardar_estado_personaje(pj)

	remove_from_group(Grupos.INTERACTIVOS)
	if pantalla != null:
		var m: StandardMaterial3D = pantalla.get_active_material(0).duplicate() as StandardMaterial3D
		if m != null:
			m.emission_enabled = false
			m.albedo_color = Color(0.25, 0.27, 0.28)
			pantalla.material_override = m
