extends Node

## Unit used for a level to add the capability of completion.
##
## Completion consists of two stages:[br]
## * 1: In this stage, a music will be played and after a while by [completion_delay], it is going to step into next stage.[br]
## * 2: In this stage, the completion unit is about to switch the scene to next one set.[br]
## [br]
## Calling [method add_stage_2_blocker] with an object will clog the process of jumping into the second stage, while calling [method remove_stage_2_blocker] will remove that object from obstructing the process.[br]
## [b]Attention:[/b] This doesn't mean that only remove one can allow the process to continue, because the methods are operations for an [Array]. To check if there is any object that blocks the process, please call [method get_stage_2_blockers] in [method @GlobalScope.print].[br]
## [br]
## [b]Note:[/b] Each level can contain ONLY ONE of this.

signal completed ## Emitted at the moment the level gets completed.
signal completion_stage_1_done ## Emitted when the completion delay is done.
signal completion_stage_2_done ## Emitted when the completion is accomplished.

@export_category("Level Completion")
## Delay after the finish of the first stage before it is going to the second stage.
@export_range(0, 20, 0.001, "suffix:s") var completion_delay: float = 8
@export_group("Character", "character_")
## Direction of the character at the completion
@export_enum("Left:-1", "Right:1") var character_direction: int = 1
## Walking speed of the character at the completion
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var character_walking_speed: float = 125
@export_group("Scene")
## Next scene to go to after the completion.[br]
## [br]
## [b]Note:[/b] Needs to give the scene file a prefix [b]"room_"[b]!
@export_file("room_*.tscn") var next_scene: String
@export_group("Sounds", "sound_")
@export var sound_completion: AudioStream = preload("res://engine/assets/sounds/level_complete.ogg")

var _objects_blocks_stage_2: Array[Object]
var _character_to_walk: Array[Character]


func _ready() -> void:
	set_process(false) # To increase performance
	
	Events.EventGame.get_signals().completed_level.connect(_on_level_completed)

func _process(_delta: float) -> void:
	for i in _character_to_walk: # Make characters walk
		if !is_instance_valid(i):
			i = null # Invalid item cannot be freed directly
			_character_to_walk.erase(i)
			continue
		
		i.direction = character_direction
		i.velocality.x = character_direction * character_walking_speed
		
		if i.is_on_wall():
			_character_to_walk.erase(i)
		
		if _character_to_walk.is_empty():
			set_process(false) # Deactivates the call to improve performance


func _on_level_completed() -> void:
	for i in Character.Getter.get_characters(get_tree()):
		if i in _character_to_walk:
			continue
		
		_character_to_walk.append(i)
		
		set_process(true) # Activates _process()
	
	completed.emit()
	
	var snd := Sound.play_1d(sound_completion, self)
	snd.volume_db = -10
	Events.EventCharacter.get_signals().all_characters_dead.connect(snd.queue_free)
	
	await get_tree().create_timer(completion_delay, false).timeout
	
	completion_stage_1_done.emit()
	Events.EventGame.get_signals().completion_summary_triggered.emit()
	
	# Blocks the process until there is nothing that blocks it 
	while is_inside_tree() && !_objects_blocks_stage_2.is_empty(): # Coroutine frame loop is unsafe so here a is_inside_tree() is necessary
		await get_tree().process_frame
	
	completion_stage_2_done.emit()
	Events.EventGame.get_signals().completion_accomplished.emit()
	
	await get_tree().create_timer(1, false).timeout
	
	if next_scene:
		Scenes.change_scene_to_path(next_scene)
	else:
		printerr("[LevelCompletion] Invalid or empty next_scene!")


#region == Stage 2 Blockers ==
## Adds an object that blocks the unit to get into the second stage of completion, into the list. See [method remove_stage_2_blocker].
func add_stage_2_blocker(obj: Object) -> void:
	if obj in _objects_blocks_stage_2:
		return
	_objects_blocks_stage_2.append(obj)

## Removes the blocker object from the list. See [method add_stage_2_blocker].
func remove_stage_2_blocker(obj: Object) -> void:
	if !obj in _objects_blocks_stage_2:
		return
	_objects_blocks_stage_2.erase(obj)

## Returns the list of stage-2 blockers. See [method add_stage_2_blocker] and [method remove_stage_2_blocker].
func get_stage_2_blockers() -> Array[Object]:
	return _objects_blocks_stage_2
#endregion
