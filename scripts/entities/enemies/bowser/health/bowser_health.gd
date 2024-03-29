extends CanvasLayer

const _Bowser := preload("res://engine/scripts/entities/enemies/bowser/bowser.gd")

@export_category("Bowser's Health")
@export_node_path("EntityBody2D") var bowser_path: NodePath = ^".."
@export_node_path("AnimationPlayer") var animation_path: NodePath = ^"AnimationPlayer"
@export_node_path("TextureRect") var health_path: NodePath = ^"Frame/Avatar/Health"

@onready var _bowser: _Bowser = get_node(bowser_path)
@onready var _animation: AnimationPlayer = get_node(animation_path)
@onready var _health: TextureRect = get_node(health_path)


func _ready() -> void:
	_bowser.bowser_in_screen.connect(_animation.play.bind(&"display"))
	_bowser.bowser_defeated.connect(func() -> void:
		reparent(_bowser.get_parent())
		_animation.play_backwards(&"display")
	)
	_bowser.bowser_health_changed.connect(func() -> void:
		_health.position.x = -_bowser.health * _health.texture.get_width()
		_health.size.x = absi(roundf(_health.position.x))
		_health.visible = _bowser.health > 0
	)
