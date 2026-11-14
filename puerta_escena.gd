class_name PuertaEscena
extends Area3D

@export_file("*.tscn") var destino: String = ""
@export var llegada: String = ""

var _usada: bool = false


func _ready() -> void:
	body_entered.connect(_al_entrar)


func _al_entrar(cuerpo: Node3D) -> void:
	if _usada or destino == "" or not cuerpo.is_in_group(Grupos.JUGADOR):
		return
	_usada = true
	var pj: Personaje = cuerpo as Personaje
	if pj != null and Partida != null:
		Partida.guardar_estado_personaje(pj)
	Partida.cambiar_escena(destino, llegada)
