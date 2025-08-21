extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 0.2 # Define a speed for dashing
const DASH_DURATION = 0.2 # Define how long the dash lasts
const DEATH_VELOCITY_Y = 0.0 # No specific upward/downward push on death
const DEATH_RELOAD_DELAY = 0.8 # Delay to allow death animation to play before reloading

const MAX_LIVES = 3 # New: Total lives the player starts with
const HURT_INVINCIBILITY_DURATION = 1.0 # New: Time in seconds player is invincible after being hurt
const HURT_FLASH_SPEED = 0.1 # New: How fast the sprite flashes during invincibility

# Reference to your single AnimatedSprite2D node
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D # Reference to your player's CollisionShape2D
# New: Reference to your HBoxContainer holding the heart TextureRects
# FIX: Changed %bar to the correct full path from the scene root.
@onready var health_bar_container: HBoxContainer = %bar

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var is_attacking: bool = false # State variable for attack
var is_dashing: bool = false # State variable for dash
var dash_timer: float = 0.0 # Timer for dash duration

var dash_direction: float = 0.0 # Direction of the dash

var is_dead: bool = false # State variable for final death
var lives: int = MAX_LIVES # New: Current lives
var is_invincible: bool = false # New: State variable for invincibility
var invincibility_timer: float = 0.0 # New: Timer for invincibility duration
var death_timer: float = 0.0 # Timer for death animation duration before reload

func _ready() -> void:
	# Connect the 'animation_finished' signal from the AnimatedSprite2D
	# This signal emits when a non-looping animation finishes playing.
	sprite_2d.animation_finished.connect(_on_sprite_2d_animation_finished)
	# Start with the idle animation
	sprite_2d.animation = "idle_anim"
	sprite_2d.play()
	
	# Initial setup: Ensure player starts with full lives
	lives = MAX_LIVES
	is_dead = false
	is_invincible = false
	invincibility_timer = 0.0
	
	# Initial update of the health bar display
	# Added a check to ensure health_bar_container is valid before using it
	if is_instance_valid(health_bar_container):
		update_health_display() 
		print("Player spawned with ", lives, " lives.") # Debug
	else:
		print("ERROR: Health bar container not found, cannot update display.")

# Renamed 'die()' to 'take_damage()' for clarity.
# This function is called by spikes or other hazards when they hit the player.
func take_damage() -> void:
	if is_dead or is_invincible: # Don't take damage if already dead or invincible
		return

	lives -= 1
	print("Player took damage! Lives remaining: ", lives) # Debug

	# Update the visual health bar immediately after taking damage
	if is_instance_valid(health_bar_container): # Check validity before calling
		update_health_display()

	if lives <= 0:
		# --- Player is truly dead ---
		is_dead = true
		death_timer = DEATH_RELOAD_DELAY
		
		# Stop all character movement immediately
		velocity = Vector2.ZERO 
		
		# Turn off collisions so player doesn't interact with world anymore
		collision_shape.set_deferred("disabled", true) # Use set_deferred for physics properties
		
		# Play the specific "death" animation
		# Ensure you have a non-looping "death" animation in your AnimatedSprite2D's SpriteFrames.
		sprite_2d.animation = "death"
		sprite_2d.play()
		
		# Hide character after death animation, or use particles here
		# sprite_2d.hide()
		
		print("Player character is dead! Playing death animation.") # Debug
	else:
		# --- Player is hurt but has lives left ---
		is_invincible = true
		invincibility_timer = HURT_INVINCIBILITY_DURATION
		
		# Play the "hurt" animation
		# Ensure you have a non-looping "hurt" animation in your AnimatedSprite2D's SpriteFrames.
		sprite_2d.animation = "hurt"
		sprite_2d.play()
		
		# Optional: Add a temporary knockback effect
		# velocity.y = JUMP_VELOCITY * 0.5 # Small bounce up
		# velocity.x = -sign(velocity.x) * SPEED * 0.5 if abs(velocity.x) > 0 else 0 # Small push back

