extends "res://personaje.gd"

func _ready() -> void:
	super._ready()
	add_to_group(Grupos.ZONA_SEGURA)
	Partida.estres = 0.0
	sonido_latidos.stop()
	sonido_respiracion.stop()

func _process(delta: float) -> void:
	Partida.estres = 0.0
	_consumir_bateria(delta)
	_actualizar_linterna()
	_actualizar_bombillo()
