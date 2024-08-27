@tool
extends "./scores_label.gd"


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_movement.call_deferred()
	
	if !change_relevant_data:
		return
	
	Character.Data.lives += amount
