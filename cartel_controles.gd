class_name CartelControles
extends Node3D

@export var tamano_en_pantalla: float = 0.8
@export var pausar_juego: bool = true

@onready var etiqueta: Label3D = $Label3D
@onready var fondo_cartel: MeshInstance3D = $FondoCartel
@onready var area: Area3D = $AreaClic

var _capa: CanvasLayer = null
var _oscuro: ColorRect = null
var _cartel: Panel = null
var _abierto: bool = false
var _pausaba: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().physics_object_picking = true
	area.input_event.connect(_al_clic)
	area.mouse_entered.connect(Input.set_default_cursor_shape.bind(Input.CURSOR_POINTING_HAND))
	area.mouse_exited.connect(Input.set_default_cursor_shape.bind(Input.CURSOR_ARROW))


func _unhandled_input(evento: InputEvent) -> void:
	if _abierto and evento.is_action_pressed("ui_cancel"):
		cerrar()
		get_viewport().set_input_as_handled()


func _al_clic(_camara: Node, evento: InputEvent, _punto: Vector3, _normal: Vector3, _forma: int) -> void:
	if evento is InputEventMouseButton:
		var boton: InputEventMouseButton = evento as InputEventMouseButton
		if boton.pressed and boton.button_index == MOUSE_BUTTON_LEFT:
			abrir()


func abrir() -> void:
	if _abierto:
		return
	_abierto = true
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if pausar_juego:
		_pausaba = get_tree().paused
		get_tree().paused = true
	_construir()
	_oscuro.modulate.a = 0.0
	_cartel.modulate.a = 0.0
	_cartel.scale = Vector2(0.6, 0.6)
	var t: Tween = _capa.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_oscuro, "modulate:a", 1.0, 0.18)
	t.tween_property(_cartel, "modulate:a", 1.0, 0.18)
	t.tween_property(_cartel, "scale", Vector2.ONE, 0.25)


func cerrar() -> void:
	if not _abierto:
		return
	_abierto = false
	if pausar_juego:
		get_tree().paused = _pausaba
	var capa: CanvasLayer = _capa
	_capa = null
	var t: Tween = capa.create_tween().set_parallel(true)
	t.tween_property(_oscuro, "modulate:a", 0.0, 0.15)
	t.tween_property(_cartel, "modulate:a", 0.0, 0.15)
	t.tween_property(_cartel, "scale", Vector2(0.6, 0.6), 0.15)
	t.chain().tween_callback(capa.queue_free)


func _al_tocar_afuera(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and (evento as InputEventMouseButton).pressed:
		cerrar()


func _construir() -> void:
	_capa = CanvasLayer.new()
	_capa.layer = 10
	_capa.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_capa)

	var pantalla: Vector2 = get_viewport().get_visible_rect().size
	var malla: BoxMesh = fondo_cartel.mesh as BoxMesh
	var proporcion: float = malla.size.x / malla.size.y
	var alto: float = pantalla.y * tamano_en_pantalla
	var ancho: float = alto * proporcion
	if ancho > pantalla.x * 0.92:
		ancho = pantalla.x * 0.92
		alto = ancho / proporcion
	var px_por_metro: float = alto / malla.size.y

	_oscuro = ColorRect.new()
	_oscuro.color = Color(0.0, 0.0, 0.0, 0.55)
	_oscuro.size = pantalla
	_oscuro.mouse_filter = Control.MOUSE_FILTER_STOP
	_oscuro.gui_input.connect(_al_tocar_afuera)
	_capa.add_child(_oscuro)

	var material: StandardMaterial3D = fondo_cartel.material_override as StandardMaterial3D
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = material.albedo_color if material != null else Color(0.08, 0.1, 0.14)
	_cartel = Panel.new()
	_cartel.add_theme_stylebox_override("panel", estilo)
	_cartel.size = Vector2(ancho, alto)
	_cartel.position = (pantalla - _cartel.size) * 0.5
	_cartel.pivot_offset = _cartel.size * 0.5
	_cartel.mouse_filter = Control.MOUSE_FILTER_STOP
	_capa.add_child(_cartel)

	var texto: Label = Label.new()
	texto.text = etiqueta.text
	texto.size = _cartel.size
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.offset_top = etiqueta.position.y * -px_por_metro
	texto.offset_bottom = texto.offset_top + _cartel.size.y
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tamano: int = int(round(etiqueta.font_size * etiqueta.pixel_size * px_por_metro))
	texto.add_theme_font_override("font", etiqueta.font)
	texto.add_theme_font_size_override("font_size", tamano)
	texto.add_theme_color_override("font_color", _color_texto())
	texto.add_theme_color_override("font_outline_color", etiqueta.outline_modulate)
	texto.add_theme_constant_override("outline_size", int(round(etiqueta.outline_size * etiqueta.pixel_size * px_por_metro)))
	_cartel.add_child(texto)

	var x: Button = Button.new()
	x.text = "X"
	x.flat = true
	x.focus_mode = Control.FOCUS_NONE
	x.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	x.add_theme_font_override("font", etiqueta.font)
	x.add_theme_font_size_override("font_size", maxi(tamano, 18))
	x.add_theme_color_override("font_color", _color_texto())
	x.add_theme_color_override("font_hover_color", Color.WHITE)
	x.add_theme_color_override("font_outline_color", etiqueta.outline_modulate)
	x.add_theme_constant_override("outline_size", 4)
	x.size = Vector2(tamano * 1.8, tamano * 1.8)
	x.position = Vector2(_cartel.size.x - x.size.x - 6.0, 6.0)
	x.pressed.connect(cerrar)
	_cartel.add_child(x)


func _color_texto() -> Color:
	var m: Color = etiqueta.modulate
	var mayor: float = maxf(maxf(m.r, m.g), maxf(m.b, 0.001))
	return Color(m.r / mayor, m.g / mayor, m.b / mayor).lerp(Color.WHITE, 0.35)
