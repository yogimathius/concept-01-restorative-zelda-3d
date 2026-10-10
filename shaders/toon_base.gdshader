shader_type spatial;
render_mode diffuse_toon, specular_disabled, cull_disabled;

uniform vec4 base_color : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform sampler2D ramp_texture : filter_nearest;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;
uniform float terrain_variation = 0.0;
uniform float mend_amount = 0.0;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float patch = sin(world_position.x * 0.83 + sin(world_position.z * 0.72))
		* sin(world_position.z * 0.57 - world_position.x * 0.31);
	ALBEDO = base_color.rgb * (1.0 + patch * terrain_variation);
	// Colored fill keeps silhouettes readable under the single key light.
	EMISSION = emission_color.rgb * emission_energy + base_color.rgb * 0.13;
	float rising = (1.0 - smoothstep(mend_amount * 1.5, mend_amount * 1.5 + 0.12, world_position.y)) * step(0.001, mend_amount);
	ALBEDO = mix(ALBEDO, vec3(0.32, 0.76, 0.58), rising * 0.4);
	EMISSION += vec3(0.12, 0.38, 0.25) * rising;
}

void light() {
	float ndotl = clamp(dot(NORMAL, LIGHT) * 0.5 + 0.5, 0.0, 1.0);
	float banded = texture(ramp_texture, vec2(ndotl, 0.5)).r;
	DIFFUSE_LIGHT += ALBEDO * max(banded, 0.22) * LIGHT_COLOR * ATTENUATION / PI;
}
