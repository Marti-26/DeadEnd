extends Control

@export_file("*.tscn") var destino: String = "res://zona_b.tscn"
@export var duracion_minima: float = 5.0
@export var ancho: float = 300.0
@export var alto: float = 580.0
@export var color_crema: Color = Color(0.984, 0.945, 0.902)
@export var color_rosa: Color = Color(0.969, 0.714, 0.784)
@export var color_rosa_medio: Color = Color(0.933, 0.498, 0.639)
@export var color_rosa_fuerte: Color = Color(0.847, 0.263, 0.435)
@export var color_vino: Color = Color(0.42, 0.08, 0.2)
@export var color_pantalla: Color = Color(0.11, 0.05, 0.09)
@export var color_aviso: Color = Color(0.24, 0.09, 0.17)
@export var color_marcador: Color = Color(1.0, 0.68, 0.32)

const FUENTE: FontFile = preload("res://assets/font/ShareTechMono-Regular.ttf")
const SIMBOLOS: String = "#%&@$?!*/\\|<>~^=+"
const HORAS_RARAS: Array[String] = ["03:33", "00:00", "13:13", "--:--", "88:88", "25:61", "??:??", "04:04"]
const FECHAS_RARAS: Array[String] = ["00/00/0000", "31/02/19??", "??/??/????", "13/13/1313", "--/--/----"]

var _telefono: Control
var _pantalla: Panel
var _hora: Label
var _fecha: Label
var _relleno: Panel
var _texto_carga: Label
var _charm: Control
var _negro: ColorRect
var _aviso_1: Panel
var _aviso_2: Panel
var _quien_2: Label
var _mensaje_2: Label
var _ancho_bateria: float = 0.0
var _tiempo: float = 0.0
var _progreso: float = 0.0
var _mostrado: float = 0.0
var _siguiente_glitch: float = 0.0
var _congelado: float = 0.0
var _glitch_aviso: float = 0.0
var _hora_x: float = 0.0
var _salio_1: bool = false
var _salio_2: bool = false
var _saliendo: bool = false


func _ready() -> void:
	_construir()
	_reubicar()
	get_viewport().size_changed.connect(_reubicar)
	if destino != "":
		ResourceLoader.load_threaded_request(destino)
	_negro.color.a = 1.0
	create_tween().tween_property(_negro, "color:a", 0.0, 0.6)


func _process(delta: float) -> void:
	_tiempo += delta
	_actualizar_carga()
	var meta: float = minf(_progreso, _tiempo / duracion_minima)
	_mostrado = move_toward(_mostrado, meta, delta * 0.45)
	_relleno.size.x = maxf(2.0, _ancho_bateria * _mostrado)
	_texto_carga.text = "cargando %d%%" % int(round(_mostrado * 100.0)) if _mostrado < 0.999 else "cargado"
	_glitch_reloj(delta)
	if not _salio_1 and _mostrado > 0.18:
		_salio_1 = true
		_mostrar_aviso(_aviso_1)
	if not _salio_2 and _mostrado > 0.8:
		_salio_2 = true
		_mostrar_aviso(_aviso_2)
	if _salio_2:
		_glitch_segundo_aviso(delta)
	_charm.rotation = sin(_tiempo * 1.7) * 0.06
	if _mostrado >= 0.999 and _progreso >= 1.0 and not _saliendo:
		_salir()


func _actualizar_carga() -> void:
	if destino == "":
		_progreso = 1.0
		return
	var avance: Array = []
	var estado: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(destino, avance)
	match estado:
		ResourceLoader.THREAD_LOAD_LOADED:
			_progreso = 1.0
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if not avance.is_empty():
				_progreso = float(avance[0])
		_:
			_progreso = 1.0


func _salir() -> void:
	_saliendo = true
	await get_tree().create_timer(0.8).timeout
	var t: Tween = create_tween()
	t.tween_property(_negro, "color:a", 1.0, 0.7)
	await t.finished
	var escena: PackedScene = ResourceLoader.load_threaded_get(destino) as PackedScene
	if escena != null:
		get_tree().change_scene_to_packed(escena)
	else:
		get_tree().change_scene_to_file(destino)


func _mostrar_aviso(aviso: Panel) -> void:
	aviso.visible = true
	var destino_y: float = aviso.position.y
	aviso.position.y -= 18.0
	aviso.modulate.a = 0.0
	var t: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(aviso, "position:y", destino_y, 0.35)
	t.tween_property(aviso, "modulate:a", 1.0, 0.35)
	_vibrar()


