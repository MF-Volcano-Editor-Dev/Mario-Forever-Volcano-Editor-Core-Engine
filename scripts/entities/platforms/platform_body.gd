extends AnimatableBody2D

signal platform_stomped ## Emitted when the platform is stomped by bodies in group [code]platform_stompable[/code]

@export_category("Platform")
@export_node_path("PlatformPathFollower2D") var follower_path: NodePath = ^"../PlatformPathFollower2D"
@export_node_path("VisibleOnScreenNotifier2D") var vision_detector_path: NodePath = ^"VisibleOnScreenNotifier2D"
@export var triggers_on_stomping: bool
@export var up_direction: Vector2 = Vector2.UP:
	set(value):
		up_direction = value.normalized()
@export_group("Falling")
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:x") var falling_acceleration_scale: float

var _falling: bool
var _stomp_count: int
var _velocity: Vector2

@onready var _follower: PlatformPathFollower2D = get_node_or_null(follower_path)
@onready var _vision_detector: VisibleOnScreenNotifier2D = get_node(vision_detector_path)

@onready var _rid: RID = get_rid()

func _ready() -> void:
	if triggers_on_stomping && _follower:
		_follower.deactivate()
		platform_stomped.connect(_follower.activate)

func _physics_process(delta: float) -> void:
	if !_falling:
		_detect_being_stomped()
	else:
		var g: Vector2 = PhysicsServer2D.body_get_direct_state(_rid).total_gravity
		_velocity += g * falling_acceleration_scale * delta
		global_position += _velocity * delta
		
		if get_global_transform_with_canvas().get_origin().y > get_viewport_rect().size.y + 512:
			queue_free()


func fall() -> void:
	if is_zero_approx(falling_acceleration_scale):
		return
	
	for i in 2:
		await get_tree().physics_frame # Used to get velocity from the path follower
	
	if _follower:
		_velocity = _follower.get_global_pos_delta() / get_physics_process_delta_time()
		_follower.queue_free()
	_falling = true


func _detect_being_stomped() -> void:
	if !is_instance_valid(_vision_detector):
		return
	if !_vision_detector.is_on_screen():
		return
	
	var up := Vector2.UP.rotated(global_rotation)
	
	# Platform detects stomper
	var kc := KinematicCollision2D.new()
	test_move(global_transform, up, kc)
	var stomper := kc.get_collider() as PhysicsBody2D
	if !is_instance_valid(stomper):
		return
	
	# If stomper is on the platform
	var kc2 := KinematicCollision2D.new()
	var vel: Vector2 = PhysicsServer2D.body_get_state(stomper.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY)
	stomper.test_move(stomper.global_transform, vel.normalized(), kc2)
	var is_platform := kc2.get_collider()
	if is_platform != self:
		return
	
	# Platform stomped
	var count := 0
	if stomper.is_in_group(&"platform_stompable"):
		count += 1
		if _stomp_count != count:
			_stomp_count = count
			if _stomp_count > 0:
				platform_stomped.emit() # Emitted once per stomp, not continuoous emission
