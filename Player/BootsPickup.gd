extends Area2D
class_name PickupBootsCls

var used := false

func _ready() -> void:
	$AnimationPlayer.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if used:
		return
	if body is PlayerCls:
		used = true
		body.jump_count_max += 1
		$AnimationPlayer.play("destroy")
		$AudioHeal.play()
