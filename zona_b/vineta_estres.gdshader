// Concepto E2 · Viñeta roja de estrés: un borde de puntos que entra desde las
// orillas. La intensidad (0–1) la pone SistemaEventos con la variable estrés.
shader_type canvas_item;

uniform float intensidad : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(0.784, 0.243, 0.243, 1.0);
uniform float pixel = 4.0;

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 c = (SCREEN_UV - 0.5) * vec2(res.x / res.y, 1.0);
	float d = length(c);
	float latido = 1.0 + 0.06 * sin(TIME * (4.0 + intensidad * 6.0)) * intensidad;
	float radio = mix(1.05, 0.28, intensidad) * latido;
	float v = smoothstep(radio, radio + 0.35, d);
	ivec2 i = ivec2(mod(floor(FRAGCOORD.xy / pixel), 4.0));
	float umbral = (BAYER[i.x + i.y * 4] + 0.5) / 16.0;
	float punto = step(umbral, v);
	float tinte = pow(intensidad, 3.0) * 0.28;
	COLOR = vec4(color.rgb, max(punto * 0.85, tinte) * step(0.01, intensidad));
}
