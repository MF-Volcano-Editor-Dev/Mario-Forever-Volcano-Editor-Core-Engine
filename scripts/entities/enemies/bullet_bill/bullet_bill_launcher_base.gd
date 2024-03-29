@tool
extends AnimatableBody2D

@export_category("Bullet Launhcer Base")
@export_range(0, 1, 0.001, "or_greater", "suffix:px") var gird_height: float = 32:
	set(value):
		gird_height = value
		height = gird_height * height_of_girds
@export_range(0, 1, 0.001, "or_greater", "suffix:girds") var height_of_girds: float = 1:
	set(value):
		height_of_girds = value
		height = gird_height * height_of_girds
@export_range(0, 1, 0.001, "or_greater", "suffix: px") var height: float = 32:
	set = set_height
@export_group("Sprite")
@export var flip_h: bool:
	set(value):
		flip_h = value
		if !is_node_ready():
			await ready
		_sprite.flip_h = flip_h
@export_group("References")
@export_node_path("Sprite2D") var sprite_path: NodePath = ^"Sprite2D"
@export_node_path("CollisionShape2D") var collision_shape_path: NodePath = ^"CollisionShape2D"

var _sprite: Sprite2D
var _collision_shape: CollisionShape2D

func _ready() -> void:
	_sprite = get_node(sprite_path)
	_collision_shape = get_node(collision_shape_path)
	
	set_height(height)


func set_height(value: float) -> void:
	if !is_node_ready():
		await ready
	
	height = value
	
	_sprite.region_rect.size.y = height
	
	if Engine.is_editor_hint():
		notify_property_list_changed()
		return
	
	var actual_height := height - gird_height
	_collision_shape.position.y = (gird_height + actual_height) / 2 
	_collision_shape.shape = _collision_shape.shape.duplicate(true)
	_collision_shape.shape.size.y = absf(actual_height)
