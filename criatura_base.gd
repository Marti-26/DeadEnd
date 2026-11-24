class_name CriaturaBase
extends CharacterBody3D

signal evento(posicion: Vector3)

@export var rapidez: float = 2.0

var puesto: Vector3 = Vector3.ZERO
var reloj: float = 0.0
var jugador: Node = null


func _enter_tree() -> void:
	add_to_group(Grupos.DISPARADORES)


func _ready() -> void:
	jugador = get_tree().get_first_node_in_group(Grupos.JUGADOR)
	puesto = global_position
	collision_mask |= 4


func aplicar_gravedad(delta: float) -> void:
	velocity += get_gravity() * delta


func emitir_evento() -> void:
	evento.emit(global_position)


func distancia_a(p: Vector3) -> float:
	var o: Vector3 = global_position
	return Vector2(p.x - o.x, p.z - o.z).length()


func distancia_al_jugador() -> float:
	if jugador != null:
		return distancia_a(jugador.global_position)
	return INF
