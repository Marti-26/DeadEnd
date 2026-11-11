extends Node

enum Estado { LISTA, ACTIVA, RECARGA }

@export var tecla: String = "dash"
@export var duracion: float = 0.8
@export var recarga: float = 3.0
@export var rapidez: float = 7.5
@export var animacion: String = "sprint"
@export var estres_por_dash: float = 15.0

@onready var pj: CharacterBody3D = get_parent() as CharacterBody3D

var estado: Estado = Estado.LISTA
var tiempo: float = 0.0
var estres: float:
	get:
		if pj != null and "estres" in pj:
			return float(pj.get("estres"))
		return Partida.estres
	set(valor):
		var limitado: float = clampf(valor, 0.0, 100.0)
		if pj != null and "estres" in pj:
			pj.set("estres", limitado)
		else:
			Partida.estres = limitado


func _physics_process(delta: float) -> void:
	tiempo -= delta
	match estado:
		Estado.LISTA:
			if Input.is_action_just_pressed(tecla) and puede():
				empezar()
		Estado.ACTIVA:
			if tiempo <= 0.001:
				terminar()
		Estado.RECARGA:
			if tiempo <= 0.001:
				estado = Estado.LISTA


func puede() -> bool:
	return pj != null and pj.is_on_floor() and not pj.is_in_group("escondidos")


func empezar() -> void:
	estado = Estado.ACTIVA
	tiempo = duracion
	pj.empuje = -pj.basis.z * rapidez
	pj.multiplicador = 0.0
	pj.accion = animacion
	print("empieza: ", tecla)
	subir_estres()


func terminar() -> void:
	estado = Estado.RECARGA
	tiempo = recarga
	pj.empuje = Vector3.ZERO
	pj.multiplicador = 1.0
	pj.accion = ""
	print("termina: ", tecla)


func subir_estres() -> void:
	if pj != null and pj.has_method("sumar_estres"):
		pj.call("sumar_estres", estres_por_dash)
	else:
		estres = minf(100.0, estres + estres_por_dash)
	print("estrés: ", snappedf(estres, 0.1))
