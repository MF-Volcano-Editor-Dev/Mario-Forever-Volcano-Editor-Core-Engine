class_name AreaClimbable extends Area2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is Character:
		body.add_to_group(&"state_climbable")

func _on_body_exited(body: Node2D) -> void:
	if body is Character:
		body.remove_from_group(&"state_climbable")
		body.remove_from_group(&"state_climbing")
