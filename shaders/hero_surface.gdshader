shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;
uniform vec4 base_color : source_color = vec4(0.6,0.6,0.6,1.0);
uniform vec4 emission_color : source_color = vec4(0.0,0.0,0.0,1.0);
uniform float emission_energy = 0.0;
uniform float surface_metallic = 0.0;
uniform float surface_roughness = 0.7;
uniform float fabric_strength = 0.0;
uniform float mend_amount = 0.0;
uniform float cloth_pattern = 0.0;
uniform float cloth_width = 0.35;
uniform float cloth_hem = 0.20;
uniform float cloth_top = 1.2165;
uniform vec4 embroidery_color : source_color = vec4(0.7,0.55,0.3,1.0);
varying vec3 model_point;
void vertex() {
	model_point = VERTEX;
	// A restrained hem ripple adds life to tailored cloth, without CPU simulation.
	float hem = 1.0-smoothstep(0.25,0.95,VERTEX.y);
	VERTEX.z += sin(TIME*1.5+VERTEX.x*9.0+VERTEX.y*5.0)*0.005*hem*fabric_strength;
}
void fragment() {
	// Vertex colours carry offline crevice shading on the heroes.
	float footprint=length(fwidth(model_point));
	float weave = sin(model_point.x*680.0)*sin(model_point.y*680.0);
	float weave_visibility=1.0-smoothstep(0.001,0.004,footprint);
	ALBEDO = base_color.rgb*COLOR.rgb*(1.0+weave*0.022*fabric_strength*weave_visibility);
	ALBEDO *= mix(1.0,0.88+0.12*smoothstep(0.15,1.0,model_point.y),fabric_strength);
	if (cloth_pattern > 0.0) {
		float t=clamp((cloth_top-model_point.y)/max(0.01,cloth_top-cloth_hem),0.0,1.0);
		float edge=abs(model_point.x)/mix(0.19,cloth_width,t);
		float border=smoothstep(0.76,0.80,edge)*(1.0-smoothstep(0.93,0.96,edge));
		vec2 cell=vec2(model_point.x*32.0,model_point.y*22.0);
		cell.x+=mod(floor(cell.y),2.0)*0.5;
		vec2 shape=abs(fract(cell)-0.5);
		float diamond=shape.x+shape.y;
		float line=1.0-smoothstep(0.045,0.09,abs(diamond-0.38));
		float clarity=1.0-smoothstep(0.0025,0.009,footprint);
		float hem_band=1.0-smoothstep(0.04,0.08,abs(model_point.y-cloth_hem-0.085));
		float pattern=max(border*line,hem_band*line*0.7)*clarity;
		ALBEDO=mix(ALBEDO,embroidery_color.rgb*0.8,pattern*0.75);
	}
	METALLIC = surface_metallic;
	ROUGHNESS = surface_roughness;
	SPECULAR = 0.38;
	EMISSION = emission_color.rgb*min(emission_energy,0.65)+base_color.rgb*0.025;
}
void light() {
	float lambert = dot(NORMAL,LIGHT);
	// Broad, continuous light preserves sculpted form at mobile camera distance.
	float shade=0.22+0.78*smoothstep(-0.25,0.85,lambert);
	DIFFUSE_LIGHT += ALBEDO*shade*LIGHT_COLOR*ATTENUATION/PI;
	vec3 half_vector=normalize(LIGHT+VIEW);
	float sheen=pow(max(dot(NORMAL,half_vector),0.0),mix(24.0,70.0,1.0-surface_roughness));
	SPECULAR_LIGHT += mix(vec3(0.12),ALBEDO,surface_metallic)*sheen*LIGHT_COLOR*ATTENUATION*0.7;
}
