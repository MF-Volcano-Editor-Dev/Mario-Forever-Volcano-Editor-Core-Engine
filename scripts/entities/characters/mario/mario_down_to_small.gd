extends ShapeCast2D

@onready var _powerup: MarioPowerup = get_parent()
@onready var _character: Character = _powerup.get_character()

var _stop_stuck_push: bool


func check_and_push() -> void:
	force_shapecast_update()
	if !get_collision_count():
		return
	
	_character.add_to_group(&"state_immovable")
	
	if _character.is_on_floor():
		while is_colliding() && is_inside_tree():
			_character.global_position += Vector2.LEFT.rotated(_character.global_rotation) * _character.direction
			force_shapecast_update()
			if !_stop_stuck_push:
				await get_tree().physics_frame
			else:
				break
	else:
		while is_colliding():
			_character.global_position -= _character.up_direction
			force_shapecast_update()
	
	_character.remove_from_group(&"state_immovable")

func stop_pushing() -> void:
	_stop_stuck_push = true
	_character.remove_from_group(&"state_immovable")
	
	await get_tree().physics_frame
	
	_stop_stuck_push = false
