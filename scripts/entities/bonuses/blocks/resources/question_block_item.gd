class_name QuestionBlockItem extends Resource

## Resources contains an default item and fallback option for [QuestionBlock2D]
##
##

## Default item
@export var default: PackedScene
## Fallback item that takes the place of [member default] if it does not exist or the situation in the documentation of [member required_powerup_level] happens.
@export var fallback: PackedScene
## If [code]true[/code], the fallback item will appear when the character's powerup is not greater than this value
@export_range(-5, 5) var required_powerup_level: int = -5
## Icon to be shown in some of the bumpable blocks
@export var icon: Texture2D

## Returns default item, or fallback option if the fallback is triggered.
func get_item(body: Node2D) -> PackedScene:
	return fallback if body is Mario && body.get_current_powerup().powerup_level < required_powerup_level || !default else default
