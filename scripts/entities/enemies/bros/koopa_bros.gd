extends Walker2D

signal jump_up_finished ## Emitted when the bro starts falling during jumping up.
signal jump_down_finished ## Emitted when the bro falls below specific height during jumping down.

enum JumpingMode {
	NONE,
	UP_AND_DOWN,
	UP,
	DOWN
}

@export_category("Koopa Bros")
@export_group("References")
@export_node_path("AnimationPlayer") var animation_path: NodePath = ^"AnimationPlayer"
@export_node_path("Instantiater2D") var thrower_path: NodePath = ^"Thrower"
@export_node_path("Timer") var timer_walk_path = ^"TimerWalk"
@export_node_path("Timer") var timer_jump_path = ^"TimerJump"
@export_node_path("Timer") var timer_attack_path = ^"TimerAttack"
@export_group("Physics")
@export_subgroup("Walking")
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px") var moving_radius: float = 32
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px") var moving_radius_extra: float = 32
@export_range(0, 20, 0.001, "suffix:s") var stop_duration: float = 0.2
@export_range(0, 20, 0.001, "suffix:s") var stop_duration_extra: float = 1.8
@export_subgroup("Jumping")
@export_range(-1, 30, 0.001, "suffix:s") var jumping_interval: float = 1
@export_range(-1, 30, 0.001, "suffix:s") var jumping_interval_extra: float = 4
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var jumping_up_speed: float = 400
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var jumping_down_speed: float = 150
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px") var jumping_down_height: float = 80
@export_group("Attack")
@export_range(0, 60, 0.001, "suffix:s") var attacking_time: float = 0.1
@export_range(0, 60, 0.001, "suffix:s") var attacking_time_extra: float = 2.4
@export_range(0, 60, 0.001, "suffix:s") var attacking_preparation_time: float = 0.6
@export_range(0, 10, 0.001, "suffix:s") var attacking_interval: float = 0.1
@export_range(0, 20) var attacking_amount: int = 1
@export_subgroup("Random")
@export var attack_random: bool = true
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var throwing_speed: float = 304
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var throwing_speed_extra: float = 205
@export_range(0, 90, 0.001, "degrees") var throwing_angle_min: float = 63.4
@export_range(0, 90, 0.001, "degrees") var throwing_angle_max: float = 80.5
@export_group("Sounds", "sound_")
@export var sound_attack: AudioStream = preload("res://engine/assets/sounds/throw.wav")

## Implemented by jumping controller
## @deprecated
var jumping_mode: JumpingMode
var _jumping_below: Vector2
var _jumping_result: bool
var _is_jumping: bool
var _is_attacking: bool

var _step: int:
	set = set_step
var _walking_speed: float
var _previous_rand_radius: float

@onready var _animation: AnimationPlayer = get_node(animation_path)
@onready var _thrower: Instantiater2D = get_node(thrower_path)
@onready var _timer_walk: Timer = get_node(timer_walk_path)
@onready var _timer_jump: Timer = get_node(timer_jump_path)
@onready var _timer_attack: Timer = get_node(timer_attack_path)


func _ready() -> void:
	initial_direction = InitDirection.LOOK_AT_PLAYER
	initialize_direction()
	_step = 0
	
	# Jump
	_time(_timer_jump, _get_rand(jumping_interval, jumping_interval_extra)).connect(_on_jump)
	_time(_timer_attack, _get_rand(attacking_time, attacking_time_extra)).connect(_on_attack)

func _physics_process(_delta: float) -> void:
	calculate_gravity()
	calculate_damp()
	
	move_and_slide()
	
	# Restore collision during jumping
	if _is_jumping:
		if _jumping_result && is_falling():
			jump_up_finished.emit()
			_is_jumping = false
		elif !_jumping_result && global_position.direction_to(_jumping_below).dot(up_direction) > 0:
			jump_down_finished.emit()
			_is_jumping = false
			_jumping_below = Vector2.ZERO
	
	# Animation & Auto-detected directions
	var np := Character.Getter.get_nearest(get_tree(), global_position) # Nearest player
	if !np:
		return
	var dir := Transform2DAlgo.get_direction_to_regardless_transform(global_position, np.global_position, global_transform)
	if _is_attacking:
		if !_animation.has_animation(&"attack_l") && !_animation.has_animation(&"attack_r"):
			_animation.play(&"attack")
		else:
			_animation.play(&"attack_l" if dir < 0 else &"attack_r")
	
	set_meta(&"facing", dir) # Useful for sprite_flip_facing_h.gd


