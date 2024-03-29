@tool
class_name GeneratorArea2D extends Area2D

## When [Character] enters in this area, specific objects will be generated in certain field
##
##

signal generated ## Emitted when an object is generated.

## Rectangle area in which an object will be created.
@export var generation_margin: Rect2 = Rect2(672, 0, 32, 480)
## The amount of objects in one generation process
@export_range(1, 999) var generating_amount: int = 1
## Extra amount of [member generating_amount], which leads to randomness on the amount of the object.
@export_range(0, 999) var generating_amount_extra: int = 0
## Base interval of generating an object.
@export_range(0, 20, 0.001, "suffix:s") var generating_interval: float = 2
## Extra interval of [member generating_interval], which causes randomness on the generation interval.
@export_range(0, 20, 0.001, "suffix:s") var generating_interval_extra: float = 1
@export_group("References")
@export var instantiater_path: NodePath = ^"Instantiater2D"
@export var timer_interval_path: NodePath = ^"TimerInterval"
@export_group("Sounds", "sound_")
@export var sound_generating: AudioStream

@onready var _instantiater: Instantiater2D = get_node(instantiater_path)
@onready var _timer_interval: Timer = get_node(timer_interval_path)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	body_entered.connect(func(body: Node2D) -> void:
		if !body is Character:
			return
		if _timer_interval.is_stopped():
			_timer_interval.start(generating_interval)
		else:
			_timer_interval.paused = false
	)
	body_exited.connect(func(body: Node2D) -> void:
		if !body is Character:
			return
		_timer_interval.paused = true
	)
	
	_timer_interval.timeout.connect(_on_generating)

func _draw() -> void:
	if !Engine.is_editor_hint():
		return
	draw_set_transform(Vector2.ZERO, -global_rotation, global_scale / Vector2.ONE)
	draw_rect(generation_margin, Color.RED)

func _process(_delta: float) -> void:
	if !Engine.is_editor_hint():
		return
	queue_redraw()

func _on_generating() -> void:
	Sound.play_1d(sound_generating, self)
	
	for i in generating_amount:
		for j in _instantiater.instantiate_all():
			j.global_position = get_viewport_transform().affine_inverse() * Vector2(
				randf_range(generation_margin.position.x, generation_margin.end.x),
				randf_range(generation_margin.position.y, generation_margin.end.y)
			)
	
	generated.emit()
	
	_timer_interval.start(_get_rand(generating_interval, generating_interval_extra))


func _get_rand_int(base: int, extra: int) -> int:
	return randi_range(base, base + extra)

func _get_rand(base: float, extra: float) -> float:
	return randf_range(base, base + extra)
