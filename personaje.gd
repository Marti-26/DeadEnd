extends CharacterBody3D

#Tabla Enum
enum Estado { QUIETO, CAMINAR, SIGILO, AIRE, ESCONDERSE, DASH }
const RUIDO = [0.0, 3.0, 0.0, 0.0, 0.0, 8.0]

#@export var speed = 4.0
@export var camara: Camera3D
@export  var speed_caminar = 3.0
@export var speed_sigilo = 1.5
@export var speed_dash = 7.5
@export var tiempo_arranque = 0.25
#se agrega la variable para que la animacion del dash tenga tiempo y se vea en la ejecucion
var dash_tiempo = 0.0 

@export var gravedad = 9.8
@export var fuerza_salto = 6.0
@onready var anim = get_node_or_null("Modelo/AnimationPlayer")
@onready var sprite = get_node_or_null("Sprite")
var direccion = "frente"


# Enchufes: otros scripts (las acciones del juego) cambian estas tres variables.
var multiplicador = 1.0     # 1 = rapidez normal, 0.5 = la mitad, 0 = quieto
var empuje = Vector3.ZERO   # velocidad extra en m/s (dash, retroceso)
var accion = ""             # animación de la acción; "" = ninguna
var avance = Vector3.ZERO

# 
const ESCENA_HUD: PackedScene = preload("res://hud.tscn")
const TASA_BATERIA_REPOSO: float = 1.0 / 6.0
const TASA_BATERIA_LINTERNA: float = 1.0 / 4.0
const ESTRES_MAX: float = 100.0
const TASA_ESTRES_OSCURIDAD: float = 5.0
const TASA_ESTRES_CRIATURA: float = 3.0
const RADIO_ESTRES_CRIATURA: float = 5.0
const UMBRAL_ESTRES_VIBRACION: float = 70.0
const RADIO_JADEO: float = 10.0

signal jadeo(posicion: Vector3)

@export var linterna: Light3D

var linterna_encendida: bool = false
var _bateria: float = 100.0
var bateria: float = 100.0:
	get:
		return Partida.bateria if Partida.bateria >= 0.0 else _bateria
	set(valor):
		_bateria = clampf(valor, 0.0, 100.0)
		Partida.bateria = _bateria

var _estres: float = 0.0
var _jadeo_disparado: bool = false
var _camara_vibrando: bool = false
var _rng_vibracion: RandomNumberGenerator = RandomNumberGenerator.new()

var estres: float = 0.0:
	get:
		return clampf(Partida.estres, 0.0, ESTRES_MAX)
	set(valor):
		var previo: float = clampf(Partida.estres, 0.0, ESTRES_MAX)
		_estres = clampf(valor, 0.0, ESTRES_MAX)
		Partida.estres = _estres
		if _estres < ESTRES_MAX:
			_jadeo_disparado = false
		elif not _jadeo_disparado and previo < ESTRES_MAX:
			_disparar_jadeo()

var estado = Estado.QUIETO
var ruido = 0.0


func _enter_tree() -> void:
	if Partida.bateria < 0.0:
		Partida.bateria = _bateria
	Partida.estres = clampf(Partida.estres, 0.0, ESTRES_MAX)
	_estres = Partida.estres


func _ready() -> void:
	_rng_vibracion.randomize()
	_preparar_linterna()
	_asegurar_hud.call_deferred()


func _exit_tree() -> void:
	_detener_vibracion_camara()


func _process(delta: float) -> void:
	_consumir_bateria(delta)
	_actualizar_linterna()
	_actualizar_estres(delta)
	_actualizar_vibracion_camara()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var tecla: InputEventKey = event as InputEventKey
		if tecla.pressed and not tecla.echo and tecla.physical_keycode == KEY_F:
			alternar_linterna()


func alternar_linterna() -> void:
	if bateria <= 0.0:
		linterna_encendida = false
	else:
		linterna_encendida = not linterna_encendida
	_actualizar_linterna()


func _preparar_linterna() -> void:
	if linterna == null:
		linterna = get_node_or_null("Linterna") as Light3D
	if linterna == null:
		var foco: SpotLight3D = SpotLight3D.new()
		foco.name = "Linterna"
		foco.position = Vector3(0.0, 1.1, -0.2)
		foco.spot_range = 8.0
		foco.light_energy = 2.5
		add_child(foco)
		linterna = foco
	_actualizar_linterna()


