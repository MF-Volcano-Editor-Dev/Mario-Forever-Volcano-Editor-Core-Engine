extends Area2D

signal item_got ## Emitted when a character gets the item.

@export_category("Starman")
## Duration of starman status.
@export_range(0, 2400, 0.001, "suffix:s") var starman_duration: float = 10
@export_group("Sounds", "sound_") 
@export var sound_item: AudioStream = preload("res://engine/assets/sounds/power_up.wav")

func _ready() -> void:
	body_entered.connect(func(body: Node2D) -> void:
		if body is Mario:
			Sound.play_2d(sound_item, self)
			body.starman(starman_duration)
			item_got.emit()
	)
