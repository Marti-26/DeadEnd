extends Node

const FUENTE_MENU: FontFile = preload("res://assets/font/Silkscreen/Silkscreen-Regular.ttf")
const FUENTE_FLECHA: FontFile = preload("res://assets/font/DeadEndPixel.ttf")
const ESCENA_JUEGO: String = "res://main.tscn"
const SIMBOLOS: String = "#%&@$?!*/\\|<>~^=+"
const TITULO: String = "DEAD END"
const ALTO_BASE: float = 648.0
const X_TITULO: float = 96.0
const Y_TITULO: float = 185.0
const Y_OPCION: float = 318.0
const X_ICONO: float = 112.0
const X_DIVISOR: float = 166.0
const X_TEXTO: float = 192.0
const TEXTO: Color = Color(0.78, 0.95, 1.0)
const TEXTO_TENUE: Color = Color(0.5, 0.72, 0.82)
const BRILLO_CIAN: Color = Color(0.25, 0.85, 1.0)
const AMBAR: Color = Color(1.0, 0.68, 0.36)
const VERDE: Color = Color(0.45, 1.0, 0.58)

@onready var fondo: FondoMenu = $Fondo
@onready var ambiente: AudioStreamPlayer = $Ambiente
@onready var sonido_puertas: AudioStreamPlayer = $Puertas
@onready var sonido_clic: AudioStreamPlayer = $Clic

var _fuente_menu: FontVariation
var _fuente_flecha: FontVariation
var _contenido: Control
var _velo: TextureRect
var _titulo: Label
var _icono: Control
var _trazos: Array[Line2D] = []
var _puntos: Array[Panel] = []
var _estilos_punto: Array[StyleBoxFlat] = []
var _divisor: ColorRect
var _jugar: Button
var _subrayado: ColorRect
var _flecha: Label
var _negro: ColorRect
var _escala: float = 1.0
var _mezcla: float = 0.0
var _brillo: float = 1.0
var _glitch: float = 0.0
var _enfocado: bool = false
var _silencio: bool = true
var _saliendo: bool = false


func _ready() -> void:
	ambiente.finished.connect(ambiente.play)
	_fuente_menu = _fuente(FUENTE_MENU, 2.0)
	_fuente_flecha = _fuente(FUENTE_FLECHA, 0.0)
	_construir()
	get_viewport().size_changed.connect(_reubicar)
	_reubicar()
	_entrada()


func _process(delta: float) -> void:
	var dead: bool = fondo.es_dead_end()
	_mezcla = move_toward(_mezcla, 1.0 if dead else 0.0, delta * 2.0)
	var esperado: float = 0.314 if dead else 1.0
	var objetivo: float = clampf(fondo.intensidad_luz() / esperado, 0.0, 1.0)
	_brillo = lerpf(_brillo, objetivo, minf(1.0, delta * 30.0))
	_pintar()
	_animar_titulo(delta)


func _unhandled_input(evento: InputEvent) -> void:
	if _saliendo:
		return
	if evento.is_action_pressed("ui_accept") and not _jugar.has_focus():
		_jugar.grab_focus()
		get_viewport().set_input_as_handled()


func _fuente(original: FontFile, espacio: float) -> FontVariation:
	var nitida: FontFile = original.duplicate() as FontFile
	nitida.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	nitida.hinting = TextServer.HINTING_NONE
	nitida.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	var variacion: FontVariation = FontVariation.new()
	variacion.base_font = nitida
	variacion.spacing_glyph = int(espacio)
	return variacion


