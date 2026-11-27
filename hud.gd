class_name HUD
extends CanvasLayer

@onready var etiqueta_bateria: Label = $Contenedor/EtiquetaBateria as Label
@onready var barra_bateria: ProgressBar = $Contenedor/BarraBateria as ProgressBar
@onready var barra_estres: ProgressBar = $Contenedor/BarraEstres as ProgressBar
@onready var _aviso_metro: PanelContainer = $Contenedor/AvisoMetro
@onready var _tiempo_aviso_metro: Timer = $TiempoAvisoMetro

var _nodo_bateria: Node = null
var _nodo_jugador: Node = null
var _nodo_dash: Node = null
var _boton_celular: Button = null
var _icono_celular: Control = null
var _indicador_metro: Panel = null
var _celular: CelularMapa = null
var _nodo_interactuar: Interactuar = null
var _panel_interaccion: PanelContainer = null
var _label_interaccion: Label = null
var _barra_interaccion: ProgressBar = null
var _tiempo_efecto_carga: float = 0.0
var _tiempo_descarga: float = 0.0
#variable para que no aparezca el hud si no tiene el celular
var indicadores_bloqueados: bool = false

func _enter_tree() -> void:
	add_to_group(Grupos.GRUPO_HUD)


func _ready() -> void:
	barra_bateria.min_value = 0.0
	barra_bateria.max_value = 100.0
	barra_bateria.value = 100.0
	barra_bateria.custom_minimum_size = Vector2(390.0, 22.0)
	barra_bateria.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	barra_estres.min_value = 0.0
	barra_estres.max_value = 100.0
	barra_estres.value = 0.0
	barra_estres.custom_minimum_size = Vector2(390.0, 22.0)
	barra_estres.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	_buscar_referencias()
	_actualizar_barras()
	_crear_celular()
	_crear_panel_interaccion()
	$Contenedor/AvisoMetro/Mensaje.text = "Terminales activadas\n" + CelularMapa.AVISO_METRO
	Partida.viaje_zona_c_habilitado.connect(_mostrar_aviso_metro)


func _process(delta: float) -> void:
	if not is_instance_valid(_nodo_bateria) or not is_instance_valid(_nodo_jugador) or not is_instance_valid(_nodo_interactuar):
		_buscar_referencias()
	_actualizar_barras(delta)
	_actualizar_boton_celular()
	_actualizar_interaccion(delta)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed(&"alternar_mapa") and visible and _tiene_celular():
		_celular.alternar()
		get_viewport().set_input_as_handled()


func _crear_celular() -> void:
	_celular = CelularMapa.new()
	add_child(_celular)
	_boton_celular = Button.new()
	_boton_celular.flat = true
	_boton_celular.focus_mode = Control.FOCUS_NONE
	_boton_celular.custom_minimum_size = Vector2(46.0, 52.0)
	_boton_celular.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_boton_celular.tooltip_text = "Mapa (M)"
	_boton_celular.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_boton_celular.pressed.connect(_celular.alternar)
	$Contenedor.add_child(_boton_celular)
	$Contenedor.move_child(_boton_celular, _aviso_metro.get_index())
	_icono_celular = Control.new()
	_icono_celular.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icono_celular.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icono_celular.draw.connect(_dibujar_icono_celular)
	_boton_celular.add_child(_icono_celular)
	_boton_celular.mouse_entered.connect(_icono_celular.queue_redraw)
	_boton_celular.mouse_exited.connect(_icono_celular.queue_redraw)
	_celular.abierto_cambiado.connect(_al_alternar_celular)

	_indicador_metro = Panel.new()
	_indicador_metro.name = "IndicadorMetro"
	_indicador_metro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_indicador_metro.hide()
	_boton_celular.add_child(_indicador_metro)
	_indicador_metro.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_indicador_metro.offset_left = -14.0
	_indicador_metro.offset_right = -2.0
	_indicador_metro.offset_top = 2.0
	_indicador_metro.offset_bottom = 14.0
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.86, 0.12, 0.22)
	estilo.border_color = _celular.color_crema
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(6)
	_indicador_metro.add_theme_stylebox_override("panel", estilo)


func _mostrar_aviso_metro() -> void:
	if not visible or not _tiene_celular():
		return
	if _celular.abierto:
		Partida.aviso_metro_leido = true
		return
	_aviso_metro.show()
	_tiempo_aviso_metro.start()


func _al_alternar_celular(esta_abierto: bool) -> void:
	_icono_celular.queue_redraw()
	if esta_abierto:
		if Partida.terminales_completadas():
			Partida.aviso_metro_leido = true
		_aviso_metro.hide()
		_tiempo_aviso_metro.stop()


