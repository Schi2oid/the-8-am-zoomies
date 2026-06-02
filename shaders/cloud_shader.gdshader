shader_type spatial;
render_mode cull_disabled, fog_disabled, blend_mix;

uniform vec4 cloud_color : source_color = vec4(0.9, 0.9, 0.95, 1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.4, 0.2, 1.0);
uniform float density : hint_range(0.0, 1.0) = 0.5;
uniform float light_transmission : hint_range(0.0, 1.0) = 0.8;

void fragment() {
	// Calculate distance from center for soft edges
	float dist = distance(VERTEX.xy, vec2(0.0));
	float alpha = smoothstep(1.0, 0.3, dist) * density;
	
	// Calculate light direction from directional light
	vec3 light_dir = normalize(-LIGHT);
	
	// Calculate normal-based lighting
	float normal_light = max(0.0, dot(NORMAL, light_dir));
	
	// Calculate view direction for rim lighting
	vec3 view_dir = normalize(VIEW);
	float rim_light = 1.0 - max(0.0, dot(NORMAL, view_dir));
	rim_light = pow(rim_light, 3.0);
	
	// Combine lighting effects
	float total_light = normal_light * 0.7 + rim_light * 0.3;
	
	// Mix cloud color with sun color based on light transmission
	// During sunrise, the sun_color will be red/orange
	vec3 final_color = mix(cloud_color.rgb, sun_color.rgb, total_light * light_transmission);
	
	// Add depth effect - edges are darker
	float depth_factor = 1.0 - dist * 0.3;
	final_color *= depth_factor;
	
	// Transparency based on light transmission
	// Clouds are more transparent when backlit by the sun
	float backlit = max(0.0, dot(-NORMAL, light_dir));
	float transmission_alpha = alpha * (1.0 - backlit * 0.4 * light_transmission);
	
	ALBEDO = final_color;
	ALPHA = transmission_alpha;
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
}
