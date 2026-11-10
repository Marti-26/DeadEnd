extends StaticBody3D

@export var carga = 100.0
@export var punto_guardado = "PuntoGuardado"
@export var pantalla: MeshInstance3D
@export var aviso: Label3D

var _mat: StandardMaterial3D


func _ready():
	add_to_group("interactivos")
	if pantalla:
		_mat = pantalla.get_active_material(0).duplicate()
		pantalla.material_override = _mat
	if aviso:
		aviso.visible = false
	_pintar()


func usar():
	var jugador = get_tree().get_first_node_in_group("bateria")
	if not Partida.estacion_usada and jugador:
		jugador.bateria = carga
		Partida.estacion_usada = true
		print("estación de carga: batería al ", carga, " %")
	Partida.guardar(punto_guardado)
	_pintar()
	_mostrar("GUARDADO")


func _pintar():
	if _mat == null:
		return
	if Partida.estacion_usada:
		_mat.emission = Color(0.9, 0.35, 0.6)
		_mat.emission_energy_multiplier = 0.8
	else:
		_mat.emission = Color(0.45, 1.0, 0.75)
		_mat.emission_energy_multiplier = 2.0


func _mostrar(texto):
	if aviso == null:
		return
	aviso.text = texto
	aviso.visible = true
	await get_tree().create_timer(2.0).timeout
	aviso.visible = false
