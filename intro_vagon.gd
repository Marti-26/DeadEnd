extends Node3D

@export_file("*.tscn") var siguiente_escena: String = "res://zona_b.tscn"

@onready var gatita: AnimatedSprite3D = $Gatita
@onready var texto_narrativo: Label = $CanvasLayer/PanelNarrativo/MarginContainer/TextoNarrativo
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect
@onready var timer_secuencia: Timer = $TimerSecuencia

@onready var audio_viaje: AudioStreamPlayer = $Audios/AudioViaje
@onready var audio_llegada: AudioStreamPlayer = $Audios/AudioLlegada
@onready var audio_puertas: AudioStreamPlayer = $Audios/AudioPuertas
@onready var audio_meow: AudioStreamPlayer = $Audios/AudioMeow

var _transicion_iniciada: bool = false
var _paso_secuencia: int = 0

func _ready() -> void:
	if timer_secuencia:
		timer_secuencia.timeout.connect(_on_timer_secuencia_timeout)

	# Iniciar con la gata sentada con sus audífonos puestos escuchando música
	if gatita:
		gatita.shaded = false
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
			# Estado 1: Tren en movimiento
			_mostrar_texto("El suave y monótono vaivén del metro...")
			timer_secuencia.start(3.2)
		1:
			# Estado 2: Frenado y anuncio de llegada
			if audio_viaje:
				var tween_vol: Tween = create_tween()
				tween_vol.tween_property(audio_viaje, "volume_db", -28.0, 2.5)
			if audio_llegada:
				audio_llegada.play()
			_mostrar_texto("'¡Atención pasajeros: Próxima parada, Estación Terminal...'")
			timer_secuencia.start(3.6)
		2:
			# Estado 3: Sonido de puertas y fin de recorrido
			if audio_puertas:
				audio_puertas.play()
			_mostrar_texto("'Última estación. Fin del recorrido. Por favor, desciendan del metro '")
			timer_secuencia.start(3.2)
		3:
			# Estado 4: Gatita se despierta / reacciona confundida
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
			# Estado 6: Transición fluida a zona_b
			_transicionar_a_siguiente_escena()

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
