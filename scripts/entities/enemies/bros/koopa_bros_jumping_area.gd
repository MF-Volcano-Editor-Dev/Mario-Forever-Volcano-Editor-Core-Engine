@tool
extends Area2D

const _KoopaBros := preload("./koopa_bros.gd")
const _Font: FontFile = preload("res://engine/assets/fonts/hud_font.png")

@export_category("Koopa Bros Jumping Area")
@export var mode: _KoopaBros.JumpingMode = _KoopaBros.JumpingMode.UP_AND_DOWN as _KoopaBros.JumpingMode: 
	set(value):
		mode = value
		if !Engine.is_editor_hint():
			return
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	body_entered.connect(_on_bro_interacts_with_area.bind(true))
	body_exited.connect(_on_bro_interacts_with_area.bind(false))


func _draw() -> void:
	if !Engine.is_editor_hint():
		return
	
	draw_set_transform(Vector2.ZERO, -global_rotation, Vector2.ONE / global_scale)
	
	var text: String
	match mode:
		_KoopaBros.JumpingMode.UP_AND_DOWN:
			text = "UP & DOWN"
		_KoopaBros.JumpingMode.UP:
			text = "UP"
		_KoopaBros.JumpingMode.DOWN:
			text = "DOWN"
	draw_string(_Font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_CENTER)


func _on_bro_interacts_with_area(body: Node2D, in_or_out: bool) -> void:
	if !body is _KoopaBros:
		return
	
	var bro := body as _KoopaBros
	bro.jumping_mode = mode if in_or_out else _KoopaBros.JumpingMode.NONE
