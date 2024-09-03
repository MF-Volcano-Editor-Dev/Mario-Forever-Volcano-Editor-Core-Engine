@tool
class_name CircularMIGenerator2D extends Node2D

## Used to generate items that needs circular movement.
##
## [i]MI[/i] refers to moving items. 
## Developers can not only install [CircularMovementObject2D]s, but any objects, to [member items] and they will be serialized
## equally, which means that their initial phases(angles) are distributed in average.[br]
## For other details, See [CircularMovementObject2D].
## [br]
## [b]Note:[/b] This requires [CircularMIGeneratorTemplate] to be installed for [member items].

var _ellipse: Ellipse = Ellipse.new() # This should be declared first

## Enables preview of movement
@export var preview_movement: bool:
	set(value):
		preview_movement = value
		if !Engine.is_editor_hint():
			return
		if preview_movement:
			_preview_initial_values.phase = phase
			_preview_initial_values.track_angle = track_angle
		else:
			phase = _preview_initial_values.phase
			track_angle = _preview_initial_values.track_angle
## Samples of track preview
@export var samples: int = 32
@export var items: Array[CircularMIGeneratorTemplate]:
	set(value):
		items = value
		if !Engine.is_editor_hint():
			return
		queue_redraw()
@export_group("Physics")
@export_subgroup("Basic")
@export var amplitude: Vector2 = Vector2.ONE * 150:
	set(value):
		amplitude = value
		_ellipse.amplitude = amplitude
		if !Engine.is_editor_hint():
			return
		queue_redraw()
@export_range(-180*50, 180*50, 0.1, "radians_as_degrees", "suffix:°/s") var frequency: float = 0.872665:
	set(value):
		frequency = value
		if !Engine.is_editor_hint():
			return
		queue_redraw()
@export_range(-180, 180, 0.1, "radians_as_degrees") var phase: float:
	set(value):
		phase = value
		if !Engine.is_editor_hint():
			return
		queue_redraw()
@export var random_phase: bool
@export_group("Track and Rotation")
@export_range(-180*50, 180*50, 0.1, "radians_as_degrees", "suffix:°/s") var track_rotation_speed: float:
	set(value):
		track_rotation_speed = value
		if !Engine.is_editor_hint():
			return
		queue_redraw()
@export_range(-180, 180, 0.1, "radians_as_degrees") var track_angle: float:
	set(value):
		track_angle = value
		_ellipse.rotation = deg_to_rad(track_angle)
		if !Engine.is_editor_hint():
			return
		queue_redraw()

var _circular_movement_objects: Array[Node2D]
var _preview_initial_values: Dictionary = {
	phase = 0,
	track_angle = 0
}


func _init() -> void:
	_ellipse.center = position
	_ellipse.amplitude = amplitude
	_ellipse.rotation = track_angle

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if random_phase:
		phase = randf_range(-PI, PI)
	
	var index: int = 0
	for i in items:
		if !i.packed_scene:
			_circular_movement_objects.append(null) # Placeholder
			continue
		var ins: Node2D = i.packed_scene.instantiate() as Node2D
		if !ins:
			ins.free()
			_circular_movement_objects.append(null) # Placeholder
			continue
		
		if ins is CircularMovementObject2D:
			ins.amplitude = amplitude
			ins.frequency = frequency
			ins.phase = wrapf(phase + index * (TAU / float(items.size())), -PI, PI)
			ins.track_rotation_speed = track_rotation_speed
			ins.track_angle = track_angle
		
		ins.transform = transform
		add_sibling.call_deferred(ins)
		
		_circular_movement_objects.append(ins)
		
		index += 1
	
	# Removes ellipse if there is no _CircularMovementObj
	if _circular_movement_objects.is_empty():
		_ellipse = null
	else:
		_ellipse.center = position
		_ellipse.amplitude = amplitude
		_ellipse.rotation = track_angle

func _draw() -> void:
	if !Engine.is_editor_hint():
		return
	
	draw_set_transform(Vector2.ZERO, -global_rotation, Vector2.ONE / global_scale)
	
	var sample_spots: PackedVector2Array = []
	for i in samples + 1:
		sample_spots.append(_get_point(i, samples))
	draw_polyline(sample_spots, Color.DARK_ORANGE, 4)
	
	var index: int = 0
	for j in items:
		if !j:
			index += 1
			continue
		elif !j.icon:
			index += 1
			continue
		draw_texture(j.icon, _get_point(index, items.size()) - j.icon.get_size() / 2)
		index += 1

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if preview_movement:
			queue_redraw()
			_rotate(delta)
		return
	
	var nulls: int = 0 # If no any items to move, then frees self.
	if nulls >= _circular_movement_objects.size():
		queue_free()
		return
	
	_rotate(delta)
	
	var index: int = 0
	
	for i in _circular_movement_objects:
		if !is_instance_valid(i):
			i = null
			nulls += 1
			continue
		elif i is CircularMovementObject2D:
			index += 1
			continue
		
		i.position =_get_point(index, _circular_movement_objects.size())
		
		index += 1


func _rotate(delta: float) -> void:
	phase = wrapf(phase + frequency * delta, -PI, PI)
	track_angle = wrapf(track_angle + track_rotation_speed * delta, -PI, PI)

func _get_point(index: int, size: int) -> Vector2:
	return _ellipse.get_point(phase + index * (TAU / float(size)))