func set_step(value: int) -> void:
	_step = value
	
	match _step:
		0: # Initial
			await _time(_timer_walk, _get_walking_time(moving_radius + moving_radius_extra))
			
			_walking_speed = velocality.x
			velocality.x = 0
			
			# Stop and wait for back
			await _time(_timer_walk, _get_rand(stop_duration + stop_duration_extra))
			await get_tree().physics_frame # To avoid track leak
			
			set_step(1) # To trigger this call
		1: # Go backward
			velocality.x = -_walking_speed
			_previous_rand_radius = _get_rand(moving_radius, moving_radius_extra)
			
			await _time(_timer_walk, _get_walking_time(moving_radius + moving_radius_extra + _previous_rand_radius))
			
			_walking_speed = velocality.x
			velocality.x = 0
			
			# Stop and wait for going forward
			await _time(_timer_walk, _get_rand(stop_duration, stop_duration_extra))
			await get_tree().physics_frame
			
			set_step(2)
		2: # Walk as ususal
			velocality.x = -_walking_speed
			
			var temp_rand_radius := _get_rand(moving_radius, moving_radius_extra)
			
			await _time(_timer_walk, _get_walking_time(_previous_rand_radius + temp_rand_radius))
			
			_previous_rand_radius = temp_rand_radius
			_walking_speed = velocality.x
			velocality.x = 0
			
			# Stop and wait for going forward
			await _time(_timer_walk, _get_rand(stop_duration, stop_duration_extra))
			await get_tree().physics_frame
			
			set_step(2)

func _on_jump() -> void:
	if is_on_floor() && jumping_mode != JumpingMode.NONE:
		var cm := collision_mask
		match jumping_mode: # Decides which result
			JumpingMode.UP_AND_DOWN: # Both are possible
				_jumping_result = [true, false].pick_random()
			JumpingMode.UP: # Only jumping up
				_jumping_result = true
			JumpingMode.DOWN: # Only jumping down
				_jumping_result = false
		if _jumping_result: # Jumping up
			_is_jumping = true
			collision_mask = 0
			
			jump(jumping_up_speed)
			
			await jump_up_finished
		else: # Jumping down
			_jumping_below = global_position - jumping_down_height * up_direction.rotated(get_gravity_rotation_angle())
			_is_jumping = true
			collision_mask = 0
			
			jump(jumping_down_speed)
			
			await jump_down_finished
		
		collision_mask = cm
	
	_timer_jump.start(_get_rand(jumping_interval, jumping_interval_extra))

func _on_attack() -> void:
	_is_attacking = true
	
	await _await_tree_time(attacking_preparation_time)
	
	# Throw objects
	for i in attacking_amount:
		var insdir: int = get_meta(&"facing", 1)
		if insdir == 0:
			insdir = [-1, 1].pick_random()
		
		var instances: Array[CanvasItem] = _thrower.instantiate_all()
		
		Sound.play_2d(sound_attack, self)
		
		for j in instances:
			if j is EntityBody2D:
				if attack_random:
					var vel := Vector2.RIGHT.rotated(deg_to_rad(-randf_range(throwing_angle_min, throwing_angle_max))) * _get_rand(throwing_speed, throwing_speed_extra)
					vel.x *= insdir
					j.velocality = vel
				else:
					j.velocality.x = absf(j.velocality.x) * insdir
		
		if attacking_amount > 1:
			await _await_tree_time(attacking_interval)
	
	_animation.play(&"RESET")
	_is_attacking = false
	
	_timer_attack.start(_get_rand(attacking_time, attacking_time_extra))


func _get_walking_time(radius: float) -> float:
	return radius / absf(velocality.x)

func _get_rand(base: float, extra: float = 0) -> float:
	return randf_range(absf(base), absf(base) + randf_range(0, absf(extra)))

func _time(timer: Timer, seconds: float) -> Signal:
	timer.start(seconds)
	return timer.timeout

func _await_tree_time(seconds: float, physics: bool = true) -> Signal:
	return get_tree().create_timer(seconds, false, physics).timeout
