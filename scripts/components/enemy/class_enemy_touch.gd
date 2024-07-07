@tool
@icon("res://engine/icons/enemy_touch.svg")
class_name EnemyTouch extends Component

## Component used for [Area2D] to provide collision interaction with other objects that is interactable with this component (touchers). 
## 
## If the toucher is character, this will damage him/her as if the character got hit by an enemy.
## This component needs an [Area2D] to react as the hitbox of an enemy. 

signal on_touched_by(toucher: PhysicsBody2D) ## Emitted when a toucher touches the [member Component.root] ([Area2D]).
signal toucher_left(toucher: PhysicsBody2D) ## Emitted when a toucher leaves from the area.

## If [code]false[/code] and the toucher is a character, the character won't get hurt if he/she gets hit by the area.[br]
## [br]
## [b]Note:[/b] For [EnemyStompable], if [code]false[/code], the character won't get hurt even if he/she fails stomping.
@export var character_damagible: bool = true

var _on_detection: bool # To prevent from double calls

var _detected_bodies: Array[PhysicsBody2D] # Touchers detected


#region == Built-in Methods ==
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if !root is Area2D:
		return
	
	var area := root as Area2D
	area.body_entered.connect(_on_body_touched)
	area.body_exited.connect(_on_body_left)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _detected_bodies.is_empty():
		return
	
	for i in _detected_bodies:
		_touched(i)
#endregion

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if !Engine.is_editor_hint():
		return warnings
	if !get_root() is Area2D:
		warnings.append("The component works only when the \"root\" is an Area2D.")
	
	return warnings


## [code]virtual[/code] Called when a toucher collides the [member Component.root] ([Area2D]).
func _touched(toucher: PhysicsBody2D) -> void:
	if _on_detection:
		_on_detection = false
		return
	if !is_instance_valid(toucher):
		return
	
	if toucher is Character:
		toucher.hurt()


#region == Character entering/exiting the area ==
func _on_body_touched(body: Node2D) -> void:
	if !body is PhysicsBody2D:
		return
	if !body.is_in_group(&"enemy_toucher"):
		return
	if body in _detected_bodies:
		return
	
	body = body as PhysicsBody2D
	
	on_touched_by.emit(body)
	
	_detected_bodies.append(body)
	_touched(body)
	_on_detection = true # To prevent from double call

func _on_body_left(body: Node2D) -> void:
	if !body is PhysicsBody2D:
		return
	if !body.is_in_group(&"enemy_toucher"):
		return
	if !body in _detected_bodies:
		return
	
	_on_detection = false
	
	body = body as PhysicsBody2D
	
	_detected_bodies.erase(body)
	
	toucher_left.emit(body)
#endregion
