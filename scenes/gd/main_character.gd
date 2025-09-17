extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 0.2
const DASH_DURATION = 0.2
const DEATH_RELOAD_DELAY = 0.8

const MAX_LIVES = 3
const HURT_INVINCIBILITY_DURATION = 1.0
const HURT_FLASH_SPEED = 0.1

@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar_container: HBoxContainer = %bar

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var is_attacking: bool = false
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: float = 0.0

var is_dead: bool = false
var lives: int = MAX_LIVES
var is_invincible: bool = false
var invincibility_timer: float = 0.0
var death_timer: float = 0.0

func _ready() -> void:
	sprite_2d.animation_finished.connect(_on_sprite_2d_animation_finished)
	sprite_2d.animation = "idle_anim"
	sprite_2d.play()
	
	lives = MAX_LIVES
	is_dead = false
	is_invincible = false
	invincibility_timer = 0.0
	
	if is_instance_valid(health_bar_container):
		update_health_display()
		print("Player spawned with ", lives, " lives.")
	else:
		print("ERROR: Health bar container not found, cannot update display.")

# We updated this function to accept a 'damage_amount' argument.
func take_damage(damage_amount: int = 1) -> void:
	print("take_damage() function called!") # New print statement for debugging
	
	if is_dead or is_invincible:
		return

	lives -= damage_amount
	print("Player took damage! Lives remaining: ", lives)

	if is_instance_valid(health_bar_container):
		update_health_display()

	if lives <= 0:
		is_dead = true
		death_timer = DEATH_RELOAD_DELAY
		
		velocity = Vector2.ZERO
		
		# set_deferred is important for changing physics properties safely
		collision_shape.set_deferred("disabled", true)
		
		sprite_2d.animation = "death"
		sprite_2d.play()
		
		print("Player character is dead! Playing death animation.")
	else:
		is_invincible = true
		invincibility_timer = HURT_INVINCIBILITY_DURATION
		
		sprite_2d.animation = "hurt"
		sprite_2d.play()
		
func update_health_display() -> void:
	if is_instance_valid(health_bar_container):
		for i in range(health_bar_container.get_child_count()):
			var heart_node = health_bar_container.get_child(i)
			if i < lives:
				heart_node.show()
			else:
				heart_node.hide()
		print("Health display updated. Hearts visible: ", lives)
	else:
		print("ERROR: Cannot update health display, health bar container is not valid.")

func _physics_process(delta):
	if is_dead:
		death_timer -= delta
		if death_timer <= 0:
			get_tree().reload_current_scene()
			print("Level reloaded after death animation finished.")
		return
	
	if is_invincible:
		invincibility_timer -= delta
		var flash_alpha = abs(sin(Time.get_ticks_msec() / 1000.0 * PI * (1.0 / HURT_FLASH_SPEED)))
		sprite_2d.modulate = Color(1.0, 1.0, 1.0, 0.5 + flash_alpha * 0.5)

		if invincibility_timer <= 0:
			is_invincible = false
			sprite_2d.modulate = Color(1.0, 1.0, 1.0, 1.0)
			print("Player is no longer invincible.")
	
	if is_attacking:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return
	
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity.x = move_toward(velocity.x, 0, SPEED)
		else:
			velocity.x = dash_direction * DASH_SPEED
			move_and_slide()
			return

	if not is_on_floor():
		velocity.y += gravity * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("attack") and is_on_floor() and not is_attacking:
		is_attacking = true
		sprite_2d.animation = "attack"
		sprite_2d.play()

	if Input.is_action_just_pressed("dash") and is_on_floor() and not is_dashing and not is_attacking:
		is_dashing = true
		dash_timer = DASH_DURATION
		if abs(velocity.x) > 1:
			dash_direction = sign(velocity.x)
		else:
			dash_direction = -1 if sprite_2d.flip_h else 1
		sprite_2d.animation = "dash"
		sprite_2d.play()

	var direction = Input.get_axis("left", "right")
	
	if direction:
		velocity.x = direction * SPEED
		sprite_2d.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, 12)
		
	move_and_slide()

	var target_animation: String
	
	if is_dead:
		target_animation = "death"
	elif is_invincible:
		target_animation = "hurt"
	elif is_attacking:
		target_animation = "attack"
	elif is_dashing:
		target_animation = "dash"
	elif not is_on_floor():
		target_animation = "jump" if velocity.y < 0 else "fall"
	else:
		target_animation = "running" if abs(velocity.x) > 1 else "idle_anim"

	if sprite_2d.animation != target_animation:
		sprite_2d.animation = target_animation
		sprite_2d.play()

func _on_sprite_2d_animation_finished():
	if sprite_2d.animation == "attack" or sprite_2d.animation == "dash" or sprite_2d.animation == "hurt":
		# After a non-looping animation finishes, re-evaluate the player's state
		# to transition to the correct next animation (idle, running, etc.)
		_physics_process(0)
