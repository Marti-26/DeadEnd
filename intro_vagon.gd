extends Node3D

@export_file("*.tscn") var siguiente_escena: String = "res://pantalla_carga.tscn"
@export var posicion_sentada: Vector3 = Vector3(-1.14, 1.21, 0.5)
@export var tamano_pixel_sentada: float = 0.0065
@export var altura_asiento: float = 0.45
@export var color_dia: Color = Color(1.0, 0.95, 0.86)
@export var mezcla_luz_noche: float = 0.5

@onready var gatita: AnimatedSprite3D = $Gatita
@onready var texto_narrativo: Label = $CanvasLayer/PanelNarrativo/MarginContainer/TextoNarrativo
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect
@onready var timer_secuencia: Timer = $TimerSecuencia

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var dir_light: DirectionalLight3D = $DirectionalLight3D
@onready var luz_ambiente: OmniLight3D = $LuzAmbienteVagon
@onready var rayo_sol: CSGBox3D = $Vagon/VentanaPrincipal/RayoSol
@onready var tunel_oscuro: Node3D = $Vagon/PaisajeExterior/TunelOscuro
@onready var tubo_neon: CSGBox3D = $Vagon/TuboLedTecho

@onready var audio_viaje: AudioStreamPlayer = $Audios/AudioViaje
@onready var audio_llegada: AudioStreamPlayer = $Audios/AudioLlegada
@onready var audio_puertas: AudioStreamPlayer = $Audios/AudioPuertas
@onready var audio_meow: AudioStreamPlayer = $Audios/AudioMeow

var _transicion_iniciada: bool = false
var _paso_secuencia: int = 0
var _siguiente_animacion: StringName = &""
var _energia_sol: float = 1.0
var _animaciones_metro: bool = false
var _velocidad_tren: float = 1.0
var _recorrido: float = 0.0
var _tiempo: float = 0.0
var _capas: Array[Dictionary] = []
var _tunel: ShaderMaterial = null
var _luz_tunel: OmniLight3D = null
var _rayos: Array[ShaderMaterial] = []
var _vidrios: Array[ShaderMaterial] = []
var _camara: Camera3D = null
var _camara_base: Transform3D = Transform3D.IDENTITY

const SEPARACION_LAMPARAS: float = 3.2
const VELOCIDAD_TUNEL: float = 11.0

const SHADER_CIELO: String = """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform vec4 cielo_alto : source_color = vec4(0.42, 0.63, 0.88, 1.0);
uniform vec4 cielo_horizonte : source_color = vec4(0.95, 0.9, 0.8, 1.0);
uniform vec4 color_sol : source_color = vec4(1.0, 0.86, 0.6, 1.0);
uniform vec2 posicion_sol = vec2(4.0, 6.0);
uniform float ancho = 18.0;
uniform float alto = 8.0;
uniform float desplazamiento = 0.0;
float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float r2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1.0, 0.0)), u.x), mix(h2(i + vec2(0.0, 1.0)), h2(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * r2(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}
void fragment() {
	float g = 1.0 - UV.y;
	vec2 p = vec2(UV.x * ancho, g * alto);
	vec3 col = mix(cielo_horizonte.rgb, cielo_alto.rgb, smoothstep(0.15, 0.95, g));
	float d = distance(p, posicion_sol);
	col += color_sol.rgb * (exp(-d * 0.9) * 0.35 + exp(-d * 6.0) * 0.6);
	vec2 q = vec2(p.x + desplazamiento, p.y * 2.2);
	float n = fbm(q * 0.45);
	float nubes = smoothstep(0.52, 0.72, n) * smoothstep(0.35, 0.6, g);
	float sombra = smoothstep(0.52, 0.8, fbm(q * 0.45 + vec2(0.0, -0.35)));
	vec3 nube = mix(vec3(1.0, 0.98, 0.95), vec3(0.82, 0.84, 0.92), sombra * 0.6);
	col = mix(col, nube, nubes * 0.9);
	col *= 0.97 + 0.03 * h2(floor(p * 60.0));
	ALBEDO = col;
}
"""

