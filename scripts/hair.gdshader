shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 ghost_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool is_ghost = false;
bool is_marker(vec4 raw_tex){
	return raw_tex.r <= 0.05 && raw_tex.b <= 0.05 && raw_tex.g > 0.5;
}
float get(vec4 col){
	if(is_marker(col)) return 0.0;
	else return col.a;
}
void fragment() {
	float tmp=COLOR.a;
    vec4 curr_color = texture(screen_texture, SCREEN_UV);
    if(is_marker(curr_color)) COLOR = line_color;
	else{
		 vec2 pixel_size = SCREEN_PIXEL_SIZE;

	    float a = get(texture(screen_texture, SCREEN_UV + vec2(pixel_size.x, 0.0)));
	    a += get(texture(screen_texture, SCREEN_UV + vec2(-pixel_size.x, 0.0)));
	    a += get(texture(screen_texture, SCREEN_UV + vec2(0.0, pixel_size.y)));
	    a += get(texture(screen_texture, SCREEN_UV + vec2(0.0, -pixel_size.y)));

	    if (curr_color.a == 0.0 && a > 0.0) {
	        COLOR = line_color;
	    } else {
	        COLOR = curr_color;
	    }
	}
	if(is_ghost && COLOR.a > 0.0){
		if(COLOR == line_color){
			COLOR = vec4(0,0,0,0);
		}
		else if(length(COLOR.rgb - vec3(0.0, 0.235, 0.388)) < 0.1){
			COLOR.rgb *= 10.0;
		}
		else{
			COLOR = ghost_color;
			COLOR.a = tmp;
		}
	}
}