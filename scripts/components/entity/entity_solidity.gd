@icon("res://icons/solid_entity.svg")
@tool
class_name EntitySolidity extends Component

## Using [Area2D] as its [member Component.root] to implement collision interaction with other [Area2D]s in the node group [code]entity_collidable[/code].
##
## This component should make [member Component.root] refer to an [Area2D] for collision, 
## and when the area collides with other ones that are in the node group [code]entity_collidable[/code],

signal collided_with_entity ## Emitted when the [member Component.root] ([Area2D]) hits other [Area2D]s that are in the node group [code]entity_collidable[/code].


func _ready() -> void:
	if !root is Area2D:
		return
	
	(root as Area2D).area_entered.connect(_on_collision_with_entity)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if !Engine.is_editor_hint():
		return warnings
	if !get_root() is Area2D:
		warnings.append("The component works only when the \"root\" is an Area2D.")
	
	return warnings


func _on_collision_with_entity(area: Area2D) -> void:
	if !area.is_in_group(&"entity_collidable"):
		return
	
	collided_with_entity.emit()