func _construir() -> void:
	var capa: CanvasLayer = CanvasLayer.new()
	capa.layer = 1
	add_child(capa)

	var degradado: Gradient = Gradient.new()
	degradado.set_color(0, Color(0.0, 0.03, 0.05, 0.62))
	degradado.set_color(1, Color(0.0, 0.03, 0.05, 0.0))
	var textura: GradientTexture2D = GradientTexture2D.new()
	textura.gradient = degradado
	textura.fill_from = Vector2(0.0, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	textura.width = 256
	textura.height = 4
	_velo = TextureRect.new()
	_velo.texture = textura
	_velo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_velo.stretch_mode = TextureRect.STRETCH_SCALE
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(_velo)

	_contenido = Control.new()
	_contenido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(_contenido)

	_titulo = _etiqueta(TITULO, _fuente_menu, 64, TEXTO)
	_titulo.add_theme_constant_override("shadow_outline_size", 0)
	_titulo.position = Vector2(X_TITULO, Y_TITULO)
	_contenido.add_child(_titulo)

	_icono = Control.new()
	_icono.size = Vector2(36.0, 36.0)
	_icono.pivot_offset = _icono.size * 0.5
	_icono.position = Vector2(X_ICONO, Y_OPCION - 18.0)
	_icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contenido.add_child(_icono)
	var paradas: Array[Vector2] = [Vector2(5.0, 29.0), Vector2(15.0, 15.0), Vector2(31.0, 8.0)]
	for k: int in paradas.size() - 1:
		var trazo: Line2D = Line2D.new()
		trazo.points = PackedVector2Array([paradas[k], paradas[k + 1]])
		trazo.width = 1.5
		trazo.antialiased = true
		_icono.add_child(trazo)
		_trazos.append(trazo)
	for p: Vector2 in paradas:
		var estilo: StyleBoxFlat = StyleBoxFlat.new()
		estilo.set_corner_radius_all(4)
		estilo.anti_aliasing = true
		var punto: Panel = Panel.new()
		punto.add_theme_stylebox_override("panel", estilo)
		punto.size = Vector2(6.0, 6.0)
		punto.position = p - punto.size * 0.5
		punto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_icono.add_child(punto)
		_puntos.append(punto)
		_estilos_punto.append(estilo)

	_divisor = ColorRect.new()
	_divisor.position = Vector2(X_DIVISOR, Y_OPCION - 46.0)
	_divisor.size = Vector2(1.0, 92.0)
	_divisor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contenido.add_child(_divisor)

	_jugar = Button.new()
	_jugar.text = "JUGAR"
	_jugar.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_jugar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_jugar.add_theme_font_override("font", _fuente_menu)
	_jugar.add_theme_font_size_override("font_size", 32)
	for estado: String in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		_jugar.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
	_jugar.add_theme_color_override("font_color", TEXTO_TENUE)
	_jugar.add_theme_color_override("font_hover_color", TEXTO)
	_jugar.add_theme_color_override("font_focus_color", TEXTO)
	_jugar.add_theme_color_override("font_pressed_color", TEXTO)
	_jugar.add_theme_color_override("font_hover_pressed_color", TEXTO)
	_jugar.position = Vector2(X_TEXTO, Y_OPCION - 24.0)
	_jugar.size = Vector2(240.0, 48.0)
	_jugar.mouse_entered.connect(_al_pasar)
	_jugar.focus_entered.connect(_enfocar)
	_jugar.focus_exited.connect(_desenfocar)
	_jugar.pressed.connect(_al_jugar)
	_contenido.add_child(_jugar)

	_subrayado = ColorRect.new()
	_subrayado.position = Vector2(X_TEXTO + 2.0, Y_OPCION + 20.0)
	_subrayado.size = Vector2(_jugar.get_minimum_size().x - 4.0, 1.0)
	_subrayado.scale.x = 0.0
	_subrayado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contenido.add_child(_subrayado)

	_flecha = _etiqueta("▸", _fuente_flecha, 30, TEXTO)
	_flecha.position = Vector2(X_TEXTO - 30.0, Y_OPCION - 20.0)
	_flecha.visible = false
	_contenido.add_child(_flecha)

	var capa_negra: CanvasLayer = CanvasLayer.new()
	capa_negra.layer = 20
	add_child(capa_negra)
	_negro = ColorRect.new()
	_negro.color = Color(0.0, 0.0, 0.0, 1.0)
	_negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_negra.add_child(_negro)


func _etiqueta(texto: String, fuente: Font, tamano: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = texto
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", fuente)
	l.add_theme_font_size_override("font_size", tamano)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color(BRILLO_CIAN, 0.45))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 0)
	l.add_theme_constant_override("shadow_outline_size", 10)
	return l


func _reubicar() -> void:
	var pantalla: Vector2 = get_viewport().get_visible_rect().size
	_escala = clampf(pantalla.y / ALTO_BASE, 0.75, 3.0)
	_contenido.scale = Vector2.ONE * _escala
	_velo.position = Vector2.ZERO
	_velo.size = Vector2(pantalla.x * 0.55, pantalla.y)


