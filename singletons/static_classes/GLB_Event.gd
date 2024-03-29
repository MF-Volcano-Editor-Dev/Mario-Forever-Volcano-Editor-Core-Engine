class_name Events

## Static class that manages game events.
##
## Game events in this static class are stored in separate subclasses:[br]
## * [Events.EventCharacter]: Used to store events related to characters, like game over.[br]
## [br]
## To trigger a game event, you can call the relative method to activate it. 
## Sometimes the function requires a [SceneTree] to be passed in because this is not a singleton extending [Node].[br]
## Before the static signals being implemented, each subclass has, generally, a unique subclass as its signal controller to store the signals.
## To listen to a game event, call [code]get_signals()[/code] in respective subclass.
## [codeblock]
## # Here we take EventCharacter's game_over as an example:
## EventCharacter.get_signals().game_over.connect(...)
## [/codeblock]
## [br]
## [b]Caution:[/b] All events are applied for ONLY ONE SCENE in the runtime, and DO NOT try to make parallel levels in the same scene, which may break the event system!


## Subclass of [Events], which is used to manage the events related to characters, including game over and completion of a level.
##
## To listen to the signals, please call [method get_signals] and see [Events.EventCharacter.EventCharacterSignals]
class EventCharacter:
	## Subclass of [Events.EventCharacter] that helps store signals.
	class Signals:
		signal character_dead(id: int) ## Emitted when a characters dies.
		signal all_characters_dead ## Emitted when all characters are dead.
		signal game_over ## Emitted when event "game over" is triggered.
		signal character_on_starman ## Emitted when a character gets starman.
		signal character_off_starman ## Emitted when a character stops starman.
	
	static var _signals: Signals = Signals.new()
	
	## Notify that a character dies.[br]
	## This call will trigger the emission of [Events.EventCharacter.EventCharacterSignals.character_dead], and even [Events.EventCharacter.EventCharacterSignals.all_characters_dead] when all players are dead.
	static func notify_character_death(scene_tree: SceneTree, id: int) -> void:
		_signals.character_dead.emit(id)
		if Character.Getter.get_characters(scene_tree).is_empty():
			_signals.all_characters_dead.emit()
			EventTimeDown.get_signals().time_down_paused.emit()
			EventMusic.get_signals().music_all_stop.emit()
	
	## Triggers the event "current game over".[br]
	## [br]
	## [b]Note:[/b] "Current game over" means that all characters are dead in the level, which requires the level to restart and cost 1 life, or to show "GAME OVER" if the lives is 0.
	static func current_game_over(scene_tree: SceneTree) -> void:
		if !Character.Getter.get_characters(scene_tree).is_empty():
			return
		
		if Character.Data.lives > 0:
			Character.Data.lives -= 1
			Character.Data.death_counts += 1
			scene_tree.reload_current_scene.call_deferred()
		else:
			_signals.game_over.emit()
	
	## Returns [Events.EventCharacter.Signals]
	static func get_signals() -> Signals:
		return _signals

## Subclass of [Events], which is used to manage the events related to timer down.
##
## To listen to the signals, please call [method get_signals] and see [Events.EventTimeDown.Signals]
class EventTimeDown:
	## Subclass of [Events.EventTimeDown] that helps store signals.
	class Signals:
		signal time_down_paused ## Emitted when making the timer pause.
		signal time_down_resume ## Emitted when making the timer resume.
	
	static var _signals: Signals = Signals.new()
	
	## Returns [Events.EventTimeDown.Signals]
	static func get_signals() -> Signals:
		return _signals


class EventGame:
	## Subclass of [Events.EventTimeDown] that helps store signals.
	class Signals:
		signal completed_level ## Emitted when a level gets completed.
		signal completion_summary_triggered ## Emitted when a level is going to start summary during the process of completion. (Completion Stage 1)
		signal completion_accomplished ## Emitted when a level is accomplished. (Completion Stage 2)
	
	static var _signals: Signals = Signals.new()
	
	
	## Makes the level completed and removes the characters except the certain one(s).[br]
	## [br]
	## [b]Note 1:[/b] You need to pass in [param tree]([SceneTree]) to make sure the [param remove_character_exception] works as expected.[br]
	## [b]Note 2:[/b] This call will cause other characters disappear ([method Node.queue_free] is called) after a fading of 0.5s, so please ensure the level design is safe to this call.
	static func complete_level(tree: SceneTree = null, remove_character_exception: Array[Character] = []) -> void:
		if tree:
			for i in Character.Getter.get_characters(tree):
				if i in remove_character_exception:
					continue # Skips the ones in the exception
				i.remove_from_group(&"character")
				i.set_process(false)
				i.set_physics_process(false)
				var tw: Tween = i.create_tween()
				tw.tween_property(i, ^"modulate:a", 0, 0.5)
				tw.tween_callback(i.queue_free)
		
		_signals.completed_level.emit()
		EventMusic.get_signals().music_all_stop.emit()
	
	## Returns [Events.EventGame.Signals]
	static func get_signals() -> Signals:
		return _signals


class EventMusic:
	## Subclass that manages the events of music
	class Signals:
		signal music_all_stop ## Emitted when musics should stop
	
	static var _signals: Signals = Signals.new()
	
	## Returns [Events.EventMusic.Signals]
	static func get_signals() -> Signals:
		return _signals
