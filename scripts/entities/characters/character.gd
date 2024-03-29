@icon("res://icons/character_entity_2d.svg")
class_name Character extends EntityBody2D

## Abstract class of controllable characters
##
## This class provides [member id] that is necessary for each character. In general situation, you can regard this class as a codical group of characters, which helps provide type hints so that it can improve your development efficiency a bit.[br]
## To get the character(s) with condition or not, it also provides [Character.Getter] got by calling [method get_character_getter], which contains several methods that allow you to get the character(s) by such way(s).
## [br]
## [b]Note:[/b] To make the [Character.Getter] work, you must set the character to the group [i]character[/i].

## Id of the character.[br]
## [br]
## [b]Note:[/b] Each character has different ids, and the characters with the same id will be considered as the same character and lead to problems.
@export_range(0, 3) var id: int
@export var nickname: StringName = &"Player"
@export_group("Physics", "physics_")
@export_enum("Left:-1", "Right:1") var direction: int = 1:
	set(value):
		direction = value
		if !direction: # No zero direction
			direction = [-1, 1].pick_random()
@export_group("Hitbox")
## Offset of hitbox center. Useful for some detections like one in [EnemyStompable].
@export var center_offset: Vector2 = Vector2(0, -4)
@export_group("Status")
## If true, the character will fall to death.[br]
## [br]
## [b]Note:[/b] This is only a switch to control falling to death, and requires manual implementation by code.
@export var falling_to_death: bool = true


func _ready() -> void:
	# Restores death count on game over
	if !Events.EventCharacter.get_signals().game_over.is_connected(Data.restore_death_count):
		Events.EventCharacter.get_signals().game_over.connect(Data.restore_death_count)


## [code]abstract[/code] Makes the character hurt.
func hurt() -> void:
	pass

## [code]abstract[/code] Makes the character die.
func die() -> void:
	pass

## Returns the global position of the body's center.[br]
## [br]
## The center of body is determined by [member Node2D.global_position] - [method CharacterBody2D.get_position_delta] + [member center_offset].rotated([member Node2D.global_rotation]).
func get_center() -> Vector2:
	return global_position - get_position_delta() + center_offset.rotated(global_rotation)


#region == Getters ==
## Returns an [param action] with [member id].[br]
## E.g.: If an [param action] is [code]&"jump"[/code] and the [member id] is 0, the returned value is to be [code]&"jump0"[/code].[br]
## [b]Tip:[/b] This is very useful when other scripts have to get access to the control status of the character.
func get_input_identifier(action: StringName) -> StringName:
	return action + str(id)

## Returns [code]true[/code] if the [param action] processed by [method get_input_identifier] is pressed.[br]
## This means that if you pass in an [param action] named [code]&"jump"[/code] and the [member id] is 0, this method is actually to detect if the action [code]&"jump0"[/code] is pressed.
func get_input_pressed(action: StringName) -> bool:
	return Input.is_action_pressed(get_input_identifier(action))

## Similar to [method get_input_pressed], but only the first time the key is pressed can this method returns [code]true[/code],
## while a [code]false[/code] is to be returned if the player keeps holding that action.
func get_input_just_pressed(action: StringName) -> bool:
	return Input.is_action_just_pressed(get_input_identifier(action))

## Similar to [method get_input_pressed], but only when the key gets released from being held can this method returns [code]true[/code];
## otherwise a [code]false[/code] is to be returned.
func get_input_just_released(action: StringName) -> bool:
	return Input.is_action_just_released(get_input_identifier(action))

## Returns a [Vector2i] which records the direction of four actions: [param left], [param right], [param up], and [param down].[br]
## [br]
## [b]Note:[/b] The [i]X[/i] component of the vector is left(-1) or right(1), while the [i]Y[/i] component signs up(-1) or down(1).
func get_udlr_directions(left: StringName, right: StringName, up: StringName, down: StringName) -> Vector2i:
	return Vector2i(
		Input.get_vector(
			get_input_identifier(left),
			get_input_identifier(right),
			get_input_identifier(up),
			get_input_identifier(down),
		).round()
	)
#endregion


