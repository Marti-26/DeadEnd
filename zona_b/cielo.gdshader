// Fondo: degradado del cielo con nubes lentas y estrellas (va en un plano lejano).
shader_type spatial;
render_mode unshaded, shadows_disabled, fog_disabled;

uniform vec4 arriba : source_color = vec4(0.04, 0.06, 0.11, 1.0);
uniform vec4 horizonte : source_color = vec4(0.12, 0.2, 0.3, 1.0);
uniform vec4 nubes : source_color = vec4(0.16, 0.24, 0.34, 1.0);
uniform float cantidad_nubes = 0.6;
uniform float estrellas = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x),
		mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int k = 0; k < 5; k++) { v += a * ruido(p); p *= 2.0; a *= 0.5; }
	return v;
}

void fragment() {
	float y = UV.y;                         // 0 arriba, 1 abajo
	vec3 c = mix(arriba.rgb, horizonte.rgb, smoothstep(0.0, 1.0, y));
	vec2 p = vec2(UV.x * 6.0 + TIME * 0.01, y * 3.0);
	float n = smoothstep(0.45, 0.8, fbm(p)) * cantidad_nubes * (1.0 - y * 0.4);
	c = mix(c, nubes.rgb, n);
	vec2 celda = floor(UV * vec2(420.0, 240.0));
	float e = step(0.9965, hash(celda)) * estrellas * (1.0 - y) * (1.0 - n);
	e *= 0.6 + 0.4 * sin(TIME * 2.0 + hash(celda) * 40.0);
	ALBEDO = c + vec3(e);
}
