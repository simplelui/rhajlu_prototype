extends Area2D

@export var damage_amount: int = 1
@export var spike_move_distance: float = 25.0
@export var spike_move_speed: float = 1000.0

@onready var spike_timer = $Spiketimer
@onready var retract_timer = $Retrack
@onready var killzone = $killzone
@onready var damage_timer: Timer = $killzone/DamageTimer

var is_triggered: bool = false
var is_moving_up: bool = false
var spikes_extended: bool = false   # Track when spikes are up
var original_position: Vector2
var target_position: Vector2

# Track trigger & killzone state
var player_in_trigger: bool = false
var player_in_zone: bool = false
var current_body: CharacterBody2D = null

func _ready():
	print("Spike trap ready")
	original_position = position
	target_position = original_position - Vector2(0, spike_move_distance)
	
	spike_timer.one_shot = true
	retract_timer.one_shot = true
	
	damage_timer.one_shot = false
	damage_timer.wait_time = 0.5
	damage_timer.autostart = false


func _process(delta: float):
	# Spikes moving UP
	if is_moving_up and position != target_position:
		position = position.move_toward(target_position, spike_move_speed * delta)
		if position == target_position:
			is_moving_up = false
			spikes_extended = true
			print("Spikes fully extended")
	
	# Spikes moving DOWN
	elif not is_moving_up and position != original_position and not is_triggered:
		position = position.move_toward(original_position, spike_move_speed * delta)
		if position == original_position:
			spikes_extended = false
			print("Spikes fully retracted")


# --- Trigger Zone (root Area2D) ---
func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_trigger = true
		if not is_triggered: # only trigger once
			print("Trigger activated by player")
			is_triggered = true
			spike_timer.start()

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_trigger = false
		# when player leaves, start retracting
		retract_timer.start()


# --- Spike animation control ---
func _on_spiketimer_timeout() -> void:
	print("Spikes extending")
	is_moving_up = true
	
	# If player already inside killzone, start damage loop
	if player_in_zone and current_body:
		damage_timer.start()

func _on_retrack_timeout() -> void:
	if not player_in_trigger: # only retract if player left trigger
		print("Retracting")
		is_triggered = false
		is_moving_up = false
		spikes_extended = false
		damage_timer.stop()


# --- Killzone (damage area) ---
func _on_killzone_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_zone = true
		current_body = body
		
		# 🔹 INSTANT damage when touching spikes
		if spikes_extended or is_moving_up:
			if body.has_method("take_damage"):
				body.take_damage(damage_amount)
				print("Player takes INSTANT spike damage!")
			damage_timer.start()
		
		print("Player entered killzone")

func _on_killzone_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_zone = false
		current_body = null
		damage_timer.stop()
		print("Player exited killzone")

func _on_damage_timer_timeout() -> void:
	if player_in_zone and (spikes_extended or is_moving_up) and current_body:
		if current_body.has_method("take_damage"):
			current_body.take_damage(damage_amount)
			print("Player takes CONTINUOUS spike damage!")
