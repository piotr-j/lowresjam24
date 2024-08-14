extends Area2D
class_name PickupKeyCls

var used := false

func _ready() -> void:
	$AnimationPlayer.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if used:
		return
	if body is PlayerCls:
		$AudioKey.play()
		used = true
		body.keys += 1
		$AnimationPlayer.play("destroy")