## A subclass that stores the data of characters
##
## The subclass contains another subclass which is used to emit signals, so that you can connect it with the functions in other objects to make them
## listen to the update of the data, because each data has a setter that emits signal when it gets updated.
class Data:
	## Help with emitting the signal of [Character.Data]
	##
	## Due to lack of supporting static signals, this is currently applied for such functionality and will be removed once that feature gets implemented in Godot.
	class DataSignal:
		## Type of value to be emitted
		enum Value {
			LIVES,
			SCORES,
			COINS,
			TOTAL_COINS,
			DEATH_COUNTS
		}
		
		signal data_updated(type: Value, value: Variant) ## Emitted when the data gets updated
	
	static var _signals: DataSignal = DataSignal.new()
	
	## Lives of all characters.
	static var lives: int = ProjectSettings.get_setting("game/data/player/default_lives", 4):
		set(value):
			lives = maxi(0, value)
			_signals.data_updated.emit(DataSignal.Value.LIVES, lives)
	## Scores of all characters.
	static var scores: int:
		set(value):
			scores = maxi(0, value)
			_signals.data_updated.emit(DataSignal.Value.SCORES, scores)
	## Coins of all characters.[br]
	## [br]
	## [b]Note:[/b] This can be reverted to 0 by external functions. If you want to get ones that won't get reverted, see [member total_coins].
	static var coins: int:
		set(value):
			total_coins += value - coins
			coins = maxi(0, value)
			_signals.data_updated.emit(DataSignal.Value.COINS, coins)
	## Total coins of all characters.[br]
	## [br]
	## [b]Note:[/b] This should NOT be reverted to 0 by external functions. If you want to get ones reverted, see [member coins].
	static var total_coins: int:
		set(value):
			total_coins = maxi(0, value)
			_signals.data_updated.emit(DataSignal.Value.TOTAL_COINS, total_coins)
	## Death counts of all characters.[br]
	## [br]
	## [b]Note:[/b] This value [u]should be reverted to 0[/u] after confirmation in game over screen.
	static var death_counts: int:
		set(value):
			death_counts = maxi(0, value)
			_signals.data_updated.emit(DataSignal.Value.DEATH_COUNTS, death_counts)
	
	
	## Initialization for each data.
	static func init_data() -> void:
		lives = lives
		scores = scores
		coins = coins
		total_coins = total_coins
		death_counts = death_counts
	
	## Returns an object that helps emit signals when the values in this object gets updated.
	static func get_signals() -> DataSignal:
		return _signals
	
	
	## Restores death count
	static func restore_death_count() -> void:
		death_counts = 0
	
	## Restores all data
	static func restore_all_data() -> void:
		lives = ProjectSettings.get_setting("game/data/player/default_lives", 4)
		coins = 0
		scores = 0
		death_counts = 0


## A subclass that allows you to get characters.
##
## [b]Note:[/b] The methods in this subclass are required to be passed in a param of [SceneTree] type. So if the caller is a node, then the param can be [method get_tree].
class Getter:
	## Returns an [Array] with [Character]s.
	static func get_characters(scene_tree: SceneTree) -> Array[Character]:
		var result: Array[Character] = []
		
		for i in scene_tree.get_nodes_in_group(&"character"):
			if i is Character:
				result.append(i)
		
		return result
	
	## Returns a character with given [param character_id]. See [member Character.id].
	static func get_character(scene_tree: SceneTree, character_id: int) -> Character:
		var characters := get_characters(scene_tree)
		
		for i in characters:
			if i.id != character_id:
				continue
			return i
		
		return null
	
	## Returns a character nearest to [param to_gpos].
	static func get_nearest(scene_tree: SceneTree, to_gpos: Vector2) -> Character:
		var characters := get_characters(scene_tree)
		var distances: Array[float] = [] # The packed array doesn't support max() nor min()
		
		for i in characters:
			distances.append(i.global_position.distance_squared_to(to_gpos))
		
		if distances.is_empty():
			return null
		
		return characters[distances.find(distances.min())]
	
	## Returns a character farest from [param to_gpos].
	static func get_farest(scene_tree: SceneTree, to_gpos: Vector2) -> Character:
		var characters := get_characters(scene_tree)
		var distances: Array[float] = [] # The packed array doesn't support max() nor min()
		
		for i in characters:
			distances.append(i.global_position.distance_squared_to(to_gpos))
		
		if distances.is_empty():
			return null
		
		return characters[distances.find(distances.max())]
	
	## Returns character(s) by random [param amount].
	static func get_random(scene_tree: SceneTree, amount: int) -> Array[Character]:
		var characters := get_characters(scene_tree)
		var result: Array[Character] = []
		
		for i in amount:
			result.append(characters.pop_at(characters.size() - 1))
		
		return result
	
	## Returns the average global position of characters.[br]
	## If no characters available, the [param default] will be returned.
	static func get_average_global_position(scene_tree: SceneTree, default: Vector2 = Vector2.ZERO) -> Vector2:
		var characters := get_characters(scene_tree)
		if characters.is_empty():
			return default
		
		var result: Vector2 = Vector2.ZERO
		for i in characters:
			result += i.global_position
		
		return result / float(characters.size())
	
	## Returns the average canvas position of characters. Similar to [method get_average_global_position].
	static func get_average_canvas_position(scene_tree: SceneTree, default: Vector2 = Vector2.ZERO) -> Vector2:
		var characters := get_characters(scene_tree)
		if characters.is_empty():
			return default
		
		var result: Vector2 = Vector2.ZERO
		for i in characters:
			result += i.get_global_transform_with_canvas().get_origin()
		
		return result / float(characters.size())


## A subclass used for checking something in terms of [Character].
##
## [b]Note:[/b] Some of methods in this subclass are required to be passed in a param of [SceneTree] type. So if the caller is a node, then the param can be [method get_tree].
class Checker:
	## Returns [code]true[/code] if a node [param to_be_checked] is an available instance of [Character].
	static func is_character(to_be_checked: Node2D) -> bool:
		return is_instance_valid(to_be_checked) && to_be_checked is Character && to_be_checked.is_in_group(&"character")
