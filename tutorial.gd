extends Node

@export_file("*.tscn") var escena_juego: String = "res://zona_b.tscn"
@export var color_luz: Color = Color(0.45, 0.88, 0.8)
@export var color_luz_oscuro: Color = Color(0.3, 0.62, 0.78)
@export var brillo_luces: float = 1.6
@export var posicion_chico: Vector3 = Vector3(2.1, 0.0, -2.3)
@export var ampliacion: float = 20.0
@export var limites_camara: Vector2 = Vector2(-30.2, 0.2)
@export var fin_pasillo: float = 10.0
@export var inicio_jugador: Vector3 = Vector3(-37.0, 0.05, 1.0)
@export var tiempo_saltar: float = 1.0
@export var pausa_entre_pasos: float = 2.5
@export var ancho_notificacion: float = 620.0
@export_range(0.0, 1.0) var factor_estres: float = 0.35
@export var tiempo_interaccion: float = 1.5
@export var x_punto_activacion: float = -6.0
@export var posicion_cartel: Vector3 = Vector3(-18.6, 2.0, -3.68)

const FUENTE: FontFile = preload("res://assets/font/ShareTechMono-Regular.ttf")

const PASOS: Array[Dictionary] = [
	{"id": "mover", "pista": true, "texto": "Muévete con W A S D o con las flechas del teclado."},
	{"id": "celular", "pista": true, "texto": "Eso que brilla en amarillo es un celular.\nAcércate y presiona E para recogerlo."},
	{"id": "linterna", "texto": "Aquí abajo casi no se ve.\nPresiona F para prender la linterna."},
	{"id": "mapa", "desde_x": -31.5, "texto": "Presiona M para abrir el mapa y ver dónde estás.\nPresiona M otra vez para cerrarlo."},
	{"id": "carga", "desde_x": -30.0, "texto": "Te queda poca batería.\nVe a la estación de carga que señala la flecha y mantén E. La barra te muestra cuánto falta."},
	{"id": "audifonos", "desde_x": -26.0, "texto": "Presiona Q para ponerte los audífonos. Te calman, pero dejas de oír lo que pasa alrededor.\nPóntelos y vuelve a presionar Q para quitártelos."},
	{"id": "estres", "importante": true, "texto": "La barra roja de arriba es tu estrés: sube en la oscuridad y cerca de las criaturas.\nSi llega a 100 perderás y reaparecerás en el último punto de guardado. Para bajarlo: audífonos, esconderte o una zona segura."},
	{"id": "sigilo", "desde_x": -24.5, "texto": "Mantén SHIFT mientras caminas para ir en sigilo: vas más lento, pero no haces ruido.\n"},
	{"id": "dash", "desde_x": -23.5, "texto": "Presiona ESPACIO para hacer un dash: es rápido, pero hace mucho ruido.\n"},
	{"id": "cartel", "desde_x": -21.5, "texto": "¿Ves el cartel que señala la flecha? Puedes hacer clic sobre los carteles para leerlos.\nÁbrelo con un clic y ciérralo haciendo clic afuera."},
	{"id": "terminal", "desde_x": -12.0, "texto": "Esa pantalla es un punto de activación. Mantén E para activarlo.\nActívalos todos para que el metro te deje avanzar."},
	{"id": "chico", "desde_x": -6.0, "texto": "Hay alguien más adelante.\nAcércate y presiona R para hablar con él."},
	{"id": "esconderse", "desde_x": -2.0, "texto": "Haz lo que te dijo: escóndete bajo la banca que señala la flecha.\nSolo camina hacia ella y entrarás sola. Para salir, solo debes caminar"},
	{"id": "salida", "desde_x": 1.5, "texto": "Eso es todo.\nSube por la escalera del fondo, desde aqui estas por tú cuenta."},
]

