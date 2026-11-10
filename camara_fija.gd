extends Camera3D

@export var objetivo: Node3D
@export var desfase := Vector3(0, 14.141, 15.253)
@export var limite_x := 10.2
@export var limite_z := Vector2(-1.2, 3.7)
@export var suavizado := 4.0


func _ready() -> void:
	saltar()


func saltar() -> void:
	if objetivo:
		global_position = _meta()


func _process(delta: float) -> void:
	if objetivo == null:
		return
	global_position = global_position.lerp(_meta(), 1.0 - exp(-suavizado * delta))


func _meta() -> Vector3:
	var p := objetivo.global_position
	return Vector3(clampf(p.x, -limite_x, limite_x), 0.0, clampf(p.z, limite_z.x, limite_z.y)) + desfase
