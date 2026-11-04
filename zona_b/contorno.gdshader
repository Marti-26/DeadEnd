// Borde de la silueta (casco invertido): el "borde rojo" de las criaturas.
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;

uniform vec4 color : source_color = vec4(0.32, 0.08, 0.1, 1.0);
uniform float grosor = 0.035;

void vertex() {
	VERTEX += NORMAL * grosor;
}

void fragment() {
	ALBEDO = color.rgb;
}