# New: Function to update the visibility of hearts in the health bar
func update_health_display() -> void:
	# Iterate through all children (heart TextureRects) in the HBoxContainer
	# Added a check to ensure health_bar_container is valid before iterating its children
	if is_instance_valid(health_bar_container):
		for i in range(health_bar_container.get_child_count()):
			var heart_node = health_bar_container.get_child(i)
			# Hide hearts that represent depleted lives
			# For 3 lives: lives=3 -> show heart3, heart2, heart1
			#              lives=2 -> show heart2, heart1, hide heart3
			#              lives=1 -> show heart1, hide heart2, heart3
			#              lives=0 -> hide all
			if i < lives:
				heart_node.show()
			else:
				heart_node.hide()
		print("Health display updated. Hearts visible: ", lives) # Debug
	else:
		print("ERROR: Cannot update health display, health bar container is not valid.")

func _physics_process(delta):
	# Handle death state first, overrides all other actions
	if is_dead:
		# When dead, we only count down the timer and reload.
		# Physics (gravity, move_and_slide) is now explicitly NOT applied
		# to allow the death animation to play without physical interaction.
		# Removed: velocity.y += gravity * delta
		# Removed: move_and_slide()
		
		# Countdown to reload scene
		death_timer -= delta
		if death_timer <= 0:
			get_tree().reload_current_scene() # Reload the level
			print("Level reloaded after death animation finished.") # Debug
		return # Exit early, no other input/movement if dead

	# Handle invincibility after being hurt
	if is_invincible:
		invincibility_timer -= delta
		# Flash the sprite to indicate invincibility
		# Corrected: Using Time.get_ticks_msec() for a reliable time value
		var flash_alpha = abs(sin(Time.get_ticks_msec() / 1000.0 * PI * (1.0 / HURT_FLASH_SPEED)))
		# Set alpha from a range (e.g., 0.5 to 1.0) instead of 0-1 for a more subtle flash
		sprite_2d.modulate = Color(1.0, 1.0, 1.0, 0.5 + flash_alpha * 0.5) 

		if invincibility_timer <= 0:
			is_invincible = false
			sprite_2d.modulate = Color(1.0, 1.0, 1.0, 1.0) # Reset sprite transparency
			print("Player is no longer invincible.") # Debug
		# Even when invincible, player can still move, attack, dash etc.
		# So we DON'T 'return' here, we let the rest of _physics_process run.
	
	# Rest of your existing movement, attack, dash, and jump logic
	# (No changes to this part unless specifically for hurt state interactions)

	# Handle attack and dash states first, as they often override other actions
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
		if velocity.x == 0:
			pass 
		else:
			sprite_2d.flip_h = velocity.x < 0
			
	move_and_slide()

	var target_animation: String = sprite_2d.animation
	var should_play: bool = false 

	# Animation logic now considers 'is_invincible' (for hurt anim) as a high priority state
	if is_dead: # If player is dead, keep 'death' anim playing, do not change
		pass
	elif is_invincible: # If player is invincible (hurt state), play hurt anim
		if sprite_2d.animation != "hurt":
			target_animation = "hurt"
			should_play = true
	elif is_attacking:
		target_animation = "attack"
	elif is_dashing:
		target_animation = "dash"
	elif not is_on_floor():
		if velocity.y < 0:
			target_animation = "jump"
		else:
			target_animation = "fall"
	else:
		if abs(velocity.x) > 1:
			target_animation = "running"
		else:
			target_animation = "idle_anim"

	if sprite_2d.animation != target_animation:
		sprite_2d.animation = target_animation
		should_play = true
	
	if should_play:
		sprite_2d.play()


func _on_sprite_2d_animation_finished():
	if sprite_2d.animation == "attack":
		is_attacking = false
		# Important: After attack, immediately re-evaluate current state
		# This will ensure the correct idle/run/jump/fall animation starts.
		_physics_process(0) # Pass 0 delta as we just want to update animation state
	
	if sprite_2d.animation == "dash":
		is_dashing = false
		# Same for dash: re-evaluate state
		_physics_process(0)

	# New: Handle 'hurt' animation finishing
	if sprite_2d.animation == "hurt":
		# After 'hurt' animation finishes, the player should return to
		# their regular animation (idle, running, jumping, etc.)
		# The invincibility will still be active for HURT_INVINCIBILITY_DURATION
		_physics_process(0) # Re-evaluate animation based on current state (idle/run/etc)
