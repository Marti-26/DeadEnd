extends StaticBody3D

const LIMITE_RECARGA: float = 60.0

@export var recarga_hasta: float = 60.0
@export var pantalla: MeshInstance3D


func usar() -> void:
	var objetivo_bat: Node = get_tree().get_first_node_in_group("bateria")
	if objetivo_bat == null or not ("bateria" in objetivo_bat):
		objetivo_bat = get_tree().get_first_node_in_group("jugador")
	if objetivo_bat == null or not ("bateria" in objetivo_bat):
		return
	var limite: float = minf(recarga_hasta, LIMITE_RECARGA)
	var actual: float = float(objetivo_bat.get("bateria"))
	if actual >= limite:
		return
	objetivo_bat.set("bateria", limite)
	print("batería: ", float(objetivo_bat.get("bateria")), " %")
	remove_from_group("interactivos")
	if pantalla != null:
		var m: StandardMaterial3D = pantalla.get_active_material(0).duplicate() as StandardMaterial3D
		if m != null:
			m.emission_enabled = false
			m.albedo_color = Color(0.25, 0.27, 0.28)
			pantalla.material_override = m
