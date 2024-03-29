@tool
extends Node2D

const _GOAL: Script = preload("./goal.gd")

@export_category("Goal Predetector")
@export_node_path("Node2D") var goal_path: NodePath = ^".."

@onready var _goal: _GOAL = get_node(goal_path)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	(func() -> void:
		# Sets rectangle size and position
		var rect_delta: Vector2 = Vector2(position.x - _goal.pos_top.position.x, _goal.pos_top.position.y - position.y)
		(_goal.completion_area_rectangle.shape as RectangleShape2D).size = rect_delta.abs()
		_goal.completion_area_rectangle.position = Vector2(position.x + _goal.pos_top.position.x, _goal.pos_top.position.y + position.y) / 2
		
		# Sets borderline position
		_goal.completion_area_infinite.global_transform = global_transform
	).call_deferred() # Called deferred to make sure the children of `_goal` is safely got
