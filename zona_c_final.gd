extends Node3D

@onready var personaje: CharacterBody3D = $Personaje
@onready var luces: Node3D = $Luces
@onready var ambiente: WorldEnvironment = $WorldEnvironment
@onready var estacion: Node3D = $Estacion

const INICIO_LUZ: float = -32.0
const FIN_LUZ: float = 34.0
const BALDOSA_OSCURA: Color = Color(0.20, 0.28, 0.29)
const BALDOSA_DORADA: Color = Color(0.90, 0.69, 0.30)
const JUNTA_OSCURA: Color = Color(0.09, 0.13, 0.14)
const JUNTA_DORADA: Color = Color(0.38, 0.29, 0.15)

var energias: Dictionary = {}
var baldosas: Array[Dictionary] = []
var avance_maximo: float = INICIO_LUZ
var terminado: bool = false

func _ready() -> void:
	ambiente.environment = ambiente.environment.duplicate(true)
	ambiente.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.environment.ambient_light_color = Color(1.0, 0.85, 0.63)
	ambiente.environment.ambient_light_energy = 0.045
	Partida.estres = 0.0
	_ocultar_barra_estres.call_deferred()

	for luz in luces.get_children():
		if luz is OmniLight3D:
			energias[luz] = luz.light_energy
			luz.light_energy = 0.0

	for nodo in estacion.get_children():
		if str(nodo.name).begins_with("Piso"):
			var malla: MeshInstance3D = nodo.get_node_or_null("Malla")
			if malla != null and malla.material_override is ShaderMaterial:
				var material: ShaderMaterial = malla.material_override.duplicate() as ShaderMaterial
				malla.material_override = material
				material.set_shader_parameter("color_ladrillo", BALDOSA_OSCURA)
				material.set_shader_parameter("color_junta", JUNTA_OSCURA)
				baldosas.append({"material": material, "x": malla.global_position.x, "mezcla": 0.0})

func _process(delta: float) -> void:
	if terminado:
		return

	Partida.estres = 0.0
	_ocultar_barra_estres()
	avance_maximo = maxf(avance_maximo, personaje.global_position.x)
	var progreso: float = smoothstep(INICIO_LUZ, FIN_LUZ, avance_maximo)

	ambiente.environment.ambient_light_energy = lerpf(0.045, 0.95, progreso)
	ambiente.environment.ambient_light_color = Color(1.0, 0.85, 0.63).lerp(Color(1.0, 0.91, 0.73), progreso)

	for luz in energias:
		var cercania: float = smoothstep(-9.0, 7.0, avance_maximo - luz.global_position.x)
		var intensidad: float = lerpf(0.65, 1.9, progreso)
		var objetivo: float = energias[luz] * cercania * intensidad
		luz.light_energy = move_toward(luz.light_energy, objetivo, delta * 2.5)

	for baldosa in baldosas:
		var tramo: float = smoothstep(-16.0, FIN_LUZ, baldosa["x"])
		var cercania: float = smoothstep(-10.0, 6.0, avance_maximo - baldosa["x"])
		var objetivo: float = tramo * cercania
		baldosa["mezcla"] = move_toward(baldosa["mezcla"], objetivo, delta * 0.65)
		var material: ShaderMaterial = baldosa["material"]
		material.set_shader_parameter("color_ladrillo", BALDOSA_OSCURA.lerp(BALDOSA_DORADA, baldosa["mezcla"]))
		material.set_shader_parameter("color_junta", JUNTA_OSCURA.lerp(JUNTA_DORADA, baldosa["mezcla"]))

func _ocultar_barra_estres() -> void:
	var hud: Node = get_node_or_null("HUD")
	if hud == null:
		hud = get_tree().get_first_node_in_group("hud")
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
