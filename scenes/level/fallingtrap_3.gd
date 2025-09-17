extends Node2D

@export var speed: float = 1000.0
@export var direction: Vector2 = Vector2.RIGHT  # Default fall direction
@export var reset_delay: float = 1           # Time before it pops back
@export var impact_damage: int = 2             # Damage applied on collision

var current_speed: float = 0.0
var original_position: Vector2

@onready var reset_timer: Timer = $ResetTimer

func _ready() -> void:
	original_position = position
	reset_timer.one_shot = true
	reset_timer.wait_time = reset_delay


func _physics_process(delta: float) -> void:
	if current_speed != 0:
		position += direction.normalized() * current_speed * delta


# Player enters detection zone → start moving
func _on_detection_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		print("Player entered detection → Trap moving")
		activate()


# Player hits the trap → instant damage only
func _on_hitbox_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		print("Hitbox collided with Player")
		if body.has_method("take_damage"):
			body.take_damage(impact_damage)
			print("Player takes instant damage:", impact_damage)
	
	# Start reset countdown
	reset_timer.start()


func activate() -> void:
	current_speed = speed


func _on_reset_timer_timeout() -> void:
	print("Trap reset (pop out)")
	position = original_position
	current_speed = 0
