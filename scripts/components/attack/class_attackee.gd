@tool
@icon("res://icons/attackee.svg")
class_name Attackee extends Component

## Used as a child of [Area2D] to provide collision reaction like an enemy. Usually works with [Attacker].
##
## This is used as a child node of [Area2D] so that it may automatically connect the collision detection to process of being attacked by [Attacker].
## Usually works with [Attacker] and see it for more details.

signal on_hit_by_attacker(attacker: Attacker) ## Emitted when the area is hit by another one that contains an [Attacker].

## Filter mode for [member filter_ids] and [member filter_types]
enum FilterMode {
	INCLUSION, ## In this mode, the collision will be regarded as success if a token is [b]included[/b] in the filter list.
	EXCLUSION ## In this mode, the collision will be regarded as success if a token is [b]excluded[/b] from the filter list.
}

@export_group("Filters")
## Filters the attackers whose ids are listed in the array.
@export var filter_ids: Array[DataList.AttackId]
## Filter mode of [member filter_ids]. See [enum FilterMode] for details.
@export var filter_ids_mode: FilterMode = FilterMode.EXCLUSION
@export_group("Defense")
## Defense level of the attackee.[br]
## This may cause [Attacker] with lower [member Attacker.damage_level] value fail attack.
@export_range(0, 20) var defense_level: int
@export_group("Sounds", "sound_")
@export var sound_attacked: AudioStream


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if !Engine.is_editor_hint():
		return warnings
	if !get_root() is Area2D:
		warnings.append("The component works only when the \"root\" is an Area2D.")
	
	return warnings


func _hit_by_attacker(attacker: Attacker) -> void:
	if !root is Area2D:
		printerr("The \"root\" of the component %s is not an Area2D! The attack is discarded!" % get_path())
		return
	
	# Filtering
	if attacker.id == DataList.AttackId.NONE:
		return
	for i in filter_ids:
		if i == DataList.AttackId.NONE || \
			(attacker.id != DataList.AttackId.FORCED && 
			((filter_ids_mode == FilterMode.EXCLUSION && attacker.id in filter_ids) || 
			(filter_ids_mode == FilterMode.INCLUSION && !attacker.id in filter_ids))):
				return
	
	Sound.play_2d(sound_attacked, root)
	
	on_hit_by_attacker.emit(attacker)
	attacker.attacked_target.emit(attacker)
