extends CharacterBody2D
class_name Player

enum Facing {
	RIGHT, LEFT
}

# 12 will do for this :d
@onready var hp_1: HPIcon = $CanvasLayer/ColorRect/HBoxContainer/HP1
@onready var hp_2: HPIcon = $CanvasLayer/ColorRect/HBoxContainer/HP2
@onready var hp_3: HPIcon = $CanvasLayer/ColorRect/HBoxContainer/HP3

@export var speed := 60.0
@export var jump_speed := -160.0
@export var attack_damage := 5

@export var health_max := 12
@export var health_start := 6
var health :int :
	get:
		return health
	set(v):
		health = clamp(v, 0, health_max)
		
		print('player hp ' + str(health))
		
		hp_1.set_health(clamp(health, 0, 4))
		hp_2.set_health(clamp(health - 4, 0, 4))
		hp_3.set_health(clamp(health - 8, 0, 4))
		
		
		if health <= 0:
			die()

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var player_sprite: AnimatedSprite2D = $PlayerSprite2D
@onready var weapon_sprite_right: AnimatedSprite2D = $WeaponSprite2DRight
@onready var weapon_sprite_left: AnimatedSprite2D = $WeaponSprite2DLeft
@onready var attack_timer: Timer = $AttackTimer
@onready var attack_cast: ShapeCast2D = $AttackCast


var facing_direction := Facing.RIGHT

var attacking := false
var damaged := false

var weapon_sprite: AnimatedSprite2D:	
	get:
		if facing_direction == Facing.RIGHT:
			return weapon_sprite_right
		return weapon_sprite_left
		
func damage(damage: int) -> void:
	health -= damage
	damaged = true

func die () -> void:
	# todo some animation/particles etc!
	print('died!')
	get_tree().reload_current_scene()
	
func _ready() -> void:
	health = health_start

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if damaged:
		velocity.y += -50
		damaged = false

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_speed
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	
	if velocity.x > 0.1:
		facing_direction = Facing.RIGHT
		weapon_sprite_right.visible = true
		weapon_sprite_left.visible = false
		attack_cast.rotation_degrees = 0
	elif velocity.x < -0.1:
		facing_direction = Facing.LEFT
		weapon_sprite_right.visible = false
		weapon_sprite_left.visible = true
		attack_cast.rotation_degrees = 180
			
	if is_on_floor():
		if velocity.x > 0.1:
			player_sprite.play("move")
			player_sprite.flip_h = false
		elif velocity.x < -0.1:
			player_sprite.play("move")
			player_sprite.flip_h = true
		else:
			player_sprite.play("idle")
	else:
		if velocity.y < 0:
			player_sprite.play("jump")
		else:
			player_sprite.play("fall")
			
		
	if Input.is_action_just_pressed("attack") and not attacking:
		print('attack!')
		attack_timer.start()
		attacking = true
		weapon_sprite.play("attack")
		attack_cast.force_shapecast_update()
		var count := attack_cast.get_collision_count()
		for i in range(count):
			var collider := attack_cast.get_collider(i)
			if collider is Enemy:
				print('attack: ' + str(collider))
				collider.damage(attack_damage)
			
		


func _on_attack_timer_timeout() -> void:
	attacking = false
	print('attack done!')