func _actualizar_boton_celular() -> void:
	if _boton_celular == null:
		return
	var tiene: bool = _tiene_celular()
	_boton_celular.visible = tiene
	var aviso_pendiente := tiene and Partida.terminales_completadas() and not Partida.aviso_metro_leido
	_indicador_metro.visible = aviso_pendiente
	_boton_celular.tooltip_text = CelularMapa.AVISO_METRO + " · Mapa (M)" if aviso_pendiente else "Mapa (M)"
	if not tiene:
		_aviso_metro.hide()
		if _celular.abierto:
			_celular.cerrar()


func _tiene_celular() -> bool:
	if is_instance_valid(_nodo_jugador) and "tiene_celular" in _nodo_jugador:
		return bool(_nodo_jugador.get("tiene_celular"))
	return Partida != null and Partida.celular_recogido


func _dibujar_icono_celular() -> void:
	var encima: bool = _boton_celular.is_hovered() or _celular.abierto
	var escala: float = 1.08 if encima else 1.0
	var tam: Vector2 = Vector2(26.0, 44.0) * escala
	var origen: Vector2 = (_icono_celular.size - tam) * 0.5
	var cuerpo: StyleBoxFlat = StyleBoxFlat.new()
	cuerpo.bg_color = _celular.color_rosa
	cuerpo.border_color = _celular.color_rosa_fuerte
	cuerpo.set_border_width_all(2)
	cuerpo.set_corner_radius_all(7)
	cuerpo.anti_aliasing = true
	_icono_celular.draw_style_box(cuerpo, Rect2(origen, tam))
	var pantalla: StyleBoxFlat = StyleBoxFlat.new()
	pantalla.bg_color = _celular.color_crema if encima else _celular.color_crema.darkened(0.08)
	pantalla.set_corner_radius_all(4)
	pantalla.anti_aliasing = true
	_icono_celular.draw_style_box(pantalla, Rect2(origen + Vector2(4.0, 5.0) * escala, tam - Vector2(8.0, 10.0) * escala))
	var centro: Vector2 = origen + tam * 0.5
	_icono_celular.draw_circle(centro + Vector2(0.0, -2.0) * escala, 4.0 * escala, _celular.color_rosa_fuerte)
	_icono_celular.draw_colored_polygon(PackedVector2Array([centro + Vector2(-3.5, 0.0) * escala, centro + Vector2(3.5, 0.0) * escala, centro + Vector2(0.0, 7.0) * escala]), _celular.color_rosa_fuerte)
	_icono_celular.draw_circle(centro + Vector2(0.0, -2.0) * escala, 1.6 * escala, _celular.color_crema)
	var hilo: Vector2 = origen + Vector2(0.0, 12.0) * escala
	_icono_celular.draw_line(hilo, hilo + Vector2(-6.0, 12.0), _celular.color_rosa_fuerte, 1.5, true)
	_icono_celular.draw_circle(hilo + Vector2(-6.0, 15.0), 3.5, Color(0.12, 0.08, 0.1))
	_icono_celular.draw_circle(hilo + Vector2(-7.2, 14.5), 0.9, _celular.color_marcador)
	_icono_celular.draw_circle(hilo + Vector2(-4.8, 14.5), 0.9, _celular.color_marcador)


func _buscar_referencias() -> void:
	_nodo_jugador = get_tree().get_first_node_in_group(Grupos.JUGADOR)
	_nodo_bateria = get_tree().get_first_node_in_group(Grupos.BATERIA)
	if is_instance_valid(_nodo_jugador):
		_nodo_dash = _nodo_jugador.get_node_or_null("Dash")
		_nodo_interactuar = _nodo_jugador.get_node_or_null("Interactuar") as Interactuar
	else:
		_nodo_dash = null
		_nodo_interactuar = null


func _actualizar_barras(delta: float = 0.0) -> void:
	if indicadores_bloqueados:
		return
	var tiene: bool = _tiene_celular()
	if etiqueta_bateria != null:
		etiqueta_bateria.visible = tiene
	if barra_bateria != null:
		barra_bateria.visible = tiene
	if tiene:
		var bat: float = _leer_bateria()
		barra_bateria.value = bat
		_actualizar_indicador_descarga(bat, delta)
	barra_estres.value = _leer_estres()


