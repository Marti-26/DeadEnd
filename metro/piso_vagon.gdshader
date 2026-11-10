shader_type spatial;

uniform vec4 color_base : source_color = vec4(0.07, 0.075, 0.12, 1.0);
uniform vec4 color_estria : source_color = vec4(0.11, 0.115, 0.18, 1.0);
uniform vec4 color_reflejo : source_color = vec4(0.45, 0.5, 1.0, 1.0);
uniform float paso_estria = 0.09;
uniform float pixel = 0.03;
uniform float mugre = 0.35;
uniform float reflejo = 0.6;
uniform float z_reflejo = 0.85;

varying vec3 local;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	local = VERTEX;
}

void fragment() {
	vec2 p = floor(local.xz / pixel) * pixel;
	float estria = step(0.5, fract(local.z / paso_estria));
	vec3 c = mix(color_base.rgb, color_estria.rgb, estria * 0.6);
	float mancha = hash(floor(p * 2.5));
	float punto = step(1.0 - mugre * mancha, hash(p));
	c *= 1.0 - punto * 0.35;
	float d = min(abs(local.z - z_reflejo), abs(local.z + z_reflejo));
	float franja = smoothstep(0.35, 0.0, d);
	float corte = step(0.45, hash(vec2(floor(local.x / 0.25), floor(local.z / 0.1))));
	ALBEDO = c;
	ROUGHNESS = mix(0.85, 0.25, franja);
	METALLIC = 0.1;
	EMISSION = color_reflejo.rgb * franja * corte * reflejo * 0.35;
}