func _vibrar() -> void:
	var t: Tween = create_tween()
	for i: int in 6:
		var lado: float = 1.0 if i % 2 == 0 else -1.0
		t.tween_property(_telefono, "rotation", lado * 0.025, 0.045)
	t.tween_property(_telefono, "rotation", 0.0, 0.06)


func _glitch_segundo_aviso(delta: float) -> void:
	_glitch_aviso -= delta
	if _glitch_aviso > 0.0:
		return
	_glitch_aviso = randf_range(0.05, 0.18)
	_quien_2.text = _corromper("mamá", 0.35)
	_mensaje_2.text = _corromper("llamada perdida", 0.18)
	_aviso_2.modulate.a = 0.55 if randf() < 0.12 else 1.0
	_aviso_2.position.x = 14.0 + (randf_range(-3.0, 3.0) if randf() < 0.2 else 0.0)


func _glitch_reloj(delta: float) -> void:
	if _congelado > 0.0:
		_congelado -= delta
		return
	_siguiente_glitch -= delta
	if _siguiente_glitch > 0.0:
		return
	_siguiente_glitch = randf_range(0.06, 0.14)
	if randf() < 0.07:
		_congelado = randf_range(0.25, 0.7)
		var real: bool = randf() < 0.4
		_hora.text = _hora_real() if real else HORAS_RARAS.pick_random()
		_fecha.text = _fecha_real() if real else FECHAS_RARAS.pick_random()
	else:
		_hora.text = _corromper(_hora_real(), 0.5)
		_fecha.text = _corromper(_fecha_real(), 0.4)
	_hora.position.x = _hora_x + randf_range(-1.5, 1.5)
	_hora.add_theme_color_override("font_color", color_rosa_fuerte if randf() < 0.15 else color_crema)


func _hora_real() -> String:
	var t: Dictionary = Time.get_time_dict_from_system()
	return "%02d:%02d" % [int(t.hour), int(t.minute)]


func _fecha_real() -> String:
	var f: Dictionary = Time.get_date_dict_from_system()
	return "%02d/%02d/%04d" % [int(f.day), int(f.month), int(f.year)]


func _corromper(texto: String, probabilidad: float) -> String:
	var salida: String = ""
	for c: String in texto:
		var separador: bool = c == ":" or c == "/" or c == " "
		if randf() < (probabilidad * 0.3 if separador else probabilidad):
			salida += SIMBOLOS[randi() % SIMBOLOS.length()]
		else:
			salida += c
	return salida


func _reubicar() -> void:
	var pantalla: Vector2 = get_viewport_rect().size
	var escala: float = minf(1.0, pantalla.y * 0.86 / alto)
	_telefono.scale = Vector2(escala, escala)
	_telefono.position = (pantalla - Vector2(ancho, alto)) * 0.5


func _estilo(fondo: Color, borde: Color = Color.TRANSPARENT, grosor: int = 0, radio: int = 0) -> StyleBoxFlat:
	var e: StyleBoxFlat = StyleBoxFlat.new()
	e.bg_color = fondo
	e.border_color = borde
	e.set_border_width_all(grosor)
	e.set_corner_radius_all(radio)
	e.anti_aliasing = true
	return e


func _panel(padre: Control, estilo: StyleBoxFlat, pos: Vector2, tam: Vector2) -> Panel:
	var p: Panel = Panel.new()
	p.add_theme_stylebox_override("panel", estilo)
	p.position = pos
	p.size = tam
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(p)
	return p


