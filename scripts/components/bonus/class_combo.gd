class_name Combo extends Component

## A component used for counting combo and provide bonus for characters
##
## This requires [member Component.root] to be [Area2D] and a [member body_path] to a body on which spawns scores or lives.

signal on_combo ## Emitted when a combo is triggered.

## Enables combo
@export var enabled: bool = true
## [ComboBonusList] for the combo
@export var combo_bonuses: ComboBonusList = preload("res://engine/objects/components/combo/default_combo_list.tres")
## Path to the body on which effects are created
@export_node_path("Node2D") var body_path: NodePath = ^".."

var _count: int

@onready var _body: Node2D = get_node(body_path)


## Counts up 1 combo count.
func combo() -> void:
	if !enabled:
		return
	
	var bonus := combo_bonuses.bonuses[_count].get_bonus().instantiate()
	bonus.global_position = _body.global_position
	bonus.amount = combo_bonuses.bonuses[_count].bonus_amount
	_body.add_sibling.call_deferred(bonus)
	
	Sound.play_2d(combo_bonuses.bonuses[_count].sound_bonus, _body).pitch_scale = combo_bonuses.bonuses[_count].sound_pitch
	
	_count += 1
	if _count > combo_bonuses.bonuses.size() - 1:
		_count = 0
	
	on_combo.emit()

## Resets the combo count.
func reset() -> void:
	_count = 0
