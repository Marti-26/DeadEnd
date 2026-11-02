class_name SistemaSol
extends Node
signal cambio_noche(es_noche: bool) 

@export var sol: DirectionalLight3D
@export var entorno: WorldEnvironment
@export var energia_sol := 1.0
@export var azimut := -30.0
@export var ambiente_dia := 1.0
@export var ambiente_noche := 0.2

@onready var ciclo: CicloDia = $CicloDia

var era_noche := false

func _ready() -> void:
	# Prueba de funciones puras requerida para la consola
	print("Puras a 9h y 20h: ", CicloDia.elevacion(9.0), " | ", CicloDia.factor_sol(9.0), " | ", CicloDia.factor_sol(20.0))
	aplicar_hora()
	era_noche = CicloDia.factor_sol(ciclo.hora) <= 0.0

func _process(delta: float) -> void:
	ciclo.avanzar(delta)
	aplicar_hora()
	var es_noche := CicloDia.factor_sol(ciclo.hora) <= 0.0
	if es_noche != era_noche:
		era_noche = es_noche
		cambio_noche.emit(es_noche)

func aplicar_hora() -> void:
	var h := ciclo.hora
	var f := CicloDia.factor_sol(h)
	
	sol.rotation_degrees = Vector3(-CicloDia.elevacion(h), azimut, 0.0)
	sol.light_energy = energia_sol * f
	sol.light_color = CicloDia.color_sol(h)
	
	if entorno and entorno.environment:
		entorno.environment.ambient_light_energy = lerpf(ambiente_noche, ambiente_dia, f)
		
static func lambert(normal: Vector3, hacia_luz: Vector3) -> float:
	var n := normal.normalized()
	var l := hacia_luz.normalized()
	return maxf(0.0, n.dot(l))

func prediccion_piso() -> float:
	# El sol alumbra hacia -Z local; por ende, hacia la luz es su +Z global en el mundo
	var hacia_luz: Vector3 = sol.global_transform.basis.z
	var normal_piso := Vector3.UP # (0, 1, 0)
	var lamber := lambert(normal_piso, hacia_luz)
	return sol.light_energy * sol.light_color.r * lamber
