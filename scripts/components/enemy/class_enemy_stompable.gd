@tool
@icon("res://icons/enemy_touch_stomp.svg")
class_name EnemyStompable extends EnemyTouch

## Component inheriting [EnemyTouch], but allows the toucher to stomp onto the [member Component.root] ([Area2D]).
##
## This component works similar to [EnemyTouch]; however, when it comes to such situation where a character stomps onto the [i]head[/i] of the area, the character will not get hurt, with being-stomped event triggered. 

## Emitted when a stomp is failed.[br]
## [br]
## [b]Note:[/b] This will be emitted [u]before[/u] the emission of [signal on_touched_by_character].
signal on_stomp_failed(body: PhysicsBody2D)

## Emitted when a stomp is successful.
## [br]
## [b]Note:[/b] This will be emitted [u]before[/u] the emission of [signal on_touched_by_character].
signal on_stomp_succeeded(body: PhysicsBody2D)

## Enables stompability; otherwsie this compoenent will behave similarly to [EnemyTouch].
@export var stompable: bool = true
@export_group("Stomp")
## Angle in tolerance, which stands for the direction that the character stomps onto the enemy.[br]
## [br]
## The direction is calculated by making the global position of the [member Component.root] ([Area2D]) subtract from global location of the character, normalized, which is definitely an arrow pointing from the character's global position to the area's.[br]
## [br]
## Whether a stomp is successful or not is determined by the angle between this direction and [member up_direction](rotated by area's [member Node2D.global_rotation]).
## If a angle is lower than [member tolerance], then the stomp is failed; otherwise, it is successful.
@export_range(0, 60, 0.001, "degrees") var tolerance: float = 45
## Up direction of successful stomp. See [member tolerance] for details.
@export var up_direction: Vector2 = Vector2.UP:
	set(value):
		if value.is_zero_approx():
			printerr("The up_direction can not be a zero vector!")
			return
		
		up_direction = value.normalized()
## Offset of the hit center.[br]
## [br]
## This is used to make offset for the hit center of the [Area2D] to ensure the safe stomp.
@export var offset: Vector2
## Delay to prevent from damaging the character when a stomp is successful.
@export_range(0, 2, 0.001, "suffix:s") var stomp_delay: float = 0.08
@export_group("Sounds", "sound_")
@export var sound_stomped: AudioStream = preload("res://engine/assets/sounds/stomp.wav")

@onready var _delay: SceneTreeTimer


func _ready() -> void:
	super()
	# To prevent from fast stomping during multicreation of the same object
	# E.g. A troopa created a koopa and dashes into creating a shell
	_delay = get_tree().create_timer(stomp_delay, false)
	_delay.timeout.connect(func() -> void:
		_delay = null
	)


## [code]virtual[/code] Called when a toucher collides the [member Component.root] ([Area2D]).
func _touched(toucher: PhysicsBody2D) -> void:
	if !is_instance_valid(toucher):
		return
	
	if character_damagible && !_delay && toucher is Character && !_is_stomp_success(toucher):
		toucher.hurt()


func _is_stomp_success(body: Node2D) -> bool:
	if !stompable:
		return false
	
	var center: Vector2 = body.get_center() if body is Character else body.global_position
	var direction := center.direction_to((root as Area2D).global_position)
	var dot := direction.dot(-up_direction)
	
	return dot >= cos(deg_to_rad(tolerance))


func _on_body_touched(body: Node2D) -> void:
	if _delay:
		return
	if !body is PhysicsBody2D:
		return
	if !body.is_in_group(&"enemy_toucher"):
		return
	
	body = body as PhysicsBody2D # Character
	if _is_stomp_success(body):
		Sound.play_2d(sound_stomped, root)
		
		_delay = get_tree().create_timer(stomp_delay, false)
		_delay.timeout.connect(func() -> void:
			_delay = null
		)
		
		on_stomp_succeeded.emit(body)
	else:
		on_stomp_failed.emit(body)
	
	super(body)
