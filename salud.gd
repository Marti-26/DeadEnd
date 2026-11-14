extends Node

signal vida_cambiada(actual: float, maxima: float)
signal sin_vida

@export var vida_maxima: float = 100.0
var vida_actual: float

func _ready() -> void:
	vida_actual = vida_maxima

func recibir_dano(cantidad: float) -> void:
	if vida_actual <= 0.0:
		return

	vida_actual = maxf(0.0, vida_actual - cantidad)
	vida_cambiada.emit(vida_actual, vida_maxima)

	if vida_actual <= 0.0:
		sin_vida.emit()
