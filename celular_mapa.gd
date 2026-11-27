class_name CelularMapa
extends Control

signal abierto_cambiado(esta_abierto: bool)

@export var ancho: float = 290.0
@export var alto: float = 600.0
@export var escala_pantalla: float = 0.78
@export var margen_derecho: float = 80.0
@export var metros_visibles: float = 16.0
@export var altura_camara: float = 2.9
@export var inclinacion: float = -3.0
@export var color_crema: Color = Color(0.984, 0.945, 0.902)
@export var color_rosa: Color = Color(0.969, 0.714, 0.784)
@export var color_rosa_medio: Color = Color(0.933, 0.498, 0.639)
@export var color_rosa_fuerte: Color = Color(0.847, 0.263, 0.435)
@export var color_vino: Color = Color(0.42, 0.08, 0.2)
@export var color_marcador: Color = Color(1.0, 0.68, 0.32)

const NOMBRES_ZONA: Dictionary = {
	"zona_b": "ANDÉN",
	"segundo_piso": "ZONA SEGURA",
	"zona_c_final": "ZONA C",
}

const NIVELES: Dictionary = {
	"segundo_piso": "NIVEL 0",
	"zona_b": "NIVEL -1",
	"zona_c_final": "FIN DE LÍNEA",
}

const PISOS: Array[Array] = [
	["segundo_piso", "N0", "ZONA SEGURA"],
	["zona_b", "N-1", "ANDÉN"],
	["zona_c_final", ">", "ZONA C"],
]

const AVISO_METRO: String = "Ya puedes tomar el metro"

const CODIGO_SHADER: String = """
shader_type canvas_item;
uniform vec4 oscuro : source_color;
uniform vec4 medio : source_color;
uniform vec4 claro : source_color;
uniform float brillo = 2.2;
uniform float curva = 0.75;
uniform vec2 tamano = vec2(238.0, 360.0);
uniform float radio = 14.0;
uniform float lineas = 0.07;
void fragment() {
	vec3 c = texture(TEXTURE, UV).rgb;
	float l = clamp(pow(dot(c, vec3(0.299, 0.587, 0.114)) * brillo, curva), 0.0, 1.0);
	vec3 col = l < 0.5 ? mix(oscuro.rgb, medio.rgb, l * 2.0) : mix(medio.rgb, claro.rgb, (l - 0.5) * 2.0);
	col *= 1.0 - lineas * step(0.5, fract(UV.y * tamano.y * 0.5));
	vec2 p = UV * tamano;
	vec2 q = abs(p - tamano * 0.5) - (tamano * 0.5 - radio);
	float d = length(max(q, 0.0)) - radio;
	COLOR = vec4(col, 1.0 - smoothstep(-1.0, 0.5, d));
}
"""

const SIMBOLOS: String = "#%&@$?!*/\\|<>~^=+"
const HORAS_RARAS: Array[String] = ["03:33", "00:00", "13:13", "--:--", "88:88", "25:61", "??:??", "04:04"]
const FECHAS_RARAS: Array[String] = ["00/00/0000", "31/02/19??", "??/??/????", "13/13/1313", "--/--/----", "29/02/2??1", "00/00/00"]

var abierto: bool = false
var _fondo: ColorRect = null
var _telefono: Control = null
var _viewport: SubViewport = null
var _camara: Camera3D = null
var _mapa: TextureRect = null
var _marcador: Control = null
var _charm: Control = null
var _hora: Label = null
var _fecha: Label = null
var _hora_x: float = 0.0
var _fecha_x: float = 0.0
var _siguiente_glitch: float = 0.0
var _congelado: float = 0.0
var _bateria: Label = null
var _zona: Label = null
var _nivel: Label = null
var _terminales: Label = null
var _estado_terminales: Label = null
var _estilo_terminales: StyleBoxFlat = null
var _terminales_mostradas: int = -1
var _tween: Tween = null
var _tiempo: float = 0.0
var _impulso_charm: float = 0.0
var _pisos_texto: Array[Label] = []
var _pisos_fondo: Array[Panel] = []
var _escena_vagon: Node = null
var _interior_vagon: Node3D = null


