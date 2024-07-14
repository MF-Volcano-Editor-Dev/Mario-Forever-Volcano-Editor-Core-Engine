extends CanvasLayer

@onready var circle_trans_anim: AnimationPlayer = $TransCircle/TransAnim
@onready var circle_trans: ColorRect = $TransCircle

signal circular_trans_done ## Emitted when circular transmission is accomplished.


func trans_reset() -> void:
	circle_trans_anim.play(&"RESET")


func circle_transmission(canvas_position: Vector2, duration: float = 1, fade_in_or_fade_out: bool = true) -> void:
	var shader_material := circle_trans.material as ShaderMaterial
	var screen_size := circle_trans.get_viewport_rect().size
	shader_material.set_shader_parameter(&"screen_width", screen_size.x)
	shader_material.set_shader_parameter(&"screen_height", screen_size.y)
	shader_material.set_shader_parameter(&"center", canvas_position / screen_size)
	
	circle_trans_anim.play(&"circle_trans", -1, 1 / duration * (1 if fade_in_or_fade_out else -1), !fade_in_or_fade_out)
	await circle_trans_anim.animation_finished
	circle_trans_anim.play(&"RESET")
	circular_trans_done.emit()
