// Niebla baja que se arrastra (ruido de valor animado + trama).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 color : source_color = vec4(0.25, 0.6, 0.5, 1.0);
uniform float fuerza = 0.35;
uniform float escala = 0.35;
uniform vec2 viento = vec2(0.12, 0.02);

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x),
		mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int k = 0; k < 4; k++) { v += a * ruido(p); p *= 2.03; a *= 0.5; }
	return v;
}

varying vec3 mundo;
void vertex() { mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }

void fragment() {
	vec2 p = mundo.xy * escala + TIME * viento;
	float n = fbm(p);
	float vertical = smoothstep(0.0, 0.55, 1.0 - UV.y) * smoothstep(1.0, 0.6, 1.0 - UV.y);
	float v = smoothstep(0.35, 0.85, n) * vertical * fuerza;
	ivec2 i = ivec2(mod(floor(FRAGCOORD.xy / 4.0), 4.0));
	float umbral = (BAYER[i.x + i.y * 4] + 0.5) / 16.0;
	float tramado = step(umbral, v * 1.8);
	ALBEDO = color.rgb * mix(v, tramado * 0.3, 0.45);
}
