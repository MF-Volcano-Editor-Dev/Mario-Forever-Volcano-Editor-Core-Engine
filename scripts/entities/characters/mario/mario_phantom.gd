extends Phantom2D

@export_category("Phantom")
@export_node_path("MarioPowerup") var powerup_path: NodePath = ^"../.."
@export var generate_on_floor_only: bool

@onready var _powerup: MarioPowerup = get_node(powerup_path)


func _phantom_generated() -> void:
	if !_powerup.character:
		return
	if (_powerup.powerup_id != _powerup.character.current_powerup) || (generate_on_floor_only != _powerup.character.is_on_floor()):
		return
	super()
