extends State

## 
##
## If you want to customize the behavior based on this script, please override the related method(s).

const _NonClimbing: Script = preload("./mario_non_climbing.gd")

@export_category("Character Climbing State")
@export_group("References")
@export_node_path("State") var state_non_climbing_path: NodePath
@export_group("Physics")
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var climbing_speed: float = 100

var _dir: Vector2
var _animation_count: float

@onready var _character: Mario = get_root().get_character()
@onready var _state_non_climbing: _NonClimbing = get_node_or_null(state_non_climbing_path)


func _state_entered() -> void:
	_character.velocality = Vector2.ZERO

func _state_exited() -> void:
	if !_state_non_climbing:
		return
	if !_state_non_climbing.animated_sprite:
		return
	_state_non_climbing.animated_sprite.scale.x = _character.direction

func _state_process(delta: float) -> void:
	if _character.is_in_group(&"state_frozen"):
		return
	
	_shape()
	_climb()
	_animation(delta)
	_non_climbing_check()

func _state_physics_process(delta: float) -> void:
	var kc: KinematicCollision2D = _character.move_and_collide(_character.velocity * delta)
	if kc && kc.get_collider():
		_character.velocity = _character.velocity.slide(kc.get_normal())
		# Climbing down onto the ground means going back to non-climbing state
		if kc.get_normal().dot(_character.up_direction) > 0:
			_character.remove_from_group(&"state_climbing")


func _non_climbing_check() -> void:
	if !_character.is_in_group(&"state_climbing"):
		_state_machine.change_state(&"non_climbing")


func _shape() -> void:
	if !_state_non_climbing:
		return
	if _state_non_climbing._shape_controller.current_animation != &"RESET":
		_state_non_climbing._shape_controller.play(&"RESET")

func _climb() -> void:
	if _character.is_in_group(&"state_uncontrollable"):
		return
	
	if !_state_non_climbing:
		return
	_dir = Vector2(_character.get_udlr_directions(&"left", &"right", &"up", &"down"))
	if !_dir.is_zero_approx():
		_dir = _dir.normalized()
		if _dir.x: # Sets the character's direction by pressing left or right
			_character.direction = int(roundf(_dir.x)) 
	_character.velocality = _dir * climbing_speed
	
	# Jump to quit the state of climbing
	if _character.get_input_just_pressed(&"jump"):
		_state_non_climbing._has_jumped = true
		_character.jump(_state_non_climbing.initial_jumping_speed)
		_character.remove_from_group(&"state_climbing")
		Sound.play_2d(_state_non_climbing.sound_jumping, _character)

func _animation(delta: float) -> void:
	if !_state_non_climbing:
		return
	if !_state_non_climbing.animated_sprite:
		return
	
	_state_non_climbing.animated_sprite.speed_scale = 1
	
	if _state_non_climbing.animated_sprite.animation in [&"appear", &"attack"]:
		return
	
	_state_non_climbing.animated_sprite.play(&"climb")
	
	if _dir.is_zero_approx():
		return
	
	_animation_count += delta
	if _animation_count > 0.1: # 10 seconds
		_animation_count = 0
		_state_non_climbing.animated_sprite.scale.x *= -1 # Flips the sprite horizontally
