extends Camera2D

func _process(delta: float) -> void:
	var pos := get_screen_center_position()
	var offset := Vector2(pos.x - floor(pos.x), pos.y - floor(pos.y))
	
	RenderingServer.global_shader_parameter_set("camera_offset", offset)
	RenderingServer.global_shader_parameter_set("camera_position", pos)
