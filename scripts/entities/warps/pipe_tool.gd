@tool
extends Node2D

const _Font := preload("res://engine/assets/fonts/hud_font.png")

const _Entrance: Script = preload("res://engine/scripts/entities/warps/pipe_entrance.gd")

var _par: Node2D
var _path_to_exit: NodePath
var _exit: Node2D

var _way_points: Array[Marker2D]


func _ready() -> void:
	if !Engine.is_editor_hint():
		queue_free()

func _draw() -> void:
	if !_par:
		return
	if !_par.preview:
		return
	
	draw_set_transform(Vector2.ZERO, -global_rotation, Vector2.ONE / global_scale)
	
	var dir: String = ""
	match _par.direction:
		0:
			dir = "UP"
		1:
			dir = "DOWN"
		2:
			dir = "LEFT"
		3:
			dir = "RIGHT"
	
	draw_string(_Font, Vector2.ZERO, dir, HORIZONTAL_ALIGNMENT_CENTER, -1)
	
	if _par is _Entrance:
		# Line to exit
		if _path_to_exit != _par.exit_path:
			_path_to_exit = _par.exit_path
			_exit = _par.get_node_or_null(_par.exit_path)
		if _exit:
			var target := _exit.global_position - global_position
			draw_line(Vector2.ZERO, target, Color.MEDIUM_PURPLE, 4)
			draw_circle(target, 8, Color.MEDIUM_PURPLE)
		# Line of waypoints
		if _way_points != _par.waypoints:
			_way_points = _par.waypoints
		if !_way_points.is_empty():
			var points: PackedVector2Array = []
			points.append(Vector2.ZERO) # Origin
			for i in _way_points:
				if !i:
					continue
				points.append(i.global_position - global_position) # Relevant position
			if points.size() > 1:
				draw_polyline(points, Color.AQUA, 4)
				draw_circle(points[-1], 8, Color.AQUA)

func _process(_delta: float) -> void:
	if !_par:
		_par = get_parent()
	if !_par:
		return
	if !visible:
		return
	
	queue_redraw()
