extends Node2D

## A singleton used to safely changes the scene.
##
## Built-in functions of changing scenes does not support emission of an event that can be suscribed by other objects, which is an issue
## when some objects, like a checkpoint, needs to clear data when the scene gets changed.
## By calling methods in this singleton, the problems mentioned will be solved in a safe way.

signal scene_changed ## Emitted when the current scene is about to be changed, before the scene gets changed.


## Changes the scene to a certain scene, by passing in the path to it.
func change_scene_to_path(path: String, with_transmission: bool = true) -> void:
	scene_changed.emit()
	
	if with_transmission:
		Transmission.circle_transmission(get_viewport_rect().size / 2)
		await Transmission.circular_trans_done
	
	get_tree().change_scene_to_file(path)
	
	if with_transmission:
		Transmission.circle_transmission(get_viewport_rect().size / 2, 0.5, false)

## Changes the scene to a certain scene, by passing in a [PackedScene] that contains it.
func change_scene_to_packed(packed: PackedScene, with_transmission: bool = true) -> void:
	scene_changed.emit()
	
	if with_transmission:
		Transmission.circle_transmission(get_viewport_rect().size / 2)
		await Transmission.circular_trans_done
	
	get_tree().change_scene_to_packed(packed)
	
	if with_transmission:
		Transmission.circle_transmission(get_viewport_rect().size / 2, 0.5, false)

## Reloads current scene.[br]
## [br]
## [b]Note:[/b] This won't emit [signal scene_changed]!
func reload_current_scene(with_transmission: bool = false) -> void:
	if with_transmission:
		Transmission.circle_transmission(get_viewport_rect().size / 2)
		await Transmission.circular_trans_done
	
	get_tree().reload_current_scene()
	
	if with_transmission:
		Transmission.circle_transmission(get_viewport_rect().size / 2, 0.5)

## Unloads current scene.[br]
## [br]
## [b]Note:[/b] This won't emit [signal scene_changed]!
func unload_current_scene(with_transmission: bool = false) -> void:
	if with_transmission:
		Transmission.circle_transmission(get_viewport_rect().size / 2)
		await Transmission.circular_trans_done
	
	get_tree().unload_current_scene()
	
	if with_transmission:
		Transmission.circle_transmission(get_viewport_rect().size / 2, 0.5)
