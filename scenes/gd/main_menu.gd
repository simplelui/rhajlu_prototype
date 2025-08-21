extends Node

func _on_casual_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level/level 1.tscn")

func _on_hardcore_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level/level 1.tscn")
	
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start/start.tscn")
