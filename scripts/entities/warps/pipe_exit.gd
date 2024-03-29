extends Area2D

@export_category("Pipe Exit")
@export_group("Warp")
## If [code]true[/code], you can preview the effect.
@export var preview: bool
## Direction of warping out
@export_enum("Up", "Down", "Left", "Right") var direction: int
@export_group("Effects")
## If [code]true[/code], then there will be a transmission between the completion of entering the pipe and the beginning of exiting from the pipe.
@export var transmission: bool
@export_group("Sounds", "sound_")
@export var sound_pipe: AudioStream = preload("res://engine/assets/sounds/power_down.wav")

var _on_trans: bool


func _ready() -> void:
	visible = false

## Called by entrance.
## @deprecated
func exit(character: Character) -> void:
	if direction in [0, 1]:
		character.add_to_group(&"state_pipe_v")
	else:
		character.direction = -1 if direction == 2 else 1
		character.add_to_group(&"state_pipe_h")
	
	# Moving the character
	var up := _get_up()
	var start_pos := global_position - 32 * up
	var target_pos := global_position + 16 * up
	var tw := character.create_tween()
	tw.tween_callback(Sound.play_2d.bind(sound_pipe, self))
	tw.tween_method(character.set_global_position, start_pos, target_pos, 1.2)
	
	await get_tree().process_frame
	_exit_effect(character.get_global_transform_with_canvas().get_origin())
	
	await tw.finished
	
	while is_inside_tree() && character in get_overlapping_bodies():
		character.global_position += 50 * get_physics_process_delta_time() * up
		await get_tree().physics_frame
	
	character.z_index += 2
	character.remove_from_group(&"state_pipe_h")
	character.remove_from_group(&"state_pipe_v")
	character.remove_from_group(&"state_frozen")


func _exit_effect(canvas_pos: Vector2) -> void:
	if !transmission:
		return
	if _on_trans: # To avoid multicalls when there are two or more characters
		return
	
	_on_trans = true
	Transmission.circle_transmission(canvas_pos, 0.75, false)
	set_deferred(&"_on_trans", false)


func _get_up() -> Vector2:
	return Vector2.UP.rotated(global_rotation)