func _actualizar_indicador_descarga(bat: float, delta: float) -> void:
	if etiqueta_bateria == null:
		return

	_tiempo_descarga += delta

	var esta_cargando: bool = is_instance_valid(_nodo_interactuar) and _nodo_interactuar.actual is EstacionCarga and _nodo_interactuar.progreso > 0.01

	if esta_cargando:
		etiqueta_bateria.text = "BATERÍA CELULAR (CARGANDO)"
		etiqueta_bateria.modulate = Color(1.0, 0.95, 0.5)
		return

	if bat <= 0.0:
		etiqueta_bateria.text = "BATERÍA CELULAR (AGOTADA)"
		etiqueta_bateria.modulate = Color(0.6, 0.6, 0.6)
		if barra_bateria != null:
			barra_bateria.modulate = Color(0.5, 0.5, 0.5)
		return

	# Detectar causas de consumo
	var linterna_on: bool = is_instance_valid(_nodo_jugador) and bool(_nodo_jugador.get("linterna_encendida"))
	var audifonos_on: bool = is_instance_valid(_nodo_jugador) and bool(_nodo_jugador.get("audifonos_activos"))
	var mapa_on: bool = _celular != null and _celular.abierto

	var consumo_alto: bool = linterna_on or audifonos_on or mapa_on
	var flechas: String = "▼▼" if consumo_alto else "▼"

	var sufijo: String = ""
	if linterna_on and audifonos_on:
		sufijo = " [LINTERNA + AUDÍFONOS]"
	elif linterna_on:
		sufijo = " [LINTERNA]"
	elif audifonos_on:
		sufijo = " [AUDÍFONOS]"
	elif mapa_on:
		sufijo = " [MAPA]"

	# Si la batería está crítica (< 20%), alertar al jugador
	if bat <= 20.0:
		var pulso_alerta: float = (sin(_tiempo_descarga * 6.0) + 1.0) * 0.5
		var color_rojo: Color = Color(1.3, 0.35, 0.35).lerp(Color(1.0, 0.8, 0.8), pulso_alerta)
		etiqueta_bateria.text = "BATERÍA CELULAR %s (BAJA)%s" % [flechas, sufijo]
		etiqueta_bateria.modulate = color_rojo
		if barra_bateria != null:
			barra_bateria.modulate = color_rojo
	elif bat <= 50.0:
		etiqueta_bateria.text = "BATERÍA CELULAR %s%s" % [flechas, sufijo]
		etiqueta_bateria.modulate = Color(1.15, 0.95, 0.5)
		if barra_bateria != null:
			barra_bateria.modulate = Color(1.15, 0.95, 0.5)
	else:
		etiqueta_bateria.text = "BATERÍA CELULAR %s%s" % [flechas, sufijo]
		etiqueta_bateria.modulate = Color.WHITE
		if barra_bateria != null:
			barra_bateria.modulate = Color.WHITE


func _leer_bateria() -> float:
	if Partida != null and Partida.bateria >= 0.0:
		return clampf(Partida.bateria, 0.0, 100.0)
	if is_instance_valid(_nodo_jugador) and "bateria" in _nodo_jugador:
		return clampf(float(_nodo_jugador.get("bateria")), 0.0, 100.0)
	if is_instance_valid(_nodo_bateria) and "bateria" in _nodo_bateria:
		return clampf(float(_nodo_bateria.get("bateria")), 0.0, 100.0)
	return 100.0


func _leer_estres() -> float:
	if Partida != null:
		return clampf(Partida.estres, 0.0, 100.0)
	if is_instance_valid(_nodo_jugador) and "estres" in _nodo_jugador:
		return clampf(float(_nodo_jugador.get("estres")), 0.0, 100.0)
	if is_instance_valid(_nodo_bateria) and "estres" in _nodo_bateria:
		return clampf(float(_nodo_bateria.get("estres")), 0.0, 100.0)
	if is_instance_valid(_nodo_dash) and "estres" in _nodo_dash:
		return clampf(float(_nodo_dash.get("estres")), 0.0, 100.0)
	return 0.0