const SHADER_CAPA: String = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 color_base : source_color = vec4(0.3, 0.4, 0.3, 1.0);
uniform vec4 color_cima : source_color = vec4(0.5, 0.6, 0.5, 1.0);
uniform vec4 color_niebla : source_color = vec4(0.9, 0.9, 0.85, 1.0);
uniform float niebla = 0.0;
uniform int tipo = 0;
uniform float ancho = 16.0;
uniform float alto = 3.0;
uniform float desplazamiento = 0.0;
uniform float base = 1.0;
uniform float amplitud = 0.5;
uniform float separacion = 1.0;
uniform float semilla = 0.0;
float h1(float n) { return fract(sin(n * 127.1 + semilla * 31.7) * 43758.5453); }
float r1(float x) {
	float i = floor(x);
	float f = fract(x);
	float u = f * f * (3.0 - 2.0 * f);
	return mix(h1(i), h1(i + 1.0), u);
}
float copa(float x, float s) {
	float c = floor(x / s);
	float f = fract(x / s) - 0.5;
	return (0.4 + 0.6 * h1(c)) * sqrt(max(0.0, 1.0 - 4.0 * f * f));
}
float cubre(float d) { return clamp(d / max(fwidth(d), 0.0001) + 0.5, 0.0, 1.0); }
void fragment() {
	float x = UV.x * ancho + desplazamiento;
	float y = (1.0 - UV.y) * alto;
	float h = base;
	float a = 0.0;
	float extra = 0.0;
	if (tipo == 0) {
		float c = floor(x / separacion);
		float f = fract(x / separacion);
		h = base + amplitud * (0.2 + 0.8 * h1(c));
		float hueco = mix(1.0, step(0.05, f) * step(f, 0.95), step(0.45, h1(c + 7.0)));
		float antena = step(abs(f - 0.3), 0.012) * step(y, h + 0.18 * step(0.7, h1(c + 3.0)));
		a = max(cubre(h - y) * hueco, antena);
		vec2 g = vec2(fract(x * 7.0), fract(y * 6.0));
		float ventana = step(0.35, g.x) * step(g.x, 0.7) * step(0.3, g.y) * step(g.y, 0.65);
		extra = ventana * step(0.6, h1(floor(x * 7.0) + floor(y * 6.0) * 13.0)) * 0.07;
	} else if (tipo == 1 || tipo == 2) {
		float copas = max(copa(x, separacion), copa(x + 0.37 * separacion, separacion * 1.53) * 0.85);
		if (tipo == 1) {
			h = base + amplitud * 0.55 * r1(x * 0.3) + copas * amplitud * 0.6;
		} else {
			h = base + copas * amplitud + 0.05 * r1(x * 3.0);
		}
		a = cubre(h - y);
	} else {
		float px = fract(x / separacion) * separacion - separacion * 0.5;
		h = base + amplitud;
		float poste = cubre(0.045 - abs(px)) * step(y, h);
		float brazo = cubre(0.022 - abs(y - (h - 0.12))) * step(abs(px), 0.45);
		float cable = cubre(0.007 - abs(y - (h - 0.2))) * 0.8;
		a = max(max(poste, brazo), cable);
	}
	float t = clamp(y / max(h, 0.01), 0.0, 1.0);
	vec3 col = mix(color_base.rgb, color_cima.rgb, t) + extra;
	col *= 0.93 + 0.07 * h1(floor(x * 45.0) + floor(y * 45.0) * 57.0);
	col = mix(col, color_niebla.rgb, niebla);
	ALBEDO = col;
	ALPHA = a;
}
"""

const SHADER_TUNEL: String = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_add;
uniform float ancho = 8.0;
uniform float alto = 3.0;
uniform float desplazamiento = 0.0;
uniform float separacion = 3.2;
uniform float intensidad = 0.0;
uniform float velocidad = 1.0;
float h1(float n) { return fract(sin(n * 91.3) * 43758.5453); }
void fragment() {
	float x = UV.x * ancho + desplazamiento;
	float y = (1.0 - UV.y) * alto;
	float c = floor(x / separacion);
	float px = fract(x / separacion) * separacion - separacion * 0.5;
	float largo = 0.12 + velocidad * 0.55;
	float lampara = exp(-pow(px / largo, 2.0)) * exp(-pow((y - 2.05) / 0.045, 2.0));
	float halo = exp(-pow(px / (largo * 2.5), 2.0)) * exp(-pow((y - 2.05) / 0.35, 2.0)) * 0.25;
	vec3 tono = mix(vec3(1.0, 0.66, 0.32), vec3(0.45, 0.6, 1.0), step(0.75, h1(c)));
	float costilla = exp(-pow((fract(x / 1.1) - 0.5) / 0.05, 2.0)) * 0.035 * step(y, 2.5);
	float cable = exp(-pow((y - 1.15) / 0.012, 2.0)) * 0.06;
	ALBEDO = (tono * (lampara * 2.2 + halo) + vec3(0.5, 0.55, 0.8) * (costilla + cable)) * intensidad;
}
"""

