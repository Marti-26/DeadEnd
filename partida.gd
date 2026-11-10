extends Node

const ESCENA_INICIO = "res://zona_b.tscn"
const LIMITE_ESTRES = 70.0
const ESTRES_AL_VOLVER = 50.0

var bateria = -1.0
var estres = 0.0
var recuperando = false
var llegada = ""
var guardado = {}
var estacion_usada = false
var encuentros_chico = 0
var _perdiendo = false


func cambiar_escena(ruta, punto = ""):
	llegada = punto
	print("cambio de escena -> ", ruta, " · batería ", snappedf(bateria, 0.1),
		" % · estrés ", snappedf(estres, 0.1))
	get_tree().change_scene_to_file.call_deferred(ruta)


func guardar(punto):
	guardado = {
		"escena": get_tree().current_scene.scene_file_path,
		"punto": punto,
		"bateria": bateria,
		"estres": estres,
	}
	print("guardado · batería ", snappedf(bateria, 0.1), " % · estrés ", snappedf(estres, 0.1))


func perder():
	if _perdiendo:
		return
	_perdiendo = true
	recuperando = false
	if guardado.is_empty():
		print("perdió: vuelve al inicio")
		bateria = -1.0
		estres = 0.0
		cambiar_escena(ESCENA_INICIO)
	else:
		bateria = guardado.bateria
		estres = guardado.estres
		if estres > LIMITE_ESTRES:
			estres = ESTRES_AL_VOLVER
		print("perdió: vuelve al último guardado")
		cambiar_escena(guardado.escena, guardado.punto)
	await get_tree().create_timer(0.5).timeout
	_perdiendo = false


func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F9:
			cambiar_escena(get_tree().current_scene.scene_file_path)
		elif event.physical_keycode == KEY_F10:
			perder()