const FRASES_CHICO: Array[String] = [
	"Tranquila, no muerdo. Llevo un buen rato aquí abajo y eres la primera que no sale corriendo.",
	"Mira, no te voy a mentir: no estamos solos. Hay cosas...raras... caminando en este lugar.",
	"Algunas te ven. Si te descubren, te siguen. Métete bajo una banca y quédate quieta hasta que se vayan.",
	"Otras no ven nada, pero lo oyen todo. Con esas, camina en sigilo y olvídate de correr si quieres que no te escuchen.",
	"Si se te acelera el corazón, ponte los audífonos un rato. Eso sí, no te descuides.",
	"Y busca los puntos de activación. Actívalos todos y el metro te llevara a tu siguiente parada. continua, nos volveremos a ver.",
]
const FRASES_CHICO_REPETIDAS: Array[String] = [
	"Ya te dije lo importante. Los puntos no se van a activar solos.",
	"Cuídate, ¿sí? Sería una pena que alguien más te encontrara primero.",
	"Qué suerte que fui yo quien te encontró...",
]
const ESCENA_CHICO: PackedScene = preload("res://chico_amable.tscn")
const DESFASE_COPIA: float = 40.0
const AMARILLO: Color = Color(1.0, 0.84, 0.2)
const POSTER_PARED: Script = preload("res://poster_pared.gd")
const SEPARACION_GUIA: float = 1.1
const SHADER_GUIA: String = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 color : source_color = vec4(1.0, 0.84, 0.2, 1.0);
uniform float alfa = 0.0;
void fragment() {
	vec2 p = UV - 0.5;
	float v = p.x + abs(p.y) - 0.12;
	float banda = 1.0 - smoothstep(0.06, 0.09, abs(v));
	float caja = step(abs(p.y), 0.36) * step(abs(p.x), 0.46);
	ALBEDO = color.rgb;
	ALPHA = banda * caja * alfa;
}
"""
const TEXTURA_CARTEL: String = "res://assets/npcs y posters/poster_atrapada.png"

var _jugador: Personaje = null
var _paso: int = 0
var _inicio: Vector3 = Vector3.ZERO
var _contador: float = 0.0
var _bandera: bool = false
var _terminado: bool = false
var _terminal: Node = null
var _mapa: CelularMapa = null

var _capa: CanvasLayer = null
var _pista: Label = null
var _tarjeta: PanelContainer = null
var _titulo: Label = null
var _texto: Label = null
var _progreso: Label = null
var _tween: Tween = null
var _camara: Camera3D = null
var _destellos: Array = []
var _destello_terminal: Node3D = null
var _chico: Node3D = null
var _charla: int = -1
var _charla_hecha: bool = false
var _charla_espera: float = 0.0
var _repeticion: int = 0
var _resaltado: Node3D = null
var _resaltado_objetivo: Node3D = null
var _resaltado_alto: float = 1.0
var _resaltado_tiempo: float = 0.0
var _boton_mapa: Control = null
var _banca: Node3D = null
var _raiz: Control = null
var _estilo: StyleBoxFlat = null
var _esperando: bool = false
var _espera: float = 0.0
var _marcadores: Array[Dictionary] = []
var _cartel: Node3D = null
var _interactuar: Interactuar = null
var _estres_previo: float = -1.0
var _teclas: Control = null
var _teclas_estilos: Dictionary = {}
var _carga_caja: PanelContainer = null
var _carga_barra: ProgressBar = null
var _carga_texto: Label = null
var _hud: Node = null
var _aviso_bloqueo: float = 0.0
var _guias: Array[Dictionary] = []
var _guia_tiempo: float = 0.0
var _barrera_escalera: StaticBody3D = null


func _ready() -> void:
	set_process(false)
	if not Partida.has_meta("tutorial_previo"):
		Partida.set_meta("tutorial_previo", {
			"t1": Partida.terminal_1_activada,
			"t2": Partida.terminal_2_activada,
			"guardado": Partida.guardado.duplicate(true),
			"estacion": Partida.estacion_usada,
		})
	_paso = int(Partida.get_meta("paso_tutorial", 0))
	_construir_interfaz()
	var escena: Node = get_parent()
	var velo: ColorRect = ColorRect.new()
	velo.color = Color.BLACK
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var capa_velo: CanvasLayer = CanvasLayer.new()
	capa_velo.layer = 50
	add_child(capa_velo)
	capa_velo.add_child(velo)
	await get_tree().process_frame
	_ampliar_pasillo(escena)
	_acortar_pasillo(escena)
	_tenir_luces(escena)
	_atenuar_maquinas(escena)
	_tomar_camara(escena)
	_jugador = get_tree().get_first_node_in_group(Grupos.JUGADOR) as Personaje
	if _jugador != null:
		if _paso >= 2 and not _jugador.tiene_celular:
			_paso = 1
		if Partida.llegada == "":
			var salida: Vector3 = inicio_jugador
			if _paso < PASOS.size() and PASOS[_paso].has("desde_x"):
				salida.x = maxf(inicio_jugador.x, float(PASOS[_paso]["desde_x"]) - 1.5)
			_jugador.global_position = salida
			_jugador.velocity = Vector3.ZERO
		_inicio = _jugador.global_position
		_mover_camara(0.0, true)
		for hijo: Node in _jugador.get_children():
			if hijo is Interactuar:
				_interactuar = hijo as Interactuar
				_interactuar.tiempo_necesario = tiempo_interaccion
	_estres_previo = Partida.estres
	_terminal = escena.get_node_or_null("Estacion/Puntoactivación1")
	if _terminal is Node3D:
		(_terminal as Node3D).global_position.x = x_punto_activacion
	var subida: Area3D = escena.get_node_or_null("Escalera/SubidaSegundoPiso") as Area3D
	if subida != null:
		subida.body_entered.connect(_al_llegar_salida)
	_decorar(escena)
	_crear_estacion_carga(escena)
	_crear_chico(escena)
	_banca = escena.get_node_or_null("Estacion/Banca2") as Node3D
	_crear_cartel(escena)
	_crear_marcadores(escena)
	_crear_guias(escena)
	_crear_entrada_escalera(escena)
	var celular: Node3D = escena.get_node_or_null("Celular") as Node3D
	if celular != null:
		_poner_destellos(celular, Vector3(0.0, 0.05, 0.0), 0.18)
	if _terminal != null:
		_poner_destellos(_terminal as Node3D, Vector3(0.0, 0.0, 0.15), 0.9)
		_destello_terminal = _destellos.back()
	_esperando = true
	_espera = 0.6
	set_process(true)
	var fundido: Tween = create_tween()
	fundido.tween_property(velo, "color:a", 0.0, 0.5)
	fundido.tween_callback(capa_velo.queue_free)


func _process(delta: float) -> void:
	if _terminado:
		return
	if _jugador == null or not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group(Grupos.JUGADOR) as Personaje
		return
	_mover_camara(delta)
	_atender_chico(delta)
	var tapada: bool = _charla >= 0 or Dialogo.obtener(get_tree()).esta_visible()
	_raiz.modulate.a = move_toward(_raiz.modulate.a, 0.0 if tapada else 1.0, delta * 5.0)
	_animar_resaltado(delta)
	_animar_marcadores(delta)
	_guiar(delta)
	_regular_estres()
	_mostrar_carga()
	_animar_teclas()
	_resaltar_barras()
	if _aviso_bloqueo > 0.0:
		_aviso_bloqueo -= delta
		if _aviso_bloqueo <= 0.0 and _paso < PASOS.size() and not bool(PASOS[_paso].get("pista", false)):
			var t_pista: Tween = create_tween()
			t_pista.tween_property(_pista, "modulate:a", 0.0, 0.3)
	if _destello_terminal != null and _terminal != null and bool(_terminal.get("activada")):
		_destello_terminal.visible = false
		_destello_terminal = null
	if _esperando:
		_espera -= delta
		if _espera <= 0.0 and _paso < PASOS.size() and _jugador.global_position.x >= float(PASOS[_paso].get("desde_x", -1000.0)):
			_esperando = false
			_mostrar_paso()
		return
	if _paso < PASOS.size() and _cumplido(delta):
		_avanzar()


func _cumplido(delta: float) -> bool:
	match str(PASOS[_paso]["id"]):
		"mover":
			return _jugador.global_position.distance_to(_inicio) > 1.5
		"celular":
			return _jugador.tiene_celular
		"linterna":
			return _jugador.linterna_encendida
		"audifonos":
			if _jugador.audifonos_activos:
				_bandera = true
			return _bandera and not _jugador.audifonos_activos
		"mapa":
			if _mapa == null:
				_mapa = get_tree().get_first_node_in_group(&"mapa_celular") as CelularMapa
			if _mapa == null:
				return false
			if _mapa.abierto:
				_bandera = true
			return _bandera and not _mapa.abierto
		"estres":
			_contador += delta
			return _contador >= 7.0
		"sigilo":
			if Input.is_action_pressed("sigilo") and _jugador.velocity.length() > 0.3:
				_contador += delta
			return _contador >= 1.2
		"dash":
			return Input.is_action_just_pressed("dash")
		"terminal":
			return _terminal == null or bool(_terminal.get("activada"))
		"carga":
			return _jugador.bateria >= 90.0
		"esconderse":
			if _jugador.is_in_group(Grupos.ESCONDIDOS):
				_contador += delta
			return _contador >= 1.5
		"chico":
			return _charla_hecha
		"cartel":
			if _cartel == null:
				return true
			if _cartel.get("_capa") != null:
				_bandera = true
			return _bandera and _cartel.get("_capa") == null
	return false


func _avanzar() -> void:
	_contador = 0.0
	_bandera = false
	_paso += 1
	Partida.set_meta("paso_tutorial", _paso)
	if _paso < PASOS.size() and str(PASOS[_paso]["id"]) == "carga" and _jugador != null:
		_jugador.bateria = minf(_jugador.bateria, 15.0)
	_marcar_listo()


func _al_llegar_salida(cuerpo: Node3D) -> void:
	if not cuerpo.is_in_group(Grupos.JUGADOR):
		return
	if _paso >= PASOS.size() - 1:
		_terminar()
		return
	_pista.text = "Todavía no puedes subir.\nTermina primero lo que te falta del tutorial."
	_pista.modulate.a = 1.0
	_aviso_bloqueo = 3.0


func _terminar() -> void:
	if _terminado:
		return
	_terminado = true
	var previo: Dictionary = Partida.get_meta("tutorial_previo", {})
	if _jugador != null and is_instance_valid(_jugador):
		Partida.guardar_estado_personaje(_jugador)
	Partida.terminal_1_activada = bool(previo.get("t1", false))
	Partida.terminal_2_activada = bool(previo.get("t2", false))
	Partida.guardado = (previo.get("guardado", {}) as Dictionary).duplicate(true)
	Partida.estacion_usada = bool(previo.get("estacion", false))
	Partida.celular_recogido = true
	Partida.estres = 0.0
	Partida.remove_meta("tutorial_previo")
	Partida.remove_meta("paso_tutorial")
	Partida.cambiar_escena(escena_juego)


func _construir_interfaz() -> void:
	_capa = CanvasLayer.new()
	_capa.layer = 4
	add_child(_capa)
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa.add_child(_raiz)
	_pista = Label.new()
	_pista.add_theme_font_override("font", FUENTE)
	_pista.add_theme_font_size_override("font_size", 26)
	_pista.add_theme_color_override("font_color", Color(0.78, 0.96, 0.92))
	_pista.add_theme_color_override("font_outline_color", Color(0.08, 0.03, 0.0, 0.9))
	_pista.add_theme_constant_override("outline_size", 8)
	_pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pista.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_pista.offset_left = -420.0
	_pista.offset_right = 420.0
	_pista.offset_top = -240.0
	_pista.offset_bottom = -200.0
	_pista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pista.modulate.a = 0.0
	_raiz.add_child(_pista)

	_tarjeta = PanelContainer.new()
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = Color(0.984, 0.945, 0.902, 0.96)
	estilo.border_color = Color(0.847, 0.263, 0.435)
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(14)
	estilo.content_margin_left = 16.0
	estilo.content_margin_right = 16.0
	estilo.content_margin_top = 10.0
	estilo.content_margin_bottom = 12.0
	estilo.shadow_color = Color(0.25, 0.02, 0.1, 0.35)
	estilo.shadow_size = 10
	estilo.shadow_offset = Vector2(4.0, 6.0)
	_tarjeta.add_theme_stylebox_override("panel", estilo)
	_estilo = estilo
	_tarjeta.custom_minimum_size = Vector2(ancho_notificacion, 0.0)
	_tarjeta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tarjeta.visible = false
	_raiz.add_child(_tarjeta)
	var columna: VBoxContainer = VBoxContainer.new()
	columna.add_theme_constant_override("separation", 4)
	_tarjeta.add_child(columna)
	var fila: HBoxContainer = HBoxContainer.new()
	columna.add_child(fila)
	_titulo = _etiqueta(18, Color(0.847, 0.263, 0.435))
	_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(_titulo)
	_progreso = _etiqueta(16, Color(0.933, 0.498, 0.639))
	fila.add_child(_progreso)
	_texto = _etiqueta(23, Color(0.42, 0.08, 0.2))
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.custom_minimum_size = Vector2(ancho_notificacion - 40.0, 0.0)
	columna.add_child(_texto)

	_crear_teclas()
	_crear_barra_carga()


func _etiqueta(tamano: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.add_theme_font_override("font", FUENTE)
	l.add_theme_font_size_override("font_size", tamano)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _mostrar_paso() -> void:
	if _paso >= PASOS.size():
		_pista.modulate.a = 0.0
		_tarjeta.visible = false
		return
	var paso: Dictionary = PASOS[_paso]
	_resaltar_paso(str(paso["id"]))
	if _tween != null:
		_tween.kill()
	if bool(paso.get("pista", false)):
		_tarjeta.visible = false
		_pista.text = str(paso["texto"])
		_tween = create_tween()
		_tween.tween_property(_pista, "modulate:a", 1.0, 0.4)
		return
	_pista.modulate.a = 0.0
	var importante: bool = bool(paso.get("importante", false))
	_titulo.text = "IMPORTANTE · ???" if importante else "MENSAJE NUEVO · ???"
	var acento: Color = Color(0.85, 0.08, 0.1) if importante else Color(0.847, 0.263, 0.435)
	_estilo.border_color = acento
	_estilo.bg_color = Color(1.0, 0.9, 0.86, 0.97) if importante else Color(0.984, 0.945, 0.902, 0.96)
	_titulo.add_theme_color_override("font_color", acento)
	_texto.add_theme_color_override("font_color", Color(0.55, 0.02, 0.04) if importante else Color(0.42, 0.08, 0.2))
	_progreso.text = "%d/%d" % [_paso - 1, PASOS.size() - 2]
	_texto.text = str(paso["texto"])
	_tarjeta.visible = true
	_tarjeta.reset_size()
	var pantalla: Vector2 = _capa.get_viewport().get_visible_rect().size
	var ancho: float = minf(ancho_notificacion, pantalla.x - 40.0)
	_tarjeta.size.x = ancho
	var x: float = (pantalla.x - ancho) * 0.5
	_tarjeta.position = Vector2(x, pantalla.y + 20.0)
	_tarjeta.modulate.a = 1.0
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_tarjeta, "position", Vector2(x, pantalla.y - _tarjeta.size.y - 28.0), 0.45)
	var sonido: AudioStreamPlayer = _jugador.get_node_or_null("Celular") as AudioStreamPlayer if _jugador != null else null
	if sonido != null and sonido.stream != null:
		sonido.play()


func _marcar_listo() -> void:
	_resaltar(null, 0.0)
	if _tween != null:
		_tween.kill()
	_esperando = true
	_espera = pausa_entre_pasos
	if _paso < PASOS.size() and str(PASOS[_paso]["id"]) == "celular":
		_espera = 0.1
	if _tarjeta.visible:
		_titulo.text = "LISTO"
		var abajo: float = _capa.get_viewport().get_visible_rect().size.y + 20.0
		_tween = create_tween()
		_tween.tween_interval(0.7)
		_tween.tween_property(_tarjeta, "position:y", abajo, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_tween.tween_callback(func() -> void: _tarjeta.visible = false)
	else:
		_tween = create_tween()
		_tween.tween_property(_pista, "modulate:a", 0.0, 0.25)


func _tenir_luces(escena: Node) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 11
	for n: Node in escena.find_children("*", "Light3D", true, false):
		var luz: Light3D = n as Light3D
		if luz.name.begins_with("LuzAura") or _bajo_cuerpo(luz) or _dentro_de(luz, "Metro"):
			continue
		var tono: Color = color_luz.lerp(color_luz_oscuro, rng.randf_range(0.0, 0.45))
		luz.light_color = tono
		if not luz is DirectionalLight3D:
			luz.light_energy *= brillo_luces
			if luz.get("energia_base") != null:
				luz.set("energia_base", float(luz.get("energia_base")) * brillo_luces)
		var tubo: StandardMaterial3D = luz.get("_mat_tubo") as StandardMaterial3D
		if tubo != null:
			tubo.emission = tono
			tubo.albedo_color = tono.lightened(0.3)
		var cono: ShaderMaterial = luz.get("_mat_cono") as ShaderMaterial
		if cono != null:
			cono.set_shader_parameter("color", Color(tono.r, tono.g, tono.b, 1.0))
	for n: Node in escena.find_children("*", "WorldEnvironment", true, false):
		var mundo: WorldEnvironment = n as WorldEnvironment
		if mundo.environment == null:
			continue
		var entorno: Environment = mundo.environment.duplicate() as Environment
		entorno.ambient_light_color = Color(0.16, 0.3, 0.32)
		entorno.ambient_light_energy = maxf(entorno.ambient_light_energy, 0.7)
		entorno.fog_light_color = Color(0.06, 0.14, 0.15)
		mundo.environment = entorno


func _bajo_cuerpo(n: Node) -> bool:
	var p: Node = n.get_parent()
	while p != null:
		if p is CharacterBody3D:
			return true
		p = p.get_parent()
	return false


func _dentro_de(n: Node, nombre: String) -> bool:
	var p: Node = n.get_parent()
	while p != null:
		if p.name == nombre:
			return true
		p = p.get_parent()
	return false


func _material_rayas() -> ShaderMaterial:
	var s: Shader = Shader.new()
	s.code = """
