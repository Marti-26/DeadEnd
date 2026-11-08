extends CharacterBody3D

@export var objetivo: Node3D
@export var rapidez = 2.0
@onready var anim = $Modelo/AnimationPlayer

func _physics_process(delta):
	velocity += get_gravity() * delta

	var hacia = objetivo.global_position - global_position
	hacia.y = 0.0
	var distancia = hacia.length()

	if distancia > 1.0:
		var dir = hacia.normalized()
		velocity.x = dir.x * rapidez
		velocity.z = dir.z * rapidez
		basis = Basis.looking_at(dir)
		anim.play("walk")
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		anim.play("idle")

	move_and_slide()

	if Engine.get_physics_frames() % 30 == 0:
		print("distancia ", snappedf(distancia, 0.01))
