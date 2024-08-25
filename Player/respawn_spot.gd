extends Node2D
class_name RespawnSpotCls

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var is_enabled := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func toggle(enabled:bool) -> void:
	if is_enabled == enabled:
		return
	is_enabled = enabled
	$ParticlesSmoke.emitting = enabled
	if enabled:
		animated_sprite_2d.play("on")
		$Audio.play()
	else:
		animated_sprite_2d.play("off")

func _on_detection_attack_body_entered(body: Node2D) -> void:
	if not body is PlayerCls:
		return
	
	body.respawn_spot = self
	
	for respawn in get_parent().get_children():
		respawn.toggle(respawn == self)
