shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

//uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
global uniform vec2 camera_position;
global uniform vec2 camera_offset;

void fragment() {

	float px = fract((UV.x)*1.0);// + camera_offset.x);
	float py = fract((UV.y)*1.0);// + camera_offset.y);

	float cs = smoothstep(0.8, 1.0, px) + smoothstep(0.8, 1.0, 1.0 - px);
	cs += smoothstep(0.8, 1.0, py) + smoothstep(0.8, 1.0, 1.0 - py);
	cs /= 4.0;


	COLOR *= vec4(vec3(clamp(pow(1.0 - cs, 0.3) - py * 0.1, 0.0, 1.0)), 1.0);
	//COLOR = vec4(px, py, 0.0, 1.0);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
