class_name CriaturaOido
extends CriaturaBase

enum Estado { EN_PUESTO, INVESTIGAR, MIRAR, VOLVER }

@export var tiempo_mirar: float = 5.0     # s, los 5 s de alerta del documento
# Se detiene antes del punto: ahí puede estar el jugador, y chocarían.
@export var llega_a: float = 1.0          # u
@export var radio_aviso: float = 5.0      # u, hasta dónde avisa a otras criaturas
@export var radio_audicion: float = 8.0   # u, lo máximo que oye: llega al dash en todas las estaciones
@export var tiempo_max_investigar: float = 8.0
@export var nombre_dialogo: String = "???"
@export var radio_hablar: float = 10.0
@export var pausa_hablar: Vector2 = Vector2(4.0, 7.0)
@export var duracion_frase: float = 3.0
@export var frases: Array[String] = [
	"Te escuché.",
	"¿Por qué corres?",
	"Sé que estás ahí.",
	"Tus pasos suenan bonito.",
	"Quédate quieta. Solo un momento.",
	"Ya casi te tengo.",
	"Respiras muy fuerte.",
	"No te voy a hacer nada.",
	"Escucho tu corazón.",
	"Ven. Aquí está más oscuro.",
	"Otra vez tú.",
	"Shhh. Ya te oí.",
	"Puedo esperar.",
	"Corre... corre.. gatita...",
]

var estado: Estado = Estado.EN_PUESTO
var _espera_hablar: float = 0.0
var _ultima_frase: int = -1
var ruido_en: Vector3 = Vector3.ZERO
# Sprites: idle y alerta van 1 2 3 2 en bucle (1 2 3 2 1 2 3...), sin saltos.
# Caminar tiene dos lados; el eje X del mundo es izquierda/derecha en pantalla.
@onready var sprite: AnimatedSprite3D = $Sprite
var lado: String = "derecha"
@onready var exclamacion: Node = get_node_or_null("Exclamacion")
@onready var sonido_alerta: AudioStreamPlayer3D = $Gruñido


func _ready() -> void:
	rapidez = 1.2
	super._ready()
	add_to_group(Grupos.OYENTES)
	mostrar_alerta()


func _physics_process(delta: float) -> void:
	aplicar_gravedad(delta)
	reloj = maxf(reloj - delta, 0.0)
	var nuevo = decidir()
	if nuevo != estado:
		cambiar_a(nuevo)
	match estado:
		Estado.EN_PUESTO:
			frenar()
		Estado.INVESTIGAR:
			ir_a(ruido_en)
		Estado.MIRAR:
			frenar()
		Estado.VOLVER:
			ir_a(puesto)
	move_and_slide()
	_hablar(delta)


func _hablar(delta: float) -> void:
	if estado != Estado.INVESTIGAR and estado != Estado.MIRAR:
		_espera_hablar = 0.0
		return
	_espera_hablar -= delta
	if _espera_hablar > 0.0 or frases.is_empty() or distancia_al_jugador() > radio_hablar:
		return
	var i: int = randi() % frases.size()
	if frases.size() > 1 and i == _ultima_frase:
		i = (i + 1) % frases.size()
	_ultima_frase = i
	Dialogo.obtener(get_tree()).mostrar(nombre_dialogo, frases[i], duracion_frase, true)
	_espera_hablar = randf_range(pausa_hablar.x, pausa_hablar.y)


func decidir():
	match estado:
		Estado.INVESTIGAR:
			if distancia_a(ruido_en) < llega_a or reloj <= 0.001:
				return Estado.MIRAR
		Estado.MIRAR:
			if reloj <= 0.001:
				return Estado.VOLVER
		Estado.VOLVER:
			if distancia_a(puesto) < 0.1:
				return Estado.EN_PUESTO
	return estado


func cambiar_a(nuevo):
	estado = nuevo
	print(name, " -> ", Estado.keys()[estado], " cuadro ",
		Engine.get_physics_frames(), " en ",
		global_position.snappedf(0.01))
	if estado == Estado.MIRAR:
		reloj = tiempo_mirar
	elif estado == Estado.INVESTIGAR:
		reloj = tiempo_max_investigar
	# Gruñido cuando Oído comienza a investigar
	if sonido_alerta != null:
		sonido_alerta.play()
	mostrar_alerta()


func mostrar_alerta():
	if exclamacion:
		exclamacion.visible = estado == Estado.INVESTIGAR or estado == Estado.MIRAR


# La llama quien hace el ruido (o una criatura vecina). Un ruido nuevo la
# interrumpe en cualquier estado.
func oir(punto):
	# Solo avisa quien estaba tranquilo: así la cadena termina.
	var estaba_en_puesto = estado == Estado.EN_PUESTO
	ruido_en = punto
	if estado != Estado.INVESTIGAR:
		cambiar_a(Estado.INVESTIGAR)
	if estaba_en_puesto:
		emitir_evento()
		avisar_a_vecinos(punto)


func avisar_a_vecinos(punto: Vector3) -> void:
	for n in get_tree().get_nodes_in_group(Grupos.OYENTES):
		if n == self:
			continue
		if global_position.distance_to(n.global_position) <= radio_aviso:
			print(name, " avisa a ", n.name)
			n.oir(punto)


func ir_a(destino):
	var hacia = destino - global_position
	hacia.y = 0.0
	if hacia.length() < 0.001:
		frenar()
		return
	var dir = hacia.normalized()
	velocity.x = dir.x * rapidez
	velocity.z = dir.z * rapidez
	# Si va casi recto hacia arriba/abajo, conserva el último lado.
	if absf(dir.x) > 0.05:
		lado = "izquierda" if dir.x < 0.0 else "derecha"
	animar("caminar_" + lado)


func frenar():
	velocity.x = 0.0
	velocity.z = 0.0
	# Quieta buscando al jugador -> alerta; en su puesto -> idle.
	animar("alerta" if estado == Estado.MIRAR else "idle")


# Usa la animación pedida si existe; si no, se queda en idle.
func animar(nombre):
	if not sprite.sprite_frames.has_animation(nombre):
		nombre = "idle"
	if sprite.animation != nombre or not sprite.is_playing():
		sprite.play(nombre)
