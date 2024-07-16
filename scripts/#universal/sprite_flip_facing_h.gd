extends Node2D

@export_category("Sprite Flip Facing H")
@export_node_path("Node2D") var root_path: NodePath = ^".."
@export var flip_position_x: bool
@export_range(-18000, 18000, 0.001, "radians_as_degrees", "suffix:°/s") var flip_rotaiton_speed: float

@onready var _sgnx: float = signf(position.x)
@onready var _root: Node2D = get_node(root_path)


func _process(delta: float) -> void:
	var facing := int(roundf(_root.get_meta(&"facing", 1)))
	if facing in [-1, 1]:
		set(&"flip_h", facing < 0)
		set_meta(&"facing", facing)
		
		if flip_position_x: 
			position.x = facing * _sgnx * absf(position.x)
		if !is_zero_approx(flip_rotaiton_speed):
			rotate(flip_rotaiton_speed * delta * facing)
