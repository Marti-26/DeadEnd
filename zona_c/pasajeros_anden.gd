extends Node3D

const SombraPies = preload("res://sombra_pies.gd")
const EXTREMO_DERECHO := 31.0
const INTERVALO := 0.85
const PEATONES_POR_GRUPO := 2
const MAXIMO_PEATONES := 16
const MARGEN_ENTRADA := 2.2
const CARRILES := [-1.65, 2.8, 0.15, 4.2]
const VELOCIDADES := [2.65, 2.95, 2.8, 3.1]
const MODELOS := [
	preload("res://personaje/character-female-b.glb"),
	preload("res://personaje/character-male-a.glb"),
	preload("res://personaje/character-female-e.glb"),
	preload("res://personaje/character-male-d.glb"),
]

class Peaton extends Node3D:
	var modelo: Node3D
	var carril: float
	var direccion: float
	var rapidez: float

	func caminar(delta: float, jugador: Vector3) -> void:
		position.x += direccion * rapidez * delta
		var carril_objetivo := carril
		if absf(jugador.x - position.x) < 2.0 and absf(jugador.z - carril) < 0.9:
			carril_objetivo += -1.0 if carril > 1.2 else 1.0
		position.z = move_toward(position.z, carril_objetivo, 2.5 * delta)
		var giro := atan2(direccion * rapidez, (carril_objetivo - position.z) * 2.0)
		rotation.y = lerp_angle(rotation.y, giro, 1.0 - exp(-12.0 * delta))

@export var jugador: Node3D
@export var camara: Camera3D
@export var letrero_exit: Node3D

var peatones: Array[Peaton] = []
var espera := 0.0
var entradas := 0

func _process(delta: float) -> void:
	if jugador == null or camara == null or get_viewport().get_camera_3d() != camara:
		return
	var inicio := letrero_exit.global_position.x + 0.6
	for i in range(peatones.size() - 1, -1, -1):
		var peaton := peatones[i]
		peaton.caminar(delta, jugador.global_position)
		var limite := EXTREMO_DERECHO if peaton.direccion > 0.0 else inicio
		if (peaton.position.x - limite) * peaton.direccion >= 0.0:
			peaton.position.x = limite
			if _fuera_de_cuadro(peaton.global_position + Vector3.UP):
				peatones.remove_at(i)
				peaton.queue_free()
			else:
				peaton.direccion *= -1.0

	espera -= delta
	if espera > 0.0 or jugador.global_position.x < inicio:
		return
	var plazas := mini(PEATONES_POR_GRUPO, MAXIMO_PEATONES - peatones.size())
	for i in range(plazas):
		var lado := -1.0 if entradas % 3 == 1 else 1.0
		if _entrar(lado, inicio) or _entrar(-lado, inicio):
			entradas += 1
			espera = INTERVALO
		else:
			break

func _entrar(lado: float, inicio: float) -> bool:
	var carril: float = CARRILES[entradas % CARRILES.size()]
	var x := camara.global_position.x + lado * (camara.size * 0.5 + MARGEN_ENTRADA)
	if x <= inicio or x >= EXTREMO_DERECHO:
		return false
	var origen := Vector3(x, 0.02, carril)
	if not _fuera_de_cuadro(to_global(origen + Vector3.UP)):
		return false
	var peaton := Peaton.new()
	peaton.modelo = MODELOS[entradas % MODELOS.size()].instantiate() as Node3D
	peaton.modelo.scale = Vector3.ONE * 2.8
	peaton.name = "%s_%d" % [peaton.modelo.name, entradas + 1]
	peaton.position = origen
	peaton.carril = carril
	peaton.direccion = -lado
	peaton.rapidez = VELOCIDADES[entradas % VELOCIDADES.size()]
	peaton.rotation.y = peaton.direccion * PI * 0.5
	peaton.add_child(peaton.modelo)
	var sombra := SombraPies.new()
	sombra.tamano = Vector2(0.7, 0.4)
	peaton.add_child(sombra)
	add_child(peaton)
	var animador := peaton.modelo.get_node("AnimationPlayer") as AnimationPlayer
	var caminata := animador.get_animation(&"walk")
	caminata.loop_mode = Animation.LOOP_LINEAR
	animador.play(&"walk", -1.0, peaton.rapidez / 2.35)
	animador.seek(caminata.length * fmod(entradas * 0.37, 1.0), true)
	peatones.append(peaton)
	return true

func _fuera_de_cuadro(punto: Vector3) -> bool:
	var pantalla := camara.get_viewport().get_visible_rect()
	var proyeccion := camara.unproject_position(punto)
	return proyeccion.x < pantalla.position.x - pantalla.size.x * 0.07 or proyeccion.x > pantalla.end.x + pantalla.size.x * 0.07
