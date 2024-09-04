@tool
extends Node2D

var _font := ThemeDB.fallback_font
var _par: QuestionBlock2D


func _ready() -> void:
	if !Engine.is_editor_hint():
		get_parent().modulate.a = 1.0
		queue_free()
		return
	
	visibility_changed.connect(set_process.bind(visible))

func _draw() -> void:
	if !_par:
		return
	if _par.items.is_empty():
		return
	
	_par.modulate.a = 0.5 if !_par.block_visible else 1.0
	
	var first_item := _par.items[0]
	if !first_item:
		return
	
	draw_texture(first_item.icon, Vector2.ZERO)
	if first_item is QuestionBlockItemAbundant:
		match first_item.limitation:
			0: # Time limit
				draw_string(_font, Vector2(24, 24), str(first_item.time) + "sec", HORIZONTAL_ALIGNMENT_LEFT, -1, int(roundf(16 / scale.x)), Color.GOLD)
			1: # Amount limit
				draw_string(_font, Vector2(24, 24), str(first_item.amount) + "x", HORIZONTAL_ALIGNMENT_LEFT, -1, int(roundf(16 / scale.x)), Color.LAWN_GREEN)

func _process(_delta: float) -> void:
	if !_par:
		_par = get_parent() as QuestionBlock2D
	if !_par:
		return
	
	queue_redraw()
