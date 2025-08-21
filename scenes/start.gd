extends Control


func _on_start_pressed() -> void:
	# Corrected: Change this path to your actual game level scene!
	# Based on previous discussions, this is likely main_character.tscn
	get_tree().change_scene_to_file("res://scenes/start/main_menu.tscn")
	print("DEBUG: Start button WAS PRESSED! Changing scene to game level.")

func _on_exit_pressed() -> void:
	print("DEBUG: Exit button WAS PRESSED! Quitting game.")
	get_tree().quit()	
