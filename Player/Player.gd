extends CharacterBody2D
class_name Player

enum Facing {
	RIGHT, LEFT
}

# 12 will do for this :d
@onready var hp_1: HPIcon = $CanvasLayer/ColorRect/HP1
@onready var hp_2: HPIcon = $CanvasLayer/ColorRect/HP2
@onready var hp_3: HPIcon = $CanvasLayer/ColorRect/HP3

@export var speed := 60.0
@export var jump_speed := -160.0
@export var attack_damage := 5
@export var dash_damage := 8
@export var air_control := .5
@export var dash_speed := 10000.0

@export var respawn_spot: RespawnSpot

@export var health_max := 12
@export var health_start := 6
var health :int :
	get:
		return health
	set(v):
		if v == health:
			return
			
		health = clamp(v, 0, health_max)
		
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
@onready var jump_timer: Timer = $JumpTimer
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown: Timer = $DashCooldown


var facing_direction := Facing.RIGHT

var attacking := false
var damaged := false
var dashing := false
var dash_played := false
@export var dash_count_max := 0
var dash_count := dash_count_max:
	set(v):
		if dash_count == v:
			return
		dash_count = v
		if dash_count == 1 and not dash_played:
			dash_played = true
			print('play dash ' + str(v))
			$PlayerAnimations.play("show_dash")

# array of enemies that we already damaged, so we dont do that each tick
var ignore_enemy_damage := []
var double_jump_played := false
# max amount if jumps player can make
@export var jump_count_max := 1
var jump_count := 1:
	set(v):
		if v == jump_count:
			return
		jump_count = v
		if jump_count == 2 and not double_jump_played:
			double_jump_played = true
			$PlayerAnimations.play("show_jump_double")
			

@export var input_enabled := true
#@export var enemies: Enemies

@export var enemies_scene: PackedScene

var keys:= 0:
	set(v):
		if v == keys:
			return
		if v > keys:
			$PlayerAnimations.play("show_key")
		keys = max(v, 0)
		$CanvasLayer/Key.visible = keys > 0

func play_need_key() -> void:
	$PlayerAnimations.play("show_key_needed")

var weapon_sprite: AnimatedSprite2D:	
	get:
		if facing_direction == Facing.RIGHT:
			return weapon_sprite_right
		return weapon_sprite_left
		
func damage(damage: int) -> void:
	health -= damage
	if health > 0:
		damaged = true

func die () -> void:
	$CanvasLayer/InfoDied.visible = true
	input_enabled = false
	$PlayerAnimations.play("died")
	player_sprite.play("dead")
	# drop key?
	#get_tree().reload_current_scene()
	
func respawn() -> void:
	$PlayerAnimations.play("RESET")
	$CanvasLayer/InfoDied.visible = false
	input_enabled = true
	player_sprite.play("idle")
	position = respawn_spot.position
	health = health_max
	# seems to work
	get_tree().get_first_node_in_group("enemies").queue_free()
	get_tree().root.add_child(enemies_scene.instantiate())
	
func _ready() -> void:
	health = health_start
	jump_count = jump_count_max
	keys = 0
	$CanvasLayer/InfoMove.visible = true

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	# Add the gravity.
	var air_control_scale := 1.0
	if not is_on_floor():
		velocity.y += gravity * delta
		air_control_scale = air_control
	else:
		jump_count = jump_count_max
		jump_timer.stop()
		dash_count = dash_count_max
		
	if damaged:
		velocity.y += -50
		damaged = false

	# Handle jump.
	if Input.is_action_just_pressed("jump") and jump_count > 0 and velocity.y >= 0 and input_enabled:
		jump_count -= 1
		velocity.y = jump_speed
		jump_timer.start()
	
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction and input_enabled:
		velocity.x = direction * speed * air_control_scale
		if $CanvasLayer/InfoMove.visible:
			$PlayerAnimations.play("hide_move")
	else:
		velocity.x = move_toward(velocity.x, 0, speed * air_control_scale)
		
	# change direction even if blocked (eg by enemy)
	if not dashing:
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
		
	if Input.is_action_just_pressed("dash") and not dashing and dash_cooldown.time_left <= 0 and dash_count > 0 and input_enabled:
		dash_timer.start()
		dash_cooldown.start()
		weapon_sprite.play("attack_dash")
		ignore_enemy_damage.clear()
		dashing = true
		dash_count -= 1
		
	if dashing:
		#print('dashing!' + str(dash_timer.time_left))
		attack_front(dash_damage)
		if velocity.y < 0:
			velocity.y = 0
		if facing_direction == Facing.RIGHT:
			velocity.x = dash_speed * delta
		else:
			velocity.x = -dash_speed * delta

	player_sprite.flip_h = facing_direction == Facing.LEFT
	
	move_and_slide()

	if input_enabled:
		if is_on_floor():
			if velocity.x > 0.1:
				player_sprite.play("move")
			elif velocity.x < -0.1:
				player_sprite.play("move")
			else:
				player_sprite.play("idle")
				pass
		else:
			if velocity.y < 0:
				player_sprite.play("jump")
			else:
				player_sprite.play("fall")
			
		
	if Input.is_action_just_pressed("attack") and not attacking and not dashing and input_enabled:
		#print('attack!')
		if $CanvasLayer/InfoAttack.visible:
			$PlayerAnimations.play("hide_attack")
		ignore_enemy_damage.clear()
		attack_timer.start()
		attacking = true
		weapon_sprite.play("attack")
		attack_front(attack_damage)
		
func attack_front(damage :int) -> void:
	attack_cast.force_shapecast_update()
	var count := attack_cast.get_collision_count()
	for i in range(count):
		var collider := attack_cast.get_collider(i)
		if collider is Enemy:
			if not ignore_enemy_damage.has(collider):
				ignore_enemy_damage.push_back(collider)
				print('attack: ' + str(collider))
				collider.damage(attack_damage)


func _on_attack_timer_timeout() -> void:
	attacking = false


func _on_dash_timer_timeout() -> void:
	dashing = false
	weapon_sprite.play("empty")
