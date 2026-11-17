
class_name Dialogo
extends CanvasLayer

const GRUPO: StringName = &"dialogo"
const ESCENA: String = "res://dialogo.tscn"

@export var letras_por_segundo: float = 32.0
@export var tiempo_fundido: float = 0.3
@export var rojo_enemigo: Color = Color(1.0, 0.16, 0.2)
@export var rojo_texto_enemigo: Color = Color(1.0, 0.7, 0.7)
@export var borde_letra_enemigo: Color = Color(0.45, 0.02, 0.05, 0.9)
@export var brillo_letra_enemigo: Color = Color(1.0, 0.12, 0.18, 0.45)

@onready var cuadro: Control = $Cuadro
@onready var nombre: Label = $Cuadro/Columnas/Nombre
@onready var texto: Label = $Cuadro/Columnas/Texto
@onready var sonido_texto: AudioStreamPlayer = $Dialogo

var _letras: float = 0.0
var _restante: float = 0.0
var _tween: Tween = null
var _estilo_normal: StyleBox = null
var _estilo_enemigo: StyleBox = null
var _color_nombre: Color = Color.WHITE


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
	_estilo_normal = cuadro.get_theme_stylebox("panel")
	_color_nombre = nombre.get_theme_color("font_color")
	if _estilo_normal is StyleBoxFlat:
		var rojo: StyleBoxFlat = _estilo_normal.duplicate() as StyleBoxFlat
		rojo.border_color = Color(rojo_enemigo.r, rojo_enemigo.g, rojo_enemigo.b, 0.85)
		rojo.shadow_color = Color(rojo_enemigo.r, rojo_enemigo.g * 0.3, rojo_enemigo.b * 0.5, 0.2)
		rojo.bg_color = Color(0.035, 0.005, 0.01, 0.88)
		_estilo_enemigo = rojo

	# No reproducir audio al iniciar
	if sonido_texto != null:
		sonido_texto.stop()


func _process(delta: float) -> void:
	if not cuadro.visible:
		if sonido_texto.playing:
			sonido_texto.stop()
		return

	# Animación de escritura del diálogo
	if texto.visible_characters >= 0 and texto.visible_characters < texto.get_total_character_count():
		_letras += letras_por_segundo * delta
		texto.visible_characters = mini(
			int(_letras),
			texto.get_total_character_count()
		)

	# Mantener el sonido mientras esté el diálogo
	if sonido_texto.stream != null and _restante > 0.0:
		if not sonido_texto.playing:
			sonido_texto.play()

	# Tiempo de duración del diálogo
	if _restante > 0.0:
		_restante -= delta

		if _restante <= 0.0:
			ocultar()


func mostrar(quien: String, frase: String, duracion: float = 4.0, enemigo: bool = false) -> void:
	_aplicar_estilo(enemigo)
	nombre.text = quien
	texto.text = frase
	texto.visible_characters = 0

	_letras = 0.0
	_restante = maxf(
		duracion,
		frase.length() / letras_por_segundo + 1.5
	)

	var estaba_oculto: bool = not cuadro.visible
	cuadro.visible = true

	# Iniciar sonido al mostrar un diálogo
	iniciar_sonido_dialogo()

	# Animación visual del cuadro
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

	# Detener inmediatamente el sonido
	if sonido_texto != null:
		sonido_texto.stop()

	if not cuadro.visible:
		return

	if _tween != null:
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(
		cuadro,
		"modulate:a",
		0.0,
		tiempo_fundido
	)

	_tween.tween_callback(
		func() -> void:
			cuadro.visible = false
	)


func _aplicar_estilo(enemigo: bool) -> void:
	if enemigo and _estilo_enemigo != null:
		cuadro.add_theme_stylebox_override("panel", _estilo_enemigo)
		nombre.add_theme_color_override("font_color", rojo_enemigo)
		texto.add_theme_color_override("font_color", rojo_texto_enemigo)
		for etiqueta: Label in [nombre, texto]:
			etiqueta.add_theme_color_override("font_outline_color", borde_letra_enemigo)
			etiqueta.add_theme_color_override("font_shadow_color", brillo_letra_enemigo)
	else:
		if _estilo_normal != null:
			cuadro.add_theme_stylebox_override("panel", _estilo_normal)
		nombre.add_theme_color_override("font_color", _color_nombre)
		texto.remove_theme_color_override("font_color")
		for etiqueta: Label in [nombre, texto]:
			etiqueta.remove_theme_color_override("font_outline_color")
			etiqueta.remove_theme_color_override("font_shadow_color")


func esta_visible() -> bool:
	return cuadro.visible and _restante > 0.0


func iniciar_sonido_dialogo() -> void:
	if sonido_texto == null or sonido_texto.stream == null:
		return

	sonido_texto.stop()
	sonido_texto.play()