func _ready() -> void:
	add_to_group(&"mapa_celular")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = load("res://tema.tres") as Theme
	_construir()
	visible = false
	get_viewport().size_changed.connect(_reubicar)


func _process(delta: float) -> void:
	if not visible:
		return
	_tiempo += delta
	_impulso_charm = move_toward(_impulso_charm, 0.0, delta * 0.6)
	_charm.rotation = sin(_tiempo * 1.7) * (0.06 + _impulso_charm)
	_seguir_jugador()
	_actualizar_textos(delta)
	_marcador.queue_redraw()


func alternar() -> void:
	if abierto:
		cerrar()
	else:
		abrir()



func abrir() -> void:
	if abierto:
		return
	abierto = true
	visible = true
	# Reproducir sonido al abrir el mapa
	var jugador = get_tree().get_first_node_in_group(Grupos.JUGADOR)
	if jugador != null:
		var sonido = jugador.get_node_or_null("Celular") as AudioStreamPlayer
		if sonido != null:
			if sonido.stream != null:
				sonido.play()
				print("Sonido del mapa reproducido")
			else:
				print("ERROR: SonidoAbrirMapa no tiene audio asignado")
		else:
			print("ERROR: No se encontró SonidoAbrirMapa")
	else:
		print("ERROR: No se encontró al jugador")
	# Activar cámara del mapa
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_seguir_jugador()
	_siguiente_glitch = 0.0
	_congelado = 0.0
	_actualizar_textos(0.0)
	_impulso_charm = 0.35
	# Animación de apertura del celular
	var destino: Vector2 = _posicion_abierta()
	_telefono.position = destino + Vector2(ancho * _escala() + margen_derecho + 60.0, 0.0)
	_telefono.rotation_degrees = inclinacion + 8.0
	_fondo.modulate.a = 0.0

	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_telefono, "position", destino, 0.42)
	_tween.tween_property(_telefono, "rotation_degrees", inclinacion, 0.42)
	_tween.tween_property(_fondo, "modulate:a", 1.0, 0.25)

	abierto_cambiado.emit(true)



func cerrar() -> void:
	if not abierto:
		return
	abierto = false
	_impulso_charm = 0.3
	var fuera: Vector2 = _posicion_abierta() + Vector2(ancho * _escala() + margen_derecho + 60.0, 0.0)
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(_telefono, "position", fuera, 0.3)
	_tween.tween_property(_telefono, "rotation_degrees", inclinacion + 8.0, 0.3)
	_tween.tween_property(_fondo, "modulate:a", 0.0, 0.25)
	_tween.chain().tween_callback(_terminar_cierre)
	abierto_cambiado.emit(false)


func _terminar_cierre() -> void:
	if abierto:
		return
	visible = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _escala() -> float:
	var pantalla: Vector2 = get_viewport_rect().size
	return clampf(pantalla.y * escala_pantalla / alto, 0.6, 2.0)


func _posicion_abierta() -> Vector2:
	var pantalla: Vector2 = get_viewport_rect().size
	var s: float = _escala()
	_telefono.scale = Vector2(s, s)
	var centro: Vector2 = Vector2(pantalla.x - margen_derecho - ancho * s * 0.5, pantalla.y * 0.5)
	return centro - Vector2(ancho, alto) * 0.5


func _reubicar() -> void:
	if abierto and (_tween == null or not _tween.is_running()):
		_telefono.position = _posicion_abierta()


