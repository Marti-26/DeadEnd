extends Area3D

var _jugador_cerca: Node = null


func _ready() -> void:
	# Si ya fue recogido en la partida, desaparece inmediatamente
	if Partida != null and "celular_recogido" in Partida and Partida.celular_recogido:
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
			# Tecla R física o acción "hablar" mapeada a R en el proyecto
			if tecla_event.physical_keycode == KEY_R or event.is_action_pressed("hablar"):
				usar()


func _on_body_entered(cuerpo: Node3D) -> void:
	if cuerpo.is_in_group("jugador"):
		_jugador_cerca = cuerpo
		print("¡Cerca del celular! Presiona R para recogerlo")


func _on_body_exited(cuerpo: Node3D) -> void:
	if cuerpo == _jugador_cerca:
		_jugador_cerca = null


func usar() -> void:
	print("¡Celular recogido con éxito!")
	if Partida != null:
		Partida.celular_recogido = true

	var jugador: Node = _jugador_cerca if _jugador_cerca != null else get_tree().get_first_node_in_group("jugador")
	if jugador != null:
		jugador.set("tiene_celular", true)

	queue_free()
