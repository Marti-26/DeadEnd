extends Node3D

@onready var personaje: CharacterBody3D = $Personaje
@onready var luces: Node3D = $Luces
@onready var ambiente: WorldEnvironment = $WorldEnvironment

var energias: Dictionary = {}
var avance_maximo: float = -27.0
var terminado: bool = false

func _ready() -> void:
	ambiente.environment = ambiente.environment.duplicate(true)
	ambiente.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.environment.ambient_light_color = Color(1.0, 0.87, 0.7)
	ambiente.environment.ambient_light_energy = 0.06
	Partida.estres = 0.0
	_ocultar_barra_estres.call_deferred()
	for luz in luces.get_children():
		if luz is OmniLight3D:
			energias[luz] = luz.light_energy
			luz.light_energy = 0.0

func _process(delta: float) -> void:
	if terminado:
		return
	_ocultar_barra_estres()
	avance_maximo = maxf(avance_maximo, personaje.global_position.x)
	var progreso: float = clampf((avance_maximo + 27.0) / 59.0, 0.0, 1.0)
	ambiente.environment.ambient_light_energy = lerpf(0.06, 0.42, smoothstep(0.0, 1.0, progreso))
	for luz in energias:
		var cercania: float = smoothstep(-9.0, 8.0, avance_maximo - luz.global_position.x)
		var objetivo: float = energias[luz] * cercania
		luz.light_energy = move_toward(luz.light_energy, objetivo, delta * 0.8)

func _ocultar_barra_estres() -> void:
	var hud: Node = get_node_or_null("HUD")
	if hud == null:
		hud = get_tree().get_first_node_in_group(Grupos.HUD)
	if hud == null:
		return
	var etiqueta: Control = hud.get_node_or_null("Contenedor/EtiquetaEstres")
	var barra: Control = hud.get_node_or_null("Contenedor/BarraEstres")
	if etiqueta != null:
		etiqueta.hide()
	if barra != null:
		barra.hide()

func _on_torniquete_final_body_entered(cuerpo: Node3D) -> void:
	if terminado or not cuerpo.is_in_group("jugador"):
		return
	if cuerpo.bateria <= 0.0:
		return
	terminado = true
	cuerpo.set_physics_process(false)
	var capa := CanvasLayer.new()
	add_child(capa)
	var fondo := ColorRect.new()
	fondo.color = Color(0.02, 0.03, 0.05, 0.88)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa.add_child(fondo)
	var mensaje := Label.new()
	mensaje.text = "FIN\nDEAD END"
	mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mensaje.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mensaje.add_theme_font_size_override("font_size", 44)
	mensaje.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.add_child(mensaje)
