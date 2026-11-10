shader_type canvas_item;

uniform sampler2D pantalla : hint_screen_texture, filter_nearest;
uniform vec4 color_vineta : source_color = vec4(0.02, 0.02, 0.08, 1.0);
uniform float vineta = 0.55;
uniform float grano = 0.06;
uniform float movimiento = 0.0;
uniform float pixel = 3.0;

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	float franja = floor(uv.y * 90.0);
	uv.x += sin(TIME * 40.0 + franja) * 0.0008 * movimiento;
	vec3 c = texture(pantalla, uv).rgb;
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 cc = (SCREEN_UV - 0.5) * vec2(res.x / res.y, 1.0);
	float v = smoothstep(0.35, 1.0, length(cc)) * vineta;
	ivec2 i = ivec2(mod(floor(FRAGCOORD.xy / pixel), 4.0));
	float b = (BAYER[i.x + i.y * 4] + 0.5) / 16.0 - 0.5;
	float ruido = fract(sin(dot(floor(FRAGCOORD.xy / pixel) + floor(TIME * 12.0), vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
	c += (b * 0.5 + ruido) * grano;
	c = mix(c, color_vineta.rgb, step(b + 0.5, v * 1.3) * 0.85);
	COLOR = vec4(c, 1.0);
}
