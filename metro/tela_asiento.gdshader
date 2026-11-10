shader_type spatial;

uniform vec4 color_fondo : source_color = vec4(0.06, 0.07, 0.12, 1.0);
uniform vec4 color_dibujo : source_color = vec4(0.16, 0.2, 0.42, 1.0);
uniform vec4 color_hilo : source_color = vec4(0.75, 0.25, 0.2, 1.0);
uniform float escala = 0.07;
uniform float pixel = 0.012;

varying vec3 local;
varying vec3 normal_local;

void vertex() {
	local = VERTEX;
	normal_local = abs(NORMAL);
}

void fragment() {
	vec2 uv = normal_local.y > 0.5 ? local.xz : (normal_local.x > 0.5 ? local.zy : local.xy);
	uv = floor(uv / pixel) * pixel / escala;
	vec2 g = abs(fract(uv) - 0.5);
	float rombo = step(g.x + g.y, 0.32);
	float hilo = step(0.94, fract(uv.x * 0.5 + uv.y * 0.5));
	vec3 c = mix(color_fondo.rgb, color_dibujo.rgb, rombo);
	c = mix(c, color_hilo.rgb, hilo * 0.6);
	ALBEDO = c;
	ROUGHNESS = 0.95;
}
