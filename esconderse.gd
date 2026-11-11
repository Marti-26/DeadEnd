extends Node

@export var tecla: String = "esconderse"
@export var grupo: String = "escondites"
@export var alcance: float = 1.5
@export var baja_estres: float = 1.0
@export var hundir_modelo: float = 0.45
@export var animacion: String = "crouch"

@onready var pj: CharacterBody3D = get_parent() as CharacterBody3D
@onready var modelo: Node3D = (pj.get_node_or_null("Sprite") if pj.has_node("Sprite") else pj.get_node_or_null("Modelo")) as Node3D
@onready var forma: CollisionShape3D = pj.get_node_or_null("CollisionShape3D") as CollisionShape3D

var escondido: bool = false
var banca: Node3D = null
var _modelo_y: float = 0.0


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed(tecla):
		if escondido:
			salir()
		else:
			var b: Node3D = mas_cercana() as Node3D
			if b != null:
				entrar(b)
	if escondido:
		if pj != null and pj.has_method("sumar_estres"):
			pj.call("sumar_estres", -baja_estres * delta)
		else:
			Partida.estres = maxf(0.0, Partida.estres - baja_estres * delta)


func entrar(b):
	escondido = true
	banca = b
	pj.add_to_group("escondidos")
	pj.set_physics_process(false)
	pj.velocity = Vector3.ZERO
	pj.avance = Vector3.ZERO
	pj.estado = pj.Estado.ESCONDERSE
	pj.ruido = 0.0
	if forma:
		forma.disabled = true
	pj.global_position = Vector3(b.global_position.x, pj.global_position.y, b.global_position.z)
	if modelo:
		_modelo_y = modelo.position.y
		modelo.position.y = _modelo_y - hundir_modelo
	if pj.sprite:
		pj.reproducir("sigilo", 0.0)
	else:
		pj.anim.play(animacion)
	print("escondida bajo ", b.name, " · estrés ", snappedf(Partida.estres, 0.1))


func salir():
	escondido = false
	pj.remove_from_group("escondidos")
	pj.global_position = banca.global_position + Vector3(0, pj.global_position.y - banca.global_position.y, 0.75)
	if modelo:
		modelo.position.y = _modelo_y
	if forma:
		forma.disabled = false
	pj.set_physics_process(true)
	print("sale de ", banca.name, " · estrés ", snappedf(Partida.estres, 0.1))
	banca = null


func mas_cercana():
	var mejor = null
	for b in get_tree().get_nodes_in_group(grupo):
		var d = distancia_a(b)
		if d <= alcance and (mejor == null or d < distancia_a(mejor)):
			mejor = b
	return mejor


func distancia_a(obj):
	var a = Vector2(pj.global_position.x, pj.global_position.z)
	var b = Vector2(obj.global_position.x, obj.global_position.z)
	return a.distance_to(b)
