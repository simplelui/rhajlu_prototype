extends Control

# Reference to the small 'Pausing' button in the top-right
# Type: TouchScreenButton
# Path: Corrected based on your hierarchy
@onready var game_pausing_button: TouchScreenButton = $"../Control/Container/Pausing"

# Reference to the Resume button inside its own container under PausePanel
# Type: TouchScreenButton
# Path: Corrected to reflect the new hierarchy
@onready var resume_button: TouchScreenButton = $"PausePanel/Container/Resume"

# Reference to the Menu button inside its own container under PausePanel
# Type: TouchScreenButton
# Path: Corrected to reflect the new hierarchy
@onready var menu_button: TouchScreenButton = $"PausePanel/Container2/Menu"


func _ready():
	# Ensure the entire pause menu is hidden when the game starts
	# This also applies to all its children (PausePanel, Resume, Menu, Label, VBoxContainer)
	hide()
	
	# Connect the small 'Pausing' button to the toggle function
	# This button toggles the pause state and menu visibility
	if is_instance_valid(game_pausing_button): # Check if the node path is valid
		game_pausing_button.pressed.connect(toggle_pause_menu)
		print("Connected 'Pausing' button signal.")
	else:
		print("ERROR: 'Pausing' button not found at path: ", game_pausing_button.get_path())

	# Connect the 'Resume' button inside the pause menu
	if is_instance_valid(resume_button): # Check if the node is valid
		resume_button.pressed.connect(_on_Resume_pressed)
		print("Connected 'Resume' button signal.")
	else:
		print("ERROR: 'Resume' button not found. Ensure its path is correct.")
		
	# Connect the 'Menu' button inside the pause menu
	if is_instance_valid(menu_button): # Check if the node is valid
		menu_button.pressed.connect(_on_Menu_pressed)
		print("Connected 'Menu' button signal.")
	else:
		print("ERROR: 'Menu' button not found. Ensure its path is correct.")


# Function to toggle the pause state and menu visibility
func toggle_pause_menu():
	if get_tree().paused:
		# Game is currently paused, so unpause it
		get_tree().paused = false
		hide() # Hide the entire pause menu
		print("DEBUG: Game Unpaused. Menu Hidden.")
	else:
		# Game is not paused, so pause it
		get_tree().paused = true
		show() # Show the entire pause menu
		print("DEBUG: Game Paused. Menu Shown.")


# Function called when the 'Resume' button is pressed
func _on_Resume_pressed():
	print("DEBUG: 'Resume' button pressed. Attempting to unpause.")
	toggle_pause_menu() # Call the toggle function to unpause and hide


# Function called when the 'Menu' button is pressed
func _on_Menu_pressed():
	print("DEBUG: 'Menu' button pressed. Going to main menu.")
	get_tree().paused = false # Always unpause before changing scenes
	# IMPORTANT: Replace "res://scenes/MainMenu.tscn" with the actual path to your main menu scene file!
	get_tree().change_scene_to_file("res://scenes/start/main_menu.tscn")

# Removed redundant _on_menu_pressed() and _on_resume_pressed() functions that had 'pass'.
# The connections are handled by the _ready() function to the correct functions above.
