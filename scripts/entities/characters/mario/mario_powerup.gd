class_name MarioPowerup extends Node2D

## [MarioPowerup] is used to provide sprites and behaviors for [Character], which are implemented in the form of [Node]s.
##
## This node is required to be a direct child of [Character] so that the character may detect and get access to this node together with its children.[br]
## [br]
## To provide specific data for a character that the powerup is tracking on, such as sprites and behaviors, please use relevant nodes and add them as the children of this node.

signal powerup_entered ## Emitted when the powerup becomes current.
signal powerup_exited ## Emitted when the powerup exits from being current.

## Id of the powerup.[br]
## This is used to make this node identified by the character, and gives the node an real identity of a [u]unique[/u] powerup.
@export var powerup_id: StringName = &"small"
## Id of the powerup when the character gets hurt. See [powerup_id] for more details.[br]
## If this keeps empty, the character will die when he gets hurt.
@export var down_to_powerup_id: StringName = &""
## Level of the powerup. Used to prevent from getting lower powerups.
@export_range(-5, 5) var powerup_level: int
@export_group("References")
## Paths to [CollisionShape2D]s that the node is going to set for the character.[br]
## [br]
## [b]Note:[/b] Before Godot 4.3 to be released, [CollisionShape2D] doesn't support indirect reference to a [PhysicsBody2D], which is the ancestor class of [Character] and even [Mario].
## That is to say, the [CollisionShape2D]s work only when they are direct children of it. 
## See [method set_shapes_for_character] for more details.
@export var collision_shapes_path: Array[NodePath] = [^"CollisionShape2D"]
## Path to [AnimatedSprite2D] of the powerup to help display the character's sprites.
@export_node_path("AnimatedSprite2D") var animated_sprite_path: NodePath = ^"AnimatedSprite2D"
## Path to [AnimatedPlayer] of the powerup to help control the character's shapes.
@export_node_path("AnimationPlayer") var shape_controller_path: NodePath = ^"ShapeController"
## Path to [StateMachine]
@export_node_path("StateMachine") var state_machine_path: NodePath = ^"StateMachine"
@export_group("Physics")
## Overrides [member EntityBody2D.gravity_scale] of the character.[br]
## [br]
## [b]Note[/b]: This property works only at the moment the powerup becomes current, or the moment the value gets changed.
@export var gravity_scale_override: float = 1:
	set(value):
		gravity_scale_override = value
		if !is_instance_valid(character):
			return
		if !character.is_node_ready():
			return
		character.gravity_scale = gravity_scale_override
## Overrides [member EntityBody2D.max_falling_speed] of the character.[br]
## See [member gravity_scale_override] for details
@export var max_falling_speed_override: float = 500:
	set(value):
		max_falling_speed_override = value
		if !is_instance_valid(character):
			return
		if !character.is_node_ready():
			return
		character.max_falling_speed = max_falling_speed_override
@export_group("Features")
## Features of the powerup.[br]
## [br]
## [b]Note:[/b] By default there are some features which should NOT be removed:[br]
## * is_small: Marks the powerup as small, which decides if the powerup allows character to crouch.
@export var features: Dictionary = {
	is_small = false,
}
@export_group("Sounds", "sound_")
@export var sound_hurt: AudioStream = preload("res://engine/assets/sounds/power_down.wav")
@export var sound_death: AudioStream = preload("res://engine/assets/sounds/death.ogg")

@onready var animated_sprite: AnimatedSprite2D = get_animated_sprite()
@onready var shape_controller: AnimationPlayer = get_shape_controller()
@onready var collision_shapes: Array[CollisionShape2D] = (func() -> Array[CollisionShape2D]:
	var rst: Array[CollisionShape2D] = []
	for i in collision_shapes_path:
		var collision_shape: CollisionShape2D = get_node_or_null(i) as CollisionShape2D
		if !collision_shape:
			continue
		rst.append(collision_shape)
	return rst
).call()
@onready var state_machine: StateMachine = get_state_machine()
@onready var character: Mario = get_parent()


## [code]virtual[/code], [code]mutable[/code] Called when the powerup becomes current.
func _powerup_entered() -> void:
	set_shapes_for_character()
	
	gravity_scale_override = gravity_scale_override # Triggers the setter of this property to set the value for the character
	max_falling_speed_override = max_falling_speed_override # Same as previous one
	
	if animated_sprite && !character.no_appearing_animation_when_ready:
		animated_sprite.play(&"appear")
		get_tree().create_timer(1, false).timeout.connect(animated_sprite.play.bind(&"default"))
	
	powerup_entered.emit()

## [code]virtual[/code], [code]mutable[/code] Called when the powerup exits from being current.
func _powerup_exited() -> void:
	powerup_exited.emit()


## Sets the shapes for the character.[br]
## [br]
## [b]Note:[/b] This is done with [PhysicsServer2D]
func set_shapes_for_character() -> void:
	(func() -> void:
		for i in collision_shapes:
			if !i:
				continue
			var crid: RID = character.get_rid()
			var srid: RID = i.shape.get_rid() if i.shape else RID()
			var index: int = collision_shapes.find(i)
			# Adds shapes if there is no any shapes created for the character directly
			if PhysicsServer2D.body_get_shape_count(crid) < collision_shapes.size():
				PhysicsServer2D.body_add_shape(crid, srid, i.transform)
			# Uses server to help with setting the shapes
			# so that even the collision shapes are not the direct child of the character.
			# the character still enjoys them as it should have them.
			PhysicsServer2D.body_set_shape(crid, index, srid)
			PhysicsServer2D.body_set_shape_as_one_way_collision(crid, index, i.one_way_collision, i.one_way_collision_margin)
			PhysicsServer2D.body_set_shape_disabled(crid, index, i.disabled)
			PhysicsServer2D.body_set_shape_transform(crid, index, i.transform)
	).call_deferred()


#region == Getters ==
func get_character() -> Mario:
	return get_parent() as Mario

func get_animated_sprite() -> AnimatedSprite2D:
	return get_node_or_null(animated_sprite_path)

func get_shape_controller() -> AnimationPlayer:
	return get_node_or_null(shape_controller_path)

func get_state_machine() -> StateMachine:
	return get_node_or_null(state_machine_path)
#endregion
