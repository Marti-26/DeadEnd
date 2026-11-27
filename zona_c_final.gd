extends Node3D

@onready var personaje: CharacterBody3D = $Personaje
@onready var luces: Node3D = $Luces
@onready var ambiente: WorldEnvironment = $WorldEnvironment
@onready var estacion: Node3D = $Estacion
@onready var destello: Sprite3D = $EscalerasSalida/Destello
@onready var luz_salida: OmniLight3D = $EscalerasSalida/LuzExteriorLateral

@onready var letrero_exit: Node3D = $Estacion/LetreroExitUnico/CartelExitPixel
@onready var murmullo_anden: AudioStreamPlayer = $MurmulloAnden
@onready var anuncio_metro: AudioStreamPlayer = $AnuncioMetro
@onready var metro: Metro = $MetroLlegada

const INICIO_LUZ: float = -32.0
const FIN_LUZ: float = 34.0
const BALDOSA_OSCURA: Color = Color(0.20, 0.28, 0.29)
const BALDOSA_DORADA: Color = Color(0.69, 0.61, 0.43)
const JUNTA_OSCURA: Color = Color(0.09, 0.13, 0.14)
const JUNTA_DORADA: Color = Color(0.30, 0.27, 0.21)
const PARED_OSCURA: Color = Color(0.22, 0.34, 0.33)
const PARED_DORADA: Color = Color(0.68, 0.60, 0.44)
const PARED_JUNTA_OSCURA: Color = Color(0.08, 0.13, 0.13)
const PARED_JUNTA_DORADA: Color = Color(0.29, 0.27, 0.22)
const VENTANA_DORADA: Color = Color(0.74, 0.65, 0.47)
const LUZ_VENTANA: Color = Color(1.0, 0.92, 0.76)
const PARTELUZ_DORADO: Color = Color(0.55, 0.48, 0.36)
var energias: Dictionary = {}
var baldosas: Array[Dictionary] = []
var paredes: Array[Dictionary] = []
var ventanas: Array[Dictionary] = []
var parteluces: Array[Dictionary] = []
var avance_maximo: float = INICIO_LUZ
var anuncio_reproducido := false
var terminado: bool = false
var _tiempo_luz: float = 0.0

const Z_BORDE_ORIGINAL: float = 5.85
const POSICIONES_X: Dictionary = {
	"Banca3": -27.5,
	"Banca1": -18.5,
	"Expendedora1": -10.0,
	"Banca2": -2.0,
	"Expendedora2": 7.5,
	"CanecaCaida": 8.9,
	"Banca5": 21.0,
	"Carteles/PosterRatini": -6.5,
	"Carteles/PosterFelidae": 16.5,
	"Carteles/PosterSeVende": 25.0,
	"DetallesAnden/Intercomunicador": 2.5,
}
const RANGO_CAMARA: Vector2 = Vector2(-29.6, 38.2)
const X_FINAL_ANDEN: float = -39.05
const TINTE_POSTER: Color = Color(1.0, 0.96, 0.9)
const LUZ_POSTER: Color = Color(1.0, 0.88, 0.7)
const Z_BORDE: float = 5.1
const BORDE_INICIO: float = -39.5
const BORDE_FIN: float = -10.0
const ANCHO_HUECO_PUERTA: float = 1.6

