extends RayCast2D

@export_category("Raycast Flip H")
@export_node_path("Node2D") var root_path: NodePath = ^".."
@export var flip_position_x: bool = true

@onready var _sgnx: float = signf(position.x)
@onready var _sgntgx: float = signf(target_position.x)
@onready var _root: Node2D = get_node(root_path)


func _process(_delta: float) -> void:
	var facing := int(roundf(_root.get_meta(&"facing", 1)))
	if facing in [-1, 1]:
		set(&"flip_h", facing < 0)
		set_meta(&"facing", facing)
		
		if flip_position_x: 
			position.x = facing * _sgnx * absf(position.x)
			target_position.x = facing * _sgntgx * absf(target_position.x)
