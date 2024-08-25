extends CharacterBody2D
class_name EnemyCls

@export_category("movement")
@export var speed := 3000
@export var jump_speed := -120.0
@export var can_jump_randomly := true
@export var jump_chance := .02

@export_category("health")
@export var health_max := 15

@export_category("attack")
@export var attack_damage := 2
@export var can_be_interrupted := true

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

func _ready() -> void:
	start_pos = position
	$AnimatedSprite2D.play("idle")
	
func damage(damage: int) -> void:
	if dead:
		return
	#print('damage ' + str(self) + ' ' + str(damage))
	health -= damage
	if health > 0:
		damaged = true
		$ParticlesDamageEnemy.emitting = true
		# restart attack timer if its running$ParticlesDamageEnemy
		if can_be_interrupted and attack_timer.time_left > 0:
			attack_timer.start()

func die () -> void:
	if dead:
		return
	if player:
		player.aggro_count -= 1
	#print('die' + str(self))
	player = null
	# todo some animation/particles etc!
	#queue_free()
	dead = true
	$AnimatedSprite2D.play("dead")
	$ParticlesDeadEnemy.emitting = true
	$CollisionShape2D.disabled = true
	#process_mode = Node.PROCESS_MODE_DISABLED

var start_pos: Vector2

	
func restart () -> void:
	#print('restart' + str(self))
	position = start_pos
	#process_mode = Node.PROCESS_MODE_INHERIT
	call_deferred("do_restart")

func do_restart() -> void:
	health = health_max
	damaged = false
	dead = false
	player = null
	$AnimatedSprite2D.play("idle")
	$CollisionShape2D.disabled = false
	
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

	# TODO direction based!
	if damaged:
		velocity.y += -300 * delta
		damaged = false
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	if health >= 0:
		# go back to start by default
		var direction := start_pos - position
		if player:
			direction = player.position - position
			
		# dont hug the player?
		if direction and direction.length() >= 8.5:
			velocity.x = direction.normalized().x * speed * delta
			$AnimatedSprite2D.play("move")
			if velocity.x < 0:
				$AnimatedSprite2D.flip_h = true
			else:
				$AnimatedSprite2D.flip_h = false
		else:
			velocity.x = 0
			if not player:
				$AnimatedSprite2D.play("idle")
	else:
		velocity.x = 0

	move_and_slide()

func _on_detection_inner_body_entered(body: Node2D) -> void:
	if dead:
		return
	if not body is PlayerCls:
		return
	if not player:
		body.aggro_count += 1
	player = body
	#print('Player entered! ' + str(self))


func _on_detection_outer_body_exited(body: Node2D) -> void:
	if dead:
		return
	if not body is PlayerCls:
		return
	if player:
		player.aggro_count -= 1
	player = null
	$AnimatedSprite2D.play("idle")
	#print('Player left! ' + str(self))


func _on_attack_timer_timeout() -> void:
	if dead:
		attack_timer.stop()
		return
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
