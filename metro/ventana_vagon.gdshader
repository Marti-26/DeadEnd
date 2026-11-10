shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tinte : source_color = vec4(0.05, 0.06, 0.14, 1.0);
uniform float opacidad = 0.3;
uniform float recorrido = 0.0;
uniform float movimiento = 0.0;
uniform float tren_x = 0.0;
uniform float pixel = 0.04;

varying vec3 mundo;

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

vec3 color_luz(float h) {
	if (h < 0.45) return vec3(1.0, 0.18, 0.12);
	if (h < 0.75) return vec3(1.0, 0.55, 0.2);
	return vec3(0.4, 0.5, 1.0);
}

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float fres = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 3.0);
	vec2 q = floor(vec2(mundo.x - tren_x, mundo.y) / pixel) * pixel;
	vec3 luces = vec3(0.0);
	for (int capa = 0; capa < 2; capa++) {
		float lejos = capa == 0 ? 0.35 : 0.8;
		float u = q.x + recorrido * lejos;
		float celda = floor(u / 1.3);
		float h = hash(celda + float(capa) * 31.0);
		float cx = (celda + 0.2 + 0.6 * hash(celda + 7.0)) * 1.3;
		float cy = 0.9 + 1.1 * hash(celda + 13.0);
		vec2 d = vec2((u - cx) / (1.0 + movimiento * 3.0), q.y - cy);
		float r = 0.12 + 0.1 * hash(celda + 5.0);
		float blob = smoothstep(r, 0.0, length(d)) * step(0.35, h);
		luces += color_luz(hash(celda + 2.0)) * blob * (capa == 0 ? 0.6 : 1.0);
	}
	ALBEDO = tinte.rgb + luces * movimiento;
	EMISSION = luces * movimiento * 2.0 + vec3(0.3, 0.35, 0.8) * fres * 0.25;
	ALPHA = clamp(opacidad + fres * 0.4 + length(luces) * movimiento, 0.0, 0.95);
	ROUGHNESS = 0.05;
}
