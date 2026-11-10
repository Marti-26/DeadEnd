extends Node

@export var tecla = "usar"
@export var alcance = 1.8
@export var tiempo_necesario = 3.0
@export var bateria_inicial = 25.0

var bateria:
	get:
		return Partida.bateria
	set(valor):
		Partida.bateria = valor

@onready var pj = get_parent()

var progreso = 0.0
var actual = null


func _ready():
	add_to_group("bateria")
	if Partida.bateria < 0.0:
		Partida.bateria = bateria_inicial
	print("batería al cargar la escena: ", snappedf(bateria, 0.1), " %")


func _physics_process(delta):
	var obj = mas_cercano()
	if not Input.is_action_pressed(tecla) or obj == null:
		progreso = 0.0
		actual = null
		return
	if obj != actual:
		actual = obj
		progreso = 0.0
	var antes = progreso
	progreso += delta / tiempo_necesario
	if int(progreso * 4) > int(antes * 4) and progreso < 0.999:
		print(obj.name, ": ", int(progreso * 4) * 25, " %")
	if progreso >= 0.999:
		print("completado: ", obj.name)
		if obj.has_method("usar"):
			obj.usar()
		progreso = 0.0


func mas_cercano():
	var mejor = null
	for obj in get_tree().get_nodes_in_group("interactivos"):
		var d = distancia_a(obj)
		if d <= alcance and (mejor == null or d < distancia_a(mejor)):
			mejor = obj
	return mejor


func distancia_a(obj):
	var a = Vector2(pj.global_position.x, pj.global_position.z)
	var b = Vector2(obj.global_position.x, obj.global_position.z)
	return a.distance_to(b)
