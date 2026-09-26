shader_type spatial;
render_mode diffuse_toon, specular_disabled, cull_disabled;

uniform vec4 base_color : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform sampler2D ramp_texture : filter_nearest;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;

void fragment() {
	ALBEDO = base_color.rgb;
	EMISSION = emission_color.rgb * emission_energy;
}

void light() {
	float ndotl = clamp(dot(NORMAL, LIGHT) * 0.5 + 0.5, 0.0, 1.0);
	float banded = texture(ramp_texture, vec2(ndotl, 0.5)).r;
	DIFFUSE_LIGHT += ALBEDO * banded * LIGHT_COLOR * ATTENUATION;
}
