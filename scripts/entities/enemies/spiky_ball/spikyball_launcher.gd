extends AnimatableBody2D

signal launched ## Emitted when something is launched.

@export_category("Spikyball Launcher")
@export_range(0, 60, 0.001, "suffix:s") var launching_interval: float = 3
@export_range(0, 150, 0.001, "degrees") var launching_central_angle: float = 74
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var launching_speed: float = 400
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var launching_speed_extra: float = 183
@export_group("Multistep Shooting")
@export_range(0, 20) var shooting_times: int = 1
@export_range(0.01, 30, 0.001, "suffix:s") var shooting_interval: float = 0.25
@export_group("References")
@export_node_path("Instantiater2D") var launcher_path: NodePath = ^"Launcher"
@export_node_path("Timer") var timer_interval_path: NodePath = ^"TimerInterval"
@export_group("Sounds", "sound_")
@export var sound_launching: AudioStream = preload("res://engine/assets/sounds/spikyball.ogg")

@onready var _launcher: Instantiater2D = get_node(launcher_path)
@onready var _timer_interval: Timer = get_node(timer_interval_path)


func _ready() -> void:
	_timer_interval.start(launching_interval)
	_timer_interval.timeout.connect(_on_launching)


func _on_launching() -> void:
	for i in shooting_times:
		Sound.play_2d(sound_launching, self)
		
		var ds := PhysicsServer2D.body_get_direct_state(get_rid()) # Direct state
		if !ds: # Probably the object may get destroyed when it's shot out of the screen
			continue
		
		var items := _launcher.instantiate_all()
		var a := deg_to_rad(launching_central_angle / 2)
		var ngdir := -ds.total_gravity.normalized() # Negative gravity direction
		
		for j in items:
			if j is CharacterBody2D:
				var up := Vector2.UP.rotated(global_rotation)
				var vel := up.rotated(randf_range(-a, a)) * randf_range(launching_speed, launching_speed + launching_speed_extra)
				vel *= clampf(cos(up.angle_to(ngdir) / 2), 0.4, 1) # cos(x/2) is a good sample
				j.velocity = vel
		
		launched.emit()
		
		if i < shooting_times - 1:
			await get_tree().create_timer(shooting_interval, false).timeout
	
	_timer_interval.start(launching_interval)