func _crear_panel_interaccion() -> void:
	_panel_interaccion = PanelContainer.new()
	_panel_interaccion.name = "PanelInteraccion"
	_panel_interaccion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_interaccion.set_anchors_preset(Control.PRESET_CENTER)
	_panel_interaccion.offset_left = -160.0
	_panel_interaccion.offset_right = 160.0
	_panel_interaccion.offset_top = 80.0
	_panel_interaccion.offset_bottom = 145.0

	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = Color(0.04, 0.06, 0.08, 0.88)
	estilo.border_color = Color(0.3, 0.85, 0.75, 1.0)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(8)
	estilo.content_margin_left = 12.0
	estilo.content_margin_right = 12.0
	estilo.content_margin_top = 8.0
	estilo.content_margin_bottom = 8.0
	_panel_interaccion.add_theme_stylebox_override("panel", estilo)
	if $Contenedor.theme != null:
		_panel_interaccion.theme = $Contenedor.theme

	var columna: VBoxContainer = VBoxContainer.new()
	columna.add_theme_constant_override("separation", 6)
	_panel_interaccion.add_child(columna)

	_label_interaccion = Label.new()
	_label_interaccion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_interaccion.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	_label_interaccion.add_theme_font_size_override("font_size", 16)
	columna.add_child(_label_interaccion)

	_barra_interaccion = ProgressBar.new()
	_barra_interaccion.min_value = 0.0
	_barra_interaccion.max_value = 100.0
	_barra_interaccion.show_percentage = false
	_barra_interaccion.custom_minimum_size = Vector2(280.0, 12.0)

	var fondo_barra: StyleBoxFlat = StyleBoxFlat.new()
	fondo_barra.bg_color = Color(0.12, 0.15, 0.18, 0.9)
	fondo_barra.set_corner_radius_all(5)

	var relleno_barra: StyleBoxFlat = StyleBoxFlat.new()
	relleno_barra.bg_color = Color(0.45, 0.85, 0.69, 1.0)
	relleno_barra.set_corner_radius_all(5)

	_barra_interaccion.add_theme_stylebox_override("background", fondo_barra)
	_barra_interaccion.add_theme_stylebox_override("fill", relleno_barra)
	columna.add_child(_barra_interaccion)

	_panel_interaccion.visible = false
	add_child(_panel_interaccion)


func _actualizar_interaccion(delta: float) -> void:
	if _panel_interaccion == null:
		return

	if not is_instance_valid(_nodo_interactuar):
		_panel_interaccion.visible = false
		if barra_bateria != null and barra_bateria.modulate != Color.WHITE:
			barra_bateria.modulate = Color.WHITE
		return

	var progreso: float = _nodo_interactuar.progreso
	var cargando: bool = progreso > 0.01 and _nodo_interactuar.actual != null

	if cargando:
		var porcentaje: int = int(round(clampf(progreso, 0.0, 1.0) * 100.0))
		var obj: Node = _nodo_interactuar.actual
		if obj is EstacionCarga:
			_label_interaccion.text = "Cargando celular... %d%%" % porcentaje
			# Pulso dorado/verde en la barra de batería del HUD
			_tiempo_efecto_carga += delta * 8.0
			var pulso: float = (sin(_tiempo_efecto_carga) + 1.0) * 0.5
			if barra_bateria != null:
				barra_bateria.modulate = Color.WHITE.lerp(Color(1.6, 1.4, 0.4), pulso)
		else:
			_label_interaccion.text = "Interactuando... %d%%" % porcentaje
			if barra_bateria != null and barra_bateria.modulate != Color.WHITE:
				barra_bateria.modulate = Color.WHITE

		_barra_interaccion.value = float(porcentaje)
		_barra_interaccion.visible = true
		_panel_interaccion.visible = true
		return

	# Si no está en progreso, restaurar color de la batería
	if barra_bateria != null and barra_bateria.modulate != Color.WHITE:
		barra_bateria.modulate = Color.WHITE

	# Revisar si está cerca de algún objeto interactivo
	var obj_cercano: Node = _nodo_interactuar.cercano
	if obj_cercano != null and is_instance_valid(obj_cercano):
		if obj_cercano is EstacionCarga:
			if _tiene_celular():
				var estacion_agotada: bool = ("usada" in obj_cercano and bool(obj_cercano.get("usada"))) or (Partida != null and Partida.estacion_usada)
				if estacion_agotada:
					_label_interaccion.text = "Sin energía"
					_barra_interaccion.visible = false
					_panel_interaccion.visible = true
					return
				elif _leer_bateria() >= 100.0:
					_label_interaccion.text = "Batería al 100%"
					_barra_interaccion.visible = false
					_panel_interaccion.visible = true
					return
				else:
					_label_interaccion.text = "[Mantén E] Cargar celular"
					_barra_interaccion.visible = false
					_panel_interaccion.visible = true
					return
		elif "activada" in obj_cercano and not bool(obj_cercano.get("activada")):
			_label_interaccion.text = "[Mantén E] Activar terminal"
			_barra_interaccion.visible = false
			_panel_interaccion.visible = true
			return

	_panel_interaccion.visible = false
