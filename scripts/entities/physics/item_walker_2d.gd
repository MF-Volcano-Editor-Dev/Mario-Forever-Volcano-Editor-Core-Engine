class_name ItemWalker2D extends Walker2D

## A [Walker2D] for items hit from [BumpBlock2D].
##
##

signal rose ## Emitted when the item completes rising.
signal started_movement ## Emitted when the movement starts.

## Speed of rising
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var rising_speed: float = 25
## Delay between the completion of rising and the beginning of movement
@export_range(0, 10, 0.001, "suffix:s") var start_movement_delay: float
@export_group("Physics")
## Jumping speed
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var jumping_speed: float
@export_group("References")
## Path to the effect box that may contain the collision behavior of the item.
@export_node_path("Area2D") var effect_box_path: NodePath
@export_group("Sounds", "sound_")
@export var sound_hit: AudioStream = preload("res://engine/assets/sounds/appear.wav")
@export var sound_jumping: AudioStream

var _rising_dir: int


func _physics_process(delta: float) -> void:
	if _rising_dir:
		var del := rising_speed * _rising_dir * delta
		move_local_y(del, false)
		# Restore behaviors
		if !test_move(global_transform, Vector2.ZERO, null, 0):
			rose.emit()
			set_physics_process(false)
			
			await get_tree().create_timer(start_movement_delay, false).timeout
			
			set_physics_process(true)
			_rising_dir = 0
			initialize_direction.call_deferred()
			
			var effect_box: Area2D = get_node_or_null(effect_box_path) as Area2D
			if effect_box:
				for i in effect_box.get_shape_owners():
					effect_box.shape_owner_set_disabled.call_deferred(i, false)
			
			started_movement.emit()
	else:
		super(delta)


## Makes the item jump
func item_jump(with_sound: bool = false) -> void:
	if with_sound:
		Sound.play_2d(sound_jumping, self)
	jump(jumping_speed)


## Called by [BumpBlock2D].
## @deprecated
func hit(block: BumpBlock2D) -> void:
	Sound.play_2d(sound_hit, self)
	
	var effect_box: Area2D = get_node_or_null(effect_box_path) as Area2D
	if effect_box:
		for i in effect_box.get_shape_owners():
			effect_box.shape_owner_set_disabled(i, true)
	
	_rising_dir = -1 if block.get_dot_to_up() > cos(deg_to_rad(block.tolerance)) else 1
