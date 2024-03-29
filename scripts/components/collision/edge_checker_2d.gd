class_name EdgeChecker2D extends RayCast2D

## Used for [CharacterBody2D] to check if it reaches the edge of tile
##
## The parent's metadata [code]facing[/code] may effect the detection position of this object.

signal reached_edge ## Emitted if the body reaches the edge of ground

@onready var _par: CharacterBody2D = get_parent()

var _facing: int


func _physics_process(_delta: float) -> void:
	_detection.call_deferred()
	
	var facing = _par.get_meta(&"facing", 1)
	if facing in [-1.0, 1.0]:
		if _facing != facing:
			_facing = facing
			position.x *= -1
			target_position.x *= -1


func _detection() -> void:
	if !_par.is_on_floor():
		return
	
	if !is_colliding():
		reached_edge.emit()
