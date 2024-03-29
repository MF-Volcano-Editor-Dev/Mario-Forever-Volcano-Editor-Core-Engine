extends Walker2D

@export_category("Enemy Death Entity")
@export_range(0, 10, 0.001, "suffix:s") var disappear_delay: float = 2.5


func _ready() -> void:
	super()
	
	# Disappearance
	get_tree().create_timer(disappear_delay, false).timeout.connect(func() -> void:
		var tw: Tween = create_tween()
		tw.tween_property(self, ^"modulate:a", 0, 0.2)
		await tw.finished
		queue_free()
	)
