class_name Effects

## Static class that provides static functions for [CanvasItem], especially [Node2D]
##
## Because of being static, the functions in this class are all static, which means that the first param of these functions are ALWAYS [CanvasItem].

## Makes a node flash.[br]
## Flash effect means a body gets its alpha loops between fading out and fading in, the lower value the [param interval] is, the faster the node flashes.
static func flash(node: CanvasItem, duration: float, interval: float = 0.06) -> void:
	if !is_instance_valid(node):
		return
	
	var a: float = node.modulate.a
	var tw: Tween = node.create_tween().set_trans(Tween.TRANS_SINE).set_loops(int(ceilf(duration / interval)))
	tw.tween_property(node, ^"modulate:a", 0.1, interval / 2)
	tw.tween_property(node, ^"modulate:a", a, interval / 2)
	tw.finished.connect(func() -> void:
		node.modulate.a = a
	)
