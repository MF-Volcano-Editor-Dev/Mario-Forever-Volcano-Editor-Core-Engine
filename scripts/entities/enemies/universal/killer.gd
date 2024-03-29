extends Area2D

signal killed_character ## Emitted when the area kills a [Character].


func _ready() -> void:
	body_entered.connect(func(body: Node2D) -> void:
		if body is Character:
			body.die()
			killed_character.emit()
	)
