extends Area3D

@export_file("*.tscn") var destino = ""
@export var llegada = ""

var _usada = false


func _ready():
	body_entered.connect(_al_entrar)


func _al_entrar(cuerpo):
	if _usada or destino == "" or not cuerpo.is_in_group("jugador"):
		return
	_usada = true
	Partida.cambiar_escena(destino, llegada)
