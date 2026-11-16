
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
@export var balanceo_altura: float = 0.08
@export var balanceo_estiramiento: float = 0.035

var tiempo_visto: float = 0.0
var estado: Estado = Estado.EN_PUESTO
var orientacion_inicial: Basis = Basis.IDENTITY
var lado: String = "derecha"
var _sprite_y: float = 0.0
var _balanceo: float = 0.0
var _atascado: float = 0.0
var _ultima_distancia: float = INF

@onready var sprite: AnimatedSprite3D = $Sprite
@onready var sonido_criatura: AudioStreamPlayer3D = $SonidoCriatura
@onready var exclamacion: Label3D = get_node_or_null("Exclamacion") as Label3D


func _ready() -> void:
	super._ready()
	orientacion_inicial = basis
	if sprite != null:
		_sprite_y = sprite.position.y
	mostrar_alerta(false)
	print("CRIATURA.GD ACTIVO: ", name)


func _physics_process(delta: float) -> void:
	aplicar_gravedad(delta)
	reloj = maxf(reloj - delta, 0.0)

	# Detectar al jugador mientras está en estados de búsqueda.
	if estado in [Estado.EN_PUESTO, Estado.BUSCAR, Estado.VOLVER]:
		if la_ve(radio_ver, true):
			tiempo_visto += delta
		else:
			tiempo_visto = 0.0

	var nuevo: Estado = decidir()
	if nuevo != estado:
		cambiar_a(nuevo)

	# Ejecutar el comportamiento correspondiente al estado.
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
			_vigilar_atasco(delta)

	# Silenciar el sonido de la criatura con audífonos.
	if sonido_criatura != null:
		if jugador != null and jugador.get("audifonos_activos") == true:
			sonido_criatura.volume_linear = 0.0
		else:
			sonido_criatura.volume_linear = 1.0

	_balancear(delta)
	move_and_slide()


func decidir() -> Estado:
	match estado:
		Estado.EN_PUESTO, Estado.BUSCAR, Estado.VOLVER:
			if tiempo_visto >= tiempo_detectar:
				return Estado.ACERCARSE

			if estado == Estado.BUSCAR and reloj <= 0.001:
				return Estado.VOLVER

			if estado == Estado.VOLVER and (distancia_a(puesto) < 0.4 or _atascado > 1.0):
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
	_atascado = 0.0
	_ultima_distancia = INF
	tiempo_visto = 0.0

	# Detener el sonido cuando deja de perseguir.
	if estado in [Estado.EN_PUESTO, Estado.BUSCAR, Estado.VOLVER]:
		if sonido_criatura != null:
			sonido_criatura.stop()

	print(
		name,
		" -> ",
		Estado.keys()[estado],
		" cuadro ",
		Engine.get_physics_frames(),
		" a ",
		snappedf(distancia(), 0.01),
		" m"
	)

	# Reproducir el sonido cuando detecta al jugador.
	if estado == Estado.ACERCARSE and antes in [
		Estado.EN_PUESTO,
		Estado.BUSCAR,
		Estado.VOLVER
	]:
		evento.emit(global_position)

		if sonido_criatura != null:
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

	mostrar_alerta(
		estado in [Estado.ACERCARSE, Estado.AVISO, Estado.GOLPE]
	)


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
	print(name, " GOLPEA EN EL CUADRO: ", Engine.get_physics_frames())

	if distancia() <= rango_ataque + 0.3:
		Partida.perder()


func ir_a(destino: Vector3) -> void:
	var hacia: Vector3 = destino - global_position
	hacia.y = 0.0

	if hacia.length() < 0.05:
		frenar("idle")
		return

	var dir: Vector3 = hacia.normalized()

	var velocidad_actual: float = (
		rapidez_persecucion
		if estado == Estado.ACERCARSE
		else rapidez
	)

	velocity.x = dir.x * velocidad_actual
	velocity.z = dir.z * velocidad_actual

	basis = Basis.looking_at(dir)
	if absf(dir.x) > 0.15:
		lado = "derecha" if dir.x > 0.0 else "izquierda"
	animar("caminar_" + lado, velocidad_actual / maxf(rapidez, 0.1))


func frenar(animacion: String) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	animar(animacion, 1.0)


func animar(nombre: String, ritmo: float) -> void:
	if sprite == null:
		return
	if not sprite.sprite_frames.has_animation(nombre):
		nombre = "idle"
	if sprite.animation != nombre or not sprite.is_playing():
		sprite.play(nombre)
	sprite.speed_scale = ritmo


func distancia() -> float:
	return distancia_al_jugador()


func _balancear(delta: float) -> void:
	if sprite == null:
		return
	var caminando: bool = sprite.animation.begins_with("caminar")
	_balanceo = move_toward(_balanceo, 1.0 if caminando else 0.0, delta * 4.0)
	var cuadros: int = maxi(sprite.sprite_frames.get_frame_count(sprite.animation), 1)
	var fase: float = (float(sprite.frame) + sprite.frame_progress) / float(cuadros)
	var paso: float = 0.5 - 0.5 * cos(fase * TAU * 2.0)
	var estiro: float = (paso - 0.5) * 2.0 * balanceo_estiramiento * _balanceo
	sprite.scale = Vector3(1.0 - estiro * 0.6, 1.0 + estiro, 1.0)
	sprite.position.y = _sprite_y * (1.0 + estiro) + paso * balanceo_altura * _balanceo


func _vigilar_atasco(delta: float) -> void:
	var d: float = distancia_a(puesto)
	if _ultima_distancia - d < rapidez * delta * 0.25:
		_atascado += delta
	else:
		_atascado = 0.0
	_ultima_distancia = d
