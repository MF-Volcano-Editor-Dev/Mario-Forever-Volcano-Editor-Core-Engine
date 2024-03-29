extends "./enemy_death.gd"

signal lakitu_reborn ## Emitted when lakitu reborn

var last_one: bool


func rebirth_time_down(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout
	lakitu_reborn.emit()
	
	if last_one:
		queue_free()
