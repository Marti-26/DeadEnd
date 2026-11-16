class_name NpcPasajero
extends Node3D

@export var tecla: String = "hablar"
@export var alcance: float = 2.0
@export var nombre_dialogo: String = "PASAJERO"
@export var frases: Array[String] = []
@export var duracion: float = 4.5
@export var mitad_ancho_vagon: float = 1.5

var _indice: int = 0
var _hablando: bool = false


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or frases.is_empty():
		return
	var jugador: Node3D = get_tree().get_first_node_in_group(Grupos.JUGADOR) as Node3D
	if jugador == null:
		return
	var cerca: bool = _al_alcance(jugador)
	if _hablando and not cerca:
		_hablando = false
		Dialogo.obtener(get_tree()).ocultar()
	if cerca and Input.is_action_just_pressed(tecla):
		hablar()


func hablar() -> void:
	Dialogo.obtener(get_tree()).mostrar(nombre_dialogo, frases[_indice], duracion)
	_indice = (_indice + 1) % frases.size()
	_hablando = true


func _al_alcance(jugador: Node3D) -> bool:
	var a: Vector2 = Vector2(global_position.x, global_position.z)
	var b: Vector2 = Vector2(jugador.global_position.x, jugador.global_position.z)
	if a.distance_to(b) > alcance:
		return false
	var vagon: Node3D = get_parent() as Node3D
	if vagon == null:
		return true
	return absf(vagon.to_local(jugador.global_position).z) < mitad_ancho_vagon
