class_name Dialogo
extends CanvasLayer

const GRUPO: StringName = &"dialogo"
const ESCENA: String = "res://dialogo.tscn"

@export var letras_por_segundo: float = 32.0
@export var tiempo_fundido: float = 0.3

@onready var cuadro: Control = $Cuadro
@onready var nombre: Label = $Cuadro/Columnas/Nombre
@onready var texto: Label = $Cuadro/Columnas/Texto

var _letras: float = 0.0
var _restante: float = 0.0
var _tween: Tween = null


static func obtener(arbol: SceneTree) -> Dialogo:
	var d: Dialogo = arbol.get_first_node_in_group(GRUPO) as Dialogo
	if d == null:
		d = (load(ESCENA) as PackedScene).instantiate() as Dialogo
		var destino: Node = arbol.current_scene if arbol.current_scene != null else arbol.root
		destino.add_child(d)
	return d


func _enter_tree() -> void:
	add_to_group(GRUPO)


func _ready() -> void:
	cuadro.visible = false
	cuadro.modulate.a = 0.0


func _process(delta: float) -> void:
	if not cuadro.visible:
		return
	if texto.visible_characters >= 0 and texto.visible_characters < texto.get_total_character_count():
		_letras += letras_por_segundo * delta
		texto.visible_characters = int(_letras)
	if _restante > 0.0:
		_restante -= delta
		if _restante <= 0.0:
			ocultar()


func mostrar(quien: String, frase: String, duracion: float = 4.0) -> void:
	nombre.text = quien
	texto.text = frase
	texto.visible_characters = 0
	_letras = 0.0
	_restante = maxf(duracion, frase.length() / letras_por_segundo + 1.5)
	var estaba_oculto: bool = not cuadro.visible
	cuadro.visible = true
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	if estaba_oculto:
		cuadro.modulate.a = 0.0
		_tween.tween_property(cuadro, "modulate:a", 0.8, 0.05)
		_tween.tween_property(cuadro, "modulate:a", 0.15, 0.05)
		_tween.tween_property(cuadro, "modulate:a", 1.0, 0.06)
		_tween.tween_property(cuadro, "modulate:a", 0.45, 0.04)
	_tween.tween_property(cuadro, "modulate:a", 1.0, 0.1)


func ocultar() -> void:
	_restante = 0.0
	if not cuadro.visible:
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(cuadro, "modulate:a", 0.0, tiempo_fundido)
	_tween.tween_callback(func() -> void: cuadro.visible = false)


func esta_visible() -> bool:
	return cuadro.visible and _restante > 0.0
