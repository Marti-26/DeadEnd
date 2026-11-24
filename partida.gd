
extends Node

const ESCENA_INICIO: String = "res://zona_b.tscn"
const LIMITE_ESTRES: float = 70.0
const ESTRES_AL_VOLVER: float = 50.0

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

# Terminales necesarias para viajar a Zona C
var terminal_1_activada: bool = false
var terminal_2_activada: bool = false


func terminales_completadas() -> bool:
	return terminal_1_activada and terminal_2_activada


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
		print("AMBAS TERMINALES ACTIVADAS")
		print("El metro ya puede llevarte a Zona C")

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

	get_tree().change_scene_to_file.call_deferred(ruta)


func guardar(punto: String) -> void:
	guardado = {
		"escena": get_tree().current_scene.scene_file_path,
		"punto": punto,
		"bateria": bateria,
		"estres": estres,
		"celular_recogido": celular_recogido,
		"terminal_1_activada": terminal_1_activada,
		"terminal_2_activada": terminal_2_activada
	}

	print(
		"Partida guardada · batería ",
		snappedf(bateria, 0.1),
		" % · estrés ",
		snappedf(estres, 0.1)
	)

func perder() -> void:
	if _perdiendo:
		return

	_perdiendo = true
	recuperando = false

	var con_apagon: bool = estres >= 99.9
	if con_apagon:
		if _apagon == null:
			_apagon = preload("res://apagon.gd").new()
			add_child(_apagon)
		await _apagon.apagar()

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

	if con_apagon:
		await _apagon.encender()
	else:
		await get_tree().create_timer(0.5).timeout
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
