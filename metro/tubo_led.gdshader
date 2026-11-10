shader_type spatial;

uniform vec4 color : source_color = vec4(0.62, 0.66, 1.0, 1.0);
uniform float energia = 5.0;
uniform float largo = 1.6;
uniform float segmentos = 6.0;
uniform float hueco = 0.12;
uniform float titileo = 0.35;
uniform float semilla = 1.0;

varying float x_local;

float hash(float n) {
	return fract(sin(n * 91.345 + semilla * 17.13) * 47453.5453);
}

void vertex() {
	x_local = VERTEX.x / largo + 0.5;
}

void fragment() {
	float s = x_local * segmentos;
	float id = floor(s);
	float f = fract(s);
	float encendido = step(hueco * 0.5, f) * step(f, 1.0 - hueco * 0.5);
	float falla = step(0.8, hash(id));
	float onda = step(0.5, fract(sin(TIME * (7.0 + hash(id + 3.0) * 9.0) + id) * 0.5 + 0.5));
	float brillo = encendido * (1.0 - falla * titileo * onda);
	ALBEDO = color.rgb * 0.2;
	EMISSION = color.rgb * energia * brillo;
	ROUGHNESS = 0.3;
}
