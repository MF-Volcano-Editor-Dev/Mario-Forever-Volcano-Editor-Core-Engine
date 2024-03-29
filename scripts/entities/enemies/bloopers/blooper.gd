extends Node2D

signal blooper_out_of_fluid ## Emitted when the cheep is out of specific fluid. See [member fluid_group].

@export_category("Blooper")
@export var fluid_group: StringName = &"water"
@export_group("References")
@export_node_path("ShapeCast2D") var collider_path: NodePath = ^"Collider"
@export_node_path("Area2D") var effect_box_path: NodePath = ^"EffectBox"
@export_node_path("AnimatedSprite2D") var sprite_path: NodePath = ^"AnimatedSprite2D"
@export_group("Physics")
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var preparing_speed: float = 50
@export_range(0, 90, 0.001, "degrees") var dashing_angle: float = 45
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px") var dashing_height_difference: float = 80
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var dashing_speed: float = 300
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s²") var dashing_decleration: float = 500

var velocity: Vector2
var _local_velocity: Vector2

var _step: int # 0: Preparing, 1: Dashing
var _dir: int

var _delayed: int = 8
var _normal: Vector2
var _nearest_player: Character

@onready var _collider: ShapeCast2D = get_node(collider_path)
@onready var _effect_box: Area2D = get_node(effect_box_path)
@onready var _sprite: AnimatedSprite2D = get_node(sprite_path)


func _process(delta: float) -> void:
	_nearest_player = Character.Getter.get_nearest(get_tree(), global_position)
	if _nearest_player:
		_dir = Transform2DAlgo.get_direction_to_regardless_transform(global_position, _nearest_player.global_position, global_transform)
	
	match _step:
		0, 2: # Preparing
			if !_nearest_player:
				velocity = velocity.move_toward(Vector2.ZERO, dashing_decleration * delta)
			
			_sprite.play(&"prepare")
			
			velocity = Vector2.DOWN.rotated(global_rotation) * preparing_speed
			
			# Delay before next preparation for dashing
			if _step == 2:
				_step = 3
				get_tree().create_timer(0.2, false).timeout.connect(func() -> void:
					_step = 0
				)
			# Preparation for dashing
			elif _step == 0:
				var trans := global_transform.affine_inverse()
				var nptposy := trans.basis_xform(_nearest_player.global_position).y
				var tposy := trans.basis_xform(global_position).y
				
				if tposy - nptposy >= dashing_height_difference:
					velocity = dashing_speed * Vector2.UP.rotated(global_rotation + deg_to_rad(_dir * dashing_angle))
					_step = 1
		1: # Dashing
			_sprite.play(&"default")
			
			velocity = velocity.move_toward(Vector2.ZERO, dashing_decleration * delta)
			if velocity.is_zero_approx():
				velocity = Vector2.ZERO
				_step = 2
	
	if _collider.is_colliding():
		for i in _collider.get_collision_count():
			_normal = _collider.get_collision_normal(i) # Get normal for turning back
			
			var col := _collider.get_collider(i)
			if col is AreaFluid && !col.is_in_group(fluid_group):
				return_to_water()
	else:
		return_to_water()
	
	global_position += velocity * delta
	_local_velocity = velocity.rotated(-global_rotation)
	_collider.position = 16 * _local_velocity.normalized()
	
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
		blooper_out_of_fluid.emit()
		return


func return_to_water() -> void:
	if !_normal.is_normalized():
		return
	velocity = velocity.bounce(_normal)
