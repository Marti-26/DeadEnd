class_name EstacionCarga
extends StaticBody3D

@export var carga: float = 100.0
@export var punto_guardado: String = "PuntoGuardado"
@export var pantalla: MeshInstance3D
@export var aviso: Label3D

var _mat: StandardMaterial3D
var usada: bool = false
@onready var sonido_recarga: AudioStreamPlayer3D = $SonidoRecarga


func _ready() -> void:
	add_to_group(Grupos.INTERACTIVOS)
	if pantalla != null:
		_mat = pantalla.get_active_material(0).duplicate() as StandardMaterial3D
		pantalla.material_override = _mat
	if aviso != null:
		aviso.visible = false
	if Partida != null and Partida.estacion_usada:
		usada = true
	_pintar()

#metodos para informar si se puede interactuar con la estacion de carga
func puede_usar(jugador: Personaje) -> bool:
	if jugador == null or not jugador.tiene_celular:
		return false
	if usada or (Partida != null and Partida.estacion_usada):
		return false
	if jugador.bateria >= carga:
		return false
	return true

func rechazar_uso() -> void:
	var pj: Personaje = get_tree().get_first_node_in_group(Grupos.JUGADOR) as Personaje
	if pj != null and not pj.tiene_celular:
		_mostrar("SIN CELULAR")
		Dialogo.obtener(get_tree()).mostrar(
			"ESTACIÓN DE CARGA",
			"Necesitas el celular para recargar la batería.",
			3.5, false, null, &"default", false
		)
		return

	if usada or (Partida != null and Partida.estacion_usada):
		_mostrar("AGOTADA")
		Dialogo.obtener(get_tree()).mostrar(
			"ESTACIÓN DE CARGA",
			"Esta estación ya no tiene energía disponible.",
			3.5, false, null, &"default", false
		)
		return

	if pj != null and pj.bateria >= carga:
		_mostrar("BATERÍA LLENA")
		Dialogo.obtener(get_tree()).mostrar(
			"ESTACIÓN DE CARGA",
			"La batería del celular ya está al 100%.",
			3.5, false, null, &"default", false
		)
		return

func usar() -> void:
	var pj: Personaje = get_tree().get_first_node_in_group(Grupos.JUGADOR) as Personaje
	if pj != null:
		if not pj.tiene_celular or usada or pj.bateria >= carga:
			return
		pj.bateria = carga
		Partida.bateria = carga
		usada = true
		if Partida != null:
			Partida.estacion_usada = true
			Partida.guardar_estado_personaje(pj)
		# Sonido al recargar la batería
		sonido_recarga.stop()
		sonido_recarga.play()
		print("estación de carga: batería al ", carga, " %")
	Partida.guardar(punto_guardado)
	_pintar()
	_mostrar("GUARDADO")



func _pintar() -> void:
	if _mat == null:
		return
	var rotulo: Label3D = get_node_or_null("Rotulo") as Label3D
	if usada or (Partida != null and Partida.estacion_usada):
		_mat.emission = Color(0.9, 0.35, 0.6)
		_mat.emission_energy_multiplier = 0.8
		if rotulo != null:
			rotulo.modulate = Color(0.9, 0.35, 0.6)
	else:
		_mat.emission = Color(0.45, 1.0, 0.75)
		_mat.emission_energy_multiplier = 2.0
		if rotulo != null:
			rotulo.modulate = Color(0.6, 1.6, 1.15)


func _mostrar(texto: String) -> void:
	if aviso == null:
		return
	var rotulo: Label3D = get_node_or_null("Rotulo") as Label3D
	if rotulo != null:
		rotulo.visible = false
	aviso.text = texto
	aviso.visible = true
	await get_tree().create_timer(2.0).timeout
	aviso.visible = false
	if rotulo != null:
		rotulo.visible = true
