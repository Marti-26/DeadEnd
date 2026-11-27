
extends Node

signal viaje_zona_c_habilitado

const ESCENA_INICIO: String = "res://zona_b.tscn"
const ESCENA_TUTORIAL: String = "res://tutorial.tscn"
const LIMITE_ESTRES: float = 70.0
const ESTRES_AL_VOLVER: float = 50.0
const TOTAL_TERMINALES: int = 2
const ARCHIVO_GUARDADO: String = "user://partida.save"

# Estado del personaje
var bateria: float = -1.0
var estres: float = 0.0
var recuperando: bool = false
var celular_recogido: bool = false
var encuentros_chico: int = 0
var llegada: String = ""
var guardado: Dictionary = {}
var estacion_usada: bool = false
var _perdiendo: bool = false
var _apagon = null
var _velo: ColorRect = null
var _tween_velo: Tween = null
var _ruta_pendiente: String = ""

# Terminales necesarias para viajar a Zona C
var terminal_1_activada: bool = false
var terminal_2_activada: bool = false
var aviso_metro_leido: bool = false


func contar_terminales_activadas() -> int:
	return int(terminal_1_activada) + int(terminal_2_activada)


func terminales_completadas() -> bool:
	return contar_terminales_activadas() == TOTAL_TERMINALES


func activar_terminal(numero: int) -> void:
	match numero:
		1:
			if terminal_1_activada:
				return
			terminal_1_activada = true
			print("Punto activación 1 activado")

		2:
			if terminal_2_activada:
				return
			terminal_2_activada = true
			print("Terminal 2 ACTIVADA")

		_:
			push_warning("Número de terminal inválido: " + str(numero))
			return

	if terminales_completadas():
		aviso_metro_leido = false
		print("AMBAS TERMINALES ACTIVADAS")
		print("El metro ya puede llevarte a Zona C")
		viaje_zona_c_habilitado.emit()

func guardar_estado_personaje(p: Personaje) -> void:
	if p == null:
		return

	bateria = p.bateria
	estres = p.estres
	celular_recogido = p.tiene_celular

	print(
		"Partida: estado de personaje guardado · batería ",
		snappedf(bateria, 0.1),
		" % · estrés ",
		snappedf(estres, 0.1),
		" · celular: ",
		celular_recogido
	)


func cargar_estado_personaje(p: Personaje) -> void:
	if p == null:
		return

	if bateria >= 0.0:
		p.bateria = bateria
	else:
		bateria = p.bateria

	p.estres = estres
	p.tiene_celular = celular_recogido

	print(
		"Partida: estado de personaje cargado · batería ",
		snappedf(p.bateria, 0.1),
		" % · estrés ",
		snappedf(p.estres, 0.1),
		" · celular: ",
		p.tiene_celular
	)


func cambiar_escena(ruta: String, punto: String = "") -> void:
	llegada = punto

	print(
		"Cambio de escena -> ",
		ruta,
		" · batería ",
		snappedf(bateria, 0.1),
		" % · estrés ",
		snappedf(estres, 0.1)
	)

	_ruta_pendiente = ruta
	_transicion()


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	var capa: CanvasLayer = CanvasLayer.new()
	capa.layer = 100
	add_child(capa)
	_velo = ColorRect.new()
	_velo.color = Color(0.0, 0.0, 0.0, 0.0)
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(_velo)


func _transicion() -> void:
	if _tween_velo != null and _tween_velo.is_valid():
		_tween_velo.kill()
	_tween_velo = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween_velo.tween_property(_velo, "color:a", 1.0, 0.12 * (1.0 - _velo.color.a))
	await _tween_velo.finished
	if _ruta_pendiente == "":
		return
	var ruta: String = _ruta_pendiente
	_ruta_pendiente = ""
	get_tree().change_scene_to_file(ruta)
	for i: int in 3:
		await get_tree().process_frame
	if _ruta_pendiente != "":
		return
	_tween_velo = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween_velo.tween_property(_velo, "color:a", 0.0, 0.35)


func guardar(punto: String) -> void:
	guardado = {
		"escena": get_tree().current_scene.scene_file_path,
		"punto": punto,
		"bateria": bateria,
		"estres": estres,
		"celular_recogido": celular_recogido,
		"terminal_1_activada": terminal_1_activada,
		"terminal_2_activada": terminal_2_activada,
		"estacion_usada": estacion_usada
	}
	_escribir_guardado()

	print(
		"Partida guardada · batería ",
		snappedf(bateria, 0.1),
		" % · estrés ",
		snappedf(estres, 0.1)
	)

func _escribir_guardado() -> void:
	var archivo: FileAccess = FileAccess.open(ARCHIVO_GUARDADO, FileAccess.WRITE)
	if archivo == null:
		push_warning("No se pudo escribir el guardado: " + ARCHIVO_GUARDADO)
		return
	archivo.store_string(JSON.stringify(guardado))


func hay_partida_guardada() -> bool:
	return not _leer_guardado().is_empty()


func _leer_guardado() -> Dictionary:
	if not FileAccess.file_exists(ARCHIVO_GUARDADO):
		return {}
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(ARCHIVO_GUARDADO))
	if datos is Dictionary and (datos as Dictionary).has("escena"):
		return datos as Dictionary
	return {}


