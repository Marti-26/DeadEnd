extends Area3D

@export var grupo = "fuera_de_alcance"


func _ready():
	body_entered.connect(func(c):
		if c.is_in_group("jugador"):
			c.add_to_group(grupo))
	body_exited.connect(func(c):
		if c.is_in_group("jugador"):
			c.remove_from_group(grupo))
