class_name ChasingWalker2D extends Walker2D

## A type of [Walker2D] that can chase the nearest character
##
##

@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s²") var acceleration: float

var _reversed_speed: float
var _turning_back: bool


func _process(delta: float) -> void:
	var np: Character = Character.Getter.get_nearest(get_tree(), global_position)
	if !np:
		return
	
	if _turning_back:
		velocality.x = move_toward(velocality.x, _reversed_speed, acceleration * delta)
		if is_equal_approx(velocality.x, _reversed_speed):
			_turning_back = false
	else:
		var trans := global_transform.affine_inverse()
		var nptposx := trans.basis_xform(np.global_position).x
		var tposx := trans.basis_xform(global_position).x
		var facing: int = get_meta(&"facing", 1)
		
		if signf(nptposx - tposx) * facing < 0:
			_turning_back = true
			_reversed_speed = -velocality.x
