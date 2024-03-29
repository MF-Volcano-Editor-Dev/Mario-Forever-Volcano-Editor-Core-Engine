extends NinePatchRect

@export_category("Fluid Area")
@export_node_path("Area2D") var area_path: NodePath

@onready var _area: Area2D = get_node_or_null(area_path)


func _ready() -> void:
	_init_shape()
	_update()

func _process(_delta: float) -> void:
	_update()


func _init_shape() -> void:
	if !_area:
		return
	var shape := _area.shape_owner_get_shape(0, 0).duplicate(true)
	_area.shape_owner_clear_shapes(0)
	_area.shape_owner_add_shape(0, shape)
	

func _update() -> void:
	if !_area:
		return
	_area.position = pivot_offset + size / 2
	_area.shape_owner_get_shape(0, 0).size = size
