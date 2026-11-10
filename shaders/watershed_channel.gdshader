shader_type spatial;
render_mode diffuse_burley;
uniform float fill : hint_range(0.0,1.0) = 1.0;
varying vec2 channel_uv;
void vertex() { channel_uv = UV; }
void fragment() {
	if (channel_uv.y > fill) { discard; }
	float ripple = sin(channel_uv.y * 110.0 - TIME * 2.2) * 0.5 + 0.5;
	ALBEDO = mix(vec3(0.15,0.43,0.43),vec3(0.32,0.68,0.59),ripple);
	EMISSION = vec3(0.02,0.08,0.07);
	ROUGHNESS = 0.32;
	METALLIC = 0.12;
}