func _consumir_bateria(delta: float) -> void:
	if bateria <= 0.0:
		return

	var tasa: float = TASA_BATERIA_LINTERNA if linterna_encendida else TASA_BATERIA_REPOSO
	bateria = maxf(0.0, bateria - tasa * delta)

	if bateria <= 0.0:
		bateria = 0.0
		linterna_encendida = false
		Partida.perder()


func _actualizar_linterna() -> void:
	if linterna != null:
		linterna.visible = linterna_encendida and bateria > 0.0


func _asegurar_hud() -> void:
	if get_tree() == null or get_tree().get_first_node_in_group("hud") != null:
		return
	var hud: Node = ESCENA_HUD.instantiate()
	var destino: Node = get_parent() if get_parent() != null else self
	destino.add_child(hud)


func sumar_estres(cantidad: float) -> void:
	estres = clampf(estres + cantidad, 0.0, ESTRES_MAX)


func _actualizar_estres(delta: float) -> void:
	if is_in_group("escondidos"):
		if estres < ESTRES_MAX:
			_jadeo_disparado = false
		return
	var delta_estres: float = 0.0
	if _esta_en_oscuridad_absoluta():
		delta_estres += TASA_ESTRES_OSCURIDAD
	var criaturas_cercanas: int = _contar_criaturas_cercanas()
	if criaturas_cercanas > 0:
		delta_estres += TASA_ESTRES_CRIATURA * float(criaturas_cercanas)
	if delta_estres > 0.0:
		sumar_estres(delta_estres * delta)
	elif estres < ESTRES_MAX:
		_jadeo_disparado = false
	elif not _jadeo_disparado:
		_disparar_jadeo()


func _esta_en_oscuridad_absoluta() -> bool:
	if linterna_encendida and bateria > 0.0:
		return false
	var arbol: SceneTree = get_tree()
	var raiz: Node = arbol.current_scene if arbol != null else get_parent()
	if raiz != null and _hay_luz_local_iluminando(raiz, global_position + Vector3(0.0, 0.9, 0.0)):
		return false
	return true


func _hay_luz_local_iluminando(nodo: Node, punto: Vector3) -> bool:
	if nodo is Light3D and not (nodo is DirectionalLight3D):
		if nodo != linterna and nodo.name != "LuzEstres" and nodo.name != "LuzEvento":
			var luz: Light3D = nodo as Light3D
			if luz.is_visible_in_tree() and luz.light_energy > 0.05:
				if luz is OmniLight3D:
					var omni: OmniLight3D = luz as OmniLight3D
					if punto.distance_to(omni.global_position) <= omni.omni_range * 0.75:
						return true
				elif luz is SpotLight3D:
					var foco: SpotLight3D = luz as SpotLight3D
					var hacia_punto: Vector3 = punto - foco.global_position
					var dist: float = hacia_punto.length()
					if dist <= foco.spot_range * 0.8:
						if dist < 0.05 or (-foco.global_basis.z).angle_to(hacia_punto / dist) <= deg_to_rad(foco.spot_angle):
							return true
	for hijo: Node in nodo.get_children():
		if _hay_luz_local_iluminando(hijo, punto):
			return true
	return false


func _obtener_criaturas() -> Array[Node3D]:
	var arbol: SceneTree = get_tree()
	if arbol == null:
		return []
	var resultado: Array[Node3D] = []
	for grupo: String in ["criaturas", "oyentes", "disparadores"]:
		for nodo: Node in arbol.get_nodes_in_group(grupo):
			if not (nodo is Node3D) or nodo == self:
				continue
			if grupo == "disparadores" and not (nodo is CharacterBody3D):
				continue
			var cuerpo: Node3D = nodo as Node3D
			if not resultado.has(cuerpo):
				resultado.append(cuerpo)
	return resultado


func _contar_criaturas_cercanas() -> int:
	var cercanas: int = 0
	for criatura: Node3D in _obtener_criaturas():
		if not criatura.is_visible_in_tree():
			continue
		if global_position.distance_to(criatura.global_position) < RADIO_ESTRES_CRIATURA:
			cercanas += 1
	return cercanas


func _obtener_camara_activa() -> Camera3D:
	if is_instance_valid(camara):
		return camara
	var viewport: Viewport = get_viewport()
	if viewport != null:
		return viewport.get_camera_3d()
	return null


func _actualizar_vibracion_camara() -> void:
	var cam: Camera3D = _obtener_camara_activa()
	if cam == null:
		return
	if estres > UMBRAL_ESTRES_VIBRACION:
		var factor: float = clampf((estres - UMBRAL_ESTRES_VIBRACION) / (ESTRES_MAX - UMBRAL_ESTRES_VIBRACION), 0.15, 1.0)
		var amplitud: float = lerpf(0.03, 0.10, factor)
		cam.h_offset = _rng_vibracion.randf_range(-amplitud, amplitud)
		cam.v_offset = _rng_vibracion.randf_range(-amplitud, amplitud)
		_camara_vibrando = true
	elif _camara_vibrando:
		_detener_vibracion_camara()


