class_name QuestionBlock2D extends BumpBlock2D

## A kind of bumpable block which may provide items by getting hit.
## 
## This requires items to be categorized in the node group named [code]item[/code], and move them under this node to become its children nodes.[br]
## [br]
## [b]Note 1:[/b] Do NOT rescale this object, and be careful to rotate it, because all items will be created with the same [member Node2D.global_transform] as the one of this.
## [b]Note 2:[/b] If a bumper should not interact with this object, please group the [Bumper2D] instance in [code]question_ignore[/code]

## Fallback if there is no any item as the child node of this object
@export var items: Array[QuestionBlockItem] = [preload("res://engine/objects/entities/bonuses/blocks/question_block_res/q_coin.tres")]
@export_group("References")
## Path to the animated_sprite
@export_node_path("AnimatedSprite2D") var animated_sprite_path: NodePath

var _run_out: bool # See QuestionBlockItemAbundant
var _timer: SceneTreeTimer # See QuestionBlockItemAbundant.time_limit
var _amount: int # See QuestionBlockItemAbundant.amount

@onready var _animated_sprite: AnimatedSprite2D = get_node_or_null(animated_sprite_path)


func _bump_process(bumper: Bumper2D, _touch_spot: Vector2) -> void:
	if !self is BricksBlock2D && bumper.is_in_group(&"question_ignore"):
		restore_bump()
		return
	
	if !items.is_empty():
		if !items[0]: # Null object
			items.remove_at(0)
		elif items[0] is QuestionBlockItemAbundant:
			_abundant_items_creation(0, bumper)
		else:
			_normal_item_creation(0, bumper)
	
	if items.is_empty():
		if _animated_sprite:
			_animated_sprite.play(&"hit")
	else:
		restore_bump()


func _normal_item_creation(items_index: int, bumper: Bumper2D, offset: Vector2 = Vector2.ZERO) -> void:
	var item_scene := (items[items_index] as QuestionBlockItem).get_item(bumper.body) as PackedScene
	if !item_scene:
		return
	
	_hit(item_scene, offset)
	items.remove_at(items_index)

func _abundant_items_creation(items_index: int, bumper: Bumper2D, offset: Vector2 = Vector2.ZERO) -> void:
	var item_pack := items[items_index] as QuestionBlockItemAbundant
	var item_scene := item_pack.get_item(bumper.body) as PackedScene
	if !item_scene:
		return
	
	match item_pack.limitation:
		0 when !_timer: # Time limit
			_timer = get_tree().create_timer(item_pack.time, false)
			_timer.timeout.connect(func() -> void:
				_run_out = true
			)
		1 when _amount < item_pack.amount: # Amount limit
			_amount += 1
			if _amount >= item_pack.amount:
				_run_out = true
	
	_hit(item_scene, offset)
	
	if _run_out:
		items.remove_at(items_index)
		_timer = null
		_amount = 0
		_run_out = false


func _hit(ins: PackedScene, offset: Vector2 = Vector2.ZERO) -> void:
	var i := ins.instantiate()
	i.global_transform = global_transform.translated_local(offset)
	add_sibling.call_deferred(i)
	get_parent().move_child.call_deferred(i, get_index())
	
	var hit := Callable(i, &"hit")
	if hit.is_valid():
		hit.call_deferred(self)
