extends Node

var bateria = -1.0
var estres = 0.0
var recuperando = false


func cambiar_escena(ruta):
	print("cambio de escena -> ", ruta, " · batería ", snappedf(bateria, 0.1),
		" % · estrés ", snappedf(estres, 0.1))
	get_tree().change_scene_to_file(ruta)


func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_F9:
		cambiar_escena(get_tree().current_scene.scene_file_path)