func _detener_vibracion_camara() -> void:
	if not _camara_vibrando:
		return
	var cam: Camera3D = _obtener_camara_activa()
	if cam != null:
		cam.h_offset = 0.0
		cam.v_offset = 0.0
	_camara_vibrando = false


func _disparar_jadeo() -> void:
	_jadeo_disparado = true
	print("jadeo: estrés al 100%, alerta en ", RADIO_JADEO, " u")
	var sonido_jadeo: AudioStreamPlayer = get_node_or_null("SonidoJadeo") as AudioStreamPlayer
	if sonido_jadeo != null:
		sonido_jadeo.play()
	jadeo.emit(global_position)
	if get_node_or_null("Ruido") == null:
		_alertar_npcs_cercanos(RADIO_JADEO)


func _alertar_npcs_cercanos(radio_alerta: float) -> void:
	for npc: Node3D in _obtener_criaturas():
		if global_position.distance_to(npc.global_position) <= radio_alerta and npc.has_method("oir"):
			npc.call("oir", global_position)

func _physics_process(delta):
	#para la resta del tiempo del dash 
	if dash_tiempo > 0.0:
		dash_tiempo -= delta

	velocity += get_gravity() * delta
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var entrada = Vector3(input_dir.x, 0.0, input_dir.y)
	
	# Girar la entrada solo en el eje Y de la cámara y normalizar
	var giro_cam = camara.global_rotation.y
	var direction = entrada.rotated(Vector3.UP, giro_cam).normalized()
	
	# Detectar si se presiona la tecla se sigilo
	var corre = Input.is_action_pressed("sigilo")
	var speed = speed_caminar
	if estado == Estado.DASH:
		speed = speed_dash
	elif corre:
		speed = speed_sigilo
	
	#N2 Cálculo de inercia con move_toward
	var objetivo = direction * speed * multiplicador
	var paso = speed / tiempo_arranque * delta
	avance = avance.move_toward(objetivo, paso)
	
	# Aplicar velocidad usando el avance y respetando enchufes (empuje)
	velocity.x = avance.x + empuje.x
	velocity.z = avance.z + empuje.z
	
	# Rotación hacia donde camina y animaciones
	if direction.length() > 0:
		basis = Basis.looking_at(direction)
		
	move_and_slide()
	#N3 Gestion de estados
	var antes = estado
	estado = elegir_estado()
	ruido = RUIDO[estado]
	if estado != antes:
		print("estado ", Estado.keys()[estado], " · ruido ", ruido, " m")
	animar()
	_prueba()

func elegir_estado():
	if not is_on_floor():
		return Estado.AIRE
	
	#Si esta activo el dash por el tiempo mantenerlo
	if dash_tiempo > 0.0:
		return Estado.DASH
		
	# 1. Dash con la barra espaciadora 
	if Input.is_action_just_pressed("dash"): 
		dash_tiempo = 0.8 #Duracion en segundos del dash
		return Estado.DASH
		
		
	# 3. Sigilo con la tecla Shift
	if Input.is_action_pressed("sigilo"):
		return Estado.SIGILO
		
	# 4. Rapidez normal o quieto
	var rapidez = Vector2(velocity.x, velocity.z).length()
	if rapidez < 0.1:
		return Estado.QUIETO
	if rapidez > speed_caminar + 0.1:
		return Estado.CAMINAR
	return Estado.CAMINAR
	
func animar():
	if sprite:
		animar_2d()
		return
	if accion != "":
		anim.play(accion)
		return
	match estado:
		Estado.QUIETO:
			anim.play("idle")
		Estado.CAMINAR:
			anim.play("walk")
		Estado.SIGILO:
			anim.play("crouch")
		Estado.AIRE:
			anim.play("fall")
		Estado.ESCONDERSE:
			anim.play("sit")
		Estado.DASH:
			anim.play("sprint")
			anim.speed_scale = 1.0

