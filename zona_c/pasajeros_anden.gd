extends Node3D

const SombraPies = preload("res://sombra_pies.gd")
const DISTANCIA_DESPUES_DEL_EXIT := 3.5
const LIMITE_ANDEN := 33.5
const PROGRESO_ENTRADA_ESCALERAS := 0.45
const ALTURA_SOBRE_PISO := 0.02
const DISTANCIA_DESVANECER := 2.5
const DISTANCIA_DESVANECER_SALIDA := 1.25
const INTERVALO_INICIAL := 2.6
const INTERVALO_FINAL := 0.50
const MAXIMO_INICIAL := 2
const MAXIMO_FINAL := 20
const MAXIMO_POR_GRUPO := 3
const MARGEN_ENTRADA := 2.2
const SEPARACION_ENTRADA := 0.9
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
	var sombra: SombraPies
	var desde_escaleras := false
	var materiales_salida: Array[StandardMaterial3D] = []

	func caminar(delta: float, jugador: Vector3) -> void:
		position.x += direccion * rapidez * delta
		var carril_objetivo := carril
		if absf(jugador.x - position.x) < 2.0 and absf(jugador.z - carril) < 0.9:
			carril_objetivo += -1.0 if carril > 1.2 else 1.0
		position.z = move_toward(position.z, carril_objetivo, 2.5 * delta)
		var giro := atan2(direccion * rapidez, (carril_objetivo - position.z) * 2.0)
		rotation.y = lerp_angle(rotation.y, giro, 1.0 - exp(-12.0 * delta))

	func desvanecer(opacidad: float) -> void:
		if materiales_salida.is_empty():
			for nodo in modelo.find_children("*", "MeshInstance3D", true, false):
				var malla := nodo as MeshInstance3D
				if malla.mesh == null:
					continue
				for i in range(malla.mesh.get_surface_count()):
					var original := malla.get_active_material(i) as StandardMaterial3D
					if original == null:
						continue
					var material := original.duplicate() as StandardMaterial3D
					material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					malla.set_surface_override_material(i, material)
					materiales_salida.append(material)
		for material in materiales_salida:
			var color := material.albedo_color
			color.a = opacidad
			material.albedo_color = color
		sombra.opacidad = 0.45 * opacidad

@export var jugador: Node3D
@export var camara: Camera3D
@export var letrero_exit: Node3D
@export var escaleras: Node3D

@onready var descanso: MeshInstance3D = escaleras.get_node("Descanso/Malla")

var peatones: Array[Peaton] = []
var peldanos: Array[MeshInstance3D] = []
var inicio_escaleras: float
var fin_escaleras: float
var altura_descanso: float
var espera := 0.0
var entradas := 0

func _ready() -> void:
	inicio_escaleras = to_local(escaleras.global_position).x
	for nodo in escaleras.get_children():
		if nodo is MeshInstance3D and nodo.name.begins_with("Escalon") and nodo.mesh is BoxMesh:
			peldanos.append(nodo)
	peldanos.append(descanso)
	var borde_malla := descanso.get_aabb().end
	var borde_descanso := to_local(descanso.to_global(Vector3(borde_malla.x, borde_malla.y, 0.0)))
	fin_escaleras = borde_descanso.x
	altura_descanso = borde_descanso.y

