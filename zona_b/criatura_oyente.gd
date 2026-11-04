class_name CriaturaOyente
extends Node3D
## Tarea B · La mecánica real de la Estación 2: "una criatura oye un ruido".
## Patrulla despacio; si la jugadora hace ruido dentro de su radio de audición
## (caer de un salto, o cualquier ruido que llame a oir()), se alerta 5 s, va
## hacia el ruido y AVISA con la señal evento. No tiene ninguna luz.
## Vacío de B: radio de audición 6 m, patrulla 1.2 m/s (alerta 2.6 m/s).

signal evento(posicion: Vector3)        # 1) la señal

enum Estado { PATRULLA, ALERTA }

@export var jugador: CharacterBody3D
@export var radio_audicion := 6.0       # m
@export var velocidad_patrulla := 1.2   # m/s (la jugadora camina a 4)
@export var velocidad_alerta := 2.6     # m/s
@export var duracion_alerta := 5.0      # s
@export var limite_izq := 1.0           # x donde da la vuelta
@export var limite_der := 9.0

@export_group("Lo que se ve")
@export var ojos: Node3D                   # los ojos (mallas emisivas)
@export var contorno: ShaderMaterial       # el borde rojo (contorno.gdshader)
@export var anillo: GeometryInstance3D     # el anillo de audición en el piso
@export var exclamacion: Label3D

var estado := Estado.PATRULLA
var direccion := 1.0
var alerta_restante := 0.0
var objetivo_x := 0.0
var _jugador_en_piso := true
var _t := 0.0
var _mat_ojos: StandardMaterial3D
var _ojos: Array[Node] = []
var _mat_contorno: ShaderMaterial
var _mat_anillo: ShaderMaterial


func _enter_tree() -> void:
	add_to_group("disparadores")        # 2) el grupo que escucha la luz
	add_to_group("oyentes")


func _ready() -> void:
	# Materiales propios, para que cada criatura se pinte sola.
	if ojos:
		_ojos = ojos.find_children("*", "MeshInstance3D")
		if _ojos.size() > 0 and _ojos[0].material_override:
			_mat_ojos = _ojos[0].material_override.duplicate()
			for o in _ojos:
				o.material_override = _mat_ojos
	if contorno:
		_mat_contorno = contorno.duplicate()
		for m in find_children("*", "MeshInstance3D"):
			if not m in _ojos and m != anillo:
				m.material_overlay = _mat_contorno
	if anillo and anillo.material_override:
		_mat_anillo = anillo.material_override.duplicate()
		anillo.material_override = _mat_anillo
		_mat_anillo.set_shader_parameter("radio", radio_audicion)
	if exclamacion:
		exclamacion.visible = false
	_pintar(0.0)


func _physics_process(delta: float) -> void:
	_t += delta
	_escuchar_saltos()
	if estado == Estado.PATRULLA:
		position.x += direccion * velocidad_patrulla * delta
		if position.x > limite_der:
			direccion = -1.0
		elif position.x < limite_izq:
			direccion = 1.0
	else:
		alerta_restante -= delta
		var falta := objetivo_x - position.x
		if absf(falta) > 0.1:
			direccion = signf(falta)
			position.x += direccion * minf(absf(falta), velocidad_alerta * delta)
		if alerta_restante <= 0.0:
			estado = Estado.PATRULLA
	_pintar(delta)


## Cualquier ruido del juego llega aquí (por ejemplo, el dash de E3:
## get_tree().call_group("oyentes", "oir", posicion)).
func oir(posicion: Vector3) -> void:
	if global_position.distance_to(posicion) > radio_audicion:
		return
	var era_patrulla := estado == Estado.PATRULLA
	estado = Estado.ALERTA
	alerta_restante = duracion_alerta
	objetivo_x = clampf(posicion.x, limite_izq - 3.0, limite_der + 3.0)
	if era_patrulla:
		evento.emit(global_position)    # 3) el aviso: "pasó esto"


# Caer de un salto hace ruido.
func _escuchar_saltos() -> void:
	if jugador == null:
		return
	var en_piso := jugador.is_on_floor()
	if en_piso and not _jugador_en_piso:
		oir(jugador.global_position)
	_jugador_en_piso = en_piso


func _pintar(delta: float) -> void:
	var alerta := estado == Estado.ALERTA
	# Patrulla: ojos rojo apagado, se balancea lento. Alerta: rojo encendido,
	# tiembla, borde rojo vivo y anillo rojo. Así se distinguen a oscuras.
	var cuerpo := get_node_or_null("Cuerpo") as Node3D
	if cuerpo:
		var vaiven := sin(_t * (9.0 if alerta else 2.0)) * (0.06 if alerta else 0.03)
		cuerpo.rotation.z = vaiven
		cuerpo.scale.x = -1.0 if direccion < 0.0 else 1.0
	if _mat_ojos:
		_mat_ojos.emission_energy_multiplier = 9.0 if alerta else 1.6
		_mat_ojos.emission = Color(0.784, 0.243, 0.243) if alerta else Color(0.55, 0.16, 0.16)
	if ojos:
		ojos.scale = Vector3.ONE * (1.5 if alerta else 1.0)
	if _mat_contorno:
		_mat_contorno.set_shader_parameter("color",
			Color(0.9, 0.25, 0.25) if alerta else Color(0.32, 0.08, 0.1))
	if _mat_anillo:
		_mat_anillo.set_shader_parameter("color",
			Color(0.784, 0.243, 0.243) if alerta else Color(0.56, 0.85, 0.69))
		_mat_anillo.set_shader_parameter("fuerza", 0.9 if alerta else 0.35)
	if exclamacion:
		exclamacion.visible = alerta and alerta_restante > duracion_alerta - 1.2
