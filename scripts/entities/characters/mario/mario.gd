class_name Mario extends Character

## Character that behaves similarly to Mario.
##
## [Mario] here is not a specific character, but a type of characters that behaves similar to Mario.
## You can specify a powerup that makes the character be in such suit and get powerful skills.

signal on_starman(duration: float) ## Emitted when the character gets into starman state.
signal damaged ## Emitted when the character gets hurt.
signal died ## Emitted when the charcter dies.

const _MarioDeath: Script = preload("./mario_death.gd")

## Id of current powerup.[br]
## [br]
## [b]Note:[/b] This will automatically set the powerup of the mario to one that contains the same [member current_powerup] matched.
## If a dismatched powerup id is set, some unexpected behaviors would happen, so please ensure this value valid in terms of existing powerups.
@export var current_powerup: StringName = &"small":
	set = set_powerup
## If [code]true[/code], the powerup will not play [code]&"appear"[/code] animation.[br]
## If [member current_powerup] is invalid, nothing is going to happen.
@export var no_appearing_animation_when_ready: bool = true
@export_group("Sounds", "sound_")
@export var sound_starman: AudioStream = preload("res://engine/assets/sounds/starman.ogg")

@onready var _death: _MarioDeath = $MarioDeath # Death effect of the character 

var _powerup: MarioPowerup # Current powerup
var _invulnerablity_counter: SceneTreeTimer # Invulerability time counter


func _ready() -> void:
	super()
	
	current_powerup = current_powerup # Triggers "set_powerup" to set initial powerup
	
	Events.EventGame.get_signals().completed_level.connect(add_to_group.bind(&"state_completed")) # Level completion


#region == Setgets ==
func set_powerup(value: StringName) -> void:
	if !is_node_ready(): # To make sure the powerup is safely got
		current_powerup = value
		return
	
	var matched_powerup: bool = false
	for i in get_children():
		if !i is MarioPowerup:
			continue
		
		i = i as MarioPowerup # To get code hints
		if i.powerup_id == value:
			current_powerup = value
			i.visible = true
			i.process_mode = PROCESS_MODE_INHERIT # Activates the process of target powerup
			i._powerup_entered()
			no_appearing_animation_when_ready = false
			_powerup = i
			matched_powerup = true
		else:
			i.visible = false
			i.process_mode = PROCESS_MODE_DISABLED # Deactivates the process of other powerups
			i._powerup_exited()
	if !matched_powerup:
		_powerup = null
#endregion

#region == Status Control ==
## Makes the character invulerable from the damage by enemies.
func invulnerablize(duration: float = 2) -> void:
	_invulnerablity_counter = get_tree().create_timer(duration, false)
	_invulnerablity_counter.timeout.connect(func() -> void:
		await get_tree().create_timer(0.075, false).timeout # Used to ensure that the alpha is properly reset
		_invulnerablity_counter = null
	)
	Effects.flash(self, duration)

## Makes the character a starman.
func starman(duration: float = 10) -> void:
	invulnerablize(duration)
	on_starman.emit(duration)
	
	add_to_group(&"state_starman") # Tags the character as being starman
	
	var snd := Sound.play_1d(sound_starman, self)
	get_tree().create_timer(duration - 2, false).timeout.connect(func() -> void:
		var tw := snd.create_tween()
		tw.tween_property(snd, ^"volume_db", -50, 2)
		tw.finished.connect(snd.queue_free)
		await tw.finished
		
		remove_from_group(&"state_starman") # Removes the tag of starman
		
		await get_tree().process_frame # To make sure all characters have got that tag removed
		
		var chrs: Array[Character] = Character.Getter.get_characters(get_tree())
		var chrs_off_starman: int = 0 # Checks the amount of characters with starman tag
		for i in chrs:
			if i is Mario && i.is_in_group(&"state_starman"):
				chrs_off_starman += 1
		if chrs_off_starman == 0: # As long as there is no character with that tag, it will be regarded as the status of "character_off_starman"
			Events.EventCharacter.get_signals().character_off_starman.emit()
	)
	
	Events.EventCharacter.get_signals().character_on_starman.emit()

## Makes the character hurt.[br]
## By default, this call will be blocked if [param forced] is [code]false[/code] while the character has been invulnerable.[br]
## If [param invincibility] is passed in with [code]false[/code], the character won't be invulnerable because of this call.[br]
## [param override_down_to] can be set to non-empty values, but needs to be a valid id of existing powerups for the character.
func hurt(duration: float = 2, forced: bool = false, invincibility: bool = true, override_down_to: StringName = &"") -> void:
	if is_in_group(&"state_frozen"):
		return
	if !forced && is_invulnerable():
		return
	if !_powerup:
		return
	
	if !override_down_to.is_empty():
		Sound.play_2d(_powerup.sound_hurt, self)
		current_powerup = override_down_to
	elif !_powerup.down_to_powerup_id.is_empty():
		Sound.play_2d(_powerup.sound_hurt, self)
		current_powerup = _powerup.down_to_powerup_id
	else:
		die()
		return
	
	if invincibility:
		invulnerablize(duration)
	
	damaged.emit()

## Makes the character die.
func die() -> void:
	if is_in_group(&"state_frozen"):
		return
	
	_death.visible = true
	
	if _powerup:
		_death.sound_death = _powerup.sound_death
		_death.process_mode = Node.PROCESS_MODE_INHERIT
	
	(func() -> void:
		_death.reparent(get_parent())
		_death.death_effect_start()
	).call_deferred()
	
	remove_from_group(&"character")
	queue_free()
	
	died.emit()

## Returns [code]true[/code] if the character is in starman status
func is_starman() -> bool:
	return false

## Returns [code]true[/code] if the character is invulnerable.
func is_invulnerable() -> bool:
	return is_instance_valid(_invulnerablity_counter)
#endregion

#region == Signal Methods ==
# Connected by VisibleOnScreenNotifierDirectional2D.screen_exited_directional
func _on_falling_to_death() -> void:
	if !falling_to_death:
		return
	die()
#endregion


#region == General Getters ==
## Returns the current powerup
func get_current_powerup() -> MarioPowerup:
	return _powerup if is_instance_valid(_powerup) else null
#endregion
