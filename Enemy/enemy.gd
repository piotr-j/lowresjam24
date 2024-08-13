extends CharacterBody2D
class_name EnemyCls

@export var speed := 2
@export var jump_speed := -120.0
@export var attack_damage := 2
@export var can_be_interrupted := true
@export var can_jump_randomly := true
@export var jump_chance := .02

@export var health_max := 15

var attack_pending := false
var attack_cooldown := false
var damaged := false

var dead := false

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
	
var player: PlayerCls

func damage(damage: int) -> void:
	health -= damage
	damaged = true
	# restart attack timer if its running
	if can_be_interrupted and attack_timer.time_left > 0:
		attack_timer.start()

func die () -> void:
	player = null
	# todo some animation/particles etc!
	#queue_free()
	dead = true
	# todo particles!
	$Sprite2D.visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

var start_pos: Vector2

func _ready() -> void:
	start_pos = position
	
func restart () -> void:
	position = start_pos
	health = health_max
	dead = false
	player = null
	$Sprite2D.visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if dead: 
		return
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if player and can_jump_randomly and is_on_floor() and randf() < jump_chance:
		velocity.y = jump_speed

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
	if not body is PlayerCls:
		return
	player = body
	#print('Player entered! ' + str(self))


func _on_detection_outer_body_exited(body: Node2D) -> void:
	if not body is PlayerCls:
		return
	player = null
	#print('Player left! ' + str(self))


func _on_attack_timer_timeout() -> void:
	attack_pending = false
	for body: Node2D in $DetectionAttack.get_overlapping_bodies():
		if not body is PlayerCls:
			continue
		#print('damage player!')
		body.damage(attack_damage)
		return
	attack_timer.stop()


func _on_detection_attack_body_entered(body: Node2D) -> void:
	if dead:
		return
	if body is PlayerCls:
		if attack_timer.time_left <= 0:
			body.damage(attack_damage)
			attack_timer.start()


func _on_detection_attack_body_exited(body: Node2D) -> void:
	pass
	#if body is Player:
		#attack_timer.stop()
