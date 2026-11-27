class_name Esconderse
extends Node

@export var tecla: String = "esconderse"
@export var grupo: String = Grupos.ESCONDITES
@export var alcance: float = 1.35
@export var baja_estres: float = 1.0
@export var hundir_modelo: float = 0.45
@export var animacion: String = "crouch"
@export var altura_ojos: float = 0.22
@export var adelanto_ojos: float = 0.1
@export var escala_ojos: float = 0.8
@export var entrada_frente: float = 0.45
@export var tiempo_acercarse: float = 0.15

@onready var pj: Personaje = get_parent() as Personaje
@onready var modelo: Node3D = (pj.get_node_or_null("Sprite") if pj.has_node("Sprite") else pj.get_node_or_null("Modelo")) as Node3D
@onready var forma: CollisionShape3D = pj.get_node_or_null("CollisionShape3D") as CollisionShape3D

var escondido: bool = false
var banca: Node3D = null
var _modelo_y: float = 0.0
var _sprite_pos: Vector3 = Vector3.ZERO
var _sprite_escala: Vector3 = Vector3.ONE
var _sprite_sombreado: bool = true
var _en_ojos: bool = false
var _saliendo: bool = false
var _entrando: bool = false
var _esperando_soltar: bool = false
var _debe_alejarse: bool = false


func _physics_process(delta: float) -> void:
	if escondido:
		var input_mov: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if input_mov.length() <= 0.1:
			_esperando_soltar = false
		var quiere_salir: bool = Input.is_action_just_pressed(tecla) or (input_mov.length() > 0.1 and not _esperando_soltar)
		if quiere_salir and not _entrando and not _saliendo:
			salir()
		elif pj != null and pj.has_method("sumar_estres"):
			pj.call("sumar_estres", -baja_estres * delta)
		else:
			Partida.estres = maxf(0.0, Partida.estres - baja_estres * delta)
	elif not _saliendo:
		var b: Node3D = mas_cercana() as Node3D
		if _debe_alejarse:
			if b == null:
				_debe_alejarse = false
		elif b != null:
			entrar(b)



func entrar(b):
	escondido = true
	banca = b
	_entrando = true

	# Reproducir maullido al entrar a la silla
	if pj.maullido_esconder != null:
		if pj.maullido_esconder.stream != null:
			pj.maullido_esconder.play()
			print("Gatita maulló al esconderse")

	_esperando_soltar = Input.get_vector("move_left", "move_right", "move_up", "move_down").length() > 0.1
	pj.add_to_group(Grupos.ESCONDIDOS)
	pj.sonido_pasos.stop()
	pj.set_physics_process(false)
	pj.velocity = Vector3.ZERO
	pj.avance = Vector3.ZERO
	pj.estado = pj.Estado.ESCONDERSE
	pj.ruido = 0.0

	if forma:
		forma.disabled = true

	print("escondida bajo ", b.name, " · estrés ", snappedf(Partida.estres, 0.1))

	if pj.sprite == null:
		pj.global_position = Vector3(b.global_position.x, pj.global_position.y, b.global_position.z)
		if modelo:
			_modelo_y = modelo.position.y
			modelo.position.y = _modelo_y - hundir_modelo
		pj.anim.play(animacion)
		_entrando = false
		return

	var sprite: AnimatedSprite3D = pj.sprite
	var local: Vector3 = b.to_local(pj.global_position)
	var dir: String = "espalda"

	if absf(local.x) > 0.9 or local.z < 0.0:
		dir = "izquierda" if local.x > 0.0 else "derecha"

	var nombre: String = "esconderse_" + dir

	if not sprite.sprite_frames.has_animation(nombre):
		dir = "espalda"
		nombre = "esconderse_espalda"

	pj.direccion = dir

	var destino: Vector3 = b.to_global(Vector3(clampf(local.x, -0.6, 0.6), 0.0, entrada_frente))
	destino.y = pj.global_position.y

	var t: Tween = create_tween()
	t.tween_property(pj, "global_position", destino, tiempo_acercarse)

	sprite.stop()
	sprite.speed_scale = 1.0
	sprite.play(nombre)

	await sprite.animation_finished
	_entrando = false

	if not escondido or banca != b:
		return

	_mostrar_ojos(b)



func _mostrar_ojos(b):
	if _en_ojos:
		return
	var sprite: AnimatedSprite3D = pj.sprite
	pj.global_position = Vector3(b.global_position.x, pj.global_position.y, b.global_position.z)
	_sprite_pos = sprite.position
	_sprite_escala = sprite.scale
	_sprite_sombreado = sprite.shaded
	sprite.global_position = Vector3(b.global_position.x, b.global_position.y + altura_ojos, b.global_position.z + adelanto_ojos)
	sprite.scale = Vector3.ONE * escala_ojos
	sprite.shaded = false
	sprite.speed_scale = 1.0
	sprite.play("esconderse_ojos")
	_en_ojos = true


func _quitar_ojos():
	if not _en_ojos:
		return
	var sprite: AnimatedSprite3D = pj.sprite
	sprite.position = _sprite_pos
	sprite.scale = _sprite_escala
	sprite.shaded = _sprite_sombreado
	_en_ojos = false


func salir():
	escondido = false
	_debe_alejarse = true
	pj.remove_from_group(Grupos.ESCONDIDOS)
	pj.global_position = banca.global_position + Vector3(0, pj.global_position.y - banca.global_position.y, 0.75)
	print("sale de ", banca.name, " · estrés ", snappedf(Partida.estres, 0.1))
	banca = null
	if pj.sprite:
		_quitar_ojos()
		pj.direccion = "frente"
		if pj.sprite.sprite_frames.has_animation("salir_escondite_frente"):
			_saliendo = true
			pj.sprite.stop()
			pj.sprite.speed_scale = 1.0
			pj.sprite.play("salir_escondite_frente")
			await pj.sprite.animation_finished
			_saliendo = false
		pj.reproducir("idle")
	elif modelo:
		modelo.position.y = _modelo_y
	if forma:
		forma.disabled = false
	pj.set_physics_process(true)


func mas_cercana():
	var mejor = null
	for b in get_tree().get_nodes_in_group(grupo):
		var d = distancia_a(b)
		if d <= alcance and (mejor == null or d < distancia_a(mejor)):
			mejor = b
	return mejor


func distancia_a(obj):
	var a = Vector2(pj.global_position.x, pj.global_position.z)
	var b = Vector2(obj.global_position.x, obj.global_position.z)
	return a.distance_to(b)
