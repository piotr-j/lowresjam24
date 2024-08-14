extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if not body is PlayerCls:
		return
	$AudioWin.play()