func _ready() -> void:
	ambiente.environment = ambiente.environment.duplicate(true)
	ambiente.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.environment.ambient_light_color = Color(1.0, 0.85, 0.63)
	ambiente.environment.ambient_light_energy = 0.045
	Partida.estres = 0.0
	_ocultar_indicadores_hud.call_deferred()
	_completar_muro()
	_cerrar_extremo_izquierdo()
	_limitar_camara()
	_distribuir_anden()
	_ajustar_posters()
	_retirar_barandas()
	_cerrar_borde_anden()
	_preparar_atmosfera()

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

	for malla in estacion.get_node("ParedTramos").get_children():
		if malla is MeshInstance3D and malla.material_override is ShaderMaterial:
			var material: ShaderMaterial = malla.material_override.duplicate() as ShaderMaterial
			malla.material_override = material
			material.set_shader_parameter("color_ladrillo", PARED_OSCURA)
			material.set_shader_parameter("color_junta", PARED_JUNTA_OSCURA)
			paredes.append({"material": material, "x": malla.global_position.x, "mezcla": 0.0})

	for nodo in estacion.get_children():
		if nodo is MeshInstance3D and nodo.material_override is StandardMaterial3D:
			if str(nodo.name).begins_with("Ventana"):
				var material: StandardMaterial3D = nodo.material_override.duplicate() as StandardMaterial3D
				nodo.material_override = material
				var color_inicial: Color = material.albedo_color
				material.emission_enabled = true
				material.emission = LUZ_VENTANA
				material.emission_energy_multiplier = 0.0
				ventanas.append({"material": material, "x": nodo.global_position.x, "mezcla": 0.0, "inicial": color_inicial})
			elif str(nodo.name).begins_with("Parteluz"):
				var material: StandardMaterial3D = nodo.material_override.duplicate() as StandardMaterial3D
				nodo.material_override = material
				parteluces.append({"material": material, "x": nodo.global_position.x, "mezcla": 0.0, "inicial": material.albedo_color})

func _process(delta: float) -> void:
	if terminado:
		return

	Partida.estres = 0.0
	avance_maximo = maxf(avance_maximo, personaje.global_position.x)
	_actualizar_audio_anden()
	var progreso: float = smoothstep(INICIO_LUZ, FIN_LUZ, avance_maximo)

	ambiente.environment.ambient_light_energy = lerpf(0.045, 0.70, progreso)
	ambiente.environment.ambient_light_color = Color(1.0, 0.85, 0.63).lerp(Color(1.0, 0.96, 0.87), progreso)
	_tiempo_luz += delta
	_actualizar_atmosfera(progreso)

	for luz in energias:
		var cercania: float = smoothstep(-9.0, 7.0, avance_maximo - luz.global_position.x)
		var intensidad: float = lerpf(0.65, 1.3, progreso)
		var respiro: float = 1.0 - 0.035 * (1.0 - progreso) * (0.5 + 0.5 * sin(_tiempo_luz * 1.3 + luz.global_position.x))
		var objetivo: float = energias[luz] * cercania * intensidad * respiro
		luz.light_energy = move_toward(luz.light_energy, objetivo, delta * 2.5)

	for baldosa in baldosas:
		var tramo: float = smoothstep(-16.0, FIN_LUZ, baldosa["x"])
		var cercania: float = smoothstep(-10.0, 6.0, avance_maximo - baldosa["x"])
		var objetivo: float = tramo * cercania
		baldosa["mezcla"] = move_toward(baldosa["mezcla"], objetivo, delta * 0.65)
		var material: ShaderMaterial = baldosa["material"]
		material.set_shader_parameter("color_ladrillo", BALDOSA_OSCURA.lerp(BALDOSA_DORADA, baldosa["mezcla"]))
		material.set_shader_parameter("color_junta", JUNTA_OSCURA.lerp(JUNTA_DORADA, baldosa["mezcla"]))

	for pared in paredes:
		var tramo: float = smoothstep(-16.0, FIN_LUZ, pared["x"])
		var cercania: float = smoothstep(-10.0, 6.0, avance_maximo - pared["x"])
		var objetivo: float = tramo * cercania
		pared["mezcla"] = move_toward(pared["mezcla"], objetivo, delta * 0.65)
		var material: ShaderMaterial = pared["material"]
		material.set_shader_parameter("color_ladrillo", PARED_OSCURA.lerp(PARED_DORADA, pared["mezcla"]))
		material.set_shader_parameter("color_junta", PARED_JUNTA_OSCURA.lerp(PARED_JUNTA_DORADA, pared["mezcla"]))

	for ventana in ventanas:
		var tramo: float = smoothstep(-16.0, FIN_LUZ, ventana["x"])
		var cercania: float = smoothstep(-10.0, 6.0, avance_maximo - ventana["x"])
		var objetivo: float = tramo * cercania
		ventana["mezcla"] = move_toward(ventana["mezcla"], objetivo, delta * 0.65)
		var material: StandardMaterial3D = ventana["material"]
		material.albedo_color = ventana["inicial"].lerp(VENTANA_DORADA, ventana["mezcla"])
		material.emission_energy_multiplier = 0.20 * ventana["mezcla"]

	for parteluz in parteluces:
		var tramo: float = smoothstep(-16.0, FIN_LUZ, parteluz["x"])
		var cercania: float = smoothstep(-10.0, 6.0, avance_maximo - parteluz["x"])
		var objetivo: float = tramo * cercania
		parteluz["mezcla"] = move_toward(parteluz["mezcla"], objetivo, delta * 0.65)
		var material: StandardMaterial3D = parteluz["material"]
		material.albedo_color = parteluz["inicial"].lerp(PARTELUZ_DORADO, parteluz["mezcla"])

