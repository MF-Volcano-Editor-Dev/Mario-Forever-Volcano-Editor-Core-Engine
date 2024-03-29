class_name ComboBonus extends Resource

## Resources used to provide combo bonus for [Combo].
##
##

const _Scores: PackedScene = preload("res://engine/objects/uis/counters/scores_label.tscn")
const _Lives: PackedScene = preload("res://engine/objects/uis/counters/lives_label.tscn")

## Type of the bonus.[br]
## 0 => Scores,[br]
## 1 => Lives
@export_enum("Scores", "Lives") var bonus_type: int
## Amount of the bonus
@export var bonus_amount: int
@export_group("Sounds", "sound_")
@export var sound_bonus: AudioStream
@export_range(0.01, 4, 0.001) var sound_pitch: float = 1


## Returns appropriate bonus
func get_bonus() -> PackedScene:
	return _Scores if bonus_type == 0 else _Lives