func _process(delta: float) -> void:
	if jugador == null or camara == null or letrero_exit == null or get_viewport().get_camera_3d() != camara:
		return
	var posicion_jugador := to_local(jugador.global_position)
	var posicion_camara_x := to_local(camara.global_position).x
	var inicio := to_local(letrero_exit.global_position).x + DISTANCIA_DESPUES_DEL_EXIT

	for i in range(peatones.size() - 1, -1, -1):
		var peaton := peatones[i]
		peaton.caminar(delta, posicion_jugador)
		var hacia_salida := peaton.direccion > 0.0
		var limite := fin_escaleras if hacia_salida else inicio
		var distancia := (limite - peaton.position.x) * peaton.direccion
		var se_acerca_desde_escaleras := peaton.desde_escaleras and peaton.position.x > posicion_camara_x
		if distancia <= 0.0 or (not se_acerca_desde_escaleras and _fuera_de_cuadro(peaton.global_position + Vector3.UP, 0.65)):
			peatones.remove_at(i)
			peaton.queue_free()
			continue
		if peaton.position.x >= inicio_escaleras:
			_ajustar_altura_escaleras(peaton, delta)
		elif peaton.desde_escaleras:
			peaton.sombra.altura_visual_piso = NAN
			peaton.position.y = move_toward(peaton.position.y, ALTURA_SOBRE_PISO, 5.0 * delta)
		var tramo_final := DISTANCIA_DESVANECER_SALIDA if hacia_salida else DISTANCIA_DESVANECER
		if distancia < tramo_final:
			peaton.desvanecer(smoothstep(0.0, tramo_final, distancia))

	if posicion_jugador.x < inicio:
		espera = 0.0
		return

	var progreso := clampf(inverse_lerp(inicio, LIMITE_ANDEN, posicion_jugador.x), 0.0, 1.0)
	var avance := ease(progreso, 0.5)
	var intervalo := lerpf(INTERVALO_INICIAL, INTERVALO_FINAL, avance)
	espera -= delta / intervalo
	if espera > 0.0:
		return

	var maximo := roundi(lerpf(MAXIMO_INICIAL, MAXIMO_FINAL, avance))
	var grupo := roundi(lerpf(1, MAXIMO_POR_GRUPO, avance))
	var plazas := mini(grupo, maximo - peatones.size())
	for i in range(plazas):
		if progreso >= PROGRESO_ENTRADA_ESCALERAS and entradas % 3 == 0:
			var peaton := _crear_peaton(fin_escaleras, altura_descanso + ALTURA_SOBRE_PISO, -1.0)
			peaton.desde_escaleras = true
			peaton.sombra.altura_visual_piso = to_global(Vector3.UP * altura_descanso).y
		else:
			var lado := -1.0 if entradas % 3 == 1 else 1.0
			var separacion := i * SEPARACION_ENTRADA
			if not (_entrar(lado, inicio, separacion) or _entrar(-lado, inicio, separacion)):
				continue
		entradas += 1
		espera = 1.0

func _ajustar_altura_escaleras(peaton: Peaton, delta: float) -> void:
	for peldano in peldanos:
		var punto := peldano.to_local(peaton.global_position)
		var limites := peldano.get_aabb()
		if punto.x >= limites.position.x and punto.x < limites.end.x:
			var superficie := peldano.to_global(Vector3.UP * limites.end.y)
			peaton.sombra.altura_visual_piso = superficie.y
			var altura := to_local(superficie).y + ALTURA_SOBRE_PISO
			peaton.position.y = move_toward(peaton.position.y, altura, 5.0 * delta)
			return

func _entrar(lado: float, inicio: float, separacion: float) -> bool:
	var carril: float = CARRILES[entradas % CARRILES.size()]
	var distancia := camara.size * 0.5 + MARGEN_ENTRADA + separacion
	var x := to_local(camara.global_position).x + lado * distancia
	if x <= inicio or x >= LIMITE_ANDEN:
		return false
	var origen := Vector3(x, ALTURA_SOBRE_PISO, carril)
	if not _fuera_de_cuadro(to_global(origen + Vector3.UP)):
		return false
	_crear_peaton(x, ALTURA_SOBRE_PISO, -lado)
	return true

func _crear_peaton(x: float, altura: float, direccion: float) -> Peaton:
	var peaton := Peaton.new()
	peaton.modelo = MODELOS[entradas % MODELOS.size()].instantiate() as Node3D
	peaton.modelo.scale = Vector3.ONE * 2.8
	peaton.name = "%s_%d" % [peaton.modelo.name, entradas + 1]
	peaton.carril = CARRILES[entradas % CARRILES.size()]
	peaton.position = Vector3(x, altura, peaton.carril)
	peaton.direccion = direccion
	peaton.rapidez = VELOCIDADES[entradas % VELOCIDADES.size()]
	peaton.rotation.y = peaton.direccion * PI * 0.5
	peaton.add_child(peaton.modelo)
	peaton.sombra = SombraPies.new()
	peaton.sombra.tamano = Vector2(0.7, 0.4)
	peaton.add_child(peaton.sombra)
	add_child(peaton)
	var animador := peaton.modelo.get_node("AnimationPlayer") as AnimationPlayer
	var caminata := animador.get_animation(&"walk")
	caminata.loop_mode = Animation.LOOP_LINEAR
	animador.play(&"walk", -1.0, peaton.rapidez / 2.35)
	animador.seek(caminata.length * fmod(entradas * 0.37, 1.0), true)
	peatones.append(peaton)
	return peaton

func _fuera_de_cuadro(punto: Vector3, margen: float = 0.07) -> bool:
	var pantalla := camara.get_viewport().get_visible_rect()
	var proyeccion := camara.unproject_position(punto)
	var margen_px := pantalla.size.x * margen
	return proyeccion.x < pantalla.position.x - margen_px or proyeccion.x > pantalla.end.x + margen_px
