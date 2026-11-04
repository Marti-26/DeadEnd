// Anillo en el piso que muestra el radio de audición de la criatura (tramado).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 color : source_color = vec4(0.56, 0.85, 0.69, 1.0);
uniform float radio = 6.0;          // m
uniform float tamano = 14.0;        // lado del plano en m
uniform float fuerza = 0.35;
uniform float medio_fondo = 1.9;    // ancho del andén / 2: no se sale del piso

varying vec3 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 c = (UV - 0.5) * tamano;
	float d = length(c);
	float anillo = 1.0 - smoothstep(0.0, 0.07, abs(d - radio));
	float dentro = (1.0 - smoothstep(0.0, radio, d)) * 0.10;
	float pulso = 0.75 + 0.25 * sin(TIME * 3.0 - d * 1.5);
	float corte = 1.0 - step(medio_fondo, abs(mundo.z));
	// trama de cuadros para que se lea como pixel art
	vec2 celda = floor(FRAGCOORD.xy / 3.0);
	float tablero = mod(celda.x + celda.y, 2.0);
	ALBEDO = color.rgb * (anillo * tablero + dentro) * fuerza * pulso * corte;
}