func _etiqueta(padre: Control, texto: String, tam_fuente: int, color: Color, pos: Vector2, tam: Vector2, alineacion: HorizontalAlignment) -> Label:
	var l: Label = Label.new()
	l.text = texto
	l.position = pos
	l.size = tam
	l.horizontal_alignment = alineacion
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FUENTE)
	l.add_theme_font_size_override("font_size", tam_fuente)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_constant_override("shadow_outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(l)
	return l


func _aviso(pos_y: float, quien: String, mensaje: String, cuando: String, rojo: bool) -> Panel:
	var ancho_p: float = _pantalla.size.x
	var fondo: Color = Color(0.3, 0.03, 0.08) if rojo else color_aviso
	var borde: Color = color_rosa_fuerte if rojo else Color(color_rosa_medio, 0.35)
	var aviso: Panel = _panel(_pantalla, _estilo(fondo, borde, 1, 12), Vector2(14.0, pos_y), Vector2(ancho_p - 28.0, 64.0))
	_panel(aviso, _estilo(color_rosa_fuerte if rojo else color_rosa_medio, Color.TRANSPARENT, 0, 6), Vector2(12.0, 12.0), Vector2(18.0, 18.0))
	var l_quien: Label = _etiqueta(aviso, quien, 14, color_rosa if not rojo else color_rosa_medio, Vector2(38.0, 9.0), Vector2(140.0, 22.0), HORIZONTAL_ALIGNMENT_LEFT)
	_etiqueta(aviso, cuando, 11, Color(color_rosa_medio, 0.7), Vector2(aviso.size.x - 92.0, 9.0), Vector2(80.0, 22.0), HORIZONTAL_ALIGNMENT_RIGHT)
	var l_mensaje: Label = _etiqueta(aviso, mensaje, 15, color_crema, Vector2(12.0, 34.0), Vector2(aviso.size.x - 24.0, 22.0), HORIZONTAL_ALIGNMENT_LEFT)
	aviso.visible = false
	if rojo:
		_quien_2 = l_quien
		_mensaje_2 = l_mensaje
	return aviso


func _construir() -> void:
	var fondo: ColorRect = ColorRect.new()
	fondo.color = Color(0.03, 0.02, 0.04)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	_telefono = Control.new()
	_telefono.size = Vector2(ancho, alto)
	_telefono.pivot_offset = Vector2(ancho, alto) * 0.5
	add_child(_telefono)

	var boton: StyleBoxFlat = _estilo(color_rosa_fuerte, Color.TRANSPARENT, 0, 3)
	_panel(_telefono, boton, Vector2(-5.0, 120.0), Vector2(8.0, 46.0))
	_panel(_telefono, boton, Vector2(-5.0, 176.0), Vector2(8.0, 46.0))
	_panel(_telefono, boton, Vector2(ancho - 3.0, 150.0), Vector2(8.0, 68.0))

	var cuerpo: StyleBoxFlat = _estilo(color_rosa, color_rosa_fuerte, 4, 42)
	cuerpo.shadow_color = Color(0.5, 0.05, 0.2, 0.25)
	cuerpo.shadow_size = 30
	_panel(_telefono, cuerpo, Vector2.ZERO, Vector2(ancho, alto))

	_pantalla = _panel(_telefono, _estilo(color_pantalla, color_rosa_medio, 2, 30), Vector2(14.0, 14.0), Vector2(ancho - 28.0, alto - 28.0))
	var ancho_p: float = _pantalla.size.x
	var alto_p: float = _pantalla.size.y

	_panel(_pantalla, _estilo(Color(0.02, 0.01, 0.02), Color.TRANSPARENT, 0, 10), Vector2(ancho_p * 0.5 - 42.0, 10.0), Vector2(84.0, 22.0))
	_hora = _etiqueta(_pantalla, "00:00", 60, color_crema, Vector2(0.0, 60.0), Vector2(ancho_p, 70.0), HORIZONTAL_ALIGNMENT_CENTER)
	_fecha = _etiqueta(_pantalla, "00/00/0000", 15, color_rosa_medio, Vector2(0.0, 128.0), Vector2(ancho_p, 22.0), HORIZONTAL_ALIGNMENT_CENTER)
	_hora_x = _hora.position.x

	_aviso_1 = _aviso(190.0, "mamá", "¿ya llegaste?", "hace 2 h", false)
	_aviso_2 = _aviso(266.0, "mamá", "llamada perdida", "ahora", true)

	var x_bat: float = ancho_p * 0.5 - 42.0
	var y_bat: float = alto_p - 92.0
	_panel(_pantalla, _estilo(Color.TRANSPARENT, color_crema, 2, 5), Vector2(x_bat, y_bat), Vector2(78.0, 32.0))
	_panel(_pantalla, _estilo(color_crema, Color.TRANSPARENT, 0, 2), Vector2(x_bat + 79.0, y_bat + 10.0), Vector2(6.0, 12.0))
	_ancho_bateria = 70.0
	_relleno = _panel(_pantalla, _estilo(Color(0.36, 0.79, 0.65), Color.TRANSPARENT, 0, 3), Vector2(x_bat + 4.0, y_bat + 4.0), Vector2(2.0, 24.0))
	_texto_carga = _etiqueta(_pantalla, "cargando 0%", 14, color_rosa_medio, Vector2(0.0, y_bat + 38.0), Vector2(ancho_p, 22.0), HORIZONTAL_ALIGNMENT_CENTER)
	_panel(_pantalla, _estilo(Color(color_rosa_medio, 0.6), Color.TRANSPARENT, 0, 3), Vector2(ancho_p * 0.5 - 50.0, alto_p - 18.0), Vector2(100.0, 5.0))

	_charm = Control.new()
	_charm.position = Vector2(-3.0, 100.0)
	_charm.draw.connect(_dibujar_charm)
	_telefono.add_child(_charm)
	_telefono.move_child(_charm, 0)

	_negro = ColorRect.new()
	_negro.color = Color(0.0, 0.0, 0.0, 1.0)
	_negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_negro)


