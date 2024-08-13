extends Area2D
class_name PickupKillCls


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerCls:
		body.damage(999)
	elif body is EnemyCls:
		body.damage(999)
