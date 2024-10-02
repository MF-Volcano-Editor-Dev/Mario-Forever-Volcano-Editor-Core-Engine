extends Area2D

signal checkpoint_checked ## Emitted when a character hits the checkpoint.
signal spawned_characters ## Emitted when the check point spawns characters.

@export_category("Check Point")
## ID of the check point.
@export_range(0, 1, 1, "or_greater") var id: int
## If [code]true[/code], all previous check points will be activated
## once this one gets activated at the beginning of the game
@export var auto_activated_once_checked: bool
@export_group("Sounds")
@export var sound_activate: AudioStream = preload("res://engine/assets/sounds/appear.wav")
@export var sounds_checkpoint: Array[AudioStream] = [
	preload("res://engine/assets/sounds/voice1.ogg"),
	preload("res://engine/assets/sounds/voice2.ogg"),
	preload("res://engine/assets/sounds/voice3.ogg"),
]

static var _current_checkpoint: int = -1
static var _checked_checkpoints: PackedInt32Array

var _activated: bool:
	set(value):
		_activated = true
		
		if !is_node_ready():
			await ready
		
		if _activated:
			_animation_swing.play(&"checked")
			_visible_enabler.enable_node_path = _visible_enabler.get_path_to(self)
		else:
			_animation_swing.play(&"RESET")
			_animation_effect.play(&"RESET")
			_visible_enabler.enable_node_path = ^"."

@onready var _animation_swing: AnimationPlayer = $AnimationSwing
@onready var _animation_effect: AnimationPlayer = $AnimationEffect
@onready var _visible_enabler: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D


func _ready() -> void:
	# Character touch
	body_entered.connect(_on_character_checked)
	
	# Clear data on level accomplishment
	Scenes.scene_changed.connect(_on_clear_data)
	Events.EventCharacter.get_signals().game_over.connect(_on_clear_data)
	
	# Activated when the register is checked and able to show activation animation
	if id in _checked_checkpoints && (auto_activated_once_checked || (!auto_activated_once_checked && id == _current_checkpoint)):
		_activated = true
		_animation_swing.play(&"checked")
	
	# Deferred call to spawn the character here
	(func() -> void:
		if id == _current_checkpoint:
			for i in Character.Getter.get_characters(get_tree()):
				i.global_position = global_position
			
			spawned_characters.emit()
	).call_deferred()


func _on_character_checked(body: Node2D) -> void:
	if id in _checked_checkpoints:
		return
	if !body is Character:
		return
	
	# Activates the check point
	if !_activated:
		Sound.play_1d(sound_activate, self)
		
		_activated = true
		_animation_effect.play(&"checked")
		
		get_tree().create_timer(1.5, false).timeout.connect(_sound)
		
		checkpoint_checked.emit()
	# Register the check point
	if !id in _checked_checkpoints:
		_checked_checkpoints.append(id)
	# Set the current check point
	_current_checkpoint = id


func _sound() -> void:
	Sound.play_1d(sounds_checkpoint.pick_random(), self)

func _on_clear_data() -> void:
	_current_checkpoint = -1
	_checked_checkpoints.clear()