func _dibujar_charm() -> void:
	var negro: Color = Color(0.12, 0.08, 0.1)
	var cordon: PackedVector2Array = PackedVector2Array()
	for i: int in 13:
		var k: float = float(i) / 12.0
		cordon.append(Vector2(-sin(k * PI) * 10.0 - k * 6.0, k * 74.0))
	_charm.draw_polyline(cordon, color_rosa_fuerte, 2.0, true)
	_charm.draw_circle(Vector2.ZERO, 3.0, color_rosa_fuerte)
	var centro: Vector2 = Vector2(-8.0, 92.0)
	_charm.draw_circle(centro + Vector2(0.0, -17.0), 4.0, color_rosa_fuerte)
	_charm.draw_circle(centro + Vector2(0.0, -17.0), 2.0, color_crema)
	_charm.draw_colored_polygon(PackedVector2Array([centro + Vector2(-15.0, -6.0), centro + Vector2(-12.0, -24.0), centro + Vector2(-3.0, -12.0)]), negro)
	_charm.draw_colored_polygon(PackedVector2Array([centro + Vector2(15.0, -6.0), centro + Vector2(12.0, -24.0), centro + Vector2(3.0, -12.0)]), negro)
	_charm.draw_colored_polygon(PackedVector2Array([centro + Vector2(-12.0, -9.0), centro + Vector2(-11.0, -19.0), centro + Vector2(-6.0, -12.0)]), color_rosa_medio)
	_charm.draw_colored_polygon(PackedVector2Array([centro + Vector2(12.0, -9.0), centro + Vector2(11.0, -19.0), centro + Vector2(6.0, -12.0)]), color_rosa_medio)
	_charm.draw_circle(centro, 15.0, negro)
	_charm.draw_circle(centro + Vector2(-5.5, -1.0), 3.6, color_marcador)
	_charm.draw_circle(centro + Vector2(5.5, -1.0), 3.6, color_marcador)
	_charm.draw_circle(centro + Vector2(-5.5, -1.0), 1.4, negro)
	_charm.draw_circle(centro + Vector2(5.5, -1.0), 1.4, negro)
	_charm.draw_circle(centro + Vector2(-9.5, 5.0), 2.4, Color(color_rosa_medio, 0.8))
	_charm.draw_circle(centro + Vector2(9.5, 5.0), 2.4, Color(color_rosa_medio, 0.8))
	_charm.draw_line(centro + Vector2(-2.0, 6.0), centro + Vector2(0.0, 7.5), color_rosa, 1.5)
	_charm.draw_line(centro + Vector2(0.0, 7.5), centro + Vector2(2.0, 6.0), color_rosa, 1.5)
	var estrella: PackedVector2Array = PackedVector2Array()
	var centro_estrella: Vector2 = centro + Vector2(17.0, 14.0)
	for i: int in 10:
		var radio: float = 7.0 if i % 2 == 0 else 3.0
		var ang: float = -PI * 0.5 + float(i) * PI / 5.0
		estrella.append(centro_estrella + Vector2(cos(ang), sin(ang)) * radio)
	_charm.draw_colored_polygon(estrella, color_rosa_medio)
	_charm.draw_polyline(estrella + PackedVector2Array([estrella[0]]), color_rosa_fuerte, 1.0, true)
