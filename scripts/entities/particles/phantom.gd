class_name Phantom2D extends Component2D

## Used to generate phantoms.
##
## [b]Note:[/b] Please control the [member interval] because this may cause heavy performance loss during the creation of lots of phantoms.

## Path to the source node that provides phantom.
@export_node_path("Node2D") var source_path: NodePath:
	set(value):
		source_path = value
		if !is_node_ready():
			await ready
		source = get_node(source_path)
## Properties to sync
@export var sync_props: Array[StringName]
## If [code]true[/code], the phantom is enabled to be generated
@export var enabled: bool = true
## If [code]true[/code], the phantom will have no script
@export var phantom_no_script: bool = true
## Lifetime of the phantom
@export_range(0, 20, 0.001, "suffix:s") var lifetime: float = 0.5
## Interval of creating a phantom
@export_range(0, 20, 0.001, "suffix:s") var interval: float = 0.08

## Source [Node2D] of the phantom
var source: Node2D


func _enter_tree() -> void:
	var tw := create_tween().set_loops()
	tw.tween_callback(_phantom_generated).set_delay(interval)
	tree_exited.connect(tw.kill)

## [code]virtual[/code] Called when a phantom is generated
func _phantom_generated() -> void:
	if !enabled || !source:
		return
	
	var ph := source.duplicate()
	
	for i in ph.get_children(): # May cause performance loss
		i.free()
	
	ph.global_transform = global_transform
	if phantom_no_script:
		ph.set_script(null)
	
	root.add_sibling.call_deferred(ph)
	root.get_parent().move_child.call_deferred(ph, root.get_index())
	
	(func() -> void:
		var tw: Tween = ph.create_tween()
		tw.tween_property(ph, ^"modulate:a", 0, lifetime)
		tw.finished.connect(ph.queue_free)
		
		for j in sync_props: # May lead to it as well
			ph.set(j, source.get(j))
	).call_deferred() # Since the phantom is added to the tree in a deferred way
