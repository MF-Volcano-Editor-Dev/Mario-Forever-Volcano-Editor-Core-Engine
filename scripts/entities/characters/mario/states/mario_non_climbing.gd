extends State

## 
##
## If you want to customize the behavior based on this script, please override the related method(s).

signal stand_up ## Emitted when the character stops from crouching.
signal crouch ## Emitted when the character crouches.

@export_category("Character Non-climbing State")
@export_group("Physics")
@export_subgroup("Walking")
## Initial walking speed.
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var initial_speed: float = 50
## Acceleration.
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s²") var acceleration: float = 312.5
## Deceleration.
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s²") var deceleration: float = 312.5
## Deceleration scale when crouching.
@export_range(0, 5, 0.001, "hide_slider", "suffix:x") var deceleration_scale_crouch: float = 2
## Deceleration on turning back.
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s²") var walking_turning_deceleration: float = 1250
## Max walking speed.
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var max_walking_speed: float = 175
## Max running speed.[br]
## [br]
## [b]Note:[/b] If the character is underwater, this is equal to [member max_walking_speed]
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var max_running_speed: float = 350
@export_subgroup("Jumping")
## Initial jumping speed.
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var initial_jumping_speed: float = 700
## Jumping acceleration when walking speed is lower than 10.
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s²") var jumping_acceleration_static: float = 1000
## Jumping acceleration when walking speed is greater than or equal to 10.
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s²") var jumping_acceleration_dynamic: float = 1250
@export_subgroup("Swimming", "swimming_")
## Swimming strength, the speed when, underwater, the jumping key is pressed.
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var swimming_strength: float = 150
## Swimming strength when the character is about to jump out of the water surface.
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var swimming_strength_jumping_out: float = 450
## Max speed of swimming up.
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var swimming_up_max_speed: float = 150
@export_group("Sounds", "sound_")
@export var sound_jumping: AudioStream = preload("res://engine/assets/sounds/jump.wav")
@export var sound_swimming: AudioStream = preload("res://engine/assets/sounds/swim.wav")

var _has_jumped: bool

@onready var _powerup: MarioPowerup = get_root()
@onready var _animated_sprite: AnimatedSprite2D = _powerup.get_animated_sprite()
@onready var _shape_controller: AnimationPlayer = _powerup.get_shape_controller()
@onready var _character: Mario = _powerup.get_character()


func _ready() -> void:
	if _animated_sprite:
		_animated_sprite.animation_finished.connect(_on_animation_finished)
		_animated_sprite.animation_looped.connect(_on_animation_looped)

func _state_process(delta: float) -> void:
	if !_character.is_in_group(&"state_frozen"):
		_crouch() # Should be executed before all the following methods to make sure the following ones can be executed as expected
		_walk()
		_jump(delta)
		_swim(delta)
		_climbing_check()
	
	_animation.call_deferred(delta) # Called at the end of a frame to make sure the animation will be correctly played if the character is walking against a wall

func _state_physics_process(_delta: float) -> void:
	if _character.is_in_group(&"state_frozen"):
		return
	
	if !_character.is_in_group(&"state_immovable"):
		_character.calculate_gravity()
		_character.move_and_slide()
		_character.correct_onto_floor()
		_character.correct_on_wall_corner()


func _climbing_check() -> void:
	if !_character.is_in_group(&"state_climbable"):
		return
	if !_character.get_input_just_pressed(&"up"):
		return
	_character.add_to_group(&"state_climbing")
	_state_machine.change_state(&"climbing")

#region == Movement ==
func _crouch() -> void:
	if !_powerup:
		return
	if _character.is_in_group(&"state_completed"):
		return
	
	# Detection for crouching
	var small_crhable: bool = ProjectSettings.get_setting("game/control/player/crouchable_in_small_suit", false)
	if _character.is_on_floor() && \
		_character.get_input_pressed(&"down") && \
		(!_powerup.features.is_small || \
		(_powerup.features.is_small && small_crhable)):
			_character.add_to_group(&"state_crouching")
	else:
		_character.remove_from_group(&"state_crouching")
	
	if _character.is_in_group(&"state_completed"):
		_character.remove_from_group(&"state_crouching")
	
	# Updates shapes to one in crouching state
	if _shape_controller:
		if _character.is_in_group(&"state_crouching") && _shape_controller.current_animation != &"CROUCH":
			_shape_controller.play(&"CROUCH")
			_powerup.set_shapes_for_character()
			crouch.emit()
		elif !_character.is_in_group(&"state_crouching") && _shape_controller.current_animation != &"RESET":
			_shape_controller.play(&"RESET")
			_powerup.set_shapes_for_character()
			stand_up.emit()

