@tool
@icon("res://engine/icons/attacker.svg")
class_name Attacker extends Component

## Used as a child of [Area2D] to provide collision reaction like an projectile. Usually works with [Attackee].
##
## This is used as a child node of [Area2D] so that it may automatically connect the collision detection to process of attacking [Attackee].
## Usually works with [Attackee] and see it for more details.

@warning_ignore("unused_signal")
signal attacked_target(target: Attackee) ## Emitted when the area collides with another one containing [Attackee] and the interaction with the [Attackee] is successful.
@warning_ignore("unused_signal")
signal attack_succeeded ## Emitted when the enemy attacked gets damaged successfully. [br][b]Called by [EnemyKillingProcess2D].[/b]
@warning_ignore("unused_signal")
signal attack_failed ## Emitted when the enemy attacked defended the attacker. [br][b]Called by [EnemyKillingProcess2D].[/b]

## Id of the attacker. See [enum DataList.AttackId], [member Attackee.filter_ids] and [enum Attackee.FilterMode] for details.
@export var id: DataList.AttackId = DataList.AttackId.NONE
## Damage level of the attacker.[br]
## This may cause [Attackee] with lower [member Attackee.defense_level] value fail blocking the attack.
@export_range(0, 20) var damage_level: int

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	(root as Area2D).area_entered.connect(_on_attacked_attackee)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if !Engine.is_editor_hint():
		return warnings
	if !get_root() is Area2D:
		warnings.append("The component works only when the \"root\" is an Area2D.")
	
	return warnings


func _on_attacked_attackee(area: Area2D) -> void:
	for i in area.get_children():
		if !i is Attackee: # Skip the Area2Ds without Attackee
			continue
		
		(i as Attackee)._hit_by_attacker(self)
		break
