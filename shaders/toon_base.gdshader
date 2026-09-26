shader_type spatial;
render_mode diffuse_toon, specular_disabled, cull_disabled;

uniform vec4 base_color : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform sampler2D ramp_texture : filter_nearest;

void fragment() {
	ALBEDO = base_color.rgb;
}

void light() {
	float ndotl = clamp(dot(NORMAL, LIGHT) * 0.5 + 0.5, 0.0, 1.0);
	float banded = texture(ramp_texture, vec2(ndotl, 0.5)).r;
	DIFFUSE_LIGHT += ALBEDO * banded * LIGHT_COLOR * ATTENUATION;
}
