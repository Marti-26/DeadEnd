class_name Criatura
extends CriaturaBase

enum Estado { EN_PUESTO, ACERCARSE, AVISO, GOLPE, RECARGA, BUSCAR, VOLVER }

@export var rapidez_persecucion: float = 3.4
@export var angulo_vision: float = 60.0
@export var tiempo_detectar: float = 2.0

@export var rango_ataque: float = 1.5
@export var tiempo_aviso: float = 0.5
@export var tiempo_recarga: float = 1.0
@export var radio_ver: float = 10.0
@export var radio_perder: float = 14.0
@export var tiempo_buscar: float = 3.0

var tiempo_visto: float = 0.0
var estado: Estado = Estado.EN_PUESTO
var orientacion_inicial: Basis = Basis.IDENTITY

@onready var anim: AnimationPlayer = $Modelo/AnimationPlayer
@onready var sonido_criatura: AudioStreamPlayer3D = $Modelo/SonidoCriatura
@onready var exclamacion: Label3D = get_node_or_null("Exclamacion") as Label3D


func _ready() -> void:
	super._ready()
	orientacion_inicial = basis
	mostrar_alerta(false)


func _physics_process(delta: float) -> void:
	aplicar_gravedad(delta)
	reloj = maxf(reloj - delta, 0.0)

	if estado in [Estado.EN_PUESTO, Estado.BUSCAR, Estado.VOLVER]:
		if la_ve(radio_ver, true):
			tiempo_visto += delta
		else:
			tiempo_visto = 0.0

	var nuevo: Estado = decidir()
	if nuevo != estado:
		cambiar_a(nuevo)

	match estado:
		Estado.EN_PUESTO:
			frenar("idle")
		Estado.ACERCARSE:
			if jugador != null:
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

	if jugador != null:
		if jugador.get("audifonos_activos") == true:
			sonido_criatura.volume_linear = 0.0
		else:
			sonido_criatura.volume_linear = 1.0

	move_and_slide()


func decidir() -> Estado:
	match estado:
		Estado.EN_PUESTO, Estado.BUSCAR, Estado.VOLVER:
			if tiempo_visto >= tiempo_detectar:
				return Estado.ACERCARSE
			if estado == Estado.BUSCAR and reloj <= 0.001:
				return Estado.VOLVER
			if estado == Estado.VOLVER and distancia_a(puesto) < 0.15:
				return Estado.EN_PUESTO
		Estado.ACERCARSE:
			if not la_ve(radio_perder, false):
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


func cambiar_a(nuevo: Estado) -> void:
	var antes: Estado = estado
	estado = nuevo
	tiempo_visto = 0.0

	if estado in [Estado.EN_PUESTO, Estado.BUSCAR, Estado.VOLVER]:
		sonido_criatura.stop()

	print(name, " -> ", Estado.keys()[estado], " cuadro ",
		Engine.get_physics_frames(), " a ",
		snappedf(distancia(), 0.01), " m")

	if estado == Estado.ACERCARSE and antes in [Estado.EN_PUESTO, Estado.BUSCAR, Estado.VOLVER]:
		evento.emit(global_position)
		sonido_criatura.play()
		print("SONIDO REPRODUCIÉNDOSE: ", sonido_criatura.playing)
	elif estado == Estado.AVISO:
		reloj = tiempo_aviso
	elif estado == Estado.RECARGA:
		reloj = tiempo_recarga
	elif estado == Estado.BUSCAR:
		reloj = tiempo_buscar
	elif estado == Estado.EN_PUESTO:
		basis = orientacion_inicial

	mostrar_alerta(estado in [Estado.ACERCARSE, Estado.AVISO, Estado.GOLPE])


func mostrar_alerta(activa: bool) -> void:
	if exclamacion != null:
		exclamacion.visible = activa


func la_ve(radio: float, usar_angulo: bool = true) -> bool:
	if jugador == null:
		return false

	if jugador.is_in_group(Grupos.ESCONDIDOS) \
			or jugador.is_in_group(Grupos.FUERA_DE_ALCANCE):
		return false

	if distancia() > radio:
		return false

	if not usar_angulo:
		return true

	var hacia_jugador: Vector3 = jugador.global_position - global_position
	hacia_jugador.y = 0.0

	if hacia_jugador.length_squared() < 0.0001:
		return true

	hacia_jugador = hacia_jugador.normalized()

	var frente: Vector3 = -global_transform.basis.z
	frente.y = 0.0
	frente = frente.normalized()

	var angulo: float = rad_to_deg(
		acos(clampf(frente.dot(hacia_jugador), -1.0, 1.0))
	)

	return angulo <= (angulo_vision / 2.0)


func golpear() -> void:
	print(name, " golpea")
	if distancia() <= rango_ataque + 0.3:
		Partida.perder()


func ir_a(destino: Vector3) -> void:
	var hacia: Vector3 = destino - global_position
	hacia.y = 0.0
	if hacia.length() < 0.05:
		frenar("idle")
		return
	var dir: Vector3 = hacia.normalized()
	var velocidad_actual: float = rapidez_persecucion if estado == Estado.ACERCARSE else rapidez
	velocity.x = dir.x * velocidad_actual
	velocity.z = dir.z * velocidad_actual
	basis = Basis.looking_at(dir)
	anim.play("walk")


func frenar(animacion: String) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	anim.play(animacion)


func distancia() -> float:
	return distancia_al_jugador()
