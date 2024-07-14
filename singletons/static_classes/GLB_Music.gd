class_name Music

## Static class used to manage the musics.
##
##

static var _musics: Array[AudioStreamPlayer]


static func _resize_musics() -> void:
	if !_musics.is_empty():
		return
	_musics.resize(ProjectSettings.get_setting("game/data/music/music_channels", 32))

## Plays a music in specific [param channel]. A [param tree] should be passed in since this class is NOT a singleton [Node].[br]
## Returns the music player if it succeeds, or [code]null[/code] if it fails.[br]
## [br]
## [b]Note:[/b] You can set [param mode] to determine its mode to play, but if it plays globally, please ensure that it is well controlled.
static func play(tree: SceneTree, music_stream: AudioStream, channel: int, mode: DataList.AudioMode = DataList.AudioMode.SCENIAL) -> AudioStreamPlayer:
	_resize_musics()
	
	if !music_stream:
		return null
	if !is_channel_valid(channel):
		printerr("[Music] Invalid channel index: %s! Playing failed." % str(channel))
		return null
	
	if is_instance_valid(_musics[channel]):
		_musics[channel].play()
		return _musics[channel]
	else:
		var m := AudioStreamPlayer.new()
		m.stream = music_stream
		m.bus = &"Music"
		
		# Called deferredly to make sure the sound player will be safely added
		(func() -> void:
			match mode:
				DataList.AudioMode.SCENIAL:
					tree.current_scene.add_child(m)
				DataList.AudioMode.GLOBAL:
					tree.root.add_child(m)
			m.play()
		).call_deferred()
		
		_musics[channel] = m
		
		# Pauses the music when characters are on starman, and resumes when all get their starmen off
		Events.EventCharacter.get_signals().character_on_starman.connect(Music.pause.bind(channel), CONNECT_REFERENCE_COUNTED)
		Events.EventCharacter.get_signals().character_off_starman.connect(Music.resume.bind(channel), CONNECT_REFERENCE_COUNTED)
		
		# Stops music if some events are triggered
		Events.EventMusic.get_signals().music_all_stop.connect(func() -> void:
			Music.stop(channel, true)
		, CONNECT_ONE_SHOT | CONNECT_REFERENCE_COUNTED)
		
		return m

## Pauses a music.
static func pause(channel: int) -> void:
	_resize_musics()
	
	if !is_channel_valid(channel):
		printerr("[Music] Invalid channel index: %s! Stopping failed." % str(channel))
		return
	
	_musics[channel].stream_paused = true

## Resumes a music.
static func resume(channel: int) -> void:
	_resize_musics()
	
	if !is_channel_valid(channel):
		printerr("[Music] Invalid channel index: %s! Stopping failed." % str(channel))
		return
	
	_musics[channel].stream_paused = false

## Stops a music from playing. You can also turn on [param destroy] to make it automatically deleted after it stops.
static func stop(channel: int, destroy: bool = true) -> void:
	_resize_musics()
	
	if !is_channel_valid(channel):
		printerr("[Music] Invalid channel index: %s! Stopping failed." % str(channel))
		return
	
	_musics[channel].stop()
	if destroy:
		_musics[channel].queue_free()

## The same as [method stop], but needs an [AudioStreamPlayer] rather than a channel id.
static func stop_by_player(music_player: AudioStreamPlayer, destroy: bool = false) -> void:
	_resize_musics()
	
	if !music_player in _musics:
		printerr("[Music] The `music_player` should be a AudioStreamPlayer by `get_music()`. Stopping failed.")
		return
	
	stop(_musics.find(music_player), destroy)

## Fades a music_player and returns the success or failure of fading a music.
static func fade(music_player: AudioStreamPlayer, to: float, duration: float, stop_after_fading: bool = false) -> bool:
	_resize_musics()
	
	if !music_player in _musics:
		printerr("[Music] The `music_player` should be a AudioStreamPlayer by `get_music()`!")
		return false
	
	(func() -> void: # Deferred for safety
		var tw: Tween = music_player.create_tween()
		tw.tween_property(music_player, ^"volume_db", to, duration)
		
		await tw.finished
		
		if stop_after_fading:
			stop_by_player(music_player)
	).call_deferred()
	
	return true

## Fades all music channels, without any value returned.
static func fade_all(to: float, duration: float, stop_after_fading: bool = false) -> void:
	for i in _musics:
		if !is_instance_valid(i):
			continue
		Music.fade(i, to, duration, stop_after_fading)


## Returns [code]true[/code] if the given channel is valid.[br]
## A valid channel is set between 0 and the value of project setting, [code]"game/data/music/music_channels"[/code].
static func is_channel_valid(channel: int) -> bool:
	_resize_musics()
	return channel >= 0 && channel < _musics.size()

## Returns an [AudioStreamPlayer] that is under the control of this class, or [code]null[/code] if the channel is invalid.
static func get_music(channel: int) -> AudioStreamPlayer:
	_resize_musics()
	return _musics[channel] if is_channel_valid(channel) else null

## Returns all [AudioStreamPlayer]s that is under the control of this class.
static func get_all_musics() -> Array[AudioStreamPlayer]:
	return _musics
