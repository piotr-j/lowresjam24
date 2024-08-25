extends CharacterBody2D
class_name PlayerCls

signal aggro_gained
signal aggro_lost

enum Facing {
	RIGHT, LEFT
}

# 12 will do for this :d
@onready var hp_1: HPIconCls = $CanvasLayer/ColorRect/HP1
@onready var hp_2: HPIconCls = $CanvasLayer/ColorRect/HP2
@onready var hp_3: HPIconCls = $CanvasLayer/ColorRect/HP3
@onready var camera_rect: ReferenceRect = $Camera2D/CameraRect

@onready var player_sprite: AnimatedSprite2D = $PlayerSprite2D
@onready var weapon_sprite_right: AnimatedSprite2D = $WeaponSprite2DRight
@onready var weapon_sprite_left: AnimatedSprite2D = $WeaponSprite2DLeft
@onready var attack_timer: Timer = $Timers/AttackTimer
@onready var attack_cast: ShapeCast2D = $AttackCast
@onready var jump_timer: Timer = $Timers/JumpTimer
@onready var dash_timer: Timer = $Timers/DashTimer
@onready var dash_cooldown: Timer = $Timers/DashCooldown


@export_category("debug")
@export var show_camera_rect := false

@export_category("movement")
@export var speed := 3600.0
@export var jump_speed := -160.0
@export var dash_damage := 8
@export var air_control := .5
@export var dash_speed := 10000.0
@export var dash_gravity_scale := .1
@export var dash_count_max := 0
# max amount if jumps player can make
@export var jump_count_max := 1

@export var input_enabled := true

@export_category("attack")
@export var attack_damage := 5

@export_category("health")
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


@export_category("references")
@export var respawn_spot: RespawnSpotCls
@export var enemies_scene: PackedScene
@export var pickups_scene: PackedScene


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var facing_direction := Facing.RIGHT

var attacking := false
var damaged := false
var dashing := false
var dash_played := false
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
var jump_count := 1:
	set(v):
		if v == jump_count:
			return
		jump_count = v
		if jump_count == 2 and not double_jump_played:
			double_jump_played = true
			$PlayerAnimations.play("show_jump_double")

var jump_id := 0


var keys:= 0:
	set(v):
		if v == keys:
			return
		if v > keys:
			$PlayerAnimations.play("show_key")
		keys = max(v, 0)
		$CanvasLayer/Key.visible = keys > 0

var aggro_count := 0:
	set(v):
		print('set aggro ' + str(v))
		if v == aggro_count:
			return
		v = max(v, 0)
		if v > aggro_count and aggro_count == 0:
			aggro_gained.emit()
		if v < aggro_count and v == 0:
			aggro_lost.emit()
		aggro_count = v
	
func _ready() -> void:
	health = health_start
	jump_count = jump_count_max
	keys = 0
	$CanvasLayer/Key.visible = false
	$Camera2D/CameraRect.visible = show_camera_rect

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
		$Audio/AudioDamage.play()
		$Particles/ParticlesDamagePlayer.emitting = true

func die () -> void:
	if $CanvasLayer/InfoDied.visible:
		return
	$CanvasLayer/InfoDied.visible = true
	input_enabled = false
	$PlayerAnimations.play("died")
	player_sprite.play("dead")
	$Audio/AudioDeath.play()
	$Particles/ParticlesDeadPlayer.emitting = true
	# drop key?
	#get_tree().reload_current_scene()
	
func respawn() -> void:
	$PlayerAnimations.play("RESET")
	$CanvasLayer/InfoDied.visible = false
	input_enabled = true
	player_sprite.play("idle")
	position = respawn_spot.position - Vector2(8, 0)
	health = health_max
	aggro_count = 0
	# seems to work-ish
	var old_enemies: Node = get_tree().get_first_node_in_group("enemies")
	if old_enemies:
		for child in old_enemies.get_children():
			child.restart()
	var old_pickups: Node = get_tree().get_first_node_in_group("pickups")
	if old_pickups:
		for child in old_pickups.get_children():
			child.restart()
	#call_deferred("respawn_scenes")

