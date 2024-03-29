@tool
extends AnimatableBody2D

signal launched ## Emitted when something is launched.

@export_category("Flameball Launcher")
@export_enum("Left: -1", "Right: 1") var direction: int = -1:
	set(value):
		var old := direction
		direction = value
		
		if !is_node_ready():
			await ready
		
		_head.flip_h = direction > 0
		_tail.flip_h = _head.flip_h
		if direction != old:
			_head.offset.x = -length_per_gird / 2 if direction < 0 else -length_per_gird / 2 - length
			_shape.position.x *= -1
			_tail.position.x *= -1
			_instantiater.position.x *= -1
@export_group("Length")
@export_range(0, 256, 0.001, "or_greater", "suffix:px") var length: float:
	set = set_length
@export_range(0, 8, 0.001, "or_greater") var girds: float:
	set(value):
		girds = value
		length = girds * length_per_gird
@export_range(0, 128, 0.001, "suffix:px") var length_per_gird: float = 32:
	set(value):
		length_per_gird = value
		length = girds * length_per_gird
@export_range(0, 128, 0.001, "suffix:px") var length_of_head_tail: float = 32:
	set(value):
		length_of_head_tail = value
		length = girds * length_per_gird
@export_group("Shooting")
@export_range(0, 60, 0.001, "suffix:s") var first_shooting_delay: float = 0.3
@export_range(0, 60, 0.001, "suffix:s") var interval: float = 3
@export_range(0, 200) var shooting_times: int = 20
@export_range(1, 9999, 1, "suffix:f") var shooting_interval_frames: int = 6
@export_group("References")
@export_node_path("Timer") var timer_interval_path: NodePath = ^"TimerInterval"
@export_node_path("Instantiater2D") var instantiater_path: NodePath = ^"Instantiater2D"
@export_node_path("Sprite2D") var head_path: NodePath = ^"Head"
@export_node_path("Sprite2D") var tail_path: NodePath = ^"Head/Tail"
@export_node_path("CollisionShape2D") var shape_path: NodePath = ^"CollisionShape2D"
@export_group("Sounds", "sound_")
@export var sound_launching: AudioStream = preload("res://engine/assets/sounds/flameball.ogg")
@export_range(0.01, 5, 0.001, "suffix:s") var sound_launching_interval: float = 0.2

@onready var _timer_interval: Timer = get_node(timer_interval_path)
@onready var _instantiater: Instantiater2D = get_node(instantiater_path)
@onready var _head: Sprite2D = get_node(head_path)
@onready var _tail: Sprite2D = get_node(tail_path)
@onready var _shape: CollisionShape2D = get_node(shape_path)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_timer_interval.start(first_shooting_delay)
	_timer_interval.timeout.connect(_on_launching)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return


func _on_launching() -> void:
	var tw := create_tween().set_loops()
	tw.tween_callback(Sound.play_2d.bind(sound_launching, self))
	tw.tween_interval(sound_launching_interval)
	
	for i in shooting_times:
		var items := _instantiater.instantiate_all()
		for j in items:
			if j is Walker2D:
				j.initial_direction = Walker2D.InitDirection.BY_VELOCITY
				j.velocality.x = direction * absf(j.velocality.x)
				(func() -> void:
					j.get_parent().move_child(j, get_index())
				).call_deferred()
		
		if i < shooting_times - 1:
			for j in shooting_interval_frames:
				await get_tree().physics_frame
	
	tw.kill()
	launched.emit()
	
	_timer_interval.start(interval)


func set_length(value: float) -> void:
	length = value
	
	if !is_node_ready():
		await ready
	 
	_head.region_rect.size.x = length_of_head_tail + length
	_tail.position.x = -direction * _head.region_rect.size.x
	_shape.shape = _shape.shape.duplicate(true) as RectangleShape2D
	_shape.shape.size.x = _head.region_rect.size.x + length_of_head_tail
	_shape.position.x = -direction * (_shape.shape.size.x - length_of_head_tail) / 2 
