extends CharacterBody2D
class_name Enemy

@export var speed := 2
@export var jump_speed := -120.0
@export var attack_damage := 2

@export var health_max := 15

var attack_pending := false
var attack_cooldown := false
var damaged := false

var health := health_max:
	get:
		return health
	set(v):
		health = v
		if health <= 0:
			die()

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var attack_timer: Timer = $AttackTimer
	
var player: Player

func damage(damage: int) -> void:
	health -= damage
	damaged = true
	# restart attack timer if its running
	if attack_timer.time_left > 0:
		attack_timer.start()

func die () -> void:
	player = null
	# todo some animation/particles etc!
	queue_free()
	
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	if damaged:
		velocity.y += -50
		damaged = false
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	if health >= 0 and player:
		var direction := player.position - position
		# dont hug the player?
		if direction and direction.length() >= 8.5:
			velocity.x = direction.x * speed
		else:
			velocity.x = 0

	move_and_slide()

func _on_detection_inner_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	player = body
	#print('Player entered! ' + str(self))


func _on_detection_outer_body_exited(body: Node2D) -> void:
	if not body is Player:
		return
	player = null
	#print('Player left! ' + str(self))


func _on_attack_timer_timeout() -> void:
	attack_pending = false
	for body: Node2D in $DetectionInner.get_overlapping_bodies():
		if not body is Player:
			continue
		#print('damage player!')
		body.damage(attack_damage)


func _on_detection_attack_body_entered(body: Node2D) -> void:
	if body is Player:
		attack_timer.start()


func _on_detection_attack_body_exited(body: Node2D) -> void:
	if body is Player:
		attack_timer.stop()
