class_name ItemPowerup2D extends Area2D

## Used to be touched by [Mario] to give the instance a powerup
##
##

signal powerup_got ## Emitted when the powerup is got by [Mario].

## If the [member MarioPowerup.powerup_level] of [Mario]'s current powerup is greater than this value,
## the character will turn into [member default_powerup]; other wise [member fallback_powerup] will be transformed into.
@export_range(-5, 5) var requirement_powerup_level: int
## Id of default powerup. See [member requirement_powerup_level].
@export var default_powerup: StringName
## Id of fallback powerup. See [member requirement_powerup_level].
@export var fallback_powerup: StringName
## Enables force powerup mode, in which the [member requirement_powerup_level] is ignored when the character gets the powerup
## and [member default_powerup] will be given if it is not empty; othersie, [member fallback_powerup] will be given.
@export var forced_powerup: bool
@export_group("Sounds", "sound_")
@export var sound_item: AudioStream = preload("res://engine/assets/sounds/power_up.wav")


func _ready() -> void:
	body_entered.connect(_on_character_powered)


func _on_character_powered(body: Node2D) -> void:
	var chr := body as Mario
	if !chr:
		return
	
	if forced_powerup:
		if fallback_powerup.is_empty():
			return
		elif default_powerup.is_empty():
			chr.current_powerup = fallback_powerup
		else:
			chr.current_powerup = default_powerup
	else:
		var pw := chr.get_current_powerup()
		if pw.powerup_level >= requirement_powerup_level && !default_powerup.is_empty() && chr.current_powerup != default_powerup:
			chr.current_powerup = default_powerup
		elif pw.powerup_level < requirement_powerup_level && !fallback_powerup.is_empty() && chr.current_powerup != fallback_powerup:
			chr.current_powerup = fallback_powerup
		
		Sound.play_2d(sound_item, self)
		
		powerup_got.emit()
