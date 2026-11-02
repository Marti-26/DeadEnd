extends Camera3D

@export var objetivo: Node3D
@export var distancia = Vector3(0, 2, 12) 
@export var suavizado = 3.0

@export var limite_min = Vector2(-3, -10) # x y z mínimas
@export var limite_max = Vector2(3, 10) # x y z máximas

func _ready():
	top_level = true
	# Se orienta UNA sola vez mirando al objetivo
	look_at_from_position(objetivo.global_position + distancia, objetivo.global_position)

func _physics_process(delta):
	# se obtiene la posición y se limita el foco dentro del mundo
	var foco = objetivo.global_position
	foco.x = clamp(foco.x, limite_min.x, limite_max.x)
	foco.z = clamp(foco.z, limite_min.y, limite_max.y)
	
	#El destino se calcula a partir del foco limitado más la distancia
	var destino = foco + distancia
	global_position = global_position.lerp(destino, suavizado * delta)
	
