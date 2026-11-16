class_name EstacionCarga
extends StaticBody3D

@export var carga: float = 100.0
@export var punto_guardado: String = "PuntoGuardado"
@export var pantalla: MeshInstance3D
@export var aviso: Label3D

var _mat: StandardMaterial3D
@onready var sonido_recarga: AudioStreamPlayer3D = $SonidoRecarga


func _ready() -> void:
	add_to_group(Grupos.INTERACTIVOS)
	if pantalla != null:
		_mat = pantalla.get_active_material(0).duplicate() as StandardMaterial3D
		pantalla.material_override = _mat
	if aviso != null:
		aviso.visible = false
	_pintar()



func usar() -> void:
	var pj: Personaje = get_tree().get_first_node_in_group(Grupos.JUGADOR) as Personaje
	if pj != null:
		if pj.bateria < carga:
			pj.bateria = carga
			Partida.bateria = carga
			Partida.estacion_usada = true
			# Sonido al recargar la batería
			sonido_recarga.stop()
			sonido_recarga.play()
			print("estación de carga: batería al ", carga, " %")
		if Partida != null:
			Partida.guardar_estado_personaje(pj)
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
