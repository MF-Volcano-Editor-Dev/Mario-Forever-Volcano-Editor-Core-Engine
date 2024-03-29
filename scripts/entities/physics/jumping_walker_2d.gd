class_name JumpingWalker2D extends Walker2D

## [Walker2D] with capability to jump.
##
## This node will get [signal EntityBody2D.collided_floor] connected to [method EntityBody2D.jump], so you should not connect the signal to the method manually.

signal jumping_times_over ## Emitted when [member jumping_times] reaches down to zero.

## Maximum of jumping times.[br]
## Minus value means no limit.
@export_range(-1, 50) var jumping_times: int = -1
## Jumping speed
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var jumping_speed: float


func _ready() -> void:
	super()
	
	# To avoid awkward and weird bug when fireball was created, disappearing, and Mario will lose every collision
	for i in 2:
		await get_tree().physics_frame
	
	# To prevent from static call of jump() that leads to still of parameter passed in
	collided_floor.connect(func() -> void:
		jump(jumping_speed)
		
		if jumping_times > 0:
			jumping_times -= 1
			if jumping_times <= 0:
				jumping_times_over.emit()
	)
