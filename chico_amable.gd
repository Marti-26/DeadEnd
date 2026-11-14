extends CharacterBody3D

enum Estado { QUIETO, ACERCARSE, HABLAR, AVISO, GOLPE, RECARGA, HUIR }

@export var tecla = "hablar"
@export var radio_notar = 4.5
@export var distancia_charla = 1.4
@export var alcance_hablar = 2.0
@export var rapidez = 1.6
@export var rango_ataque = 2.0
@export var tiempo_aviso = 0.5
@export var tiempo_recarga = 1.0
@export var senalar: Node3D
@export var frases: Array[String] = [
	"¿También te perdiste? La estación de carga de allá todavía funciona.",
	"Aquí arriba no entran. Bueno... casi nunca.",
]

var estado = Estado.QUIETO
var jugador = null
var puesto = Vector3.ZERO
var reloj = 0.0
var _ya_se_acerco = false
var agresivo = false
var huyendo = false

@onready var anim = $Modelo/AnimationPlayer
@onready var bocadillo = $Bocadillo
@onready var salud = $Salud


func _ready():
	jugador = get_tree().get_first_node_in_group("jugador")
	puesto = global_position
	bocadillo.visible = false
	salud.vida_cambiada.connect(_al_cambiar_vida)
		
func _physics_process(delta):
	velocity += get_gravity() * delta
	reloj = maxf(reloj - delta, 0.0)

	match estado:
		Estado.QUIETO:
			if agresivo:
				estado = Estado.ACERCARSE
				return
			if not _ya_se_acerco and distancia() < radio_notar and distancia() > distancia_charla:
				estado = Estado.ACERCARSE
			elif distancia_a(puesto) > 0.2 and distancia() >= radio_notar:
				ir_a(puesto)
			else:
				frenar("idle")
				if distancia() < radio_notar:
					mirar(jugador.global_position)
		Estado.ACERCARSE:
			if agresivo:
				if distancia() <= rango_ataque:
					estado = Estado.AVISO
					reloj = tiempo_aviso
					frenar("idle")
				else:
					ir_a(jugador.global_position)
			else:
				if distancia() <= distancia_charla or distancia() > radio_notar + 1.0:
					_ya_se_acerco = true
					estado = Estado.QUIETO
					frenar("idle")
				else:
					ir_a(jugador.global_position)
		Estado.HABLAR:
			frenar("interact-right" if reloj > 2.5 else "idle")
			if reloj <= 0.001:
				bocadillo.visible = false
				estado = Estado.QUIETO
		Estado.AVISO:
			frenar("idle")
			mirar(jugador.global_position)
			if reloj <= 0.001:
				estado = Estado.GOLPE
				reloj = 0.45
		Estado.GOLPE:
			frenar("attack-melee-right")
			if reloj <= 0.001:
				if distancia() <= rango_ataque:
					print("Jugador detectado: ", jugador.get_path())
					var salud = jugador.get_node_or_null("Salud")
					if salud == null:
						print("ERROR: No se encontró el nodo Salud en Gatita")
					else:
						salud.recibir_dano(20.0)
						print("Golpe acertado. Vida restante: ", salud.vida_actual)
				else:
					print("Golpe fallido: jugador fuera del alcance")
				estado = Estado.RECARGA
				reloj = tiempo_recarga
		Estado.RECARGA:
			frenar("idle")
			if reloj <= 0.001:
				estado = Estado.ACERCARSE
		Estado.HUIR:
			if jugador != null:
				var direccion_huida = global_position - jugador.global_position
				direccion_huida.y = 0.0
				if direccion_huida.length() > 0.05:
					ir_a(global_position + direccion_huida.normalized() * 3.0)
				else:
					frenar("idle")
			else:
				frenar("idle")
	if Input.is_action_just_pressed(tecla) and not agresivo and distancia() <= alcance_hablar:
		interactuar()
	move_and_slide()



func interactuar():
	Partida.encuentros_chico += 1
	var n = Partida.encuentros_chico
	print("encuentro con el Chico: ", n)
	if n >= 3:
		Partida.encuentros_chico = 0
		bocadillo.visible = false
		agresivo = true
		mirar(jugador.global_position)
		estado = Estado.AVISO
		reloj = tiempo_aviso
		return
	bocadillo.text = frases[mini(n - 1, frases.size() - 1)]
	bocadillo.visible = true
	estado = Estado.HABLAR
	reloj = 4.0
	if n == 1 and senalar:
		mirar(senalar.global_position)
	else:
		mirar(jugador.global_position)


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


func mirar(p):
	var hacia = p - global_position
	hacia.y = 0.0
	if hacia.length() > 0.05:
		basis = Basis.looking_at(hacia.normalized())


func distancia():
	if jugador == null:
		return INF
	return distancia_a(jugador.global_position)


func distancia_a(p):
	var o = global_position
	return Vector2(p.x - o.x, p.z - o.z).length()
	
func _al_cambiar_vida(actual: float, maxima: float) -> void:
	if actual <= maxima * 0.30 and not huyendo:
		huyendo = true
		agresivo = false
		estado = Estado.HUIR
		bocadillo.visible = false
		print("Chico Amable comienza a huir. Vida: ", actual)
		
