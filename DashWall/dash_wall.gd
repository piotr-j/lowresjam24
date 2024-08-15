extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var dead := false
var player: PlayerCls
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if dead:
		return
	if player and player.dashing:
		dead = true
		$Sprite2D.visible = false
		$ParticlesExplodes.emitting = true
		$StaticBody2D.process_mode = Node.PROCESS_MODE_DISABLED
		#queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is PlayerCls:
		player = body


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is PlayerCls:
		player = null
