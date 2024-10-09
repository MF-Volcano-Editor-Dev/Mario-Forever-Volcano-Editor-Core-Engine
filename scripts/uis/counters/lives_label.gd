@tool
extends "./scores_label.gd"


func _ready() -> void:
	amount = amount # Triggers setter to initialize its visual effect
	
	if Engine.is_editor_hint():
		return
	
	queue_redraw()
	
	_movement.call_deferred()
	
	if !change_relevant_data:
		return
	
	Character.Data.lives += amount