func nueva_partida() -> void:
	guardado = {}
	bateria = -1.0
	estres = 0.0
	recuperando = false
	celular_recogido = false
	encuentros_chico = 0
	llegada = ""
	estacion_usada = false
	terminal_1_activada = false
	terminal_2_activada = false
	aviso_metro_leido = false


func cargar_partida() -> bool:
	var datos: Dictionary = _leer_guardado()
	if datos.is_empty():
		return false
	nueva_partida()
	guardado = datos
	bateria = float(datos.get("bateria", -1.0))
	estres = float(datos.get("estres", 0.0))
	celular_recogido = bool(datos.get("celular_recogido", false))
	terminal_1_activada = bool(datos.get("terminal_1_activada", false))
	terminal_2_activada = bool(datos.get("terminal_2_activada", false))
	estacion_usada = bool(datos.get("estacion_usada", false))
	cambiar_escena(str(datos.get("escena", ESCENA_INICIO)), str(datos.get("punto", "")))
	return true


func perder(motivo: String = "estres") -> void:
	if _perdiendo:
		return

	_perdiendo = true
	recuperando = false

	var con_apagon: bool = true
	if _apagon == null:
		_apagon = preload("res://apagon.gd").new()
		add_child(_apagon)
	await _apagon.apagar()

	# Mostrar mensaje explícito de causa de muerte con estilo de enemigo (rojo)
	var titulo_muerte: String = "HAS MUERTO"
	var texto_muerte: String = "No lograste sobrevivir en el metro."
	if motivo == "estres":
		titulo_muerte = "COLAPSO NERVIOSO"
		texto_muerte = "Moriste por llegar al 100% del estrés. El pánico te consumió."
	elif motivo == "criatura":
		titulo_muerte = "ATRAPADO"
		texto_muerte = "Moriste porque la criatura te atrapó en la oscuridad."
	await _mostrar_muerte(titulo_muerte, texto_muerte, 3.5)

	var escena_actual: Node = get_tree().current_scene
	if escena_actual != null and escena_actual.scene_file_path == ESCENA_TUTORIAL:
		estres = 0.0
		cambiar_escena(ESCENA_TUTORIAL)
		await _apagon.encender()
		_perdiendo = false
		return

	if guardado.is_empty():
		print("Perdió: vuelve al inicio")

		bateria = -1.0
		estres = 0.0
		celular_recogido = false
		terminal_1_activada = false
		terminal_2_activada = false

		cambiar_escena(ESCENA_INICIO)

	else:
		bateria = float(guardado.get("bateria", -1.0))
		estres = float(guardado.get("estres", 0.0))
		celular_recogido = bool(guardado.get("celular_recogido", false))

		terminal_1_activada = bool(
			guardado.get("terminal_1_activada", false)
		)

		terminal_2_activada = bool(
			guardado.get("terminal_2_activada", false)
		)

		if estres > LIMITE_ESTRES:
			estres = ESTRES_AL_VOLVER

		print("Perdió: vuelve al último guardado")

		var escena_guardada: String = str(
			guardado.get("escena", ESCENA_INICIO)
		)

		var punto_guardado: String = str(
			guardado.get("punto", "")
		)

		cambiar_escena(escena_guardada, punto_guardado)

	await _apagon.encender()
	_perdiendo = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event as InputEventKey

		if key_event.physical_keycode == KEY_F9:
			cambiar_escena(
				get_tree().current_scene.scene_file_path
			)

		elif key_event.physical_keycode == KEY_F10:
			perder()


func _mostrar_muerte(titulo: String, texto: String, duracion: float) -> void:
	var fuente: Font = load("res://assets/font/ShareTechMono-Regular.ttf") as Font
	var capa: CanvasLayer = CanvasLayer.new()
	capa.layer = 70
	add_child(capa)
	var caja: VBoxContainer = VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 18)
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.modulate.a = 0.0
	capa.add_child(caja)
	var etiqueta_titulo: Label = _texto_muerte(titulo, fuente, 64, Color(1.0, 0.16, 0.2), Color(0.45, 0.0, 0.04, 0.9), 12)
	caja.add_child(etiqueta_titulo)
	var etiqueta_texto: Label = _texto_muerte(texto, fuente, 28, Color(1.0, 0.86, 0.86), Color(0.12, 0.0, 0.02, 0.9), 8)
	etiqueta_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta_texto.custom_minimum_size = Vector2(minf(900.0, get_viewport().get_visible_rect().size.x - 80.0), 0.0)
	etiqueta_texto.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caja.add_child(etiqueta_texto)
	var entrada: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	entrada.tween_property(caja, "modulate:a", 1.0, 0.4)
	await get_tree().create_timer(duracion, true).timeout
	var salida: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	salida.tween_property(caja, "modulate:a", 0.0, 0.35)
	await salida.finished
	capa.queue_free()


func _texto_muerte(contenido: String, fuente: Font, tamano: int, color: Color, borde: Color, grosor: int) -> Label:
	var etiqueta: Label = Label.new()
	etiqueta.text = contenido
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if fuente != null:
		etiqueta.add_theme_font_override("font", fuente)
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_color_override("font_outline_color", borde)
	etiqueta.add_theme_constant_override("outline_size", grosor)
	return etiqueta
