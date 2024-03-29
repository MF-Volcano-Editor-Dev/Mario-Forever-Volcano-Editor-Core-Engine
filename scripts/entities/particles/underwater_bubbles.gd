extends GPUParticles2D

@export_category("Bubble")
## If [code]true[/code], the emission of bubble will be manually processed
@export var manual_emission: bool

@onready var _par: Node2D = get_parent()


func _process(_delta: float) -> void:
	if manual_emission:
		return
	emitting = _par.is_in_group(&"state_in_water")
