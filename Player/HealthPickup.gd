extends Area2D
class_name PickupHealthCls

@export var health := 4

var used := false

func _ready() -> void:
	#$AnimationPlayer.play("RESET")
	$AnimationPlayer.play("idle")
	
func restart() -> void:
	used = false
	$Sprite2D.visible = true
	#$AnimationPlayer.play("RESET")
	$AnimationPlayer.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if used:
		return
	if body is PlayerCls and body.health < body.health_max:
		used = true
		body.health += health
		$AnimationPlayer.play("destroy")
		$Audio.play()
