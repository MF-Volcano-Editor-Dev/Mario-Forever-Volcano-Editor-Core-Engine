class_name BumpingWalker2D extends Walker2D

## [Walker2D] with capability to bounce and bump.
##
## This node will collide with other bodies and bounce, when [signal bumped] will be emitted with a parameter in type of [KinematicCollision2D] that provides information about the collision.

signal bumped(collision: KinematicCollision2D) ## Emitted when the body bumps on the body
signal bump_called ## Emitted when [method bump] is called.
signal bumped_over ## Emitted when [member bouncing_times] reaches zero.

## Rest bouncing times. If it reaches zero, the collision with other ones will be disabled
@export_range(0, 20) var bouncing_times: int = 3:
	set(value):
		bouncing_times = value
		if bouncing_times <= 0:
			collision_mask = 0
			bumped_over.emit()
@export_group("Bouncing")
## When reflect mode is on, the relative axis of velocality will be reflected rather than setting it the related compoennt of [member bouncing_velocality].[br]
## [br]
## For example, if [code]X Reflect[/code] is checked, [code]velocality.x[/code] will be [code]-velocality.x[/code] instead of [code]signf(velocality.x) * bouncing_velocality.x[/code], and the same goes for Y Reflect on [code]velocality.y[/code].
@export_flags("X Reflect", "Y Reflect") var reflect_mode: int
## If [code]true[/code], the bumper can only jump along y-axis rather than reflect.[br]
## [br]
## [b]Note:[/b] This will replace the reflection of [member EntityBody2D.velocality] on y-axis with [method EntityBody2D.jump].
@export var y_jump_only: bool = true
## [EntityBody2D.velocality] in reversed direction on bumping.[br]
## [br]
## If the bumper hits the ceiling, then no velocality.y will be assigned.[br]
## [br]
## See [member reflect_mode] as well for velocality reflection.
@export var bouncing_velocality: Vector2
@export_group("Sounds", "sound_")
@export var sound_bumping: AudioStream = preload("res://engine/assets/sounds/stun.wav")


func _physics_process(delta: float) -> void:
	super(delta)
	
	var last_col := get_last_slide_collision()
	if last_col:
		bumped.emit(last_col)
		bump()

func bump() -> void:
	Sound.play_2d(sound_bumping, self)
	
	# X bouncing
	if reflect_mode & 1:
		turn_wall()
	else:
		velocality.x = signf(get_previous_velocity().x) * -bouncing_velocality.x
	
	# Y bouncing
	if !is_on_ceiling():
		if y_jump_only:
			jump(bouncing_velocality.y)
		elif (reflect_mode >> 1) & 1:
			turn_ceiling_ground()
		else:
			velocality.y = signf(get_previous_velocity().y) * -bouncing_velocality.y
	else:
		velocality.y = 0
	
	# Reduces bouncing times
	if bouncing_times > 0:
		bouncing_times -= 1
	
	bump_called.emit()
