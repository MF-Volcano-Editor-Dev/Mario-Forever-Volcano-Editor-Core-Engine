extends Node

## Entrance scene to make the game run as expected
@export var start_scene: PackedScene = preload("res://engine/scenes/templates/level.tscn")


func _enter_tree() -> void:
	if start_scene:
		get_tree().change_scene_to_packed(start_scene)
	else:
		OS.alert("The entrance scene is empty. The game cannot run as expected!", "Error!")
		get_tree().quit(1)
