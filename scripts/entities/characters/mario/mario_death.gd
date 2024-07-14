extends Node2D

@export_category("Mario Death")
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var initial_speed: float = 600
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:x") var gravity_scale: float = 0.5
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var max_falling_speed: float = 500
@export_range(-18000, 18000, 0.001, "suffix:°/s") var rotation_speed: float = 250

var _gravity: Vector2
var _velocity: Vector2
var _rot_dir: float # Rotating direction

var sound_death: AudioStream ## [i]Passed by [method Mario.die][/i]

@onready var _character: Mario = get_parent()
@onready var _sprite: Sprite2D = $Sprite2D


func _process(delta: float) -> void:
	_velocity += _gravity * gravity_scale * ProjectSettings.get_setting("physics/2d/default_gravity", 980.0) * delta
	if _velocity.dot(_gravity) > 0 && _velocity.project(_gravity).length_squared() > max_falling_speed ** 2:
		_velocity = _velocity - _velocity.project(_gravity) + _gravity * max_falling_speed
	
	global_position += _velocity * delta
	
	## Rotate
	_sprite.rotate(deg_to_rad(rotation_speed * _rot_dir * delta))


## [i]Called by [method Mario.die].[/i][br]
## Activates the death effect.[br]
## [br]
## [b]Note[/b] Since the moment the call get triggered, the character will be deleted from the RAM, the notification to [Events] in terms of "current game over", which should be triggered after the death effect finishes its process as an effect, should be sent by this object.[br]
## See [Events.EventCharacter] for more details.
func death_effect_start() -> void:
	if _character:
		_gravity = _character.get_gravity_vector().normalized()
		
		Events.EventCharacter.notify_character_death(get_tree(), _character.id)
	
	var sound: AudioStreamPlayer = Sound.play_1d(sound_death, _character)
	var death_canvas_pos := get_global_transform_with_canvas().get_origin()
	
	set_process(false)
	await get_tree().create_timer(0.5, false).timeout
	set_process(true)
	
	_rot_dir = [-1.0, 1.0].pick_random()
	_velocity = Vector2.UP.rotated(global_rotation) * initial_speed
	
	# Transmission
	var tree: SceneTree = get_tree()
	get_tree().create_timer(2, false, false, true).timeout.connect(func() -> void:
		if !Character.Getter.get_characters(tree).is_empty():
			return
		if Character.Data.lives > 0: # Only lives greater than 0 can trigger circular transmission
			Transmission.circle_transmission(death_canvas_pos)
	)
	
	await sound.finished
	await get_tree().create_timer(1, false).timeout
	
	# After-death executions
	remove_from_group(&"character_death")
	if tree.get_nodes_in_group(&"character_death").is_empty(): # Prevent from quick restart when there are two or more characters who die in different time
		Events.EventCharacter.current_game_over(tree)
	
	queue_free()
