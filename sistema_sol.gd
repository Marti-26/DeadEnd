class_name SistemaSol
extends Node

@export var sol: DirectionalLight3D
@export var entorno: WorldEnvironment
@export var energia_sol := 1.0
@export var azimut := -30.0
@export var ambiente_dia := 1.0
@export var ambiente_noche := 0.2

@onready var ciclo: CicloDia = $CicloDia

func _ready() -> void:
	# Prueba de funciones puras requerida para la consola
	print("Puras a 9h y 20h: ", CicloDia.elevacion(9.0), " | ", CicloDia.factor_sol(9.0), " | ", CicloDia.factor_sol(20.0))
	aplicar_hora()

func _process(delta: float) -> void:
	ciclo.avanzar(delta)
	aplicar_hora()

func aplicar_hora() -> void:
	var h := ciclo.hora
	var f := CicloDia.factor_sol(h)
	
	sol.rotation_degrees = Vector3(-CicloDia.elevacion(h), azimut, 0.0)
	sol.light_energy = energia_sol * f
	sol.light_color = CicloDia.color_sol(h)
	
	if entorno and entorno.environment:
		entorno.environment.ambient_light_energy = lerpf(ambiente_noche, ambiente_dia, f)
