class_name Celular
extends Area3D

var _jugador_cerca: Node = null


func _ready() -> void:
	add_to_group(Grupos.INTERACTIVOS)
	# Si ya fue recogido en la partida, desaparece inmediatamente
	if Partida != null and Partida.celular_recogido:
		queue_free()
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _jugador_cerca == null:
		return
	if event is InputEventKey:
		var tecla_event: InputEventKey = event as InputEventKey
		if tecla_event.pressed and not tecla_event.echo:
			# Tecla E física o acción interactuar ("usar" / "esconderse")
			if tecla_event.physical_keycode == KEY_E or event.is_action_pressed("usar") or event.is_action_pressed("esconderse"):
				usar()


func _on_body_entered(cuerpo: Node3D) -> void:
	if cuerpo.is_in_group(Grupos.JUGADOR):
		_jugador_cerca = cuerpo
		print("¡Cerca del celular! Presiona E para recogerlo")


func _on_body_exited(cuerpo: Node3D) -> void:
	if cuerpo == _jugador_cerca:
		_jugador_cerca = null


func usar() -> void:
	print("¡Celular recogido con éxito!")
	if Partida != null:
		Partida.celular_recogido = true

	var jugador: Personaje = (_jugador_cerca if _jugador_cerca != null else get_tree().get_first_node_in_group(Grupos.JUGADOR)) as Personaje
	
	if jugador != null:
		jugador.tiene_celular = true

	# Reproducir el sonido al recoger el celular
	var sonido = jugador.get_node_or_null("RecogerCelular") as AudioStreamPlayer
	if sonido != null:
		sonido.play()

	if Partida != null:
		Partida.guardar_estado_personaje(jugador)


	remove_from_group(Grupos.INTERACTIVOS)
	queue_free()
