class_name GameRoom2D extends Node2D

## Abstract class for all 2D game rooms (large scenes).
##
##

func _ready() -> void:
	await get_tree().process_frame
	
	var trans_spot_start := get_viewport_rect().get_center()
	
	var tree := get_tree()
	var characters: Array[Character] = Character.Getter.get_characters(tree)
	if !characters.is_empty():
		trans_spot_start = Character.Getter.get_average_canvas_position(tree, get_viewport_rect().get_center())
	
	Transmission.circle_transmission(trans_spot_start, 0.5, false)
