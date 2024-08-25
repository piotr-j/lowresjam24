shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	
	//COLOR = texture(TEXTURE, UV) * vec4(fract(FRAGCOORD.x*64.0), fract(FRAGCOORD.y*64.0), 0.0, 1.0);
	float px = fract(FRAGCOORD.x/16.0);
	float py = fract(FRAGCOORD.y/16.0);
	float ss = 8.0/16.0;
	//float cs = (smoothstep(0.0, ss, px) * smoothstep(0.0, ss, py) * smoothstep(0.0, ss, 1.0 - px) * smoothstep(0.0, ss, 1.0 - py)) * 16.0;
	//float cs = px * py * (1.0 - px) * (1.0 - py);
	//float cs = (px + py + (1.0 - px) + (1.0 - py))/4.0;
	float cs = smoothstep(0.8, 1.0, px) + smoothstep(0.8, 1.0, 1.0 - px);
	cs += smoothstep(0.8, 1.0, py) + smoothstep(0.8, 1.0, 1.0 - py);
	cs /= 4.0;
	//float cs = (smoothstep(0.0, ss, px) + smoothstep(0.0, ss, py) + smoothstep(0.0, ss, 1.0 - px) + smoothstep(0.0, ss, 1.0 - py))/4.0;
	//COLOR = texture(TEXTURE, UV) * vec4(px, py, 0.0, 1.0);
	//COLOR = texture(TEXTURE, UV) * clamp(cs, 0.9, 1.0);
	//COLOR = texture(TEXTURE, UV) * clamp(cs, 0.9, 1.0);
	COLOR = texture(TEXTURE, UV) * vec4(vec3(clamp(pow(1.0 - cs, 0.3) - py * 0.1, 0.0, 1.0)), 1.0);
	//COLOR = vec4(vec3(smoothstep(0.0, 1.0, 1.0 - py))/8.0, 1.0);
	//COLOR = vec4(vec3(py) * .2, 1.0);
	//COLOR = texture(TEXTURE, UV) * vec4(POINT_COORD.x, POINT_COORD.y, 0.0, 1.0);
	//COLOR = texture(TEXTURE, UV) * vec4(FRAGCOORD.x*2.0, 0.0, 0.0, 1.0);
	//COLOR = texture(TEXTURE, UV) * vec4(0.0, fract(POINT_COORD.x), 0.0, 1.0);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
