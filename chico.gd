extends CharacterBody3D

@export var objetivo: Node3D
@onready var anim = $Modelo/AnimationPlayer

func _physics_process(delta):
	velocity += get_gravity() * delta

	anim.play("idle")

	move_and_slide()

	var hacia = objetivo.global_position - global_position
	hacia.y = 0.0

	if Engine.get_physics_frames() % 30 == 0:
		print("distancia ", snappedf(hacia.length(), 0.01))