const SHADER_VIDRIO: String = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 tinte : source_color = vec4(0.82, 0.92, 1.0, 1.0);
uniform float base_alfa = 0.04;
uniform float reflejo = 1.0;
uniform float proporcion = 1.8;
void fragment() {
	float d = UV.x * proporcion + UV.y * 0.8;
	float banda = smoothstep(0.0, 0.05, fract(d * 0.7) - 0.55) * (1.0 - smoothstep(0.0, 0.12, fract(d * 0.7) - 0.62));
	float linea = exp(-pow((fract(d * 0.7 + 0.21) - 0.5) / 0.012, 2.0));
	float e = min(min(UV.x, 1.0 - UV.x) * proporcion, min(UV.y, 1.0 - UV.y));
	float marco = 1.0 - smoothstep(0.0, 0.05, e);
	ALBEDO = tinte.rgb;
	ALPHA = clamp(base_alfa + (banda * 0.09 + linea * 0.07) * reflejo + marco * 0.06, 0.0, 1.0);
}
"""

const SHADER_RAYO: String = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_add;
uniform vec4 color : source_color = vec4(1.0, 0.9, 0.72, 1.0);
uniform float intensidad = 1.0;
uniform float tiempo = 0.0;
float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	float lados = smoothstep(0.0, 0.18, UV.x) * smoothstep(0.0, 0.18, 1.0 - UV.x);
	float caida = pow(1.0 - UV.y, 1.6);
	float rayas = 0.75 + 0.25 * sin((UV.x * 9.0 + UV.y * 2.0) * 3.1416);
	vec2 celda = floor(vec2(UV.x * 60.0, UV.y * 60.0 + tiempo * 1.5));
	float polvo = step(0.985, h2(celda)) * 0.6;
	ALBEDO = color.rgb * (lados * caida * rayas * 0.11 + polvo * lados * caida * 0.25) * intensidad;
}
"""

const ANIMACIONES_METRO: Dictionary = {
	"metro_sentada": [3, 5.0, true],
	"metro_quedandose_dormida": [6, 6.0, false],
	"metro_dormida": [3, 3.5, true],
	"metro_despertando": [6, 8.0, false],
	"metro_asustada": [3, 8.0, true],
}

func _ready() -> void:
	if timer_secuencia:
		timer_secuencia.timeout.connect(_on_timer_secuencia_timeout)

	# Duplicar recursos en tiempo de ejecución para tweens dinámicos seguros
	if world_env and world_env.environment:
		world_env.environment = world_env.environment.duplicate()
	if rayo_sol and rayo_sol.material:
		rayo_sol.material = rayo_sol.material.duplicate()
	if tubo_neon and tubo_neon.material:
		tubo_neon.material = tubo_neon.material.duplicate()

	# Iniciar con la gata sentada con sus audífonos puestos escuchando música
	if gatita:
		gatita.shaded = false
		gatita.modulate = Color(1.0, 1.0, 1.0)
		_preparar_animaciones_metro()
		if _animaciones_metro:
			_animar(&"metro_sentada")
		elif gatita.sprite_frames and gatita.sprite_frames.has_animation("audifonos_idle_frente"):
			gatita.play("audifonos_idle_frente")
		else:
			gatita.play("idle_frente")
	if dir_light:
		_energia_sol = maxf(dir_light.light_energy, 0.001)
	
	# Transición suave de entrada (fade in desde negro)
	if fade_rect:
		fade_rect.color.a = 1.0
		var tween_in: Tween = create_tween()
		tween_in.tween_property(fade_rect, "color:a", 0.0, 0.8)
	
	_mejorar_escena()

	# Sonido del metro en marcha
	if audio_viaje:
		audio_viaje.play()
	
	# Comenzar la secuencia cinematográfica
	_ejecutar_paso(0)

