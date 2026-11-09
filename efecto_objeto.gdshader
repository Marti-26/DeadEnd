shader_type spatial;

uniform vec3 color_base : source_color = vec3(0.204, 0.314, 0.431);   // #34506E
uniform vec3 color_flash : source_color = vec3(0.953, 0.890, 0.765);  // #F3E3C3
uniform float flash : hint_range(0.0, 1.0) = 0.0;

uniform sampler2D ruido;
uniform float avance : hint_range(0.0, 1.0) = 0.0;
uniform float ancho_borde = 0.06;
uniform vec3 color_borde : source_color = vec3(0.561, 0.851, 0.690); // #8FD9B0

void fragment() {
	ALBEDO = mix(color_base, color_flash, flash);
	EMISSION = color_flash * flash;
	float r = texture(ruido, UV).r;
	if (r < avance) {
		discard;
	}
	if (avance > 0.0 && r < avance + ancho_borde) {
		EMISSION = color_borde * 2.0;
	}
}
