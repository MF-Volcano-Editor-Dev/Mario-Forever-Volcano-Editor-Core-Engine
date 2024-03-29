extends CharacterBody2D

@export_category("Podoboo")
@export var thrown: bool
@export_group("Physics")
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px") var height: float = 256
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:x") var gravity_scale: float = 0.25
@export_range(0, 60, 0.001, "suffix:s") var jumping_interval: float = 3
@export_group("References")
@export_node_path("Timer") var timer_jump_path: NodePath = ^"TimerJump"
@export_node_path("Node2D") var sprite_path: NodePath

var _moving: bool
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980)
var _falling: bool

@onready var _timer_jump: Timer = get_node(timer_jump_path)
@onready var _sprite: Node2D = get_node_or_null(sprite_path)

@onready var _gpos: Vector2 = global_position


func _ready() -> void:
	if !thrown:
		_timer_jump.start(jumping_interval)
		_timer_jump.timeout.connect(_on_jump)
	else:
		_moving = true

func _process(delta: float) -> void:
	if !_moving:
		return
	
	var up := Vector2.UP.rotated(global_rotation)
	if _falling && velocity.dot(up.normalized()) < 0:
		_falling = false
		if _sprite:
			var tw: Tween = _sprite.create_tween().set_trans(Tween.TRANS_SINE)
			tw.tween_property(_sprite, ^"rotation", PI, 0.5)
	if !_falling && velocity.dot(up.normalized()) > 0:
		_falling = true
		_sprite.rotation = 0
	
	velocity -= up * gravity_scale * _gravity * delta
	global_position += velocity * delta
	
	# Stop
	if global_position.direction_to(_gpos).dot(up) > 0:
		global_position = _gpos
		_moving = false
		if !thrown:
			_timer_jump.start(jumping_interval)


func _on_jump() -> void:
	if thrown:
		return
	var v0 := sqrt(2 * gravity_scale * _gravity * height) # v0 = sqrt(2 * g * h)
	velocity = Vector2.UP.rotated(global_rotation) * v0
	_moving = true
