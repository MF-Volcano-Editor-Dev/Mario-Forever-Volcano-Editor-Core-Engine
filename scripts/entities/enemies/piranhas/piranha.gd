extends CharacterBody2D

signal piranha_stretched_out ## Emitted when the piranha stretches out of the pipe.
signal piranha_shrank_in ## Emitted when the piranha shrinks in the pipe.

@export_category("Piranha")
@export var out_of_pipe_initially: bool = true
@export_range(0, 1024, 0.001, "or_greater", "suffix:px") var stretch_length: float = 48
@export_group("Physics")
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var stretch_speed: float = 50
@export_range(0, 512, 0.001, "suffix:px/s") var stop_stretching_margin: float = 80
@export_range(0, 60, 0.001, "suffix:s") var rest_duration: float = 1
@export_group("Shoot", "shooting_")
@export var shooting_random: bool = true
@export_range(0, 180, 0.001, "degrees") var shooting_central_angle: float = 75
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var shooting_speed_min: float = 320
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var shooting_speed_max: float = 585
@export_range(0, 20, 0.001) var shooting_amount: int = 3
@export_range(0, 60, 0.001, "suffix:s") var shooting_interval: float = 0.2
@export_group("References")
@export_node_path("Instantiater2D") var shooter_path: NodePath
@export_node_path("VisibleOnScreenEnabler2D") var vision_enabler: NodePath = ^"VisibleOnScreenEnabler2D"
@export_group("Sounds", "sound_")
@export var sound_shooting: AudioStream = preload("res://engine/assets/sounds/shoot.wav")

var _tween: Tween
var _step: int:  # 0: Initialization; 1: Out; 2: Wait for shrinking in; 3: In; 4: Wait for stretching out
	set(value):
		_step = value
		
		if !is_node_ready():
			await ready
		
		if is_inside_tree(): # To prevent from calling on a freed object
			_steps()
var _in_range: bool

@onready var _shooter: Instantiater2D = get_node_or_null(shooter_path)
@onready var _vision_enabler: VisibleOnScreenEnabler2D = get_node(vision_enabler)


func _ready() -> void:
	if !out_of_pipe_initially:
		_step = 3
	else:
		_step = 0 # Triggers setter to fresh the vision enabler
		move_local_y(stretch_length)

func _process(_delta: float) -> void:
	var np: Character = Character.Getter.get_nearest(get_tree(), global_position)
	if !np:
		return
	
	var trans := global_transform.affine_inverse()
	var nptx := trans.basis_xform(np.global_position).x # Nearest character position x (transformed)
	var tx := trans.basis_xform(global_position).x # Transformed position x
	
	_in_range = nptx > tx - stop_stretching_margin && nptx < tx + stop_stretching_margin

func _steps() -> void:
	var t := stretch_length / stretch_speed # Duration
	var btm := stretch_length * Vector2.DOWN.rotated(rotation) # Bottom
	
	match _step:
		0: # Initialization
			await get_tree().create_timer(0.2, false).timeout
			while is_inside_tree() && !_vision_enabler.is_on_screen():
				await get_tree().process_frame
			_step = 1
		1, 3: # Stretching, Shrinking
			var tg := position - btm if _step == 1 else position + btm
			
			_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			_tween.tween_property(self, ^"position", tg, t)
			await _tween.finished
			
			if _step == 1: # Shooting
				_shoot()
			
			_step = 2 if _step == 1 else 4
			
			(piranha_stretched_out if _step == 1 else piranha_shrank_in).emit()
		2, 4: # Waiting outside, waiting inside
			await get_tree().create_timer(rest_duration, false).timeout
			if _step == 2:
				_step = 3
			else:
				while is_inside_tree() && (_in_range || !_vision_enabler.is_on_screen()):
					await get_tree().process_frame
				_step = 1


func _shoot() -> void:
	if !_shooter:
		return
		
	for i in shooting_amount:
		var ds := PhysicsServer2D.body_get_direct_state(get_rid()) # Direct state
		if !ds: # Probably the object may get destroyed when it's shot out of the screen
			continue
		
		Sound.play_2d(sound_shooting, self)
		
		if shooting_random:
			var a := deg_to_rad(shooting_central_angle / 2)
			
			var ngdir := -ds.total_gravity.normalized() # Negative gravity direction
			var sts := _shooter.instantiate_all() # Shootees
			
			for j in sts:
				if j is CharacterBody2D:
					var up := Vector2.UP.rotated(global_rotation)
					var vel := up.rotated(randf_range(-a, a)) * randf_range(shooting_speed_min, shooting_speed_max)
					vel *= clampf(cos(up.angle_to(ngdir) / 2), 0.4, 1) # cos(x/2) is a good sample
					j.velocity = vel
		
		await get_tree().create_timer(shooting_interval, false).timeout


func _stop_vision_enabler() -> void:
	_vision_enabler.enable_node_path = ^"."

func _reset_vision_enabler() -> void:
	_vision_enabler.enable_node_path = _vision_enabler.get_path_to(self)
