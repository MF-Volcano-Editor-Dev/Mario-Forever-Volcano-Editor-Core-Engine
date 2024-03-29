@icon("res://icons/component.svg")
class_name Component extends Node

## Abstract base class of such nodes that provides extra functions for other nodes, or help these nodes with some process.
##
## [b]Note 1:[/b] Generally, [member root] should be manually set in order to make the component work as expected, though some components have no any requirement on it.[br]
## [b]Note 2:[/b] If you want to get a more specific type of [member root] please cast the member with [code]as[/code]:
## [codeblock]
## var specific: Type = root as Type # Type should be the child of Node!
## [/codeblock]

## Path to the [Node] that the component takes effect on
@export_node_path("Node") var root_path: NodePath = ^"..":
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


## Returns the root node of the component.[br]
## [br]
## [b]Note:[/b] In some situation, variables prefixed with [annotation @onready] will fail getting source node because of the speciality of the annotation.
## For safely getting the node, it's more recommended to use the getter.
func get_root() -> Node:
	return get_node_or_null(root_path)
