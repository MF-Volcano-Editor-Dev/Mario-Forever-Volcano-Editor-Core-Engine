extends Area2D

@export_category("Area Spray")
@export var spray: PackedScene

@onready var _par: NinePatchRect = get_parent() as NinePatchRect


func _ready() -> void:
	_init_shape()
	
	body_entered.connect(func(body: Node2D) -> void:
		if !spray:
			return
		
		var sp := spray.instantiate() as Node2D
		var par := get_parent()
		sp.position = Vector2(to_local(body.global_position).x, position.y)
		add_sibling.call_deferred(sp)
		par.move_child.call_deferred(sp, get_index())
	)

func _init_shape() -> void:
	var shape := shape_owner_get_shape(0, 0).duplicate(true)
	shape_owner_clear_shapes(0)
	shape_owner_add_shape(0, shape)

func _process(_delta: float) -> void:
	if !_par:
		return
	
	var shape := shape_owner_get_shape(0, 0)
	(shape as SegmentShape2D).b.x = _par.size.x
