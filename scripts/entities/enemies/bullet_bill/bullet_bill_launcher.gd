extends AnimatableBody2D

signal launched ## Emitted when something is launched.

@export_category("Bullet Launcher")
@export_range(0, 256, 0.001, "suffix:px") var stop_launching_margin: float = 80
@export_range(0, 60, 0.001, "suffix:s") var first_launch_delay: float = 0.5
@export_range(0, 60, 0.001, "suffix:s") var interval: float = 1.5
@export_range(0, 60, 0.001, "suffix:s") var interval_extra: float = 3
@export_group("Multistep Shooting")
@export_range(0, 20) var shooting_times: int = 1
@export_range(0.01, 30, 0.001, "suffix:s") var shooting_interval: float = 0.25
@export_group("References")
@export_node_path("Timer") var timer_interval_path: NodePath = ^"TimerInterval"
@export_node_path("Instantiater2D") var instantiater_path: NodePath = ^"Instantiater2D"
@export_group("Sounds", "sound_")
@export var sound_launching: AudioStream = preload("res://engine/assets/sounds/bullet.ogg")

var _dir: int = 1:
	set(value):
		_dir = value
		if _dir == 0:
			_dir = [-1, 1].pick_random()
var _nearest_character: Character

@onready var _timer_interval: Timer = get_node(timer_interval_path)
@onready var _instantiater: Instantiater2D = get_node(instantiater_path)


func _ready() -> void:
	_timer_interval.start(first_launch_delay)
	_timer_interval.timeout.connect(_on_launching)

func _process(_delta: float) -> void:
	_nearest_character = Character.Getter.get_nearest(get_tree(), global_position)
	if _nearest_character:
		var trans := global_transform.affine_inverse()
		var nptposx := trans.basis_xform(_nearest_character.global_position).x
		var tposx := trans.basis_xform(global_position).x
		
		_timer_interval.paused = nptposx > tposx - stop_launching_margin && nptposx < tposx + stop_launching_margin


func _on_launching() -> void:
	if _nearest_character:
		_dir = Transform2DAlgo.get_direction_to_regardless_transform(global_position, _nearest_character.global_position, global_transform)
	
	for i in shooting_times:
		Sound.play_2d(sound_launching, self)
		
		_instantiater.position.x = absf(_instantiater.position.x) * _dir
		
		var items := _instantiater.instantiate_all()
		for j in items:
			if j is Walker2D:
				j.initial_direction = Walker2D.InitDirection.BY_VELOCITY
				j.velocality.x = _dir * absf(j.velocality.x)
		
		launched.emit()
		
		if i < shooting_times - 1:
			await get_tree().create_timer(shooting_interval, false).timeout
	
	_timer_interval.start(randf_range(interval, interval + interval_extra))
