@tool
extends Node2D

const _Counter: Script = preload("res://engine/scripts/uis/counters/counter_label.gd")

signal completion_triggered ## Emitted when the level completion is successfully triggered.
signal completion_restored ## Emitted when the level completion is restored.

@export_category("Goal")
## The facing direction of goal.
@export_enum("Left:-1", "Right:1") var facing: int = -1:
	set(value):
		facing = value
		scale.x *= -absf(facing)
## The shape of detection area:[br]
## [b]* Rectangle:[/b] This requires a goal pre-detector so as to make sure the shape can be determined by both the position of pre-detector and the position of goal. Once a character goes into the rectangle, the detection is successful.[br]
## [b]* Infinite:[/b] In this shappe, as long as a character moves to the back of goal's middle, the detection is successful.
@export_enum("Rectangle", "Infinite") var detection_area_shape: int = 0:
	set(value):
		detection_area_shape = value
		$CompletionDetc/Rectangle.set_deferred(&"disabled", detection_area_shape != 0)
		$CompletionDetc/Infinite.set_deferred(&"disabled", detection_area_shape != 1)
@export_group("Score")
## Scores according to the position of the pole.
@export var scores: PackedInt32Array = [200, 500, 1000, 2000, 5000, 10000]
## Score to be given if a character fails hitting down the pole.
@export_range(0, 10000, 1) var default_score: int = 100

var _has_completed: bool # If true, the complete_level() is not callable, and the pole is unhittable as well.
var _hit_pole: bool # If true, the score will be `default_score`

@onready var _completion_detection: Area2D = $CompletionDetc
@onready var _instantiater_2d: Instantiater2D = $Instantiater2D
@onready var _animation_player: AnimationPlayer = $AnimationPlayer

@onready var completion_area_rectangle: CollisionShape2D = $CompletionDetc/Rectangle
@onready var completion_area_infinite: CollisionShape2D = $CompletionDetc/Infinite
@onready var pos_top: Marker2D = $SpriteGate/PosTop


func _ready() -> void:
	if Engine.is_editor_hint():
		return


## Triggers the completion of current level.
func complete_level(body: Node2D) -> void:
	if !Character.Checker.is_character(body):
		return
	
	body = body as Character
	while !_hit_pole && !body.is_on_floor(): # Coroutine loop by physics step until the character is on the floor
		if !_completion_detection.overlaps_body(body): # Coroutine interruption, stops the execution if, during the loop, the character leaves from the area
			return
		await get_tree().process_frame
	
	if _has_completed:
		return
	_has_completed = true
	
	Events.EventGame.complete_level(get_tree(), [body]) # This triggers completion of the level
	
	var counter: _Counter = _instantiater_2d.instantiate(0) as _Counter
	if _hit_pole:
		var section: int = maxi(0, int(roundf(scores.size() * _animation_player.current_animation_position / _animation_player.current_animation_length)) - 1) # Get which score the character can attain
		counter.amount = scores[section]
	else:
		counter.amount = default_score
	
	completion_area_rectangle.queue_free()
	completion_area_infinite.queue_free()
	_animation_player.queue_free()
	
	completion_triggered.emit()
