extends "./mario_non_climbing.gd"

@export_category("Character Projectile")
## Path to instantiater to create projectile
@export_node_path("Instantiater2D") var projectile_instantiater_path: NodePath = ^"../../Projectile"
## Id of the projectile.[br]
## [br]
## [b]Note:[/b] Please keep the value of this variable different from this of each powerup.
@export var projectile_id: DataList.AttackId = DataList.AttackId.FIREBALL
## Maximum of the projectile amount. See [member projectile_id].
@export_range(0, 20) var projectile_max_amount: int = 2
@export_group("Sound", "sound_")
@export var sound_projectile: AudioStream = preload("res://engine/assets/sounds/shoot.wav")

@onready var _projectile_instantiater: Instantiater2D = get_node(projectile_instantiater_path)


func _state_process(delta: float) -> void:
	super(delta)
	
	if _character.is_in_group(&"state_frozen"):
		return
	if _character.is_in_group(&"state_crouching"):
		return
	if _character.is_in_group(&"state_completed"):
		return
	if !_character.get_input_just_pressed(&"fire"):
		return
	
	var projectile_group: StringName = _character.name + str(_character.id) + str(projectile_id)
	if get_tree().get_nodes_in_group(projectile_group).size() >= projectile_max_amount:
		return
	
	Sound.play_2d(sound_projectile, _character)
	
	_animated_sprite.play(&"attack")
	
	var projectiles: Array[CanvasItem] = _projectile_instantiater.instantiate_all()
	
	(func() -> void:
		for i in projectiles:
			i.add_to_group(projectile_group)
			if i is EntityBody2D:
				i.velocality.x = absf(i.velocality.x) * _character.direction
	).call_deferred()