shader_type spatial;
uniform vec4 a : source_color = vec4(0.82, 0.86, 0.84, 1.0);
uniform vec4 b : source_color = vec4(0.06, 0.05, 0.05, 1.0);
void fragment() {
	float r = step(0.5, fract((UV.x * 6.0 + UV.y * 2.0)));
	ALBEDO = mix(b.rgb, a.rgb, r);
	ROUGHNESS = 0.8;
}
"""
	var m: ShaderMaterial = ShaderMaterial.new()
	m.shader = s
	return m


func _decorar(escena: Node) -> void:
	var raiz: Node3D = Node3D.new()
	raiz.name = "DecoradoTutorial"
	escena.add_child(raiz)
	var rayas: ShaderMaterial = _material_rayas()
	for x: float in [-38.6, -20.5, 9.2]:
		_caballete(raiz, Vector3(x, 0.0, 2.6), rayas)
	var naranja: StandardMaterial3D = StandardMaterial3D.new()
	naranja.albedo_color = Color(0.85, 0.3, 0.1)
	var blanco: StandardMaterial3D = StandardMaterial3D.new()
	blanco.albedo_color = Color(0.92, 0.9, 0.85)
	for p: Vector3 in [Vector3(-35.0, 0.0, 2.9), Vector3(-21.5, 0.0, 2.8), Vector3(-1.4, 0.0, -2.6)]:
		_cono(raiz, p, naranja, blanco)
	_cartel_destellos(raiz, Vector3(-37.0, 2.0, -3.66))
	_letrero(raiz, Vector3(-22.0, 2.35, -3.66), "TÚNEL DE SERVICIO 3", 0.0)
	_letrero(raiz, Vector3(3.2, 2.35, -3.66), "SOLO PERSONAL AUTORIZADO", 0.0)
	var x: float = -35.0
	while x < fin_pasillo - 4.0:
		var flecha: Label3D = Label3D.new()
		flecha.text = ">>"
		flecha.font = FUENTE
		flecha.font_size = 128
		flecha.pixel_size = 0.006
		flecha.modulate = Color(0.7, 0.95, 0.9, 0.4)
		flecha.shaded = true
		flecha.alpha_cut = Label3D.ALPHA_CUT_DISCARD
		flecha.double_sided = false
		raiz.add_child(flecha)
		flecha.position = Vector3(x, 0.012, 1.6)
		flecha.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
		x += 7.0


func _caballete(padre: Node3D, pos: Vector3, rayas: ShaderMaterial) -> void:
	var nodo: Node3D = Node3D.new()
	padre.add_child(nodo)
	nodo.position = pos
	var tabla: MeshInstance3D = MeshInstance3D.new()
	var caja: BoxMesh = BoxMesh.new()
	caja.size = Vector3(1.3, 0.22, 0.05)
	tabla.mesh = caja
	tabla.material_override = rayas
	tabla.position = Vector3(0.0, 0.85, 0.0)
	nodo.add_child(tabla)
	var gris: StandardMaterial3D = StandardMaterial3D.new()
	gris.albedo_color = Color(0.18, 0.17, 0.16)
	for lado: float in [-0.55, 0.55]:
		var pata: MeshInstance3D = MeshInstance3D.new()
		var p: BoxMesh = BoxMesh.new()
		p.size = Vector3(0.06, 0.95, 0.06)
		pata.mesh = p
		pata.material_override = gris
		pata.position = Vector3(lado, 0.47, 0.0)
		nodo.add_child(pata)


func _cono(padre: Node3D, pos: Vector3, naranja: StandardMaterial3D, blanco: StandardMaterial3D) -> void:
	var cono: MeshInstance3D = MeshInstance3D.new()
	var cil: CylinderMesh = CylinderMesh.new()
	cil.top_radius = 0.025
	cil.bottom_radius = 0.17
	cil.height = 0.5
	cil.radial_segments = 12
	cono.mesh = cil
	cono.material_override = naranja
	padre.add_child(cono)
	cono.position = pos + Vector3(0.0, 0.25, 0.0)
	var banda: MeshInstance3D = MeshInstance3D.new()
	var b: CylinderMesh = CylinderMesh.new()
	b.top_radius = 0.075
	b.bottom_radius = 0.095
	b.height = 0.08
	b.radial_segments = 12
	banda.mesh = b
	banda.material_override = blanco
	cono.add_child(banda)
	banda.position = Vector3(0.0, 0.04, 0.0)


func _letrero(padre: Node3D, pos: Vector3, texto: String, giro: float) -> void:
	var nodo: Node3D = Node3D.new()
	padre.add_child(nodo)
	nodo.position = pos
	nodo.rotation.y = giro
	var fondo: MeshInstance3D = MeshInstance3D.new()
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.24 * float(texto.length()) * 0.55 + 0.4, 0.42)
	fondo.mesh = quad
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.8, 0.78)
	mat.emission_enabled = true
	mat.emission = Color(0.45, 0.75, 0.7)
	mat.emission_energy_multiplier = 0.25
	fondo.material_override = mat
	nodo.add_child(fondo)
	var etiqueta: Label3D = Label3D.new()
	etiqueta.text = texto
	etiqueta.font = FUENTE
	etiqueta.font_size = 64
	etiqueta.pixel_size = 0.0042
	etiqueta.modulate = Color(0.04, 0.07, 0.08)
	etiqueta.outline_size = 0
	etiqueta.shaded = true
	etiqueta.position = Vector3(0.0, 0.0, 0.01)
	nodo.add_child(etiqueta)


func _cartel_destellos(padre: Node3D, pos: Vector3) -> void:
	var nodo: Node3D = Node3D.new()
	nodo.name = "CartelDestellos"
	padre.add_child(nodo)
	nodo.position = pos
	var marco: MeshInstance3D = MeshInstance3D.new()
	var caja: BoxMesh = BoxMesh.new()
	caja.size = Vector3(4.0, 1.0, 0.05)
	marco.mesh = caja
	var oscuro: StandardMaterial3D = StandardMaterial3D.new()
	oscuro.albedo_color = Color(0.03, 0.04, 0.05)
	marco.material_override = oscuro
	nodo.add_child(marco)
	var etiqueta: Label3D = Label3D.new()
	etiqueta.text = "FÍJATE EN EL AMARILLO:\nSI ALGO BRILLA,\nPUEDES INTERACTUAR CON ESTO"
	etiqueta.font = FUENTE
	etiqueta.font_size = 52
	etiqueta.pixel_size = 0.0042
	etiqueta.line_spacing = 4.0
	etiqueta.modulate = AMARILLO
	etiqueta.outline_size = 0
	etiqueta.shaded = false
	etiqueta.position = Vector3(0.0, 0.0, 0.03)
	nodo.add_child(etiqueta)
	_poner_destellos(nodo, Vector3(0.0, 0.0, 0.05), 1.8)


func _crear_estacion_carga(escena: Node) -> void:
	var plantilla: Node = load("res://segundo_piso.tscn").instantiate()
	var estacion: Node3D = plantilla.get_node_or_null("EstacionCarga") as Node3D
	if estacion == null:
		plantilla.free()
		return
	plantilla.remove_child(estacion)
	plantilla.free()
	estacion.name = "EstacionCargaPractica"
	escena.add_child(estacion)
	estacion.global_position = Vector3(-28.0, 0.0, -3.6)
	estacion.global_rotation = Vector3.ZERO
	_poner_destellos(estacion, Vector3(0.0, 1.0, 0.35), 0.8)


func _poner_destellos(padre: Node3D, desfase: Vector3, radio: float) -> void:
	var chispas: CPUParticles3D = CPUParticles3D.new()
	chispas.name = "DestellosAmbar"
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	var punto: QuadMesh = QuadMesh.new()
	punto.size = Vector2(0.05, 0.05)
	punto.material = mat
	chispas.mesh = punto
	chispas.amount = 8
	chispas.lifetime = 1.6
	chispas.randomness = 0.6
	chispas.local_coords = true
	chispas.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE_SURFACE
	chispas.emission_sphere_radius = radio
	chispas.direction = Vector3.UP
	chispas.spread = 30.0
	chispas.gravity = Vector3.ZERO
	chispas.initial_velocity_min = 0.03
	chispas.initial_velocity_max = 0.1
	var curva: Curve = Curve.new()
	curva.add_point(Vector2(0.0, 0.0))
	curva.add_point(Vector2(0.35, 1.0))
	curva.add_point(Vector2(1.0, 0.0))
	chispas.scale_amount_curve = curva
	var rampa: Gradient = Gradient.new()
	rampa.set_color(0, Color(1.0, 0.72, 0.25, 0.0))
	rampa.set_color(1, Color(1.0, 0.72, 0.25, 0.0))
	rampa.add_point(0.35, Color(1.0, 0.75, 0.3, 0.95))
	chispas.color_ramp = rampa
	chispas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(chispas)
	chispas.position = desfase
	_destellos.append(chispas)


func _ampliar_pasillo(escena: Node) -> void:
	var estacion: Node3D = escena.get_node_or_null("Estacion") as Node3D
	if estacion == null:
		return
	var borde: float = 20.0 - ampliacion + 0.5
	var continuas: Array[String] = ["FranjaTactil", "MuroFondo", "Borde", "MuroBarrera", "Balasto", "Durmientes", "PostesBarrera", "RielA5", "RielB5", "RielA8", "RielB8", "Pared", "Zocalo", "Cornisa", "Travesano", "LimiteIzq"]
	var copia: Node3D = estacion.duplicate() as Node3D
	copia.name = "EstacionExtra"
	copia.position.x -= DESFASE_COPIA
	for n: Node in copia.get_children():
		var quitar: bool = str(n.name) in ["ParedDer", "ZocaloDer", "CornisaDer", "TravesanoDer", "LimiteDer", "Puntoactivación1"]
		if not quitar and n is Node3D and not str(n.name) in continuas:
			quitar = (n as Node3D).position.x < borde
		if quitar:
			copia.remove_child(n)
			n.free()
	var centro: float = 20.0 - ampliacion * 0.5
	for nombre: String in ["Pared", "Zocalo", "Cornisa", "Travesano"]:
		var pieza: Node3D = copia.get_node_or_null(nombre) as Node3D
		if pieza != null:
			pieza.position.x = centro
			pieza.scale.x = ampliacion / 36.25
	var limite_copia: Node3D = copia.get_node_or_null("LimiteIzq") as Node3D
	if limite_copia != null:
		limite_copia.position.x = 19.8 - ampliacion
	var muro: Node = copia.get_node_or_null("MuroFondo")
	if muro != null:
		var der: Node = muro.get_node_or_null("FormaDer")
		if der != null:
			muro.remove_child(der)
			der.free()
		var forma: CollisionShape3D = muro.get_node_or_null("Forma") as CollisionShape3D
		if forma != null and forma.shape is BoxShape3D:
			var caja: BoxShape3D = (forma.shape as BoxShape3D).duplicate() as BoxShape3D
			caja.size.x = ampliacion
			forma.shape = caja
			forma.position.x = centro
	escena.add_child(copia)
	var limite: Node = estacion.get_node_or_null("LimiteIzq")
	if limite != null:
		limite.queue_free()
	var tubos: Node3D = escena.get_node_or_null("Tubos") as Node3D
	if tubos != null:
		var doble: Node3D = tubos.duplicate() as Node3D
		doble.name = "TubosExtra"
		doble.position.x -= DESFASE_COPIA
		for n: Node in doble.get_children():
			if n is Node3D and (n as Node3D).position.x < borde:
				doble.remove_child(n)
				n.free()
		for luz: Node in doble.find_children("*", "LuzParpadeante", true, false):
			var padre: Node = luz.get_parent()
			luz.set("tubo", padre.get_node_or_null("Tubo"))
			luz.set("cono", padre.get_node_or_null("Cono"))
		escena.add_child(doble)


func _acortar_pasillo(escena: Node) -> void:
	var dx: float = fin_pasillo - 20.0
	if absf(dx) < 0.01:
		return
	var corte: float = fin_pasillo - 4.0
	var ancho: float = 36.25 + dx
	var centro: float = -20.0 + ancho * 0.5
	var continuas: Array[String] = ["FranjaTactil", "Borde", "MuroBarrera", "Balasto", "Durmientes", "PostesBarrera", "RielA5", "RielB5", "RielA8", "RielB8", "LimiteIzq"]
	var estacion: Node3D = escena.get_node_or_null("Estacion") as Node3D
	if estacion != null:
		for n: Node in estacion.get_children():
			if not n is Node3D:
				continue
			var pieza: Node3D = n as Node3D
			var nombre: String = str(pieza.name)
			if nombre in ["ParedDer", "ZocaloDer", "CornisaDer", "TravesanoDer", "LimiteDer"]:
				pieza.position.x += dx
			elif nombre in ["Pared", "Zocalo", "Cornisa", "Travesano"]:
				pieza.position.x = centro
				pieza.scale.x = ancho / 36.25
			elif nombre == "MuroFondo":
				var forma: CollisionShape3D = pieza.get_node_or_null("Forma") as CollisionShape3D
				if forma != null and forma.shape is BoxShape3D:
					var caja: BoxShape3D = (forma.shape as BoxShape3D).duplicate() as BoxShape3D
					caja.size.x = ancho
					forma.shape = caja
					forma.position.x = centro
				var der: Node3D = pieza.get_node_or_null("FormaDer") as Node3D
				if der != null:
					der.position.x += dx
			elif nombre in continuas:
				continue
			elif nombre.begins_with("Piso"):
				if pieza.position.x - 2.5 >= fin_pasillo - 0.01:
					pieza.queue_free()
			elif pieza.position.x > corte:
				pieza.queue_free()
	for ruta: String in ["Escalera", "MurosEnemigos/Escalera", "AcentosCalidos/SenalDer"]:
		var mover: Node3D = escena.get_node_or_null(ruta) as Node3D
		if mover != null:
			mover.position.x += dx
	for grupo: String in ["Tubos", "AcentosCalidos"]:
		var padre: Node = escena.get_node_or_null(grupo)
		if padre == null:
			continue
		for n: Node in padre.get_children():
			if n is Node3D and str(n.name) != "SenalDer" and (n as Node3D).position.x > corte:
				n.queue_free()


func _tomar_camara(escena: Node) -> void:
	_camara = escena.get_node_or_null("Camara") as Camera3D
	if _camara != null:
		_camara.set_process(false)


func _mover_camara(delta: float, al_instante: bool = false) -> void:
	if _camara == null or not is_instance_valid(_camara):
		return
	var p: Vector3 = _jugador.global_position
	var limite_z: Vector2 = _camara.get("limite_z") if _camara.get("limite_z") != null else Vector2(-1.2, 3.7)
	var desfase: Vector3 = _camara.get("desfase") if _camara.get("desfase") != null else Vector3(0.0, 14.141, 15.253)
	var suave: float = float(_camara.get("suavizado")) if _camara.get("suavizado") != null else 4.0
	var meta: Vector3 = Vector3(clampf(p.x, limites_camara.x, limites_camara.y), 0.0, clampf(p.z, limite_z.x, limite_z.y)) + desfase
	if al_instante:
		_camara.global_position = meta
	else:
		_camara.global_position = _camara.global_position.lerp(meta, 1.0 - exp(-suave * delta))


func _crear_chico(escena: Node) -> void:
	_chico = ESCENA_CHICO.instantiate() as Node3D
	_chico.name = "ChicoTutorial"
	_chico.set("alcance_hablar", -1.0)
	_chico.set("quedarse_en_su_lugar", true)
	_chico.set("radio_notar", 6.0)
	escena.add_child(_chico)
	_chico.global_position = posicion_chico
	_poner_destellos(_chico, Vector3(0.0, 1.0, 0.0), 0.7)


func _atender_chico(delta: float) -> void:
	if _chico == null or not is_instance_valid(_chico):
		return
	var dialogo = Dialogo.obtener(get_tree())
	if _charla >= 0:
		if dialogo.esta_visible():
			_charla_espera = 0.0
			return
		_charla_espera += delta
		if _charla_espera < 0.2:
			return
		_charla += 1
		if _charla < FRASES_CHICO.size():
			_decir_chico(FRASES_CHICO[_charla])
		else:
			_charla = -1
			_charla_hecha = true
		return
	if not Input.is_action_just_pressed("hablar") or dialogo.esta_visible():
		return
	var d: Vector3 = _chico.global_position - _jugador.global_position
	if Vector2(d.x, d.z).length() > 2.4:
		return
	if _charla_hecha:
		_decir_chico(FRASES_CHICO_REPETIDAS[_repeticion % FRASES_CHICO_REPETIDAS.size()])
		_repeticion += 1
		return
	_charla = 0
	_charla_espera = 0.0
	_decir_chico(FRASES_CHICO[0])


func _decir_chico(frase: String) -> void:
	var sprite: AnimatedSprite3D = _chico.get_node_or_null("Sprite") as AnimatedSprite3D
	var animacion: StringName = &"idle"
	if _chico.has_method("animacion_charla") and _charla >= 0 and (_charla == 0 or _charla == FRASES_CHICO.size() - 1):
		animacion = _chico.call("animacion_charla")
	_chico.set("animacion_hablando", animacion)
	Dialogo.obtener(get_tree()).mostrar(str(_chico.get("nombre_dialogo")), frase, 4.0, false, sprite.sprite_frames if sprite != null else null, animacion)
	_chico.set("estado", 2)
	if _chico.has_method("mirar"):
		_chico.call("mirar", _jugador.global_position)


func _resaltar_paso(id: String) -> void:
	var escena: Node = get_parent()
	match id:
		"celular":
			_resaltar(escena.get_node_or_null("Celular") as Node3D, 0.9)
		"carga":
			_resaltar(escena.get_node_or_null("EstacionCargaPractica") as Node3D, 2.6)
		"chico":
			_resaltar(_chico, 3.8)
		"esconderse":
			_resaltar(_banca, 1.6)
		"cartel":
			_resaltar(_cartel, 1.1)
		"terminal":
			_resaltar(_terminal as Node3D, 1.2)
		"mapa":
			_resaltar(null, 0.0)
		_:
			_resaltar(null, 0.0)


func _resaltar(objetivo: Node3D, alto: float) -> void:
	if _boton_mapa != null and is_instance_valid(_boton_mapa):
		_boton_mapa.modulate = Color.WHITE
	_boton_mapa = null
	_resaltado_objetivo = objetivo
	_resaltado_alto = alto
	if objetivo == null:
		if _resaltado != null:
			_resaltado.visible = false
		return
	if _resaltado == null:
		_resaltado = Node3D.new()
		_resaltado.name = "Resaltado"
		get_parent().add_child(_resaltado)
		var flecha: MeshInstance3D = MeshInstance3D.new()
		flecha.name = "Flecha"
		var prisma: PrismMesh = PrismMesh.new()
		prisma.size = Vector3(0.62, 0.62, 0.14)
		flecha.mesh = prisma
		flecha.rotation.z = PI
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = AMARILLO
		flecha.material_override = mat
		flecha.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_resaltado.add_child(flecha)
		var luz: OmniLight3D = OmniLight3D.new()
		luz.name = "LuzAura_Resaltado"
		luz.light_color = AMARILLO
		luz.light_energy = 1.8
		luz.omni_range = 2.8
		luz.shadow_enabled = false
		_resaltado.add_child(luz)
	_resaltado.visible = true
	_resaltado_tiempo = 0.0
	_animar_resaltado(0.0)


func _animar_resaltado(delta: float) -> void:
	if _boton_mapa != null and is_instance_valid(_boton_mapa):
		_resaltado_tiempo += delta
		_boton_mapa.modulate = Color.WHITE.lerp(Color(1.5, 1.25, 0.35), 0.5 + 0.5 * sin(_resaltado_tiempo * 5.0))
		return
	if _resaltado == null or not _resaltado.visible:
		return
	if _resaltado_objetivo == null or not is_instance_valid(_resaltado_objetivo):
		_resaltado.visible = false
		return
	_resaltado_tiempo += delta
	var base: Vector3 = _resaltado_objetivo.global_position
	_resaltado.global_position = Vector3(base.x, base.y, maxf(base.z, -3.2))
	var flecha: Node3D = _resaltado.get_node("Flecha") as Node3D
	flecha.position = Vector3(0.0, _resaltado_alto + 0.25 + 0.16 * sin(_resaltado_tiempo * 4.0), 0.3)
	var luz: OmniLight3D = _resaltado.get_node("LuzAura_Resaltado") as OmniLight3D
	luz.position = Vector3(0.0, minf(_resaltado_alto * 0.5, 1.2), 0.6)
	luz.light_energy = 1.2 + 0.4 * sin(_resaltado_tiempo * 3.0)


func _buscar_boton_mapa(n: Node) -> Control:
	if n is Button and (n as Button).tooltip_text.begins_with("Mapa"):
		return n as Control
	for h: Node in n.get_children():
		var b: Control = _buscar_boton_mapa(h)
		if b != null:
			return b
	return null


func _crear_cartel(escena: Node) -> void:
	var textura: Texture2D = load(TEXTURA_CARTEL) as Texture2D
	if textura == null:
		return
	_cartel = POSTER_PARED.new() as Node3D
	_cartel.name = "CartelTutorial"
	_cartel.set("alto", 1.35)
	_cartel.set("textura", textura)
	escena.add_child(_cartel)
	_cartel.global_position = posicion_cartel


func _crear_marcadores(escena: Node) -> void:
	var lista: Array[Array] = [
		[escena.get_node_or_null("Celular"), 0.9],
		[escena.get_node_or_null("EstacionCargaPractica"), 2.6],
		[_terminal, 1.2],
		[_chico, 3.8],
		[_cartel, 1.1],
	]
	for banca: Node in get_tree().get_nodes_in_group(Grupos.ESCONDITES):
		if banca is Node3D and escena.is_ancestor_of(banca):
			lista.append([banca, 1.6])
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(AMARILLO.r, AMARILLO.g, AMARILLO.b, 0.75)
	var prisma: PrismMesh = PrismMesh.new()
	prisma.size = Vector3(0.36, 0.36, 0.08)
	var raiz: Node3D = Node3D.new()
	raiz.name = "Marcadores"
	escena.add_child(raiz)
	for par: Array in lista:
		var objetivo: Node3D = par[0] as Node3D
		if objetivo == null:
			continue
		var flecha: MeshInstance3D = MeshInstance3D.new()
		flecha.mesh = prisma
		flecha.material_override = mat
		flecha.rotation.z = PI
		flecha.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(flecha)
		_marcadores.append({"flecha": flecha, "objetivo": objetivo, "alto": float(par[1]), "fase": randf() * TAU})


func _animar_marcadores(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() * 0.001
	for m: Dictionary in _marcadores:
		var flecha: MeshInstance3D = m["flecha"] as MeshInstance3D
		var objetivo = m["objetivo"]
		if not is_instance_valid(objetivo):
			flecha.visible = false
			continue
		var nodo: Node3D = objetivo as Node3D
		var oculto: bool = nodo == _resaltado_objetivo and _resaltado != null and _resaltado.visible
		if nodo == _terminal and bool(nodo.get("activada")):
			oculto = true
		flecha.visible = not oculto
		var base: Vector3 = nodo.global_position
		flecha.global_position = Vector3(base.x, base.y + float(m["alto"]) + 0.1 * sin(t * 3.0 + float(m["fase"])), maxf(base.z, -3.2) + 0.3)


func _atenuar_maquinas(escena: Node) -> void:
	for maquina: Node in escena.find_children("Expendedora*", "Node3D", true, false):
		for n: Node in maquina.find_children("*", "GeometryInstance3D", true, false):
			var geo: GeometryInstance3D = n as GeometryInstance3D
			var original: Material = geo.material_override
			if original == null and geo is MeshInstance3D and (geo as MeshInstance3D).mesh != null and (geo as MeshInstance3D).mesh.get_surface_count() > 0:
				original = (geo as MeshInstance3D).get_active_material(0)
			if not original is BaseMaterial3D:
				continue
			var mat: BaseMaterial3D = original.duplicate() as BaseMaterial3D
			var c: Color = mat.albedo_color
			var gris: float = c.r * 0.3 + c.g * 0.59 + c.b * 0.11
			mat.albedo_color = Color(gris, gris, gris, c.a).lerp(c, 0.4).darkened(0.25)
			if mat.emission_enabled:
				mat.emission_energy_multiplier *= 0.3
				var e: Color = mat.emission
				var ge: float = e.r * 0.3 + e.g * 0.59 + e.b * 0.11
				mat.emission = Color(ge, ge, ge).lerp(e, 0.4)
			geo.material_override = mat
		for n: Node in maquina.find_children("*", "Light3D", true, false):
			(n as Light3D).light_energy *= 0.4


func _regular_estres() -> void:
	var actual: float = Partida.estres
	if _estres_previo >= 0.0 and actual > _estres_previo and actual < 99.9:
		actual = _estres_previo + (actual - _estres_previo) * factor_estres
		Partida.estres = actual
	_estres_previo = actual


func _crear_teclas() -> void:
	_teclas = Control.new()
	_teclas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_teclas.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_teclas.offset_left = -230.0
	_teclas.offset_right = 230.0
	_teclas.offset_top = -370.0
	_teclas.offset_bottom = -250.0
	_teclas.modulate.a = 0.0
	_raiz.add_child(_teclas)
	var tam: float = 52.0
	var hueco: float = 6.0
	var grupos: Array[Array] = [
		[0.0, [["W", KEY_W, 1, 0], ["A", KEY_A, 0, 1], ["S", KEY_S, 1, 1], ["D", KEY_D, 2, 1]]],
		[270.0, [["^", KEY_UP, 1, 0], ["<", KEY_LEFT, 0, 1], ["v", KEY_DOWN, 1, 1], [">", KEY_RIGHT, 2, 1]]],
	]
	for grupo: Array in grupos:
		var x0: float = float(grupo[0])
		for tecla: Array in grupo[1]:
			var caja: Panel = Panel.new()
			caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var estilo: StyleBoxFlat = StyleBoxFlat.new()
			estilo.bg_color = Color(0.984, 0.945, 0.902, 0.92)
			estilo.border_color = Color(0.847, 0.263, 0.435)
			estilo.set_border_width_all(2)
			estilo.border_width_bottom = 5
			estilo.set_corner_radius_all(8)
			caja.add_theme_stylebox_override("panel", estilo)
			caja.size = Vector2(tam, tam)
			caja.position = Vector2(x0 + float(tecla[2]) * (tam + hueco), float(tecla[3]) * (tam + hueco))
			_teclas.add_child(caja)
			_teclas_estilos[int(tecla[1])] = estilo
			var simbolo: String = str(tecla[0])
			if simbolo in ["^", "<", "v", ">"]:
				var dibujo: Control = Control.new()
				dibujo.mouse_filter = Control.MOUSE_FILTER_IGNORE
				dibujo.set_anchors_preset(Control.PRESET_FULL_RECT)
				dibujo.draw.connect(_dibujar_flecha_tecla.bind(dibujo, simbolo))
				caja.add_child(dibujo)
			else:
				var letra: Label = _etiqueta(26, Color(0.42, 0.08, 0.2))
				letra.text = simbolo
				letra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				letra.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				letra.set_anchors_preset(Control.PRESET_FULL_RECT)
				caja.add_child(letra)
	var o: Label = _etiqueta(22, Color(0.78, 0.96, 0.92))
	o.text = "o"
	o.add_theme_color_override("font_outline_color", Color(0.08, 0.03, 0.0, 0.9))
	o.add_theme_constant_override("outline_size", 6)
	o.position = Vector2(222.0, 66.0)
	_teclas.add_child(o)


func _dibujar_flecha_tecla(lienzo: Control, simbolo: String) -> void:
	var c: Vector2 = lienzo.size * 0.5
	var r: float = minf(lienzo.size.x, lienzo.size.y) * 0.26
	var puntos: PackedVector2Array
	match simbolo:
		"^":
			puntos = PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, r * 0.7), c + Vector2(-r, r * 0.7)])
		"v":
			puntos = PackedVector2Array([c + Vector2(0, r), c + Vector2(-r, -r * 0.7), c + Vector2(r, -r * 0.7)])
		"<":
			puntos = PackedVector2Array([c + Vector2(-r, 0), c + Vector2(r * 0.7, -r), c + Vector2(r * 0.7, r)])
		_:
			puntos = PackedVector2Array([c + Vector2(r, 0), c + Vector2(-r * 0.7, r), c + Vector2(-r * 0.7, -r)])
	lienzo.draw_colored_polygon(puntos, Color(0.42, 0.08, 0.2))


func _animar_teclas() -> void:
	if _teclas == null:
		return
	var mostrar: bool = _paso == 0 and not _esperando
	_teclas.modulate.a = move_toward(_teclas.modulate.a, 1.0 if mostrar else 0.0, get_process_delta_time() * 3.0)
	for codigo: int in _teclas_estilos:
		var estilo: StyleBoxFlat = _teclas_estilos[codigo]
		estilo.bg_color = AMARILLO if Input.is_physical_key_pressed(codigo) else Color(0.984, 0.945, 0.902, 0.92)


func _crear_barra_carga() -> void:
	_carga_caja = PanelContainer.new()
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = Color(0.03, 0.05, 0.06, 0.85)
	estilo.border_color = AMARILLO
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(10)
	estilo.content_margin_left = 14.0
	estilo.content_margin_right = 14.0
	estilo.content_margin_top = 8.0
	estilo.content_margin_bottom = 10.0
	_carga_caja.add_theme_stylebox_override("panel", estilo)
	_carga_caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carga_caja.set_anchors_preset(Control.PRESET_CENTER)
	_carga_caja.offset_left = -170.0
	_carga_caja.offset_right = 170.0
	_carga_caja.offset_top = 90.0
	_carga_caja.offset_bottom = 160.0
	_carga_caja.visible = false
	_capa.add_child(_carga_caja)
	var columna: VBoxContainer = VBoxContainer.new()
	columna.add_theme_constant_override("separation", 6)
	_carga_caja.add_child(columna)
	_carga_texto = _etiqueta(18, AMARILLO)
	_carga_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(_carga_texto)
	_carga_barra = ProgressBar.new()
	_carga_barra.min_value = 0.0
	_carga_barra.max_value = 100.0
	_carga_barra.show_percentage = false
	_carga_barra.custom_minimum_size = Vector2(300.0, 14.0)
	var fondo: StyleBoxFlat = StyleBoxFlat.new()
	fondo.bg_color = Color(0.15, 0.17, 0.18)
	fondo.set_corner_radius_all(6)
	var relleno: StyleBoxFlat = StyleBoxFlat.new()
	relleno.bg_color = AMARILLO
	relleno.set_corner_radius_all(6)
	_carga_barra.add_theme_stylebox_override("background", fondo)
	_carga_barra.add_theme_stylebox_override("fill", relleno)
	_carga_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(_carga_barra)


func _mostrar_carga() -> void:
	if _carga_caja != null:
		_carga_caja.visible = false
	return
	var accion: String = "Usando"
	if _interactuar.actual is EstacionCarga:
		accion = "Cargando batería"
	elif _interactuar.actual == _terminal:
		accion = "Activando punto"
	var porcentaje: float = clampf(_interactuar.progreso, 0.0, 1.0) * 100.0
	_carga_texto.text = "%s  %d%%" % [accion, int(porcentaje)]
	_carga_barra.value = porcentaje
	_carga_caja.visible = true


func _resaltar_barras() -> void:
	if _hud == null or not is_instance_valid(_hud):
		_hud = get_tree().get_first_node_in_group(Grupos.GRUPO_HUD)
		if _hud == null:
			return
	var id: String = str(PASOS[_paso]["id"]) if _paso < PASOS.size() and not _esperando else ""
	var pulso: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)
	var barra_estres: Control = _hud.get("barra_estres") as Control
	var barra_bateria: Control = _hud.get("barra_bateria") as Control
	if barra_estres != null:
		barra_estres.modulate = Color.WHITE.lerp(Color(1.6, 1.3, 0.4), pulso) if id == "estres" else Color.WHITE
	if barra_bateria != null:
		barra_bateria.modulate = Color.WHITE.lerp(Color(1.6, 1.3, 0.4), pulso) if id == "carga" else Color.WHITE


func _crear_guias(escena: Node) -> void:
	var sombreador: Shader = Shader.new()
	sombreador.code = SHADER_GUIA
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.75, 0.75)
	var raiz: Node3D = Node3D.new()
	raiz.name = "FlechasGuia"
	escena.add_child(raiz)
	for i: int in 14:
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = sombreador
		mat.set_shader_parameter("color", AMARILLO)
		mat.set_shader_parameter("alfa", 0.0)
		var flecha: MeshInstance3D = MeshInstance3D.new()
		flecha.mesh = quad
		flecha.material_override = mat
		flecha.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flecha.visible = false
		raiz.add_child(flecha)
		_guias.append({"flecha": flecha, "material": mat, "alfa": 0.0})


func _destino_guia() -> Variant:
	if _jugador == null or _paso >= PASOS.size() or _charla >= 0:
		return null
	var paso: Dictionary = PASOS[_paso]
	if _esperando:
		if not paso.has("desde_x"):
			return null
		var meta_x: float = float(paso["desde_x"]) + 1.0
		if _jugador.global_position.x >= meta_x - 0.5:
			return null
		return Vector3(meta_x, 0.0, clampf(_jugador.global_position.z, -1.5, 2.0))
	if str(paso["id"]) == "salida":
		var subida: Node3D = get_parent().get_node_or_null("Escalera/SubidaSegundoPiso") as Node3D
		if subida != null:
			return Vector3(subida.global_position.x, 0.0, -2.4)
	if _resaltado == null or not _resaltado.visible or not is_instance_valid(_resaltado_objetivo):
		return null
	var base: Vector3 = _resaltado_objetivo.global_position
	return Vector3(base.x, 0.0, clampf(base.z, -2.5, 2.6))


func _guiar(delta: float) -> void:
	if _guias.is_empty():
		return
	_guia_tiempo += delta
	var destino = _destino_guia()
	var origen: Vector3 = Vector3.ZERO
	var direccion: Vector3 = Vector3.ZERO
	var distancia: float = 0.0
	if destino != null:
		origen = Vector3(_jugador.global_position.x, 0.0, _jugador.global_position.z)
		var hacia: Vector3 = (destino as Vector3) - origen
		distancia = hacia.length()
		if distancia > 0.01:
			direccion = hacia / distancia
	var activo: bool = destino != null and distancia > 2.2
	var desplazamiento: float = fmod(_guia_tiempo * 1.4, SEPARACION_GUIA)
	var giro: Basis = Basis(Vector3.UP, atan2(-direccion.z, direccion.x)) * Basis(Vector3.RIGHT, -PI * 0.5)
	for i: int in _guias.size():
		var g: Dictionary = _guias[i]
		var flecha: MeshInstance3D = g["flecha"] as MeshInstance3D
		var mat: ShaderMaterial = g["material"] as ShaderMaterial
		var s: float = 1.1 + desplazamiento + float(i) * SEPARACION_GUIA
		var visible_aqui: bool = activo and s < distancia - 0.9
		var alfa_actual: float = float(g["alfa"])
		var alfa_meta: float = 0.0
		if visible_aqui:
			alfa_meta = 0.85 * clampf((s - 1.1) / 0.6, 0.0, 1.0) * clampf((distancia - 0.9 - s) / 0.8, 0.0, 1.0)
			flecha.global_transform = Transform3D(giro, origen + direccion * s + Vector3(0.0, 0.03, 0.0))
		var alfa: float = move_toward(alfa_actual, alfa_meta, delta * 4.0) if visible_aqui or not activo else alfa_meta
		g["alfa"] = alfa
		mat.set_shader_parameter("alfa", alfa)
		flecha.visible = alfa > 0.01


func _crear_entrada_escalera(escena: Node) -> void:
	var escalera: Node3D = escena.get_node_or_null("Escalera/SubidaSegundoPiso") as Node3D
	var centro_x: float = fin_pasillo - 2.3
	if escalera != null:
		centro_x = escalera.global_position.x
	_barrera_escalera = StaticBody3D.new()
	_barrera_escalera.name = "BarreraEscalera"
	var forma: CollisionShape3D = CollisionShape3D.new()
	var caja: BoxShape3D = BoxShape3D.new()
	caja.size = Vector3(3.4, 4.0, 0.4)
	forma.shape = caja
	_barrera_escalera.add_child(forma)
	escena.add_child(_barrera_escalera)
	_barrera_escalera.global_position = Vector3(centro_x, 2.0, -3.55)
	var entrada: Area3D = Area3D.new()
	entrada.name = "EntradaEscalera"
	entrada.monitorable = false
	var zona: CollisionShape3D = CollisionShape3D.new()
	var caja_zona: BoxShape3D = BoxShape3D.new()
	caja_zona.size = Vector3(3.0, 2.5, 1.0)
	zona.shape = caja_zona
	entrada.add_child(zona)
	escena.add_child(entrada)
	entrada.global_position = Vector3(centro_x, 1.25, -2.95)
	entrada.body_entered.connect(_al_llegar_salida)
