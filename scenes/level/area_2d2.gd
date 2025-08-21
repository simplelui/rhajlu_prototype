extends Area2D # This script *must* be attached to an Area2D node

func _on_body_entered(body: Node2D) -> void:
	# Debug print to see what kind of body entered the Area2D.
	print("Body entered spike Area2D: ", body.name, " (Type: ", body.get_class(), ")")

	# Check if the 'body' that entered is an instance of CharacterBody2D.
	if body is CharacterBody2D:
		print("  -> Detected CharacterBody2D. Attempting to call 'take_damage()' method.")
		# Safely check if the detected body (your player) has a 'take_damage' method.
		if body.has_method("take_damage"):
			body.take_damage() # Call the take_damage() method on the player character.
			print("  -> Player 'take_damage()' method found and called successfully!")
		else:
			print("  -> ERROR: CharacterBody2D detected but does NOT have a 'take_damage' method!")
	else:
		print("  -> Entered body is NOT a CharacterBody2D. Ignoring.")
