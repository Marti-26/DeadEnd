extends Node

@onready var metro: Metro = $"../MetroLlegada"
@onready var gata: Personaje = $"../Personaje"

func _ready() -> void:
	metro.camara_vagon.size = 7.8
	metro.camara_vagon.far = 80.0
	metro.distancia = 3.0
	metro.tiempo_frenado = 3.0
	metro.tiempo_detenido = 99999.0
	metro.sonido_llegada.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	metro.sonido_llegada.unit_size = 18.0
	metro.sonido_llegada.max_distance = 55.0
	metro.sonido_llegada.volume_db = -2.0
	metro.tren.position.x = metro.x_parada + metro.distancia
	metro._x_antes = metro.tren.position.x
	var lugar: Vector3 = Partida.get_meta("posicion_vagon_final", Vector3(0.0, 0.3, 0.0))
	if absf(lugar.x) > Metro.LARGO / 2.0 - 0.4 or absf(lugar.z) > Metro.ANCHO / 2.0 - 0.1:
		push_warning("Zona C: posicion original fuera del vagon: " + str(lugar))
	gata.global_position = metro.tren.to_global(lugar)
	gata.velocity = Vector3.ZERO
	Partida.remove_meta("posicion_vagon_final")
	print("Zona C: misma posicion dentro del vagon: ", lugar)
	metro._capas_plataforma = gata.platform_floor_layers
	gata.platform_floor_layers = 0
	gata.set_physics_process(false)
	metro.viajando = true
	metro.viaje_final_pendiente = false
	metro.cambiando_zona_c = false
	metro.llego.connect(_al_llegar)
	call_deferred("_mostrar_llegada")
	metro._entrar_vista()
	metro._cambiar(Metro.Estado.LLEGANDO)

func _al_llegar() -> void:
	gata.set_physics_process(true)
	print("Zona C: metro detenido, puertas abriendo. Sal por la puerta hacia el andén.")


func _mostrar_llegada() -> void:
	var capa: CanvasLayer = get_tree().root.get_node_or_null("TransicionMetroFinal") as CanvasLayer
	if capa == null:
		capa = CanvasLayer.new()
		capa.name = "TransicionMetroFinal"
		capa.layer = 120
		get_tree().root.add_child(capa)

	var negro: ColorRect = capa.get_node_or_null("Fondo") as ColorRect
	if negro == null:
		negro = ColorRect.new()
		negro.name = "Fondo"
		capa.add_child(negro)

	negro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	negro.color = Color.BLACK

	var animacion: Tween = create_tween()
	animacion.tween_interval(0.25)
	animacion.tween_property(negro, "color:a", 0.0, 1.6)
	animacion.tween_callback(capa.queue_free)
