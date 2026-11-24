
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
@export var altura_retrato: float = 0.55
@export var retrato_tapado: float = 0.3
@export var salto_retrato: float = 22.0
@export var tecla_cerrar: StringName = &"hablar"

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
var _retrato: TextureRect = null
var _marcos: SpriteFrames = null
var _animacion: StringName = &"default"
var _cuadro_retrato: int = 0
var _tiempo_retrato: float = 0.0
var _base_retrato: float = 0.0
var _tween_salto: Tween = null
var _persistente: bool = false
var _desde_mostrado: float = 0.0
var _aviso: Label = null
var _parpadeo: float = 0.0


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
	_retrato = TextureRect.new()
	_retrato.name = "Retrato"
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_retrato.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_retrato.visible = false
	add_child(_retrato)
	move_child(_retrato, 0)
	_aviso = Label.new()
	_aviso.name = "AvisoCerrar"
	_aviso.text = "[R]"
	_aviso.add_theme_font_size_override("font_size", 16)
	_aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aviso.visible = false
	add_child(_aviso)
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
	_animar_retrato(delta)
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

	var escribiendo: bool = texto.visible_characters >= 0 and texto.visible_characters < texto.get_total_character_count()

	# Mantener el sonido mientras esté el diálogo
	if sonido_texto.stream != null and escribiendo:
		if not sonido_texto.playing:
			sonido_texto.play()
	elif sonido_texto.playing:
		sonido_texto.stop()

	_actualizar_aviso(delta, escribiendo)
	_desde_mostrado += delta
	if _persistente and _desde_mostrado > 0.12 and Input.is_action_just_pressed(tecla_cerrar):
		if escribiendo:
			_letras = float(texto.get_total_character_count())
			texto.visible_characters = texto.get_total_character_count()
		else:
			ocultar()
		return

	# Tiempo de duración del diálogo
	if _restante > 0.0:
		_restante -= delta

		if _restante <= 0.0:
			ocultar()


func mostrar(quien: String, frase: String, duracion: float = 4.0, enemigo: bool = false, marcos: SpriteFrames = null, animacion: StringName = &"default") -> void:
	_aplicar_estilo(enemigo)
	_poner_retrato(marcos, animacion)
	nombre.text = quien
	texto.text = frase
	texto.visible_characters = 0

	_letras = 0.0
	_persistente = not enemigo
	_desde_mostrado = 0.0
	_restante = 0.0 if _persistente else maxf(
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

	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(cuadro, "modulate:a", 1.0, tiempo_fundido * 0.6)


func ocultar() -> void:
	_restante = 0.0
	_persistente = false
	if _aviso != null:
		_aviso.visible = false

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


func _poner_retrato(marcos: SpriteFrames, animacion: StringName) -> void:
	if marcos == null or not marcos.has_animation(animacion) or marcos.get_frame_count(animacion) == 0:
		_marcos = null
		_retrato.visible = false
		return
	var mismo: bool = marcos == _marcos and animacion == _animacion and _retrato.visible
	_marcos = marcos
	_animacion = animacion
	if not mismo:
		_cuadro_retrato = 0
		_tiempo_retrato = 0.0
		_retrato.texture = marcos.get_frame_texture(animacion, 0)
		_retrato.modulate.a = cuadro.modulate.a if cuadro.visible else 0.0
	_ubicar_retrato()
	_retrato.visible = true
	_saltar_retrato()


func _ubicar_retrato() -> void:
	var textura: Texture2D = _retrato.texture
	if textura == null:
		return
	var pantalla: Vector2 = get_viewport().get_visible_rect().size
	var alto: float = pantalla.y * altura_retrato
	var ancho: float = alto * float(textura.get_width()) / float(textura.get_height())
	_retrato.size = Vector2(ancho, alto)
	var arriba_caja: float = pantalla.y * cuadro.anchor_top + cuadro.offset_top
	var derecha_caja: float = pantalla.x * cuadro.anchor_right + cuadro.offset_right
	_base_retrato = arriba_caja - alto * (1.0 - retrato_tapado)
	_retrato.position = Vector2(derecha_caja - ancho - 12.0, _base_retrato)


func _saltar_retrato() -> void:
	if _tween_salto != null:
		_tween_salto.kill()
	_retrato.position.y = _base_retrato
	_tween_salto = create_tween()
	_tween_salto.tween_property(_retrato, "position:y", _base_retrato - salto_retrato, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween_salto.tween_property(_retrato, "position:y", _base_retrato, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _animar_retrato(delta: float) -> void:
	if _retrato == null:
		return
	if not cuadro.visible or _marcos == null:
		_retrato.visible = false
		return
	_retrato.modulate.a = cuadro.modulate.a
	var cantidad: int = _marcos.get_frame_count(_animacion)
	if cantidad <= 1:
		return
	_tiempo_retrato += delta * _marcos.get_animation_speed(_animacion)
	if _tiempo_retrato >= 1.0:
		_tiempo_retrato -= 1.0
		_cuadro_retrato = (_cuadro_retrato + 1) % cantidad
		_retrato.texture = _marcos.get_frame_texture(_animacion, _cuadro_retrato)


func esta_visible() -> bool:
	return cuadro.visible and (_persistente or _restante > 0.0)


func _actualizar_aviso(delta: float, escribiendo: bool) -> void:
	if _aviso == null:
		return
	if not _persistente or escribiendo:
		_aviso.visible = false
		_parpadeo = 0.0
		return
	_parpadeo += delta
	_aviso.visible = true
	_aviso.modulate.a = (0.55 + 0.45 * sin(_parpadeo * 4.0)) * cuadro.modulate.a
	var caja: Rect2 = cuadro.get_global_rect()
	_aviso.position = caja.end - _aviso.size - Vector2(18.0, 10.0)


func iniciar_sonido_dialogo() -> void:
	if sonido_texto == null or sonido_texto.stream == null:
		return

	sonido_texto.stop()
	sonido_texto.play()