func _actualizar_audio_anden() -> void:
	var distancia := personaje.global_position.x - letrero_exit.global_position.x
	if distancia <= 0.0:
		murmullo_anden.stop()
		return

	var mezcla := smoothstep(0.0, 10.0, distancia)
	murmullo_anden.volume_db = lerpf(-2.0, 8.0, mezcla)
	if not murmullo_anden.playing:
		murmullo_anden.play(1.0)

	if distancia >= 7.0 and not anuncio_reproducido:
		anuncio_reproducido = true
		anuncio_metro.play()
		if metro.estado == Metro.Estado.FUERA:
			metro.proxima = metro.reloj

func _ocultar_indicadores_hud() -> void:
	var hud := get_tree().get_first_node_in_group(Grupos.GRUPO_HUD)
	if hud == null:
		return
	for ruta: NodePath in [
		^"Contenedor/EtiquetaBateria",
		^"Contenedor/BarraBateria",
		^"Contenedor/EtiquetaEstres",
		^"Contenedor/BarraEstres",
	]:
		var indicador := hud.get_node_or_null(ruta) as Control
		if indicador != null:
			indicador.hide()

func _on_salida_superficie_body_entered(cuerpo: Node3D) -> void:
	if terminado or not cuerpo.is_in_group("jugador"):
		return
	if cuerpo.bateria <= 0.0:
		return
	terminado = true
	cuerpo.set_physics_process(false)
	cuerpo.set_process(false)
	var capa := CanvasLayer.new()
	capa.layer = 20
	add_child(capa)
	var fondo := ColorRect.new()
	fondo.color = Color(1.0, 0.91, 0.74, 0.0)
	capa.add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mensaje := Label.new()
	mensaje.text = "FIN\nDEAD END"
	mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mensaje.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mensaje.add_theme_font_size_override("font_size", 44)
	mensaje.modulate.a = 0.0
	fondo.add_child(mensaje)
	mensaje.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cierre := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	cierre.tween_property(destello, "modulate:a", 1.0, 0.55)
	cierre.parallel().tween_property(luz_salida, "light_energy", 3.5, 0.55)
	cierre.parallel().tween_property(fondo, "color:a", 0.78, 0.55)
	cierre.tween_interval(0.16)
	cierre.tween_property(fondo, "color", Color(0.02, 0.03, 0.05), 0.75)
	cierre.parallel().tween_property(mensaje, "modulate:a", 1.0, 0.75)


