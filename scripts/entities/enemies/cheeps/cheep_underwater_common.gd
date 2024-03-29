extends Node2D

signal cheep_out_of_fluid ## Emitted when the cheep is out of specific fluid. See [member fluid_group].
signal cheep_collided_wall ## Emitted when the cheep collides with wall.

@export_category("Cheep Swimming")
@export var fluid_group: StringName = &"water"
@export var initially_facing_character: bool = true
@export_group("Physics")
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px") var body_radius: float = 16
@export_enum("Linear", "Up Down", "Homing") var swimming_mode: int:
	set(value):
		swimming_mode = value
		
		if !is_node_ready():
			await ready
		
		if swimming_mode == 1:
			_timer_interval.start(swimming_up_down_interval)
		elif swimming_mode == 2:
			_timer_interval.start(homing_interval)
@export var collidable: bool
@export_subgroup("Up Down & Linear", "swimming_")
@export var swimming_speed: Vector2 = Vector2(50, 0)
@export_range(0, 180, 0.001, "degrees") var swimming_up_down_central_angle: float = 22.5
@export_range(0, 20, 0.001, "suffix:s") var swimming_up_down_interval: float = 1
@export_subgroup("Homing", "homing_")
@export_range(0, 60, 0.001, "suffix:s") var homing_interval: float = 1
@export_group("Generated")
@export var is_created_by_generator: bool
@export var disappearance_margin: float = 32
@export_group("References")
@export_node_path("ShapeCast2D") var collider_x_path: NodePath = ^"ColliderX"
@export_node_path("ShapeCast2D") var collider_y_path: NodePath = ^"ColliderY"
@export_node_path("Area2D") var effect_box_path: NodePath = ^"EffectBox"
@export_node_path("Timer") var timer_interval_path: NodePath = ^"TimerInterval"

var velocity: Vector2
var _local_velocity: Vector2

var _delayed: int = 8
var _nearest_player: Character

@onready var _collider_x: ShapeCast2D = get_node(collider_x_path)
@onready var _collider_y: ShapeCast2D = get_node(collider_y_path)
@onready var _effect_box: Area2D = get_node(effect_box_path)
@onready var _timer_interval: Timer = get_node(timer_interval_path)


func _ready() -> void:
	swimming_mode = swimming_mode # Triggers setter to initialize the swimming mode
	
	_timer_interval.timeout.connect(_on_interval)
	
	if initially_facing_character:
		_nearest_player = Character.Getter.get_nearest(get_tree(), global_position)
		if _nearest_player:
			var dir := Transform2DAlgo.get_direction_to_regardless_transform(global_position, _nearest_player.global_position, global_transform)
			velocity = dir * swimming_speed.rotated(global_rotation)

func _process(delta: float) -> void:
	_update_collider(_collider_x)
	_collision(_collider_x)
	_update_collider(_collider_y)
	_collision(_collider_y)
	
	global_position += velocity * delta
	_local_velocity = velocity.rotated(-global_rotation)
	
	set_meta(&"facing", signf(_local_velocity.x))
	
	if _delayed > 0:
		_delayed -= 1 # To prevent from mistaken detect as being out of water
		return
	# If the cheep is indeed out of water, the notify that the fish is out of water currently
	# And the signal should be connected to forced_kill() of EnemyKillingProcess
	var is_in_fluid: bool = false
	for i in _effect_box.get_overlapping_areas():
		if i.is_in_group(fluid_group):
			is_in_fluid = true
			break
	if !is_in_fluid:
		cheep_out_of_fluid.emit()
		return


#region == Collider related ==
func _update_collider(collider: ShapeCast2D) -> void:
	if collider == _collider_x:
		_collider_x.global_position = Vector2(global_position.x + body_radius * signf(velocity.x), global_position.y)
		_collider_x.global_rotation = 0
	if collider == _collider_y:
		_collider_y.global_position = Vector2(global_position.x, global_position.y + body_radius * signf(velocity.y))
		_collider_y.global_rotation = 0

func _collision(collider: ShapeCast2D) -> void:
	if collider.is_colliding():
		for i in collider.get_collision_count():
			var col := collider.get_collider(i)
			if collidable && (!col is AreaFluid || (col is AreaFluid && !col.is_in_group(fluid_group))):
				cheep_collided_wall.emit()
	else: # Turn back to prevent from going out of water
		return_to_water(collider)

func return_to_water(collider: ShapeCast2D) -> void:
	if collider == _collider_x:
		velocity.x *= -1
		_update_collider(_collider_x)
		_collider_x.force_shapecast_update()
	if collider == _collider_y:
		velocity.y *= -1
		_update_collider(_collider_y)
		_collider_y.force_shapecast_update()
#endregion


func _on_interval() -> void:
	match swimming_mode:
		1: # Up Down
			velocity = signf(_local_velocity.x) * swimming_speed.rotated(global_rotation + deg_to_rad(randf_range(-swimming_up_down_central_angle, swimming_mode) / 2))
		2: # Homing
			if !_nearest_player:
				velocity = Vector2.ZERO
				return
			velocity = swimming_speed.rotated(global_position.angle_to_point(_nearest_player.global_position))

func _on_screen_exited() -> void:
	_delayed = 8 # Refresh the delay to prevent mistaken death from being out of water
	if !is_created_by_generator:
		return
	queue_free()
