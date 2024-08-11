extends TextureRect
class_name HPIcon

const HP_EMPTY = preload("res://Assets/hp_empty.tres")
const HP_QUARTER = preload("res://Assets/hp_quarter.tres")
const HP_HALF = preload("res://Assets/hp_half.tres")
const HP_THREEQUARTER = preload("res://Assets/hp_threequarter.tres")
const HP_FULL = preload("res://Assets/hp_full.tres")

func _ready() -> void:
	pass
	
func set_health(hp: int) -> void:
	print ('hp: ' + str(hp))
	
	if hp <= 0:
		set_texture(HP_EMPTY)
	elif hp == 1:
		set_texture(HP_QUARTER)
	elif hp == 2:
		set_texture(HP_HALF)
	elif hp == 3:
		set_texture(HP_THREEQUARTER)
	else:
		set_texture(HP_FULL)
	
