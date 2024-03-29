class_name Walker2D extends EntityBody2D

## A type of physics body that walks, containing a property to set initial facing direction.
##
## This body will automatically move in [method Node._physics_process], and if you override the virtual method, remember to add a [code]super()[/code] before or after the execution of your own codes in that function.[br]
## [br]
## Meanwhile, the body allows you to set its initial direction in three modes. See [enum InitDirection] for details.

## Methods determining the walking direction on the readiness of the body.
enum InitDirection {
	BY_VELOCITY, ## Default option. The body will move as the value of [member EntityBody2D.velocality].x, which means that a minus value forces the body to move left while a positive value forces it to move right.
	FORCED_LEFT, ## The body will move left initially.
	FORCED_RIGHT, ## The body will move left initially.
	LOOK_AT_PLAYER, ## The body will move towards the player initially.
	BACK_TO_PLAYER ## The body will move backwards to the player initially.
}

## Initial walking direction. See [enum InitDirection] for details.
@export var initial_direction: InitDirection = InitDirection.BY_VELOCITY
## Enables real velocity mode.[br]
## [br]
## [b]Note:[/b] Once this mode is enabled, the body will simulate the physics in realler way. For example, the body will slide down with acceleration from a slope.
@export var enable_real_velocity: bool

func _ready() -> void:
	if initial_direction != InitDirection.BY_VELOCITY:
		initialize_direction.call_deferred() # Called in a deferred manner to ensure the direction will be correctly set no matter where the node is in the scene tree


func _physics_process(_delta: float) -> void:
	calculate_gravity()
	calculate_damp()
	move_and_slide(enable_real_velocity)
	
	set_meta(&"facing", signf(velocality.x)) # Useful for sprite_flip_facing_h.gd


## Initializes the moving direction of the object.
func initialize_direction() -> void:
	# Forced directions
	if initial_direction == InitDirection.FORCED_LEFT:
		velocality.x = -1 * absf(velocality.x)
		return
	elif initial_direction == InitDirection.FORCED_RIGHT:
		velocality.x = absf(velocality.x)
		return
	
	# Auto-detected directions
	var np := Character.Getter.get_nearest(get_tree(), global_position) # Nearest player
	if !np:
		velocality.x = absf(velocality.x) * [-1, 1].pick_random() # Random direction if no player is in the level
		return
	
	var dir := (1 if initial_direction == InitDirection.LOOK_AT_PLAYER else -1) * Transform2DAlgo.get_direction_to_regardless_transform(global_position, np.global_position, global_transform)
	if dir == 0:
		dir = [-1, 1].pick_random()
	velocality.x = absf(velocality.x) * dir
