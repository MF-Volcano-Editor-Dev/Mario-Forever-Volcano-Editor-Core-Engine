extends CharacterBody2D

@export_category("Piranha")
@export_group("Shoot", "shooting_")
@export_range(0, 60, 0.001, "suffix:s") var shooting_total_interval: float = 2
@export var shooting_random: bool = true
@export_range(0, 180, 0.001, "degrees") var shooting_central_angle: float = 75
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var shooting_speed_min: float = 320
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var shooting_speed_max: float = 585
@export_range(0, 20, 0.001) var shooting_amount: int = 3
@export_range(0, 60, 0.001, "suffix:s") var shooting_interval: float = 0.2
@export_group("References")
@export_node_path("Instantiater2D") var shooter_path: NodePath
@export_node_path("VisibleOnScreenEnabler2D") var vision_enabler: NodePath = ^"VisibleOnScreenEnabler2D"
@export_node_path("Timer") var timer_shoot_path: NodePath = ^"TimerShoot"
@export_group("Sounds", "sound_")
@export var sound_shooting: AudioStream = preload("res://engine/assets/sounds/shoot.wav")

@onready var _shooter: Instantiater2D = get_node_or_null(shooter_path)
@onready var _vision_enabler: VisibleOnScreenEnabler2D = get_node(vision_enabler)
@onready var _timer_shoot: Timer = get_node(timer_shoot_path)


func _ready() -> void:
	_timer_shoot.start(shooting_total_interval)
	_timer_shoot.timeout.connect(_shoot)


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
