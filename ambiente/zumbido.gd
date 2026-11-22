extends AudioStreamPlayer3D

@export var frecuencia: float = 100.0
@export var volumen: float = -24.0

var _generador: AudioStreamGeneratorPlayback = null
var _fase: float = 0.0
var _tasa: float = 22050.0
var _luz: Light3D = null
var _energia_max: float = 1.0
var _ruido: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	var flujo: AudioStreamGenerator = AudioStreamGenerator.new()
	flujo.mix_rate = _tasa
	flujo.buffer_length = 0.15
	stream = flujo
	volume_db = volumen
	unit_size = 2.5
	max_distance = 9.0
	attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	if AudioServer.get_bus_index("Juego") >= 0:
		bus = &"Juego"
	_luz = get_parent() as Light3D
	if _luz != null:
		_energia_max = maxf(_luz.light_energy, 0.01)
	_ruido.randomize()
	play()
	_generador = get_stream_playback() as AudioStreamGeneratorPlayback


func _process(_delta: float) -> void:
	if _generador == null:
		return
	var nivel: float = 1.0
	if _luz != null:
		_energia_max = maxf(_energia_max, _luz.light_energy)
		nivel = clampf(_luz.light_energy / _energia_max, 0.0, 1.0)
	var chasquido: bool = nivel < 0.45
	var cantidad: int = _generador.get_frames_available()
	var paso: float = frecuencia / _tasa
	for i: int in cantidad:
		_fase = fmod(_fase + paso, 1.0)
		var s: float = sin(_fase * TAU) * 0.5 + sin(_fase * TAU * 2.0) * 0.3 + sin(_fase * TAU * 3.0) * 0.15
		s *= 0.25 + 0.75 * nivel
		if chasquido and _ruido.randf() < 0.02:
			s += _ruido.randf_range(-0.8, 0.8)
		s *= 0.35
		_generador.push_frame(Vector2(s, s))
