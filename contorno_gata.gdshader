shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, blend_mix, shadows_disabled;

uniform sampler2D tex : source_color, filter_linear;
uniform vec4 color : source_color = vec4(1.0, 0.65, 0.25, 1.0);
uniform float energia = 1.8;
uniform float grosor = 3.0;
uniform float intensidad = 0.85;
uniform float pulso = 0.2;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
		MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 paso = grosor / vec2(textureSize(tex, 0));
	float propio = texture(tex, UV).a;
	float vecino = 0.0;
	for (int i = 0; i < 12; i++) {
		float ang = float(i) * 0.5235988;
		vecino = max(vecino, texture(tex, UV + vec2(cos(ang), sin(ang)) * paso).a);
	}
	float borde = clamp(vecino - propio, 0.0, 1.0);
	float latido = 1.0 - pulso + pulso * sin(TIME * 2.2);
	ALBEDO = color.rgb * energia;
	ALPHA = borde * intensidad * latido;
}