func _cerrar_borde_anden() -> void:
	var puertas: Array[float] = []
	if metro != null:
		for px: float in metro.puertas_x:
			puertas.append(metro.global_position.x + metro.x_parada + px)
	puertas.sort()
	var tramos: Array[Vector2] = []
	var desde: float = BORDE_INICIO
	for px: float in puertas:
		if px - ANCHO_HUECO_PUERTA * 0.5 > desde and px < BORDE_FIN:
			tramos.append(Vector2(desde, px - ANCHO_HUECO_PUERTA * 0.5))
			desde = px + ANCHO_HUECO_PUERTA * 0.5
	if desde < BORDE_FIN:
		tramos.append(Vector2(desde, BORDE_FIN))
	var barra: MeshInstance3D = estacion.get_node_or_null("Barrera3") as MeshInstance3D
	var barra_arriba: MeshInstance3D = estacion.get_node_or_null("BarreraArriba3") as MeshInstance3D
	var postes: MultiMeshInstance3D = estacion.get_node_or_null("PostesBarrera") as MultiMeshInstance3D
	var raiz: Node3D = Node3D.new()
	raiz.name = "BordeAndenSeguro"
	estacion.add_child(raiz)
	var choque: StaticBody3D = StaticBody3D.new()
	choque.name = "Choque"
	raiz.add_child(choque)
	for tramo: Vector2 in tramos:
		var largo: float = tramo.y - tramo.x
		var centro: float = (tramo.x + tramo.y) * 0.5
		var forma: CollisionShape3D = CollisionShape3D.new()
		var caja: BoxShape3D = BoxShape3D.new()
		caja.size = Vector3(largo, 2.0, 0.3)
		forma.shape = caja
		choque.add_child(forma)
		forma.global_position = Vector3(centro, 1.0, Z_BORDE)
		if barra != null:
			_barra_borde(raiz, Vector3(largo, 0.32, 0.05), Vector3(centro, 0.62, Z_BORDE), barra.material_override)
		if barra_arriba != null:
			_barra_borde(raiz, Vector3(largo, 0.05, 0.07), Vector3(centro, 0.8, Z_BORDE), barra_arriba.material_override)
		if postes != null and postes.multimesh != null and postes.multimesh.mesh != null:
			var x: float = tramo.x
			while x <= tramo.y + 0.01:
				var poste: MeshInstance3D = MeshInstance3D.new()
				poste.mesh = postes.multimesh.mesh
				raiz.add_child(poste)
				poste.global_position = Vector3(x, 0.42, Z_BORDE)
				x += minf(2.5, maxf(largo, 0.1))


func _barra_borde(padre: Node3D, tam: Vector3, pos: Vector3, material: Material) -> void:
	var malla: MeshInstance3D = MeshInstance3D.new()
	var caja: BoxMesh = BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.material_override = material
	padre.add_child(malla)
	malla.global_position = pos


func _preparar_atmosfera() -> void:
	var entorno: Environment = ambiente.environment
	entorno.glow_enabled = true
	entorno.glow_intensity = 0.25
	entorno.glow_bloom = 0.0
	entorno.glow_hdr_threshold = 1.2
	entorno.fog_enabled = false


func _actualizar_atmosfera(progreso: float) -> void:
	var entorno: Environment = ambiente.environment
	entorno.tonemap_exposure = lerpf(1.05, 1.15, progreso)
	entorno.glow_intensity = lerpf(0.2, 0.35, progreso)
	if luz_salida != null and not terminado:
		luz_salida.light_energy = maxf(luz_salida.light_energy, lerpf(0.0, 0.6, smoothstep(0.55, 1.0, progreso)))


func _retirar_barandas() -> void:
	var desplazo: float = Z_BORDE - Z_BORDE_ORIGINAL
	for nodo: Node in estacion.get_children():
		var nombre: String = str(nodo.name)
		var es_baranda: bool = nombre.begins_with("Barrera") or nombre in ["PostesBarrera", "MuroBarrera", "BarandasExtremos", "BarandaPasilloDespuesMetro"]
		if es_baranda and nodo is Node3D:
			(nodo as Node3D).position.z += desplazo


