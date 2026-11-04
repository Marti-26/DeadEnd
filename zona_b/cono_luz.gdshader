shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 color : source_color = vec4(0.56, 0.85, 0.69, 1.0);
uniform float intensidad = 0.3;
uniform float altura = 3.0;
uniform float pixel = 3.0;
uniform float trama = 0.65;

varying float h;

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

float bayer(vec2 p) {
	ivec2 i = ivec2(mod(floor(p / pixel), 4.0));
	return (BAYER[i.x + i.y * 4] + 0.5) / 16.0;
}

void vertex() {
	h = clamp(VERTEX.y / altura + 0.5, 0.0, 1.0);
}

void fragment() {
	float borde = pow(abs(dot(normalize(NORMAL), normalize(VIEW))), 1.6);
	float v = borde * pow(h, 1.3) * intensidad;
	float punto = step(bayer(FRAGCOORD.xy), v * 1.4) * 0.4;
	ALBEDO = color.rgb * mix(v, punto, trama);
}
