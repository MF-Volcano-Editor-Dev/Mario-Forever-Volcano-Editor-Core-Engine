class_name Sound

## Static class that manages the playing of sounds
##
##

## Plays a sound in the 1D space.
static func play_1d(stream: AudioStream, owner: Node, mode: DataList.AudioMode = DataList.AudioMode.SCENIAL) -> AudioStreamPlayer:
	if !stream || !is_instance_valid(owner) || !owner.is_inside_tree():
		return null
	
	var snd: AudioStreamPlayer = AudioStreamPlayer.new()
	snd.stream = stream
	snd.bus = &"Sound"
	
	(func() -> void: # Called deferredly to make sure the sound player will be safely added
		match mode:
			DataList.AudioMode.AS_CHILD:
				owner.add_child(snd)
			DataList.AudioMode.SCENIAL:
				owner.get_tree().current_scene.add_child(snd)
			DataList.AudioMode.GLOBAL:
				owner.get_tree().root.add_child(snd)
		snd.finished.connect(snd.queue_free)
		snd.play()
	).call_deferred()
	
	return snd

## Plays a sound in the 2D space.
static func play_2d(stream: AudioStream, owner: CanvasItem, mode: DataList.AudioMode = DataList.AudioMode.SCENIAL, area_mask: int = int(ProjectSettings.get_setting("game/data/sound/default_area_mask", 1))) -> AudioStreamPlayer2D:
	if !stream || !is_instance_valid(owner) || !owner.is_inside_tree():
		return null
	
	var snd: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	snd.area_mask = area_mask
	snd.stream = stream
	snd.bus = &"Sound"
	
	(func() -> void: # Called deferredly to make sure the sound player will be safely added
		match mode:
			DataList.AudioMode.AS_CHILD:
				owner.add_child(snd)
			DataList.AudioMode.SCENIAL:
				owner.get_tree().current_scene.add_child(snd)
			DataList.AudioMode.GLOBAL:
				owner.get_tree().root.add_child(snd)
		snd.global_transform = owner.get_global_transform()
		snd.finished.connect(snd.queue_free)
		snd.play()
	).call_deferred()
	
	return snd