func animar_2d():
	var v = Vector2(velocity.x, velocity.z)
	var moviendo = v.length() > 0.1
	if moviendo:
		if absf(v.x) >= absf(v.y):
			direccion = "derecha" if v.x > 0.0 else "izquierda"
		else:
			direccion = "frente" if v.y > 0.0 else "espalda"
	match estado:
		Estado.CAMINAR:
			reproducir("caminar")
		Estado.DASH:
			reproducir("dash")
		Estado.SIGILO:
			reproducir("sigilo", 1.0 if moviendo else 0.0)
		Estado.AIRE:
			reproducir("caminar", 0.0)
		_:
			reproducir("idle")


func reproducir(accion_2d, velocidad = 1.0):
	if sprite == null:
		return
	var nombre = accion_2d + "_" + direccion
	if not sprite.sprite_frames.has_animation(nombre):
		nombre = "idle_" + direccion
	var repetir = sprite.sprite_frames.get_animation_loop(nombre)
	if sprite.animation != nombre or (repetir and not sprite.is_playing()):
		sprite.play(nombre)
	sprite.speed_scale = velocidad

#
@export_enum("Ninguna", "Avanzar 60 cuadros", "Avanzar 60 y soltar", "Avanzar y la acción desde el cuadro 30", "Mantener la acción 2 s", "Avanzar con la acción 60 cuadros", "Diagonal W+D 60 cuadros") var prueba = 0
@export var accion_prueba = ""
var _cuadro = 0
var _termino = false
var _y_max = 0.0
var _cuadro_max = 0


func _prueba():
	if prueba == 0 or _termino:
		return
	_cuadro += 1
	var avanzar = "move_right"
	var lado = "move_up"
	if _cuadro == 1:
		if prueba <= 3 or prueba == 5:
			_apretar(avanzar)
		if prueba == 4 or prueba == 5:
			_apretar(accion_prueba)
		if prueba == 6:
			_apretar(avanzar)
			_apretar(lado)
		return
	var n = _cuadro - 1
	if prueba == 3 and n == 30:
		_apretar(accion_prueba)
	if prueba == 2 and n == 60:
		Input.action_release(avanzar)
	var marcas = []
	if prueba == 1 or prueba == 5:
		marcas = [1, 2, 3, 5, 10, 15, 20, 30, 60]
	elif prueba == 2:
		marcas = [59, 60, 61, 62, 63, 65, 70, 80, 90]
	elif prueba == 3:
		marcas = [29, 30, 31, 32, 33, 35, 40, 45, 50, 60, 75, 90]
	elif prueba == 6:
		marcas = [1, 30, 60]
	else:
		marcas = [1, 15, 30, 45, 60, 75, 90, 105, 120, 135, 150]
	if n in marcas:
		print("[prueba] cuadro ", n, ": ", _resumen())
	_cambios(n)
	if global_position.y > _y_max + 0.0001:
		_y_max = global_position.y
		_cuadro_max = n
	if n == marcas[-1]:
		Input.action_release(avanzar)
		Input.action_release(lado)
		_soltar(accion_prueba)
		_termino = true
		if _y_max > 0.01:
			print("[prueba] altura máxima ", snappedf(_y_max, 0.01), " en el cuadro ", _cuadro_max)


func _resumen():
	var t = "posición " + str(global_position.snappedf(0.01))
	t += " · rapidez " + str(snappedf(absf(velocity.x), 0.01))
	t += " · y " + str(snappedf(global_position.y, 0.01))
	t += " · animación " + str(sprite.animation if sprite else anim.current_animation)
	for nodo in _con_estado():
		t += " · " + str(nodo.name) + ".estado " + _nombre(nodo)
	return t


# Escribe el cuadro exacto en el que cambia cualquier variable "estado".
var _antes = {}


func _cambios(n):
	for nodo in _con_estado():
		var e = _nombre(nodo)
		if _antes.has(nodo) and _antes[nodo] != e:
			print("[prueba] cuadro ", n, ": ", nodo.name, ".estado cambia a ", e)
		_antes[nodo] = e


func _con_estado():
	var lista = []
	for nodo in [self] + get_children() + get_tree().get_nodes_in_group("probar"):
		if nodo.get_script() != null and "estado" in nodo:
			lista.append(nodo)
	return lista


func _nombre(nodo):
	var nombres = nodo.get_script().get_script_constant_map().get("Estado", {})
	for k in nombres:
		if nombres[k] == nodo.estado:
			return k
	return str(nodo.estado)


func _apretar(a):
	if a == "":
		print("[prueba] escriban el nombre de la acción en 'Accion Prueba'")
	elif not InputMap.has_action(a):
		print("[prueba] falta la acción '", a, "' en el Input Map")
	else:
		Input.action_press(a)


func _soltar(a):
	if a != "" and InputMap.has_action(a):
		Input.action_release(a)
