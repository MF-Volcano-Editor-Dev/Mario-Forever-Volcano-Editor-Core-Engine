class_name AreaFluidDeadily extends AreaFluid

## When a [Character] enters into this area, the character dies.
##
##

func _ready() -> void:
	super()
	
	body_entered.connect(func(body: Node2D) -> void:
		if body is Character:
			body.die()
	)
