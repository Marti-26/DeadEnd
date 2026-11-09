extends Node
## Tarea B · Restrepo Sanabria María Camila — el emisor del ruido.
## Va como hijo del Personaje (no se toca personaje.gd).
## Quien hace el ruido avisa UNA vez a los del grupo "oyentes" que están cerca.
##  · Tecla hacer_ruido (R): ruido de prueba con el Radio del Inspector.
##  · En el juego, además, suenan solos: los pasos (3 u), el dash (8 u) y el
##    jadeo al llegar a 100 de estrés (10 u). El sigilo no suena: ruido 0.

@export var tecla = "hacer_ruido"
@export var radio = 6.0
@export var grupo = "oyentes"

@export_group("Ruido del juego")
@export var ruido_del_personaje = true   # pasos y dash según el estado del Personaje
@export var cada_paso = 0.5              # s entre un ruido de pasos y el siguiente
@export var radio_jadeo = 10.0           # u, el jadeo alerta a todo en 10 u

@onready var pj = get_parent()
@onready var dash = pj.get_node_or_null("Dash")

var _ruido_antes = 0.0
var _reloj_paso = 0.0
var _jadeo_antes = false


func _physics_process(delta):
	if Input.is_action_just_pressed(tecla):
		sonar()
	if ruido_del_personaje:
		_ruido_del_juego(delta)


## r: hasta dónde llega el ruido (sin r, usa el Radio del Inspector).
## siempre: escribir aunque nadie lo oiga.
## respeta_oido: cada criatura oye como máximo su radio_audicion.
func sonar(r = -1.0, siempre = true, respeta_oido = true):
	if r < 0.0:
		r = radio
	var cuantos = 0
	for n in get_tree().get_nodes_in_group(grupo):
		var alcance = r
		if respeta_oido and "radio_audicion" in n:
			alcance = minf(r, n.radio_audicion)
		if pj.global_position.distance_to(n.global_position) <= alcance:
			n.oir(pj.global_position)
			cuantos += 1
	if siempre or cuantos > 0:
		print("ruido de ", r, " m: lo oyen ", cuantos)
	return cuantos


# Lee el ruido que ya calcula personaje.gd (RUIDO[estado]) sin editarlo.
func _ruido_del_juego(delta):
	if not "ruido" in pj:
		return
	var r = pj.ruido
	_reloj_paso = maxf(_reloj_paso - delta, 0.0)
	if r > _ruido_antes:
		# Empezó algo más fuerte (por ejemplo el dash): suena ya.
		sonar(r, false)
		_reloj_paso = cada_paso
	elif r > 0.0 and _reloj_paso <= 0.001:
		# Pasos: un ruido cada medio segundo mientras camina.
		sonar(r, false)
		_reloj_paso = cada_paso
	_ruido_antes = r
	# El jadeo: lo dispara dash.gd al llegar a 100 de estrés.
	if dash != null and "recuperando" in dash:
		if dash.recuperando and not _jadeo_antes:
			sonar(radio_jadeo, true, false)
		_jadeo_antes = dash.recuperando
