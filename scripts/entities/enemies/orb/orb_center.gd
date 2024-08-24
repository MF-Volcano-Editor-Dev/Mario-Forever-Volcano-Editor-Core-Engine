@tool
extends Node2D

enum _OrbsPlacement {
	NONE,
	BAR,
	CIRCLE
}

@export_category("Orb")
@export var preview: bool:
	set = set_preview
@export var orb_prefix: StringName = &"Orb"
@export_group("Placement")
@export var orbs_placement: _OrbsPlacement = _OrbsPlacement.NONE:
	set = set_orbs_placement
@export_subgroup("Bar")
@export_range(0, 1, 0.1, "or_greater", "hide_slider", "suffix:px") var size: float = 32
@export_subgroup("Circle")
@export_range(-180, 180, 0.1, "radians_as_degrees") var initial_phase: float

var _orb_data: Array[OrbData]


func _enter_tree() -> void:
	for i in get_children(): # Reset the position of orbs to this object to makes their origin proper
		if !orb_prefix in i.name || !i is CircularMovementObject2D:
			continue
		i.position = Vector2.ZERO

func _process(delta: float) -> void:
	_run_orbs(delta)


func _run_orbs(delta: float) -> void:
	if !Engine.is_editor_hint():
		return
	
	if !get_child_count():
		return
	
	for i in get_children():
		if !orb_prefix in i.name || !i is CircularMovementObject2D:
			continue
		
		var orb := i as CircularMovementObject2D
		_update_orb_pos(orb)
		
		if !preview:
			continue
		
		var f := orb.frequency * delta
		var t := orb.track_rotation_speed * delta
		
		orb.phase = wrapf(orb.phase + f, -PI, PI)
		orb.track_angle = wrapf(orb.track_angle + t, -PI, PI)

func _update_orb_pos(orb: CircularMovementObject2D) -> void:
	var ang := orb.phase
	orb.position = Vector2(
		orb.amplitude.x * cos(ang),
		orb.amplitude.y * sin(ang)
	).rotated(orb.track_angle)


func set_preview(value: bool) -> void:
	if !Engine.is_editor_hint():
		return
	
	preview = value
	
	if !is_node_ready():
		await ready
	
	if preview:
		for i in get_children():
			if !orb_prefix in i.name || !i is CircularMovementObject2D:
				continue
			
			var orb := i as CircularMovementObject2D
			var tw: Tween = null
			
			if orb.amplitude_changing_speed > 0:
				# Average values
				var avr_amplitude := (absf(orb.amplitude_max.x - orb.amplitude.x) + absf(orb.amplitude_max.y - orb.amplitude.y)) / 2
				# Tween (Using average values)
				tw = i.create_tween().set_trans(i.amplitude_changing_mode).set_loops()
				tw.tween_property(i, ^"amplitude", i.amplitude_max, avr_amplitude / i.amplitude_changing_speed)
				tw.tween_property(i, ^"amplitude", orb.amplitude, avr_amplitude / i.amplitude_changing_speed)
			
			_orb_data.append(OrbData.new(orb, orb.phase, orb.track_angle, orb.amplitude, tw))
	else:
		var orbs := get_children()
		
		for j in orbs:
			if !orb_prefix in j.name || !j is CircularMovementObject2D:
				continue
			for k in _orb_data: # Iterates the orb datas to find matching one
				if k.orb != j: # Skip dismatched orb data
					continue
				for l in k.properties:
					j.set(l, k.properties[l])
			
			_update_orb_pos(j) # Moves the orb to the position before preview was turned on
		
		_orb_data.clear()


func set_orbs_placement(value: _OrbsPlacement) -> void:
	orbs_placement = value
	
	match orbs_placement:
		# Placement pattern: Bar
		_OrbsPlacement.BAR:
			var orbs_index := 1
			var phase := 0
			for i in get_children():
				if !orb_prefix in i.name || !i is CircularMovementObject2D:
					continue
				i.amplitude = Vector2(i.amplitude).normalized() * orbs_index * size
				# Records the phase of the first orb
				if orbs_index == 1:
					phase = i.phase
				# Then set other orbs' phases to the recorded one
				else:
					i.phase = phase
				orbs_index += 1
			print("[Orbs] Became an orbs bar")
		# Placement pattern: Circle
		_OrbsPlacement.CIRCLE:
			var orbs: Array[CircularMovementObject2D] = []
			for i in get_children():
				if !orb_prefix in i.name || !i is CircularMovementObject2D:
					continue
				orbs.append(i)
			for j in orbs:
				j.phase = initial_phase + orbs.find(j) * TAU / orbs.size()
			print("[Orbs] Became an orbs circle")
	
	orbs_placement = _OrbsPlacement.NONE


class OrbData:
	var orb: CircularMovementObject2D
	var tweener: Tween
	var properties: Dictionary = {
		phase = 0.0,
		track_angle = 0.0,
		amplitude = Vector2.ZERO,
	}
	
	func _init(p_orb: CircularMovementObject2D, phase: float, track_angle: float, amplitude: Vector2, p_tweener: Tween) -> void:
		orb = p_orb
		tweener = p_tweener
		properties.phase = phase
		properties.track_angle = track_angle
		properties.amplitude = amplitude
	
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			if is_instance_valid(tweener):
				print(tweener, "is deleted!")
				tweener.kill()
				tweener = null
