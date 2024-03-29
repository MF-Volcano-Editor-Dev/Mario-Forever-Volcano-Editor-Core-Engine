extends Walker2D

## Shell
##
## Needs [code]shell_kickable[/code] group set for characters to make them able to interact with the shell.

signal shell_moved ## Emitted when the shell is kicked by a body.
signal shell_stopped ## Emitted when the shell stops.

@export_category("Shell")
## If [code]true[/code], the shell will move
@export var moving: bool:
	set(value):
		moving = value
		
		if !is_node_ready():
			await ready
		
		(func() -> void:
			# Speed
			if !moving: # Stop
				velocality.x = 0
			else: # Run
				velocality.x = _speed
			
			# Compoenents
			_attacker.id = DataList.AttackId.SHELL if moving else DataList.AttackId.NONE
			if !moving:
				shell_stopped.emit()
				
				_enemy_stompable.stompable = false
				_enemy_stompable.character_damagible = false
			else:
				shell_moved.emit()
				
				_enemy_stompable.stompable = true
				await get_tree().create_timer(0.3, false).timeout
				_enemy_stompable.character_damagible = true
		).call_deferred()
@export_group("References")
## Path to the effect box ([Area2D])
@export_node_path("Area2D") var effect_box_path: NodePath = ^"EffectBox"
## Path to the attacker component
@export_node_path("Attacker") var attacker_path: NodePath = ^"EffectBox/Attacker"
## Path to the enemy stompable component
@export_node_path("EnemyStompable") var enemy_stompable_path: NodePath = ^"EffectBox/EnemyStompable"
@export_group("Sounds", "sound_")
@export var sound_kick: AudioStream = preload("res://engine/assets/sounds/kick.wav")

@onready var _effect_box: Area2D = get_node(effect_box_path)
@onready var _attacker: Attacker = get_node(attacker_path)
@onready var _enemy_stompable: EnemyStompable = get_node(enemy_stompable_path)

@onready var _speed: float = absf(velocality.x)


func _ready() -> void:
	super()
	
	moving = moving # Triggers setter to initialize behavior
	
	_effect_box.monitoring = false
	await get_tree().create_timer(0.1, false).timeout
	_effect_box.monitoring = true


func _on_shell_stomp_succeeded(body: PhysicsBody2D) -> void:
	if !moving:
		return
	if !body.is_in_group(&"shell_kickable"):
		return
	moving = false

func _on_shell_kicked(body: PhysicsBody2D) -> void:
	if moving:
		return
	if !body.is_in_group(&"shell_kickable"):
		return
	
	Sound.play_2d(sound_kick, self)
	
	moving = true
	
	initial_direction = InitDirection.BACK_TO_PLAYER
	initialize_direction.call_deferred()