func _unhandled_input(event: InputEvent) -> void:
	if _transicion_iniciada:
		return
	if event.is_action_pressed("ui_accept"):
		_saltar_cinematica()
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
				_saltar_cinematica()

func _on_timer_secuencia_timeout() -> void:
	_paso_secuencia += 1
	_ejecutar_paso(_paso_secuencia)

func _ejecutar_paso(paso: int) -> void:
	if _transicion_iniciada:
		return
		
	match paso:
		0:
			# Estado 1: Tren en movimiento de día, gata relajada con música
			_mostrar_texto("El suave y monótono vaivén del metro...")
			timer_secuencia.start(3.2)
			get_tree().create_timer(1.4).timeout.connect(_dormirse)
		1:
			# Estado 2: Frenado, aviso de llegada y transición a iluminación oscura de metro
			if audio_viaje:
				var tween_vol: Tween = create_tween()
				tween_vol.tween_property(audio_viaje, "volume_db", -28.0, 2.5)
			if audio_llegada:
				audio_llegada.play()
			
			# Ejecutar la transición visual al ambiente oscuro del metro
			_oscurecer_a_estacion_terminal()
			var frenado: Tween = create_tween()
			frenado.tween_property(self, "_velocidad_tren", 0.0, 4.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

			_mostrar_texto("'¡Atención pasajeros: Próxima parada, Estación Terminal...'")
			timer_secuencia.start(3.8)
		2:
			# Estado 3: Sonido de puertas y fin de recorrido
			if audio_puertas:
				audio_puertas.play()
			_mostrar_texto("'Última estación. Fin del recorrido. Por favor, desciendan del metro '")
			timer_secuencia.start(3.2)
		3:
			# Estado 4: Gatita se despierta / reacciona confundida en la penumbra
			if gatita:
				if _animaciones_metro:
					_animar(&"metro_despertando", &"metro_asustada")
				else:
					gatita.play("idle_frente")
			if audio_meow:
				audio_meow.play()
			_mostrar_texto("¿Eh?... ¿Me quedé dormida?... ¿Dónde están todos?")
			timer_secuencia.start(3.2)
		4:
			# Estado 5: Se percata de la oscuridad del andén
			_mostrar_texto("Las luces del andén están apagadas... Debo bajar rápido")
			timer_secuencia.start(2.8)
		5:
			# Estado 6: Transición fluida a la siguiente escena
			_transicionar_a_siguiente_escena()

func _oscurecer_a_estacion_terminal() -> void:
	# 1. Apagar luz solar y desvanecer rayo de sol
	var tween_sol: Tween = create_tween().set_parallel(true)
	if dir_light:
		tween_sol.tween_property(dir_light, "light_energy", 0.0, 2.0)
	if rayo_sol and rayo_sol.material is StandardMaterial3D:
		var mat_rayo: StandardMaterial3D = rayo_sol.material as StandardMaterial3D
		tween_sol.tween_property(mat_rayo, "albedo_color:a", 0.0, 1.4)

	# 2. Desvanecer exterior día y mostrar el túnel oscuro de la estación con luces neón
	if tunel_oscuro:
		var tween_tunel: Tween = create_tween().set_parallel(true)
		for hijo: Node in tunel_oscuro.get_children():
			if hijo is CSGBox3D:
				var csg: CSGBox3D = hijo as CSGBox3D
				if csg.material is StandardMaterial3D:
					var mat: StandardMaterial3D = csg.material.duplicate() as StandardMaterial3D
					csg.material = mat
					var alfa_objetivo: float = 1.0 if csg.name == "FondoTunel" else 0.85
					tween_tunel.tween_property(mat, "albedo_color:a", alfa_objetivo, 1.8)

	# 3. Parpadeo de luces interiores (efecto apagón / cambio de vía en la terminal)
	if luz_ambiente:
		var tween_flicker: Tween = create_tween()
		tween_flicker.tween_property(luz_ambiente, "light_energy", 0.1, 0.15)
		tween_flicker.tween_property(luz_ambiente, "light_energy", 0.45, 0.1)
		tween_flicker.tween_property(luz_ambiente, "light_energy", 0.05, 0.2)
		tween_flicker.tween_property(luz_ambiente, "light_energy", 0.32, 0.3)
		# Transición de color al azul/violeta LED característico del otro metro
		tween_flicker.parallel().tween_property(luz_ambiente, "light_color", Color(0.42, 0.48, 0.98), 1.8)

	# 4. Encender tubo neón violeta del techo
	if tubo_neon and tubo_neon.material is StandardMaterial3D:
		var mat_neon: StandardMaterial3D = tubo_neon.material as StandardMaterial3D
		var tween_neon: Tween = create_tween()
		tween_neon.tween_property(mat_neon, "emission_energy_multiplier", 2.2, 1.8)

	# 5. Transición ambiental del WorldEnvironment a la atmósfera subterránea nocturna
	if world_env and world_env.environment:
		var env: Environment = world_env.environment
		var tween_env: Tween = create_tween().set_parallel(true)
		tween_env.tween_property(env, "ambient_light_color", Color(0.12, 0.14, 0.32), 2.0)
		tween_env.tween_property(env, "ambient_light_energy", 0.18, 2.0)
		tween_env.tween_property(env, "background_color", Color(0.015, 0.018, 0.035), 2.0)

func _mostrar_texto(texto: String) -> void:
	if not texto_narrativo:
		return
	var tween: Tween = create_tween()
	tween.tween_property(texto_narrativo, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func() -> void: texto_narrativo.text = texto)
	tween.tween_property(texto_narrativo, "modulate:a", 1.0, 0.3)

func _saltar_cinematica() -> void:
	_transicionar_a_siguiente_escena()

func _transicionar_a_siguiente_escena() -> void:
	if _transicion_iniciada:
		return
	_transicion_iniciada = true
	if timer_secuencia:
		timer_secuencia.stop()
	
	if fade_rect:
		var tween: Tween = create_tween()
		tween.tween_property(fade_rect, "color:a", 1.0, 0.5)
		await tween.finished
	
	var error: Error = get_tree().change_scene_to_file(siguiente_escena)
	if error != OK:
		push_error("Error al cargar la escena '%s': %d" % [siguiente_escena, error])
		_transicion_iniciada = false


func _process(delta: float) -> void:
	_tiempo += delta
	_recorrido += delta * _velocidad_tren
	var dia: float = 0.0
	if dir_light:
		dia = clampf(dir_light.light_energy / _energia_sol, 0.0, 1.0)
	var noche: float = 1.0 - dia
	for capa: Dictionary in _capas:
		(capa["material"] as ShaderMaterial).set_shader_parameter("desplazamiento", _recorrido * float(capa["velocidad"]))
	var brillo_tunel: float = 0.0
	if _tunel != null:
		var desplazamiento: float = _recorrido * VELOCIDAD_TUNEL
		var intensidad: float = noche * smoothstep(0.0, 0.25, _velocidad_tren)
		_tunel.set_shader_parameter("desplazamiento", desplazamiento)
		_tunel.set_shader_parameter("intensidad", intensidad)
		_tunel.set_shader_parameter("velocidad", _velocidad_tren)
		if _luz_tunel != null:
			var fase: float = fposmod(SEPARACION_LAMPARAS * 0.5 - desplazamiento, SEPARACION_LAMPARAS) - SEPARACION_LAMPARAS * 0.5
			_luz_tunel.position.x = 0.5 + fase * 1.6
			brillo_tunel = intensidad * pow(1.0 - absf(fase) / (SEPARACION_LAMPARAS * 0.5), 2.0)
			_luz_tunel.light_energy = brillo_tunel * 1.6
	for rayo: ShaderMaterial in _rayos:
		rayo.set_shader_parameter("intensidad", dia)
		rayo.set_shader_parameter("tiempo", _tiempo)
	for vidrio: ShaderMaterial in _vidrios:
		vidrio.set_shader_parameter("reflejo", lerpf(0.55, 1.0, dia))
	if _camara != null:
		var vaiven: float = _velocidad_tren
		var movida: Transform3D = _camara_base
		movida.origin += Vector3(sin(_tiempo * 0.9) * 0.006, sin(_tiempo * 1.7) * 0.005, 0.0) * vaiven
		movida.basis = movida.basis * Basis(Vector3.FORWARD, sin(_tiempo * 1.1) * 0.0035 * vaiven)
		_camara.transform = movida
	if gatita == null:
		return
	var color_noche: Color = Color(0.5, 0.52, 0.78)
	if luz_ambiente:
		var tono: Color = luz_ambiente.light_color.lerp(Color.WHITE, mezcla_luz_noche)
		var brillo: float = clampf(0.3 + luz_ambiente.light_energy * 0.9, 0.28, 0.7)
		color_noche = Color(tono.r * brillo, tono.g * brillo, tono.b * brillo)
	color_noche += Color(1.0, 0.66, 0.32) * brillo_tunel * 0.35
	var final: Color = color_noche.lerp(color_dia, dia)
	final.a = 1.0
	gatita.modulate = final
	if _animaciones_metro:
		gatita.position.y = posicion_sentada.y + sin(_tiempo * 1.7) * 0.004 * _velocidad_tren


func _mejorar_escena() -> void:
	_camara = get_node_or_null("Camera3D") as Camera3D
	if _camara != null:
		_camara_base = _camara.transform
	if world_env and world_env.environment:
		var env: Environment = world_env.environment
		env.glow_enabled = true
		env.glow_intensity = 0.5
		env.glow_bloom = 0.04
		env.glow_hdr_threshold = 1.0
	if dir_light:
		dir_light.shadow_enabled = true
		dir_light.shadow_blur = 2.5
		dir_light.light_color = Color(1.0, 0.93, 0.8)
	var exterior: Node = get_node_or_null("Vagon/PaisajeExterior")
	if exterior != null:
		for hijo: Node in exterior.get_children():
			if hijo != tunel_oscuro and hijo is Node3D:
				(hijo as Node3D).visible = false
	if tunel_oscuro:
		for nombre: String in ["LuzTunelAzul", "LuzTunelRoja", "LuzTunelAmbar"]:
			var luz_vieja: Node3D = tunel_oscuro.get_node_or_null(nombre) as Node3D
			if luz_vieja != null:
				luz_vieja.visible = false
	if rayo_sol:
		rayo_sol.visible = false
	_crear_paisaje()
	_crear_tunel()
	_crear_vidrios()
	_crear_rayos()
	_tapar_huecos()
	var sticker: CSGBox3D = get_node_or_null("Vagon/VentanaDerecha/StickerAlerta") as CSGBox3D
	if sticker != null and sticker.material is StandardMaterial3D:
		var mat_sticker: StandardMaterial3D = sticker.material.duplicate() as StandardMaterial3D
		mat_sticker.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		sticker.material = mat_sticker


func _quad(padre: Node3D, tamano: Vector2, posicion: Vector3, material: Material) -> MeshInstance3D:
	var malla: MeshInstance3D = MeshInstance3D.new()
	var quad: QuadMesh = QuadMesh.new()
	quad.size = tamano
	malla.mesh = quad
	malla.material_override = material
	malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(malla)
	malla.position = posicion
	return malla


func _crear_paisaje() -> void:
	var raiz: Node3D = Node3D.new()
	raiz.name = "PaisajeVivo"
	add_child(raiz)
	var horizonte: Color = Color(0.95, 0.9, 0.8)
	var sombreador_cielo: Shader = Shader.new()
	sombreador_cielo.code = SHADER_CIELO
	var cielo: ShaderMaterial = ShaderMaterial.new()
	cielo.shader = sombreador_cielo
	cielo.set_shader_parameter("ancho", 18.0)
	cielo.set_shader_parameter("alto", 8.0)
	cielo.set_shader_parameter("cielo_horizonte", horizonte)
	_quad(raiz, Vector2(18.0, 8.0), Vector3(0.5, 2.4, -3.6), cielo)
	_capas.append({"material": cielo, "velocidad": 0.08})
	var sombreador: Shader = Shader.new()
	sombreador.code = SHADER_CAPA
	var capas: Array[Dictionary] = [
		{"tipo": 0, "ancho": 16.0, "alto": 3.0, "y": 1.9, "z": -3.1, "base": 1.05, "amplitud": 0.8, "separacion": 0.55, "velocidad": 0.45, "base_color": Color(0.5, 0.58, 0.72), "cima": Color(0.62, 0.7, 0.82), "niebla": 0.2, "semilla": 1.0},
		{"tipo": 1, "ancho": 14.0, "alto": 3.0, "y": 1.7, "z": -2.3, "base": 0.95, "amplitud": 0.5, "separacion": 0.75, "velocidad": 1.5, "base_color": Color(0.33, 0.5, 0.36), "cima": Color(0.52, 0.7, 0.47), "niebla": 0.16, "semilla": 2.0},
		{"tipo": 2, "ancho": 12.0, "alto": 2.0, "y": 1.0, "z": -1.4, "base": 0.85, "amplitud": 0.3, "separacion": 0.45, "velocidad": 4.5, "base_color": Color(0.17, 0.3, 0.2), "cima": Color(0.29, 0.47, 0.3), "niebla": 0.0, "semilla": 3.0},
		{"tipo": 3, "ancho": 12.0, "alto": 3.0, "y": 1.5, "z": -0.95, "base": 0.0, "amplitud": 2.55, "separacion": 4.5, "velocidad": 8.0, "base_color": Color(0.2, 0.21, 0.24), "cima": Color(0.3, 0.31, 0.34), "niebla": 0.0, "semilla": 4.0},
	]
	for datos: Dictionary in capas:
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = sombreador
		mat.set_shader_parameter("tipo", int(datos["tipo"]))
		mat.set_shader_parameter("ancho", float(datos["ancho"]))
		mat.set_shader_parameter("alto", float(datos["alto"]))
		mat.set_shader_parameter("base", float(datos["base"]))
		mat.set_shader_parameter("amplitud", float(datos["amplitud"]))
		mat.set_shader_parameter("separacion", float(datos["separacion"]))
		mat.set_shader_parameter("color_base", datos["base_color"])
		mat.set_shader_parameter("color_cima", datos["cima"])
		mat.set_shader_parameter("color_niebla", horizonte)
		mat.set_shader_parameter("niebla", float(datos["niebla"]))
		mat.set_shader_parameter("semilla", float(datos["semilla"]))
		var y_centro: float = float(datos["y"])
		_quad(raiz, Vector2(float(datos["ancho"]), float(datos["alto"])), Vector3(0.5, y_centro, float(datos["z"])), mat)
		_capas.append({"material": mat, "velocidad": float(datos["velocidad"])})


func _crear_tunel() -> void:
	var sombreador: Shader = Shader.new()
	sombreador.code = SHADER_TUNEL
	_tunel = ShaderMaterial.new()
	_tunel.shader = sombreador
	_tunel.set_shader_parameter("ancho", 8.0)
	_tunel.set_shader_parameter("alto", 3.0)
	_tunel.set_shader_parameter("separacion", SEPARACION_LAMPARAS)
	_quad(self, Vector2(8.0, 3.0), Vector3(0.5, 0.15 + 1.5, -0.45), _tunel)
	_luz_tunel = OmniLight3D.new()
	_luz_tunel.name = "LuzTunelPasa"
	_luz_tunel.light_color = Color(1.0, 0.68, 0.36)
	_luz_tunel.light_energy = 0.0
	_luz_tunel.omni_range = 4.5
	_luz_tunel.shadow_enabled = false
	add_child(_luz_tunel)
	_luz_tunel.position = Vector3(0.5, 2.0, -0.3)


func _crear_vidrios() -> void:
	var sombreador: Shader = Shader.new()
	sombreador.code = SHADER_VIDRIO
	for ruta: String in ["Vagon/VentanaPrincipal", "Vagon/VentanaDerecha"]:
		var ventana: Node3D = get_node_or_null(ruta) as Node3D
		if ventana == null:
			continue
		var viejo: CSGBox3D = ventana.get_node_or_null("Vidrio") as CSGBox3D
		if viejo == null:
			continue
		viejo.visible = false
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = sombreador
		mat.set_shader_parameter("proporcion", viejo.size.x / viejo.size.y)
		_quad(ventana, Vector2(viejo.size.x, viejo.size.y), Vector3(0.0, 0.0, 0.015), mat)
		_vidrios.append(mat)


func _crear_rayos() -> void:
	var sombreador: Shader = Shader.new()
	sombreador.code = SHADER_RAYO
	for datos: Array in [[-0.55, 2.3], [2.15, 1.35]]:
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = sombreador
		var rayo: MeshInstance3D = _quad(self, Vector2(float(datos[1]), 2.1), Vector3(float(datos[0]), 1.35, 0.42), mat)
		rayo.rotation = Vector3(-0.46, 0.0, 0.0)
		_rayos.append(mat)


func _tapar_huecos() -> void:
	var paredes: Node3D = get_node_or_null("Vagon/Paredes") as Node3D
	if paredes == null:
		return
	var inferior: CSGBox3D = paredes.get_node_or_null("ParedInferior") as CSGBox3D
	if inferior != null:
		inferior.size.y = 0.97
		inferior.position.y = 0.485
	var superior: CSGBox3D = paredes.get_node_or_null("ParedSuperior") as CSGBox3D
	if superior != null:
		superior.size.y = 0.44
		superior.position.y = 2.53
	var pilar: CSGBox3D = paredes.get_node_or_null("PilarCentral") as CSGBox3D
	var material: Material = pilar.material if pilar != null else null
	for tramo: Vector2 in [Vector2(-1.87, -1.76), Vector2(0.66, 0.74), Vector2(1.36, 1.44), Vector2(2.86, 2.97)]:
		var relleno: CSGBox3D = CSGBox3D.new()
		relleno.size = Vector3(tramo.y - tramo.x, 1.46, 0.1)
		relleno.material = material
		paredes.add_child(relleno)
		relleno.position = Vector3((tramo.x + tramo.y) * 0.5, 1.65, 0.0)


func _preparar_animaciones_metro() -> void:
	if gatita.sprite_frames == null:
		return
	var cuadros: SpriteFrames = gatita.sprite_frames.duplicate() as SpriteFrames
	var completas: bool = true
	for nombre: String in ANIMACIONES_METRO:
		var datos: Array = ANIMACIONES_METRO[nombre]
		if cuadros.has_animation(nombre):
			cuadros.remove_animation(nombre)
		cuadros.add_animation(nombre)
		cuadros.set_animation_speed(nombre, float(datos[1]))
		cuadros.set_animation_loop(nombre, bool(datos[2]))
		for i: int in range(1, int(datos[0]) + 1):
			var ruta: String = "res://assets/gatita/gatita_%s_%d.png" % [nombre, i]
			if ResourceLoader.exists(ruta):
				cuadros.add_frame(nombre, load(ruta) as Texture2D)
			else:
				completas = false
	if not completas:
		return
	_animaciones_metro = true
	gatita.sprite_frames = cuadros
	gatita.pixel_size = tamano_pixel_sentada
	gatita.position = posicion_sentada
	var sombra: Node = gatita.get_node_or_null("Sombra")
	if sombra != null:
		sombra.set("altura_visual_piso", altura_asiento)
		sombra.set("tamano", Vector2(0.75, 0.35))
	gatita.animation_finished.connect(_al_terminar_animacion)


func _animar(nombre: StringName, siguiente: StringName = &"") -> void:
	if gatita == null or not gatita.sprite_frames.has_animation(nombre):
		return
	_siguiente_animacion = siguiente
	gatita.play(nombre)


func _al_terminar_animacion() -> void:
	if _siguiente_animacion == &"":
		return
	var siguiente: StringName = _siguiente_animacion
	_siguiente_animacion = &""
	gatita.play(siguiente)


func _dormirse() -> void:
	if _transicion_iniciada or not _animaciones_metro:
		return
	_animar(&"metro_quedandose_dormida", &"metro_dormida")
