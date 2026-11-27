class_name HUD
extends CanvasLayer

@onready var etiqueta_bateria: Label = $Contenedor/EtiquetaBateria as Label
@onready var barra_bateria: ProgressBar = $Contenedor/BarraBateria as ProgressBar
@onready var barra_estres: ProgressBar = $Contenedor/BarraEstres as ProgressBar

var _nodo_bateria: Node = null
var _nodo_jugador: Node = null
var _nodo_dash: Node = null
var _boton_celular: Button = null
var _icono_celular: Control = null
var _celular: CelularMapa = null
#variable para que no aparezca el hud si no tiene el celular
var indicadores_bloqueados: bool = false

func _enter_tree() -> void:
	add_to_group(Grupos.GRUPO_HUD)


func _ready() -> void:
	barra_bateria.min_value = 0.0
	barra_bateria.max_value = 100.0
	barra_bateria.value = 100.0
	barra_estres.min_value = 0.0
	barra_estres.max_value = 100.0
	barra_estres.value = 0.0
	_buscar_referencias()
	_actualizar_barras()
	_crear_celular()


func _process(_delta: float) -> void:
	if not is_instance_valid(_nodo_bateria) or not is_instance_valid(_nodo_jugador):
		_buscar_referencias()
	_actualizar_barras()
	_actualizar_boton_celular()


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
	_icono_celular = Control.new()
	_icono_celular.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icono_celular.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icono_celular.draw.connect(_dibujar_icono_celular)
	_boton_celular.add_child(_icono_celular)
	_boton_celular.mouse_entered.connect(_icono_celular.queue_redraw)
	_boton_celular.mouse_exited.connect(_icono_celular.queue_redraw)
	_celular.abierto_cambiado.connect(func(_esta_abierto: bool) -> void: _icono_celular.queue_redraw())


func _actualizar_boton_celular() -> void:
	if _boton_celular == null:
		return
	var tiene: bool = _tiene_celular()
	_boton_celular.visible = tiene
	if not tiene and _celular.abierto:
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
	else:
		_nodo_dash = null


func _actualizar_barras() -> void:
	if indicadores_bloqueados:
		return
	var tiene: bool = _tiene_celular()
	if etiqueta_bateria != null:
		etiqueta_bateria.visible = tiene
	if barra_bateria != null:
		barra_bateria.visible = tiene
	if tiene:
		barra_bateria.value = _leer_bateria()
	barra_estres.value = _leer_estres()


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
