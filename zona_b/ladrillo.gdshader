shader_type spatial;

uniform vec4 color_ladrillo : source_color = vec4(0.2, 0.27, 0.35, 1.0);
uniform vec4 color_junta : source_color = vec4(0.08, 0.1, 0.14, 1.0);
uniform vec2 tamano = vec2(0.5, 0.22);
uniform float desfase = 0.5;
uniform float junta = 0.07;
uniform float variacion = 0.12;
uniform float pixel = 0.045;
uniform float rugosidad = 0.85;
uniform bool en_piso = false;
uniform float manchas = 0.0;

varying vec3 mundo;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = en_piso ? mundo.xz : mundo.xy;
	vec2 p = floor(uv / pixel) * pixel;
	float fila = floor(p.y / tamano.y);
	vec2 q = vec2(p.x / tamano.x + mod(fila, 2.0) * desfase, p.y / tamano.y);
	vec2 id = floor(q);
	vec2 f = fract(q);
	float j = max(step(f.x, junta), step(f.y, junta * tamano.x / tamano.y));
	vec3 c = color_ladrillo.rgb * (1.0 - variacion + 2.0 * variacion * hash(id));
	float mancha = step(1.0 - manchas, hash(id + 7.3)) * 0.45;
	c = mix(c, color_junta.rgb, mancha);
	ALBEDO = mix(c, color_junta.rgb, j);
	ROUGHNESS = rugosidad;
}
