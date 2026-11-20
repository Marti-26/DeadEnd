
class_name Terminal
extends StaticBody3D

@export_range(1, 2) var numero_terminal: int = 1
@export var recarga_hasta: float = 60.0
@export var pantalla: MeshInstance3D

var activada: bool = false


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

	activada = true

	# Registrar la terminal activada
	Partida.activar_terminal(numero_terminal)

	# Impedir que se vuelva a utilizar
	remove_from_group(Grupos.INTERACTIVOS)

	if pantalla != null:
		var material_actual = pantalla.get_active_material(0)

		if material_actual is StandardMaterial3D:
			var m: StandardMaterial3D = material_actual.duplicate()
			m.emission_enabled = false
			m.albedo_color = Color(0.25, 0.27, 0.28)
			pantalla.material_override = m
