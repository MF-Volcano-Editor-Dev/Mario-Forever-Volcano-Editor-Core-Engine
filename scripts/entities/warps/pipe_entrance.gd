extends Area2D

const _Exit: Script = preload("./pipe_exit.gd")

@export_category("Pipe Entrance")
@export_group("Warp")
## If [code]true[/code], you can preview the effect.
@export var preview: bool
## Path to the exit node
@export_node_path("Area2D") var exit_path: NodePath
## Direction of warping in
@export_enum("Up", "Down", "Left", "Right") var direction: int = 1
## Waypoints during the transmission
@export var waypoints: Array[Marker2D]
@export_group("Special Settings")
## If [code]true[/code], when a character enters the pipe, the level is regarded as completed.
@export var as_goal: bool
## If this is set to a valid scene, then the game will jump into it.
@export_file("*.tscn") var to_scene: String
@export_group("Effects")
## If [code]true[/code], then there will be a transmission between the completion of entering the pipe and the beginning of exiting from the pipe.
@export var transmission: bool
@export_group("Sounds", "sound_")
@export var sound_pipe: AudioStream = preload("res://engine/assets/sounds/power_down.wav")

@onready var _exit: _Exit = get_node_or_null(exit_path)

var _characters: Array[Character]


func _ready() -> void:
	visible = false
	# Registering a character when it enters
	body_entered.connect(func(body: Node2D) -> void:
		if body is Character && !body in _characters:
			_characters.append(body)
	)
	# Unregistering the character when it leaves
	body_exited.connect(func(body: Node2D) -> void:
		if body is Character && body in _characters:
			_characters.erase(body)
	)

func _process(_delta: float) -> void:
	for i in _characters:
		var key_dir := i.get_udlr_directions(&"left", &"right", &"up", &"down")
		if (key_dir.y < 0 && direction == 0) || \
			(key_dir.y > 0 && direction == 1) || \
			(key_dir.x < 0 && direction == 2) || \
			(key_dir.x > 0 && direction == 3):
				_entrance(key_dir, i)
				set_process(false) # To prevent holding key that leads to repeated calls
				break

func _entrance(key_dir: Vector2i, character: Character) -> void:
	var chrs: Array[Character] = Character.Getter.get_characters(get_tree())
	var down := _get_down()
	
	for i in chrs:
		i.velocity = Vector2.ZERO
		i.global_position = character.global_position
		i.z_index -= 2
		# Freezes the character
		i.add_to_group(&"state_frozen")
		# Defines animation direction
		if key_dir.x != 0: 
			i.add_to_group(&"state_pipe_h")
		if key_dir.y != 0:
			i.add_to_group(&"state_pipe_v")
		
		# Slide the character to the proper place
		var tw := i.create_tween()
		var target_pos := global_position if i.is_in_group(&"state_pipe_h") else i.global_position + (global_position - i.global_position).project(down.orthogonal())
		tw.tween_property(i, ^"global_position", target_pos, 0.1)
		# Moving the character
		tw.tween_callback(Sound.play_2d.bind(sound_pipe, self))
		tw.tween_method(i.set_global_position, target_pos, global_position + (64 if i.is_in_group(&"state_pipe_v") else 32) * down, 1.2)
	
	await get_tree().create_timer(1.3, false).timeout
	
	# Waypoint, and chrs[0] is moved while others are repositioned
	if !waypoints.is_empty():
		for i in chrs:
			var tw: Tween = null
			for j in waypoints:
				tw = i.create_tween()
				tw.tween_callback(i.hide)
				tw.tween_property(i, ^"global_position", j.global_position, 0.5)
				await tw.finished
				i.show()
	
	# Transmission
	var canvas_pos := chrs[0].get_global_transform_with_canvas().get_origin()
	if transmission:
		Transmission.circle_transmission(canvas_pos, 0.75)
		await Transmission.circular_trans_done
	
	# Special settings
	if as_goal:
		Events.EventGame.complete_level(get_tree())
		return
	if to_scene:
		get_tree().change_scene_to_file(to_scene)
		return
	
	_warp(chrs)
	
	set_process(true)


func _warp(characters: Array[Character]) -> void:
	if !_exit:
		return
	for i in characters:
		i.remove_from_group(&"state_pipe_h")
		i.remove_from_group(&"state_pipe_v")
		_exit.exit(i)


func _get_down() -> Vector2:
	return Vector2.DOWN.rotated(global_rotation)