func _al_tocar_fondo(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and (evento as InputEventMouseButton).pressed:
		cerrar()
		accept_event()


func _seguir_jugador() -> void:
	var jugador: Node3D = get_tree().get_first_node_in_group(Grupos.JUGADOR) as Node3D
	if jugador == null or _camara == null:
		return
	_camara.global_position = jugador.global_position + Vector3(0.0, altura_camara, 0.0)


func _actualizar_textos(delta: float) -> void:
	_glitch_reloj(delta)
	var carga: float = 100.0
	if Partida != null and Partida.bateria >= 0.0:
		carga = Partida.bateria
	_bateria.text = "%d%%" % int(round(clampf(carga, 0.0, 100.0)))
	var escena: Node = get_tree().current_scene
	var clave: String = escena.scene_file_path.get_file().get_basename() if escena != null else ""
	var lugar: String = _lugar_actual(clave)
	_nivel.text = str(NIVELES.get(clave, ""))
	_zona.text = lugar
	_actualizar_pisos(clave)
	_actualizar_terminales()


func _actualizar_terminales() -> void:
	var activadas := Partida.contar_terminales_activadas()
	if activadas == _terminales_mostradas:
		return
	_terminales_mostradas = activadas
	_terminales.text = "TERMINALES · %d/%d ACTIVADAS" % [activadas, Partida.TOTAL_TERMINALES]
	var faltan := Partida.TOTAL_TERMINALES - activadas
	var color_texto := color_crema if faltan == 0 else color_vino
	_estilo_terminales.bg_color = color_vino if faltan == 0 else color_rosa.lightened(0.45)
	_terminales.add_theme_color_override("font_color", color_texto)
	_estado_terminales.add_theme_color_override("font_color", color_texto)
	match faltan:
		0:
			_estado_terminales.text = AVISO_METRO
		1:
			_estado_terminales.text = "Falta 1 punto de activación"
		_:
			_estado_terminales.text = "Faltan %d puntos de activación" % faltan


func _construir_pisos(pantalla: Control, pos: Vector2, ancho_caja: float) -> void:
	var alto_fila: float = 24.0
	var caja: Panel = _panel(pantalla, _estilo(color_crema, color_rosa_medio, 2, 8), pos, Vector2(ancho_caja, 8.0 + float(PISOS.size()) * alto_fila))
	for i: int in PISOS.size():
		var resalte: Panel = _panel(caja, _estilo(color_rosa_fuerte, Color.TRANSPARENT, 0, 6), Vector2(4.0, 4.0 + float(i) * alto_fila), Vector2(ancho_caja - 8.0, alto_fila - 2.0))
		resalte.visible = false
		_pisos_fondo.append(resalte)
		var fila: Label = _etiqueta(caja, "", 14, color_vino, Vector2(12.0, 4.0 + float(i) * alto_fila), Vector2(ancho_caja - 24.0, alto_fila - 2.0), HORIZONTAL_ALIGNMENT_LEFT)
		_pisos_texto.append(fila)


func _actualizar_pisos(clave: String) -> void:
	var zona_c_conocida: bool = clave == "zona_c_final" or (Partida != null and Partida.terminales_completadas())
	for i: int in PISOS.size():
		var piso: Array = PISOS[i]
		var actual: bool = piso[0] == clave
		var nombre: String = str(piso[2])
		if piso[0] == "zona_c_final" and not zona_c_conocida:
			nombre = _corromper("??????", 0.5)
		_pisos_texto[i].text = "%s  %s%s" % [piso[1], nombre, "   < TÚ" if actual else ""]
		_pisos_fondo[i].visible = actual
		_pisos_texto[i].add_theme_color_override("font_color", color_crema if actual else color_vino)


func _lugar_actual(clave: String) -> String:
	var base: String = str(NOMBRES_ZONA.get(clave, clave.to_upper()))
	var jugador: Node3D = get_tree().get_first_node_in_group(Grupos.JUGADOR) as Node3D
	if jugador == null or clave != "zona_b":
		return base
	if _en_vagon(jugador):
		return "VAGÓN"
	if jugador.is_in_group(Grupos.FUERA_DE_ALCANCE) and not jugador.is_in_group(Grupos.ZONA_SEGURA):
		return "ESCALERAS"
	return base


func _en_vagon(jugador: Node3D) -> bool:
	var escena: Node = get_tree().current_scene
	if escena != _escena_vagon:
		_escena_vagon = escena
		_interior_vagon = null
		if escena != null:
			for n: Node in escena.find_children("Interior", "Node3D", true, false):
				if n.get_parent() != null and n.get_parent().name == "Tren":
					_interior_vagon = n as Node3D
					break
	if _interior_vagon == null or not is_instance_valid(_interior_vagon):
		return false
	var local: Vector3 = _interior_vagon.to_local(jugador.global_position)
	return absf(local.x) < 12.0 and absf(local.z) < 1.5 and local.y > -1.0 and local.y < 3.0


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
		_hora.text = _corromper(_hora_real(), 0.6)
		_fecha.text = _corromper(_fecha_real(), 0.5)
	_hora.position.x = _hora_x + randf_range(-1.5, 1.5)
	_fecha.position.x = _fecha_x + randf_range(-2.0, 2.0)
	var color_hora: Color = color_rosa_fuerte if randf() < 0.15 else color_vino
	_hora.add_theme_color_override("font_color", color_hora)
	_fecha.add_theme_color_override("font_color", color_vino if randf() < 0.2 else color_rosa_medio)


func _hora_real() -> String:
	var t: Dictionary = Time.get_time_dict_from_system()
	return "%02d:%02d" % [int(t.hour), int(t.minute)]


func _fecha_real() -> String:
	var f: Dictionary = Time.get_date_dict_from_system()
	return "%02d/%02d/%04d" % [int(f.day), int(f.month), int(f.year)]


func _corromper(texto: String, probabilidad: float) -> String:
	var salida: String = ""
	for c: String in texto:
		var separador: bool = c == ":" or c == "/"
		if randf() < (probabilidad * 0.3 if separador else probabilidad):
			salida += SIMBOLOS[randi() % SIMBOLOS.length()]
		else:
			salida += c
	return salida


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
	padre.add_child(p)
	return p


func _etiqueta(padre: Control, texto: String, tam_fuente: int, color: Color, pos: Vector2, tam: Vector2, alineacion: HorizontalAlignment) -> Label:
	var l: Label = Label.new()
	l.text = texto
	l.position = pos
	l.size = tam
	l.horizontal_alignment = alineacion
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam_fuente)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_constant_override("shadow_outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(l)
	return l


func _construir() -> void:
	_fondo = ColorRect.new()
	_fondo.color = Color(0.05, 0.0, 0.03, 0.28)
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	_fondo.gui_input.connect(_al_tocar_fondo)
	add_child(_fondo)

	_telefono = Control.new()
	_telefono.size = Vector2(ancho, alto)
	_telefono.pivot_offset = Vector2(ancho, alto) * 0.5
	_telefono.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_telefono)

	var boton: StyleBoxFlat = _estilo(color_rosa_fuerte, Color.TRANSPARENT, 0, 3)
	_panel(_telefono, boton, Vector2(-5.0, 110.0), Vector2(8.0, 42.0))
	_panel(_telefono, boton, Vector2(-5.0, 162.0), Vector2(8.0, 42.0))
	_panel(_telefono, boton, Vector2(ancho - 3.0, 140.0), Vector2(8.0, 62.0))

	var cuerpo_estilo: StyleBoxFlat = _estilo(color_rosa, color_rosa_fuerte, 4, 40)
	cuerpo_estilo.shadow_color = Color(0.25, 0.02, 0.1, 0.4)
	cuerpo_estilo.shadow_size = 16
	cuerpo_estilo.shadow_offset = Vector2(8.0, 10.0)
	_panel(_telefono, cuerpo_estilo, Vector2.ZERO, Vector2(ancho, alto))

	var pantalla: Panel = _panel(_telefono, _estilo(color_crema, color_rosa_medio, 2, 28), Vector2(14.0, 14.0), Vector2(ancho - 28.0, alto - 28.0))
	var ancho_p: float = pantalla.size.x
	var alto_p: float = pantalla.size.y

	_panel(pantalla, _estilo(color_rosa_fuerte, Color.TRANSPARENT, 0, 10), Vector2(ancho_p * 0.5 - 40.0, 8.0), Vector2(80.0, 20.0))
	_hora = _etiqueta(pantalla, "00:00", 13, color_vino, Vector2(18.0, 6.0), Vector2(60.0, 22.0), HORIZONTAL_ALIGNMENT_LEFT)
	_bateria = _etiqueta(pantalla, "100%", 13, color_vino, Vector2(ancho_p - 78.0, 6.0), Vector2(60.0, 22.0), HORIZONTAL_ALIGNMENT_RIGHT)
	_etiqueta(pantalla, "MAPA", 24, color_rosa_fuerte, Vector2(0.0, 30.0), Vector2(ancho_p, 28.0), HORIZONTAL_ALIGNMENT_CENTER)
	_fecha = _etiqueta(pantalla, "00/00/0000", 12, color_rosa_medio, Vector2(0.0, 56.0), Vector2(ancho_p, 16.0), HORIZONTAL_ALIGNMENT_CENTER)
	_nivel = _etiqueta(pantalla, "", 14, color_rosa_medio, Vector2(0.0, 74.0), Vector2(ancho_p, 18.0), HORIZONTAL_ALIGNMENT_CENTER)
	_zona = _etiqueta(pantalla, "", 26, color_rosa_fuerte, Vector2(0.0, 90.0), Vector2(ancho_p, 30.0), HORIZONTAL_ALIGNMENT_CENTER)
	_hora_x = _hora.position.x
	_fecha_x = _fecha.position.x

	var tam_mapa: Vector2 = Vector2(ancho_p - 28.0, alto_p - 128.0 - 176.0)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(int(tam_mapa.x * 1.5), int(tam_mapa.y * 1.5))
	_viewport.debug_draw = Viewport.DEBUG_DRAW_UNSHADED
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_viewport.msaa_3d = Viewport.MSAA_2X
	add_child(_viewport)

	_camara = Camera3D.new()
	_camara.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camara.keep_aspect = Camera3D.KEEP_HEIGHT
	_camara.size = metros_visibles
	_camara.near = 0.05
	_camara.far = 40.0
	_camara.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
	var entorno: Environment = Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color.BLACK
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color.WHITE
	_camara.environment = entorno
	_viewport.add_child(_camara)
	_camara.current = true

	_mapa = TextureRect.new()
	_mapa.texture = _viewport.get_texture()
	_mapa.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mapa.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_mapa.position = Vector2(14.0, 128.0)
	_mapa.size = tam_mapa
	_mapa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sombra: Shader = Shader.new()
	sombra.code = CODIGO_SHADER
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = sombra
	mat.set_shader_parameter("oscuro", color_vino)
	mat.set_shader_parameter("medio", color_rosa_medio)
	mat.set_shader_parameter("claro", color_crema)
	mat.set_shader_parameter("tamano", tam_mapa)
	_mapa.material = mat
	pantalla.add_child(_mapa)

	_marcador = Control.new()
	_marcador.position = _mapa.position
	_marcador.size = tam_mapa
	_marcador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marcador.draw.connect(_dibujar_marcador)
	pantalla.add_child(_marcador)

	_construir_pisos(pantalla, Vector2(14.0, _mapa.position.y + tam_mapa.y + 10.0), tam_mapa.x)

	_estilo_terminales = _estilo(color_rosa.lightened(0.45), color_rosa_medio, 1, 7)
	var y_tarjeta: float = _mapa.position.y + tam_mapa.y + 10.0 + 8.0 + float(PISOS.size()) * 24.0 + 10.0
	var tarjeta_terminales := _panel(pantalla, _estilo_terminales, Vector2(14.0, y_tarjeta), Vector2(tam_mapa.x, 44.0))
	_terminales = _etiqueta(tarjeta_terminales, "", 13, color_vino, Vector2(0.0, 5.0), Vector2(tam_mapa.x, 17.0), HORIZONTAL_ALIGNMENT_CENTER)
	_estado_terminales = _etiqueta(tarjeta_terminales, "", 13, color_vino, Vector2(0.0, 22.0), Vector2(tam_mapa.x, 17.0), HORIZONTAL_ALIGNMENT_CENTER)
	_panel(pantalla, _estilo(color_rosa_fuerte, Color.TRANSPARENT, 0, 3), Vector2(ancho_p * 0.5 - 45.0, alto_p - 13.0), Vector2(90.0, 5.0))

	_charm = Control.new()
	_charm.position = Vector2(-3.0, 96.0)
	_charm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_charm.draw.connect(_dibujar_charm)
	_telefono.add_child(_charm)
	_telefono.move_child(_charm, 0)


