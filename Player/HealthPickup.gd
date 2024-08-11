extends Area2D

@export var health := 4

var used := false

func _ready() -> void:
	$AnimationPlayer.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if used:
		return
	if body is Player and body.health < body.health_max:
		used = true
		body.health += health
		$AnimationPlayer.play("destroy")
