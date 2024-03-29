extends "./enemy_death.gd"

@export_category("Bowser Death")
@export_group("Sounds", "sound_")
@export var sound_falling: AudioStream = preload("res://engine/assets/sounds/bowser_fall.wav")

@onready var _visible_on_screen: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var _gravity_scale: float = gravity_scale


func _ready() -> void:
	gravity_scale = 0

func _physics_process(_delta: float) -> void:
	calculate_gravity()
	calculate_damp()
	move_and_slide()


func _on_start_falling() -> void:
	gravity_scale = _gravity_scale
	
	await Sound.play_2d(sound_falling, self).finished
	
	while is_inside_tree() && _visible_on_screen.is_on_screen():
		await get_tree().physics_frame
	
	remove_from_group(&"boss_death")
	
	var tree := get_tree()
	if tree.get_nodes_in_group(&"boss").is_empty() && tree.get_nodes_in_group(&"boss_death").is_empty():
		Events.EventGame.complete_level(tree, [Character.Getter.get_nearest(tree, global_position)])
	elif !tree.get_nodes_in_group(&"boss").is_empty():
		Events.EventTimeDown.get_signals().time_down_resume.emit()
	
	queue_free()
