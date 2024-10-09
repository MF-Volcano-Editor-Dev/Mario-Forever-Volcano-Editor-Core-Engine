@tool
extends Node2D

@export_category("Counter")
## Number to display
@export var amount: int:
	set(value):
		amount = value
		
		text = str(amount) + str(suffix)
		modulate = Color.WHITE
		
		if amount < 0:
			text = text.replacen("-", "") + str(suffix)
			modulate = Color(1, 0.25, 0, modulate.a)
		
		queue_redraw()
## Suffix of the number to display
@export_placeholder("Suffix") var suffix: String:
	set(value):
		suffix = value
		amount = amount # Triggers the setter of `amount` to update the text
@export_group("Font")
@export var font: Font
@export_range(0, 20, 0.01, "or_greater", "suffix:px") var char_average_weight: float = 8
@export_group("Sound")
@export var sound_appear: AudioStream

var text: String


func _ready() -> void:
	amount = amount # Triggers setter to initialize its visual effect
	
	if Engine.is_editor_hint():
		return
	
	_movement.call_deferred()
	
	queue_redraw()

func _draw() -> void:
	if !font:
		return
	
	draw_string(font, -Vector2(160, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 320)


func _movement() -> void:
	rotation = 0 # Reset rotation of label
	
	Sound.play_2d(sound_appear, self)
	
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, ^"position", position + 64 * Vector2.UP, 0.75)
	tw.tween_interval(0.5)
	tw.tween_property(self, ^"modulate:a", 0, 0.25)
	
	await tw.finished
	queue_free()
