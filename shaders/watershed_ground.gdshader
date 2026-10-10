shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D trail_mask : filter_linear, repeat_disable;
uniform vec2 trail_origin;
uniform vec2 trail_size;
varying vec3 ground_position;
varying vec3 ground_color;
float hash_point(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float soft_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 blend = fract(p);
	blend = blend*blend*(3.0-2.0*blend);
	return mix(mix(hash_point(cell),hash_point(cell+vec2(1.0,0.0)),blend.x),mix(hash_point(cell+vec2(0.0,1.0)),hash_point(cell+vec2(1.0,1.0)),blend.x),blend.y);
}
void vertex() { ground_color = COLOR.rgb; ground_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float grain = soft_noise(ground_position.xz*8.0);
	float patch = soft_noise(ground_position.xz*0.65);
	vec2 trail_uv = (ground_position.xz - trail_origin) / trail_size;
	float trail = texture(trail_mask, trail_uv).r;
	vec3 soil = ground_color * (0.94+grain*0.045+patch*0.075);
	float shore = (1.0-smoothstep(1.4,5.0,abs(ground_position.x-25.5)+(patch-0.5)*0.9))
		* (1.0-smoothstep(10.0,14.0,ground_position.z));
	soil = mix(soil,vec3(0.39,0.39,0.35)*(0.95+grain*0.08),shore*0.7);
	vec3 worn_path = vec3(0.57,0.54,0.46) * (0.94+grain*0.04+patch*0.06);
	ALBEDO = mix(soil, worn_path, trail*0.92);
	ROUGHNESS = 0.98;
}
