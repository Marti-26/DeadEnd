extends Node

@export var tecla = "esconderse"
@export var grupo = "escondites"
@export var alcance = 1.5
@export var baja_estres = 1.0
@export var hundir_modelo = 0.45
@export var animacion = "crouch"

@onready var pj = get_parent()
@onready var modelo = pj.get_node_or_null("Modelo")
@onready var forma = pj.get_node_or_null("CollisionShape3D")

var escondido = false
var banca = null
var _modelo_y = 0.0


func _physics_process(delta):
	if Input.is_action_just_pressed(tecla):
		if escondido:
			salir()
		else:
			var b = mas_cercana()
			if b != null:
				entrar(b)
	if escondido:
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
