extends CharacterBody3D

signal evento(posicion: Vector3)

enum Estado { EN_PUESTO, ACERCARSE, AVISO, GOLPE, RECARGA, BUSCAR, VOLVER }

@export var rapidez = 2.0
@export var rango_ataque = 1.5
@export var tiempo_aviso = 0.5
@export var tiempo_recarga = 1.0
@export var radio_ver = 5.0
@export var radio_perder = 8.0
@export var tiempo_buscar = 3.0

var estado = Estado.EN_PUESTO
var reloj = 0.0
var jugador = null
var puesto = Vector3.ZERO

@onready var anim = $Modelo/AnimationPlayer


func _enter_tree():
	add_to_group("disparadores")


func _ready():
	jugador = get_tree().get_first_node_in_group("jugador")
	puesto = global_position
	collision_mask |= 4


func _physics_process(delta):
	velocity += get_gravity() * delta
	reloj = maxf(reloj - delta, 0.0)

	var nuevo = decidir()
	if nuevo != estado:
		cambiar_a(nuevo)

	match estado:
		Estado.EN_PUESTO:
			frenar("idle")
		Estado.ACERCARSE:
			ir_a(jugador.global_position)
		Estado.AVISO:
			frenar("interact-right")
		Estado.GOLPE:
			frenar("attack-melee-right")
			golpear()
		Estado.RECARGA:
			frenar("idle")
		Estado.BUSCAR:
			frenar("idle")
		Estado.VOLVER:
			ir_a(puesto)

	move_and_slide()


func decidir():
	match estado:
		Estado.EN_PUESTO, Estado.BUSCAR, Estado.VOLVER:
			if la_ve(radio_ver):
				return Estado.ACERCARSE
			if estado == Estado.BUSCAR and reloj <= 0.001:
				return Estado.VOLVER
			if estado == Estado.VOLVER and distancia_a(puesto) < 0.15:
				return Estado.EN_PUESTO
		Estado.ACERCARSE:
			if not la_ve(radio_perder):
				return Estado.BUSCAR
			if distancia() <= rango_ataque:
				return Estado.AVISO
		Estado.AVISO:
			if reloj <= 0.001:
				return Estado.GOLPE
		Estado.GOLPE:
			return Estado.RECARGA
		Estado.RECARGA:
			if reloj <= 0.001:
				return Estado.ACERCARSE
	return estado


func cambiar_a(nuevo):
	var antes = estado
	estado = nuevo
	print(name, " -> ", Estado.keys()[estado], " cuadro ",
		Engine.get_physics_frames(), " a ",
		snappedf(distancia(), 0.01), " m")

	if estado == Estado.ACERCARSE and antes in [Estado.EN_PUESTO, Estado.BUSCAR, Estado.VOLVER]:
		evento.emit(global_position)
	elif estado == Estado.AVISO:
		reloj = tiempo_aviso
	elif estado == Estado.RECARGA:
		reloj = tiempo_recarga
	elif estado == Estado.BUSCAR:
		reloj = tiempo_buscar


func la_ve(radio):
	if jugador == null or jugador.is_in_group("escondidos") \
			or jugador.is_in_group("fuera_de_alcance"):
		return false
	return distancia() <= radio


func golpear():
	print(name, " golpea")


func ir_a(destino):
	var hacia = destino - global_position
	hacia.y = 0.0
	if hacia.length() < 0.05:
		frenar("idle")
		return
	var dir = hacia.normalized()
	velocity.x = dir.x * rapidez
	velocity.z = dir.z * rapidez
	basis = Basis.looking_at(dir)
	anim.play("walk")


func frenar(animacion):
	velocity.x = 0.0
	velocity.z = 0.0
	anim.play(animacion)


func distancia():
	return distancia_a(jugador.global_position)


func distancia_a(p):
	var o = global_position
	return Vector2(p.x - o.x, p.z - o.z).length()
