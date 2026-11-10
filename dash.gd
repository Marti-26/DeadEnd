extends Node

enum Estado { LISTA, ACTIVA, RECARGA }

@export var tecla = "dash"
@export var duracion = 0.8
@export var recarga = 3.0
@export var rapidez = 7.5
@export var animacion = "sprint"
@export var estres_por_dash = 15.0
@export var estres_tras_jadeo = 70.0
@export var bajada_tras_jadeo = 2.0

@onready var pj = get_parent()

var estado = Estado.LISTA
var tiempo = 0.0
# El estrés vive en Partida (partida.gd) para que no vuelva a 0 al cambiar de escena.
var estres:
	get:
		return Partida.estres
	set(valor):
		Partida.estres = valor
var recuperando:
	get:
		return Partida.recuperando
	set(valor):
		Partida.recuperando = valor


func _physics_process(delta):
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
	if recuperando and estado != Estado.ACTIVA:
		estres = maxf(0.0, estres - bajada_tras_jadeo * delta)
		if estres <= 0.0:
			recuperando = false
			print("estrés de vuelta en 0")


func puede():
	return pj.is_on_floor()


func empezar():
	estado = Estado.ACTIVA
	tiempo = duracion
	pj.empuje = -pj.basis.z * rapidez
	pj.multiplicador = 0.0
	pj.accion = animacion
	print("empieza: ", tecla)
	subir_estres()


func terminar():
	estado = Estado.RECARGA
	tiempo = recarga
	pj.empuje = Vector3.ZERO
	pj.multiplicador = 1.0
	pj.accion = ""
	print("termina: ", tecla)


func subir_estres():
	estres = minf(100.0, estres + estres_por_dash)
	print("estrés: ", snappedf(estres, 0.1))
	if estres >= 100.0:
		print("jadeo: alerta en 10 u")
		estres = estres_tras_jadeo
		recuperando = true
		print("estrés después del jadeo: ", snappedf(estres, 0.1))
