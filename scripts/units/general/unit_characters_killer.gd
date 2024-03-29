extends Node

## Kills a random character.
func kill_random() -> void:
	var characters: Array[Character] = Character.Getter.get_characters(get_tree())
	characters.pick_random().die()

## Kills all characters.
func kill_all_characters() -> void:
	var characters: Array[Character] = Character.Getter.get_characters(get_tree())
	for i in characters:
		i.die()
