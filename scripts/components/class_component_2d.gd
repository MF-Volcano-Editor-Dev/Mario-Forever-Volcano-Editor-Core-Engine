@icon("res://icons/component_2d.svg")
class_name Component2D extends Node2D

## Abstract base class of [Component], with features from [Node2D].
##
## This kind of component is basically the [Node2D] version of [Component], and many aspects are almost the same.[br]
## [b]Note:[/b] As this node is a [Node2D], the [member root] can be only set for [Node2D] types for convenience and coherence.


## Path to the [Node2D] that the component takes effect on
@export_node_path("Node2D") var root_path: NodePath = ^"..":
	set(value):
		root_path = value
		
		# For @tool-ed extending classes
		if !Engine.is_editor_hint():
			return
		
		root = get_root()
		
		notify_property_list_changed()
		update_configuration_warnings()

## See [member root_path].
@onready var root: Node = get_root()


## Returns the root 2D node of the component.[br]
## [br]
## [b]Note:[/b] In some situation, variables prefixed with [annotation @onready] will fail getting source node because of the speciality of the annotation.
## For safely getting the node, it's more recommended to use the getter.
func get_root() -> Node2D:
	return get_node_or_null(root_path)
