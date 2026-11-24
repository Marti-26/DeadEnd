extends Node3D

@export_file("*.tscn") var siguiente_escena: String = "res://pantalla_carga.tscn"

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
		if gatita.sprite_frames and gatita.sprite_frames.has_animation("audifonos_idle_frente"):
			gatita.play("audifonos_idle_frente")
		else:
			gatita.play("idle_frente")
	
	# Transición suave de entrada (fade in desde negro)
	if fade_rect:
		fade_rect.color.a = 1.0
		var tween_in: Tween = create_tween()
		tween_in.tween_property(fade_rect, "color:a", 0.0, 0.8)
	
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
		1:
			# Estado 2: Frenado, aviso de llegada y transición a iluminación oscura de metro
			if audio_viaje:
				var tween_vol: Tween = create_tween()
				tween_vol.tween_property(audio_viaje, "volume_db", -28.0, 2.5)
			if audio_llegada:
				audio_llegada.play()
			
			# Ejecutar la transición visual al ambiente oscuro del metro
			_oscurecer_a_estacion_terminal()

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

	# 6. Adaptar suavemente el matiz de la gata a la penumbra
	if gatita:
		var tween_gata: Tween = create_tween()
		tween_gata.tween_property(gatita, "modulate", Color(0.82, 0.84, 0.94), 2.0)

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
