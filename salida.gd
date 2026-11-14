
extends Area3D


func _ready() -> void:
	body_entered.connect(_al_entrar)



func _al_entrar(cuerpo: Node3D) -> void:
	if not cuerpo.is_in_group("jugador"):
		return

	if cuerpo.bateria <= 0.0:
		print("No puedes salir sin batería")
		return

	print("La gata cruzó el torniquete con batería: ", cuerpo.bateria)
