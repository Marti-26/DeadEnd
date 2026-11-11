extends StaticBody3D

const LIMITE_RECARGA: float = 60.0

@export var carga: float = 60.0
@export var punto_guardado: String = "PuntoGuardado"
@export var pantalla: MeshInstance3D
@export var aviso: Label3D

var _mat: StandardMaterial3D


func _ready() -> void:
	add_to_group("interactivos")
	if pantalla != null:
		_mat = pantalla.get_active_material(0).duplicate() as StandardMaterial3D
		pantalla.material_override = _mat
	if aviso != null:
		aviso.visible = false
	_pintar()


func usar() -> void:
	var objetivo_bat: Node = get_tree().get_first_node_in_group("bateria")
	if objetivo_bat == null or not ("bateria" in objetivo_bat):
		objetivo_bat = get_tree().get_first_node_in_group("jugador")
	if not Partida.estacion_usada and objetivo_bat != null and "bateria" in objetivo_bat:
		var limite: float = minf(carga, LIMITE_RECARGA)
		var actual: float = float(objetivo_bat.get("bateria"))
		if actual < limite:
			objetivo_bat.set("bateria", limite)
			Partida.estacion_usada = true
			print("estación de carga: batería al ", limite, " %")
	Partida.guardar(punto_guardado)
	_pintar()
	_mostrar("GUARDADO")


func _pintar() -> void:
	if _mat == null:
		return
	if Partida.estacion_usada:
		_mat.emission = Color(0.9, 0.35, 0.6)
		_mat.emission_energy_multiplier = 0.8
	else:
		_mat.emission = Color(0.45, 1.0, 0.75)
		_mat.emission_energy_multiplier = 2.0


func _mostrar(texto: String) -> void:
	if aviso == null:
		return
	aviso.text = texto
	aviso.visible = true
	await get_tree().create_timer(2.0).timeout
	aviso.visible = false
