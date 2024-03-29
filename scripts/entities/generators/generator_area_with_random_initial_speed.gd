@tool
extends GeneratorArea2D

@export_category("GeneratorRandomArea2D")
@export_group("Randomness")
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var initial_speed: float = 304
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px/s") var initial_speed_extra: float = 400
@export_range(0, 90, 0.001, "degrees") var velocality_angle_min: float = 30
@export_range(0, 90, 0.001, "degrees") var velocality_angle_max: float = 78


func _on_generating() -> void:
	Sound.play_1d(sound_generating, self)
	
	for i in generating_amount:
		for j in _instantiater.instantiate_all():
			j.global_position = get_viewport_transform().affine_inverse() * Vector2(
				randf_range(generation_margin.position.x, generation_margin.end.x),
				randf_range(generation_margin.position.y, generation_margin.end.y)
			)
			if j is EntityBody2D:
				(func() -> void:
					var vel := randf_range(initial_speed, initial_speed + initial_speed_extra) * Vector2.RIGHT.rotated(deg_to_rad(-randf_range(velocality_angle_min, velocality_angle_max)))
					vel.x *= Transform2DAlgo.get_direction_to_regardless_transform(j.get_global_transform_with_canvas().get_origin(), get_viewport_rect().size / 2, get_viewport_transform())
					j.velocality = vel
				).call_deferred()
	
	generated.emit()
	
	_timer_interval.start(_get_rand(generating_interval, generating_interval_extra))