func _walk() -> void:
	var lr: int = _character.get_udlr_directions(&"left", &"right", &"up", &"down").x # Acceleration
	var crh: bool = _character.is_in_group(&"state_crouching") # Crouching
	var crh_walkable: bool = ProjectSettings.get_setting("game/control/player/walkable_when_crouching", false) # Crouch-walkable
	if _character.is_in_group(&"state_completed") || (!crh_walkable && crh):
		lr = 0 # If the character has completed the level, then the input will be interfered
	# Deceleration
	if !lr:
		if !is_zero_approx(_character.velocality.x):
			var dc: float = deceleration * (deceleration_scale_crouch if crh else 1.0) # Deceleration
			_character.decelerate_with_friction(dc)
		return
	# Initial walking speed
	elif is_zero_approx(_character.velocality.x):
		_character.direction = lr
		_character.velocality.x = _character.direction * initial_speed
	# Walking and running
	if lr == _character.direction:
		if _character.get_input_pressed(&"run") && !crh: # Crouching-walking should not be applied to running
			_character.add_to_group(&"state_running")
		else:
			_character.remove_from_group(&"state_running")
		var max_spd: float = max_running_speed if _character.is_in_group(&"state_running") && !_character.is_in_group(&"state_swimming") else max_walking_speed if !crh else max_walking_speed * 0.2
		_character.accelerate_local_x(acceleration, max_spd * _character.direction)
	# Turning back
	elif lr == -_character.direction:
		_character.add_to_group(&"state_turning_back")
		_character.decelerate_with_friction(walking_turning_deceleration)
		if is_zero_approx(_character.velocality.x):
			_character.direction *= -1
			_character.remove_from_group(&"state_turning_back")

func _jump(delta: float) -> void:
	if _character.is_in_group(&"state_completed"):
		return
	if _character.is_in_group(&"state_swimming"):
		return
	if _character.is_in_group(&"state_crouching") && !ProjectSettings.get_setting("game/control/player/jumpable_when_crouching", false):
		return
	
	# Resets _has_jumped
	var pj: bool = _character.get_input_just_pressed(&"jump") # Pressing jump
	var hj: bool = _character.get_input_pressed(&"jump") # Holding jump
	if _has_jumped && \
		(_character.is_falling() && pj) || \
		(_character.is_on_floor() && !hj):
			_has_jumped = false
	# Jumping
	if !_has_jumped && _character.is_on_floor() && hj: # `hold_jump` detects more precise than `press_jump` here
		_has_jumped = true
		_character.jump(initial_jumping_speed)
		Sound.play_2d(sound_jumping, _character)
	# Accelerates jumping
	if !_character.is_on_floor() && _character.is_leaving_ground() && hj:
		_character.jump((jumping_acceleration_dynamic if absf(_character.velocality.x) >= 10 else jumping_acceleration_static) * delta, true)

func _swim(delta: float) -> void:
	if _character.is_in_group(&"state_completed"):
		_character.remove_from_group(&"state_swimming")
		return
	if !_character.is_in_group(&"state_swimming"):
		return
	
	if _character.get_input_just_pressed(&"jump"):
		var swspd: float = swimming_strength if !_character.is_in_group(&"state_swimming_to_jumping") else swimming_strength_jumping_out
		_character.jump(swspd)
		
		if _animated_sprite.animation == &"swim":
			_animated_sprite.frame = 0 # Resets animation frame
		
		Sound.play_2d(sound_swimming, _character)
	
	var max_swspd: float = -absf(swimming_up_max_speed) # Max swimming speed
	if !_character.is_in_group(&"state_swimming_to_jumping") && _character.velocality.y < max_swspd:
		_character.velocality.y = lerpf(_character.velocality.y, max_swspd, 16 * delta)
#endregion

#region == Animations ==
func _animation(delta: float) -> void:
	if !_animated_sprite:
		return
	
	_animated_sprite.speed_scale = 1
	_animated_sprite.flip_h = _character.direction < 0 # Facing
	
	if _character.is_in_group(&"state_pipe_h"):
		_animated_sprite.play(&"walk")
		_animated_sprite.speed_scale = 2
		return
	if _character.is_in_group(&"state_pipe_v"):
		_animated_sprite.play(&"pipe")
		return
	
	if _animated_sprite.animation in [&"appear", &"attack"]:
		return
	
	if _character.is_on_floor():
		if _character.is_in_group(&"state_crouching"):
			_animated_sprite.play(&"crouch")
		else:
			var real_vel: Vector2 = _character.velocity
			if !real_vel.slide(_character.get_floor_normal()).is_zero_approx() && !_character.is_on_wall():
				_animated_sprite.play(&"walk")
				_animated_sprite.speed_scale = clampf(absf(_character.velocality.x) * delta * (1 / get_physics_process_delta_time() / 50) * 4, 0, 5)
			else:
				_animated_sprite.play(&"default")
	elif _character.is_in_group(&"state_swimming"):
		_animated_sprite.play(&"swim")
	elif _character.is_falling():
		_animated_sprite.play(&"fall")
	else:
		_animated_sprite.play(&"jump")

func _on_animation_looped() -> void:
	if _animated_sprite.animation == &"swim":
		_animated_sprite.frame = _animated_sprite.sprite_frames.get_frame_count(_animated_sprite.animation) - 2

func _on_animation_finished() -> void:
	if _animated_sprite.animation == &"attack":
		_animated_sprite.play(&"default")
#endregion