func _dibujar_marcador() -> void:
	var c: Vector2 = _marcador.size * 0.5
	var pulso: float = 0.5 + 0.5 * sin(_tiempo * 3.2)
	_dibujar_guia_segura(c)
	_marcador.draw_circle(c, 9.0 + pulso * 9.0, Color(color_marcador, 0.35 * (1.0 - pulso)))
	_marcador.draw_circle(c, 7.0, color_vino)
	_marcador.draw_circle(c, 5.0, color_marcador)


func _dibujar_guia_segura(c: Vector2) -> void:
	var guia: Node = get_parent().get_node_or_null("GuiaZonaSegura") if get_parent() != null else null
	if guia == null or not guia.has_method("destino_actual"):
		return
	var destino = guia.call("destino_actual")
	var jugador: Node3D = get_tree().get_first_node_in_group(Grupos.JUGADOR) as Node3D
	if destino == null or jugador == null:
		return
	var por_metro: float = _marcador.size.y / maxf(metros_visibles, 0.1)
	var diferencia: Vector3 = (destino as Vector3) - jugador.global_position
	var objetivo: Vector2 = c + Vector2(diferencia.x, diferencia.z) * por_metro
	var margen: float = 22.0
	var caja: Rect2 = Rect2(Vector2(margen, margen), _marcador.size - Vector2(margen, margen) * 2.0)
	var dentro: bool = caja.has_point(objetivo)
	var direccion: Vector2 = (objetivo - c).normalized()
	if direccion == Vector2.ZERO:
		direccion = Vector2.RIGHT
	var punto: Vector2 = objetivo
	if not dentro:
		var escala_x: float = (caja.size.x * 0.5) / maxf(absf(direccion.x), 0.0001)
		var escala_y: float = (caja.size.y * 0.5) / maxf(absf(direccion.y), 0.0001)
		punto = c + direccion * minf(escala_x, escala_y)
	var largo: float = c.distance_to(punto)
	var paso: float = 9.0
	var avance: float = fmod(_tiempo * 14.0, paso)
	var d: float = 14.0 + avance
	while d < largo - 16.0:
		_marcador.draw_circle(c + direccion * d, 1.6, Color(color_rosa_fuerte, 0.55))
		d += paso
	var vaiven: float = sin(_tiempo * 2.4) * 2.0
	var centro: Vector2 = punto + (direccion * vaiven if not dentro else Vector2(0.0, vaiven))
	_marcador.draw_circle(centro, 13.0, Color(color_crema, 0.9))
	_marcador.draw_circle(centro, 11.0, color_rosa_fuerte)
	if dentro:
		var casa: PackedVector2Array = PackedVector2Array([
			centro + Vector2(0.0, -6.5), centro + Vector2(6.0, -1.0), centro + Vector2(4.0, -1.0),
			centro + Vector2(4.0, 5.0), centro + Vector2(-4.0, 5.0), centro + Vector2(-4.0, -1.0), centro + Vector2(-6.0, -1.0),
		])
		_marcador.draw_colored_polygon(casa, color_crema)
	else:
		var giro: Transform2D = Transform2D(direccion.angle(), centro)
		var flecha: PackedVector2Array = PackedVector2Array([
			giro * Vector2(6.0, 0.0), giro * Vector2(-4.0, 5.5), giro * Vector2(-1.5, 0.0), giro * Vector2(-4.0, -5.5),
		])
		_marcador.draw_colored_polygon(flecha, color_crema)
	var fuente: Font = _zona.get_theme_font("font") if _zona != null else ThemeDB.fallback_font
	var texto: String = "ZONA SEGURA"
	var tam: int = 10
	var ancho_texto: float = fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1.0, tam).x
	var pastilla: Vector2 = Vector2(ancho_texto + 12.0, 16.0)
	var hacia_adentro: Vector2 = (c - centro).normalized() if not dentro else Vector2(0.0, 1.0)
	var origen: Vector2 = centro + hacia_adentro * 24.0 - pastilla * 0.5
	origen.x = clampf(origen.x, 2.0, _marcador.size.x - pastilla.x - 2.0)
	origen.y = clampf(origen.y, 2.0, _marcador.size.y - pastilla.y - 2.0)
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = Color(color_vino, 0.92)
	estilo.border_color = color_rosa
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(8)
	_marcador.draw_style_box(estilo, Rect2(origen, pastilla))
	_marcador.draw_string(fuente, origen + Vector2(6.0, 12.0), texto, HORIZONTAL_ALIGNMENT_LEFT, -1.0, tam, color_crema)


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
