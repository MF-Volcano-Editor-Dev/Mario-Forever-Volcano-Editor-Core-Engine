@tool
class_name VisibleOnScreenNotifierDirectional2D extends VisibleOnScreenNotifier2D

## A 2D area to detect if the rectangle is visible on the screen, and if the object is leaving from the screen in a specific direction.
##
## Similar to [VisibleOnScreenNotifier2D], this node provides extra detection of leaving in a specific direction, and [signal screen_exited_directionally] will be triggered if the event is triggered.

signal screen_exited_directionally ## Emitted when the node leaves the screen along a specific direction.

@export_category("VisibleDirectional2D")
@export_group("Direction")
## Leaving direction of the node.[br]
@export_flags("Left", "Right", "Up", "Down") var direction: int
@export var with_global_transform: bool = false

var _delay: int = 1
var _is_initialized: bool


#region == Export Storage ==
func _set(property: StringName, value: Variant) -> bool:
	if property == &"_is_initialized":
		_is_initialized = value
	return false

func _get(property: StringName) -> Variant:
	if property == &"_is_initialized":
		return _is_initialized
	return null

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	
	properties.append({
		name = &"_is_initialized",
		type = TYPE_BOOL,
		usage = PROPERTY_USAGE_NO_EDITOR,
		hint = PROPERTY_HINT_NONE,
		hint_string = ""
	})
	
	return properties
#endregion


func _ready() -> void:
	if !_is_initialized && Engine.is_editor_hint():
		_is_initialized = true
		visible = false
	elif !Engine.is_editor_hint():
		visible = true


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if is_on_screen():
		return
	if _delay > 0:
		_delay -= 1
		return
	
	var t := global_transform.affine_inverse() if with_global_transform else Transform2D()
	var c := t.basis_xform(get_global_transform_with_canvas().get_origin()) # Canvas position, transformed by the global transform or unit transform of the node
	var b := t.basis_xform(get_viewport_rect().size) # Border position, transformed by the global transform or unit transform of the node
	
	match direction:
		var d when d & 1 && c.x < 0:
			screen_exited_directionally.emit()
		var d when (d >> 1) & 1 && c.x > b.x:
			screen_exited_directionally.emit()
		var d when (d >> 2) & 1 && c.y < 0:
			screen_exited_directionally.emit()
		var d when (d >> 3) & 1 && c.y > b.y:
			screen_exited_directionally.emit()
