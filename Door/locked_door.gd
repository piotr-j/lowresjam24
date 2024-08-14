extends Node2D
class_name DoorCls

var is_open := false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if is_open:
		return
	if not body is PlayerCls:
		return
	if body.keys <= 0:
		body.play_need_key()
		return
	body.keys -= 1
	
	open()
	await get_tree().create_timer(2).timeout
	#print ("close!")
	#close()
	
	
func open() -> void:
	is_open = true
	$StaticBody2D.process_mode = Node.PROCESS_MODE_DISABLED
	$SpriteLocked.visible = false
	$SpriteOpenLeft.visible = true
	$SpriteOpenRight.visible = true
	$AudioOpen.play()
	
func close() -> void:
	is_open = false
	$StaticBody2D.process_mode = Node.PROCESS_MODE_INHERIT
	$SpriteLocked.visible = true
	$SpriteOpenLeft.visible = false
	$SpriteOpenRight.visible = false
