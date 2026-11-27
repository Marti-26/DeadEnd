class_name Interactuar
extends Node

@export var tecla: String = "usar"
@export var alcance: float = 1.35
@export var tiempo_necesario: float = 3.0
@export var bateria_inicial: float = 25.0

var bateria: float:
	get:
		return Partida.bateria
	set(valor):
		Partida.bateria = valor

@onready var pj: Personaje = get_parent() as Personaje

var progreso: float = 0.0
var actual: Node = null
var cercano: Node = null


func _ready() -> void:
	add_to_group(Grupos.BATERIA)
	if Partida.bateria < 0.0:
		Partida.bateria = bateria_inicial
	print("batería al cargar la escena: ", snappedf(bateria, 0.1), " %")


func _physics_process(delta: float) -> void:
	var obj: Node = mas_cercano()
	cercano = obj
	if not Input.is_action_pressed(tecla) or obj == null:
		progreso = 0.0
		actual = null
		return
	# Si el objeto no se puede usar, rechazar de inmediato
	if obj.has_method("puede_usar") and not obj.puede_usar(pj):
		if Input.is_action_just_pressed(tecla) or obj != actual:
			actual = obj
			if obj.has_method("rechazar_uso"):
				obj.rechazar_uso()
		progreso = 0.0
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


func mas_cercano() -> Node:
	var mejor: Node = null
	for obj in get_tree().get_nodes_in_group(Grupos.INTERACTIVOS):
		if not is_instance_valid(obj) or not obj.is_inside_tree() or not obj.is_visible_in_tree():
			continue
		var d = distancia_a(obj)
		if d <= alcance and (mejor == null or d < distancia_a(mejor)):
			mejor = obj
	return mejor


func distancia_a(obj):
	if pj == null or obj == null:
		return 9999.0
	# Si están en pisos distintos o hay diferencia de altura, ignorar
	if absf(pj.global_position.y - obj.global_position.y) > 1.6:
		return 9999.0
	var a = Vector2(pj.global_position.x, pj.global_position.z)
	var b = Vector2(obj.global_position.x, obj.global_position.z)
	return a.distance_to(b)