func _completar_muro() -> void:
	var muro: StaticBody3D = StaticBody3D.new()
	muro.name = "MuroFondoCompleto"
	var forma: CollisionShape3D = CollisionShape3D.new()
	var caja: BoxShape3D = BoxShape3D.new()
	caja.size = Vector3(76.0, 5.0, 0.6)
	forma.shape = caja
	muro.add_child(forma)
	estacion.add_child(muro)
	muro.global_position = Vector3(-3.0, 2.5, -3.7)


func _distribuir_anden() -> void:
	for ruta: String in POSICIONES_X:
		var nodo: Node3D = estacion.get_node_or_null(ruta) as Node3D
		if nodo != null:
			nodo.position.x = float(POSICIONES_X[ruta])


func _ajustar_posters() -> void:
	var carteles: Node = estacion.get_node_or_null("Carteles")
	if carteles == null:
		return
	for poster: Node in carteles.get_children():
		if poster.get("tinte") == null:
			continue
		poster.set("tinte", TINTE_POSTER)
		poster.set("saturacion", 0.95)
		poster.set("color_luz", LUZ_POSTER)
		poster.set("luz", maxf(float(poster.get("luz")), 0.5))


func _limitar_camara() -> void:
	var camara: Camera3D = get_node_or_null("Camara") as Camera3D
	if camara == null or camara.get("rango_x") == null:
		return
	camara.set("rango_x", RANGO_CAMARA)
	if camara.has_method("saltar"):
		camara.call("saltar")


func _cerrar_extremo_izquierdo() -> void:
	var raiz: Node3D = Node3D.new()
	raiz.name = "ExtremoIzquierdo"
	estacion.add_child(raiz)
	var muro_mat: Material = null
	var tramo: MeshInstance3D = estacion.get_node_or_null("ParedTramos/Tramo00") as MeshInstance3D
	if tramo != null and tramo.material_override is ShaderMaterial:
		var mat: ShaderMaterial = (tramo.material_override as ShaderMaterial).duplicate() as ShaderMaterial
		mat.set_shader_parameter("color_ladrillo", PARED_OSCURA.darkened(0.25))
		mat.set_shader_parameter("color_junta", PARED_JUNTA_OSCURA)
		muro_mat = mat
	else:
		var simple: StandardMaterial3D = StandardMaterial3D.new()
		simple.albedo_color = PARED_OSCURA.darkened(0.25)
		muro_mat = simple
	var concreto: StandardMaterial3D = StandardMaterial3D.new()
	concreto.albedo_color = Color(0.07, 0.09, 0.1)
	concreto.roughness = 0.95
	var vacio: StandardMaterial3D = StandardMaterial3D.new()
	vacio.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vacio.albedo_color = Color(0.008, 0.01, 0.014)
	var x: float = X_FINAL_ANDEN
	_caja_extremo(raiz, Vector3(7.0, 6.0, 10.4), Vector3(x - 3.5, 1.8, 0.95), muro_mat)
	_caja_extremo(raiz, Vector3(7.2, 0.4, 18.8), Vector3(x - 3.5, 4.95, 5.05), concreto)
	_caja_extremo(raiz, Vector3(0.6, 1.6, 8.3), Vector3(x - 0.3, 3.95, 10.3), concreto)
	_caja_extremo(raiz, Vector3(0.6, 6.5, 0.6), Vector3(x - 0.3, 1.6, 14.45), concreto)
	_caja_extremo(raiz, Vector3(6.0, 6.5, 8.4), Vector3(x - 3.6, 0.8, 10.3), vacio)
	var luz: OmniLight3D = OmniLight3D.new()
	luz.light_color = Color(0.55, 0.65, 0.75)
	luz.light_energy = 0.35
	luz.omni_range = 5.0
	luz.shadow_enabled = false
	raiz.add_child(luz)
	luz.global_position = Vector3(X_FINAL_ANDEN + 1.2, 3.4, -1.5)


func _caja_extremo(padre: Node3D, tam: Vector3, pos: Vector3, material: Material) -> void:
	var malla: MeshInstance3D = MeshInstance3D.new()
	var caja: BoxMesh = BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.material_override = material
	padre.add_child(malla)
	malla.global_position = pos
