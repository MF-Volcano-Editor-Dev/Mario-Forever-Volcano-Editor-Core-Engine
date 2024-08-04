class_name BumpBlock2D extends AnimatableBody2D

## Abstract class used for blocks that are interactable with other [PhysicsBody2D] by bumping.
## 
## [Bumper2D] in the following node groups may effect this object in different manners:[br]
## * [code]bumper_head[/code]: The bumper can hit the block from the [u]bottom[/u] of this object.[br]
## * [code]bumper_feet[/code]: The bumper can hit the block from the [u]top[/u] of this object.[br]
## * [code]bumper_side[/code]: The bumper can hit the block from the [u]both sides[/u] of this object.[br]
## * Otherwise, [u]each side[/u] is valid.

signal bumped ## Emitted when the block gets bumped.
signal bump_over ## Emitted when the bumping is over.

const _HeadHit: PackedScene = preload("res://engine/objects/entities/#projectiles/head/head.tscn")

## Up direction offset angle
@export_range(-180, 180, 0.001, "degrees") var up_direction_angle: float = 0
## Hitting tolerance angle based on up direction
@export_range(0, 90, 0.001, "degrees") var tolerance: float = 45.25
## Delay of restoring bumping status
@export_range(0, 20, 0.001, "suffix:s") var restoring_delay: float = 0.1
@export_group("References")
## Path to a node to be hidden by [member visible_at_beginning]
@export_node_path("Node2D") var visible_node_path: NodePath
@export_group("Settings")
## If [code]false[/code], the block will be invisible at the beginning of the game, which may also cause the collision invalidity of the block until its reappearance.
@export var block_visible: bool = true
## [member CollisionObject2D.collision_layer] when invisible
@export_flags_2d_physics var invisible_collision_layer: int = 0b1
## [member CollisionObject2D.collision_mask] when invisible
@export_flags_2d_physics var invisible_collision_mask: int = 0b0
## If [code]false[/code], the block will disappear when the death amount of character is greater than zero
@export var disappear_after_death: bool

var _is_on_bumping: bool
var _up: Vector2
var _dir_to_c: Vector2

@onready var _layer: int = collision_layer
@onready var _mask: int = collision_mask

@onready var _visible_node: Node2D = get_node_or_null(visible_node_path)


func _ready() -> void:
	if disappear_after_death && Character.Data.death_counts > 0:
		queue_free()
		return
	
	_set_visibility_and_collision()


## Called by [Bumper2D].
## @deprecated
func bump(bumper: Bumper2D, touch_spot: Vector2) -> void:
	if !bumper:
		return
	if _is_on_bumping:
		return
	
	_is_on_bumping = true
	
	_up = Vector2.UP.rotated(global_rotation + deg_to_rad(up_direction_angle))
	_dir_to_c = touch_spot.direction_to(global_position)
	var tol := deg_to_rad(tolerance)
	
	var on_bump: bool = false
	if bumper.is_in_group(&"bumper_head") && _dir_to_c.dot(_up) > cos(tol):
		bumped.emit()
		on_bump = true
	elif bumper.is_in_group(&"bumper_feet") && _dir_to_c.dot(-_up) > cos(tol):
		bumped.emit()
		on_bump = true
	elif bumper.is_in_group(&"bumper_side") && (_dir_to_c.dot(_up.orthogonal()) > cos(tol) || _dir_to_c.dot(-_up.orthogonal()) > cos(tol)):
		bumped.emit()
		on_bump = true
	else:
		bumped.emit()
		on_bump = true
	
	if on_bump:
		_bump_process(bumper, touch_spot)
		
		if !block_visible:
			block_visible = true
			_set_visibility_and_collision() # Restores collision
		
		var heights: Array[float] = []
		for i in get_shape_owners():
			for j in shape_owner_get_shape_count(i):
				heights.append(shape_owner_get_shape(i, j).get_rect().size.y / 2)
		
		var h := _HeadHit.instantiate()
		h.global_transform = global_transform.translated_local(Vector2.UP * heights.max())
		add_sibling.call_deferred(h)
	
	get_tree().physics_frame.connect(func() -> void:
		_up = Vector2.ZERO
		_dir_to_c = Vector2.ZERO
	)

## [code]virtual[/code] Called on getting bumped by a bumper.
func _bump_process(_bumper: Bumper2D, _touch_spot: Vector2) -> void:
	restore_bump()


func _set_visibility_and_collision() -> void:
	if _visible_node:
		_visible_node.visible = block_visible
	
	collision_layer = _layer if block_visible else invisible_collision_layer
	collision_mask = _mask if block_visible else invisible_collision_mask


## Called in [method _bump_process] to restore the status of being bumped.
func restore_bump() -> void:
	get_tree().create_timer(restoring_delay, false).timeout.connect(func() -> void:
		bump_over.emit()
	)
	await bump_over
	_is_on_bumping = false

## Returns the dot product between direction from touching position to the center of the block, and up direction.[br]
## [br]
## [b]Note:[/b] This call can be called ONLY in [method _bump_process]!
func get_dot_to_up() -> float:
	return _dir_to_c.dot(_up)
