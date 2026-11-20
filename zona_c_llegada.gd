extends Node

@onready var metro: Metro = $"../MetroLlegada"
@onready var gata: Personaje = $"../Personaje"

func _ready() -> void:
    metro.camara_vagon.size = 7.8
    metro.camara_vagon.far = 80.0
    metro.distancia = 3.0
    metro.tiempo_frenado = 3.0
    metro.tiempo_detenido = 99999.0
    metro.tren.position.x = metro.x_parada + metro.distancia
    metro._x_antes = metro.tren.position.x
    gata.global_position = metro.tren.to_global(Vector3(0, 0.3, 0))
    metro._capas_plataforma = gata.platform_floor_layers
    gata.platform_floor_layers = 0
    gata.set_physics_process(false)
    metro.viajando = true
    metro.viaje_final_pendiente = false
    metro.cambiando_zona_c = false
    metro.llego.connect(_al_llegar)
    metro._entrar_vista()
    metro._cambiar(Metro.Estado.LLEGANDO)

func _al_llegar() -> void:
    gata.set_physics_process(true)
    print("Zona C: metro detenido, puertas abriendo. Sal por la puerta hacia el andén.")