func _entrada() -> void:
	_titulo.modulate.a = 0.0
	_icono.modulate.a = 0.0
	_divisor.scale.y = 0.0
	_divisor.pivot_offset = Vector2(0.0, _divisor.size.y * 0.5)
	_jugar.modulate.a = 0.0
	var t: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(_negro, "color:a", 0.0, 1.8)
	t.tween_property(_titulo, "modulate:a", 1.0, 1.2).set_delay(0.6)
	t.tween_property(_divisor, "scale:y", 1.0, 0.6).set_delay(1.9)
	t.tween_property(_icono, "modulate:a", 1.0, 0.6).set_delay(2.1)
	t.tween_property(_jugar, "modulate:a", 1.0, 0.6).set_delay(2.2)
	t.tween_property(_jugar, "position:x", X_TEXTO, 0.6).from(X_TEXTO - 20.0).set_delay(2.2)
	t.chain().tween_callback(_enfocar_inicio)


func _enfocar_inicio() -> void:
	_silencio = true
	_jugar.grab_focus()
	_silencio = false


func _al_pasar() -> void:
	if not _saliendo:
		_jugar.grab_focus()


func _enfocar() -> void:
	_enfocado = true
	if not _silencio:
		sonido_clic.pitch_scale = randf_range(0.9, 1.1)
		sonido_clic.play()
	var t: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(_subrayado, "scale:x", 1.0, 0.35)
	t.tween_property(_icono, "rotation", deg_to_rad(-8.0), 0.35)
	t.tween_property(_icono, "scale", Vector2(1.12, 1.12), 0.35)


func _desenfocar() -> void:
	_enfocado = false
	var t: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(_subrayado, "scale:x", 0.0, 0.25)
	t.tween_property(_icono, "rotation", 0.0, 0.25)
	t.tween_property(_icono, "scale", Vector2.ONE, 0.25)


func _al_jugar() -> void:
	if _saliendo:
		return
	_saliendo = true
	_jugar.focus_mode = Control.FOCUS_NONE
	_jugar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sonido_puertas.play()
	var t: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	t.tween_property(_jugar, "position:x", X_TEXTO + 24.0, 0.5).set_ease(Tween.EASE_OUT)
	t.tween_property(_subrayado, "scale:x", 1.6, 0.5)
	t.tween_property(_negro, "color:a", 1.0, 1.3).set_delay(0.35)
	t.tween_property(ambiente, "volume_db", -40.0, 1.5)
	t.chain().tween_callback(_empezar)


func _empezar() -> void:
	Partida.nueva_partida()
	Partida.cambiar_escena(ESCENA_JUEGO)


func _pintar() -> void:
	var acento: Color = AMBAR.lerp(VERDE, _mezcla)
	var v: float = lerpf(0.2, 1.0, _brillo)
	_contenido.modulate = Color(v, v, v, 1.0)
	_divisor.color = Color(acento, 0.45)
	_subrayado.color = acento
	var pulso: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005)
	var intensidad: float = 1.0 if _enfocado else 0.55
	for trazo: Line2D in _trazos:
		trazo.default_color = Color(acento, intensidad * 0.8)
	for i: int in _estilos_punto.size():
		var brillo_punto: float = intensidad
		if _enfocado and i == _estilos_punto.size() - 1:
			brillo_punto = 0.6 + 0.4 * pulso
		_estilos_punto[i].bg_color = Color(acento, brillo_punto)
		_estilos_punto[i].shadow_color = Color(acento, 0.5 * brillo_punto)
		_estilos_punto[i].shadow_size = 5 if _enfocado else 0
	_flecha.visible = _enfocado and pulso > 0.35
	_flecha.add_theme_color_override("font_color", TEXTO.lerp(acento, 0.25))
	_jugar.add_theme_color_override("font_focus_color", TEXTO.lerp(acento, 0.25))
	_jugar.add_theme_color_override("font_hover_color", TEXTO.lerp(acento, 0.25))


func _animar_titulo(delta: float) -> void:
	if _glitch > 0.0:
		_glitch -= delta
		if _glitch <= 0.0:
			_titulo.text = TITULO
			_titulo.position.x = X_TITULO
	if _brillo < 0.55 and randf() < delta * 12.0:
		_glitch = randf_range(0.05, 0.12)
		_titulo.text = _texto_roto()
		_titulo.position.x = X_TITULO + randf_range(-3.0, 3.0)


func _texto_roto() -> String:
	var letras: PackedStringArray = TITULO.split("")
	for _k: int in randi_range(1, 2):
		var i: int = randi() % letras.size()
		if letras[i] != " ":
			letras[i] = SIMBOLOS[randi() % SIMBOLOS.length()]
	return "".join(letras)
