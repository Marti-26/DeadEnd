extends Node
## Tarea · Restrepo Sanabria María Camila — lo que sobrevive al cambiar de escena.
## Va como Autoload con el nombre "Partida" (Proyecto > Configuración del
## proyecto > Globales). Las escenas se cargan y se borran, pero este nodo vive
## todo el juego: aquí quedan la batería y el estrés para que al cambiar de
## escena no vuelvan a su valor inicial.
##
## interactuar.gd (batería) y dash.gd (estrés) ya no guardan el valor en el
## nodo: lo leen y lo escriben aquí. Desde fuera se sigue usando igual:
## jugador.bateria, dash.estres.
##
## Para cambiar de escena (por ejemplo la escalera al segundo piso):
##     Partida.cambiar_escena("res://segundo_piso.tscn")
##
## Prueba: F9 recarga la escena actual. La batería y el estrés deben seguir igual.

var bateria = -1.0        # %. -1 = todavía no empieza: la pone interactuar.gd la primera vez
var estres = 0.0          # 0 a 100
var recuperando = false   # el jadeo de dash.gd sigue bajando el estrés en la otra escena


func cambiar_escena(ruta):
	print("cambio de escena -> ", ruta, " · batería ", snappedf(bateria, 0.1),
		" % · estrés ", snappedf(estres, 0.1))
	get_tree().change_scene_to_file(ruta)


func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_F9:
		cambiar_escena(get_tree().current_scene.scene_file_path)