func respawn_scenes() -> void:
	if enemies_scene:
		get_tree().root.add_child(enemies_scene.instantiate())
	if pickups_scene:
		get_tree().root.add_child(pickups_scene.instantiate())

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	#print ('physics fps ' + str(1.0/delta) + ", dt " + str(delta))
	# Add the gravity.
	var air_control_scale := 1.0
	if not is_on_floor():
		if dashing:
			velocity.y += gravity * delta * dash_gravity_scale
		else:
			velocity.y += gravity * delta
		air_control_scale = air_control
	else:
		jump_reset()
		$Timers/WasOnFloorTimer.start()
		
	if damaged:
		velocity.y += -300 * delta
		damaged = false

	try_jump()
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction and input_enabled:
		velocity.x = direction * speed * air_control_scale * delta
	else:
		velocity.x = move_toward(velocity.x, 0, speed * air_control_scale * delta)
		
	# change direction even if blocked (eg by enemy)
	update_facing()
		
	if Input.is_action_just_pressed("dash") and not dashing and dash_cooldown.time_left <= 0 and dash_count > 0 and input_enabled:
		dash_timer.start()
		dash_cooldown.start()
		weapon_sprite.play("attack_dash")
		ignore_enemy_damage.clear()
		dashing = true
		dash_count -= 1
		velocity.y = 0
		$Audio/AudioDash.play()
		$Particles/ParticlesDash.emitting = true
		
	if dashing:
		#print('dashing!' + str(velocity.y))
		attack_front(dash_damage)
		if facing_direction == Facing.RIGHT:
			velocity.x = dash_speed * delta
		else:
			velocity.x = -dash_speed * delta

	player_sprite.flip_h = facing_direction == Facing.LEFT
	
	move_and_slide()

	$Particles/ParticlesWalk.emitting = velocity.x > .1 or velocity.x < -.1 and is_on_floor()

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
		$Audio/AudioAttack.play()
		weapon_sprite.play("attack")
		attack_front(attack_damage)
		
func update_facing () -> void:
	if dashing:
		return
		
	if velocity.x > 0.1:
		facing_direction = Facing.RIGHT
		attack_cast.rotation_degrees = 0
		$Particles/ParticlesDash.rotation_degrees = 0
	elif velocity.x < -0.1:
		facing_direction = Facing.LEFT
		attack_cast.rotation_degrees = 180
		$Particles/ParticlesDash.rotation_degrees = 180
		
	weapon_sprite_right.visible = facing_direction != Facing.LEFT
	weapon_sprite_left.visible = facing_direction == Facing.LEFT
	
	
func attack_front(damage :int) -> void:
	attack_cast.force_shapecast_update()
	var count := attack_cast.get_collision_count()
	for i in range(count):
		var collider := attack_cast.get_collider(i)
		if collider is EnemyCls:
			if not ignore_enemy_damage.has(collider):
				ignore_enemy_damage.push_back(collider)
				#print('attack: ' + str(collider))
				collider.damage(attack_damage)
	
func try_jump() -> void:
	# Handle jump.
	if not Input.is_action_just_pressed("jump") or not input_enabled:
		return
	# no double jump
	if jump_count_max == 1:
		if is_on_floor() or was_on_floor():
			jump_start()
			$Audio/AudioJump.play()
			$Particles/ParticlesJump.emitting = true
		return
		
	# double jump can be done only from ground, eg not when we are falling without jumping first
	if jump_id == 0:
		if not (is_on_floor() or was_on_floor()):
			jump_count -= 1
		jump_start()
		$Audio/AudioJump.play()
		$Particles/ParticlesJump.emitting = true
	elif jump_count > 0:
		jump_start()
		$Audio/AudioJump2.play()
		$Particles/ParticlesJump2.emitting = true
		
			
func jump_start() -> void:
	jump_count -= 1
	velocity.y = jump_speed
	jump_timer.start()
	jump_id += 1
		
		
func jump_reset() -> void:
	jump_count = jump_count_max
	jump_timer.stop()
	dash_count = dash_count_max
	jump_id = 0
	
func was_on_floor() -> bool:
	return $Timers/WasOnFloorTimer.time_left > 0

func _on_attack_timer_timeout() -> void:
	attacking = false


func _on_dash_timer_timeout() -> void:
	dashing = false
	weapon_sprite.play("empty")
