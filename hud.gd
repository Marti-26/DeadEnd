class_name HUD
extends CanvasLayer

@onready var barra_bateria: ProgressBar = $Contenedor/BarraBateria as ProgressBar
@onready var barra_estres: ProgressBar = $Contenedor/BarraEstres as ProgressBar

var _nodo_bateria: Node = null
var _nodo_jugador: Node = null
var _nodo_dash: Node = null


func _enter_tree() -> void:
	add_to_group("hud")


func _ready() -> void:
	barra_bateria.min_value = 0.0
	barra_bateria.max_value = 100.0
	barra_bateria.value = 100.0
	barra_estres.min_value = 0.0
	barra_estres.max_value = 100.0
	barra_estres.value = 0.0
	_buscar_referencias()
	_actualizar_barras()


func _process(_delta: float) -> void:
	if not is_instance_valid(_nodo_bateria) and not is_instance_valid(_nodo_jugador):
		_buscar_referencias()
	_actualizar_barras()


func _buscar_referencias() -> void:
	_nodo_bateria = get_tree().get_first_node_in_group("bateria")
	_nodo_jugador = get_tree().get_first_node_in_group("jugador")
	if is_instance_valid(_nodo_jugador):
		_nodo_dash = _nodo_jugador.get_node_or_null("Dash")
	else:
		_nodo_dash = null


func _actualizar_barras() -> void:
	barra_bateria.value = _leer_bateria()
	barra_estres.value = _leer_estres()


func _leer_bateria() -> float:
	if is_instance_valid(_nodo_bateria) and "bateria" in _nodo_bateria:
		return clampf(float(_nodo_bateria.get("bateria")), 0.0, 100.0)
	if is_instance_valid(_nodo_jugador) and "bateria" in _nodo_jugador:
		return clampf(float(_nodo_jugador.get("bateria")), 0.0, 100.0)
	return 100.0


func _leer_estres() -> float:
	if is_instance_valid(_nodo_jugador) and "estres" in _nodo_jugador:
		return clampf(float(_nodo_jugador.get("estres")), 0.0, 100.0)
	if is_instance_valid(_nodo_bateria) and "estres" in _nodo_bateria:
		return clampf(float(_nodo_bateria.get("estres")), 0.0, 100.0)
	if is_instance_valid(_nodo_dash) and "estres" in _nodo_dash:
		return clampf(float(_nodo_dash.get("estres")), 0.0, 100.0)
	return 0.0
