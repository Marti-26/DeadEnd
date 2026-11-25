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
const ATLAS_ANIMALES := preload("res://assets/animales_aventureros.png")
const ANIMALES: Array[StringName] = [&"Zorro", &"Gato", &"Rana", &"Nutria", &"Conejo", &"Cuervo", &"Lobo"]
const TAMANO_FOTOGRAMA := Vector2i(224, 152)
const FOTOGRAMAS_CAMINATA := 5
const TAMANO_PIXEL := 0.014
const ALTURA_CENTRO_SPRITE := 72.5 * TAMANO_PIXEL

class Peaton extends Node3D:
	var sprite: AnimatedSprite3D
	var carril: float
	var direccion: float
	var rapidez: float
	var sombra: SombraPies
	var desde_escaleras := false

	func caminar(delta: float, jugador: Vector3) -> void:
		position.x += direccion * rapidez * delta
		var carril_objetivo := carril
		if absf(jugador.x - position.x) < 2.0 and absf(jugador.z - carril) < 0.9:
			carril_objetivo += -1.0 if carril > 1.2 else 1.0
		position.z = move_toward(position.z, carril_objetivo, 2.5 * delta)

	func desvanecer(opacidad: float) -> void:
		sprite.modulate.a = opacidad
		sombra.opacidad = 0.45 * opacidad

@export var jugador: Node3D
@export var camara: Camera3D
@export var letrero_exit: Node3D
@export var escaleras: Node3D

@onready var descanso: MeshInstance3D = escaleras.get_node("Descanso/Malla")

var peatones: Array[Peaton] = []
var peldanos: Array[MeshInstance3D] = []
var marcos_animales: SpriteFrames
var inicio_escaleras: float
var fin_escaleras: float
var altura_descanso: float
var espera := 0.0
var entradas := 0

func _ready() -> void:
	marcos_animales = _crear_marcos_animales()
	inicio_escaleras = to_local(escaleras.global_position).x
	for nodo in escaleras.get_children():
		if nodo is MeshInstance3D and nodo.name.begins_with("Escalon") and nodo.mesh is BoxMesh:
			peldanos.append(nodo)
	peldanos.append(descanso)
	var borde_malla := descanso.get_aabb().end
	var borde_descanso := to_local(descanso.to_global(Vector3(borde_malla.x, borde_malla.y, 0.0)))
	fin_escaleras = borde_descanso.x
	altura_descanso = borde_descanso.y

func _crear_marcos_animales() -> SpriteFrames:
	var marcos := SpriteFrames.new()
	marcos.remove_animation(&"default")
	for fila in range(ANIMALES.size()):
		var animal := ANIMALES[fila]
		marcos.add_animation(animal)
		marcos.set_animation_speed(animal, 7.0)
		for columna in range(1, FOTOGRAMAS_CAMINATA + 1):
			var fotograma := AtlasTexture.new()
			fotograma.atlas = ATLAS_ANIMALES
			fotograma.region = Rect2(Vector2i(columna, fila) * TAMANO_FOTOGRAMA, TAMANO_FOTOGRAMA)
			fotograma.filter_clip = true
			marcos.add_frame(animal, fotograma)
	return marcos

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
	var animal := ANIMALES[entradas % ANIMALES.size()]
	peaton.name = "%s_%d" % [animal, entradas + 1]
	peaton.carril = CARRILES[entradas % CARRILES.size()]
	peaton.position = Vector3(x, altura, peaton.carril)
	peaton.direccion = direccion
	peaton.rapidez = VELOCIDADES[entradas % VELOCIDADES.size()]
	peaton.sprite = AnimatedSprite3D.new()
	peaton.sprite.sprite_frames = marcos_animales
	peaton.sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	peaton.sprite.shaded = true
	peaton.sprite.flip_h = direccion < 0.0
	peaton.sprite.pixel_size = TAMANO_PIXEL
	peaton.sprite.position.y = ALTURA_CENTRO_SPRITE
	peaton.add_child(peaton.sprite)
	peaton.sombra = SombraPies.new()
	peaton.sombra.tamano = Vector2(0.7, 0.4)
	peaton.add_child(peaton.sombra)
	add_child(peaton)
	peaton.sprite.play(animal, peaton.rapidez / 2.35)
	peaton.sprite.set_frame_and_progress(entradas % FOTOGRAMAS_CAMINATA, 0.0)
	peatones.append(peaton)
	return peaton

func _fuera_de_cuadro(punto: Vector3, margen: float = 0.07) -> bool:
	var pantalla := camara.get_viewport().get_visible_rect()
	var proyeccion := camara.unproject_position(punto)
	var margen_px := pantalla.size.x * margen
	return proyeccion.x < pantalla.position.x - margen_px or proyeccion.x > pantalla.end.x + margen_px
