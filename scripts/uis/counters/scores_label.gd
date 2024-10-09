@tool
extends "./counter_label.gd"

@export_category("Scores Label")
@export var change_relevant_data: bool = true


func _ready() -> void:
	amount = amount # Triggers setter to initialize its visual effect
	
	if Engine.is_editor_hint():
		return
	
	queue_redraw()
	
	_movement.call_deferred()
	
	if !change_relevant_data:
		return
	
	Character.Data.scores += amount
