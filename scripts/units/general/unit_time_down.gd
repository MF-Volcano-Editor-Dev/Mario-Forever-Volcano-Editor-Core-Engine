extends CanvasLayer

## Unit used for a level to add the capability of time count-down.
##
## [b]Note:[/b] Each level can contain ONLY ONE of this.

const _LevelCompletion: Script = preload("res://engine/scripts/units/general/unit_level_completion.gd")

signal time_changed(time: int) ## Emitted every time the [member rest_time] gets changed.
signal time_count_down(amount: int) ## Emitted when the timer counts down.
signal time_count_up(amount: int) ## Emitted when the timer counts up.
signal time_warning ## Emitted when not-enough-time warning is triggered.
signal time_over ## Emitted when the timer is up.
signal timer_done_summary ## Emitted when the summary is finished.

@export_category("Unit Time Down")
## Rest time that the character have to complete the level.
@export_range(0, 99999, 1, "suffix:ut") var rest_time: int = 360:
	set = set_rest_time
@export_group("Unit Ticks", "unit_tick_")
## Unit tick of the timer down.
@export_range(0, 86400, 0.001, "suffix:s") var unit_tick: float = 0.5
## Unit ticks to count down.
## [br]
## [b]Note:[/b] The value can be minus, which means that the timer will count [u]up[/u] rather than [i]down[/i].
@export_range(-99999, 99999, 1, "suffix:ut") var unit_tick_down: int = 1
@export_group("Warning", "warning_")
@export_range(0, 99999, 1, "suffix:ut") var warning_line: int = 100
@export_group("Summary", "sum_")
@export_subgroup("Unit Ticks", "sum_unit_tick_")
## [member unit_tick] during the summary.
@export_range(0, 86400, 0.001, "suffix:ut") var sum_unit_tick: float = 0.01
## [member unit_tick_down] during the summary.
@export_range(-99999, 99999, 1, "suffix:ut") var sum_unit_tick_down: int = 10
## Scores that can be gained by the character, per unit tick during the summary.
@export_range(0, 99999, 1, "suffix:point") var sum_scores_per_ut: int = 10
@export_group("Reference")
## Path to level completion unit.
@export_node_path("Node") var level_completion_path: NodePath = ^"../LevelCompletion"
@export_group("Sounds", "sound_")
@export var sound_time_warning: AudioStream = preload("res://engine/assets/sounds/timer_warning.wav")
@export var sound_summarizing: AudioStream = preload("res://engine/assets/sounds/timer_scoring.wav")

var _has_warned: bool # Has the warning been triggered
var _is_sum: bool # Is summarizing

@onready var _time_count: Label = $Frame/TimeCount
@onready var _animation: AnimationPlayer = $Animation
@onready var _count_down: Timer = $CountDown
@onready var _time_up: Label = $Frame/TimeUp
@onready var _level_completion: _LevelCompletion = get_node_or_null(level_completion_path)


func _ready() -> void:
	rest_time = rest_time # Triggers the setter to initialize the display of `time_count`
	
	Events.EventTimeDown.get_signals().time_down_paused.connect(pause_time_down)
	Events.EventTimeDown.get_signals().time_down_resume.connect(start_time_down)
	
	Events.EventGame.get_signals().completed_level.connect(stop_time_down)
	Events.EventGame.get_signals().completion_summary_triggered.connect(_on_summary_triggered)


#region == Timer Controls ==
## Makes the timer start counting down.[br]
## If the timer is paused, this call will resume it rather than restart it.
func start_time_down() -> void:
	if _count_down.paused:
		_count_down.wait_time = unit_tick
		_count_down.paused = false
	else:
		_count_down.start(sum_unit_tick if _is_sum else unit_tick)

## Stops the timer from counting down.[br]
## [br]
## [b]Note:[/b] Once this call is done, the timer will stop counting down and the rest ticks to trigger the counting down will be discarded.
func stop_time_down() -> void:
	_count_down.stop()

## Pauses the timer from continuing counting down.[br]
## [br]
## [b]Note:[/b] Similar to [method stop_time_down], but the rest ticks will remain.
func pause_time_down() -> void:
	_count_down.paused = true
#endregion


#region == Timer ==
func _on_count_down_timeout() -> void:
	rest_time -= sum_unit_tick_down if _is_sum else unit_tick_down

func _on_summary_triggered() -> void:
	_is_sum = true
	
	if _level_completion:
		_level_completion.add_stage_2_blocker(self)
	
	# Sound
	var tw: Tween = create_tween().set_loops()
	tw.tween_callback(Sound.play_1d.bind(sound_summarizing, self)).set_delay(0.075)
	tw.tween_callback(func() -> void:
		if rest_time <= 0:
			tw.kill()
	)
	
	start_time_down()
	
	# Done summary
	time_changed.connect(func(time: int) -> void:
		if time <= 0 && _level_completion:
			_level_completion.remove_stage_2_blocker(self)
			timer_done_summary.emit()
			stop_time_down()
	)
#endregion


#region == Setgets ==
func set_rest_time(value: int) -> void:
	value = maxi(0, value) # The bottom is 0
	var delta: int = value - rest_time # Delta of the time
	rest_time = value
	
	if !is_node_ready():
		return
	
	_time_count.text = str(rest_time)
	
	# Count down or up
	if delta < 0:
		time_count_down.emit(delta)
	elif delta > 0:
		time_count_up.emit(delta)
	
	time_changed.emit(rest_time) # Emits the signal to update listener's relevant property
	
	# Adds scores during the summary
	if _is_sum:
		Character.Data.scores += absi(delta) * sum_scores_per_ut
	else:
		# Time warning
		if _has_warned && rest_time >= warning_line:
			_has_warned = false
			_animation.play(&"RESET")
		if !_has_warned && rest_time < warning_line:
			_has_warned = true
			_animation.play(&"warning")
			Sound.play_1d(sound_time_warning, self)
		
		# Time up
		if rest_time <= 0:
			_time_up.visible = true
			var a: float = _time_up.modulate.a
			
			var tw: Tween = _time_up.create_tween()
			tw.tween_interval(2)
			tw.tween_property(_time_up, ^"modulate:a", 0, 1)
			tw.tween_callback(func() -> void:
				_time_up.visible = false
				_time_up.modulate.a = a
			)
			
			stop_time_down()
			
			time_over.emit()
#endregion
