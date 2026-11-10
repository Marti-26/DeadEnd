extends CharacterBody3D

enum Estado { PATRULLA, PERSEGUIR }

@export var objetivo: Node3D
@export var rapidez_patrulla = 2.0
@export var rapidez_perseguir = 2.0
@export var radio_ver = 6.0
@export var radio_perder = 9.0
@export var puntos: Array[Vector3] = [Vector3(-6, 0, -3), Vector3(6, 0, -3)]
@onready var anim = $Modelo/AnimationPlayer

var estado = Estado.PATRULLA
var punto = 0

func _physics_process(delta):
	velocity += get_gravity() * delta
	var distancia = global_position.distance_to(objetivo.global_position)
	match estado:
		Estado.PATRULLA:
			if distancia < radio_ver and not objetivo.is_in_group("escondidos"):
				estado = Estado.PERSEGUIR
				print("lo vio a ", snappedf(distancia, 0.01), " m")
			ir_a(puntos[punto], rapidez_patrulla)
			if global_position.distance_to(puntos[punto]) < 0.3:
				punto = (punto + 1) % puntos.size()
		Estado.PERSEGUIR:
			if distancia > radio_perder or objetivo.is_in_group("escondidos"):
				estado = Estado.PATRULLA
				print("lo perdió a ", snappedf(distancia, 0.01), " m")
			ir_a(objetivo.global_position, rapidez_perseguir)
	move_and_slide()

func ir_a(p, v):
	var hacia = p - global_position
	hacia.y = 0.0
	if hacia.length() < 0.05:
		return
	var dir = hacia.normalized()
	velocity.x = dir.x * v
	velocity.z = dir.z * v
	basis = Basis.looking_at(dir)
	anim.play("walk")
