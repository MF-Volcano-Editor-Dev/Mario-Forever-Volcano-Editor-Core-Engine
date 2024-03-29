extends Timer

func _ready() -> void:
	var effboxes: Array[Node] = get_parent().find_children("EffectBox*")
	for i in effboxes:
		if i is Area2D:
			for j in i.get_shape_owners():
				i.shape_owner_set_disabled(i, true)
			
			timeout.connect(func() -> void:
				for k in i.get_shape_owners():
					i.shape_owner_set_disabled(k, false)
			, CONNECT_DEFERRED)
