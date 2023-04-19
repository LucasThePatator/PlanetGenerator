shader_type spatial;
render_mode specular_toon;

uniform vec4 water_blue : hint_color = vec4(0.2, 0.2, 0.5, 1.0);
uniform float earth_rough : hint_range(0.0, 1.0, 0.1);
uniform float earth_metal : hint_range(0.0, 1.0, 0.1);
uniform float earth_rim : hint_range(0.0, 1.0, 0.1);
uniform float water_level : hint_range(0.0, 2.0, 0.01) = 1.0;

varying float is_water;


void vertex() {
	float l = length(VERTEX.xyz)/water_level;
	is_water = 0.0;
	if(l < water_level*1.0)
	{
		is_water = 1.0;
		VERTEX.xyz = normalize(VERTEX.xyz);
		NORMAL = normalize(VERTEX.xyz);
		COLOR = water_blue;
	} else if(l < water_level*1.01)
	{
		COLOR.rgb = vec3(0.5, 0.5, 0.1);
	} else if(l < water_level*1.08)
	{
		COLOR.rgb = l*vec3(0.8, 1.0, 0.8) - vec3(0.5, 0.3, 0.5);
	} else if(l < water_level*1.1)
	{
		COLOR.rgb = l*vec3(0.9, 0.9, 0.9) - vec3(0.5, 0.5, 0.5);
	}
}

void fragment()
{
	ALBEDO = COLOR.rgb;
	if(is_water > 0.8)
	{
		METALLIC = 0.0;
		float fresnel = sqrt(1.0 - dot(NORMAL, VIEW));
		ROUGHNESS = 0.01 * (1.0 - fresnel);
		RIM = 0.2;
		ALBEDO = water_blue.rgb + (0.1 * fresnel);
	} else
	{
		METALLIC = earth_metal;
		ROUGHNESS = earth_rough;
		RIM = earth_rim;
	}
	

	
}
