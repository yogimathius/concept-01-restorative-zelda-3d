shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float restored = 0.0;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float wave = sin(world_position.x * 1.2 + world_position.z * 0.55 + TIME * 0.32)
		* sin(world_position.z * 1.8 - TIME * 0.25);
	vec3 ink = vec3(0.055, 0.11, 0.15);
	vec3 teal = vec3(0.08, 0.23, 0.26);
	vec3 water = mix(ink, teal, restored * 0.5 + 0.25);
	float ribbon = smoothstep(0.91, 0.98, wave);
	ALBEDO = water + vec3(0.055, 0.095, 0.10) * ribbon;
}
