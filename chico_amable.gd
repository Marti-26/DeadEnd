extends CharacterBody3D

enum Estado { QUIETO, ACERCARSE, HABLAR, AVISO, GOLPE, RECARGA, HUIR }

@export var tecla = "hablar"
@export var radio_notar = 7.0
@export var distancia_charla = 1.4
@export var alcance_hablar = 2.0
@export var quedarse_en_su_lugar = true
@export var rapidez = 1.6
@export var rapidez_alcanzar = 3.8
@export var distancia_alcanzar = 4.0
@export var rango_ataque = 2.0
@export var tiempo_aviso = 0.5
@export var tiempo_recarga = 1.0
@export var senalar: Node3D
@export var frases: Array[String] = [
	"¿También te perdiste? La estación de carga de allá todavía funciona.",
	"Aquí arriba no entran. Bueno... casi nunca.",
]
@export var nombre_dialogo = "CHICO"
@export var rebote_caminar: float = 0.05
@export var vaiven_caminar: float = 0.035
@export var tiempo_confundido: float = 1.8

var estado = Estado.QUIETO
var jugador = null
var puesto = Vector3.ZERO
var reloj = 0.0
var _caminando = false
var _siguiendo = false
var _tiempo_paso = 0.0
var agresivo = false
var huyendo = false
var _confundido: float = 0.0

@onready var sprite: AnimatedSprite3D = $Sprite
@onready var _sprite_y: float = $Sprite.position.y
@onready var salud = $Salud


func _ready():
	jugador = get_tree().get_first_node_in_group("jugador")
	puesto = global_position
	salud.vida_cambiada.connect(_al_cambiar_vida)
		
func _physics_process(delta):
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")
	velocity += get_gravity() * delta
	reloj = maxf(reloj - delta, 0.0)

	match estado:
		Estado.QUIETO:
			if agresivo:
				estado = Estado.ACERCARSE
				return
			if distancia() < radio_notar:
				if not _siguiendo:
					_confundido = tiempo_confundido
				_siguiendo = true
			if _siguiendo and distancia() > distancia_charla + 0.4:
				estado = Estado.ACERCARSE
			elif not _siguiendo and distancia_a(puesto) > 0.2:
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
				if distancia() <= distancia_charla:
					estado = Estado.QUIETO
					frenar("idle")
				else:
					ir_a(jugador.global_position)
		Estado.HABLAR:
			frenar("interact-right" if reloj > 2.5 else "idle")
			if not _dialogo().esta_visible():
				estado = Estado.QUIETO
		Estado.AVISO:
			frenar("idle")
			mirar(jugador.global_position)
			if reloj <= 0.001:
				estado = Estado.GOLPE
				print("Chico Amable -> GOLPE cuadro ", Engine.get_physics_frames())
				reloj = 0.45
		Estado.GOLPE:
			frenar("attack-melee-right")
			if reloj <= 0.001:
				if distancia() <= rango_ataque:
					print("Jugador detectado: ", jugador.get_path())
					var salud_jugador = jugador.get_node_or_null("Salud")
					if salud_jugador == null:
						print("ERROR: No se encontró el nodo Salud en Gatita")
					else:
						salud_jugador.recibir_dano(20.0)
						print("Vida ", salud_jugador.vida_actual, "en el golpe del cuadro ", Engine.get_physics_frames())
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
	if Input.is_action_just_pressed(tecla) and not agresivo and distancia() <= alcance_hablar and not _dialogo().esta_visible():
		interactuar()
	move_and_slide()



func interactuar():
	Partida.encuentros_chico += 1
	var n = Partida.encuentros_chico
	print("encuentro con el Chico: ", n)
	if n >= 3:
		Partida.encuentros_chico = 0
		_dialogo().ocultar()
		agresivo = true
		mirar(jugador.global_position)
		estado = Estado.AVISO
		print("Chico Amable -> AVISO cuadro ", Engine.get_physics_frames())
		reloj = tiempo_aviso
		return
	_dialogo().mostrar(nombre_dialogo, frases[mini(n - 1, frases.size() - 1)], 4.0, false, sprite.sprite_frames if sprite != null else null, animacion_charla())
	estado = Estado.HABLAR
	reloj = 4.0
	if n == 1 and senalar:
		mirar(senalar.global_position)
	else:
		mirar(jugador.global_position)


func ir_a(destino):
	if quedarse_en_su_lugar:
		frenar("idle")
		mirar(destino)
		return
	var hacia = destino - global_position
	hacia.y = 0.0
	if hacia.length() < 0.05:
		frenar("idle")
		return
	var dir = hacia.normalized()
	var velocidad = rapidez
	if not agresivo and estado == Estado.ACERCARSE:
		velocidad = lerpf(rapidez, rapidez_alcanzar, clampf((distancia() - distancia_charla) / distancia_alcanzar, 0.0, 1.0))
	velocity.x = dir.x * velocidad
	velocity.z = dir.z * velocidad
	basis = Basis.looking_at(dir)
	_caminando = true


func frenar(_animacion):
	velocity.x = 0.0
	velocity.z = 0.0
	_caminando = false


func _process(delta):
	if sprite == null:
		return
	_confundido = maxf(_confundido - delta, 0.0)
	var animacion: StringName = &"idle"
	if not agresivo and not huyendo:
		if estado == Estado.HABLAR:
			animacion = animacion_charla()
		elif _confundido > 0.0 and sprite.sprite_frames.has_animation(&"confundido"):
			animacion = &"confundido"
	if sprite.animation != animacion:
		sprite.play(animacion)
	if _caminando:
		_tiempo_paso += delta * maxf(Vector2(velocity.x, velocity.z).length(), rapidez) * 5.5
		sprite.position.y = _sprite_y + absf(sin(_tiempo_paso)) * rebote_caminar
		sprite.rotation.z = sin(_tiempo_paso) * vaiven_caminar
	else:
		_tiempo_paso = 0.0
		sprite.position.y = lerpf(sprite.position.y, _sprite_y, minf(delta * 10.0, 1.0))
		sprite.rotation.z = lerpf(sprite.rotation.z, 0.0, minf(delta * 10.0, 1.0))


func animacion_charla() -> StringName:
	if sprite != null and sprite.sprite_frames.has_animation(&"entusiasmado"):
		return &"entusiasmado"
	return &"idle"


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
		_dialogo().ocultar()
		print("Chico Amable comienza a huir. Vida: ", actual)
		print("Atacante vida ", actual, " y HUIR cuadro ",
			Engine.get_physics_frames(), " a ",
			snappedf(distancia(), 0.01), " m: se aleja")


func _dialogo():
	return Dialogo.obtener(get_tree())
